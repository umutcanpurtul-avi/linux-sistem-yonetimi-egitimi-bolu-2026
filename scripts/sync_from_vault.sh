#!/usr/bin/env bash
# Obsidian vault'undaki eğitim notlarını bu repoya tek yönlü senkronlar.
# Kaynak (vault) hiçbir zaman değiştirilmez; repo tarafı her çalıştırmada
# vault'un güncel haliyle yeniden oluşturulur, sonra GitHub için dönüştürülür.
set -euo pipefail

VAULT="/home/umutcanpurtul/Documents/UCP/Linux Sistem Yönetimi Eğitimi"
REPO="/home/umutcanpurtul/repos/linux-sistem-yonetimi-egitimi"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "$REPO/Kamp Eğitim" "$REPO/AI-Egitim-Dokümanı"

echo "Günlük Notlar -> Kamp Eğitim/"
rsync -a --delete "$VAULT/Günlük Notlar/" "$REPO/Kamp Eğitim/"

echo "CL-Egitim -> AI-Egitim-Dokümanı/"
rsync -a --delete "$VAULT/CL-Egitim/" "$REPO/AI-Egitim-Dokümanı/"
if [ -f "$REPO/AI-Egitim-Dokümanı/00-BASLA-BURADAN.md" ]; then
  mv "$REPO/AI-Egitim-Dokümanı/00-BASLA-BURADAN.md" "$REPO/AI-Egitim-Dokümanı/README.md"
fi

echo "Kök dosyalar kopyalanıyor"
rsync -a "$VAULT/00 - Eğitim Planı.md" "$REPO/00 - Eğitim Planı.md"

echo "Obsidian -> GitHub dönüşümü çalıştırılıyor"
python3 "$SCRIPT_DIR/obsidian_to_github.py" "$REPO"

echo
echo "Senkron tamam. Şimdi gözden geçir:"
echo "  cd '$REPO' && git status && git diff"
