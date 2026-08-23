---
tags: [linux, egitim, izleme, monitoring, donanim, kernel]
modul: 15
durum: tamamlandi
---

# 15 — Linux Sistem İzleme Araçları

> **Ön koşul:** [08-surec-yonetimi](08-surec-yonetimi.md), [09-disk-yonetimi](09-disk-yonetimi.md)
> **Süre:** ~3 saat

## Hedefler

- [ ] Dört kaynağı (CPU, RAM, disk, ağ) doğru araçlarla izleyebiliyorum
- [ ] "Sunucu yavaş" şikâyetini sistematik olarak teşhis edebiliyorum
- [ ] Donanım hakkında komut satırından bilgi alabiliyorum
- [ ] Çekirdek modüllerini listeleyip yükleyip kaldırabiliyorum
- [ ] Kalıcı modül ve parametre ayarı yapabiliyorum

---

## 1. Genel bakış — ilk 60 saniye

Bir sunucuya "yavaş" diye bağlandığında ilk çalıştıracakların:

```bash
uptime                  # yük ortalaması — ne zamandır böyle
dmesg -T | tail -20     # kernel son ne dedi (OOM, disk hatası)
vmstat 1 5              # CPU/bellek/IO genel görünüm
mpstat -P ALL 1 3       # çekirdek bazlı CPU
pidstat 1 3             # süreç bazlı CPU
iostat -xz 1 3          # disk gecikmesi
free -h                 # bellek
sar -n DEV 1 3          # ağ throughput
top / htop              # canlı liste
```

`sysstat` paketi (`iostat`, `mpstat`, `pidstat`, `sar`) ayrıca kurulur:
```bash
sudo dnf install sysstat && sudo systemctl enable --now sysstat
sudo apt install sysstat
```

---

## 2. CPU

```bash
uptime
# 14:32:01 up 12 days,  3:44,  2 users,  load average: 0.52, 0.58, 0.59
```

**Load average yorumu:** 1, 5, 15 dakikalık ortalama. **Çekirdek sayısına böl.**

```bash
nproc                        # çekirdek sayısı
lscpu                        # ⭐ CPU detayları
lscpu | grep -E "Model name|Socket|Core|Thread|MHz"
cat /proc/cpuinfo
```

| Load / çekirdek | Yorum |
|---|---|
| < 0.7 | Rahat |
| ~1.0 | Tam kapasite |
| > 1.0 | Kuyruk oluşuyor, süreçler bekliyor |
| > 2.0 | Ciddi aşırı yük |

> 8 çekirdekli makinede load 6.0 normaldir; tek çekirdeklide felakettir.
> Load, "çalışmayı bekleyen süreç sayısı"dır ve **disk beklemesini de içerir** —
> bu yüzden yüksek load her zaman CPU darboğazı demek değildir.

```bash
top                          # P: CPU'ya göre sırala, 1: çekirdekleri ayrı göster
htop
mpstat -P ALL 2 5            # çekirdek bazlı dağılım
pidstat -u 2 5               # süreç bazlı CPU
vmstat 2 5
```

**`top`/`vmstat` CPU sütunları:**

| Sütun | Anlamı |
|---|---|
| `us` (user) | Kullanıcı alanı — uygulamalar |
| `sy` (system) | Kernel alanı — sistem çağrıları |
| `ni` (nice) | Önceliği düşürülmüş süreçler |
| `id` (idle) | Boşta |
| `wa` (iowait) | ⭐ **Disk bekliyor** — yüksekse darboğaz diskte, CPU'da değil |
| `st` (steal) | ⭐ Hipervizör CPU'yu başkasına verdi — komşu VM sorunu |
| `si/hi` | Yazılım/donanım kesmeleri |

> **`wa` yüksek + load yüksek + `us` düşük** = CPU boş, disk boğuluyor. `iostat`'a bak.
> **`st` yüksek** = sanallaştırma platformunda aşırı taahhüt var, hipervizör tarafına bak.

### `top` ekranını soru işareti bırakmadan okumak

`top` çalıştırdığında ekranın üstünde birkaç özet satırı, altında da süreç listesi görürsün.
İkisini de sütun sütun açalım — çünkü bu ekranı "okuyamamak", aslında verinin orada olmasına
rağmen görememek demektir.

**Üst özet satırları:**

```
top - 14:32:01 up 12 days,  3:44,  2 users,  load average: 0.52, 0.58, 0.59
Tasks: 210 total,   1 running, 209 sleeping,   0 stopped,   0 zombie
%Cpu(s):  3.2 us,  1.1 sy,  0.0 ni, 95.0 id,  0.5 wa,  0.0 hi,  0.2 si,  0.0 st
MiB Mem :   7877.4 total,   1245.6 free,   2150.3 used,   4481.5 buff/cache
MiB Swap:   2048.0 total,   2048.0 free,      0.0 used.   5200.1 avail Mem
```

- **1. satır:** saat, sistemin kaç gündür açık olduğu (`uptime`), kaç kullanıcı bağlı, ve
  1/5/15 dakikalık **load average** (yukarıda ayrıntılı anlatıldı).
- **Tasks:** toplam süreç sayısı ve durumları — `running` (o an CPU'da çalışan), `sleeping`
  (bir şey bekleyen, çoğu süreç burada durur, normaldir), `stopped` (durdurulmuş, ör. `Ctrl+Z`),
  **`zombie`** (bitmiş ama üst süreç durumunu henüz "toplamamış" süreçler — birkaç taneyse
  normal, sürekli artıyorsa üst süreçte bir hata var demektir).
- **%Cpu(s):** yukarıda tek tek açıklanan `us/sy/ni/id/wa/hi/si/st` yüzdeleri — tüm çekirdeklerin
  ortalaması. `1` tuşuna basarsan her çekirdeği ayrı satırda görürsün.
- **MiB Mem / MiB Swap:** bellek durumu — bu konu bir sonraki bölümde (§3 Bellek) `free -h`
  ile birlikte ayrıntılı işleniyor; mantığı aynıdır (`available`/`avail Mem` sütununa bak,
  `free`e değil).

**Süreç listesi sütunları** (alt kısım):

```
  PID USER      PR  NI    VIRT    RES    SHR S  %CPU  %MEM     TIME+ COMMAND
 1234 postgres  20   0  845200  98304  81920 S   2.3   1.2   14:22.10 postgres
```

| Sütun | Anlamı |
|---|---|
| `PID` | Süreç kimlik numarası — `kill`, `strace -p` gibi komutlarda bu numarayı kullanırsın |
| `USER` | Süreci hangi kullanıcı çalıştırıyor |
| `PR` | **Priority** — kernel zamanlayıcısının gördüğü gerçek öncelik (düşük sayı = önce çalışır) |
| `NI` | **Nice değeri** — kullanıcının ayarladığı öncelik tercihi, -20 (en yüksek öncelik) ile +19 (en düşük) arası; `PR` bunun üstüne kernel tarafından hesaplanır |
| `VIRT` | ⭐ **Virtual memory** — sürecin adresleyebildiği toplam sanal bellek (kullandığı kütüphaneler, mmap'lediği dosyalar dahil). **Genelde çok yanıltıcıdır** — büyük olması gerçekten o kadar RAM kullandığı anlamına gelmez, sadece "adresleyebileceği" alanı gösterir |
| `RES` | ⭐ **Resident memory** — sürecin **gerçekten fiziksel RAM'de tuttuğu** miktar. Bir sürecin "ne kadar bellek yiyor" sorusunun en gerçekçi cevabı budur |
| `SHR` | **Shared memory** — `RES` içinden, başka süreçlerle **paylaşılan** kısım (ör. ortak kütüphaneler, `libc`). Aynı programın 10 kopyası çalışıyorsa, kütüphane belleği bir kere sayılır, aralarında paylaşılır |
| `S` | Süreç durumu: `R` çalışıyor, `S` uyuyor (bekliyor, normal), `D` **kesintisiz disk beklemesi** (bu durumda takılı bir süreç `kill -9` ile bile öldürülemeyebilir — genelde bozuk disk/NFS işareti), `Z` zombie, `T` durdurulmuş |
| `%CPU` | O süreç son ölçüm aralığında CPU'nun yüzde kaçını kullandı |
| `%MEM` | `RES`'in toplam fiziksel RAM'e oranı |
| `TIME+` | Süreç başladığından beri **toplam** CPU süresi (duvar saati değil, işlemci zamanı) |
| `COMMAND` | Çalıştırılan komut/program adı |

> **Pratikte en çok işine yarayacak ikili: `RES` + `%MEM`.** "Bu sunucuda bellek kim yiyor"
> sorusunun cevabı `VIRT` değil, `RES`'tir — `ps aux --sort=-%mem | head` de aynı mantıkla
> `RES`'e göre sıralar. `htop`'ta bu sütunlar renkli ve daha okunaklı gösterilir, ayrıca
> `F5` ile ağaç görünümüne geçip hangi sürecin hangi sürecin çocuğu olduğunu görebilirsin.

---

## 3. Bellek

```bash
free -h
#               total   used   free  shared  buff/cache  available
# Mem:           7.7Gi  2.1Gi  1.2Gi   180Mi       4.4Gi      5.2Gi
# Swap:          2.0Gi     0B  2.0Gi
```

> ⚠️ **`free` sütunu düşük diye panik yapma.** Linux boş RAM'i disk önbelleği olarak
> kullanır (`buff/cache`) — bu **iyi** bir şeydir, gerektiğinde anında geri verilir.
> Bakman gereken sütun **`available`**'dır. O düşükse gerçekten bellek sıkıntısı var.

```bash
cat /proc/meminfo
vmstat -s
ps aux --sort=-%mem | head -10
smem -rs uss                        # gerçek (paylaşılmayan) bellek kullanımı
slabtop                             # kernel slab önbelleği
```

**Swap kullanımı:**
```bash
swapon --show
# Süreç bazında swap kullanımı
for f in /proc/*/status; do
  awk '/^Name|^VmSwap/{printf "%s ", $2}END{print ""}' "$f"
done | sort -k2 -rn | head
```

**OOM Killer** — bellek tükendiğinde kernel süreç öldürür:
```bash
dmesg -T | grep -i "out of memory"
journalctl -k | grep -i "killed process"
grep -i oom /var/log/messages
```
> "Uygulama sebepsiz kapandı" şikayetinde ilk bakılacak yer burasıdır.
> Bir sürecin OOM'a karşı korunması: `echo -1000 > /proc/PID/oom_score_adj`
> (systemd unit'te `OOMScoreAdjust=-1000`).

---

## 4. Disk ve I/O

```bash
df -h                        # doluluk
df -i                        # ⭐ inode doluluk
du -sh /* 2>/dev/null | sort -rh | head
ncdu /                       # ⭐ interaktif disk gezgini (ayrıca kurulur)

lsblk ; blkid ; findmnt

iostat -xz 2 5               # ⭐ genişletilmiş disk istatistikleri
iotop -o                     # ⭐ hangi SÜREÇ disk kullanıyor (root gerekir)
```

**`iostat -x` önemli sütunlar:**

| Sütun | Anlamı |
|---|---|
| `r/s`, `w/s` | Saniyedeki okuma/yazma |
| `rkB/s`, `wkB/s` | Throughput |
| `await` | ⭐ Ortalama I/O tamamlanma süresi (ms) |
| `r_await`, `w_await` | Okuma/yazma ayrı |
| `%util` | Cihazın meşguliyet yüzdesi |
| `aqu-sz` | Ortalama kuyruk uzunluğu |

Kaba eşikler: SSD'de `await` > 10 ms, HDD'de > 20 ms şüphelidir.
`%util` 100'e yakınsa cihaz doymuş demektir (NVMe'de bu metrik yanıltıcı olabilir —
paralel kuyrukları var).

**Disk sağlığı:**
```bash
sudo smartctl -H /dev/sda            # sağlık özeti
sudo smartctl -a /dev/sda | grep -iE "reallocated|pending|error"
sudo smartctl -t short /dev/sda
```

**Kim ne açmış:**
```bash
sudo lsof +D /var/log                # dizindeki açık dosyalar
sudo lsof +L1                        # ⭐ silinmiş ama açık (disk boşalmıyor sorunu)
sudo fuser -vm /mnt/veri             # "device is busy" çözümü
```

---

## 5. Ağ

```bash
ss -tulnp                    # ⭐ dinlenen portlar
ss -s                        # özet istatistik
ss -tan state established | wc -l    # kurulu bağlantı sayısı
ip -s link                   # arayüz paket/hata sayaçları

iftop -i ens18               # ⭐ bağlantı bazlı canlı bant genişliği
nload ens18                  # basit giriş/çıkış grafiği
bmon                         # çok arayüzlü
vnstat -d                    # günlük toplam trafik (uzun dönem)
nethogs                      # ⭐ SÜREÇ bazlı bant genişliği
sar -n DEV 1 5               # geçmişe dönük ağ istatistiği

sudo tcpdump -i ens18 -n port 443
mtr 8.8.8.8
```

> `ip -s link` çıktısında `errors`, `dropped`, `overrun` sayaçları artıyorsa
> fiziksel katman (kablo, NIC, switch portu, duplex uyuşmazlığı) sorunu var demektir.

---

## 6. Hepsi bir arada araçlar

| Araç | Not |
|---|---|
| `htop` | top'un modern hali — F5 ağaç, F6 sırala, F9 kill |
| `btop` / `bpytop` | Grafiksel, renkli, fare destekli ⭐ |
| `glances` | Tek ekranda CPU+RAM+disk+ağ+süreç, web arayüzü var (`glances -w`) |
| `atop` | Geçmişe dönük kayıt tutar (`atop -r`) ⭐ olay sonrası analiz |
| `nmon` | AIX kökenli, tuşlarla panel açıp kapama |
| `dstat` | Çok metrikli tek satır çıktı |
| `sar` | `sysstat` ile geçmiş veriyi sorgular |

```bash
sar -u 1 3           # CPU
sar -r 1 3           # bellek
sar -d 1 3           # disk
sar -n DEV 1 3       # ağ
sar -u -f /var/log/sa/sa15      # ⭐ ayın 15'indeki veriyi oku
```

> **`atop` ve `sar` neden değerli?** Sorun gece 03:00'te oldu, sabah bakıyorsun.
> `top` sana o anı gösteremez. `atop`/`sar` geçmişi kaydeder — "o anda ne oluyordu"
> sorusunun tek cevabı budur. Yeni sunucuda `sysstat` ve `atop` kur, aktifleştir.

**Üretim izleme yığınları (bilgi):** Prometheus + node_exporter + Grafana,
Zabbix, Netdata, Checkmk. Tek sunucudan öte, filo izlemesi için bunlar kullanılır.

---

## 7. "Sunucu yavaş" — sistematik teşhis

```
1. uptime            → load yüksek mi? Çekirdek sayısına böl.
       │
2. top / vmstat 1    → hangi sütun yüksek?
       │
       ├─ us yüksek  → CPU'ya yüklenen süreç var
       │               ps aux --sort=-%cpu | head ; pidstat -u 1
       │
       ├─ sy yüksek  → aşırı sistem çağrısı / kernel
       │               strace -c -p PID
       │
       ├─ wa yüksek  → ⭐ DİSK darboğazı
       │               iostat -xz 1 ; iotop -o ; await ve %util'e bak
       │
       ├─ st yüksek  → hipervizör kaynak kısıyor (VM komşuları)
       │
       └─ hepsi düşük ama yavaş
                     → free -h (available düşük mü, swap kullanılıyor mu)
                     → ss -s (bağlantı patlaması)
                     → dmesg -T (donanım/OOM hatası)
                     → uygulama seviyesi (DB kilidi, dış API gecikmesi)
```

**Kontrol listesi:**
```bash
uptime && nproc
free -h
df -h && df -i
dmesg -T | tail -30
journalctl -p err --since "1 hour ago"
systemctl --failed
ps aux --sort=-%cpu | head -5
ps aux --sort=-%mem | head -5
iostat -xz 1 3
ss -s
```

---

## 8. Donanım bilgisi

```bash
# Genel
sudo lshw -short              # ⭐ tüm donanımın özeti
sudo lshw -class network
sudo dmidecode -t system      # üretici, model, seri no
sudo dmidecode -t memory      # ⭐ takılı RAM modülleri, hız, slot
sudo dmidecode -t bios
hostnamectl                   # sanal mı fiziksel mi (Virtualization satırı) ⭐
systemd-detect-virt           # kvm / vmware / none

# CPU
lscpu
lscpu | grep -i virtual       # sanallaştırma desteği (vmx/svm)

# Bellek
free -h
sudo dmidecode -t 17 | grep -E "Size|Speed|Locator"

# Depolama
lsblk -o NAME,SIZE,TYPE,MODEL,SERIAL,ROTA
#   ROTA=1 → HDD, ROTA=0 → SSD ⭐
sudo smartctl -i /dev/sda
sudo hdparm -I /dev/sda

# PCI / USB
lspci                         # tüm PCI aygıtlar
lspci -nnk | grep -A3 -i ethernet    # ⭐ ağ kartı + kullanılan SÜRÜCÜ
lsusb
lsusb -t

# Ağ kartı
ethtool ens18                 # hız, duplex, link
ethtool -i ens18              # ⭐ sürücü ve firmware sürümü
ethtool -S ens18              # istatistikler

# Sıcaklık / sensörler
sudo sensors-detect
sensors
```

> `lspci -nnk` neden önemli? Çıktıda `Kernel driver in use:` satırı yoksa, o donanım
> için sürücü yüklenmemiş demektir — aygıt görünür ama çalışmaz. Yeni bir ağ kartı
> veya RAID denetleyicisi tanınmadığında ilk bakılacak yer burasıdır.

---

## 9. Çekirdek modülleri

Kernel modülü = kernel'e çalışırken eklenip çıkarılabilen sürücü/özellik (`.ko` dosyası).

```bash
lsmod                          # ⭐ yüklü modüller
lsmod | grep ext4
modinfo ext4                   # modül bilgisi, parametreler, bağımlılıklar
modinfo -p e1000e              # ⭐ modülün kabul ettiği parametreler

sudo modprobe DOSYA_SISTEMI    # ⭐ modülü BAĞIMLILIKLARIYLA yükle
sudo modprobe -r modul         # kaldır (bağımlılıklarıyla)
sudo modprobe -v modul         # ne yaptığını göster

sudo insmod /yol/modul.ko      # ham yükleme — bağımlılık ÇÖZMEZ
sudo rmmod modul               # ham kaldırma
depmod -a                      # bağımlılık haritasını yeniden oluştur
```

> **`modprobe` vs `insmod`:** Aynı `dnf` vs `rpm` ilişkisi.
> `modprobe` `/lib/modules/$(uname -r)/modules.dep` dosyasına bakar, bağımlılıkları
> sırayla yükler. `insmod` tam yol ister ve bağımlılığı çözmez. **Daima `modprobe` kullan.**

### Kalıcı ayarlar

**Açılışta otomatik yükle:**
```bash
echo "br_netfilter" | sudo tee /etc/modules-load.d/br_netfilter.conf   # systemd (her ikisi)
# Debian alternatifi: /etc/modules dosyasına satır ekle
```

**Modül parametresi:**
```bash
echo "options e1000e InterruptThrottleRate=3" | sudo tee /etc/modprobe.d/e1000e.conf
# Çalışan modül için:
cat /sys/module/e1000e/parameters/InterruptThrottleRate
```

**Modülü kara listeye al (yüklenmesin):**
```bash
cat <<'EOF' | sudo tee /etc/modprobe.d/blacklist-nouveau.conf
blacklist nouveau
options nouveau modeset=0
EOF

sudo dracut -f                       # RHEL — initramfs'i güncelle
sudo update-initramfs -u             # Debian
sudo reboot
```
> Kara liste değişikliği initramfs'te de olmalı, yoksa modül açılışın erken
> aşamasında yine yüklenir. Bu adımı atlamak yaygın bir hatadır.
> Klasik kullanım: NVIDIA kurulumu öncesi `nouveau`'yu devre dışı bırakmak.

### Kernel parametreleri (sysctl)

```bash
sysctl -a                              # tüm parametreler
sysctl net.ipv4.ip_forward
sudo sysctl -w vm.swappiness=10        # geçici

# Kalıcı
echo "vm.swappiness=10" | sudo tee /etc/sysctl.d/99-ozel.conf
sudo sysctl --system                   # tüm .d dosyalarını yeniden yükle
sudo sysctl -p /etc/sysctl.d/99-ozel.conf
```

Sık kullanılanlar:
```ini
vm.swappiness=10                       # swap iştahını azalt
net.ipv4.ip_forward=1                  # yönlendirme (router/konteyner)
net.core.somaxconn=1024                # dinleme kuyruğu (yoğun web sunucusu)
fs.file-max=2097152                    # sistem geneli dosya tanıtıcı sınırı
net.ipv4.tcp_syncookies=1              # SYN flood koruması
```

**Kaynak limitleri:**
```bash
ulimit -a                              # mevcut kabuk limitleri
ulimit -n                              # açık dosya sayısı sınırı
# Kalıcı: /etc/security/limits.d/99-ozel.conf
#   ali  soft  nofile  65535
#   ali  hard  nofile  65535
# systemd servisleri için: unit dosyasında LimitNOFILE=65535
```

---

## 🧪 Lab

1. `sysstat`, `htop`, `iotop`, `ncdu`, `atop` kur (RHEL'de EPEL gerekebilir).
   `systemctl enable --now sysstat` ile geçmiş kaydını başlat.
2. `nproc` ve `uptime` çıktılarıyla mevcut yükü çekirdek başına hesapla.
3. **Yapay CPU yükü:** `for i in $(seq $(nproc)); do yes > /dev/null & done`
   `top`, `mpstat -P ALL 1`, `uptime` ile izle. Sonra `pkill yes` ile durdur.
4. **Yapay disk yükü:** `dd if=/dev/zero of=/tmp/buyuk bs=1M count=5000 oflag=direct &`
   Aynı anda `iostat -xz 1` ve `iotop -o` çalıştır. `%util`, `await` ve `top`'taki `wa`
   sütununun yükselişini gözlemle. Dosyayı sil.
5. `free -h` çıktısını yorumla: `free` ile `available` farkını kendi cümlenle yaz.
6. `ps aux --sort=-%mem | head -5` ile bellek canavarlarını bul.
7. `df -i` ile inode kullanımını kontrol et. `/tmp`'te 50.000 boş dosya oluştur
   (`for i in {1..50000}; do touch /tmp/t/$i; done`), `df -i` farkını gör, temizle.
8. `sudo lshw -short`, `dmidecode -t system`, `dmidecode -t memory` çıktılarını al.
   `systemd-detect-virt` ile sanal mı fiziksel mi doğrula.
9. `lsblk -o NAME,SIZE,TYPE,MODEL,ROTA` ile disklerinin SSD mi HDD mi olduğunu belirle.
10. `lspci -nnk | grep -A3 -i ethernet` ile ağ kartının hangi sürücüyü kullandığını bul,
    `ethtool -i` ile doğrula.
11. `lsmod | head -20`, bir modül seçip `modinfo` ile parametrelerini incele.
12. Kullanılmayan bir modül yükle (`sudo modprobe dummy`), `lsmod | grep dummy` ile
    doğrula, `ip link` ile `dummy0` arayüzünü gör, `modprobe -r dummy` ile kaldır.
13. `/etc/modules-load.d/` altında bir modülü kalıcı yükleyecek dosya oluştur,
    reboot sonrası `lsmod` ile doğrula.
14. `vm.swappiness` değerini `sysctl -w` ile geçici, `/etc/sysctl.d/` ile kalıcı değiştir.
    `sysctl --system` ile yükle, doğrula.
15. **Bütünsel teşhis egzersizi:** 3. ve 4. adımı aynı anda çalıştır, "sunucu yavaş"
    senaryosunu baştan sona uygula, bulgularını bir not dosyasına yaz.

---

## ❓ Kendini test et

**S1.** `free -h` çıktısında `free` sadece 200 MB. Panik mi?

<details><summary>Cevap</summary>
Hayır. Linux kullanılmayan RAM'i disk önbelleğinde (`buff/cache`) tutar ve
gerektiğinde anında geri verir. Bakılacak sütun **`available`**'dır.
O da düşükse gerçek bellek baskısı var demektir.
</details>

**S2.** `top`'ta `wa` (iowait) %40. Ne anlama gelir, sırada ne var?

<details><summary>Cevap</summary>
CPU zamanının %40'ı disk I/O beklemekle geçiyor — darboğaz CPU'da değil, **diskte**.
`iostat -xz 1` ile `await` ve `%util`'e bak, `iotop -o` ile hangi sürecin
disk kullandığını bul. Yüksek load'un sebebi de büyük olasılıkla budur.
</details>

**S3.** Uygulama gece sebepsiz kapanmış. Log'da hiçbir şey yok. Nereye bakarsın?

<details><summary>Cevap</summary>
OOM Killer'a: `dmesg -T | grep -i "out of memory"` veya
`journalctl -k | grep -i "killed process"`. Kernel bellek yetersizliğinde
en yüksek `oom_score`'lu süreci öldürür ve bunu uygulama loguna yazmaz.
</details>

**S4.** `insmod` yerine neden `modprobe` kullanmalısın?

<details><summary>Cevap</summary>
`modprobe` `modules.dep` üzerinden bağımlılıkları çözer ve modül adıyla çalışır.
`insmod` tam dosya yolu ister, bağımlılık çözmez — bağımlı modül yüklü değilse hata verir.
İlişki `dnf` ile `rpm` arasındaki ilişkiyle aynıdır.
</details>

**S5.** Bir modülü `/etc/modprobe.d/` ile kara listeye aldın ama açılışta yine yükleniyor. Ne unuttun?

<details><summary>Cevap</summary>
initramfs'i güncellemeyi. Modül açılışın erken aşamasında initramfs içinden yükleniyor.
`sudo dracut -f` (RHEL) veya `sudo update-initramfs -u` (Debian) çalıştırıp reboot etmelisin.
</details>

**S6.** 8 çekirdekli sunucuda `load average: 7.2`. Sorun var mı?

<details><summary>Cevap</summary>
Kapasite sınırına yakın ama teknik olarak aşırı yük değil (8 çekirdek ≈ 8.0).
İzlenmeli. Ayrıca load, disk bekleyen süreçleri de sayar — `top`'ta `wa` yüksekse
CPU değil disk darboğazı olabilir. Load'u tek başına yorumlama.
</details>

---

## 📋 Hızlı referans

```bash
# İlk 60 saniye
uptime ; nproc ; free -h ; df -h ; df -i
dmesg -T | tail -30 ; journalctl -p err --since "1 hour ago"
systemctl --failed
vmstat 1 5 ; iostat -xz 1 3 ; ss -s

# Kaynak bazlı
top / htop / btop            # canlı
mpstat -P ALL 1 ; pidstat 1  # CPU detay
iotop -o                     # disk kullanan süreç
nethogs ; iftop -i IFACE     # ağ kullanan süreç/bağlantı
atop -r ; sar -u -f /var/log/sa/saNN   # ⭐ GEÇMİŞ veri

# Donanım
lshw -short ; lscpu ; lsblk -o NAME,SIZE,MODEL,ROTA
dmidecode -t system|memory|bios
lspci -nnk | grep -A3 -i ethernet
ethtool -i IFACE ; smartctl -H /dev/sdX
systemd-detect-virt

# Modüller
lsmod ; modinfo MODUL ; modinfo -p MODUL
modprobe MODUL ; modprobe -r MODUL
/etc/modules-load.d/X.conf       # açılışta yükle
/etc/modprobe.d/X.conf           # parametre / blacklist
dracut -f | update-initramfs -u  # ⭐ blacklist sonrası ŞART

# sysctl
sysctl -a | grep X ; sysctl -w K=V
/etc/sysctl.d/99-ozel.conf ; sysctl --system
ulimit -a ; /etc/security/limits.d/
```
