---
tags:
  - egitim/linux-sistem-yonetimi
tarih: 2026-08-25
konular:
  - FHS derinlemesine tekrar
  - Açık dosya tanıtıcısı ile silinen dosyayı kurtarma
  - Sıkıştırma/arşivleme (gzip, xz, tar)
  - ASCII ve HEX ilişkisi
  - Paket yönetim sistemleri (apt ve genel mantık)
---

# Gün 4 Raporu

Bağlantı: [Linux Sistem Yönetimi Eğitimi](../README.md) · [00 - Eğitim Planı](../00%20-%20Eğitim%20Planı.md) · [Gün 3](Gün%203.md) · [Gün 5](Gün%205.md)

## İşlenen Konular

- FHS derinlemesine: bölümlerin amaçları, içerikleri ve dikkat edilmesi gereken alanları.
- Paket yöneticisi nedir, ne işe yarar — derinlemesine incelenmeli.

Örnek bir soru: bir mp3 dosyasını terminal üzerinde açtım, çalıyor. Çalarken mp3 dosyasını sildim. Devam eden bir süreç olduğu için inode'a bağlı bir process var; dosya hâlâ disk içinde — bunu kurtarmanın bir yolu var mı?

Dosya sıkıştırma metodları: `gzip`, `xz`, `tar` — bunların kullanımı ve parametreleri işlendi.

ASCII ve HEX arasındaki farklar nelerdir?

---

Paket yönetim sistemleri nelerdir?
Paket yönetim sistemlerinin farkları nelerdir?
Paket yönetim sistemlerinin yükleme, silme ve güncelleme metodları nelerdir?
Paket yönetim sistemlerinde repoların önemi ve mantığı, dağıtım repoları arasındaki farklar nelerdir?

Linux server dağıtımlarında paket yönetim yazılımları nelerdir?

`apt` komutu ve parametreleri.

## Genişletilmiş Anlatım (Öğrenme İçin Ek Açıklamalar)

> [!WARNING]
> **Yukarıda bulunan kısa notların AI ile genişletilmiş halidir. Bilgiler sadece o gün işlenen konular ile sınırlandırılmış olup referans olması için eklenmiştir. Lütfen bu genişletilmiş metni kendi araştırmalarınıza bir ön bilgi olarak kullanın ve testlerinizi sadece burayı kullanarak değil, farklı kaynaklardan da yararlanarak yapın.**

### FHS'nin derinlemesine tekrarı — Gün 3'ün üzerine

Bugün tekrar edilen FHS konusunu (`/bin`, `/etc`, `/var`, `/tmp`, `/home`, `/opt`...) ve her dizinin **neden** o şekilde ayrıldığını (tarihsel `/usr` ayrımı ve `usr-merge`, `/var`'ın ayrı bölüm olmasının kökü log taşmasından koruması, `/tmp`'nin `tmpfs` olması, `/etc`'nin program kodundan ayrı tutulması) [Gün 3#Dizin yapısı (FHS) — hangi dizin ne işe yarar, ve **neden** böyle ayrılmış](Gün%203.md#dizin-yapısı-fhs-hangi-dizin-ne-işe-yarar-ve-neden-böyle-ayrılmış) bölümünde satır satır işledik — burada tekrar yazmak yerine oraya yönlendiriyorum.

**Bugünkü tekrarın vurguladığı ek nokta:** FHS bir **kural (standart)** olduğu için, dağıtımlar arası taşınabilirlik sağlar ama **zorunlu kılınmaz** — `/opt`, `/srv` gibi dizinlerin içeriği dağıtıma göre değişebilir, `/usr/local` senin (paket yöneticisi dışında) elle kurduğun şeyler içindir ve paket güncellemeleri buraya asla dokunmaz. "Dosyayı nereye koyayım / nerede ararım" sorusunun cevabı çoğu zaman FHS'de yazılıdır (`man hier` de aynı bilgiyi sistemin kendi manual'ından verir).

Bugünün asıl yeni konusu, dosyanın "silinmesi" ile "kernel'in onu gerçekten serbest bırakması" arasındaki farkın **canlı bir senaryoda** ne anlama geldiği.

### mp3 çalarken silinen dosya — "hayalet dosya" senaryosu ve kurtarma yöntemi

**Mekanizma:** Bu, Gün 3'te gördüğün bir gerçeğin doğrudan pratiğe dökülmüş hâlidir: *"Bir inode, `st_nlink` sıfıra düşse bile, onu açık tutan en az bir süreç varsa disk üzerinde yaşamaya devam eder."*

- **Ne oluyor:** `mpg123 sarki.mp3` gibi bir komut dosyayı `open()` ile açar; kernel ona bir **dosya tanıtıcısı (file descriptor, fd)** verir. Bu fd doğrudan dosyanın **inode'una** bağlıdır, **adına** değil.
- **Sen `rm sarki.mp3` yapınca:** kernel sadece dizin girdisini (`"sarki.mp3" → inode_no`) siler, `st_nlink`'i bir azaltır. Ama oynatıcının hâlâ açık fd'si olduğundan "veriyi gerçekten sil" kuralı (`st_nlink == 0` **VE** açık fd == 0) sağlanmamıştır — veri diskte **tamamen sağlam**, sadece **hiçbir dizinden erişilemez** ("hayalet" dosya).
- **Müzik neden devam ediyor:** oynatıcı dosyayı zaten isimle değil **fd ile** okuyor; silme ismi kaldırır, fd'yi değil.

**5N1K:**
- **Ne zaman kurtarma mümkün:** sadece o dosyayı açık tutan süreç **hâlâ çalışırken**. Süreç kapanırsa fd kapanır, açık fd 0'a düşer, kernel veriyi serbest bırakır — kurtarma penceresi kapanır.
- **Neden `/proc/<pid>/fd/` işe yarıyor:** `man 5 proc`'a göre `/proc/<pid>/fd/` her sürecin açık tuttuğu fd'leri **symlink gibi görünen girdilerle** dışa vurur. Silinmiş ama açık dosyanın linki `... (deleted)` etiketiyle görünmeye devam eder ve isme değil doğrudan **inode'a** işaret ettiğinden hâlâ **okunabilir**.
- **Kim:** dosyaya erişim izni olan kullanıcı (genelde sürecin sahibi ya da root).

```bash
# 1. Dosyayı çalan sürecin PID'ini bul
pgrep mpg123                      # ya da: lsof | grep "sarki.mp3 (deleted)"

# 2. O sürecin açık fd listesine bak, "(deleted)" etiketli olanı bul
ls -l /proc/<PID>/fd/
# lr-x------ 1 ucp ucp 64 ... 3 -> /home/ucp/sarki.mp3 (deleted)

# 3. O fd'yi normal dosyaymış gibi kopyala — veri hâlâ orada
cp /proc/<PID>/fd/3 kurtarilan.mp3
```

> [!TIP]
> **Bu numara sadece mp3 için değil, **her türlü açık dosyada** işe yarar — yanlışlıkla sildiğin bir log dosyasını, üzerine yazan servis kapanmadan aynı yöntemle kurtarabilirsin. "Disk dolu görünüyor ama `du` boş gösteriyor" bulmacasının çözümü de aynı mekanizmaya dayanır (`lsof | grep deleted`); bu, Gün 6'daki zombi/reap konusuyla aynı "kaynak, ona referans veren varken serbest bırakılmaz" fikrinin bir başka yüzü.**

### Sıkıştırma ve arşivleme — `tar`, `gzip`, `xz` gerçekte ne yapar

**Kavram karışıklığını netleştir: `tar` bir sıkıştırma aracı DEĞİLDİR.**

**`tar` (tape archive) — arşivleme:**
`tar`'ın tek işi, birden çok dosyayı (izinler, sahiplik, dizin yapısı korunarak) art arda **tek bir akışa** eklemektir — sıkıştırmaz, "paketler". Adı tesadüf değil: 1970'lerde **kendi dosya sistemi olmayan sıralı I/O aygıtlarına** (manyetik teyp) yazmak için tasarlandı. Format: her dosyanın önüne 512 baytlık bir başlık bloğu; dosya verisi olduğu gibi, sonuna 512'nin katına tamamlayacak sıfır dolgu; arşivin sonu en az iki sıfır blokla işaretlenir. POSIX bunu **ustar** (ve genişletmesi **pax**) olarak standartlaştırdı.

- **Neden `.tar` içindeki tek dosyaya rastgele erişemezsin:** teyp tasarımının sonucu — merkezi "içindekiler" tablosu (central directory) **yoktur**; arşivi baştan sıralı okumak zorundasın. `.zip`'in farkı budur (zip her dosyanın nerede başladığını gösteren bir dizin tutar).
- **5N1K:** *Ne* = çoklu dosyayı tek akışa birleştiren arşivleyici. *Nasıl* = başlık + veri + dolgu blokları zinciri. *Ne zaman* = yedekleme, taşıma, dağıtım öncesi. *Neden* = teyp/sıralı ortamda dosya sistemi olmadan çoklu dosya saklamak; izin/sahiplik/symlink korumak (düz `cp` her zaman korumaz). *Kim* = kullanıcı; `tar` sistemin ayrıcalığına dokunmaz.

**`gzip` / `xz` — asıl sıkıştırma:**
Bunlar **dosya/dizin kavramını bilmez** — sadece "gelen bayt akışını" alıp daha küçük bir akışa çevirir (ve tersi). Bu yüzden **tek bir akışı** sıkıştırırlar; çoklu dosya için önce `tar` ile tek akışa çevirip **sonra** sıkıştırırsın — `tar.gz` / `tar.xz` kombinasyonunun sebebi budur (önce paketle, sonra sıkıştır).

- **`gzip` (DEFLATE — RFC 1951):** iki adım. (1) **LZ77:** akışta daha önce geçmiş bir bayt dizisini bulunca onu "şu kadar geriye git, şu kadar bayt kopyala" referansıyla değiştirir; arama penceresi **sabit 32 KB** (32.768 bayt), maksimum geri referans 258 bayt. (2) **Huffman kodlama:** sık geçen baytlara kısa bit kodları, nadir baytlara uzun kodlar. Küçük pencere → **hızlı**, ama pencereden uzaktaki tekrarları yakalayamaz. DEFLATE aslında Phil Katz'ın PKZIP'i için tanımlandı, sonra RFC 1951 oldu.
- **`xz` (LZMA):** aynı LZ77 fikri ama **çok daha büyük sözlük** (tipik 64 KiB–64 MiB, teoride ~1.5 GiB'e kadar) ve daha güçlü olasılıksal kodlama (range coding). Uzak tekrarları da yakaladığı için **çok daha iyi sıkıştırma oranı**, bedeli **daha fazla CPU/zaman ve bellek**.

```bash
tar -cf arsiv.tar dizin/          # sadece paketle (c=create, f=dosya adı)
tar -czf arsiv.tar.gz dizin/      # paketle + gzip (z)
tar -cJf arsiv.tar.xz dizin/      # paketle + xz (J)  -> daha küçük, daha yavaş
tar -xf arsiv.tar.gz              # aç (x) — z/J vermesen de tar dosya imzasından anlar
tar -tf arsiv.tar.gz              # AÇMADAN içindekileri listele (t)
tar -xvf arsiv.tar.gz             # v=verbose, göstere göstere aç
tar -czf yedek.tar.gz --exclude='*.log' dizin/   # bazı dosyaları dışarıda bırak
```

> [!TIP]
> **Ne zaman hangisi: hız önemliyse (günlük yedek, sık çalışan iş) `gzip`; disk/ağ alanı önemliyse (dağıtım paketleri, uzun süre saklama) `xz`. `zstd` (`--zstd` / `.tar.zst`) son yıllarda "gzip hızında ama daha iyi oran" diye ikisinin arasına oturdu — Arch ve Fedora paketleri artık `zstd` kullanır.**

### ASCII ve HEX — bunlar karşılaştırılabilir iki şey bile değil

**Farklı kategorilerden:** biri bir **kod tablosu**, diğeri bir **sayı yazma biçimi**.

- **ASCII:** bir **karakter kodlama** standardı — her karaktere (harf, rakam, sembol) **0–127 arası bir sayı** atar (`man ascii` tam tabloyu verir). `'A'`'nın ASCII kodu **65**'tir. Bilgisayar "A harfini" saklamaz, **65 sayısını** saklar; ekrana bastırılırken bu sayı fontla 'A' şeklinde çizilir. UTF-8, ilk 128 kod noktasında ASCII ile **birebir uyumludur** — bu yüzden saf ASCII bir dosya aynı zamanda geçerli UTF-8'dir.
- **HEX (onaltılık taban):** kodlama değil, bir **sayıyı yazma biçimi** — 10'luk ya da 2'lik taban gibi, sadece 16 rakam (`0-9`, `A-F`). Her türlü sayı hex ile yazılabilir.

**Bağlantı:** bir dosyayı "hex dump" ile (`xxd`/`hexdump`) incelediğinde, **her baytın değerini hex tabanında** görürsün. Metin dosyasında bu baytlar karakter kodlarıdır:

```
'A' harfi  →  ondalık: 65   →  hex: 0x41   →  ikili: 01000001
```

```bash
echo -n "A" | xxd
# 00000000: 41                                       A
#           ^^ 65 sayısının hex yazımı — 'A'nın ASCII kodu

printf '%d\n' 0x41     # hex → decimal: 65
printf '%x\n' 65       # decimal → hex: 41
```

**Neden hex bu iş için standart:** her hex hanesi **tam 4 bit**, yani **2 hane = tam 1 bayt** — ham baytları insan gözüyle okunur, hizalı göstermenin en kompakt yolu (decimal'de baytlar düzgün hizalanmaz). `xxd`/`hexdump`, bir dosyanın metin mi binary mi olduğunu anlamak, "sihirli sayı" (magic number — dosya imzası) kontrol etmek, bozuk kodlama sorunlarını teşhis etmek için sistem yöneticisinin sık başvurduğu araçlardır.

### Paket yönetim sistemleri — bir paket gerçekte nedir, kurulum/kaldırma/güncelleme nasıl çalışır

**Mekanizma — bir "paket" ne içerir:**
Bir `.deb` (Debian/Ubuntu) ya da `.rpm` (RHEL/Fedora/Rocky) dosyası sihirli bir kurulum programı değil — **yapılandırılmış bir arşivdir**.

Bir **`.deb`**, aslında bir **`ar` arşividir** (`man 5 deb`) ve sırayla üç üye içerir:
1. **`debian-binary`** — format sürümünü belirten küçük metin (`2.0`).
2. **`control.tar.{gz,xz,zst}`** — paketin **metadata**'sı: adı, sürümü, **bağımlılıkları** (`Depends: libc6 (>= 2.34), ...`), kurulum öncesi/sonrası betikleri (`preinst`/`postinst`).
3. **`data.tar.{gz,xz,zst}`** — paketin **gerçek dosyaları**, sistemdeki hedef yollarıyla (`/usr/bin/...`, `/etc/...`) birlikte.

Bir **`.rpm`** benzer biçimde: lead + imza + **header** (metadata/bağımlılıklar) + genelde sıkıştırılmış **cpio yükü** (dosyalar).

```bash
ar t paket.deb                 # .deb'in bir 'ar' arşivi olduğunu, 3 üyeyi göster
dpkg -c paket.deb               # data.tar içindeki dosya listesi (nereye kurulacaklar)
dpkg -I paket.deb               # control bilgisi (bağımlılıklar, açıklama)
rpm -qpl paket.rpm              # .rpm içindeki dosya listesi
rpm -qpR paket.rpm              # .rpm'in bağımlılıkları
```

**Kurulum sırasında ne oluyor?**
1. `data.tar` içindeki dosyalar hedef yollarına **çıkarılır**.
2. Her dosyanın **hangi pakete ait olduğu** yerel bir veritabanına kaydedilir — Debian: `/var/lib/dpkg/status` + `/var/lib/dpkg/info/`; RPM: `/var/lib/rpm` veritabanı. **Bu kayıt kritik:** kaldırma (`remove`) işleminin "hangi dosyaları sileceğini" bilmesinin tek nedeni budur — paket yöneticisi tahmin etmez, veritabanından okur.
3. `postinst` betiği varsa çalıştırılır (servis etkinleştir, kullanıcı oluştur — kurulumun "son rötuşları").

**Silme (`remove` / `purge`):** veritabanı kaydına bakılarak o pakete ait dosyalar silinir; `purge` ayrıca `/etc` altındaki config'i de kaldırır (`remove` bilerek bırakır — belki yeniden kurarsın).

**Güncelleme (`upgrade`):** ayrı bir mekanizma değil — yeni sürümün dosyaları eskisinin üzerine yazılır, `postinst` bu sefer "eski sürümden geçiş" bilgisiyle çalışır (eski config formatını migrate edebilir).

**5N1K çerçevesinde paket yöneticisi:**
- **Ne:** yazılımı doğru yerlere kopyalayıp bir veritabanına kaydeden + bağımlılıkları çözen katman.
- **Nasıl:** düşük seviye araç (`dpkg`/`rpm`) tek pakete dokunur, dosyaları yerleştirir/siler, veritabanını günceller; yüksek seviye araç (`apt`/`dnf`) repo indekslerinden **bağımlılık grafiğini** çözer, gerekli tüm paketleri indirir, sonra düşük seviye araca teker teker verir. *"DNF wraps rpm, apt wraps dpkg; neither installs software by itself."*
- **Ne zaman:** sen çağırdığında; ayrıca `unattended-upgrades` / `dnf-automatic` ile zamanlanmış olarak (Gün 6'daki timer/cron mantığı).
- **Neden elle dosya kopyalamak yerine:** (1) bağımlılıkların otomatik çözülmesi, (2) "hangi dosya nereden geldi" kaydı → temiz kaldırma ve bütünlük kontrolü (`debsums` / `rpm -V`), (3) imzalı repo → sahte/bozuk paket engellenir. Paket yöneticisi dışında elle dosya silmek/değiştirmek bu veritabanını gerçekle çelişir hâle getirir.
- **Kim:** kurulum/kaldırma root gerektirir (sistem yollarına yazma); sorgulama (`apt show`, `rpm -q`) sıradan kullanıcıyla yapılır.

**Repo (depo) gerçekte nedir?**
Büyülü bir sunucu değil — HTTP üzerinden erişilen, içinde şunlar olan bir dizin ağacı:
- **Debian:** `pool/` altında gerçek `.deb` dosyaları; `dists/<sürüm>/<bileşen>/binary-<mimari>/Packages.gz` indeksi (her paket için `Depends`, `Filename`, `SHA256`); `dists/<sürüm>/InRelease` (imzalı — tüm indekslerin checksum'larını listeler, `Release` + `Release.gpg` eski istemciler için).
- **RPM (dnf/yum):** `repodata/repomd.xml` (ana indeks) → `primary.xml.gz` (paket listesi + bağımlılıklar) + `filelists.xml.gz` + `other.xml.gz`.

- `apt update` / `dnf makecache`: makine **sadece bu indeks dosyalarını** indirir, yerelde önbelleğe alır (`/var/lib/apt/lists/`). **Hiçbir paket indirilmez** — sadece "hangi paket hangi sürümde mevcut" güncellenir.
- `apt install X`: yerel indeksten X'in bağımlılık listesine bakılır, eksik bağımlılıklar için de aynısı tekrarlanır (zincirleme bağımlılık grafiği çözümü), gerekli tüm dosyalar indirilir, `dpkg` her birine kurulum adımlarını uygular.

**Dağıtımlar arası fark — aynı kavram, farklı araçlar:**

| Dağıtım ailesi | Düşük seviye | Yüksek seviye | Paket formatı | Yerel veritabanı |
|---|---|---|---|---|
| Debian / Ubuntu | `dpkg` | `apt` (`apt-get`/`apt-cache`'in modern arayüzü) | `.deb` | `/var/lib/dpkg/` |
| RHEL / Fedora / Rocky / Alma | `rpm` | `dnf` (Fedora'da artık `dnf5`; eski adı `yum`) | `.rpm` | `/var/lib/rpm/` |
| Arch (referans) | — | `pacman` | `.pkg.tar.zst` | `/var/lib/pacman/` |
| openSUSE (referans) | `rpm` | `zypper` | `.rpm` | `/var/lib/rpm/` |

Fark sadece isimlerde/formatta değil — **bağımlılık çözme algoritmaları ve metadata biçimleri** de farklıdır (modern `apt` kendi çözücüsüne sahip; `dnf5` çözücüyü C++ `libdnf5`'e taşıdı). Bu yüzden bir `.deb`'i doğrudan RHEL'e kuramazsın (`alien` gibi dönüştürücüler var ama önerilmez).

**`apt` ve en sık kullanılan parametreleri:**
```bash
sudo apt update                    # repo indekslerini güncelle (henüz paket indirmez)
sudo apt upgrade                   # kurulu paketleri en yeni sürümlerine güncelle
sudo apt full-upgrade              # gerekirse paket kaldırarak da güncelle (eski adı dist-upgrade)
sudo apt install paket_adi         # paketi + eksik bağımlılıklarını kur
sudo apt remove paket_adi          # paketi kaldır, /etc altındaki config'i BIRAKIR
sudo apt purge paket_adi           # paket + config dosyalarını da tamamen kaldır
sudo apt autoremove                # başka hiçbir paketin ihtiyaç duymadığı "öksüz" bağımlılıkları temizle
apt search kelime                  # yerel indekste isim/açıklamaya göre ara
apt show paket_adi                 # bağımlılıklar/açıklama/boyut detayı
apt list --installed               # kurulu tüm paketler
apt-mark hold paket_adi            # bu paketi güncellemelerden sabitle (dondur)
```

DNF karşılıkları: `dnf check-update` ≈ `apt update` + `upgrade` listesi, `dnf install/remove/upgrade`, `dnf autoremove`, `dnf search`, `dnf info`, `dnf list installed`, `dnf mark`.

### Kaynaklar

**Bu başlık her zaman Genişletilmiş Anlatım'ın SON `###` bölümüdür** — hemen ardından `## Notlar` gelir.

- **FHS ve `man hier`:**
  - [Filesystem Hierarchy Standard 3.0 — Linux Foundation Refspecs](https://refspecs.linuxfoundation.org/FHS_3.0/fhs/index.html) — `/opt`, `/srv`, `/usr/local` tanımları; standardın zorunlu olmayan doğası. (Ayrıntı [Gün 3#Dizin yapısı (FHS) — hangi dizin ne işe yarar, ve **neden** böyle ayrılmış](Gün%203.md#dizin-yapısı-fhs-hangi-dizin-ne-işe-yarar-ve-neden-böyle-ayrılmış).)
- **`/proc/<pid>/fd/` ile silinmiş-ama-açık dosya kurtarma:**
  - [proc(5) — man7.org](https://man7.org/linux/man-pages/man5/proc.5.html) — `/proc/[pid]/fd/` symlink girdileri; silinen hedefin `(deleted)` etiketiyle görünmesi.
- **`tar` / ustar / pax formatı (merkezi dizin yok, sıralı akış):**
  - [Basic Tar Format — GNU tar manual](https://www.gnu.org/software/tar/manual/html_node/Standard.html) — 512 baytlık başlık + veri + dolgu blokları; arşiv sonu iki sıfır blok.
  - [ustar — Wikipedia (tar)](https://en.wikipedia.org/wiki/Tar_(computing)) — "originally developed to write data to sequential I/O devices with no file system of their own"; POSIX ustar/pax.
- **`gzip` / DEFLATE (LZ77 32 KB pencere + Huffman):**
  - [RFC 1951 — DEFLATE Compressed Data Format Specification](https://www.rfc-editor.org/rfc/rfc1951) — LZ77 + Huffman; 32 KB pencere, 258 bayt maksimum eşleşme uzunluğu.
  - [Deflate — Wikipedia](https://en.wikipedia.org/wiki/Deflate) (tersiyer — Phil Katz / PKZIP kökeni, RFC 1951 standartlaşması).
- **`xz` / LZMA (büyük sözlük, range coding):**
  - [XZ data compression in Linux — The Linux Kernel documentation](https://www.kernel.org/doc/html/latest/staging/xz.html) — LZMA'nın LZ77 temeli, değişken sözlük boyutu.
  - [xz(1) manual page](https://man7.org/linux/man-pages/man1/xz.1.html) — sözlük boyutu aralığı (4 KiB – 1.5 GiB), preset seviyeleri ve CPU/bellek maliyeti.
- **ASCII tablosu:**
  - [ascii(7) — man7.org](https://man7.org/linux/man-pages/man7/ascii.7.html) — 0–127 karakter–kod eşlemesi; UTF-8'in ilk 128 kod noktasında ASCII ile uyumu.
- **`.deb` paket formatı (`ar` arşivi: `debian-binary` + `control.tar` + `data.tar`):**
  - [deb(5) — man7.org](https://man7.org/linux/man-pages/man5/deb.5.html) — üye sırası ve içerikleri.
- **Debian APT repo yapısı (`dists/`, `Release`/`InRelease`, `Packages.gz`, `pool/`; `apt update` sadece indeks indirir):**
  - [DebianRepository/Format — Debian Wiki](https://wiki.debian.org/DebianRepository/Format) — `InRelease` "signed in-line" tüm indeks checksum'larını listeler; `Packages` girdisi `Filename`/`Depends`/`SHA256` içerir.
- **`apt` vs `dnf` (her ikisi de `dpkg`/`rpm`'i sarmalar, kendisi kurulum yapmaz; farklı çözücüler):**
  - [The Histories, Similarities and Differences of APT and DNF — djere.com](https://djere.com/the-histories-similarities-and-differences-of-the-apt-and-dnf-gnulinux-package-managers.html) (ikincil — pratik karşılaştırma; birincil doğrulama için `man apt` / `man dnf` ve yukarıdaki Debian Wiki).
  - [RPM Reference Manual](https://rpm-software-management.github.io/rpm/manual/) — RPM'in kendisinin bağımlılık çözmediği, `/var/lib/rpm` veritabanı.

Tekil bayrak/sözdizimi anlamları (`tar -x`, `apt install`, `xxd` çıktısı) ilgili `man` sayfalarıyla doğrulanabilir; bunlar için ayrıca kaynak gösterilmedi.

## Notlar

- Bugünün ana teması: dün öğrenilen "inode'a bağlı süreç" fikrinin **canlı bir kurtarma senaryosuna** dönüşmesi (`/proc/<pid>/fd/`), **sıkıştırma ile arşivlemenin birbirinden bağımsız iki katman** olduğu (`tar` paketler → `gzip`/`xz` sıkıştırır), ASCII'nin (kodlama) HEX ile (sayı tabanı) kıyaslanamaz iki şey olduğu, ve paket yöneticisinin aslında "dosyaları doğru yere kopyalayıp bir veritabanına kaydeden + bağımlılık grafiği çözen" nispeten anlaşılır bir mekanizma olduğu.
- En kritik pratik çıkarım: bir programın hâlâ açık tuttuğu bir dosyayı yanlışlıkla silersen panik yapma — `lsof` / `/proc/<pid>/fd/` ile kurtarma şansın var, **ama sadece o program kapanana kadar**.
- Paket yöneticisinin "hangi dosya hangi pakete ait" veritabanı, paket yöneticisi dışında elle dosya değiştirmenin neden sistemin bütünlüğünü bozduğunu açıklar — veritabanı artık gerçekle uyuşmaz, `apt`/`dnf` bir sonraki işlemde beklenmedik davranabilir.
- `tar.gz`, `.deb` (içi `ar` + `tar`), repo indeksleri (`Packages.gz`) — hepsi aynı "önce paketle/listeleyip sonra sıkıştır" desenini kullanıyor.

## Komutlar / Örnekler

```bash
# silinen ama açık dosyayı kurtarma
pgrep mpg123
lsof | grep deleted
ls -l /proc/<PID>/fd/
cp /proc/<PID>/fd/3 kurtarilan.mp3

# arşivleme / sıkıştırma
tar -czf arsiv.tar.gz dizin/
tar -cJf arsiv.tar.xz dizin/
tar -tf arsiv.tar.gz
tar -xvf arsiv.tar.gz
tar -czf yedek.tar.gz --exclude='*.log' dizin/

# ASCII <-> HEX
echo -n "A" | xxd
printf '%d\n' 0x41
printf '%x\n' 65

# paket yönetimi (apt)
sudo apt update
sudo apt install paket_adi
sudo apt remove paket_adi
sudo apt purge paket_adi
sudo apt autoremove
apt show paket_adi
dpkg -c paket.deb
dpkg -I paket.deb

# paket yönetimi (dnf — Rocky/RHEL)
sudo dnf makecache
sudo dnf install paket_adi
sudo dnf remove paket_adi
rpm -qpl paket.rpm
```

## Sorular / Takip Edilecekler

- [ ] Kendi VM'inde küçük bir dosya oluşturup `tail -f` ile açık tut, başka terminalden `rm` et, sonra `/proc/$(pgrep tail)/fd/` altından `cp` ile kurtar — kurtarma penceresinin `tail`'i öldürünce kapandığını gözlemle.
- [ ] Aynı dizini `tar -czf` (gzip) ve `tar -cJf` (xz) ile arşivleyip `ls -l` ile boyut, `time` ile süre farkını karşılaştır.
- [ ] `apt show <paket>` çıktısındaki `Depends:` satırını al, o bağımlılıklardan birini `apt show` ile aç — bağımlılık grafiğinin nasıl zincirlendiğini elle takip et.
