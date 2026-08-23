#!/usr/bin/env python3
"""Obsidian vault kopyasını GitHub'da doğru render olacak Markdown'a dönüştürür.

Kullanım: obsidian_to_github.py <repo_kök_dizini>
Bu script, sync_from_vault.sh tarafından rsync adımlarından SONRA çağrılır.
"""
import os
import re
import sys
from pathlib import Path

WIKILINK_RE = re.compile(r"\[\[([^\]|]+?)(?:\|([^\]]+?))?\]\]")
CALLOUT_RE = re.compile(r"^(?P<indent>>+) \[!(?P<type>info|warning|tip)\](?P<rest>.*)$", re.MULTILINE)
CALLOUT_MAP = {"info": "NOTE", "warning": "WARNING", "tip": "TIP"}
SENSITIVE_STRINGS = ["egitim2026"]


def prune_empty_gun_notlari(egitim_dir: Path) -> None:
    """tarih: alanı boş olan Gün N.md şablonlarını (henüz doldurulmamış günler) kaldırır."""
    for f in sorted(egitim_dir.glob("Gün *.md")):
        text = f.read_text(encoding="utf-8")
        m = re.search(r"^tarih:[ \t]*(.*)$", text, re.MULTILINE)
        value = m.group(1).strip() if m else ""
        if not value:
            f.unlink()
            print(f"  atlandı (boş şablon): {f.relative_to(egitim_dir.parent)}")


def build_title_index(repo: Path) -> dict:
    index = {}
    for f in repo.rglob("*.md"):
        if "scripts" in f.parts:
            continue
        index[f.stem] = f
    # Yeniden adlandırılan/rota değişen dosyalar için takma adlar
    cl_readme = repo / "CL-Eğitim" / "README.md"
    if cl_readme.exists():
        index["00-BASLA-BURADAN"] = cl_readme
    index.setdefault("Günlük Notlar", repo / "Eğitim" / "README.md")
    index.setdefault("Linux Sistem Yönetimi Eğitimi", repo / "README.md")
    return index


def convert_wikilinks(text: str, current_file: Path, index: dict) -> str:
    def repl(m: re.Match) -> str:
        target, label = m.group(1).strip(), m.group(2)
        target_path = index.get(target)
        if target_path is None:
            return m.group(0)  # bilinmeyen hedef (bash [[ ]] testi vb.) — dokunma
        rel = os.path.relpath(target_path, current_file.parent).replace(" ", "%20")
        display = (label or target).strip()
        return f"[{display}]({rel})"

    return WIKILINK_RE.sub(repl, text)


def convert_callouts(text: str) -> str:
    def repl(m: re.Match) -> str:
        line1 = f"{m['indent']} [!{CALLOUT_MAP[m['type']]}]"
        rest = m["rest"].strip()
        if rest:
            return f"{line1}\n{m['indent']} **{rest}**"
        return line1

    return CALLOUT_RE.sub(repl, text)


def fix_egitim_plani(text: str) -> str:
    text = re.sub(r"^kaynak:.*\n", "", text, flags=re.MULTILINE)
    text = text.replace(
        "~/Downloads/gnu_linux_sistem_yonetimi_1_duzey_9_gun_surumu.md",
        "yerel eğitim materyali (repo dışı)",
    )
    return text


def fix_durum(text: str) -> str:
    return re.sub(r"^durum:\s*baslamadi\s*$", "durum: tamamlandi", text, flags=re.MULTILINE)


def generate_egitim_readme(egitim_dir: Path) -> None:
    def gun_no(p: Path) -> int:
        m = re.search(r"\d+", p.stem)
        return int(m.group()) if m else 0

    entries = []
    for f in sorted(egitim_dir.glob("Gün *.md"), key=gun_no):
        text = f.read_text(encoding="utf-8")
        m = re.search(r"^tarih:[ \t]*(.+)$", text, re.MULTILINE)
        tarih = m.group(1).strip() if m else "?"
        entries.append((f.name, tarih))

    lines = [
        "# Eğitim — Günlük Notlar",
        "",
        "Eğitim boyunca gün gün tutulan notlar. Yeni günler eğitim ilerledikçe eklenir.",
        "",
        "| Gün | Tarih |",
        "|---|---|",
    ]
    for name, tarih in entries:
        title = name[:-3]
        link = name.replace(" ", "%20")
        lines.append(f"| [{title}]({link}) | {tarih} |")
    (egitim_dir / "README.md").write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    if len(sys.argv) != 2:
        print("Kullanım: obsidian_to_github.py <repo_kök_dizini>", file=sys.stderr)
        sys.exit(2)

    repo = Path(sys.argv[1]).resolve()
    egitim_dir = repo / "Eğitim"

    if egitim_dir.exists():
        print("Boş gün şablonları filtreleniyor...")
        prune_empty_gun_notlari(egitim_dir)

    index = build_title_index(repo)

    print("Wikilink ve callout dönüşümü yapılıyor...")
    for f in repo.rglob("*.md"):
        if "scripts" in f.parts:
            continue
        text = f.read_text(encoding="utf-8")
        original = text
        text = convert_wikilinks(text, f, index)
        text = convert_callouts(text)
        if f.name == "00 - Eğitim Planı.md":
            text = fix_egitim_plani(text)
        if "CL-Eğitim" in f.parts:
            text = fix_durum(text)
        if text != original:
            f.write_text(text, encoding="utf-8")

    if egitim_dir.exists():
        generate_egitim_readme(egitim_dir)
        print("Eğitim/README.md güncellendi.")

    print("Güvenlik taraması yapılıyor...")
    leaked = []
    for f in repo.rglob("*.md"):
        text = f.read_text(encoding="utf-8")
        for s in SENSITIVE_STRINGS:
            if s in text:
                leaked.append((f, s))
    if leaked:
        print("\n🔴 GÜVENLİK: hassas veri bulundu, işlem DURDURULDU (commit/push yapma!):")
        for f, s in leaked:
            print(f"   - {f}: '{s}'")
        sys.exit(1)

    print("\nDönüşüm tamamlandı, hassas veri bulunamadı.")


if __name__ == "__main__":
    main()
