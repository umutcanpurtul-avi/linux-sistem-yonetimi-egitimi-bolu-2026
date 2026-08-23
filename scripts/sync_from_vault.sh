#!/usr/bin/env bash
# Obsidian vault'undaki eğitim notlarını bu repoya tek yönlü senkronlar.
# Kaynak (vault) hiçbir zaman değiştirilmez; repo tarafı her çalıştırmada
# vault'un güncel haliyle yeniden oluşturulur, sonra GitHub için dönüştürülür.
set -euo pipefail

VAULT="/home/umutcanpurtul/Documents/UCP/Linux Sistem Yönetimi Eğitimi"
REPO="/home/umutcanpurtul/repos/linux-sistem-yonetimi-egitimi"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "$REPO/Eğitim" "$REPO/CL-Eğitim"

echo "Günlük Notlar -> Eğitim/"
rsync -a --delete "$VAULT/Günlük Notlar/" "$REPO/Eğitim/"

echo "CL-Egitim -> CL-Eğitim/"
rsync -a --delete "$VAULT/CL-Egitim/" "$REPO/CL-Eğitim/"
if [ -f "$REPO/CL-Eğitim/00-BASLA-BURADAN.md" ]; then
  mv "$REPO/CL-Eğitim/00-BASLA-BURADAN.md" "$REPO/CL-Eğitim/README.md"
fi

echo "Kök dosyalar kopyalanıyor"
rsync -a "$VAULT/00 - Eğitim Planı.md" "$REPO/00 - Eğitim Planı.md"

echo "Obsidian -> GitHub dönüşümü çalıştırılıyor"
python3 "$SCRIPT_DIR/obsidian_to_github.py" "$REPO"

echo
echo "Senkron tamam. Şimdi gözden geçir:"
echo "  cd '$REPO' && git status && git diff"
