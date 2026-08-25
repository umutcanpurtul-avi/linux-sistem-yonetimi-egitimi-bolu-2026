---
tags:
  - egitim/linux-sistem-yonetimi
tarih: 2026-08-24
konular:
  - Gün 1-3 Pratik Challenge cevap anahtarı
---

# Gün 1-3 Pratik Challenge — Cevaplar

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
