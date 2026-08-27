---
tags:
  - egitim/linux-sistem-yonetimi
tarih: 2026-08-27
konular:
  - ABI uyumluluğu
  - Süreç izleme — ps, root'un diğer kullanıcıların süreçlerini görebilmesi
  - nice / renice
  - lsusb / lspci
  - free, top
  - kill ve sinyaller
  - Zombi süreçler
  - Sunucu servisleri (systemd) — Debian 13, Ubuntu 24, Rocky
  - Log tutma — doğrudan dosya, syslog, rsyslog, journald
  - /var/log dizini
  - Zamanlanmış görevler — cron, /etc/cron.d
  - logrotate
---

# Gün 6

Bağlantı: [Linux Sistem Yönetimi Eğitimi](../README.md) · [00 - Eğitim Planı](../00%20-%20Eğitim%20Planı.md) · [Gün 5](Gün%205.md)

## İşlenen Konular

- ABI uyumluluğu nedir? (Araştırılacak olarak not düşülmüştü — aşağıda ele alındı.)
- `ps` komutunun kullanımı ve parametreleri.
- Root kullanıcısı diğer kullanıcıların süreçlerini nasıl görebilir?
- `nice` ve `renice` komutları.
- `lsusb`, `lspci`.
- `free`, `top`.
- `kill` nedir? Ön tanımlı olarak hangi sinyalle çalışır? `kill -l` ile görülen sinyaller nelerdir?
- Zombi süreç nedir, neden ortaya çıkar, nasıl yönetilir?
- Sunucu servisleri: Debian 13, Ubuntu 24 ve Rocky üzerinde servis mimarisi — servis dosyalarının bulunduğu dizinler, servislerin işlevi/çalışma mantığı, bir servisin nasıl inceleneceği ve servis içindeki bilgilerle nerelere erişilebileceği.
- Log tutma konuları: dosyaya doğrudan yazma, syslog, rsyslog (en çok kullanılan), systemd altında journal yapısı.
- `/var/log` dizini incelendi.
- Zamanlanmış görevler: cron ve cron tabloları, `/etc/cron.d` dizinindeki düzenlemeler.
- `logrotate` nedir ve nasıl uygulanır?

## Genişletilmiş Anlatım (Öğrenme İçin Ek Açıklamalar)

> [!WARNING]
> **Yukarıda bulunan kısa notların AI ile genişletilmiş halidir. Bilgiler sadece o gün işlenen konular ile sınırlandırılmış olup referans olması için eklenmiştir. Lütfen bu genişletilmiş metni kendi araştırmalarınıza bir ön bilgi olarak kullanın ve testlerinizi sadece burayı kullanarak değil, farklı kaynaklardan da yararlanarak yapın.**

### ABI uyumluluğu nedir?

Bu konu notlarda "araştırılacak" olarak işaretlenmişti — dolayısıyla derste sorulmuş bir soru olarak kapsam içinde, aşağıda dış kaynaklardan (kernel.org resmi dokümantasyonu, opensource.com) doğrulanarak cevaplanıyor.

**ABI (Application Binary Interface)**, iki **derlenmiş** (binary) bileşenin birbiriyle nasıl konuşacağını tanımlayan sözleşmedir: fonksiyon çağrılırken argümanların hangi register'lara/stack konumlarına konacağı, veri yapılarının bellekte hangi boyut ve hizalamayla (padding/alignment) durduğu, sembol isimlerinin (symbol) binary içinde nasıl kodlandığı gibi düşük seviye detaylar. Bunu **API** ile karıştırmamak gerekir: API, **kaynak kod** (source code) seviyesinde bir sözleşmedir ("bu fonksiyonun adı X, şu parametreleri alır") — kodu yeniden derlersen API uyumluluğu yeter. ABI ise **derlenmiş hâliyle**, kaynak koduna hiç dokunmadan bir `.so`/`.ko`/binary'nin çalışmaya devam edip etmeyeceğini belirler.

Linux'ta ABI kararlılığı iki tamamen farklı katmanda, iki farklı kuralla işler:

- **Kernel ↔ userspace ABI (syscall arayüzü):** Linus Torvalds'ın ünlü kuralı **"we don't break userspace"** (kullanıcı alanını asla kırma) burada geçerlidir. Bir syscall'ın (örn. `open()`, `read()`, `execve()`) davranışı bir kere yayınlandıktan sonra **süresiz olarak** geriye dönük uyumlu kalmak zorundadır — 10 yıl önce derlenmiş statik bir binary bugünkü bir kernelde hâlâ çalışabilmelidir. Bu yüzden `/proc/sys`, `/sys` gibi arayüzler ve syscall numaraları neredeyse hiç değişmez; değiştiğinde bile eski numara/davranış korunur, yeni bir tane eklenir.
- **Kernel modülü (`.ko`) ABI'si:** Bunun tam tersi geçerlidir — kernel'in **iç** ABI'si (bir modülün kullanabileceği iç fonksiyonlar/veri yapıları) **hiçbir sürüm garantisi taşımaz**, her kernel derlemesinde değişebilir. Bu yüzden bir donanım sürücüsü modülü, derlendiği kernel sürümüne **tam olarak** eşleşmek zorundadır — `/lib/modules/$(uname -r)/` dizininin adında kernel sürümünün (`uname -r` çıktısı) geçmesinin sebebi tam olarak budur: her kernel sürümü kendi modül ABI'sine sahiptir, sürüm değişince modüller yeniden derlenmelidir (DKMS gibi araçların var olma sebebi de budur — kernel güncellendiğinde üçüncü parti sürücüleri otomatik yeniden derlerler).

> [!TIP]
> **Pratik sonucu: "Bu `.ko` dosyasını başka bir sunucuya kopyalayıp yükleyebilir miyim?" sorusunun cevabı hemen hemen her zaman **hayır**dır (kernel sürümleri birebir aynı olmadıkça) — ama "10 yıl önce derlenmiş bir `ls` binary'sini bugünkü kernelde çalıştırabilir miyim?" sorusunun cevabı **evet**tir. Bu ayrım, "ABI uyumluluğu" derken hangi katmandan bahsedildiğine göre tamamen değişir.**

Bunun yanında bir de **glibc (C kütüphanesi) ABI'si** var: glibc de kendi sembollerini **sürümler** (symbol versioning, `objdump -T` ile görülebilir) — böylece eski bir glibc sürümüne göre derlenmiş bir binary, daha **yeni** bir glibc üzerinde genelde çalışır (ileri uyumluluk), ama yeni glibc'ye göre derlenmiş bir binary çoğu zaman **eski** bir glibc üzerinde çalışmaz (geriye uyumluluk garanti edilmez) — bu, farklı dağıtımlar arası (örn. Ubuntu 24.04'te derlenmiş bir binary'yi Debian 11'de çalıştırma) taşınabilirlik sorunlarının kök nedenidir.

### `ps` — süreç listeleme

`ps`, o an çalışan süreçleri (kernel'in process tablosundan, aslında `/proc/<PID>/` altındaki dosyalardan) okuyup listeler. Tarihsel bir tuhaflık taşır: aynı anda **üç farklı sözdizimi ailesini** destekler, çünkü `ps` UNIX (AT&T) ve BSD dünyalarından gelen iki ayrı gelenek + GNU'nun eklediği uzun parametreleri birleştirir:

| Aile | Örnek | Kural |
|---|---|---|
| UNIX/System V | `ps -ef` | parametreden önce **tek tire** (`-`) |
| BSD | `ps aux` | parametreden önce **tire YOK** |
| GNU uzun form | `ps --sort=-%cpu` | parametreden önce **çift tire** |

Bu yüzden `ps aux` ile `ps -ef` **benzer ama aynı olmayan** çıktılar üretir — ikisi de "tüm kullanıcıların tüm süreçlerini" listeler ama sütun seçimi ve format farklıdır (`aux`'ta `%CPU`/`%MEM`/`START` gibi BSD alanları, `-ef` de `PPID`/`STIME`/`TTY` UNIX alanları öne çıkar). Üç dağıtımda da (Debian, Ubuntu, RHEL/Rocky) `ps` artık aynı **`procps-ng`** paketinden gelir — eski `procps` projesinin devamıdır, bu yüzden `ps`/`top`/`free`/`kill`/`pkill` gibi araçların davranışı dağıtımlar arası neredeyse birebir aynıdır; farklılık paket adında kalır (Debian/Ubuntu `procps`, RHEL/Rocky `procps-ng`).

**Sık kullanılan parametreler:**

| Komut | Anlamı |
|---|---|
| `ps aux` | tüm kullanıcıların tüm süreçleri, terminale bağlı olsun olmasın (BSD stili) |
| `ps -ef` | aynı kapsam, UNIX stili sütunlarla, `PPID` (üst süreç) dahil |
| `ps -u kullanici` | sadece belirtilen kullanıcının süreçleri |
| `ps -p PID` | belirli bir PID'yi göster |
| `ps --forest` | süreç ağacını (parent→child ilişkisini) girintili göster |
| `ps -eo pid,ppid,ni,cmd` | `-o` (özel format) ile sadece istenen sütunları seç |
| `ps -eLf` | LWP/thread seviyesinde göster (`-L` = threads dahil) |

`STAT`/`S` sütunundaki kod harfleri süreç durumunu gösterir: `R` çalışıyor/çalışmaya hazır, `S` uykuda (kesintiye açık bekleme), `D` kesintiye kapalı uykuda (genelde disk I/O bekliyor — bu durumdaki süreç `kill -9` ile bile anında durdurulamaz), `T` durdurulmuş (stopped/traced), `Z` **zombi** (aşağıda ayrı başlık). Harfin yanına gelen `<`/`N`/`s`/`+`/`l` gibi ek karakterler sırasıyla yüksek öncelik, düşük öncelik (nice edilmiş), oturum lideri, ön plan grubu üyesi, çoklu-thread anlamına gelir.

### Root diğer kullanıcıların süreçlerini nasıl görebilir?

Bunun cevabı aslında biraz beklenmedik: **süreçlerin varlığını ve komut satırını görmek için** çoğu Linux sisteminde **root olmaya gerek bile yoktur** — `/proc` dosya sistemi varsayılan olarak her kullanıcıya sistemdeki **tüm** süreçlerin `/proc/<PID>/` dizinini (dolayısıyla `cmdline`, `stat`, `status` gibi temel bilgileri) okuma izni verir; `ps -ef` normal bir kullanıcı olarak çalıştırıldığında da tüm kullanıcıların süreçlerini listeler. Bunu isteyerek kısıtlamak için `/proc`'un **`hidepid`** mount seçeneği kullanılır (`/etc/fstab`'da `proc /proc proc defaults,hidepid=2 0 0` gibi): `hidepid=1` diğer kullanıcıların `/proc/<PID>/` içindeki hassas dosyalarını (örn. `environ`), `hidepid=2` ise dizinin **varlığını bile** normal kullanıcılardan tamamen gizler. Bu seçenek verilmediyse (`hidepid=0`, çoğu dağıtımın varsayılanı) herkes herkesin süreç listesini görür.

Asıl root ayrıcalığı, **süreç hakkında hassas ek bilgilere** erişimde devreye girer — `/proc/<PID>/environ` (o sürecin ortam değişkenleri, içinde parola/token olabilir), `/proc/<PID>/fd/` (açık dosya tanımlayıcıları), `/proc/<PID>/maps` (bellek haritası) gibi dosyalar **sadece sürecin sahibi** tarafından okunabilir izinlerle oluşturulur; bunları başka bir kullanıcının süreci için okumak normalde `Permission denied` verir. Root bu noktada devreye girer: kernel, root'a (daha kesin ifadeyle `CAP_DAC_OVERRIDE`/`CAP_DAC_READ_SEARCH` **capability**'lerine sahip sürece) klasik dosya izin kontrolünü (DAC) **atlama** yetkisi tanır — root bu dosyaları izinlere bakılmaksızın okuyabilir. Ayrıca `kill`, `renice`, `strace`/`ptrace` gibi bir sürece **müdahale eden** işlemler de varsayılan olarak sadece sürecin sahibine izinlidir; root (veya `CAP_KILL`/`CAP_SYS_PTRACE` capability'sine sahip bir süreç) bu kısıtlamayı da aşabilir.

### `nice` ve `renice` — süreç önceliği

Linux'un zamanlayıcısı (modern kernellerde **CFS — Completely Fair Scheduler**), CPU zamanını süreçler arasında **ağırlıklı** olarak paylaştırır; bu ağırlığı belirleyen değer **niceness**'tır. İsmi tam olarak niyetini anlatır: yüksek bir nice değeri, "diğerlerine karşı ne kadar **nazik/uysal**' olduğunu" ifade eder — yüksek nice = CPU'dan daha az pay iste (düşük öncelik), düşük (hatta negatif) nice = CPU'dan daha çok pay iste (yüksek öncelik).

- Aralık: **-20** (en yüksek öncelik) ile **+19** (en düşük öncelik), varsayılan **0**.
- Bu ölçek **doğrusal değil, yaklaşık geometriktir** — her nice biriminin CPU payında yaklaşık %10'luk bir çarpan etkisi vardır, bu yüzden -20 ile 0 arasındaki fark, 0 ile 19 arasındaki farktan çok daha büyüktür.
- **Yetki kısıtı önemli:** normal bir kullanıcı sadece **kendi** sürecinin niceness'ını **artırabilir** (yani sürecini daha da "nazik/düşük öncelikli" yapabilir) — kendi sürecinin önceliğini **düşük değere/negatife çekmek** (yani CPU'da daha fazla hak istemek) veya **başka bir kullanıcının** sürecine dokunmak **root** ister; bunun mantığı açık: aksi halde herkes kendi sürecini `-20` yaparak sistemi tekeline alabilirdi.

```bash
nice -n 10 komut          # komutu YENİ başlatırken niceness=10 (düşük öncelik) ile çalıştır
nice komut                 # parametresiz: varsayılan +10 nice ile başlat
renice -n 5 -p 1234         # ZATEN ÇALIŞAN 1234 PID'li sürecin niceness'ını 5 yap
renice -n -5 -p 1234        # negatif değer — root gerektirir
ps -eo pid,ni,cmd | grep x  # bir sürecin güncel nice değerini gör (NI sütunu)
```

`nice`, **yeni** bir süreç başlatırken kullanılır (komutu sarmalar); `renice`, **hâlihazırda çalışan** bir sürecin önceliğini sonradan değiştirir — ikisi aynı değeri farklı zamanlarda ayarlar.

### `lsusb` ve `lspci`

Kernel, algıladığı her donanım aygıtını **sysfs** üzerinden (`/sys/bus/usb/devices/`, `/sys/bus/pci/devices/`) userspace'e açar — bu ham veri sadece sayısal **vendor:device ID** çiftleridir (örn. `8086:1234`), insan tarafından okunabilir isim içermez. `lsusb` (**usbutils** paketi) ve `lspci` (**pciutils** paketi), bu sysfs verisini okuyup, yerel olarak paketle birlikte gelen ve düzenli güncellenen bir **ID veritabanı** (`/usr/share/misc/usb.ids`, `/usr/share/misc/pci.ids` — Linux USB ID Repository / PCI ID Repository'den türetilir) ile eşleştirerek "Intel Corporation ..." gibi okunabilir isimler üretir. Üç dağıtımda da (Debian/Ubuntu `apt install usbutils pciutils`, Rocky `dnf install usbutils pciutils`) aynı üst-akım (upstream) araçlardır, davranış farkı yoktur — sadece paket adı/kurulum komutu değişir.

```bash
lsusb                 # bağlı USB aygıtlarını listele (bus:device vendor:product isim)
lsusb -v               # her aygıt için TÜM descriptor detaylarını (verbose) göster
lsusb -t                # USB hub/aygıt hiyerarşisini AĞAÇ olarak göster

lspci                  # PCI/PCIe aygıtlarını listele
lspci -v                # verbose — IRQ, bellek adresleri, yetenekler dahil
lspci -k                # her aygıt için kernel'in HANGİ SÜRÜCÜYÜ (driver) yüklediğini göster
lspci -nn               # isimle BİRLİKTE ham [vendor:device] hex ID'lerini de göster
```

`lspci -k` ve `lspci -nn` özellikle donanım/sürücü sorunlarında değerlidir: bir aygıtın adı görünüyor ama sürücü yüklenmemişse (`Kernel driver in use:` satırı boş çıkar), sorun donanım algılama değil sürücü katmanındadır.

### `free` — bellek kullanımı

`free`, kaynağını doğrudan **`/proc/meminfo`**'dan alır (kendisi bir ölçüm yapmaz, kernel'in zaten tuttuğu sayaçları okuyup biçimlendirir).

```bash
free -h        # human-readable (KB yerine "1.2G" gibi)
free -m         # MB cinsinden
free -s 2        # her 2 saniyede bir tekrar göster (izleme modu)
free -w          # "wide" — buffer ve cache sütunlarını AYRI göster (varsayılanda birleşiktirler)
```

En sık kafa karıştıran nokta **`available`** sütunudur: eski `free` çıktısındaki "free" (boş) bellek düşük görünse de bu **sorun değildir** — Linux, kullanılmayan RAM'i **disk cache** olarak kullanır (I/O hızlandırmak için), bu bellek bir uygulama talep ettiği an **anında geri verilir**. `available` sütunu, kernel'in "gerçekte, bir uygulama şu an ne kadar bellek talep edebilir" hesaplamasının sonucudur (basit bir `free + buffers + cache` toplamından daha isabetlidir, çünkü bazı cache sayfaları geri alınamaz durumdadır) — bir sistemin bellek durumunu değerlendirirken bakılması gereken asıl sütun budur, "free" sütunu değil.

### `top` — canlı süreç izleme

`top`, `ps`'in **anlık görüntüsünün** aksine, ekranı düzenli aralıklarla (varsayılan 3 sn) yeniden çizen **etkileşimli** bir izleme aracıdır; kaynağı yine `/proc` (her tur `/proc/[PID]/stat` ve `/proc/meminfo` gibi dosyaları yeniden okur).

Üst kısımdaki **load average** üç sayısı (örn. `0.42, 0.38, 0.29`), sırasıyla son **1, 5, 15 dakikalık** ortalama sistem yükünü gösterir — "çalışmaya hazır ama CPU bekleyen + kesintiye kapalı (D durumu) süreç sayısı"nın ortalamasıdır; bu sayı CPU çekirdek sayısına göre yorumlanmalıdır (4 çekirdekli bir sistemde `4.0`, çekirdeklerin tam dolu olduğu anlamına gelir; `8.0` iki katı yük demektir).

Sütunlar: `PR` (kernel'in gördüğü gerçek öncelik, `nice`'tan RT süreçler için farklılaşabilir), `NI` (niceness), `VIRT` (sürecin talep ettiği toplam sanal bellek), `RES` (fiziksel RAM'de gerçekten tutulan kısım — asıl bakılması gereken sütun genelde budur), `SHR` (paylaşılan bellek, örn. ortak kütüphaneler), `S` (durum kodu, `ps`'teki ile aynı harfler).

**Etkileşimli tuşlar:** `P` CPU'ya göre sırala, `M` belleğe göre sırala, `k` bir PID'ye sinyal gönder (kill), `r` bir PID'yi renice et, `1` çekirdek başına ayrı CPU satırı göster, `q` çık.

### `kill` ve sinyaller

`kill`, ismine rağmen "öldürmekten" çok daha genel bir işi yapar: bir sürece **sinyal gönderir**; sürecin bu sinyale nasıl tepki vereceği (yakalama/işleme/görmezden gelme) o sürecin kendi sinyal tablosuna bağlıdır — `kill` sadece kernel aracılığıyla sinyali **iletir**.

- **Ön tanımlı (parametresiz) sinyal: `SIGTERM` (15)** — sürece "lütfen düzgünce kapan" der; süreç bunu **yakalayabilir**, açık dosyaları kapatıp/geçici verileri temizleyip kendi isteğiyle çıkabilir. Bu yüzden normal kapatma işlemlerinde her zaman önce `SIGTERM` denenmelidir.
- **`SIGKILL` (9)** — kernel'in sürece **doğrudan, hiçbir işlem yaptırmadan** son verdiği, **yakalanamayan/engellenemeyen** tek sinyaldir; süreç temizlik yapamaz (açık dosyalar/kilitler tutarsız kalabilir) — bu yüzden **son çare** olmalıdır, `SIGTERM` işe yaramadığında kullanılır.

```bash
kill PID              # varsayılan: SIGTERM gönder
kill -9 PID             # SIGKILL — zorla, yakalanamaz
kill -SIGKILL PID        # aynı şey, isimle
kill -l                  # TÜM sinyal isim/numaralarını listele
```

`kill -l` çıktısında görülen başlıca sinyaller: `1) SIGHUP` (terminal bağlantısı koptu / bazı servislerde "config'i yeniden oku" anlamında kullanılır — `logrotate`'in `postrotate` adımında geçecek), `2) SIGINT` (Ctrl+C), `3) SIGQUIT`, `9) SIGKILL`, `15) SIGTERM`, `18) SIGCONT` (durdurulmuş süreci devam ettir), `19) SIGSTOP` (SIGKILL gibi yakalanamaz — süreci duraklat).

### Zombi süreç nedir, neden ortaya çıkar, nasıl yönetilir?

Bir sürecin ölüm süreci iki aşamalıdır ve bu, Unix süreç modelinin **temel** bir tasarım kararıdır: bir süreç `exit()` çağırdığında kernel onu **anında tamamen silmez** — çünkü üst süreç (parent), çocuğun **çıkış kodunu** (`exit status`, örn. başarılı mı 0 mı döndü, hangi hata koduyla çıktı) `wait()`/`waitpid()` sistem çağrısıyla okumak isteyebilir. Kernel bu yüzden süreci **zombi (Z)** durumuna alır: bellek/açık dosyalar gibi her şey serbest bırakılır, sadece process tablosunda **PID + çıkış kodu**'ndan ibaret minimal bir kayıt kalır, parent bunu `wait()` ile "toplayana" (**reap** etmesine) kadar.

- **Neden ortaya çıkar:** parent süreç, çocuğunun bittiğini bildiren `SIGCHLD` sinyalini alır ama `wait()` çağırmayı **ihmal ederse** (kötü yazılmış bir program, ya da kasıtlı olarak sinyali görmezden gelen bir servis) zombi kalıcı hâle gelir.
- **Neden `kill` ile "temizlenemez":** zombi zaten **ölü**dür — çalışan bir süreç değildir, hiçbir kod çalıştırmaz, sinyal gönderilecek aktif bir şey yoktur (`kill -9` bir zombiye gönderilse bile hiçbir etkisi olmaz). Zombiyi ortadan kaldırmanın tek yolu, **parent'ın `wait()` çağırmasını sağlamaktır**.
- **Pratik yönetim:** genelde asıl hedef parent'tır — parent süreci **düzgün kapatıp yeniden başlatmak** (`systemctl restart <servis>`), tüm çocuklarını da beraberinde reap eder. Parent zaten ölmüşse (ya da hiç yoksa), o zombiler otomatik olarak **PID 1**'e (systemd/init) **reparent** edilir — systemd, kendisine devrolan tüm "yetim" (orphan) süreçleri **düzenli olarak `wait()` ile reap eden** bir döngü çalıştırır, bu yüzden PID 1'e devrolmuş zombiler kısa sürede kendiliğinden temizlenir. Gerçekten temizlenemeyen inatçı bir zombi varsa, çare neredeyse her zaman **parent'ı** (veya son çare olarak sistemi) yeniden başlatmaktır.
- **Kaynak tüketimi:** bir zombi bellek/CPU harcamaz (zaten tüm kaynakları serbest bırakılmıştır) — tek kısıtlı kaynağı **PID numarası** işgal etmesidir; binlerce zombi birikirse (PID tükenmesi teorik olarak mümkün) sistem yeni süreç başlatamaz hâle gelebilir, ama tek/birkaç zombi pratikte zararsızdır.

### Sunucu servisleri — Debian 13, Ubuntu 24, Rocky (systemd mimarisi)

Üç dağıtım da bugün **systemd**'yi init sistemi (PID 1) olarak kullanır — eski `/etc/init.d/` SysVinit script mimarisi artık sadece **geriye dönük uyumluluk** için (systemd'nin dahili `systemd-sysv-generator`'ı bu script'leri otomatik olarak birer systemd unit'iymiş gibi sarmalar) varlığını sürdürür.

**Servis dosyalarının bulunduğu dizinler — ve NEDEN üç ayrı katman var:**

systemd bir unit dosyasını (`.service`, `.timer`, `.socket` vb.) ararken **üç** dizine, sabit bir öncelik sırasıyla bakar:

| Öncelik | Dizin | Kim yazar / ne zaman kullanılır |
|---|---|---|
| 1 (en yüksek) | `/etc/systemd/system/` | **sistem yöneticisinin** kendi elle yazdığı/özelleştirdiği unit'ler ve `systemctl edit` ile oluşturulan override (drop-in) dosyaları |
| 2 | `/run/systemd/system/` | **çalışma anına özel, geçici** unit'ler — reboot'ta silinir (örn. bazı servislerin dinamik ürettiği unit'ler) |
| 3 (en düşük) | `/usr/lib/systemd/system/` (Debian 13/Ubuntu 24'te usrmerge sonrası `/lib` buraya symlink; Rocky/RHEL zaten uzun süredir bu yapıda) | **paket yöneticisinin** (`apt`/`dnf`) kurduğu, dağıtımın/yazılımın kendi sağladığı **vendor** (fabrika ayarı) unit dosyaları |

Bu üç katmanın **var olma sebebi** tam olarak `/etc/passwd` vs `/etc/shadow` ayrımındaki mantıkla aynı prensibe dayanır: **paket güncellemeleri, senin özelleştirmeni asla ezmemeli.** `apt upgrade`/`dnf update` bir paketi güncellediğinde sadece 3. katmandaki (`/usr/lib/...`) dosyayı değiştirir; 1. katmandaki (`/etc/systemd/system/...`) senin override'ın dokunulmadan kalır ve hâlâ üstün gelir. Bu yüzden bir vendor unit dosyasını **doğrudan** `/usr/lib/systemd/system/` içinde düzenlemek yanlıştır (bir sonraki güncellemede kaybolur) — doğru yol `systemctl edit <servis>` ile `/etc/systemd/system/<servis>.service.d/override.conf` içinde bir **drop-in** dosyası oluşturmaktır (bu konu daha önce CL-Egitim materyaline de eklendi, bkz. `08-surec-yonetimi.md`).

**Bir servisin işlevi/çalışma mantığı — unit dosyasının anatomisi:**

```ini
[Unit]
Description=Kısa açıklama
After=network.target          # BAŞLAMA SIRASI: network.target'tan SONRA başlat (bağımlılık değil, sadece sıra)
Requires=postgresql.service     # GERÇEK bağımlılık: bu servis olmadan başlamamalı

[Service]
Type=simple                     # simple/forking/oneshot/notify — süreç modeli
ExecStart=/usr/bin/uygulama --config /etc/uygulama.conf
Restart=on-failure               # çökerse otomatik yeniden başlat
User=uygulama-servis              # HANGİ kullanıcı kimliğiyle çalışacak

[Install]
WantedBy=multi-user.target        # `systemctl enable` bu servisi hangi target'a bağlar
```

- `[Unit]` — kimlik ve **bağımlılık/sıralama** bilgisi (`After=`/`Before=` sadece sıralama, `Requires=`/`Wants=` gerçek bağımlılık ifade eder — bu ayrım sık karıştırılır).
- `[Service]` — servisin **nasıl çalıştırılacağı** (hangi binary, hangi kullanıcı, çökerse ne olacak).
- `[Install]` — servis **`enable` edildiğinde** hangi target'a (systemd'nin "runlevel" karşılığı, örn. `multi-user.target` ≈ eski runlevel 3) bağlanacağı; bu bölüm sadece `enable`/`disable` sırasında okunur, `start`/`stop` ile ilgisi yoktur.

**Bir servisin nasıl incelenir, hangi bilgilere nereden erişilir:**

```bash
systemctl status sshd          # anlık durum: aktif mi, ne zamandır, son birkaç log satırı
systemctl cat sshd              # unit dosyasının GERÇEK, birleştirilmiş (vendor + override) içeriğini göster
systemctl show sshd             # TÜM özellik/parametreleri (env, limitler, cgroup yolu) ham liste olarak göster
systemctl list-dependencies sshd   # bu servisin bağımlılık ağacı
journalctl -u sshd                # SADECE bu servise ait logları (journald üzerinden)
```

`systemctl cat`, `systemctl edit` ile eklenmiş override'ların **vendor dosyayla birleşmiş son hâlini** gösterdiği için, "bu servis şu an gerçekte hangi ayarlarla çalışıyor" sorusuna en doğru cevabı verir — sadece `/usr/lib/.../*.service` dosyasını okumak, üstüne binen override'ları kaçırabilir.

### Log tutma — dosyaya doğrudan yazma, syslog, rsyslog, journald

Bir uygulamanın ürettiği log mesajı, sistemde üç farklı **katmanda** ele alınabilir; ders sırasında bu üçü birlikte anlatılmış:

**1) Dosyaya doğrudan yazma** — en basit yöntem: uygulama kendi log dosyasını (örn. bir web sunucusunun `access.log`'u) kendisi açar, kendisi yazar, kendisi döndürür (rotate). Basittir ama **merkezi yönetimi yoktur** — her uygulamanın kendi formatı, kendi konumu vardır; sistem çapında "son 1 saatte ne oldu" sorusuna cevap vermek için tek tek her dosyaya bakmak gerekir.

**2) syslog** — 1980'lerden kalma, tüm Unix dünyasında ortak bir **protokol/model**dir (RFC 3164, sonra RFC 5424 ile standartlaştı): her mesaj bir **facility** (kaynağın türü: `kern`, `auth`, `cron`, `daemon`, `mail`, `local0-7`...) ve bir **severity** (önem derecesi: `emerg`, `alert`, `crit`, `err`, `warning`, `notice`, `info`, `debug`) etiketiyle gönderilir. syslog kendisi bir protokoldür, **uygulaması** (daemon'u) farklı olabilir — bugün bu daemon rolünü çoğu Linux sisteminde **rsyslog** üstlenir.

**3) rsyslog** — "**r**eliable syslog", klasik syslog daemon'unun (`sysklogd`) modernleştirilmiş, TCP/TLS üzerinden **güvenilir** iletim, filtreleme, uzak sunucuya yönlendirme (merkezi log sunucusu kurma) gibi yetenekler eklenmiş hâlidir. Yapılandırması `/etc/rsyslog.conf` + `/etc/rsyslog.d/*.conf` altındadır; facility.severity kurallarıyla hangi mesajın hangi dosyaya yazılacağını belirler (örn. `auth,authpriv.* /var/log/auth.log`). Derste "en çok kullanılan" diye vurgulanmasının sebebi budur: journald'in binary/yapısal yaklaşımına rağmen, **kurumsal ortamlarda düz metin log dosyaları ve merkezi syslog sunucularına yönlendirme** hâlâ endüstri standardıdır ve rsyslog bunun fiili aracıdır.

> [!WARNING]
> **Dağıtım farkı — rsyslog her zaman kurulu gelmeyebilir: **Ubuntu Server 24.04**'te rsyslog varsayılan olarak kuruludur. **Debian 12+**'ta minimal/netinst kurulumlarda rsyslog **varsayılan olarak kurulu DEĞİLDİR** (sadece journald vardır, `/var/log/syslog` boş kalabilir) — `apt install rsyslog` ile elle kurulması gerekir. **Rocky/RHEL 9**'da da minimal kurulumda rsyslog genelde kurulu değildir (`dnf install rsyslog` gerekir); DVD/graphical kurulumlarda kurulu gelebilir. Bir sistemde `/var/log/syslog` ya da `/var/log/messages` boş/yoksa, ilk kontrol edilecek şey `systemctl status rsyslog`'un o serviste **hiç mevcut olup olmadığı**dır.**

**4) systemd altında journal yapısı** — `systemd-journald`, systemd'nin kendi **yapısal (structured), binary** log sistemidir. Her mesaja otomatik olarak zengin **metadata** eklenir (hangi systemd unit, hangi PID/UID/GID, hangi boot oturumu, tam zaman damgası) — bu, düz metin syslog satırlarında elle regex ile çıkarılması gereken bilgilerin **sorgu zamanında hazır** gelmesi demektir.

```bash
journalctl                    # tüm journal kayıtlarını göster (en son en altta)
journalctl -u ssh              # sadece 'ssh' unit'ine ait kayıtlar
journalctl -b                   # sadece BU boot oturumuna ait kayıtlar
journalctl -f                    # canlı takip (tail -f gibi)
journalctl --since "1 hour ago"   # zaman aralığına göre filtrele
journalctl -p err                 # sadece err ve üzeri önem derecesindeki kayıtlar
journalctl -k                      # sadece kernel mesajları (dmesg'in journal karşılığı)
```

Journal'ın **kalıcılığı** (`Storage=` ayarı, `/etc/systemd/journald.conf`) varsayılan olarak `auto`'dur — bu, `/var/log/journal/` dizininin **var olup olmamasına** göre iki farklı davranışa yol açar, ve burada dağıtımlar ayrışır:

> [!WARNING]
> **Dağıtım farkı — journal kalıcılığı: **Debian**, paket kurulumu sırasında `/var/log/journal/` dizinini **önceden oluşturur** — bu yüzden `Storage=auto` Debian'da fiilen **kalıcı** (disk üzerinde, reboot'ta kaybolmayan) davranır. **RHEL/Rocky**'de bu dizin varsayılan olarak **yoktur** — aynı `Storage=auto` ayarı bu sefer **volatile** (sadece `/run/log/journal/`, bellekte, **reboot'ta tamamen silinen**) davranışa düşer. Rocky/RHEL'de logları kalıcı yapmak için elle `mkdir -p /var/log/journal && systemd-tmpfiles --create --prefix /var/log/journal` çalıştırmak gerekir.**

Ubuntu 24.04'te tipik zincir şudur: **uygulama → journald (binary, önce burada toplanır) → rsyslog (journald'i `imjournal`/varsayılan yapılandırmayla okur) → `/var/log/*.log` (düz metin dosyaları) → logrotate.** Yani journald ve rsyslog genelde **birbirinin yerine değil, birlikte** çalışır — journald tüm mesajları tek merkezi, sorgulanabilir bir kaynakta tutar; rsyslog bunları geleneksel dosya yapısına da yazarak eski araçlarla (`grep`, `tail`, merkezi log sunucusuna gönderme) uyumluluğu korur.

### `/var/log` dizini

FHS'ye (Filesystem Hierarchy Standard) göre `/var`, adı üstünde **değişken (variable)** veriler için ayrılmıştır — `/usr`'ın aksine (statik, paket kurulumuyla gelen, salt-okunur olabilecek dosyalar) `/var` altındaki her şeyin **çalışma zamanında sürekli büyüyüp değişmesi** beklenir (loglar, spool'lar, cache'ler, veritabanı dosyaları). Bu yüzden `/var` genelde ayrı bir disk bölümüne (partition) konur — bir logun taşması, `/` (kök) dosya sistemini dolduramasın diye.

Tipik içerik (kurulu servislere göre değişir):

| Dosya/dizin | İçeriği |
|---|---|
| `/var/log/syslog` (Debian/Ubuntu) veya `/var/log/messages` (RHEL/Rocky) | rsyslog'un ürettiği genel sistem logu |
| `/var/log/auth.log` (Debian/Ubuntu) veya `/var/log/secure` (RHEL/Rocky) | kimlik doğrulama olayları — `sudo`, `su`, SSH giriş denemeleri |
| `/var/log/kern.log` | sadece kernel mesajları |
| `/var/log/journal/` | journald'in binary kayıtları (kalıcıysa) |
| `/var/log/dpkg.log` / `/var/log/apt/` (Debian/Ubuntu) — `/var/log/dnf.log`, `/var/log/dnf.rpm.log` (Rocky) | paket kurulum/güncelleme geçmişi |
| `/var/log/wtmp`, `/var/log/btmp`, `/var/log/lastlog` | **binary** formatlı giriş kayıtları — düz metin editörüyle okunmaz, `last`/`lastb`/`lastlog` komutlarıyla okunur |

### Zamanlanmış görevler — cron, crontab, `/etc/cron.d`

> [!NOTE]
> **Küçük bir düzeltme: ders notlarında dizin adı "`/etc/crontab.d`" olarak geçiyor; gerçek/standart dizin adı **`/etc/cron.d/`**'dir (ayrıca `/etc/crontab` diye **tekil, ayrı bir dosya** da vardır — ikisi farklı şeyler, aşağıda ayrıştırılıyor).**

`cron` daemon'u, her dakika uyanıp kendi kural kaynaklarını kontrol eden bir zamanlayıcıdır. Kuralların yazıldığı **satır formatı** hep aynıdır:

```
dakika  saat  ay-günü  ay  hafta-günü  KOMUT
  *       *      *      *       *      /yol/komut
0        3      *      *       0       /usr/local/bin/yedekle.sh   # her Pazar 03:00'te çalıştır
```

Ama bu satırların **nerede** durduğuna göre bir **kullanıcı alanı gerekip gerekmediği** değişir — bu, cron mimarisinin en can alıcı noktasıdır:

| Kaynak | Format | Neden farklı |
|---|---|---|
| `crontab -e` (kullanıcının **kendi** crontab'ı, `/var/spool/cron/crontabs/<kullanici>` (Debian) ya da `/var/spool/cron/<kullanici>` (RHEL) altında saklanır) | 5 alan + komut (**kullanıcı alanı YOK**) | dosyanın kendisi zaten belirli bir kullanıcıya ait — kim çalıştıracağı örtük olarak bellidir |
| `/etc/crontab` (tekil, sistem geneli dosya) | 5 alan + **kullanıcı** + komut | bu dosya **root** tarafından okunur/çalıştırılır; her satırın **hangi kullanıcı kimliğiyle** çalışacağı açıkça belirtilmek zorundadır |
| `/etc/cron.d/*` (paketlerin bıraktığı ayrı dosyalar) | 5 alan + **kullanıcı** + komut (aynı `/etc/crontab` mantığı) | `/etc/crontab`'ın **modüler** hâli — bir paket kurulurken kendi zamanlanmış görevini, ana dosyayı hiç düzenlemeden buraya bırakabilir (mantığı `/etc/sudoers.d/` ile birebir aynı: paket güncellemesi sırasında üzerine yazılma riski olmadan, kolayca eklenip kaldırılabilir) |
| `/etc/cron.{hourly,daily,weekly,monthly}/` | **komut yok, sadece çalıştırılabilir script** dosyaları | `/etc/crontab`'daki bir satır bu dizinlerin içeriğini `run-parts` ile toplu çalıştırır — "her gün çalışacak bir şey ekle" demek, burada sadece bir script bırakmak kadar basit hâle gelir, cron sözdizimiyle hiç uğraşmadan |

### `logrotate`

Log dosyaları sınırsız büyürse diski doldurur — `logrotate`, belirli aralıklarla (günlük/haftalık/aylık) veya boyuta göre bir log dosyasını **kapatıp yeniden adlandırır** (`app.log` → `app.log.1`), isteğe bağlı sıkıştırır (`app.log.1.gz`), eski kopyaları belirli sayıdan sonra siler, ve **yeni, boş** bir `app.log` açar.

**Neden sadece dosyayı yeniden adlandırmak yetmiyor, uygulamaya haber vermek gerekiyor:** bir uygulama log dosyasını açtığında, işletim sistemi seviyesinde dosyayı **inode** üzerinden, açık bir **dosya tanımlayıcısı (file descriptor)** ile tutar — dosya adı sadece bir "etiket"tir. `logrotate` dosyayı `mv` ile yeniden adlandırdığında, uygulamanın elindeki file descriptor **hâlâ eski (artık `app.log.1` olan) inode'u** göstermeye devam eder — uygulama farkında olmadan **artık kimsenin görmediği** bir dosyaya yazmaya devam eder. Bu yüzden `logrotate` yapılandırmalarında **`postrotate`/`endscript`** bloğu bulunur: rotasyondan hemen sonra uygulamaya (genelde `SIGHUP` sinyaliyle ya da `systemctl reload`) "log dosyanı **yeniden aç**" der; uygulama bu sinyali yakalayıp dosyayı adından tekrar açar, artık gerçekten **yeni** `app.log`'a yazmaya başlar.

**Yapılandırma:** `/etc/logrotate.conf` genel varsayılanları tanımlar ve `/etc/logrotate.d/*` altındaki paket-bazlı dosyaları `include` eder (yine `/etc/cron.d/` ile aynı modülerlik mantığı — her paket kendi log rotasyon kuralını kendi dosyasında tanımlar):

```
/var/log/uygulama.log {
    daily              # günlük rotasyon
    rotate 7            # 7 eski kopya tut, sonrasını sil
    compress             # eski kopyaları gzip'le
    delaycompress          # BİR ÖNCEKİ kopyayı sıkıştırma (o an okunuyor olabilir), bir sonraki turda sıkıştır
    missingok               # dosya yoksa hata verme, sessizce geç
    notifempty               # dosya boşsa rotasyon yapma
    create 0640 www-data adm   # yeni dosyayı bu izin/sahiplikle oluştur
    postrotate
        systemctl reload uygulama > /dev/null 2>&1 || true
    endscript
}
```

**Tetikleme mekanizması:** `logrotate`'in kendisi bir daemon **değildir** — sadece çalıştırıldığında kontrol yapıp gerekiyorsa rotasyon uygulayan bir **script/binary**'dir; birinin onu düzenli aralıklarla **çağırması** gerekir. Modern Debian/Ubuntu ve RHEL/Rocky'de bu artık eski `/etc/cron.daily/logrotate` girdisi yerine bir **systemd timer** (`logrotate.timer`, `OnCalendar=daily`) ile tetiklenir — yukarıdaki "servis mimarisi" bölümünde anlatılan `.timer` unit türünün gerçek bir üretim örneğidir.

## Notlar

- Bugünün ana teması: **süreç yaşam döngüsü** (fork → çalışma → sinyal → exit → reap) ile **log/servis mimarisinin katmanlı yapısı** birbirine paralel iki fikir taşıyor — ikisinde de "üç katman, en yüksek öncelikli olan kazanır" deseni tekrar ediyor (systemd unit'lerde `/etc` > `/run` > `/usr/lib`; loglamada uygulama-log → syslog/rsyslog → journald hepsi aynı olayı farklı katmanlarda tutuyor).
- Zombi süreçler ile "servis nasıl incelenir" konusu aslında birbirine bağlı: `ps`'te `Z` durumunu gördüğünde ilk bakılacak yer PPID'sidir (`ps -eo pid,ppid,stat,cmd`) — parent kimse, sorunun kaynağı orasıdır.
- `nice`/`renice`'daki "kendi sürecini düşük öncelik yapabilirsin ama yükseltemezsin" kuralı ile `sudoers`'taki "kendi yetkini genişletemezsin" mantığı aynı güvenlik prensibinin (ayrıcalık yükseltmeyi engelleme) farklı alt sistemlerdeki tekrarı.
- `/etc/cron.d/`, `/etc/sudoers.d/`, `/etc/logrotate.d/`, `systemd`'nin `/etc/systemd/system/*.d/` override dizinleri — hepsi aynı **modüler yapılandırma deseni**ni (ana dosyaya dokunmadan, paket bazlı ek dosyalarla genişletme) tekrar tekrar kullanıyor; bu deseni bir kere kavrayınca Linux'ta yeni bir yapılandırma sistemiyle karşılaşınca nereye bakılacağını tahmin etmek kolaylaşıyor.

## Komutlar / Örnekler

```bash
# süreç izleme
ps aux
ps -ef
ps -eo pid,ppid,ni,stat,cmd
ps --forest
top
free -h
free -w

# öncelik
nice -n 10 komut
renice -n 5 -p 1234

# donanım
lsusb
lsusb -t
lspci
lspci -k
lspci -nn

# sinyal / süreç sonlandırma
kill PID
kill -9 PID
kill -l

# systemd servis inceleme
systemctl status sshd
systemctl cat sshd
journalctl -u sshd
journalctl -b -p err

# log / journal
journalctl -f
journalctl --since "1 hour ago"
journalctl -k

# cron
crontab -e
crontab -l
cat /etc/crontab
ls /etc/cron.d/
ls /etc/cron.daily/

# logrotate
cat /etc/logrotate.conf
ls /etc/logrotate.d/
sudo logrotate -d /etc/logrotate.conf   # -d: DRY RUN, gerçek rotasyon yapmadan ne yapacağını göster
sudo logrotate -f /etc/logrotate.conf   # -f: FORCE, koşullara bakmadan hemen rotasyon yaptır
```

## Sorular / Takip Edilecekler

- [ ] `hidepid` mount seçeneğini kendi VM'de deneyip (`/etc/fstab`'a `hidepid=2` ekleyip) `ps -ef`'in başka kullanıcının süreçlerini gerçekten gizlediğini doğrula.
- [ ] Kendi VM'de `/var/log/journal/` dizininin var olup olmadığını kontrol et (`ls -la /var/log/journal 2>/dev/null || echo yok`) — Debian 13 olduğu için kalıcı olması beklenir, doğrula.
- [ ] Basit bir zombi süreç senaryosunu elle üretip (`fork()` sonrası parent'ı `wait()` çağırmadan uyutan küçük bir C/bash örneği) `ps`'te `Z` durumunu canlı gözlemle.
