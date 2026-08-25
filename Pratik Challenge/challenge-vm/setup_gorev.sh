#!/usr/bin/env bash
# Debian-Challenge VM icinde 'ogrenci' kullanicisi olarak calistirilir.
# ~/gorev/ altinda Gun 1-3 pratik senaryosunu hazirlar (idempotent).
# Senaryo: onceki sistem yoneticisinden kalma dagimik bir ev dizini --
# dosya adlari GERCEKCI, hicbiri gorevin cevabini ele vermiyor.
set -euo pipefail
cd ~
rm -rf gorev
mkdir -p gorev/bolum-a/yedekler gorev/bolum-a/env
mkdir -p gorev/bolum-a/projeler/web-app gorev/bolum-a/projeler/veritabani
mkdir -p gorev/bolum-a/projeler/api-servisi/gelistirme gorev/bolum-a/projeler/api-servisi/uretim
mkdir -p gorev/bolum-b/loglar gorev/bolum-b/ayarlar gorev/bolum-b/depo
mkdir -p gorev/bolum-b/config gorev/bolum-b/belge gorev/bolum-b/arsiv gorev/bolum-b/yedek
mkdir -p gorev/bolum-d/belgeler gorev/bolum-d/masaustu gorev/bolum-d/indirilenler gorev/bolum-d/harici

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

echo "== Gorev ortami hazir: ~/gorev/ =="
find ~/gorev -maxdepth 4 | sort
