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

Bağlantı: [Linux Sistem Yönetimi Eğitimi](../README.md) · [00 - Eğitim Planı](../00%20-%20Eğitim%20Planı.md) · [Gün 3](Gün%203.md)

## İşlenen Konular

- FHS Derinlemesine bölümlerin amaçları ve içerikleri dikkat edilmesi gereken alanları.
- Paket yöneticisi nedir ne işe yarar Derinlemesine incelemeliyiz.

Örnek bir soru: bir mp3 dosyasını açtım terminal üzerinde çalıyor, mp3 çalarken mp3 dosyasını sildim. Devam eden bir süreç olduğu için inode'ye bağlı bir process var, aslında dosya hâlâ disk içinde — bunu kurtarmanın bir yolu var mı?

Dosya sıkıştırma metodları:
Gzip, Xz, Tar bunların kullanımı ve parametre kullanımı konuları işlendi.

ASCII ve HEX arasındaki farklar nelerdir?

----
Paket yönetim sistemleri nelerdir?
Paket yönetim sistemlerinin farkları nelerdir?
Paket yönetim sistemlerinin Yükleme, Silme ve Güncelleme metodları nelerdir.
Paket yönetim sistemlerinde Repoların önemi ve mantığı, dağıtım repoları arasındaki farklar nelerdir.

Linux Server Dağıtımlarında Paket yönetim yazılımları nelerdir.

apt komutu ve parametreleri

## Genişletilmiş Anlatım (Öğrenme İçin Ek Açıklamalar)

> [!WARNING]
> **Yukarıda bulunan kısa notların AI ile genişletilmiş halidir. Bilgiler sadece o gün işlenen konular ile sınırlandırılmış olup referans olması için eklenmiştir. Lütfen bu genişletilmiş metni kendi araştırmalarınıza bir ön bilgi olarak kullanın ve testlerinizi sadece burayı kullanarak değil, farklı kaynaklardan da yararlanarak yapın.**

### FHS'nin derinlemesine tekrarı — Gün 3'ün üzerine

Bugün tekrar edilen FHS konusunu (`/bin`, `/etc`, `/var`, `/tmp`, `/home`...) ve her dizinin **neden** o şekilde ayrıldığını (tarihsel `/usr` ayrımı, `/var`'ın ayrı bölüm olmasının kök dosya sistemini log taşmasından koruması, `/tmp`'nin `tmpfs` olma nedeni gibi) [Gün 3](Gün%203.md) içindeki "Dizin yapısı (FHS)" bölümünde satır satır işledik — burada tekrar yazıp kendini tekrar etmek yerine oraya yönlendiriyorum. Bugünün asıl yeni konusu, dosyanın "silinmesi" ile "kernel'in onu gerçekten serbest bırakması" arasındaki farkın **canlı bir senaryoda** ne anlama geldiği — tam olarak bunu aşağıda çözüyoruz.

### mp3 çalarken silinen dosya — "hayalet dosya" senaryosu ve kurtarma yöntemi

Bu, Gün 3'te gördüğün bir gerçeği **doğrudan pratiğe döken** klasik bir Unix sorusudur: *"Bir inode, `st_nlink` sıfıra düşse bile, onu açık tutan en az bir süreç (process) varsa disk üzerinde yaşamaya devam eder."* mp3 örneğinde tam olarak olan şey şudur:

1. `mpg123 sarki.mp3` gibi bir komutla dosyayı çaldığında, oynatıcı program `open("sarki.mp3")` çağrısı yapar — kernel bu çağrıya karşılık ona bir **dosya tanıtıcısı (file descriptor, fd)** verir; bu fd, doğrudan dosyanın **inode'una** bağlıdır, dosyanın **adına** değil.
2. Sen `rm sarki.mp3` çalıştırdığında, kernel sadece dizin girdisini (`"sarki.mp3" → inode_no` satırını) siler ve inode'un `st_nlink` sayacını bir azaltır. **Ama** oynatıcı sürecin hâlâ o inode'a açık bir fd'si olduğu için, kernel'in "veriyi gerçekten sil" kuralı (`st_nlink == 0` **VE** açık fd sayısı == 0) henüz sağlanmamıştır — veri diskte **tamamen sağlam** durur, sadece artık **hiçbir dizinden erişilemez** hâle gelmiştir (bir "hayalet" dosya).
3. Müzik çalmaya devam eder çünkü oynatıcı zaten dosyayı **isimle değil, fd ile** okumaya devam ediyordur — silme işlemi ismi kaldırır, fd'yi değil.

**Kurtarma yöntemi — `/proc/<pid>/fd/` mekanizması:**
Kernel, her sürecin o an açık tuttuğu tüm dosya tanıtıcılarını `/proc/<pid>/fd/` altında sembolik link gibi görünen girdilerle dışa vurur. Silinen ama hâlâ açık olan bir dosyanın linki, hedefi artık yokken bile `dosya_adi.mp3 (deleted)` etiketiyle görünmeye devam eder — ve bu link, isme değil doğrudan **inode'a** işaret ettiği için hâlâ **okunabilir**:

```bash
# 1. Dosyayı çalan sürecin PID'ini bul
pgrep mpg123                      # ya da: lsof | grep "sarki.mp3 (deleted)"

# 2. O sürecin açık fd listesine bak, "(deleted)" etiketli olanı bul
ls -l /proc/<PID>/fd/
# lr-x------ 1 ucp ucp 64 ... 3 -> /home/ucp/sarki.mp3 (deleted)

# 3. O fd'yi normal bir dosyaymış gibi kopyala — veri hâlâ orada
cp /proc/<PID>/fd/3 kurtarilan.mp3
```

> [!TIP]
> **Bu numara sadece mp3 için değil, **her türlü açık dosyada** işe yarar — yanlışlıkla sildiğin bir log dosyasını, üzerine yazan servis kapanmadan önce aynı yöntemle kurtarabilirsin. Pratikte "disk dolu görünüyor ama `du` boş gösteriyor" bulmacasının çözümü de aynı mekanizmaya dayanır (Gün 3'te değindiğimiz `lsof | grep deleted`).**

### Sıkıştırma ve arşivleme — `tar`, `gzip`, `xz` gerçekte ne yapar

Burada sık yapılan bir kavram karışıklığını netleştirmek gerekiyor: **`tar` bir sıkıştırma aracı DEĞİLDİR.**

**`tar` (tape archive) — arşivleme:**
`tar`'ın tek işi, **birden çok dosyayı** (izinleri, sahiplik bilgisi, dizin yapısı korunarak) **tek bir dosyaya** art arda ekleyip birleştirmektir — sıkıştırma yapmaz, sadece "paketler". `.tar` uzantılı bir dosya, orijinal dosyaların toplamıyla neredeyse aynı boyuttadır (üstüne sadece küçük bir başlık/metadata eklenir). Adının "tape archive" olması tesadüf değil — 1970'lerde manyetik teybe **sıralı** olarak yazılan, tek bir uzun akış (stream) olarak tasarlanmıştır; bu yüzden `tar` içindeki tek bir dosyaya rastgele erişemezsin, arşivi baştan okumak zorundasın (`.zip` gibi formatlardan farkı budur — zip her dosyanın nerede başladığını gösteren bir "içindekiler" tablosu tutar, tar tutmaz).

**`gzip`/`xz` — asıl sıkıştırma:**
Bunlar dosya/dizin **kavramını hiç bilmez** — sadece "gelen bayt akışını" alıp daha küçük bir bayt akışına dönüştürürler (ve tersini yapabilirler). Bu yüzden **tek bir dosyayı** sıkıştırırlar; birden fazla dosyayı sıkıştırmak istiyorsan önce `tar` ile TEK bir akışa dönüştürüp SONRA o akışı sıkıştırman gerekir — `tar.gz`/`tar.xz` kombinasyonunun var olma nedeni tam olarak budur (önce paketle, sonra sıkıştır).

- **`gzip` (DEFLATE algoritması):** İki adımlı çalışır — (1) **LZ77:** akış içinde daha önce geçmiş bir bayt dizisini bulursa, onu tekrar yazmak yerine "şu kadar geriye git, şu kadar bayt kopyala" şeklinde küçük bir referansla değiştirir (küçük, 32KB'lık bir "pencere" içinde arar), (2) **Huffman kodlama:** akışta **sık geçen** baytlara **kısa** bit kodları, **nadir geçen** baytlara **uzun** bit kodları atar (bir metinde 'e' harfi 'q'dan çok daha sık geçtiği için 'e'yi daha az bitle temsil etmek yer kazandırır). Küçük pencere sayesinde **hızlıdır** ama uzak tekrarları yakalayamaz.
- **`xz` (LZMA algoritması):** Aynı LZ77 fikrinin çok daha büyük bir pencereyle (megabaytlarca) ve çok daha güçlü, olasılıksal bir kodlama (range coding) ile geliştirilmiş hâlidir. Uzak tekrarları da yakalayabildiği ve daha akıllı kodladığı için **çok daha iyi sıkıştırma oranı** verir ama bunun bedeli **daha fazla CPU/zaman**dır.

```bash
tar -cf arsiv.tar dizin/          # sadece paketle (c=create, f=dosya adı)
tar -czf arsiv.tar.gz dizin/      # paketle + gzip ile sıkıştır (z=gzip)
tar -cJf arsiv.tar.xz dizin/      # paketle + xz ile sıkıştır (J=xz)   -> daha küçük, daha yavaş
tar -xf arsiv.tar.gz              # aç (x=extract) — z/J vermesen de tar dosya imzasından hangi sıkıştırma olduğunu KENDİSİ anlar
tar -tf arsiv.tar.gz              # AÇMADAN sadece içindekileri listele (t=list)
tar -xvf arsiv.tar.gz             # v=verbose, hangi dosyanın açıldığını göstere göstere aç
```

> [!TIP]
> **Ne zaman hangisi: hız önemliyse (örn. günlük yedekleme, sık çalışan bir iş) `gzip`; disk/ağ alanı önemliyse (örn. dağıtım paketleri, arşive bir kez yazıp uzun süre saklama) `xz` tercih edilir. `bzip2` (`j` bayrağı) da vardır, ikisinin arasında bir yerde durur ama günümüzde `xz` genelde onu geride bırakmıştır.**

### ASCII ve HEX — bunlar karşılaştırılabilir iki şey bile değil

Bu ikisi genelde "birbirine alternatif iki format" gibi algılanır ama aslında **tamamen farklı kategorilerdendir** — biri bir **kod tablosu**, diğeri bir **sayı yazma biçimi**:

- **ASCII:** Bir **karakter kodlama** standardıdır — her karaktere (harf, rakam, sembol) **0-127 arası bir sayı** atar. Örneğin `'A'` harfinin ASCII kodu **65**'tir (ondalık/decimal olarak). Bilgisayar aslında hiçbir zaman "A harfini" saklamaz, sadece **65 sayısını** saklar; ekrana bastırılırken bu sayı ASCII tablosuna göre 'A' şeklinde çizilir.
- **HEX (onaltılık taban):** Bu bir kodlama değil, sadece bir **sayıyı yazma biçimidir** — tıpkı 10'luk (decimal) ya da 2'lik (binary) taban gibi, sadece 16 rakam kullanır (`0-9` ve `A-F`). **Her türlü sayı** (ASCII kodu olsun olmasın) hex ile yazılabilir.

**Bağlantı nerede kuruluyor?** Bir metin dosyasını "hex dump" ile (`xxd`/`hexdump`) incelediğinde, aslında **her karakterin ASCII (ya da UTF-8) kodunu, hex tabanında yazılmış hâliyle** görürsün — üç farklı gösterim, aynı sayı:

```
'A' harfi  →  ondalık (decimal): 65   →  hex: 0x41   →  ikili (binary): 01000001
```

```bash
echo -n "A" | xxd
# 00000000: 41                                       A
#           ^^ bu "41", 65 sayısının hex yazımı — 'A'nın ASCII kodu

printf '%d\n' 0x41     # hex'ten decimal'e çevir -> 65
printf '%x\n' 65       # decimal'den hex'e çevir -> 41
```

Hex'in popüler olmasının pratik nedeni: her hex hanesi **tam olarak 4 bit**e karşılık gelir, yani **2 hex hanesi = tam 1 bayt** — bu da onu binary veriyi (ham baytları) insan gözüyle okunabilir şekilde göstermenin en kompakt, en "temiz" yolu yapar (decimal'de baytlar böyle düzgün hizalanmaz).

### Paket yönetim sistemleri — bir paket gerçekte nedir, kurulum/kaldırma/güncelleme nasıl çalışır

**Bir "paket" aslında ne içerir?**
Bir `.deb` (Debian/Ubuntu) ya da `.rpm` (RHEL/Fedora/Rocky) dosyası, sihirli bir kurulum programı değil — sadece **yapılandırılmış bir arşivdir** (yukarıda gördüğün `tar` mantığına çok yakın). Bir `.deb` dosyasının içinde üç parça vardır:
1. **`control.tar.xz`** — paketin **metadata**'sı: adı, sürümü, **bağımlılıkları** (`Depends: libc6 (>= 2.34), ...`), kurulum öncesi/sonrası çalıştırılacak küçük betikler (`preinst`/`postinst`).
2. **`data.tar.xz`** — paketin **gerçek dosyaları** (binary'ler, config dosyaları, kütüphaneler) — sistemdeki hangi tam yola (`/usr/bin/...`, `/etc/...`) kopyalanacaklarını da içinde taşır.
3. **`debian-binary`** — format sürümünü belirten küçük bir metin dosyası.

```bash
ar t paket.deb                 # bir .deb'in aslında bir 'ar' arşivi olduğunu, içindeki 3 parçayı göster
dpkg -c paket.deb               # data.tar.xz içindeki dosya listesini (nereye kurulacaklarını) göster
dpkg -I paket.deb               # control bilgisini (bağımlılıklar, açıklama) göster
```

**Kurulum sırasında gerçekte ne oluyor?**
1. `data.tar.xz` içindeki dosyalar, kendi hedef yollarına **çıkarılır** (kopyalanır).
2. Her dosyanın **hangi pakete ait olduğu**, sistemin yerel bir veritabanına kaydedilir (Debian ailesinde `/var/lib/dpkg/status` ve `/var/lib/dpkg/info/`, RPM ailesinde kendi RPM veritabanı). Bu kayıt kritik önemdedir — **kaldırma (`remove`) işleminin nasıl "hangi dosyaları sileceğini bildiğinin"** tek nedeni budur; paket yöneticisi tahmin etmez, tam olarak hangi dosyaların o pakete ait olduğunu bu veritabanından okur.
3. Paketin `postinst` betiği varsa çalıştırılır (örn. bir servisi etkinleştirmek, bir kullanıcı oluşturmak gibi kurulumun "son rötuşları").

**Silme (`remove`/`purge`):** Veritabanındaki kayda bakılarak o pakete ait dosyalar tek tek silinir; `purge` ayrıca `/etc` altındaki yapılandırma dosyalarını da kaldırır (`remove` bunları bilerek bırakır — belki yeniden kurarsın diye).

**Güncelleme (`upgrade`):** Aslında ayrı bir mekanizma değildir — yeni sürümün dosyaları eskisinin **üzerine** yazılır, `postinst` betiği bu sefer "eski sürümden şuna geçiş yapılıyor" bilgisiyle çalışır (örn. eski bir config formatını yeni formata migrate edebilir).

**Repo (depo) gerçekte nedir?**
Bir "repo", büyülü bir sunucu değil — sadece HTTP üzerinden erişilen, içinde şunlar olan **düz bir dizin**dir: (a) gerçek `.deb`/`.rpm` dosyaları, (b) bunların **hepsinin bir listesini** çıkaran bir **indeks dosyası** (Debian'da `Packages.gz`, üstünde bütünlüğü imzalayan `Release`/`InRelease`; RPM ailesinde `repodata/repomd.xml`).

- `apt update` çalıştırdığında olan şey: senin makinen bu indeks dosyalarını indirir, yerelde (`/var/lib/apt/lists/`) önbelleğe alır. **Hiçbir paket henüz indirilmez** — sadece "hangi paketler hangi sürümde mevcut" bilgisi güncellenir.
- `apt install X` çalıştırdığında: yerel önbellekteki indeksten X'in bağımlılık listesine bakılır, **henüz kurulu olmayan** bağımlılıklar için de aynı işlem tekrarlanır (bu bir **bağımlılık grafiği** çözümlemesidir — "X, Y'ye ihtiyaç duyar; Y de Z'ye ihtiyaç duyar" şeklinde zincirleme çözülür), gerekli tüm `.deb` dosyaları indirilir, sonra `dpkg` her biri için yukarıdaki kurulum adımlarını uygular.

**Dağıtımlar arası fark — aynı kavram, farklı araçlar:**

| Dağıtım ailesi | Düşük seviye araç | Yüksek seviye (kullanıcı dostu) araç | Paket formatı |
|---|---|---|---|
| Debian / Ubuntu | `dpkg` | `apt` (`apt-get`/`apt-cache`'in daha rahat arayüzü) | `.deb` |
| RHEL / Fedora / Rocky / Alma | `rpm` | `dnf` (eskiden `yum`) | `.rpm` |
| Arch (referans için) | — | `pacman` | `.pkg.tar.zst` |

Fark sadece **isimlerde/formatta** değil — **bağımlılık çözme algoritmaları ve metadata biçimleri** de farklıdır, bu yüzden bir `.deb` dosyasını doğrudan RHEL'e kuramazsın (dönüştürme araçları — `alien` gibi — var ama garantili/önerilen değildir).

**`apt` komutu ve en sık kullanılan parametreleri:**
```bash
sudo apt update                    # repo indekslerini güncelle (henüz paket indirmez)
sudo apt upgrade                   # kurulu paketleri en yeni sürümlerine güncelle
sudo apt install paket_adi         # paketi (ve eksik bağımlılıklarını) kur
sudo apt remove paket_adi          # paketi kaldır, /etc altındaki config'i BIRAKIR
sudo apt purge paket_adi           # paketi + config dosyalarını da tamamen kaldır
sudo apt autoremove                # başka hiçbir paketin ihtiyaç duymadığı "öksüz" bağımlılıkları temizle
apt search kelime                  # yerel indekste isim/açıklamaya göre ara
apt show paket_adi                 # bir paketin bağımlılıkları/açıklaması/boyutu gibi detaylarını göster
apt list --installed               # sistemde kurulu tüm paketleri listele
```

## Notlar

- Bugünün ana teması: dün öğrendiğin "inode'a bağlı süreç" fikrinin **canlı bir kurtarma senaryosuna** dönüşmesi (`/proc/<pid>/fd/`), sıkıştırma ile arşivlemenin **birbirinden bağımsız iki katman** olduğu (`tar` paketler, `gzip`/`xz` sıkıştırır), ASCII (kodlama) ile HEX'in (sayı tabanı) hiç kıyaslanabilir iki şey olmadığı, ve paket yöneticisinin aslında sadece "dosyaları doğru yere kopyalayıp bir veritabanına kaydeden" nispeten basit bir mekanizma olduğu.
- En kritik pratik çıkarım: bir programın hâlâ açık tuttuğu bir dosyayı yanlışlıkla silersen panik yapma — `lsof`/`/proc/<pid>/fd/` ile kurtarma şansın var, ama program kapanana kadar.
- Paket yöneticisinin "hangi dosya hangi pakete ait" bilgisini bir veritabanında tutması, elle (paket yöneticisi dışında) dosya silip/değiştirmenin neden sistemin bütünlüğünü bozabileceğini açıklar — paket yöneticisi artık gerçekle uyuşmayan bir kayıt tutmaya başlar.

## Komutlar / Örnekler

```bash
# silinen ama açık dosyayı kurtarma
pgrep mpg123
ls -l /proc/<PID>/fd/
cp /proc/<PID>/fd/3 kurtarilan.mp3

# arşivleme / sıkıştırma
tar -czf arsiv.tar.gz dizin/
tar -cJf arsiv.tar.xz dizin/
tar -tf arsiv.tar.gz
tar -xvf arsiv.tar.gz

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
```

## Sorular / Takip Edilecekler

- [ ]
