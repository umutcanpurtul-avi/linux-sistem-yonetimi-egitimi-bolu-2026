#!/usr/bin/env bash
# Debian-Challenge VM icinde 'ogrenci' kullanicisi olarak calistirilir.
# ~/gorev/ altinda Gun 1-9 pratik senaryosunu hazirlar (idempotent).
# Senaryo:
#   Bolum A-F (Gun 1-5): onceki sistem yoneticisinden kalma dagimik bir ev
#     dizini -- dosya adlari GERCEKCI, hicbiri gorevin cevabini ele vermiyor.
#   Bolum G-L (Gun 6-9): ayni admin, calisan sunucuyu de BOZUK teslim etmis --
#     kacak surec, failed/masked servisler, bozuk cron, 8080'i kilitleyen
#     firewall, yanlis /etc/hosts kaydi, sertlestirilmemis sshd, bozuk apt deposu.
#     Bu bolumler agirlikli "teshis et + duzelt + dogrula" formatinda.
# GUVENLIK: firewall/sshd degisiklikleri ogrenci'nin 2224 uzerinden SSH erisimini
#    etkilemez (nft kurali sadece tcp/8080; sshd drop-in sadece PermitRootLogin).
set -euo pipefail
cd ~

SUDO_PASS="ogrenci123"
# 'sudo -S' stdin'den parola okur -- ama tee/chpasswd gibi komutlara heredoc/pipe
# ile GERCEK icerik de stdin uzerinden gecmesi gerektigi icin ikisi CARPISIR
# (sudo -S kendi parolasini heredoc'un icerigiyle karistirip yanlis veri yazabilir).
# Bunun yerine 'askpass' yontemi kullaniliyor: sudo parolayi AYRI bir yardimci
# programdan alir, hedef komutun (tee/chpasswd/...) stdin'ine hic dokunmaz.
ASKPASS_SCRIPT="/tmp/gorev_askpass.sh"
cat > "$ASKPASS_SCRIPT" <<EOF
#!/bin/sh
echo "$SUDO_PASS"
EOF
chmod 700 "$ASKPASS_SCRIPT"
export SUDO_ASKPASS="$ASKPASS_SCRIPT"
sudo_do() { sudo -A "$@"; }

echo "== Gerekli paketler kontrol ediliyor/kuruluyor (Bolum E/F icin) =="
# Onceki calistirmadan kalan bozuk depoyu (Bolum L3) temizle ki 'apt update' patlamasin;
# script sonunda tekrar eklenir.
sudo_do rm -f /etc/apt/sources.list.d/gorev-ekstra.list
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

echo "== Gun 6-9 paketleri (Bolum G-L icin) =="
# G/H: cron + logrotate (minimal Debian'da gelmeyebilir); I: nftables + ipcalc + netcat;
# J: dig/host/whois; K: rsync (ssh var); L: tmux. hepsi idempotent (zaten kuruluysa gecer).
sudo_do env DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
  cron logrotate nftables ipcalc netcat-openbsd bind9-dnsutils whois rsync tmux >/dev/null 2>&1 || \
  sudo_do env DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
  cron logrotate nftables ipcalc netcat-traditional dnsutils whois rsync tmux >/dev/null 2>&1 || true
sudo_do systemctl enable --now cron.service >/dev/null 2>&1 || true
sudo_do systemctl enable --now nftables.service >/dev/null 2>&1 || true

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
mkdir -p gorev/bolum-g gorev/bolum-h gorev/bolum-i gorev/bolum-j/app
mkdir -p gorev/bolum-k/veri gorev/bolum-l

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
sudo_do usermod -c "Yedekleme Servis Hesabi (KOD-N=1147)" yedekleme

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

########## BOLUM G (Gun 6: surec ve servis yonetimi) ##########
echo "== Bolum G: surec/servis senaryosu =="

# G1 -- kacak (CPU yiyen) surec. Bir servis olarak calisir ki 'ps'/'top' ile
# bulunup 'renice' edilebilsin ve durdurulunca geri gelmesin (Restart=no).
sudo_do tee /usr/local/bin/gorev-hog.sh >/dev/null <<'EOF'
#!/bin/bash
# Bilerek CPU yakan sonsuz dongu -- challenge senaryosu.
while :; do :; done
EOF
sudo_do chmod 755 /usr/local/bin/gorev-hog.sh
sudo_do tee /etc/systemd/system/gorev-hog.service >/dev/null <<'EOF'
[Unit]
Description=Gorev pratik: eski adminden kalma kacak surec (Bolum G1)
[Service]
ExecStart=/usr/local/bin/gorev-hog.sh
Nice=0
Restart=no
[Install]
WantedBy=multi-user.target
EOF

# G2 -- zombi uretici. Parent cocugu fork eder, cocuk hemen exit eder, parent
# wait() cagirmadan uyur -> cocuk 'Z' durumunda takili kalir.
sudo_do tee /usr/local/bin/gorev-zombi.py >/dev/null <<'EOF'
#!/usr/bin/env python3
import os, time
pid = os.fork()
if pid == 0:
    os._exit(0)          # cocuk: hemen olur, ama parent reap etmez
while True:
    time.sleep(3600)     # parent: wait() YOK -> cocuk zombi kalir
EOF
sudo_do chmod 755 /usr/local/bin/gorev-zombi.py
sudo_do tee /etc/systemd/system/gorev-zombi.service >/dev/null <<'EOF'
[Unit]
Description=Gorev pratik: zombi birakan hatali parent (Bolum G2)
[Service]
ExecStart=/usr/bin/python3 /usr/local/bin/gorev-zombi.py
Restart=no
[Install]
WantedBy=multi-user.target
EOF

# G3 -- 'failed' servis. ExecStart betigi /var/lib/gorev/ altina yazmaya calisir
# ama o dizin YOK -> servis baslayamaz. journalctl -u ... "No such file or directory"
# gosterir. Cozum: sudo mkdir /var/lib/gorev  (sonra servis KOD-U yazar).
sudo_do tee /usr/local/bin/gorev-rapor.sh >/dev/null <<'EOF'
#!/bin/bash
set -e
echo "KOD-U: 5218" > /var/lib/gorev/rapor.txt
echo "rapor uretildi: $(date -Is)" >> /var/lib/gorev/rapor.txt
EOF
sudo_do chmod 755 /usr/local/bin/gorev-rapor.sh
sudo_do rm -rf /var/lib/gorev            # G3'un ogretici ani icin dizin OLMAMALI
sudo_do tee /etc/systemd/system/gorev-rapor.service >/dev/null <<'EOF'
[Unit]
Description=Gorev pratik: baslamayan rapor servisi (Bolum G3)
[Service]
Type=oneshot
ExecStart=/usr/local/bin/gorev-rapor.sh
RemainAfterExit=yes
[Install]
WantedBy=multi-user.target
EOF

# G4 -- 'masked' servis. Calismasi gereken bakim servisi maskelenmis; student
# unmask + start yapinca journalctl'de KOD-V gorunur.
sudo_do tee /etc/systemd/system/gorev-bakim.service >/dev/null <<'EOF'
[Unit]
Description=Gorev pratik: maskelenmis bakim servisi (Bolum G4)
[Service]
Type=oneshot
ExecStart=/bin/sh -c 'echo "bakim tamamlandi -- KOD-V: 7791"'
[Install]
WantedBy=multi-user.target
EOF

sudo_do systemctl daemon-reload
sudo_do systemctl unmask gorev-bakim.service       >/dev/null 2>&1 || true
sudo_do systemctl enable gorev-hog.service gorev-zombi.service >/dev/null 2>&1 || true
sudo_do systemctl restart gorev-hog.service        >/dev/null 2>&1 || true
sudo_do systemctl restart gorev-zombi.service      >/dev/null 2>&1 || true
sudo_do systemctl stop gorev-rapor.service         >/dev/null 2>&1 || true   # onceki basarili durumu geri al
sudo_do systemctl start gorev-rapor.service        >/dev/null 2>&1 || true   # bilerek FAIL eder (dizin yok)
sudo_do systemctl disable gorev-bakim.service      >/dev/null 2>&1 || true
sudo_do systemctl mask gorev-bakim.service         >/dev/null 2>&1 || true

########## BOLUM H (Gun 6: log, cron, logrotate) ##########
echo "== Bolum H: log/cron senaryosu =="

# H1 -- journald'e yazilan kritik hata. Bir oneshot servis her boot'ta bu hatayi
# loglar; student 'journalctl -p err -b | grep GOREV' ile KOD-W'yi bulur.
sudo_do tee /etc/systemd/system/gorev-hatali.service >/dev/null <<'EOF'
[Unit]
Description=Gorev pratik: boot'ta kritik hata loglayan servis (Bolum H1)
After=systemd-journald.service
[Service]
Type=oneshot
ExecStart=/usr/bin/logger -p daemon.err -t gorev-app "GOREV kritik: uygulama baslatilamadi, KOD-W: 4419"
[Install]
WantedBy=multi-user.target
EOF
sudo_do systemctl daemon-reload
sudo_do systemctl enable gorev-hatali.service >/dev/null 2>&1 || true
sudo_do systemctl start  gorev-hatali.service >/dev/null 2>&1 || true   # kaydi her calistirmada tazele

# H2 -- bozuk cron.d job. Sozdizimi DOGRU ama betik yolu YANLIS
# (/usr/local/bin/... yerine dogrusu /opt/gorev/...). Cron her dakika den/er,
# 'journalctl -u cron' / /var/log/syslog "No such file or directory" gosterir.
sudo_do mkdir -p /opt/gorev
sudo_do tee /opt/gorev/gunluk-rapor.sh >/dev/null <<'EOF'
#!/bin/bash
echo "KOD-X: 6127  ($(date -Is))" >> /home/ogrenci/gorev/bolum-h/rapor-cikti.txt
EOF
sudo_do chmod 755 /opt/gorev/gunluk-rapor.sh
sudo_do chown ogrenci:ogrenci /opt/gorev/gunluk-rapor.sh
: > gorev/bolum-h/rapor-cikti.txt
sudo_do tee /etc/cron.d/gorev-rapor >/dev/null <<'EOF'
# Gorev pratik: gunluk rapor (Bolum H2) -- YANLIS YOL, student duzeltecek
* * * * * ogrenci /usr/local/bin/gunluk-rapor.sh
EOF
sudo_do chmod 644 /etc/cron.d/gorev-rapor

# H3 -- rotasyon kurulmamis, buyumus log dosyasi. Student /etc/logrotate.d/ altina
# kural yazip 'logrotate -d' (kuru) ve 'logrotate -f' ile test edecek.
sudo_do bash -c 'yes "$(date -Is) INFO gorev-app istek islendi ref=$RANDOM" | head -n 40000 > /var/log/gorev-app.log' || true
sudo_do chown root:adm /var/log/gorev-app.log 2>/dev/null || true
sudo_do chmod 640 /var/log/gorev-app.log
sudo_do rm -f /etc/logrotate.d/gorev-app   # kural YOK -- student yazacak

########## BOLUM I (Gun 7: ag temelleri, ss, firewall) ##########
echo "== Bolum I: ag/firewall senaryosu =="

# I4 -- nftables kurali 8080'i DROP ediyor. Izole bir tabloda (inet gorev_fw),
# SADECE tcp dport 8080 -- port 22/2224'e ASLA dokunmaz. Bir servis her boot'ta
# kurali uygular ki challenge oturumlar arasi dayansin; cozum = servisi durdur +
# tabloyu sil.
sudo_do tee /usr/local/bin/gorev-fw.sh >/dev/null <<'EOF'
#!/bin/sh
# Gorev pratik (Bolum I4): sadece 8080'i engelleyen izole kural.
nft delete table inet gorev_fw 2>/dev/null || true
nft add table inet gorev_fw
nft 'add chain inet gorev_fw giris { type filter hook input priority 0 ; }'
nft add rule inet gorev_fw giris tcp dport 8080 drop
EOF
sudo_do chmod 755 /usr/local/bin/gorev-fw.sh
sudo_do tee /etc/systemd/system/gorev-fw.service >/dev/null <<'EOF'
[Unit]
Description=Gorev pratik: 8080'i engelleyen firewall kurali (Bolum I4)
After=nftables.service
[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/local/bin/gorev-fw.sh
ExecStop=/bin/sh -c '/usr/sbin/nft delete table inet gorev_fw 2>/dev/null || true'
[Install]
WantedBy=multi-user.target
EOF
sudo_do systemctl daemon-reload
sudo_do systemctl enable gorev-fw.service >/dev/null 2>&1 || true
sudo_do systemctl restart gorev-fw.service >/dev/null 2>&1 || true   # kurali her calistirmada yeniden uygula

cat > gorev/bolum-i/BILGI.txt <<'EOF'
Bu bolumde sabit KOD yok -- kendi urettigin degerleri (arayuz adi, IP/prefix,
gateway, network/broadcast adresi, dinleyen port sayisi, nc sonuclari) kaydet.
I4'ten sonra 'curl http://localhost:8080/gizli.txt' tekrar calismali (KOD-T).
EOF

########## BOLUM J (Gun 8: /etc/hosts, nsswitch, dig) ##########
echo "== Bolum J: isim cozumleme senaryosu =="

# Ic API servisi: sadece 127.0.0.1:8090, bolum-j/app/ dizinini servis eder.
echo '{ "durum": "ok", "kod": "KOD-Y: 8863" }' > gorev/bolum-j/app/durum.json
echo "KOD-AA: 3074" > gorev/bolum-j/app/tunel.txt   # Bolum K3: sadece localhost'a bagli servise ssh -L tuneli
sudo_do tee /etc/systemd/system/gorev-api.service >/dev/null <<EOF
[Unit]
Description=Gorev pratik ic API (Bolum J) -- sadece localhost:8090
After=network.target
[Service]
Type=simple
User=ogrenci
WorkingDirectory=$HOME/gorev/bolum-j/app
ExecStart=/usr/bin/python3 -m http.server 8090 --bind 127.0.0.1
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOF
sudo_do systemctl daemon-reload
sudo_do systemctl enable --now gorev-api.service >/dev/null 2>&1 || true

# Uygulamanin DB/API'yi cagirdigi betik -- host adi ile.
cat > gorev/bolum-j/app/kontrol.sh <<'EOF'
#!/bin/bash
# Uygulama, bagimliligini HOST ADI ile arar (IP ile degil).
echo "api.local.gorev adresine baglaniliyor..."
curl -sS --max-time 5 "http://api.local.gorev:8090/durum.json" || {
  echo "BAGLANTI BASARISIZ -- isim cozumleme / erisim sorunu?"
  exit 1
}
EOF
chmod +x gorev/bolum-j/app/kontrol.sh

# /etc/hosts'a YANLIS kayit (idempotent: once temizle, sonra ekle).
sudo_do sed -i '/api\.local\.gorev/d' /etc/hosts
echo "10.0.0.250   api.local.gorev   # Gorev pratik Bolum J -- bu IP YANLIS" | sudo_do tee -a /etc/hosts >/dev/null

########## BOLUM K (Gun 9: SSH) ##########
echo "== Bolum K: SSH senaryosu =="

if ! id -u sshtest &>/dev/null; then
  sudo_do useradd -m -s /bin/bash sshtest
fi
echo "sshtest:sshtest123" | sudo_do chpasswd
sudo_do install -d -m 700 -o sshtest -g sshtest /home/sshtest/.ssh
echo "KOD-Z: 4930" | sudo_do tee /home/sshtest/kod.txt >/dev/null
sudo_do chown sshtest:sshtest /home/sshtest/kod.txt

# K4 icin: rsync ile aktarilacak ornek veri
echo "musteri kaydi 1" > gorev/bolum-k/veri/kayit1.txt
echo "musteri kaydi 2" > gorev/bolum-k/veri/kayit2.txt
head -c 4096 /dev/urandom > gorev/bolum-k/veri/blob.bin

# K2 -- sshd sertlestirmesi. Drop-in dosyada KOTU ayar: PermitRootLogin yes.
# ogrenci'nin 2224 uzerinden erisimi bundan ETKILENMEZ.
sudo_do mkdir -p /etc/ssh/sshd_config.d
sudo_do tee /etc/ssh/sshd_config.d/60-gorev.conf >/dev/null <<'EOF'
# Gorev pratik (Bolum K2): eski adminden kalma GUVENSIZ ayar -- student duzeltecek.
PermitRootLogin yes
EOF
# sozdizimi bozuk degil, sadece politika kotu; sshd calismaya devam eder.
sudo_do sshd -t 2>/dev/null && sudo_do systemctl reload ssh 2>/dev/null || true

########## BOLUM L (Gun 9: dd, oto-baslatma, apt repo, tmux, alias) ##########
echo "== Bolum L: dd / repo / tmux senaryosu =="

# L1 icin bilgi (dd ile /dev/sda ilk sektorunun son 2 baytini okuyacak: 55 aa)
cat > gorev/bolum-l/BILGI.txt <<'EOF'
L1: 'dd' ile /dev/sda'nin ILK sektorunu (512 bayt) okuyup son 2 baytina bak
    (xxd | tail). Bu "boot signature" degeri nedir? (ipucu: 55 aa)
L2: 'systemctl is-enabled gorev-web' ve enable'in /etc/systemd/system/
    <target>.wants/ altinda ac/tigi symlink'i bul.
L4: uzun surecek bir isi 'tmux' oturumunda baslat, detach et, SSH'i kapat,
    yeniden baglan, attach et -- is hala calisiyor mu?
EOF

# L3 -- bozuk apt deposu. 'apt update' cozumlenemeyen bir URL'de hata verir.
sudo_do tee /etc/apt/sources.list.d/gorev-ekstra.list >/dev/null <<'EOF'
# Gorev pratik (Bolum L3): eski adminden kalma, artik var olmayan depo.
deb http://apt.olmayan.gorev/debian trixie main
EOF

rm -f "$ASKPASS_SCRIPT"

echo
echo "== Gorev ortami hazir: ~/gorev/ (Bolum A-L) =="
echo "-- Bolum G-L servis durumu (senaryo bilerek bozuk olabilir) --"
for u in gorev-hog gorev-zombi gorev-api gorev-fw gorev-web gorev-rapor gorev-bakim; do
  printf '  %-14s %s\n' "$u" "$(systemctl is-active "$u" 2>/dev/null || true)/$(systemctl is-enabled "$u" 2>/dev/null || true)"
done
echo
find ~/gorev -maxdepth 3 | sort
