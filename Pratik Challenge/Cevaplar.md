---
tags:
  - egitim/linux-sistem-yonetimi
tarih: 2026-08-24
konular:
  - Gün 1-9 Pratik Challenge cevap anahtarı
---

# Gün 1-9 Pratik Challenge — Cevaplar

Bağlantı: [Sorular](Sorular.md)

> [!WARNING]
> **Bu dosya, [Sorular](Sorular.md) dosyasındaki görevlerin tam çözümlerini içerir. Önce kendin çözmeyi dene, önce İpucu'ya bak, buraya sadece gerçekten takıldığında gel.**

## Bölüm A

**A1.**
```bash
cat ~/gorev/bolum-a/yedekler/rapor_2026.txt   # Permission denied
ls -l ~/gorev/bolum-a/yedekler/rapor_2026.txt  # ---------- , hiçbir izin biti yok
chmod u+r ~/gorev/bolum-a/yedekler/rapor_2026.txt
cat ~/gorev/bolum-a/yedekler/rapor_2026.txt    # KOD-A: 4471
```

**A2.**
```bash
ls -a ~/gorev/bolum-a/env/
cat ~/gorev/bolum-a/env/.env       # KOD-B=8825
```

**A3.**
```bash
~/gorev/bolum-a/calistir.sh 1> basarili.log 2> hatali.log
cat basarili.log
cat hatali.log
```

**A4.**
```bash
ls -ld ~/gorev/bolum-a/projeler/*
# api-servisi: link=4 (icinde 2 alt dizin var), digerleri link=2
cat ~/gorev/bolum-a/projeler/api-servisi/ozet.txt   # KOD-J: 6604
```

**A5.**
```bash
wc -l ~/gorev/bolum-a/erisim.log          # 500
head -n 250 ~/gorev/bolum-a/erisim.log | tail -n 1   # 250. satır, hedefe göre kıyasla, daralt
head -n 214 ~/gorev/bolum-a/erisim.log | tail -n 1
# 0214 ARANAN-SATIR: KOD-C-9183
```

**A6.**
```bash
cat ~/gorev/bolum-a/giris_kontrol.sh
# if [ "$ANAHTAR" = "acilsin" ] ... görülüyor

ANAHTAR=acilsin ~/gorev/bolum-a/giris_kontrol.sh   # KOD-D: 3390
echo $ANAHTAR                                       # boş — kalıcı olmadı
```

## Bölüm B

**B1.**
```bash
grep -ri "hata" ~/gorev/bolum-b/loglar/ | grep -vi "test-ortami"
# app-worker.log:HATA: KOD-E-7724 - uretim ortaminda kritik hata
```

**B2.**
```bash
find ~/gorev/bolum-b/ayarlar -name "*.conf" -mmin -60
cat ~/gorev/bolum-b/ayarlar/samba.conf   # ... KOD-F: 6157
```

**B3.**
```bash
find ~/gorev/bolum-b/depo -size +100k -size -1024k   # -size -1M KULLANMA (yuvarlama tuzağı)
tail -c 100 ~/gorev/bolum-b/depo/dump_02.bin   # ...KOD-G: 2087
```

**B4.**
```bash
diff -u ~/gorev/bolum-b/config/httpd.conf.orig ~/gorev/bolum-b/config/httpd.conf
# -max_baglanti=50
# +max_baglanti=9241   -> KOD-H: 9241
```

**B5.**
```bash
find ~/gorev/bolum-b -samefile ~/gorev/bolum-b/belge/sozlesme.txt
# belge/sozlesme.txt, belge/sozlesme_taslak.txt, arsiv/sozlesme_2026.txt, yedek/sozlesme_yedek.txt

find ~/gorev/bolum-b -type l -lname '*sozlesme.txt*'
# guncel_sozlesme.txt -> belge/sozlesme.txt

cat ~/gorev/bolum-b/belge/sozlesme.txt   # KOD-I: 5563
```

## Bölüm C

**C1.**
```bash
lsblk
lsblk -f
```

**C2.**
```bash
sudo fdisk /dev/sdb   # g (gpt), n (yeni bölüm), w (yaz)
sudo mkfs.ext4 /dev/sdb1
sudo blkid /dev/sdb1   # UUID="..."
```

**C3.**
```bash
mkdir -p ~/gorev/bolum-c/veri
sudo mount /dev/sdb1 ~/gorev/bolum-c/veri
df -h ~/gorev/bolum-c/veri   # Avail sütunu
```

**C4.**
```bash
echo "test" > ~/gorev/bolum-c/veri/deneme.txt
sudo umount ~/gorev/bolum-c/veri
ls ~/gorev/bolum-c/veri        # boş görünür
sudo mount /dev/sdb1 ~/gorev/bolum-c/veri
ls ~/gorev/bolum-c/veri        # deneme.txt geri geldi
```

**C5.**
Görünmez — mount, altındaki dizin girdisini erişilemez kılar (silmez). Görmek için:
```bash
sudo mkdir -p /mnt/gecici
sudo mount /dev/sda1 /mnt/gecici   # kök bölümü ikinci bir noktaya bağla
cat /mnt/gecici/home/ogrenci/gorev/bolum-c/veri/notum.txt
sudo umount /mnt/gecici
```

**C6.**
```bash
stat ~/gorev/bolum-c/veri/deneme.txt          # Inode: N
mv ~/gorev/bolum-c/veri/deneme.txt ~/gorev/bolum-c/veri/deneme2.txt
stat ~/gorev/bolum-c/veri/deneme2.txt         # Inode: aynı N
```

**C7.**
```bash
df -i ~/gorev/bolum-c/veri
df -i /
```
İnode sayısı `mkfs` sırasında disk boyutuna göre hesaplanıp sabitlenir — küçük disk küçük inode havuzu demektir.

**C8.**
```bash
sudo umount ~/gorev/bolum-c/veri
sudo fdisk /dev/sdb   # d (sil), w (yaz)
lsblk -f              # sdb1 satırı ve dosya sistemi kayboldu
```

## Bölüm D

**D1.**
```bash
ls -l ~/gorev/bolum-d/masaustu/notlarim.txt   # l ile başlar, -> ../belgeler/notlar.txt (symlink)
readlink ~/gorev/bolum-d/masaustu/notlarim.txt   # ../belgeler/notlar.txt (hedef metni, taşımadan önce)

mv ~/gorev/bolum-d/belgeler/notlar.txt ~/gorev/bolum-d/harici/
cat ~/gorev/bolum-d/masaustu/notlarim.txt   # "No such file or directory" — kırıldı
```
Symlink'in içeriği hiç değişmedi (`readlink` hâlâ aynı metni verir), ama hedef taşındığı için artık karşılığı yok.

**D2.**
```bash
mv ~/gorev/bolum-d/harici/notlar.txt ~/gorev/bolum-d/belgeler/
mv ~/gorev/bolum-d/masaustu/notlarim.txt ~/gorev/bolum-d/
cat ~/gorev/bolum-d/notlarim.txt   # yine kırık — artık ../belgeler/notlar.txt, bolum-d'nin bir üstünü arıyor
readlink ~/gorev/bolum-d/notlarim.txt   # metin aynı: ../belgeler/notlar.txt — ama artık farklı bir yerden çözülüyor
```

**D3.**
```bash
ls -i ~/gorev/bolum-d/belgeler/notlar.txt ~/gorev/bolum-d/belgeler/notlar_yedek.txt   # aynı inode -> hardlink
ls -l ~/gorev/bolum-d/belgeler/notlar.txt      # once: -rw-rw-r--
chmod 600 ~/gorev/bolum-d/belgeler/notlar_yedek.txt
ls -l ~/gorev/bolum-d/belgeler/notlar.txt      # sonra: -rw------- (DEĞİŞTİ — aynı inode, aynı izin)
```

**D4.**
```bash
stat ~/gorev/bolum-d/indirilenler/rapor.csv   # Device/Inode not al
mv ~/gorev/bolum-d/indirilenler/rapor.csv ~/gorev/bolum-d/indirilenler/rapor2.csv
stat ~/gorev/bolum-d/indirilenler/rapor2.csv  # aynı Device/Inode

mv ~/gorev/bolum-d/indirilenler/rapor2.csv ~/gorev/bolum-c/veri/
stat ~/gorev/bolum-c/veri/rapor2.csv          # Device VE Inode değişti
```
Aynı disk içinde `mv` sadece dizin girdisini günceller (anlık); farklı diske `mv` içeride kopyala-sil yapar (dosya boyutuyla orantılı sürer).

**D5.**
```bash
ls -l /dev | grep "^b" | wc -l   # blok aygıtları
ls -l /dev | grep "^c" | wc -l   # karakter aygıtları
```
`mkfs` sadece blok aygıtların üzerinde çalışabilir.

**D6.**
```bash
sudo fdisk -l /dev/sdb    # Disklabel type: gpt
sudo parted /dev/sdb print   # Partition Table: gpt
```

**D7.**
```bash
ldd /bin/ls   # libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6

LD_LIBRARY_PATH=/tmp/olmayan-bir-yer ldd /bin/ls   # yol AYNI kaldı
```
`LD_LIBRARY_PATH` sadece önce aranacak EK bir yer ekler, var olan gerçek kütüphaneyi silmez/gizlemez.

**D8.**
```bash
stat /proc/cpuinfo   # Size: 0
cat /proc/cpuinfo | head -5
ls /sys/class/net/
```
`/proc` ve `/sys` diskte gerçek dosyalar değil — kernel'in o anki durumunu dosya arayüzüyle sunan sanal dosya sistemleridir, bu yüzden boyutları `0` görünür.

## Bölüm E

**E1.**
```bash
tail -f ~/gorev/bolum-e/canli/kayit.log &
# [1] 12345
rm ~/gorev/bolum-e/canli/kayit.log
ls -l /proc/12345/fd/
# lr-x------ 1 ogrenci ogrenci 64 ... 3 -> /home/ogrenci/gorev/bolum-e/canli/kayit.log (deleted)
cat /proc/12345/fd/3   # KOD-K: 7734
kill %1
```

**E2.**
```bash
tar -tf ~/gorev/bolum-e/arsiv/paket.tar.xz    # gizli/rapor.txt görünür
tar -xf ~/gorev/bolum-e/arsiv/paket.tar.xz -C ~/gorev/bolum-e/arsiv/
cat ~/gorev/bolum-e/arsiv/gizli/rapor.txt     # KOD-L: 3312
```

**E3.**
```bash
cat ~/gorev/bolum-e/hex/sifreli.hex
xxd -r -p ~/gorev/bolum-e/hex/sifreli.hex     # KOD-M: 5590
```

**E4.**
```bash
which tree             # boş, kurulu değil
sudo apt update
sudo apt install -y tree
tree ~/gorev/bolum-e    # çıktının en altındaki "X directories, Y files" satırı — kendi ürettiğin değer
```

## Bölüm F

**F1.**
```bash
cat /etc/passwd | grep yedekleme
# yedekleme:x:<uid>:<gid>:Yedekleme Servis Hesabi (KOD-N=1147):/nonexistent:/usr/sbin/nologin
```

**F2.**
```bash
cat ~/gorev/bolum-f/acl/hassas.txt   # yine de okunabiliyor (ACL sayesinde)
ls -l ~/gorev/bolum-f/acl/hassas.txt
# -rw-r-----+ 1 root root ... hassas.txt   -> sondaki '+' ek ACL kuralı olduğunu gösterir
getfacl ~/gorev/bolum-f/acl/hassas.txt
# user:ogrenci:r--   <- klasik owner/group/other'ın dışında, sana özel tanımlanmış izin
# KOD-O: 8402
```

**F3.**
```bash
ls -l ~/gorev/bolum-f/sahiplik/veri.txt   # -rw------- root root
sudo chown ogrenci:ogrenci ~/gorev/bolum-f/sahiplik/veri.txt
chmod 600 ~/gorev/bolum-f/sahiplik/veri.txt
cat ~/gorev/bolum-f/sahiplik/veri.txt     # KOD-P: 2261
```

**F4.**
```bash
su - raportor
# Password: raportor123
sudo -l
# User raportor may run: (root) NOPASSWD: /usr/local/bin/durum-raporu.sh
sudo /usr/local/bin/durum-raporu.sh   # KOD-Q: 6650

sudo whoami
# Sorry, user raportor is not allowed to execute '/usr/bin/whoami' as root...
sudo cat /etc/shadow
# aynı şekilde reddedilir — sudoers kuralı yalnızca TEK bir tam komutu kapsıyor
```

**F5.**
```bash
diff -u ~/gorev/bolum-f/sshd/sshd_config.orig ~/gorev/bolum-f/sshd/sshd_config
# -Port 22
# +Port 4415   -> KOD-R: 4415
```

**F6.**
```bash
locate gizliyapilandirma.conf     # ilk denemede SONUÇ YOK — indeks güncel değil
sudo updatedb
locate gizliyapilandirma.conf     # şimdi tam yol görünür
cat <bulunan_yol>                 # KOD-S: 7203
```

**F7.**
```bash
curl http://localhost:8080/gizli.txt        # KOD-T: 9981, ekrana basılır
wget -O indirilen.txt http://localhost:8080/gizli.txt
cat indirilen.txt                            # aynı içerik, bu sefer diskte
```

## Bölüm G — Süreç ve Servis Yönetimi (Gün 6)

**G1.**
```bash
top                                  # P ile CPU'ya sırala — gorev-hog.sh %100
ps aux --sort=-%cpu | head -3
# ogrenci ... /usr/local/bin/gorev-hog.sh  (bir bash döngüsü)
systemctl status <PID>               # -> gorev-hog.service
sudo renice -n 19 -p <PID>           # önce önceliği düşür (sistem nefes alsın)
ps -o pid,ni,comm -p <PID>           # NI: 19 doğrula
sudo systemctl stop gorev-hog.service
sudo systemctl disable gorev-hog.service
systemctl is-active gorev-hog.service    # inactive — geri gelmedi
```
`Restart=no` olduğu için `stop` yeter; `disable` bir sonraki boot'ta da başlamamasını sağlar.

**G2.**
```bash
ps -eo pid,ppid,stat,comm | awk '$3 ~ /Z/'
#  <zpid>  <ppid>  Z+  python3 <defunct>
sudo kill -9 <zpid>          # HİÇBİR ETKİSİ YOK — zombi zaten ölü, çalışan kod yok
ps -p <ppid> -o pid,comm     # parent: python3  (gorev-zombi.py)
systemctl status <ppid>      # -> gorev-zombi.service
sudo systemctl restart gorev-zombi.service   # parent yeniden başlar, eski çocuğu init reap eder
ps -eo pid,ppid,stat,comm | awk '$3 ~ /Z/'   # artık zombi yok
# (kalıcı olarak istemiyorsan: sudo systemctl stop --now gorev-zombi.service && disable)
```
Zombi = `exit()` etmiş ama parent'ı `wait()` çağırmadığı için process tablosunda PID+çıkış kodu olarak duran kayıt. Sinyal alacak canlı bir şey yok; çare parent'ı `wait()`'e zorlamak (= restart) ya da parent ölünce PID 1'in devralıp reap etmesi.

**G3.**
```bash
systemctl status gorev-rapor.service
journalctl -u gorev-rapor.service -n 20
# ... gorev-rapor.sh: /var/lib/gorev/rapor.txt: No such file or directory
systemctl cat gorev-rapor.service       # ExecStart=/usr/local/bin/gorev-rapor.sh
cat /usr/local/bin/gorev-rapor.sh       # /var/lib/gorev/ altına yazıyor — o dizin yok
sudo mkdir -p /var/lib/gorev
sudo systemctl start gorev-rapor.service
systemctl is-active gorev-rapor.service  # active
sudo cat /var/lib/gorev/rapor.txt        # KOD-U: 5218
```

**G4.**
```bash
sudo systemctl start gorev-bakim.service
# Failed to start ...: Unit gorev-bakim.service is masked.
sudo systemctl unmask gorev-bakim.service
sudo systemctl start gorev-bakim.service
journalctl -u gorev-bakim.service -n 5
# ... bakim tamamlandi -- KOD-V: 7791
```

**G5.**
```bash
sudo ss -tlnp
# LISTEN 0 5   0.0.0.0:8080  ... users:(("python3",pid=<A>,fd=3))   -> gorev-web.service
# LISTEN 0 5   127.0.0.1:8090 ... users:(("python3",pid=<B>,...))   -> gorev-api.service
# LISTEN ...   0.0.0.0:22     ... sshd
systemctl status <A> <B>     # servis adlarını doğrula
```
8090 sadece `127.0.0.1`'e bağlı (dışarıdan erişilemez), 8080 tüm arayüzlerde.

## Bölüm H — Log, Cron, Log Rotasyonu (Gün 6)

**H1.**
```bash
journalctl -p err -b | grep -i gorev
# ... gorev-app[..]: GOREV kritik: uygulama baslatilamadi, KOD-W: 4419
journalctl -t gorev-app -p err        # etikete göre de bulunur
```

**H2.**
```bash
journalctl -u cron --since "5 min ago"
# ... CRON[..]: (ogrenci) CMD (/usr/local/bin/gunluk-rapor.sh)   <- her dakika DENIYOR
# ... CRON[..]: (CRON) info (No MTA installed, discarding output)  <- komut hata veriyor, cikti yok
ls -l /usr/local/bin/gunluk-rapor.sh   # yok
cat /etc/cron.d/gorev-rapor
# * * * * * ogrenci /usr/local/bin/gunluk-rapor.sh   <- yol yanlış
sudo find / -name gunluk-rapor.sh 2>/dev/null   # -> /opt/gorev/gunluk-rapor.sh
sudo sed -i 's#/usr/local/bin/gunluk-rapor.sh#/opt/gorev/gunluk-rapor.sh#' /etc/cron.d/gorev-rapor
# ~1-2 dk bekle
cat ~/gorev/bolum-h/rapor-cikti.txt   # KOD-X: 6127  (2026-...)
```
`journalctl -u cron` cron'un her dakika CMD'yi denediğini gösterir; komut bulunamadığı için çıktı üretilmez ("No MTA installed, discarding output"). `/etc/cron.d/*` dosyalarında (kullanıcı crontab'ından farklı olarak) komuttan önce **kullanıcı alanı** vardır (`ogrenci`).

**H3.**
```bash
sudo tee /etc/logrotate.d/gorev-app >/dev/null <<'EOF'
/var/log/gorev-app.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 0640 root adm
}
EOF
sudo logrotate -d /etc/logrotate.d/gorev-app     # kuru çalıştırma — ne yapacağını anlatır
sudo logrotate -f /etc/logrotate.d/gorev-app     # zorla rotasyon
ls -l /var/log/gorev-app.log*
# gorev-app.log    (0 bayt, yeni)
# gorev-app.log.1  (eski içerik; delaycompress yüzünden henüz .gz değil)
```

**H4.**
```bash
last -a
# ogrenci  pts/0  ...  10.0.2.2   (VirtualBox NAT gateway'i = SSH kaynağı)
last -a ogrenci | grep -c "still logged in\|pts"   # bu boottaki oturum sayısı
journalctl -u ssh | grep "Accepted"                # aynı bilgi sshd tarafından
```
`10.0.2.2`, VirtualBox NAT'ın host tarafını temsil eder — `ssh -p 2224` bağlantıların hepsi oradan görünür.

## Bölüm I — Ağ, Soket İstatistiği, Firewall (Gün 7)

**I1.**
```bash
ip -brief address
# enp0s3   UP   10.0.2.15/24 ...
ip route
# default via 10.0.2.2 dev enp0s3 ...   -> gateway 10.0.2.2
```
(Arayüz adı VBox sürümüne göre `enp0s3` / `eth0` olabilir.)

**I2.** `10.0.2.15/24` için:
```bash
ipcalc 10.0.2.15/24
# Network:   10.0.2.0/24
# HostMin:   10.0.2.1
# HostMax:   10.0.2.254
# Broadcast: 10.0.2.255
# Hosts/Net: 254
```
Elle: /24 → son oktet host kısmı. Network `.0`, broadcast `.255`, kullanılabilir `.1`–`.254`, toplam `2^8 - 2 = 254`.

**I3.**
```bash
curl --max-time 3 http://localhost:8080/gizli.txt   # takılır / Connection timed out
sudo nft list ruleset
# table inet gorev_fw {
#   chain giris { type filter hook input priority 0; policy accept;
#     tcp dport 8080 drop
#   }
# }
sudo systemctl stop gorev-fw.service      # ExecStop tabloyu siler
sudo systemctl disable gorev-fw.service   # bir daha uygulanmasın
# (ya da tek seferlik: sudo nft delete table inet gorev_fw)
curl http://localhost:8080/gizli.txt      # KOD-T: 9981
```
Kural yalnızca `tcp dport 8080` — 22/2224 ve diğer her şey `policy accept`, etkilenmez.

**I4.**
```bash
nc -zv localhost 8080   # I3'ten ÖNCE: timed out / refused   — SONRA: succeeded
nc -zv localhost 22     # succeeded (sshd dinliyor)
nc -zv localhost 9999   # Connection refused (kimse dinlemiyor)
```

**I5.**
```bash
ping -c3 10.0.2.2                 # gateway'e ICMP — cevap gelir
traceroute 10.0.2.2              # tek atlama (doğrudan komşu)
ping -c2 1.1.1.1                 # IP ile — çalışırsa yönlendirme/bağlantı sağlam
ping -c2 debian.org             # isimle — burada takılıp IP'de çalışıyorsa sorun DNS'tir
```
IP'ye ping çalışıp isme çalışmıyorsa: bağlantı/yönlendirme sağlam, **isim çözümleme** bozuk (`/etc/resolv.conf`, `systemd-resolved`, `/etc/nsswitch.conf`). Her ikisi de çalışmıyorsa yönlendirme/gateway ya da firewall.

## Bölüm J — İsim Çözümleme (Gün 8)

**J1.**
```bash
~/gorev/bolum-j/app/kontrol.sh
# api.local.gorev adresine baglaniliyor... BAGLANTI BASARISIZ
getent hosts api.local.gorev
# 10.0.0.250   api.local.gorev        <- bu IP yanlış (bu ağda değil)
dig api.local.gorev +short
# (boş — DNS'te yok, demek ki cevap /etc/hosts'tan geliyor)
grep api.local.gorev /etc/hosts
# 10.0.0.250   api.local.gorev   # ... bu IP YANLIS
sudo ss -tlnp | grep 8090        # gerçek API: 127.0.0.1:8090
sudo sed -i 's/^10\.0\.0\.250\s\+api\.local\.gorev.*/127.0.0.1   api.local.gorev/' /etc/hosts
~/gorev/bolum-j/app/kontrol.sh
# { "durum": "ok", "kod": "KOD-Y: 8863" }
```

**J2.**
```bash
grep '^hosts:' /etc/nsswitch.conf
# hosts:  files dns
```
`files` = `/etc/hosts`, `dns` = yapılandırılmış DNS sunucuları. Sıra soldan sağa: `/etc/hosts`'ta bir eşleşme bulunursa DNS'e **hiç gidilmez**. J1'de yanlış da olsa bir cevap dönmesinin nedeni buydu — `files` katmanı `10.0.0.250` diyordu.

**J3.** (internet varsa)
```bash
dig google.com A +short        # bir/birkaç A kaydı (IP)
dig google.com MX +short       # mail sunucuları, öncelik sayısıyla
dig -x 1.1.1.1 +short          # one.one.one.one.  (PTR — ters kayıt)
dig @9.9.9.9 debian.org +short # belirli bir resolver'a sor
dig debian.org | sed -n '/ANSWER SECTION/,/^$/p'   # TTL sütunu = 2. alan
```
İnternet yoksa: `dig api.local.gorev` → `status: NXDOMAIN` — yani bu isim gerçekten DNS'te yok, sadece `/etc/hosts`'ta (J1/J2'nin doğrulaması).

**J4.** (internet varsa)
```bash
host 1.1.1.1                    # 1.1.1.1.in-addr.arpa domain name pointer one.one.one.one
whois debian.org | grep -iE 'registrar|creation'
```

## Bölüm K — SSH (Gün 9)

**K1.**
```bash
ssh-keygen -t ed25519 -f ~/.ssh/gorev_key -N ''
ssh-copy-id -i ~/.ssh/gorev_key.pub sshtest@localhost      # bir kez sshtest123 sorar
ssh -i ~/.ssh/gorev_key sshtest@localhost 'cat ~/kod.txt'  # KOD-Z: 4930 — parola SORMADAN
```
`ssh-copy-id`, açık anahtarı hedefin `~/.ssh/authorized_keys` dosyasına ekler; sonraki bağlantılarda sunucu bu anahtarla kimlik doğrular.

**K2.**
```bash
cat /etc/ssh/sshd_config.d/60-gorev.conf     # PermitRootLogin yes
sudo sed -i 's/^PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config.d/60-gorev.conf
sudo sshd -t && echo "sözdizimi OK"
sudo systemctl reload ssh
sudo sshd -T | grep -i permitrootlogin        # permitrootlogin no   <- etkin değer
```
`sshd -T` tüm drop-in'ler birleştirilmiş **efektif** yapılandırmayı verir. `ogrenci`'nin `2224` bağlantısı parola/anahtarla, root olmayan kullanıcı olarak devam eder — etkilenmez.

**K3.**
```bash
curl --max-time 2 http://localhost:8090/tunel.txt   # doğrudan da çalışır (aynı makinedeyiz)
                                                     # ama servis 127.0.0.1'e bağlı — başka makineden erişilemez
ssh -i ~/.ssh/gorev_key -L 9090:127.0.0.1:8090 -N -f sshtest@localhost
curl http://localhost:9090/tunel.txt          # KOD-AA: 3074  (tünel üzerinden)
pgrep -af 'ssh .*9090' ; kill <pid>           # tüneli kapat
```
`-L 9090:127.0.0.1:8090`: yerel `9090`'a gelen trafiği SSH bağlantısı üzerinden karşı uçta `127.0.0.1:8090`'e ilet. Gerçek senaryoda `sshtest@localhost` yerine uzak bir sunucu olurdu ve bu, o sunucunun yalnızca kendi loopback'inde dinleyen bir servisine (DB yönetim paneli, metrics endpoint...) güvenli erişimin tek yolu olurdu.

**K4.**
```bash
rsync -av -e 'ssh -i ~/.ssh/gorev_key' ~/gorev/bolum-k/veri/ sshtest@localhost:/tmp/gorev-veri/
sha256sum ~/gorev/bolum-k/veri/*
ssh -i ~/.ssh/gorev_key sshtest@localhost 'sha256sum /tmp/gorev-veri/*'   # aynı özetler
rsync -av -e 'ssh -i ~/.ssh/gorev_key' ~/gorev/bolum-k/veri/ sshtest@localhost:/tmp/gorev-veri/
# "sent ... total size ... speedup" — hiçbir dosya listelenmez
```
İkinci çalıştırmada `rsync` her dosyanın boyut+zaman damgasını karşılaştırır, değişen olmadığı için hiçbir şey göndermez (delta-transfer mantığı).

**K5.**
```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/gorev_key
ssh-add -l
# 256 SHA256:xxxxxxxx... gorev_key (ED25519)   <- parmak izi
ssh sshtest@localhost 'hostname'   # -i vermeden — agent anahtarı sağlıyor
```

## Bölüm L — dd, Otomatik Başlatma, Depo, tmux (Gün 9)

**L1.**
```bash
sudo dd if=/dev/sda bs=512 count=1 2>/dev/null | xxd | tail -2
# 000001f0: .... .... .... .... .... .... .... 55aa   <- boot signature: 55 aa
```
Her (protective-)MBR'ın 510–511. baytı `0x55 0xAA`'dır — BIOS bunu "bu sektör bir boot sektörü" işareti olarak arar.

**L2.**
```bash
systemctl is-enabled gorev-web.service         # enabled
ls -l /etc/systemd/system/multi-user.target.wants/gorev-web.service
# ... -> /etc/systemd/system/gorev-web.service   (enable = [Install] WantedBy hedefine symlink)
```
Debian, `apt install` sırasında `deb-systemd-helper` / `policy-rc.d` politikası ile servisi otomatik `enable` + `start` eder; RHEL/Fedora ailesi bunu yapmaz, `dnf install` sonrası servis `disabled` gelir ve yöneticinin elle `systemctl enable --now` yapması beklenir.

**L3.**
```bash
sudo apt update
# Err ... http://apt.olmayan.gorev/debian ... Could not resolve 'apt.olmayan.gorev'
grep -rl 'apt.olmayan.gorev' /etc/apt/
# /etc/apt/sources.list.d/gorev-ekstra.list
sudo rm /etc/apt/sources.list.d/gorev-ekstra.list
sudo apt update      # temiz — hata yok
```

**L4.**
```bash
tmux new -s gorev
#   (tmux içinde)  sleep 600
#   Ctrl-b  d        <- detach
exit                 # SSH bağlantısını kapat
# yeniden bağlan:
ssh -p 2224 ogrenci@127.0.0.1
tmux ls              # gorev: 1 windows ...
tmux attach -t gorev # sleep hâlâ sayıyor
```
`&` / `nohup` süreci arka plana atar ama **etkileşimli terminalini** korumaz — geri dönüp `top` içinde tuşa basamaz, yarım kalan bir `vi`'ye devam edemezsin. `tmux` tam bir terminal oturumunu (ekran içeriği, çalışan program, kabuk durumu) sunucuda canlı tutar.

**L5.**
```bash
echo "alias gd='systemctl status gorev-web --no-pager'" >> ~/.bashrc
source ~/.bashrc          # ya da yeni SSH oturumu
gd                        # servis durumu
type gd                   # gd is aliased to `systemctl status gorev-web --no-pager'
```
`~/.bashrc` her etkileşimli (non-login) bash oturumunda okunur; SSH login oturumu için `~/.profile` → `~/.bashrc` zinciri de çalışır (Debian varsayılanı).
