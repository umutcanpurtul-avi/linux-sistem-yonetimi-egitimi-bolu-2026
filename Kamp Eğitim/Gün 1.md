---
tags:
  - egitim/linux-sistem-yonetimi
tarih: 2026-08-22
konular:
  - Unix ve GNU/Linux temelleri
  - Özgür yazılım
  - Temel kabuk komutları
  - Girdi/Çıktı yönlendirme
  - Çevresel değişkenler
---

# Gün 1 Raporu

Bağlantı: [Linux Sistem Yönetimi Eğitimi](../README.md) · [00 - Eğitim Planı](../00%20-%20Eğitim%20Planı.md)

## İşlenen Konular

-Unix Nedir ?
-İşletim sistemi nedir?
-Distro nedir?
-Neden distro üretilir?
-Distro seçimleri neye göre yapılır?
-Özgür yazılım nedir ?


Konularını konuştuk.

LS komutu üzerinden komutlara karşı bakışı detaylandırmak üzere konuşuldu.
	- ve -- arasındaki fark nedir? neden kullanılır?
	- info ve man yardımcı komutları anlatıldı,
	- \ işareti neden kullanılır " cd Virtual\ Box/ " örneği verildi her \ işaretikendinden sonra random bir karakter sayar boşluk varsa boşluk olarak göremez gibi
	- ls çıktısı ve ls -al çıktısı arasında ki farklar ve çıktı içerisinde bulunan anlanların anlamları nedir?
	-  -R = recursive kullanımı
	￼-  > işareti ile çıktı yönlendirme 
		- 0 <--- stdin
		- 1 ---> stdout,
		￼- 2 ---> stderor
			- Bu girdi ve çıktıların komutlar ile kullanımı 
			- ls -al 1> home home5 2>dosya.txt ( Home yi listeler sonra home5 listelemeye çalışır eğer home yada home5 yoksa eror çıktısını dosya.txt dosyası içine yazar)
			- & işsreti ile kullanmak 
	- File komutu ile dosya hakkında bilgi alamak.
	￼- | işaretinin kullanımı ve çıktı yönlendirip bir sonraki adımda kullanma
		- ls --help | head -n 10 | tail -n 5  ( önneğinde olduğu gibi önce ls --help ile ls  komutu yardım bölümü alınıp head ile ilk 10 satır alınmış tail ile head dan gelen 10 satırın sadece son 5 satırı ekrana basılmış )
	- Tail ve Head komutları işlendi
	- pwd komutu kullanıldı
	- cd - komutu kullanıldı bir önceki ziyaret edilen dizine gider.
	- printenv komutu anlatıldı
	- export değişken ="değer" komutu anlatıldı
	- echo komutu anlatıldı 
	- değişken + komut (Kullanılacak komut için değişkeni sadece tek seferlik değiştirme)

## Genişletilmiş Anlatım (Öğrenme İçin Ek Açıklamalar)

> [!WARNING]
> **Yukarıda bulunan kısa notların AI ile genişletilmiş halidir. Bilgiler sadece o gün işlenen konular ile sınırlandırılmış olup referans olması için eklenmiştir. Lütfen bu genişletilmiş metni kendi araştırmalarınıza bir ön bilgi olarak kullanın ve testlerinizi sadece burayı kullanarak değil, farklı kaynaklardan da yararlanarak yapın.**

### Temel Kavramlar

**Unix nedir?**
1960'ların sonunda Bell Labs'te (AT&T) geliştirilen, çok kullanıcılı ve çok görevli (multiuser/multitasking) bir işletim sistemi ailesidir. "Her şey bir dosyadır" felsefesi, küçük ve işini iyi yapan araçların boru hattı (`|`) ile birleştirilmesi gibi tasarım ilkeleriyle bugünün GNU/Linux, macOS (Unix türevi Darwin çekirdeği üzerine kurulu) ve BSD sistemlerinin atasıdır. GNU/Linux, Unix'in kaynak kodunu kullanmaz ama Unix felsefesini ve komut arayüzünü (POSIX standardı) taklit eder — bu yüzden "Unix benzeri (Unix-like)" olarak anılır.

**İşletim sistemi nedir?**
Donanım ile kullanıcı/uygulamalar arasında köprü kuran yazılım katmanıdır. İşlemciyi (CPU) zaman dilimlerine bölerek süreçlere paylaştırır (zamanlayıcı/scheduler), belleği yönetir, dosya sistemini sunar, aygıtlarla (disk, ağ kartı, klavye) sürücüler aracılığıyla konuşur. Çekirdek (kernel) bu işlerin merkezinde durur; kabuk (shell), kullanıcı programları ve sistem araçları da çekirdeğin üstüne kurulan katmanlardır.

**Distro (dağıtım) nedir?**
"GNU/Linux" aslında sadece bir çekirdektir (Linux kernel) + GNU araçları (bash, coreutils, gcc vb.) birleşimidir; kendi başına kurulup kullanılabilir hâle gelmesi için paket yöneticisi, kurulum programı, varsayılan yapılandırmalar ve genelde bir masaüstü/sunucu araç seti eklenir. Bu hazır paketin tamamına **dağıtım (distribution/distro)** denir. Örnek: Ubuntu, Debian, Rocky Linux, Arch, Fedora — hepsi aynı Linux çekirdeğini kullanır ama paket yöneticisi, dosya düzeni ve felsefesi farklıdır.

**Neden distro üretilir?**
Çünkü farklı ihtiyaçlar farklı varsayılanlar gerektirir: sunucu için kararlılık ve uzun destek süresi (ör. Rocky Linux, Debian Stable), masaüstü için güncellik ve kolay kullanım (ör. Ubuntu, Fedora), güvenlik testi için özel araç seti (Kali), yönlendirici/güvenlik duvarı için minimal ayak izi (pfSense) gibi. Aynı çekirdeği farklı hedef kitlelere göre "paketleyerek" her grup kendi ihtiyacına uygun bir sistem elde eder.

**Distro seçimleri neye göre yapılır?**
Tipik kriterler: kullanım amacı (sunucu mu masaüstü mü), paket yöneticisi tercihi (apt/deb, dnf/rpm, pacman), destek/güncelleme süresi (LTS mi rolling-release mi), topluluk/dokümantasyon büyüklüğü, kurumsal destek olup olmadığı (RHEL, SUSE gibi ücretli destekli sürümler), donanım uyumluluğu ve ekibin/deneyimin o dağıtıma aşinalığı.

**Özgür yazılım nedir?**
Richard Stallman ve FSF'nin tanımına göre kullanıcıya şu dört özgürlüğü veren yazılımdır: (0) programı istediğin amaçla çalıştırma, (1) kaynak koda erişip nasıl çalıştığını inceleme ve değiştirme, (2) kopyalarını dağıtma, (3) değiştirilmiş sürümleri de dağıtma özgürlüğü. "Ücretsiz" (gratis) ile karıştırılmamalı — vurgu **özgürlük** üzerinedir ("free as in freedom, not free beer"). Açık kaynak (open source) terimi teknik olarak benzer lisansları kapsar ama felsefi vurgusu daha çok pratik faydalar (daha iyi kod kalitesi, işbirliği) üzerinedir; özgür yazılım hareketi ise etik/özgürlük vurgusu yapar.

### Komut Satırı Temelleri

**`-` ve `--` arasındaki fark**
Tek tire (`-`) tek harfli kısa seçenekleri belirtir ve yan yana birleştirilebilir (`-la` = `-l -a`). Çift tire (`--`) ise okunabilir, tam kelime seçenekleri belirtir (`--all`, `--help`) ve birleştirilemez. Çoğu GNU aracı her ikisini de destekler; kısa hâli hızlı yazım için, uzun hâli betiklerde okunabilirlik için tercih edilir.

**`man` ve `info`**
`man <komut>` klasik, bölümlere ayrılmış (NAME, SYNOPSIS, DESCRIPTION, OPTIONS...) kısa referans kılavuzunu gösterir. `info <komut>` GNU projelerinin daha ayrıntılı, hiper-bağlantılı (düğümler arası gezilebilir) belgeleme sistemidir — özellikle GNU araçlarında (coreutils, bash, gcc) `man`'dan daha kapsamlıdır. Kısayol olarak `komut --help` de hızlı bir özet verir.

**`\` (backslash) kaçış (escape) karakteri**
Kabuk (shell) için özel anlamı olan bir karakteri (boşluk, `*`, `$`, vb.) "düz metin" olarak yorumlatmak için kullanılır. `cd Virtual\ Box/` örneğinde boşluk normalde kabuk için "argüman ayracı"dır (yani `Virtual` ve `Box/` iki ayrı argüman gibi algılanır); `\` bu boşluğu kaçırarak (escape ederek) kabuğa "bu boşluk da dosya adının bir parçası" der. Genel kural: `\` kendinden sonra gelen **tek bir karakterin** özel anlamını iptal eder. Alternatifler: tüm adı tırnak içine almak (`cd "Virtual Box/"` veya `cd 'Virtual Box/'`).

**`ls` ve `ls -al` çıktısının anlamı**
`ls` tek başına sadece dosya/dizin adlarını listeler. `ls -a` gizli dosyaları da gösterir (adı `.` ile başlayanlar). `ls -l` "uzun format" verir; `-al` ikisini birleştirir. Uzun formatın satır satır anlamı (bugünkü sohbette detaylandırdığımız kısım):

```
drwxr-x--- 4 ucp ucp 4096 Aug 22 12:51 .cache
│└┬┘└┬┘└┬┘ │  │   │    │        │        │
│ │  │  │  │  │   │    │        │        └─ dosya/dizin adı
│ │  │  │  │  │   │    │        └─ son değiştirilme tarihi
│ │  │  │  │  │   │    └─ boyut (byte)
│ │  │  │  │  │   └─ grup sahibi
│ │  │  │  │  └─ kullanıcı sahibi (owner)
│ │  │  │  └─ hard link sayısı
│ │  │  └─ "diğerleri" izinleri (others)
│ │  └─ grup izinleri (group)
│ └─ sahip izinleri (owner)
└─ dosya tipi: - normal dosya, d dizin, l sembolik link (ayrıca b/c aygıt, s soket, p pipe)
```

- İzin üçlüsü her zaman `rwx` sırasıyla okuma/yazma/çalıştırma anlamına gelir; eksik hak `-` ile gösterilir.
- **Link sayısı**: dosyalarda genelde `1`dir. Dizinlerde en az `2`dir (kendisi `.` + üst dizinden gelen `..` referansı) ve her alt dizin bu sayıyı bir artırır (çünkü alt dizinin `..`'si üst dizine işaret eder).
- `ls -l` çıktısının en üstünde çıkan `total N` satırı, dizindeki girdilerin kapladığı disk blok sayısının (genelde 1024B blok) toplamıdır — dosya boyutlarının toplamı değildir.

**`-R` (recursive) kullanımı**
`ls -R` bir dizini listelerken alt dizinlere de inip onların içeriğini de gösterir. Birçok komutta (`cp -r`, `rm -r`, `chmod -R`, `chown -R`) aynı harf "alt dizinlere de uygula" anlamına gelir.

**`>` ile çıktı yönlendirme ve dosya tanımlayıcıları (file descriptors)**
Her Unix sürecinde varsayılan olarak üç "kanal" açıktır:
- `0` = **stdin** (standart girdi) — komutun okuduğu kaynak, varsayılan klavye.
- `1` = **stdout** (standart çıktı) — komutun normal çıktısı, varsayılan ekran.
- `2` = **stderr** (standart hata) — hata mesajları, varsayılan yine ekran ama `stdout`tan ayrı bir kanaldır.

`>` operatörü stdout'u bir dosyaya yönlendirir (üzerine yazar), `>>` ise dosyanın sonuna ekler. Numarayla belirtilerek hangi kanalın yönlendirileceği seçilebilir:

```bash
ls -al 1> home home5 2> dosya.txt
```
Bu örnekte: `home` dizini listelenir ve çıktısı (`1>`) ekrana değil `home` diye bir hedefe... (not: burada asıl kullanım `ls -al home home5 1> ... 2> ...` şeklindedir) — `home5` dizini yoksa `ls` bunun için üreteceği hata mesajını (`2>`) `dosya.txt` içine yazar, `home`un normal listesi ise stdout'a (ekrana ya da `1>` ile verilen hedefe) gider. Böylece **normal çıktı ile hata çıktısı ayrı ayrı yönetilebilir.**

`&` işareti burada iki farklı bağlamda kullanılabilir:
- Dosya tanımlayıcıları birleştirmede: `2>&1` → "stderr'i, stdout'un şu an yönlendirildiği yere gönder" (ikisini aynı yere birleştirme).
- Komut sonunda: `komut &` → komutu **arka planda (background)** çalıştırır, kabuğu bloklamaz.

**`file` komutu**
Bir dosyanın uzantısına değil, **içeriğine** (magic number/byte imzasına) bakarak türünü tahmin eder. Örn. uzantısı olmayan bir dosyanın ELF çalıştırılabilir mi, metin mi, PNG mi olduğunu `file dosya` ile anlarsın — uzantıya güvenmek yerine gerçek tipi doğrulamak için kullanılır.

**`|` (pipe) kullanımı**
Bir komutun stdout'unu, başka bir komutun stdin'ine bağlar; böylece komutlar zincirlenip küçük araçlardan büyük işler kurulabilir (Unix felsefesinin özü). Örnek:
```bash
ls --help | head -n 10 | tail -n 5
```
Akış: `ls --help` yardım metnini üretir → `head -n 10` bunun ilk 10 satırını alır → `tail -n 5` bu 10 satırın son 5'ini ekrana basar. Yani sonuçta yardım metninin **6-10. satırları** görünür.

**`head` ve `tail`**
`head -n N dosya` dosyanın ilk N satırını, `tail -n N dosya` son N satırını gösterir (varsayılan N=10). `tail -f dosya` ise dosyaya yeni eklenen satırları canlı takip eder (log dosyalarını izlemek için çok kullanılır).

**`pwd`**
"Print Working Directory" — bulunduğun dizinin **mutlak (absolute) yolunu** yazdırır.

**`cd -`**
Bir önceki bulunduğun dizine geri döner (kabuğun `$OLDPWD` değişkenini kullanır). İki dizin arasında hızlı geçiş için kullanışlıdır.

**`printenv`**
O anki kabuk oturumunda tanımlı **çevresel değişkenleri (environment variables)** listeler (`printenv PATH` gibi tek bir değişkeni de sorgulayabilirsin). `env` komutu da benzer işi görür.

**`export değişken="değer"`**
Kabukta tanımlanan bir değişkeni sadece o kabukla sınırlı kalmaktan çıkarıp, o kabuktan başlatılacak **alt süreçlere de (child processes)** miras bırakılacak şekilde işaretler. `export` edilmemiş bir değişken sadece tanımlandığı kabukta görünür; `export` edilmiş bir değişken, örneğin o kabuktan çalıştırdığın bir programın da erişebileceği bir ortam değişkeni hâline gelir.

**`echo`**
Verilen metni (veya değişken değerini `$DEĞİŞKEN` ile) ekrana yazdırır. Değişken içeriğini hızlıca kontrol etmek için sık kullanılır (`echo $PATH`).

**Değişken + komut (tek seferlik geçersiz kılma)**
```bash
DEĞİŞKEN=değer komut
```
Bu söz dizimi, `DEĞİŞKEN`i **sadece o tek komutun çalıştığı süreç için** ayarlar; kabuğun kendi ortamını kalıcı olarak değiştirmez (export edilmiş olsa bile o kabuktaki değeri geçici olarak o komut özelinde ezer). Komut bitince kabuktaki değer eskisi gibi kalır. Örnek: `LANG=C ls` sadece o `ls` çalışırken dil ayarını değiştirir, kalıcı export etmeden.

### Kaynaklar

Bu günün konuları (kabuk mekaniği, `ls -al` çıktısı, I/O yönlendirme, `export`/çevresel değişkenler) POSIX/GNU coreutils'in uzun süredir sabit, `man`/`info` ile sisteminde de doğrudan doğrulanabilir davranışlarıdır — ayrıca kaynak gösterilmedi. Dış kaynaktan alınan tek somut iddia, özgür yazılımın "dört özgürlük" tanımıdır:

- **Özgür yazılımın dört özgürlüğü (freedom 0-3):** [What is Free Software? — GNU Project / Free Software Foundation](https://www.gnu.org/philosophy/free-sw.html)

## Notlar

- Bugünün ana teması: Unix/GNU-Linux felsefesi ve özgür yazılımın "neden"i + kabuk (shell) ile ilk temas — özellikle `ls -al` çıktısını okuyabilmek ve I/O yönlendirmenin (`stdin`/`stdout`/`stderr`) mantığını kavramak.
- `|` (pipe) ve `>` (redirection) arasındaki fark netleşmeli: pipe bir komutun çıktısını başka bir **komuta**, redirection ise bir **dosyaya** bağlar.
- `export` edilmemiş bir değişken sadece o kabukta yaşar; yeni bir terminal açıldığında kaybolur — kalıcılık için `~/.bashrc` gibi başlangıç dosyalarına yazılması gerekir (bu, aşağıdaki takip sorularıyla doğrudan ilişkili).

## Komutlar / Örnekler

```bash
# man / info / help
man ls
info ls
ls --help

# gizli dosyalar dahil uzun format
ls -al

# recursive listeleme
ls -R Belgeler/

# çıktı ve hata ayrı dosyalara yönlendirme
ls -al home home5 1> cikti.txt 2> hata.txt

# stderr'i stdout ile birleştirip tek dosyaya yazma
ls -al home home5 > hepsi.txt 2>&1

# arka planda çalıştırma
sleep 60 &

# dosya türünü içerikten anlama
file /bin/bash

# pipe zinciri
ls --help | head -n 10 | tail -n 5

# geçmiş dizine dönme
cd /tmp
cd -            # tekrar önceki dizine döner

# çevresel değişkenler
printenv PATH
export RENK="mavi"
echo $RENK

# tek seferlik değişken geçersiz kılma
LANG=C ls -al
```

## Sorular / Takip Edilecekler

- [ ] Bir çevresel değişken değeri aynı kalsın istiyorum bunu nasıl yaparım.
- [ ] Farklı kullanıcıların çevresel değişken farkları nedir?
- [ ] Bir çevresel değişken mevcut tüm kullanıcılarda aynı olsun ama yeni kullanıcıda farklı olsun istiyorum nasıl olur.

> [!TIP]
> **Ön araştırma notu (eğitmenle teyit edilmeli)**
> - **Kalıcı değişken:** `export DEĞİŞKEN="değer"` satırını `~/.bashrc` (etkileşimli kabuklar) dosyanın sonuna eklersen, her yeni terminal açılışında otomatik tanımlanır. Sistem genelinde tek bir kullanıcıya değil **tüm giriş kabuklarına** kalıcı olsun istersen `~/.bash_profile` / `~/.profile` de kullanılabilir (dosyaların hangi durumda okunduğu login/non-login shell farkına göre değişir — bu ayrım Gün 1'de işlenmedi, ileride netleşecektir).
> - **Kullanıcılar arası fark:** Her kullanıcının kendi `~/.bashrc`, `~/.profile` gibi dosyaları vardır; bu yüzden aynı isimli değişken kullanıcıdan kullanıcıya farklı değer taşıyabilir — her kullanıcı kendi ev dizinindeki başlangıç dosyalarını kontrol eder.
> - **Tüm kullanıcılarda ortak, yeni kullanıcıda farklı:** Sistem geneli için `/etc/environment` veya `/etc/profile` / `/etc/profile.d/*.sh` kullanılır (tüm kullanıcılara uygulanır). Yeni açılacak bir kullanıcıya farklı bir değer vermek için ise kullanıcı oluşturulurken şablon olarak kullanılan `/etc/skel/` dizinindeki `.bashrc`/`.profile` dosyalarına o değişkeni ekleyip, sonradan o kullanıcının kendi dosyasında override etmek gerekir. Bu konu muhtemelen ileriki günlerde ("Kullanıcı ve Grup Yönetimi" bölümü) daha ayrıntılı işlenecek.
