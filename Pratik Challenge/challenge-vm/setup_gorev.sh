#!/usr/bin/env bash
# Debian-Challenge VM icinde 'ogrenci' kullanicisi olarak calistirilir.
# ~/gorev/ altinda Gun 1-5 pratik senaryosunu hazirlar (idempotent).
# Senaryo: onceki sistem yoneticisinden kalma dagimik bir ev dizini --
# dosya adlari GERCEKCI, hicbiri gorevin cevabini ele vermiyor.
set -euo pipefail
cd ~

SUDO_PASS="ogrenci123"
sudo_do() { echo "$SUDO_PASS" | sudo -S -p '' "$@"; }

echo "== Gerekli paketler kontrol ediliyor/kuruluyor (Bolum E/F icin) =="
sudo_do -v
sudo_do env DEBIAN_FRONTEND=noninteractive apt-get update -qq
sudo_do env DEBIAN_FRONTEND=noninteractive apt-get install -y -qq acl curl >/dev/null
sudo_do env DEBIAN_FRONTEND=noninteractive apt-get install -y -qq xxd >/dev/null 2>&1 \
  || sudo_do env DEBIAN_FRONTEND=noninteractive apt-get install -y -qq vim-common >/dev/null
sudo_do env DEBIAN_FRONTEND=noninteractive apt-get install -y -qq plocate >/dev/null 2>&1 \
  || sudo_do env DEBIAN_FRONTEND=noninteractive apt-get install -y -qq mlocate >/dev/null
# Bolum F6'nin "indeks guncel degil" ogretici anini garanti altina almak icin
# otomatik gunluk updatedb zamanlayicisini/cron'unu kapatiyoruz -- indeks sadece
# ogrenci elle 'sudo updatedb' calistirdiginda guncellenecek.
sudo_do systemctl disable --now plocate-updatedb.timer >/dev/null 2>&1 || true
sudo_do rm -f /etc/cron.daily/mlocate /etc/cron.daily/plocate 2>/dev/null || true

rm -rf gorev
mkdir -p gorev/bolum-a/yedekler gorev/bolum-a/env
mkdir -p gorev/bolum-a/projeler/web-app gorev/bolum-a/projeler/veritabani
mkdir -p gorev/bolum-a/projeler/api-servisi/gelistirme gorev/bolum-a/projeler/api-servisi/uretim
mkdir -p gorev/bolum-b/loglar gorev/bolum-b/ayarlar gorev/bolum-b/depo
mkdir -p gorev/bolum-b/config gorev/bolum-b/belge gorev/bolum-b/arsiv gorev/bolum-b/yedek
mkdir -p gorev/bolum-d/belgeler gorev/bolum-d/masaustu gorev/bolum-d/indirilenler gorev/bolum-d/harici
mkdir -p gorev/bolum-e/canli gorev/bolum-e/arsiv gorev/bolum-e/hex gorev/bolum-e/paket
mkdir -p gorev/bolum-f/acl gorev/bolum-f/sahiplik gorev/bolum-f/sshd gorev/bolum-f/web
mkdir -p gorev/bolum-f/derin/proje/arsiv/2026/yedek/kontrol/son

########## BOLUM A ##########
echo "KOD-A: 4471" > gorev/bolum-a/yedekler/rapor_2026.txt
chmod 000 gorev/bolum-a/yedekler/rapor_2026.txt

echo "KOD-B=8825" > "gorev/bolum-a/env/.env"

cat > gorev/bolum-a/calistir.sh <<'EOF'
#!/bin/bash
echo "Islem basladi, normal cikti."
echo "HATA: yetki reddedildi (sahte hata, betigin bir parcasi)" >&2
EOF
chmod +x gorev/bolum-a/calistir.sh

python3 - <<'PYEOF'
import random
target_line = 214
lines = []
for i in range(1, 501):
    if i == target_line:
        lines.append(f"{i:04d} ARANAN-SATIR: KOD-C-9183")
    else:
        lines.append(f"{i:04d} kayit islendi, referans={random.randint(1000,9999)}")
with open("gorev/bolum-a/erisim.log", "w") as f:
    f.write("\n".join(lines) + "\n")
PYEOF

cat > gorev/bolum-a/giris_kontrol.sh <<'EOF'
#!/bin/bash
if [ "${ANAHTAR:-}" = "acilsin" ]; then
    echo "KOD-D: 3390"
else
    echo "Erisim reddedildi."
fi
EOF
chmod +x gorev/bolum-a/giris_kontrol.sh

echo "Bos proje iskeleti." > gorev/bolum-a/projeler/web-app/README.txt
echo "Bos proje iskeleti." > gorev/bolum-a/projeler/veritabani/README.txt
echo "Surum notlari burada tutuluyor." > gorev/bolum-a/projeler/api-servisi/gelistirme/not.txt
echo "Surum notlari burada tutuluyor." > gorev/bolum-a/projeler/api-servisi/uretim/not.txt
echo "KOD-J: 6604" > gorev/bolum-a/projeler/api-servisi/ozet.txt

########## BOLUM B ##########
cat > gorev/bolum-b/loglar/nginx-access.log <<'EOF'
bilgi: baglanti kuruldu
hata: disk gecici olarak dolu (test-ortami)
bilgi: istek tamamlandi
EOF

cat > gorev/bolum-b/loglar/app-worker.log <<'EOF'
bilgi: kuyruk isleniyor
HATA: KOD-E-7724 - uretim ortaminda kritik hata
bilgi: kuyruk bosaltildi
EOF

cat > gorev/bolum-b/loglar/cron.log <<'EOF'
Hata: test-ortami icinde beklenen istisna
bilgi: zamanlanmis gorev calisti
EOF
touch -d "40 days ago" gorev/bolum-b/loglar/cron.log

cat > gorev/bolum-b/ayarlar/postfix.conf <<'EOF'
myhostname = mail.local
mydestination = localhost
EOF
cat > gorev/bolum-b/ayarlar/crontab.conf <<'EOF'
0 3 * * * /usr/local/bin/temizlik.sh
EOF
touch -d "5 days ago" gorev/bolum-b/ayarlar/postfix.conf gorev/bolum-b/ayarlar/crontab.conf

cat > gorev/bolum-b/ayarlar/samba.conf <<'EOF'
[global]
workgroup = WORKGROUP
# KOD-F: 6157
EOF

python3 - <<'PYEOF'
import os
sizes = {
    "dump_01.bin": 20_000,
    "dump_02.bin": 350_000,
    "dump_03.bin": 2_000_000,
}
for name, size in sizes.items():
    with open(f"gorev/bolum-b/depo/{name}", "wb") as f:
        f.write(os.urandom(size))
with open("gorev/bolum-b/depo/dump_02.bin", "ab") as f:
    f.write(b"\nKOD-G: 2087\n")
PYEOF

cat > gorev/bolum-b/config/httpd.conf.orig <<'EOF'
max_baglanti=50
zaman_asimi=30
EOF
cat > gorev/bolum-b/config/httpd.conf <<'EOF'
max_baglanti=9241
zaman_asimi=30
EOF

echo "KOD-I: 5563 - bu icerik tum kopyalarinda aynen gorunur." > gorev/bolum-b/belge/sozlesme.txt
ln gorev/bolum-b/belge/sozlesme.txt gorev/bolum-b/belge/sozlesme_taslak.txt
ln gorev/bolum-b/belge/sozlesme.txt gorev/bolum-b/arsiv/sozlesme_2026.txt
ln gorev/bolum-b/belge/sozlesme.txt gorev/bolum-b/yedek/sozlesme_yedek.txt
ln -s belge/sozlesme.txt gorev/bolum-b/guncel_sozlesme.txt

########## BOLUM D ##########
echo "Toplanti notlari - taslak." > gorev/bolum-d/belgeler/notlar.txt
ln -s ../belgeler/notlar.txt gorev/bolum-d/masaustu/notlarim.txt
ln gorev/bolum-d/belgeler/notlar.txt gorev/bolum-d/belgeler/notlar_yedek.txt
echo "musteri,tutar,tarih" > gorev/bolum-d/indirilenler/rapor.csv

########## BOLUM E (Gun 4: silinen/acik dosya, sikistirma, ASCII/HEX, paket yonetimi) ##########
echo "Izleme kaydi basladi." > gorev/bolum-e/canli/kayit.log
echo "KOD-K: 7734" >> gorev/bolum-e/canli/kayit.log

mkdir -p /tmp/gorev-e2-build/gizli
echo "KOD-L: 3312" > /tmp/gorev-e2-build/gizli/rapor.txt
tar -cJf gorev/bolum-e/arsiv/paket.tar.xz -C /tmp/gorev-e2-build gizli
rm -rf /tmp/gorev-e2-build

python3 - <<'PYEOF'
data = "KOD-M: 5590"
with open("gorev/bolum-e/hex/sifreli.hex", "w") as f:
    f.write(data.encode().hex() + "\n")
PYEOF

cat > gorev/bolum-e/paket/gerekli-arac.txt <<'EOF'
Bu klasordeki dosya sayisini gormek icin 'tree' araci gerekiyor, sistemde kurulu degil.
Kurup ~/gorev/bolum-e dizininin agacini cikar, kac dosya/dizin oldugunu not al.
EOF

########## BOLUM F (Gun 5: kullanici/grup, izinler, ACL, sudo, arac kullanimi) ##########
if ! id -u yedekleme &>/dev/null; then
  sudo_do useradd -r -M -s /usr/sbin/nologin yedekleme
fi
sudo_do usermod -c "Yedekleme Servis Hesabi (KOD-N:1147)" yedekleme

sudo_do tee "$HOME/gorev/bolum-f/acl/hassas.txt" >/dev/null <<'EOF'
KOD-O: 8402
EOF
sudo_do chown root:root "$HOME/gorev/bolum-f/acl/hassas.txt"
sudo_do chmod 600 "$HOME/gorev/bolum-f/acl/hassas.txt"
sudo_do setfacl -m u:ogrenci:r-- "$HOME/gorev/bolum-f/acl/hassas.txt"

sudo_do tee "$HOME/gorev/bolum-f/sahiplik/veri.txt" >/dev/null <<'EOF'
KOD-P: 2261
EOF
sudo_do chown root:root "$HOME/gorev/bolum-f/sahiplik/veri.txt"
sudo_do chmod 600 "$HOME/gorev/bolum-f/sahiplik/veri.txt"

if ! id -u raportor &>/dev/null; then
  sudo_do useradd -m -s /bin/bash raportor
fi
echo "raportor:raportor123" | sudo_do chpasswd

sudo_do tee /usr/local/bin/durum-raporu.sh >/dev/null <<'EOF'
#!/bin/bash
echo "KOD-Q: 6650"
EOF
sudo_do chmod 755 /usr/local/bin/durum-raporu.sh
sudo_do chown root:root /usr/local/bin/durum-raporu.sh

sudo_do tee /etc/sudoers.d/raportor >/dev/null <<'EOF'
raportor ALL=(root) NOPASSWD: /usr/local/bin/durum-raporu.sh
EOF
sudo_do chmod 440 /etc/sudoers.d/raportor
sudo_do visudo -c -f /etc/sudoers.d/raportor >/dev/null

cat > gorev/bolum-f/sshd/sshd_config.orig <<'EOF'
Port 22
PermitRootLogin no
PasswordAuthentication yes
EOF
cat > gorev/bolum-f/sshd/sshd_config <<'EOF'
Port 4415
PermitRootLogin no
PasswordAuthentication yes
EOF

echo "KOD-S: 7203" > gorev/bolum-f/derin/proje/arsiv/2026/yedek/kontrol/son/gizliyapilandirma.conf

echo "KOD-T: 9981" > gorev/bolum-f/web/gizli.txt

sudo_do tee /etc/systemd/system/gorev-web.service >/dev/null <<EOF
[Unit]
Description=Gorev pratik web servisi (Bolum F)
After=network.target

[Service]
Type=simple
User=ogrenci
WorkingDirectory=$HOME/gorev/bolum-f/web
ExecStart=/usr/bin/python3 -m http.server 8080
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
sudo_do systemctl daemon-reload
sudo_do systemctl enable --now gorev-web.service
sudo_do systemctl restart gorev-web.service

echo "== Gorev ortami hazir: ~/gorev/ =="
find ~/gorev -maxdepth 4 | sort
