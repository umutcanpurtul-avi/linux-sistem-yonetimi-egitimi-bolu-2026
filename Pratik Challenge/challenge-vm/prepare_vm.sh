#!/usr/bin/env bash
# Pratik Challenge'i HERHANGI bir Debian 13 makinesine kurar
# (Proxmox, KVM/libvirt, VMware, Hyper-V, bare-metal -- VirtualBox icin provision.sh var).
#
# TAZE bir Debian 13 VM'in ICINDE, root olarak calistir:
#     sudo bash prepare_vm.sh
#
# Yapar (idempotent -- tekrar tekrar calistirilabilir):
#   1. 'ogrenci' kullanicisini olusturur (parola: ogrenci123), 'sudo' grubuna ekler
#   2. Gerekli temel paketleri kurar (sudo openssh-server python3 curl)
#   3. SSH'i acar
#   4. Bolum C/D icin ikinci (bos) diski kontrol eder
#   5. setup_gorev.sh'yi 'ogrenci' olarak calistirir -> ~/gorev/ (Bolum A-L) senaryosu
#   6. Baglanti bilgisini yazar
set -euo pipefail

CHALLENGE_USER="ogrenci"
CHALLENGE_PASS="ogrenci123"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RAW_BASE="https://raw.githubusercontent.com/umutcanpurtul-avi/linux-sistem-yonetimi-egitimi-bolu-2026/main/Pratik%20Challenge/challenge-vm"

if [ "$(id -u)" -ne 0 ]; then
  echo "HATA: root olarak calistir:  sudo bash prepare_vm.sh" >&2
  exit 1
fi

# --- 0. Debian surum kontrolu -------------------------------------------------
if [ -r /etc/os-release ]; then . /etc/os-release; fi
echo "== Sistem: ${PRETTY_NAME:-bilinmiyor} =="
case "${VERSION_CODENAME:-}" in
  trixie) : ;;  # Debian 13 -- hedef
  bookworm) echo "   UYARI: Debian 12. Cogu bolum calisir; bazi paket adlari farkli"
            echo "          olabilir, Bolum L3 repo satiri 'trixie' yazar (kozmetik)." ;;
  "")     echo "   UYARI: /etc/os-release okunamadi. Debian degilse bu script uygun degil." ;;
  *)      echo "   UYARI: Beklenen 'trixie' (Debian 13), bulunan: ${VERSION_CODENAME}." ;;
esac

# --- 1. ogrenci kullanicisi -------------------------------------------------
if id -u "$CHALLENGE_USER" >/dev/null 2>&1; then
  echo "== '$CHALLENGE_USER' zaten var -- parola '$CHALLENGE_PASS' olarak ayarlaniyor =="
  echo "   (setup_gorev.sh'nin sudo askpass'i bu parolaya bagli)"
else
  echo "== '$CHALLENGE_USER' kullanicisi olusturuluyor =="
  useradd -m -s /bin/bash "$CHALLENGE_USER"
fi
echo "${CHALLENGE_USER}:${CHALLENGE_PASS}" | chpasswd
# 'sudo' grubu (Debian'da sudo yetkisi bu grupla gelir)
getent group sudo >/dev/null || groupadd sudo
id -nG "$CHALLENGE_USER" | tr ' ' '\n' | grep -qx sudo || usermod -aG sudo "$CHALLENGE_USER"

# --- 2. temel paketler ------------------------------------------------------
echo "== Temel paketler kuruluyor (sudo openssh-server python3 curl ca-certificates) =="
export DEBIAN_FRONTEND=noninteractive
# Onceki bir setup_gorev.sh calismasindan kalmis olabilecek bozuk depoyu (Bolum L3)
# temizle ki 'apt-get update' gurultu cikarmasin; setup_gorev.sh sonunda geri ekler.
rm -f /etc/apt/sources.list.d/gorev-ekstra.list
apt-get update -qq
apt-get install -y -qq sudo openssh-server python3 curl ca-certificates >/dev/null

# --- 3. SSH ---------------------------------------------------------------
systemctl enable --now ssh >/dev/null 2>&1 || systemctl enable --now sshd >/dev/null 2>&1 || true

# --- 4. ikinci disk kontrolu (Bolum C/D) --------------------------------------
ROOT_SRC="$(findmnt -no SOURCE / 2>/dev/null || true)"
ROOT_DISK="$(lsblk -no pkname "$ROOT_SRC" 2>/dev/null | head -1)"
[ -z "$ROOT_DISK" ] && ROOT_DISK="$(echo "$ROOT_SRC" | sed -E 's#/dev/##; s#p?[0-9]+$##')"
echo
echo "== Diskler =="
lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS
echo
# kok olmayan, bolumsuz/fs'siz bir disk ara
SECOND_DISK=""
while read -r name type; do
  [ "$type" = "disk" ] || continue
  [ "$name" = "$ROOT_DISK" ] && continue
  # uzerinde bolum veya fs var mi?
  if [ -z "$(lsblk -no FSTYPE "/dev/$name" | tr -d ' ')" ] && \
     [ "$(lsblk -rno NAME "/dev/$name" | wc -l)" -eq 1 ]; then
    SECOND_DISK="/dev/$name"; break
  fi
done < <(lsblk -rno NAME,TYPE)

if [ -n "$SECOND_DISK" ]; then
  echo "== Bolum C/D icin ikinci (bos) disk: $SECOND_DISK  -- hazir =="
else
  echo "!! Bolum C/D icin ikinci BOS disk bulunamadi."
  echo "!! Proxmox'ta VM'e ~1-2 GB ikinci bir disk ekle (bicimlendirme, bos birak),"
  echo "!! VM'i yeniden baslat, bu script'i tekrar calistir. Simdilik devam ediliyor;"
  echo "!! Bolum C ve D4 disinda tum bolumler calisir."
fi

# --- 4b. birincil disk adi (Bolum L1 metni /dev/sda varsayar) -----------------
if [ "$ROOT_DISK" != "sda" ]; then
  echo
  echo "== NOT: Kok disk /dev/${ROOT_DISK} (virtio?). Bolum L1/C metinleri /dev/sda diyor;"
  echo "        oralarda /dev/${ROOT_DISK} olarak oku. Istersen Proxmox'ta disk barasini"
  echo "        SATA/SCSI yaparsan /dev/sda olur."
fi

# --- 5. setup_gorev.sh ----------------------------------------------------
SETUP="$SCRIPT_DIR/setup_gorev.sh"
if [ ! -f "$SETUP" ]; then
  echo
  echo "== setup_gorev.sh yaninda yok, main'den indiriliyor =="
  SETUP="/tmp/setup_gorev.sh"
  curl -fsSL "$RAW_BASE/setup_gorev.sh" -o "$SETUP"
fi
install -m 0755 -o "$CHALLENGE_USER" -g "$CHALLENGE_USER" "$SETUP" "/home/$CHALLENGE_USER/setup_gorev.sh"

echo
echo "== Gorev senaryosu kuruluyor ('$CHALLENGE_USER' olarak) =="
runuser -l "$CHALLENGE_USER" -c "bash ~/setup_gorev.sh"

# --- 6. baglanti -----------------------------------------------------------
IP="$(hostname -I 2>/dev/null | awk '{print $1}')"
echo
echo "=================================================================="
echo " HAZIR."
echo "   Baglan:   ssh ${CHALLENGE_USER}@${IP:-<VM-IP>}      (parola: ${CHALLENGE_PASS})"
echo "   Gorevler: Pratik Challenge/Sorular.md"
echo "   Cevaplar: Pratik Challenge/Cevaplar.md"
echo
echo "   Sifirlamak icin (VM icinde, $CHALLENGE_USER olarak):  bash ~/setup_gorev.sh"
echo "   (setup_gorev.sh idempotenttir; her calismada senaryo bilerek-bozuk baslar.)"
echo "=================================================================="
