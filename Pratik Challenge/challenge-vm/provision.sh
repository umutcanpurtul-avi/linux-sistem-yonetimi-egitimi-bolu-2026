#!/usr/bin/env bash
# Gün 1-5 Pratik Challenge için tek amaçlı, izole bir Debian 13 VM'i kurar.
# Gereksinimler: VirtualBox 7.x, sshpass, ~500MB internet (paket indirme).
#
# Kullanım:
#   bash provision.sh
#
# Sonuç: "Debian-Challenge" adında, ssh -p 2224 ogrenci@127.0.0.1 (şifre: ogrenci123)
# ile erişilebilen, 20GB birincil + 1.2GB boş ikincil diske sahip bir VM.
set -euo pipefail

VM="Debian-Challenge"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKDIR="${WORKDIR:-$HOME/VMs/$VM}"
ISO_DIR="${ISO_DIR:-$HOME/VMs/isos}"
ISO="$ISO_DIR/debian-13.6.0-amd64-netinst.iso"
ISO_URL="https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-13.6.0-amd64-netinst.iso"
TPL="$SCRIPT_DIR/debian_preseed.tpl"
DISK1="$WORKDIR/${VM}.vdi"
DISK2="$WORKDIR/${VM}_1.vdi"
SSHPORT=2224
SSHUSER=ogrenci
SSHPASS=ogrenci123

mkdir -p "$WORKDIR" "$ISO_DIR"

if [ ! -f "$ISO" ]; then
  echo "== Debian netinst ISO indiriliyor =="
  curl -fL -o "$ISO" "$ISO_URL"
fi

if VBoxManage list vms | grep -q "\"$VM\""; then
  echo "== '$VM' zaten kayıtlı, önce silinsin mi? (mevcut sürüm korunuyor, script durduruluyor) =="
  echo "Temiz kurulum için: VBoxManage unregistervm '$VM' --delete"
  exit 1
fi

echo "== VM oluşturuluyor =="
VBoxManage createvm --name "$VM" --ostype Debian13_64 --register --basefolder "$(dirname "$WORKDIR")"
VBoxManage modifyvm "$VM" --memory 2048 --cpus 4 --nic1 nat
VBoxManage modifyvm "$VM" --natpf1 "ssh,tcp,,${SSHPORT},,22"

echo "== Diskler oluşturuluyor =="
VBoxManage storagectl "$VM" --name SATA --add sata --controller IntelAhci --portcount 30 --bootable on
VBoxManage createmedium disk --filename "$DISK1" --size 20480 --format VDI
VBoxManage storageattach "$VM" --storagectl SATA --port 0 --device 0 --type hdd --medium "$DISK1"

echo "== Unattended kurulum başlıyor (headless, birkaç dakika sürebilir) =="
VBoxManage unattended install "$VM" \
  --iso="$ISO" \
  --user="$SSHUSER" \
  --password="$SSHPASS" \
  --full-user-name="Ogrenci" \
  --hostname="debian-challenge.local" \
  --locale=en_US \
  --country=US \
  --time-zone=Europe/Istanbul \
  --package-selection-adjustment=minimal \
  --script-template="$TPL" \
  --start-vm=headless

echo "== Kurulumun bitip SSH'nin ayağa kalkması bekleniyor (~5-10 dk) =="
for i in $(seq 1 90); do
  if sshpass -p "$SSHPASS" ssh -p "$SSHPORT" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
       -o ConnectTimeout=3 "$SSHUSER@127.0.0.1" true 2>/dev/null; then
    echo "SSH hazır (deneme $i)"
    break
  fi
  sleep 10
done

echo "== VM kapatılıp ikinci (boş) disk ekleniyor =="
VBoxManage controlvm "$VM" acpipowerbutton
for i in $(seq 1 30); do
  state=$(VBoxManage showvminfo "$VM" --machinereadable | grep -oP '(?<=VMState=")[a-z]+')
  [ "$state" = "poweroff" ] && break
  sleep 5
done

VBoxManage createmedium disk --filename "$DISK2" --size 1200 --format VDI
VBoxManage storageattach "$VM" --storagectl SATA --port 2 --device 0 --type hdd --medium "$DISK2"

echo "== VM yeniden başlatılıyor (headless) =="
VBoxManage startvm "$VM" --type headless

echo "== SSH tekrar ayakta mı bekleniyor =="
for i in $(seq 1 30); do
  if sshpass -p "$SSHPASS" ssh -p "$SSHPORT" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
       -o ConnectTimeout=3 "$SSHUSER@127.0.0.1" "lsblk" 2>/dev/null; then
    echo "== Temel kurulum hazır, ikinci disk görünüyor =="
    break
  fi
  sleep 5
done

echo "== Görev senaryosu (~/gorev) VM içine kuruluyor =="
sshpass -p "$SSHPASS" scp -P "$SSHPORT" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
  "$SCRIPT_DIR/setup_gorev.sh" "$SSHUSER@127.0.0.1:~/setup_gorev.sh"
sshpass -p "$SSHPASS" ssh -p "$SSHPORT" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
  "$SSHUSER@127.0.0.1" "bash ~/setup_gorev.sh && rm ~/setup_gorev.sh"

echo
echo "== TAMAMLANDI =="
echo "Bağlantı: ssh -p $SSHPORT $SSHUSER@127.0.0.1  (şifre: $SSHPASS)"
echo "Görevler: ../Sorular.md   Cevaplar: ../Cevaplar.md"
