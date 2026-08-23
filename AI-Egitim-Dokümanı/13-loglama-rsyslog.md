---
tags: [linux, egitim, log, rsyslog, journald]
modul: 13
durum: tamamlandi
---

# 13 — Loglama Sistemi (rsyslog + journald)

> **Ön koşul:** [08-surec-yonetimi](08-surec-yonetimi.md), [11-ag-ayarlari](11-ag-ayarlari.md)
> **Süre:** ~3 saat

## Hedefler

- [ ] Facility ve severity kavramlarını anlıyorum
- [ ] rsyslog kurallarını yazabiliyorum
- [ ] journald ile log sorgulayabiliyorum
- [ ] Merkezi log sunucusu kurabiliyorum
- [ ] logrotate ile log döngüsü yapılandırabiliyorum
- [ ] Log analizi ile sorun teşhis edebiliyorum

---

## 1. Modern Linux'ta iki log sistemi

```
Uygulama / Kernel
      │
      ├──► systemd-journald ──► /run/log/journal/  (ikili biçim, RAM veya disk)
      │           │
      │           └──► rsyslog'a iletir
      │
      └──► rsyslog ──────────► /var/log/*.log      (düz metin)
                     │
                     └──► uzak sunucuya (TCP/UDP 514)
```

| | journald | rsyslog |
|---|---|---|
| Biçim | İkili (binary), yapısal | Düz metin |
| Sorgulama | `journalctl` — güçlü filtreler | `grep`, `awk` |
| Kalıcılık | **Varsayılan olarak geçici** (RAM) ⚠️ | Kalıcı |
| Uzak gönderim | Sınırlı | ✅ Olgun |
| Metadata | Zengin (unit, PID, boot ID, cgroup) | Sınırlı |

> **Önemli:** Çoğu dağıtımda ikisi **birlikte** çalışır. journald toplar, rsyslog'a
> aktarır, rsyslog `/var/log`'a yazar ve uzağa gönderir.
> Kurs sadece rsyslog anlatıyor; sahada ikisini de kullanacaksın.

### Neden aynı işi yapan iki sistem birden var? (soru işareti bırakmadan)

Şöyle düşün: bir uygulama çöktüğünde ya da bir sorun yaşadığında elinde **iki farklı ihtiyaç**
oluşur ve tek bir araç ikisini de aynı anda iyi karşılayamaz.

**İhtiyaç 1 — "Bu servisle ilgili SON ne oldu, ayrıntılı şekilde?"**
Bunun cevabı `journald`'dadır. systemd her servisi kendisi başlattığı için, o servisin PID'ini,
hangi cgroup'ta çalıştığını, hangi boot'ta (açılışta) olduğunu, stdout/stderr çıktısını —
hepsini otomatik, yapılandırma yapmana bile gerek kalmadan yakalar. `journalctl -u nginx`
yazdığında nginx'in **sadece kendi** loglarını, zengin metadata ile görürsün. Bunu klasik
metin dosyalarıyla yapmak, `grep nginx /var/log/messages` ile onlarca farklı servisin
karışık loglarını elemeye çalışmaktan çok daha kolaydır.

**İhtiyaç 2 — "Bu logu 1 yıl sonra da okuyabilecek miyim, başka sunucuya gönderebilecek miyim?"**
İşte burada `journald` tek başına yetersiz kalır, çünkü:
- **İkili (binary) formattadır** — `cat`, `grep`, `awk` gibi klasik metin araçlarıyla direkt okunamaz,
  sadece `journalctl` ile okunur. Bir metin editörüyle açamazsın.
- **Varsayılan olarak kalıcı bile değildir** — aşağıda anlatılan ayar yapılmazsa RAM'de
  (`/run/log/journal`) tutulur ve **sunucu yeniden başladığında tamamen silinir.**
- Başka bir sunucuya (merkezi log sunucusuna) düzgün, olgun bir şekilde göndermek için
  tasarlanmamıştır.

Bu ikinci ihtiyacı **rsyslog** karşılar: düz metin dosyasına yazar (yıllarca saklanabilir,
herhangi bir metin aracıyla okunabilir), TCP/UDP üzerinden başka sunuculara güvenilir şekilde
gönderebilir, `logrotate` ile disk kaplamasını kontrol altında tutabilirsin.

**Sonuç — pratikte nasıl çalışır:** Bir uygulama bir mesaj ürettiğinde, önce `journald` yakalar
(çünkü systemd her şeyi ilk o görür), sonra journald bu mesajı `rsyslog`'a da iletir. rsyslog
onu `/var/log/messages` gibi bir dosyaya yazar ve isterse uzak sunucuya gönderir. Yani ikisi
**rakip değil, birbirini tamamlayan iki katmandır**: journald = "az önce ne oldu, ayrıntılı ve
sorgulanabilir", rsyslog = "kalıcı, taşınabilir, uzun süreli arşiv".

> **Somut örnek — neden bu fark seni bir gün kurtarır:** Sunucu gece 03:00'te çöktü. Sabah
> `journalctl -b -1` ile (bir önceki açılışın logları) bakıyorsun ama journald kalıcı
> yapılandırılmamışsa RAM'deki her şey reboot'ta silinmiştir — **hiçbir şey göremezsin.**
> Eğer rsyslog da çalışıyor olsaydı, `/var/log/messages` diskte kalıcı olarak dururdu ve
> çökme anındaki son mesajları oradan okuyabilirdin. Bu yüzden üretim sunucusunda ya
> journald'ı kalıcı yap (aşağıda anlatılıyor) ya da rsyslog'un aktif olduğundan emin ol —
> ikisi birden en güvenlisi.

---

## 2. Facility ve Severity

Syslog protokolünün (RFC 5424) temeli.

### Facility — mesaj nereden geldi

| No | Facility | Kaynak |
|---|---|---|
| 0 | `kern` | Kernel |
| 1 | `user` | Kullanıcı süreçleri |
| 2 | `mail` | Posta sistemi |
| 3 | `daemon` | Sistem daemon'ları |
| 4 | `auth` | Kimlik doğrulama ⭐ |
| 5 | `syslog` | Syslog'un kendisi |
| 6 | `lpr` | Yazıcı |
| 7 | `news` / 8 `uucp` / 9 `cron` | — |
| 10 | `authpriv` | Özel kimlik doğrulama ⭐ |
| 16–23 | `local0`–`local7` | **Kendi uygulamaların için** ⭐ |

### Severity — ne kadar ciddi

| No | Seviye | Anlam |
|---|---|---|
| 0 | `emerg` | Sistem kullanılamaz |
| 1 | `alert` | Anında müdahale |
| 2 | `crit` | Kritik |
| 3 | `err` | Hata |
| 4 | `warning` | Uyarı |
| 5 | `notice` | Normal ama kayda değer |
| 6 | `info` | Bilgi |
| 7 | `debug` | Hata ayıklama |

> Sayı **küçüldükçe ciddiyet artar**. Kuralda `err` yazdığında "err **ve daha ciddi**"
> (err, crit, alert, emerg) anlaşılır. Sadece o seviyeyi istiyorsan `=err` yaz.

---

## 3. rsyslog yapılandırması

```bash
sudo dnf install rsyslog ; sudo systemctl enable --now rsyslog
sudo apt install rsyslog ; sudo systemctl enable --now rsyslog

sudo vi /etc/rsyslog.conf
ls /etc/rsyslog.d/          # ⭐ modüler dosyalar — değişikliklerini buraya yaz
```

### Kural biçimi

```
facility.severity        hedef
```

```
*.info;mail.none;authpriv.none;cron.none   /var/log/messages
authpriv.*                                  /var/log/secure
mail.*                                      -/var/log/maillog
cron.*                                      /var/log/cron
*.emerg                                     :omusrmsg:*
local7.*                                    /var/log/boot.log
kern.*                                      /var/log/kern.log
*.err                                       /var/log/hatalar.log
:programname, isequal, "nginx"              /var/log/nginx-syslog.log
```

- `.none` → o facility'yi bu dosyaya **yazma**
- `-` öneki → asenkron yaz (**diske senkron yazma**, performans; ani kapanmada son
  satırlar kaybolabilir)
- `*` → hepsi
- `=err` → sadece err seviyesi
- `!=info` → info hariç

Değişiklik sonrası:
```bash
sudo rsyslogd -N1                    # ⭐ sözdizimi doğrula
sudo systemctl restart rsyslog
```

### Test

```bash
logger "Test mesaji"
logger -p local7.info "Uygulama basladi"
logger -t uygulamam -p local0.err "Baglanti hatasi"
tail -f /var/log/messages
```
`logger`, betiklerinden syslog'a yazmanın standart yoludur:
```bash
logger -t yedek -p local0.info "Yedekleme basladi: $(date)"
```

---

## 4. Standart log dosyaları

> **Dağıtım farkı — dosya adları farklı:**

| İçerik | RHEL / Rocky / Alma | Debian / Ubuntu |
|---|---|---|
| Genel sistem | `/var/log/messages` | `/var/log/syslog` |
| Kimlik doğrulama | `/var/log/secure` ⭐ | `/var/log/auth.log` ⭐ |
| Kernel | `/var/log/dmesg` | `/var/log/kern.log` |
| Cron | `/var/log/cron` | (syslog içinde) |
| Paket yönetimi | `/var/log/dnf.log` | `/var/log/apt/history.log` |
| Açılış | `/var/log/boot.log` | `/var/log/boot.log` |
| Posta | `/var/log/maillog` | `/var/log/mail.log` |

> "SSH giriş denemelerine bakacağım" dediğinde RHEL'de `/var/log/secure`,
> Ubuntu'da `/var/log/auth.log`. Bu ikiliyi ezberle.

**İkili (binary) loglar — `cat` ile okunmaz:**
```bash
last          # /var/log/wtmp   — giriş/çıkış geçmişi
lastb         # /var/log/btmp   — BAŞARISIZ giriş denemeleri ⭐
lastlog       # /var/log/lastlog — her kullanıcının son girişi
who /var/log/wtmp
```

**Ubuntu 24.04+ notu:** Bazı kurulumlarda `/var/log/syslog` artık üretilmiyor,
her şey journald'de. `rsyslog` kurulu değilse `journalctl` kullanılır.

---

## 5. journald — journalctl

```bash
journalctl                       # tüm loglar (less içinde)
journalctl -f                    # ⭐ canlı takip (tail -f gibi)
journalctl -n 50                 # son 50 satır
journalctl -r                    # ters sırayla (en yeni üstte)
journalctl -e                    # sona atla

# Birime göre
journalctl -u sshd               # ⭐ servis logları
journalctl -u nginx -f
journalctl -u nginx --since today

# Zamana göre
journalctl --since "2026-08-20 10:00" --until "2026-08-20 12:00"
journalctl --since "1 hour ago"
journalctl --since yesterday
journalctl --since "10 min ago"

# Önceliğe göre
journalctl -p err                # err ve daha ciddi ⭐
journalctl -p warning..err
journalctl -p err -b             # bu açılıştan beri hatalar

# Açılışa göre
journalctl -b                    # ⭐ mevcut açılış
journalctl -b -1                 # bir önceki açılış (çökme sonrası altın değerinde)
journalctl --list-boots

# Diğer filtreler
journalctl _PID=1234
journalctl _UID=1000
journalctl /usr/sbin/sshd        # çalıştırılabilir dosyaya göre
journalctl -k                    # sadece kernel (= dmesg)
journalctl -g "hata"             # ⭐ regex ile içerik ara (grep gibi)

# Çıktı biçimi
journalctl -o json-pretty        # yapısal
journalctl -o cat                # sadece mesaj, metadata yok
journalctl -o short-precise      # mikrosaniye hassasiyet
journalctl -x                    # açıklayıcı yardım metni ekle
journalctl -xeu nginx            # ⭐ EN ÇOK KULLANACAĞIN: son hatalar + açıklama
```

### journald'ı kalıcı yapmak ⭐

Varsayılan olarak journald logları `/run/log/journal`'da (**RAM**) tutar —
**reboot'ta kaybolur**. Kalıcı yapmak:

```bash
sudo mkdir -p /var/log/journal
sudo systemd-tmpfiles --create --prefix /var/log/journal
sudo systemctl restart systemd-journald

journalctl --list-boots          # artık eski açılışları da görürsün
```
Ya da `/etc/systemd/journald.conf`:
```ini
[Journal]
Storage=persistent
SystemMaxUse=1G          # toplam disk sınırı
MaxRetentionSec=1month   # saklama süresi
```

> Bu ayar yapılmamışsa "sunucu gece çöktü, sabah bakıyorum, hiçbir log yok" durumu
> yaşarsın. Yeni kurulan her sunucuda ilk yapılacaklar listesine koy.

### Disk kullanımı

```bash
journalctl --disk-usage
sudo journalctl --vacuum-size=500M     # 500 MB'a düşür
sudo journalctl --vacuum-time=30d      # 30 günden eskiyi sil
sudo journalctl --verify               # bütünlük kontrolü
```

---

## 6. Merkezi log sunucusu

Neden? Sunucu çökerse/ele geçirilirse yerel loglar kaybolur veya silinir.
Merkezi sunucu hem kurtarma hem uyumluluk (KVKK, ISO 27001, PCI-DSS) gereğidir.

### Sunucu tarafı (log toplayan)

`/etc/rsyslog.conf` veya `/etc/rsyslog.d/10-sunucu.conf`:

```rsyslog
# TCP dinle (güvenilir — tercih et)
module(load="imtcp")
input(type="imtcp" port="514")

# UDP dinle (hızlı ama paket kaybolabilir)
module(load="imudp")
input(type="imudp" port="514")

# Gelen logları istemciye göre ayır  ⭐
template(name="UzakLog" type="string"
         string="/var/log/uzak/%HOSTNAME%/%PROGRAMNAME%.log")

if $fromhost-ip != '127.0.0.1' then {
    action(type="omfile" dynaFile="UzakLog")
    stop
}
```

```bash
sudo mkdir -p /var/log/uzak
sudo rsyslogd -N1
sudo systemctl restart rsyslog
sudo ss -tulnp | grep 514

# Firewall
sudo firewall-cmd --permanent --add-port=514/tcp && sudo firewall-cmd --reload  # RHEL
sudo ufw allow 514/tcp                                                          # Ubuntu

# SELinux (RHEL) — 514 zaten syslogd_port_t'dir, farklı port kullanırsan:
sudo semanage port -a -t syslogd_port_t -p tcp 5514
```

### İstemci tarafı (log gönderen)

`/etc/rsyslog.d/90-uzak.conf`:
```rsyslog
# TCP (@@ = TCP, @ = UDP)
*.* @@192.168.1.100:514

# Disk kuyruğu — sunucu erişilemezse logları biriktir, sonra gönder  ⭐
$ActionQueueFileName kuyruk
$ActionQueueMaxDiskSpace 1g
$ActionQueueSaveOnShutdown on
$ActionQueueType LinkedList
$ActionResumeRetryCount -1
```

```bash
sudo rsyslogd -N1
sudo systemctl restart rsyslog
logger "Merkezi log testi $(hostname)"
```
Sunucuda doğrula:
```bash
tail -f /var/log/uzak/*/*.log
```

> **Neden TCP (`@@`)?** UDP'de paket kaybolursa fark etmezsin. TCP + disk kuyruğu
> kombinasyonu, ağ kesintisinde bile log kaybını önler. Üretimde TCP kullan.
> Şifreleme gerekiyorsa RELP + TLS (`omrelp`) veya `imtcp` üzerinde TLS.

### Alternatifler (bilgi)

- **journald ile:** `systemd-journal-remote` / `systemd-journal-upload`
- **Modern yığın:** Filebeat/Fluent Bit → Elasticsearch/OpenSearch → Kibana,
  ya da Promtail → Loki → Grafana

---

## 7. logrotate — log döngüsü

### Neden gerekli? (somut senaryoyla)

Bir log dosyası, sen hiçbir şey yapmazsan **sonsuza kadar büyür**. Düşün: yoğun trafik alan
bir web sunucusunun `access.log`'u her istekte bir satır ekliyor. Günde 1 milyon istek alan
bir sunucuda bu, günde yüzlerce MB, ayda onlarca GB demektir. Hiçbir müdahale olmazsa:

1. Disk zamanla dolar (`df -h` %100'e yaklaşır).
2. Disk dolduğunda sistem **yeni log yazamaz**, çoğu zaman da başka hiçbir şey yazamaz —
   veritabanı, uygulama, hatta systemd'nin kendisi bile disk dolduğunda garip şekilde
   davranmaya başlar.
3. Dev boyuttaki tek bir log dosyasını `grep`/`less` ile açmak da başlı başına yavaş ve
   pratik değildir — 20 GB'lık bir dosyada "dün saat 14:00'teki hatayı bul" demek işkencedir.

`logrotate` bu üç sorunu birden çözer: dosyayı belirli aralıklarla (günlük/haftalık/boyuta göre)
**keser**, eskiyi yeniden adlandırıp sıkıştırır, belirlediğin sayıda eski kopyayı saklar,
bu sayıyı aşanları **siler**. Böylece disk kullanımı öngörülebilir bir tavana oturur ve her
log dosyası makul boyutta, yönetilebilir kalır. Kısacası: **logrotate olmazsa disk bir gün
mutlaka dolar** — bu "olabilir" değil, zaman meselesidir.

```bash
cat /etc/logrotate.conf
ls /etc/logrotate.d/         # ⭐ paket bazlı yapılandırmalar
```

### Kendi kuralın

```bash
sudo vi /etc/logrotate.d/uygulamam
```
```
/var/log/uygulamam/*.log {
    daily                    # günlük döndür (weekly, monthly, hourly)
    rotate 14                # 14 kopya sakla
    size 100M                # VEYA boyut bazlı (daily ile birlikte: hangisi önce olursa)
    compress                 # eskileri gzip'le
    delaycompress            # bir sonraki döngüde sıkıştır (açık dosya sorunu için) ⭐
    missingok                # dosya yoksa hata verme
    notifempty               # boşsa döndürme
    create 0640 root adm     # yeni dosyayı bu izinlerle oluştur
    dateext                  # .1 yerine tarih ekle: app.log-20260823
    sharedscripts            # birden çok dosya için script'i BİR KERE çalıştır
    postrotate
        /usr/bin/systemctl reload uygulamam.service > /dev/null 2>&1 || true
    endscript
}
```

### Önemli direktifler

| Direktif | Anlamı |
|---|---|
| `daily/weekly/monthly` | Döngü sıklığı |
| `rotate N` | Kaç eski kopya saklansın |
| `size 100M` | Boyut eşiği |
| `compress` / `delaycompress` | Sıkıştırma |
| `copytruncate` | Kopyala + orijinali sıfırla (uygulama dosyayı açık tutuyorsa) ⭐ |
| `create MOD SAHİP GRUP` | Yeni dosyanın izinleri |
| `postrotate/endscript` | Döngü sonrası komut (genelde servis reload) |
| `su root adm` | Hangi kullanıcıyla çalışsın (izin sorunlarında) |

> **`copytruncate` ne zaman?** Uygulama log dosyasını sürekli açık tutuyor ve yeniden
> açmayı bilmiyorsa (`reload` desteklemiyorsa). `logrotate` dosyayı yeniden adlandırınca
> uygulama eski inode'a yazmaya devam eder, yeni dosya boş kalır. `copytruncate` içeriği
> kopyalar ve orijinali sıfırlar — kısa bir yarış durumu riski vardır ama sorunu çözer.

### Test etme

```bash
sudo logrotate -d /etc/logrotate.d/uygulamam    # ⭐ DRY RUN — ne yapacağını göster
sudo logrotate -v /etc/logrotate.d/uygulamam    # ayrıntılı çalıştır
sudo logrotate -f /etc/logrotate.d/uygulamam    # ZORLA döndür (test için)
cat /var/lib/logrotate/logrotate.status         # son döngü zamanları (RHEL)
cat /var/lib/logrotate/status                   # Debian
```

logrotate `cron.daily` veya systemd timer ile çalışır:
```bash
systemctl list-timers | grep logrotate
```

---

## 8. Log analizi — pratik komutlar

```bash
# Başarısız SSH girişleri
sudo grep "Failed password" /var/log/secure     # RHEL
sudo grep "Failed password" /var/log/auth.log   # Debian
sudo lastb | head -20

# Saldırgan IP'ler (en çok deneyen 10)
sudo grep "Failed password" /var/log/auth.log \
  | awk '{print $(NF-3)}' | sort | uniq -c | sort -rn | head -10

# Başarılı girişler
sudo grep "Accepted" /var/log/secure

# sudo kullanımı
sudo grep sudo /var/log/secure | grep COMMAND

# Kernel hataları / OOM killer
sudo dmesg -T | grep -i error
sudo dmesg -T | grep -i "out of memory"         # ⭐ süreç neden öldü
sudo journalctl -k -p err

# Servis çökmesi
sudo journalctl -u nginx -p err --since today
sudo journalctl -xeu nginx

# Disk / dosya sistemi hataları
sudo journalctl -k | grep -iE "i/o error|ext4|xfs"

# Son açılışta ne oldu
sudo journalctl -b -p err
sudo journalctl -b -1 -p err                    # önceki açılış (çökme analizi) ⭐

# En çok log üreten servisler
sudo journalctl --since today -o json | jq -r '._SYSTEMD_UNIT' | sort | uniq -c | sort -rn | head
```

**Web sunucusu log analizi:**
```bash
awk '{print $1}' /var/log/nginx/access.log | sort | uniq -c | sort -rn | head -10   # en aktif IP
awk '{print $9}' /var/log/nginx/access.log | sort | uniq -c | sort -rn              # HTTP kodları
grep " 500 " /var/log/nginx/access.log | tail -20                                   # 500 hataları
```

---

## 🧪 Lab

1. `logger -p local7.info "test"` çalıştır, hangi dosyaya düştüğünü bul.
2. `/etc/rsyslog.d/50-ozel.conf` oluştur: `local0.*` mesajlarını `/var/log/ozel.log`'a
   yaz. `rsyslogd -N1` ile doğrula, servisi yeniden başlat, `logger -p local0.err` ile test et.
3. `journalctl --disk-usage` ile mevcut kullanımı gör. journald'ı **kalıcı** yap,
   reboot et, `journalctl -b -1` ile önceki açılışın loglarını okuyabildiğini doğrula.
4. `journalctl -u sshd --since "1 hour ago" -p err` çalıştır. SSH ile kasten yanlış
   parola gir, log'da göründüğünü doğrula.
5. `lastb` ile başarısız girişleri gör. Yukarıdaki `awk` tek satırlığıyla en çok
   deneyen IP'leri çıkar.
6. **Merkezi log:** `rocky1`'i sunucu, `deb1`'i istemci yap. TCP 514 üzerinden
   log gönderimini kur, firewall'u aç, `logger` ile test et,
   `/var/log/uzak/deb1/` altında dosyanın oluştuğunu doğrula.
7. İstemcide rsyslog'u durdur, sunucuyu kapat, istemcide `logger` ile log üret,
   sunucuyu aç — disk kuyruğu sayesinde logların geldiğini gör.
8. `/var/log/uygulamam/` dizini oluştur, içine 50 MB'lık sahte log koy.
   Günlük döngü, 7 kopya, `compress`, `dateext` ayarlı bir logrotate kuralı yaz.
   `logrotate -d` ile dry run, sonra `-f` ile zorla döndür, sonucu incele.
9. `copytruncate` ile normal döngü arasındaki farkı deneyle gör: `tail -f` ile dosyayı
   açık tut, normal rotate yap, yeni dosyaya yazılmadığını gözlemle; sonra `copytruncate`
   ile tekrarla.
10. `journalctl -o json-pretty -n 1` ile bir log kaydının tüm metadata'sını incele.

---

## ❓ Kendini test et

**S1.** Sunucu gece çöktü, sabah `journalctl` ile bakıyorsun ama çökmeden önceki
loglar yok. Neden?

<details><summary>Cevap</summary>
journald **kalıcı depolama** ile yapılandırılmamış; loglar `/run/log/journal` (RAM)
içindeydi ve reboot'ta silindi. `sudo mkdir -p /var/log/journal` +
`systemctl restart systemd-journald` ya da `Storage=persistent`.
</details>

**S2.** rsyslog kuralında `*.err` yazdın. Hangi mesajlar yakalanır?

<details><summary>Cevap</summary>
`err` **ve daha ciddi** olanlar: err(3), crit(2), alert(1), emerg(0).
Sadece err seviyesini istiyorsan `*.=err` yazmalısın.
</details>

**S3.** `@@192.168.1.100:514` ile `@192.168.1.100:514` farkı?

<details><summary>Cevap</summary>
`@@` = TCP (güvenilir, teslim garantili, kuyruklanabilir).
`@` = UDP (hızlı ama paket kaybı sessizce olur).
Üretimde TCP + disk kuyruğu kullanılır.
</details>

**S4.** logrotate döngü yaptı ama uygulama hâlâ eski dosyaya yazıyor, yeni dosya boş.
Ne yapmalısın?

<details><summary>Cevap</summary>
Uygulama log dosyasını açık tutuyor, yeniden adlandırma sonrası eski inode'a yazmaya
devam ediyor. İki çözüm: `postrotate` ile servise `reload`/sinyal göndermek (tercih edilen),
ya da `copytruncate` kullanmak (uygulama reload desteklemiyorsa).
</details>

**S5.** Ubuntu'da SSH giriş denemelerini nerede ararsın? RHEL'de?

<details><summary>Cevap</summary>
Ubuntu/Debian: `/var/log/auth.log`. RHEL/Rocky: `/var/log/secure`.
Her ikisinde de alternatif: `journalctl -u sshd`. Başarısız denemeler için `lastb`.
</details>

---

## 📋 Hızlı referans

```bash
# journald
journalctl -xeu SERVIS          # ⭐ en çok kullanacağın
journalctl -f                   # canlı takip
journalctl -b | -b -1           # bu / önceki açılış
journalctl -p err --since today
journalctl -k                   # kernel
journalctl -g "regex"           # içerik ara
journalctl --disk-usage ; --vacuum-time=30d
mkdir -p /var/log/journal       # ⭐ KALICI YAP

# rsyslog
logger -t etiket -p local0.info "mesaj"
rsyslogd -N1                    # sözdizimi kontrolü
# /etc/rsyslog.d/*.conf :  facility.severity  /var/log/dosya
# uzak:  *.*  @@sunucu:514      (@@=TCP, @=UDP)

# Log dosyaları
# RHEL:   /var/log/messages , /var/log/secure
# Debian: /var/log/syslog   , /var/log/auth.log
last ; lastb ; lastlog ; dmesg -T

# logrotate
logrotate -d /etc/logrotate.d/X    # dry run
logrotate -f /etc/logrotate.d/X    # zorla
# daily rotate 14 compress delaycompress missingok notifempty
# postrotate ... endscript | copytruncate
```
