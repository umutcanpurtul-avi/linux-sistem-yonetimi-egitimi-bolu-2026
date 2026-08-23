---
tags: [linux, egitim, dosya-sistemi, izinler]
modul: 04
durum: tamamlandi
---

# 04 — Linux Dosya Sistemi

> **Ön koşul:** [02-temel-komutlar](02-temel-komutlar.md)
> **Süre:** ~3 saat

## Hedefler

- [ ] FHS'ye göre bir dosyanın nereye ait olduğunu söyleyebiliyorum
- [ ] 7 dosya tipini `ls -l` çıktısından tanıyorum
- [ ] Sayısal (`755`) ve sembolik (`u+x`) izin gösterimini birbirine çevirebiliyorum
- [ ] SUID/SGID/Sticky bitlerinin ne yaptığını biliyorum
- [ ] `umask` hesabını yapabiliyorum
- [ ] `tar` ile arşivleme ve geri açma yapabiliyorum

---

## 1. Dosya Sistemi Hiyerarşisi (FHS)

> [!NOTE]
> **Neden bu konu var?**
> Windows'a alışkınsan ilk şaşıracağın şey şu: **sürücü harfi yok**. `C:`, `D:`, `E:` diye
> ayrı ayrı disklerin yerine, Linux'ta **tek bir kök** vardır: `/`. İkinci bir disk taksan
> bile o disk kendine ait bir harf almaz — mevcut ağacın içinde **bir dizinin üzerine
> bağlanır** (bu işleme `mount` denir, ileride 09. modülde ayrıntılı işlenecek). Yani
> `/home` dediğinde bu aslında ayrı bir diskte olabilir, ama sen bunu fark etmeden
> `/home/ali/belge.txt` diye erişirsin — sanki hepsi tek bir diskmiş gibi görünür.
> Bu tasarımın **neden** böyle olduğunu anlamak önemli: disk sayısı, RAID yapısı,
> ağ depolaması değiştiğinde bile klasör yolları (ve dolayısıyla o yolları kullanan
> programlar) **hiç değişmez**. Disk arkada değişir, ağaç önde aynı kalır.

Linux'ta **her şey bir dosyadır** ve tek bir kök (`/`) ağacı vardır. Windows'taki
gibi `C:`, `D:` yoktur; diskler ağacın bir dalına **bağlanır** (mount).

```
/
├── bin      -> usr/bin    Temel kullanıcı komutları (ls, cp)
├── sbin     -> usr/sbin   Sistem yönetimi komutları (fdisk, ip)
├── boot                   Kernel, initramfs, GRUB   ← genelde ayrı bölüm
├── dev                    Aygıt dosyaları (sda, null, tty)
├── etc                    ⭐ Yapılandırma dosyaları. Tamamı METİN.
├── home                   Kullanıcı ev dizinleri
├── root                   root'un ev dizini (/home/root DEĞİL)
├── lib      -> usr/lib    Paylaşılan kütüphaneler
├── media                  Çıkarılabilir medya otomatik bağlanır
├── mnt                    Geçici manuel bağlama noktası
├── opt                    3. parti / kurumsal yazılımlar
├── proc                   ⭐ Sanal FS: çalışan süreçler + kernel (diskte yok!)
├── sys                    ⭐ Sanal FS: kernel ve donanım arayüzü
├── run                    Çalışma zamanı verisi (PID, socket) — RAM'de
├── srv                    Servislerin sunduğu veri (web, ftp)
├── tmp                    Geçici — açılışta temizlenir
├── usr                    Kullanıcı programları (salt okunur olabilir)
│   ├── bin, sbin, lib, share, local
└── var                    ⭐ Değişken veri: log, veritabanı, mail, cache, spool
    ├── log                Log dosyaları
    ├── lib                Uygulama durum verisi
    ├── spool              Kuyruklar (cron, mail, print)
    └── tmp                Yeniden başlatmada silinmeyen geçici
```

> [!TIP]
> **Bu ağacı nasıl akılda tutarsın?**
> Ezberlemeye çalışma, **mantığını** kavra: her dizin "kim için, ne zaman değişir"
> sorusuna göre ayrılmış.
> - **`/bin`, `/sbin`, `/usr`** → programların kendisi. Kurulum/güncelleme dışında değişmez.
> - **`/etc`** → o programların **ayarları**. Sen elle düzenlersin, program kendi değiştirmez (genelde).
> - **`/var`** → programların çalışırken ürettiği **veri** (log, kuyruk, veritabanı). Sürekli büyür.
> - **`/home`, `/root`** → **insan** verisi, kullanıcıların kendi dosyaları.
> - **`/tmp`, `/run`** → **geçici**, kaybolması sorun olmayan şeyler.
> - **`/proc`, `/sys`** → diskte hiç yer kaplamayan, kernel'in "canlı" durumunu gösteren pencereler.
> Bir dosyayı nereye koyacağını bilemediğinde kendine şunu sor: "Bu bir program mı,
> bir ayar mı, üretilen bir veri mi, yoksa bir insanın kişisel dosyası mı?" — cevap
> seni doğru dizine götürür.

### Bilinmesi gereken 4 kritik nokta

**`/etc` her şeyin ayarı, tamamı metin.** Windows'taki registry'nin karşılığı yoktur;
her ayar okunabilir bir dosyadadır, `grep`lenebilir, sürüm kontrolüne konabilir.

> [!NOTE]
> **Bunun pratikte ne anlama geldiğini gör**
> Windows'ta bir ayarı değiştirmek istediğinde çoğu zaman bir arayüz açman, tıklaman,
> Registry Editor'a girmen gerekir — ayarlar binary bir veritabanında (registry) saklanır,
> elle okunamaz. Linux'ta ise SSH ile bağlı, hiç grafik arayüzü olmayan bir sunucuda bile
> `cat /etc/ssh/sshd_config` yazıp SSH ayarlarının tamamını düz metin olarak okuyabilirsin,
> `vim` ile düzenleyebilirsin, `git init /etc && git add -A && git commit` ile **tüm sistem
> ayarlarını versiyon kontrolüne alabilirsin** — kim ne zaman ne değiştirdi, tam olarak görürsün.
> Bu, otomasyon (Ansible gibi araçlar metin dosyası üretip `/etc`'ye kopyalar) ve felaket
> kurtarma (bir yapılandırmayı yedekten geri almak = dosyayı kopyalamak) açısından devasa
> bir avantajdır.

**`/proc` ve `/sys` diskte yok.** Kernel bunları RAM'de üretir.
```bash
cat /proc/cpuinfo        # CPU bilgisi
cat /proc/meminfo        # Bellek
cat /proc/1234/cmdline   # PID 1234 hangi komutla çalışıyor
ls /proc/1234/fd         # O sürecin açık dosyaları
cat /sys/class/net/ens18/address   # MAC adresi
```

> [!NOTE]
> **"Diskte yok" ne demek, nasıl çalışıyor o zaman?**
> `/proc` ve `/sys`, `ls -l /` çıktısında normal bir dizin gibi görünür ama aslında
> bunlar **sanal dosya sistemleridir (virtual filesystem)** — kernel, "her şey bir
> dosyadır" felsefesini kendi iç durumunu göstermek için de kullanır. `cat /proc/meminfo`
> yazdığında disktten bir dosya okunmaz; bu isteği alan kernel, **o an** bellek durumunu
> hesaplayıp metin olarak sana "dosyaymış gibi" sunar. Bu yüzden `/proc/meminfo`'nun
> boyutu `ls -l`'de `0` görünür — kernel içeriği önceden üretip diske yazmıyor, sen
> okuduğun anda anlık üretiyor. Bunun pratik faydası: `top`, `ps`, `free`, `lsof` gibi
> araçların **hepsi** aslında arkada bu `/proc` dosyalarını okur; sen de aynı bilgiye
> hiçbir araç kurmadan doğrudan erişebilirsin. `/proc/1234/cmdline` PID 1234'ün tam
> olarak hangi komutla başlatıldığını, `/proc/1234/fd` ise o sürecin o an açık tuttuğu
> tüm dosya tanımlayıcılarını (dosyalar, socket'ler, pipe'lar) gösterir — bir sürecin
> "hangi dosyayı kilitli tutuyor" sorusunu çözmenin en temel yolu budur.

**`/usr` birleşmesi (usrmerge).** RHEL 7+ ve Debian 12+'da `/bin` artık `/usr/bin`'e
symlink'tir. Eski dokümanlardaki "`/bin` temel komutlar, `/usr/bin` diğerleri" ayrımı
pratikte kalktı.

> [!NOTE]
> **Bu neden değişti?**
> Eskiden `/bin` "sistem açılışı sırasında, `/usr` henüz bağlanmamışken bile çalışması
> gereken temel komutlar" içindi (çünkü bazı sistemlerde `/usr` ayrı bir disk bölümüydü
> ve açılışın erken aşamasında henüz mount edilmemiş olabiliyordu). Modern sistemlerde
> initramfs zaten `/usr`'ı erkenden bağladığı için bu ayrımın pratik bir faydası kalmadı,
> sadece kafa karıştırıyordu (aynı komutun iki farklı yerde olup olmadığını kontrol etmek
> gerekiyordu). "usrmerge" ile `/bin`, `/sbin`, `/lib` artık gerçek dizin değil, sırasıyla
> `/usr/bin`, `/usr/sbin`, `/usr/lib`'e işaret eden birer sembolik linktir — ikisi de
> aynı dosyaya çıkar, hangisini yazarsan yaz fark etmez.

**`/tmp` vs `/var/tmp`.** `/tmp` yeniden başlatmada silinir (modern sistemlerde
`systemd-tmpfiles` 10 günde bir de temizler). `/var/tmp` reboot'tan sağ çıkar.

> [!NOTE]
> **Hangi durumda hangisini kullanmalısın?**
> Bir programın çalışması sırasında ürettiği, program bitince gerek kalmayan ara
> dosyalar (`/tmp/derleme-xyz123`) için `/tmp` doğru yerdir — kimse elle temizlemek
> zorunda kalmaz, sistem kendi temizler. Ama örneğin büyük bir dosyayı indirip parça
> parça işleyen, saatler/günler sürebilecek bir işlemin ara durumunu `/var/tmp`'ye
> koymalısın; aksi halde sistem yeniden başlarsa (güncelleme sonrası gibi) işin
> yarıda kalır ve ilerleme kaybolur.

> **Dağıtım farkı:** Bazı sistemlerde `/tmp` bir `tmpfs`'tir (RAM'de). `df -h /tmp`
> ile kontrol et. tmpfs ise büyük dosya koyma, RAM'ini yersin.

---

## 2. Dosya tipleri

> [!NOTE]
> **Neden 7 farklı tip var, hepsi "dosya" değil miydi?**
> Linux'un "her şey bir dosyadır" felsefesi, bir diskteki metin dosyasıyla bir ağ
> soketini veya bir terminal ekranını **aynı arayüzle** (aç/oku/yaz/kapat) kullanabilmeni
> sağlar. Ama arka planda bu "dosyaların" gerçek davranışı çok farklıdır — biri diskte
> duran veri, biri o an akan bir bayt akışı, biri iki sürecin birbirine mesaj gönderdiği
> bir kanaldır. `ls -l` çıktısının en başındaki tek karakter, sana **hangi tür arayüzle
> karşı karşıya olduğunu** söyler; bunu bilmeden `cat` ettiğin bir soket dosyası seni
> sonsuza kadar bekletebilir, çünkü o "dosya" aslında bir akıştır, sonu yoktur.

`ls -l` çıktısının **ilk karakteri** dosya tipini söyler:

| Karakter | Tip | Örnek |
|---|---|---|
| `-` | Normal dosya | `/etc/passwd` |
| `d` | Dizin | `/etc` |
| `l` | Sembolik link | `/bin -> usr/bin` |
| `b` | Blok aygıt (tamponlu, disk) | `/dev/sda` |
| `c` | Karakter aygıt (akış, terminal) | `/dev/null`, `/dev/tty` |
| `s` | Socket (yerel IPC) | `/run/docker.sock` |
| `p` | Named pipe / FIFO | `mkfifo` ile oluşur |

> [!NOTE]
> **Blok aygıt ile karakter aygıt farkı nedir, neden ikisi de var?**
> **Blok aygıt** (`b`), verinin sabit boyutlu bloklar (genelde 512B veya 4KB) halinde,
> **rastgele erişimle** (ortasından okuma/yazma yapılabilir, tamponlanabilir) okunup
> yazıldığı aygıtlardır — diskler böyledir, çünkü bir dosyanın ortasına atlayıp
> okuyabilmen gerekir. **Karakter aygıt** (`c`) ise veriyi **akış (stream)** halinde,
> baytları sırayla, tamponlamadan sunar — bir klavyeden veya terminalden veri "geriye
> gidip tekrar okunamaz", sadece sırayla akar. `/dev/null` klasik bir karakter aygıttır:
> ona ne yazarsan yazılsın kaybolur (bir "çöp kutusu"), ondan okuduğunda anında dosya
> sonu (EOF) alırsın.
>
> **Socket** (`s`), iki sürecin (aynı makinede veya farklı konteynerlerde) birbirine
> dosya sistemi üzerinden mesaj gönderebilmesini sağlayan bir uç noktadır — Docker'ın
> `/run/docker.sock` üzerinden konuşması buna örnektir; `docker` komutu aslında bu
> soket dosyasına yazıp okuyarak Docker daemon'ıyla konuşur. **Named pipe / FIFO**
> (`p`) ise iki sürecin, birinin yazdığını diğerinin **sırayla ve tek yönlü** okuduğu
> bir kanaldır (`mkfifo boru` ile diskte "kalıcı" bir isimle oluşturulabilir, normal
> `|` pipe'ının kabuk kapanınca kaybolmasından farklı olarak).

```bash
ls -l /dev/sda /dev/null /etc /bin
file /dev/sda /etc/passwd /bin
```

**Faydalı sanal aygıtlar:**
```bash
komut > /dev/null 2>&1      # Çıktıyı tamamen sustur (çöp kutusu)
cat /dev/zero               # Sonsuz sıfır — dosya doldurmak için
head -c 32 /dev/urandom     # Rastgele bayt — parola/anahtar üretimi
```

> [!TIP]
> **Bu üç aygıtın gerçek hayatta ne işe yaradığını gör**
> - `/dev/null`: Bir betiğin çıktısını hiç görmek istemediğinde (örneğin cron'da
>   çalışan sessiz bir yedekleme işi) `komut > /dev/null 2>&1` yazarsın — çıktı da
>   hata da yutulur, hiçbir log dosyası şişmez.
> - `/dev/zero`: Boyutu belli, içeriği önemsiz bir test dosyası veya swap dosyası
>   oluştururken kaynak olarak kullanılır (`dd if=/dev/zero of=test.img bs=1M count=100`
>   gibi — 09. modülde göreceksin). Sonsuz sıfır ürettiği için `count` ile ne kadar
>   istediğini sen sınırlarsın.
> - `/dev/urandom`: Bir SSH anahtarı, bir geçici parola, bir güvenlik token'ı
>   üretmen gerektiğinde kriptografik olarak güvenli rastgelelik kaynağıdır —
>   `$RANDOM` gibi kabuğun kendi rastgele sayı üretecinden çok daha güvenlidir,
>   çünkü tahmin edilemez.

---

## 3. İzinler — bu bölümü gerçekten öğren

> [!NOTE]
> **İzinler neden var, ne sorunu çözer?**
> Linux çok kullanıcılı bir sistem olarak tasarlandı — aynı makinede birden fazla
> kullanıcı, hatta birbirini tanımayan kullanıcılar aynı anda çalışabilir. Eğer her
> kullanıcı her dosyayı okuyup değiştirebilseydi, biri diğerinin özel dosyalarını
> okuyabilir, sistem dosyalarını bozabilirdi. İzin sistemi, **her dosya ve dizin için
> "kim ne yapabilir" sorusuna üç ayrı seviyede** (dosyanın sahibi, dosyanın ait olduğu
> grup, sistemdeki herkes) cevap verir. Bu, tek kullanıcılı bir Windows masaüstünde
> pek hissedilmez ama bir sunucuda — mesela 5 farklı geliştiricinin aynı makinede
> çalıştığı bir ortamda — hayati önemdedir: birinin yanlışlıkla diğerinin dosyasını
> silmesini, ya da normal bir kullanıcının sistem ayarlarını bozmasını izin sistemi
> engeller.

```
-rwxr-xr--  1 ali gelistirici 1024 Aug 20 14:32 script.sh
 │└┬┘└┬┘└┬┘
 │ u  g  o
 │ │  │  └── other  : r-- (4)  → sadece oku
 │ │  └───── group  : r-x (5)  → oku + çalıştır
 │ └──────── user   : rwx (7)  → oku + yaz + çalıştır
 └────────── tip
```

> [!NOTE]
> **Bu satırı gerçekten sökerek oku**
> `-rwxr-xr--` toplam 10 karakterdir ve 4 parçaya ayrılır:
> 1. **İlk karakter (`-`)**: dosya tipi (yukarıdaki tabloya bak — burada `-` = normal dosya).
> 2. **2-4. karakterler (`rwx`)**: dosyanın **sahibinin** (`ali`) izinleri — okuma,
>    yazma, çalıştırma, üçü de açık.
> 3. **5-7. karakterler (`r-x`)**: dosyanın ait olduğu **grubun** (`gelistirici`)
>    izinleri — okuma ve çalıştırma açık, yazma kapalı (`-` ile gösteriliyor).
> 4. **8-10. karakterler (`r--`)**: sistemdeki **herkesin** (other) izinleri —
>    sadece okuma açık.
>
> Yani bu dosyayı: sahibi `ali` her şeyi yapabilir, `gelistirici` grubundaki başkaları
> sadece okuyup çalıştırabilir (değiştiremez), grupta olmayan herkes sadece okuyabilir.
> Sayısal karşılığı `754`'tür (7=rwx, 5=r-x, 4=r--) — bu sayıları nereden bulduğunu
> aşağıda `chmod` bölümünde göreceksin: her hak bir bite karşılık gelir (`r`=4, `w`=2,
> `x`=1) ve üçü toplanır (rwx = 4+2+1 = 7, r-x = 4+0+1 = 5, r-- = 4+0+0 = 4).

| İzin | Sayı | Dosyada | **Dizinde** |
|---|---|---|---|
| `r` (read) | 4 | İçeriği okuyabilir | İçindekileri **listeleyebilir** (`ls`) |
| `w` (write) | 2 | İçeriği değiştirebilir | İçinde dosya **oluşturup silebilir** |
| `x` (execute) | 1 | **Çalıştırabilir** | İçine **girebilir** (`cd`), içindekilere erişebilir |

> [!WARNING]
> **Dizinlerde izinlerin anlamı dosyalardan tamamen farklıdır — burada çoğu kişi takılır**
> Bir dosyada `r` = "içeriğini okuyabilirsin" gibi sezgiseldir. Ama bir **dizinde**
> `r` sadece "içindeki dosya **isimlerini** listeleyebilirsin" demektir (`ls` çalışır) —
> o dosyaların **içeriğine** erişip erişemeyeceğin ayrı bir konudur (o da her dosyanın
> kendi izinlerine bağlıdır). Bir dizinde `x` ise çok farklı bir şey ifade eder:
> "çalıştırma" değil, **"bu dizine girebilirsin, içindeki dosyalara isimle erişebilirsin"**
> anlamına gelir (`cd dizin` ya da `cat dizin/dosya.txt` yapabilmen için gerekir).
> Bunun sonucu: bir dizinde `r` var ama `x` yoksa, `ls` ile dosya **isimlerini**
> görürsün ama hiçbirinin içeriğine giremezsin, `cd` bile yapamazsın — "Permission
> denied" alırsın. Tersine `x` var ama `r` yoksa, dizine `cd` yapabilir ve içindeki bir
> dosyanın **tam adını biliyorsan** ona erişebilirsin, ama `ls` ile dizinin içeriğini
> listeleyemezsin (bu bazen kasıtlı yapılır: "adını bilmeyen göremesin" gibi bir gizlilik
> katmanı için).

> ⚠️ Dizinlerde `x` olmadan `r` işe yaramaz. `r` var `x` yoksa isimleri görürsün
> ama hiçbirine erişemezsin. Klasik yanlış: `chmod 644 /var/www` — dizine girilemez olur.
> Dizinler neredeyse her zaman `755` veya `750` olmalıdır.

### chmod — sayısal yöntem

> [!NOTE]
> **Sayısal yöntem neden var, mantığı ne?**
> `chmod` "change mode" (kip değiştir) demektir. Sayısal yöntemde her izin üçlüsünü
> (kullanıcı/grup/diğer) tek bir rakamla ifade edersin çünkü `r`, `w`, `x` ikili
> (var/yok) bayraklardır ve ikili bayraklar toplanarak tek bir sayıya sığdırılabilir:
> `r`=4, `w`=2, `x`=1 — bunlar 2'nin kuvvetleridir (2⁰=1, 2¹=2, 2²=4), yani her
> kombinasyonun **tek bir toplamı** vardır ve o toplamdan hangi izinlerin açık
> olduğunu geri çıkarabilirsin (7=4+2+1=rwx, 6=4+2=rw-, 5=4+1=r-x, 4=r--, 0=---).
> Üç haneli bir sayı (`754` gibi) böylece "sahip=7, grup=5, diğer=4" demenin kısa yoludur.
> Bu yöntemin avantajı: **mutlak** bir durum tanımlarsın — dosyanın önceki izinleri
> ne olursa olsun, `chmod 644` dediğinde sonuç kesin olarak `rw-r--r--` olur.

```bash
chmod 755 script.sh      # rwxr-xr-x  → betikler, dizinler
chmod 644 dosya.txt      # rw-r--r--  → normal dosyalar
chmod 600 ~/.ssh/id_rsa  # rw-------  → gizli anahtarlar (ZORUNLU)
chmod 700 ~/.ssh         # rwx------  → ssh dizini
chmod 640 /etc/shadow    # rw-r-----
chmod -R 755 /var/www    # özyinelemeli
```

> [!WARNING]
> **`~/.ssh/id_rsa` neden `600` olmak ZORUNDA?**
> SSH istemcisi, özel anahtar dosyanı okumadan önce izinlerini kontrol eder. Eğer
> grup veya diğerleri okuyabiliyorsa ("başka biri bu özel anahtarı okuyabilir" demek,
> ki bu anahtar senin kimliğin) SSH bağlanmayı **reddeder** — "UNPROTECTED PRIVATE KEY
> FILE" hatası verir. Bu bir güvenlik önlemidir: bir sunucudaki özel anahtarın başka
> kullanıcılar tarafından okunabilir olması, o anahtarla giriş yapılan **her yere**
> yetkisiz erişim demektir.

### chmod — sembolik yöntem

> [!NOTE]
> **Sembolik yöntem ne zaman sayısaldan daha iyidir?**
> Sayısal yöntem "dosyanın izinleri tam olarak şu olsun" derken, sembolik yöntem
> "mevcut izinlere şunu ekle/çıkar" der — yani **göreceli (relative)** bir işlemdir.
> Mesela bir betiğin izinlerini bilmeden sadece "çalıştırılabilir de olsun" demek
> istiyorsan (`chmod u+x script.sh`), sayısal yöntemle önce mevcut izni öğrenip
> (`ls -l`) sonra hesaplayıp yazman gerekirdi; sembolik yöntemle mevcut durumu bilmene
> gerek kalmadan doğrudan ekleyebilirsin.

```bash
chmod u+x script.sh      # sahibe çalıştırma ekle
chmod g-w dosya          # gruptan yazmayı al
chmod o=  dosya          # diğerlerinin TÜM izinlerini kaldır
chmod a+r dosya          # herkese (all) okuma
chmod u+x,g+x,o-rwx dosya
```

**Ne zaman hangisi?** Mutlak bir izin durumu istiyorsan sayısal (`chmod 644`).
Mevcut izinlere ekleme/çıkarma yapıyorsan sembolik (`chmod +x`).

### Akıllı özyineleme: `X` (büyük X)

```bash
chmod -R a+rX /var/www
```
Büyük `X`: **dizinlere** ve zaten çalıştırılabilir olan dosyalara `x` verir,
normal dosyalara vermez. `chmod -R 755` yaparsan tüm `.html` dosyaları da
çalıştırılabilir olur — güvenlik açığı. `X` doğru yoldur.

> [!NOTE]
> **Bunun "güvenlik açığı" olmasının sebebi tam olarak nedir?**
> `chmod -R 755` yaptığında dizin farkı gözetmeden **her şeye** `x` (çalıştırma)
> hakkı verirsin. Bir web sunucusunda kullanıcının yüklediği bir resim ya da PHP
> dosyası "çalıştırılabilir" hale gelirse, sunucu yanlış yapılandırılmışsa o dosya
> bir program gibi çalıştırılabilir hale gelebilir — saldırgan resim gibi görünen
> ama aslında kod içeren bir dosya yükleyip sunucuda kod çalıştırabilir. Büyük `X`
> bunu önler: sadece "zaten en az bir yerde çalıştırılabilir olan" dosyalara (yani
> muhtemelen gerçekten programlar olan dosyalara) ve tüm dizinlere (dizinlerde `x`
> zaten "içine girebilme" anlamına geldiği için her zaman gerekli) `x` ekler; düz
> veri dosyalarına (resim, metin, PHP kaynak kodu) dokunmaz.

---

## 4. Özel izin bitleri: SUID, SGID, Sticky

> [!NOTE]
> **Bunlar neden var, standart rwx yetmiyor mu?**
> Standart `rwx` üçlüsü "kim, neyi yapabilir" sorusuna cevap verir ama şu soruyu
> cevaplayamaz: **"bu program çalıştığında KİMİN yetkisiyle çalışacak?"** Normalde
> bir programı çalıştırdığında, o program **seni çalıştıran kullanıcının** yetkisiyle
> çalışır. Ama bazı işler (parola değiştirmek gibi) normal bir kullanıcının doğrudan
> yapamayacağı, root yetkisi gerektiren işlemlerdir. SUID/SGID/Sticky, bu "kimin
> yetkisiyle" ve "kim silebilir" sorularına standart rwx'in cevap veremediği,
> ek/özel durumlar için cevap verir.

| Bit | Sayı | Dosyada etkisi | Dizinde etkisi |
|---|---|---|---|
| SUID | 4000 | Program **sahibinin** yetkisiyle çalışır | — |
| SGID | 2000 | Program **grubunun** yetkisiyle çalışır | Yeni dosyalar dizinin grubunu alır ⭐ |
| Sticky | 1000 | — | Sadece **sahibi** kendi dosyasını silebilir ⭐ |

```bash
ls -l /usr/bin/passwd
# -rwsr-xr-x  1 root root ...
#    ↑ s = SUID

ls -ld /tmp
# drwxrwxrwt ...
#         ↑ t = sticky
```

**SUID neden var?** `passwd` komutu `/etc/shadow` dosyasını yazmak zorunda, ama o dosya
sadece root'a açık. SUID sayesinde normal kullanıcı `passwd` çalıştırdığında program
root yetkisiyle çalışır. Güçlü ama **tehlikeli** — SUID'li bir programda açık varsa
root olunur.

> [!NOTE]
> **Bunu somut bir örnek üzerinden gör**
> Normal kullanıcı `ali` kendi parolasını değiştirmek istiyor: `passwd` komutunu
> çalıştırıyor. Bu komutun yapması gereken şey, `/etc/shadow` dosyasındaki `ali`
> satırını güncellemek. Ama `/etc/shadow` izinleri `640` (sadece root okuyup yazabilir,
> normal kullanıcılar hiç erişemez) — çünkü içinde herkesin parola hash'leri var,
> herkes okuyabilseydi hash'leri kırmaya çalışabilirdi. Çelişki: `ali` kendi parolasını
> değiştirebilmeli ama `/etc/shadow`'a dokunamamalı. Çözüm SUID: `/usr/bin/passwd`
> dosyasının sahibi `root`'tur ve SUID biti açıktır. `ali` bu programı çalıştırdığında,
> program **`ali`'nin değil, dosyanın sahibi olan `root`'un** yetkisiyle çalışır —
> yani o an için geçici olarak root gibi davranır, `/etc/shadow`'u güncelleyebilir,
> sonra normal `ali` yetkisine döner. Program kendi içinde "sadece kendi satırını
> değiştirebilirsin" kontrolünü yapar; SUID sadece dosyaya erişim iznini açar, mantığı
> kontrol etmez — bu yüzden SUID'li bir programın kendi içinde güvenlik açığı olursa
> (örneğin kontrolsüz bir komut çalıştırma noktası), o açığı kullanan kişi doğrudan
> root yetkisi kazanır. Bu yüzden sistemdeki SUID'li dosya sayısı **minimumda**
> tutulmalı ve düzenli denetlenmelidir (aşağıdaki `find / -perm -4000` komutuyla).

**Sticky neden var?** `/tmp` herkese yazılabilir (`777`). Sticky olmasaydı, Ali'nin
dosyasını Veli silebilirdi. Sticky bit "yazma iznin var ama sadece kendi dosyanı silebilirsin" der.

> [!NOTE]
> **Neden `/tmp` herkese yazılabilir olmak zorunda, daha güvenli yapılamaz mı?**
> `/tmp`'in amacı, sistemdeki **her kullanıcının** geçici dosya oluşturabileceği ortak
> bir alan olmasıdır — herhangi bir program (senin çalıştırdığın bir uygulama dahil)
> orada geçici dosya yaratabilmeli. Bunu sağlamanın yolu izinleri `777` (herkes
> okuyabilir/yazabilir/girebilir) yapmaktır. Ama standart `w` izni "bu dizinde dosya
> oluşturup **silebilirsin**" anlamına geldiği için, `777` tek başına olsaydı, `ali`
> tarafından oluşturulan bir geçici dosyayı `veli` de silebilirdi (çünkü `veli`'nin de
> dizine yazma izni var) — kötü niyetli ya da kazara veri kaybına yol açabilirdi.
> Sticky bit, bu genel yazma izninin **silme** kısmını kısıtlar: "herkes buraya dosya
> koyabilir, ama bir dosyayı sadece onu koyan (ya da root) silebilir." `ls -ld /tmp`
> çıktısındaki en sondaki `t` harfi bu bitin açık olduğunu gösterir (küçük `t` = hem
> sticky hem `x` açık, büyük `T` = sticky açık ama `x` kapalı — bu ikinci durum
> nadirdir ve genelde bir yapılandırma hatasıdır).

**SGID dizin — ekip paylaşımının doğru yolu:**
```bash
sudo mkdir /srv/proje
sudo groupadd gelistirici
sudo chgrp gelistirici /srv/proje
sudo chmod 2775 /srv/proje       # 2 = SGID
# Artık bu dizinde oluşturulan her dosya otomatik "gelistirici" grubuna ait olur
```

> [!NOTE]
> **SGID olmadan bu senaryoda ne ters gider?**
> SGID olmadan, bir dizindeki yeni dosyalar **oluşturan kullanıcının birincil grubunu**
> alır, dizinin grubunu değil. Yani `ali` (birincil grubu `ali`) ve `veli` (birincil
> grubu `veli`) `gelistirici` grubuna ek üye olarak eklenmiş olsalar bile, `ali`
> `/srv/proje` içinde bir dosya oluşturduğunda o dosyanın grubu `ali` olur — `veli`
> bu dosyaya `gelistirici` grup izniyle erişemez, çünkü dosyanın grubu `gelistirici`
> değil `ali`'dir. SGID biti dizine konduğunda, kural değişir: "bu dizinde oluşturulan
> her yeni dosya, **oluşturanın grubunu değil, dizinin kendi grubunu** miras alır."
> Böylece herkesin oluşturduğu dosyalar otomatik olarak `gelistirici` grubuna ait olur
> ve ekipteki herkes birbirinin dosyasına erişebilir — elle `chgrp` yapmaya gerek kalmaz.

```bash
chmod u+s dosya    # SUID ekle (= chmod 4755)
chmod g+s dizin    # SGID ekle (= chmod 2775)
chmod +t dizin     # Sticky ekle (= chmod 1777)

# Güvenlik denetimi: sistemdeki tüm SUID dosyalar
sudo find / -perm -4000 -type f 2>/dev/null
```

---

## 5. umask

> [!NOTE]
> **umask neden var, hangi problemi çözer?**
> Yeni bir dosya veya dizin oluşturduğunda, "bu ilk açıldığında ne kadar açık izinle
> gelsin" sorusunun bir varsayılanı olması gerekir. Eğer her yeni dosya varsayılan
> olarak herkese açık (`666`/`777`) gelseydi, dikkatsiz bir `touch` veya `mkdir`
> komutu istemeden hassas bir dosyayı herkese okunabilir/yazılabilir bırakabilirdi.
> `umask`, "yeni oluşan her şeyden **hangi izinleri baştan çıkar**" diyen bir filtredir
> — böylece her komutta elle `chmod` yapmak zorunda kalmadan, sistem genelinde güvenli
> bir varsayılan sağlarsın.

Yeni oluşturulan dosyaların izni `umask` ile **kısıtlanır**.

```
Dosya başlangıç:  666 (rw-rw-rw-)   ← dosyalar asla x ile doğmaz
Dizin başlangıç:  777 (rwxrwxrwx)

Sonuç = başlangıç − umask
```

> [!NOTE]
> **"Dosyalar asla x ile doğmaz" neden?**
> Bir dosyanın çalıştırılabilir olması, onu bilerek sen (`chmod +x`) ya da bir kurulum
> programı belirlemesi gereken bir karardır — rastgele oluşan her metin/veri dosyasının
> otomatik olarak "çalıştırılabilir" sayılması güvenlik açısından tehlikelidir (birisi
> senin indirdiğin bir dosyanın içine kod koyup çalıştırmanı sağlamaya çalışabilir).
> Bu yüzden işletim sistemi dosyalar için başlangıç izin tavanını `666` (x hiç yok)
> olarak sabitlemiştir; `x` sadece elle eklenir. Dizinler ise `x` olmadan işe
> yaramayacağı (yukarıda gördüğün gibi, `x`'siz bir dizine girilemez) için başlangıç
> tavanları `777`'dir.

| umask | Yeni dosya | Yeni dizin |
|---|---|---|
| `022` | 644 | 755 |
| `002` | 664 | 775 |
| `027` | 640 | 750 |
| `077` | 600 | 700 |

> [!NOTE]
> **Bu tablodaki çıkarma işlemini elle nasıl yaparsın?**
> `umask` bir "çıkarma" değil aslında **bit bazında maskeleme**dir ama basit
> durumlarda çıkarma gibi düşünmek işe yarar. Örnek: `umask 027` iken yeni bir
> **dosya** oluşturuyorsun. Dosyanın başlangıcı `666`. `umask`'ın her hanesi, o
> haneden **hangi hakların kapatılacağını** söyler: `0` (sahip) → hiçbir şey kapanmaz,
> sahip hakları olduğu gibi kalır (rw-); `2` (grup) → `w` (yazma, değeri 2) kapanır,
> `rw-`den `w` çıkar, `r--` kalır; `7` (diğer) → `rwx`'in hepsi kapanır (ama dosyada
> zaten `x` yoktu), `rw-`den hepsi çıkar, `---` kalır. Sonuç: `rw-r-----` = `640`.
> Aynı mantık dizinler için `777` üzerinden işler: `umask 027` ile dizin `777-027=750`
> (`rwxr-x---`) olur — burada `x` de dahil olduğu için çıkarma gerçekten "toplamdan
> çıkarma" gibi çalışır çünkü dizinin başlangıcında her üç hak da açıktı.

```bash
umask            # Mevcut değeri gör
umask 077        # Bu oturum için değiştir (çok kısıtlı)
touch test && ls -l test    # Doğrula
```

Kalıcı yapmak: `~/.bashrc` (kullanıcıya özel) veya `/etc/profile` / `/etc/login.defs`
(sistem geneli).

> **Dağıtım farkı — varsayılan umask:**
> - RHEL ailesi: kullanıcılar için `002`, root için `022`
> - Debian/Ubuntu: `022`
> - RHEL'deki `002` "user private group" mantığıyla gelir: her kullanıcının kendi
>   adında bir grubu olduğu için grup yazma izni riskli değildir.

---

## 6. Dosya ve dizin işlemleri (özet)

Detayı Modül 02'de işlendi; buradaki eklemeler:

```bash
# Dizin ağacını görsel gör
tree /etc/ssh              # ayrıca kurulur: dnf/apt install tree
tree -L 2 /var             # 2 seviye derinlik

# Sahiplik
chown ali dosya            # Sahibi değiştir
chown ali:gelistirici dosya  # Sahip ve grup
chgrp gelistirici dosya    # Sadece grup
chown -R ali:ali /home/ali # Özyinelemeli
chown --reference=A B      # B'ye A ile aynı sahipliği ver

# Zaman damgaları (stat ile görülür)
stat dosya
#  Access: son okunma (atime)
#  Modify: içerik son değişimi (mtime)   ← ls -l bunu gösterir
#  Change: metadata son değişimi (ctime) — izin/sahip değişince güncellenir
```

`ctime` doğrudan değiştirilemez — adli analizde bu yüzden önemlidir.

> [!NOTE]
> **Neden üç ayrı zaman damgası var, biri yetmez mi?**
> Bir dosyanın "değişmesi" farklı anlamlara gelebilir ve bu üç ayrımın her biri
> farklı bir soruya cevap verir. **mtime (modify)**: dosyanın **içeriği** ne zaman
> değişti — `ls -l`'nin gösterdiği tarih budur, çünkü genelde "bu dosya en son ne
> zaman düzenlendi" sorusuyla ilgileniriz. **atime (access)**: dosya en son ne zaman
> **okundu** — sadece `cat` etmek bile bunu günceller (bu yüzden performans için
> genelde `noatime` mount seçeneğiyle kapatılır, 09. modülde göreceksin). **ctime
> (change)**: dosyanın **metadata**'sı (izinleri, sahibi, grubu, ya da içeriği) en
> son ne zaman değişti — `chmod` ya da `chown` yaptığında içerik değişmez ama `ctime`
> güncellenir. `ctime`'ın "doğrudan değiştirilemez" olması adli analizde önemlidir:
> mtime'ı `touch -d "2020-01-01" dosya` ile istediğin tarihe ayarlayabilirsin (birisi
> bir dosyayı değiştirip "eskiden beri böyleymiş" gibi göstermeye çalışabilir), ama
> `ctime` her zaman **gerçek** değişiklik anını gösterir — bu değişikliğin ne zaman
> olduğunu gizlemenin standart bir yolu yoktur.

---

## 7. Arşivleme ve sıkıştırma

> [!NOTE]
> **tar ile gzip/xz farkı — bu ayrımı netleştir**
> Bu ikisi sık karıştırılır ama tamamen farklı işler yapar. **Arşivleme**, birden
> fazla dosyayı (klasör yapısıyla, izinleriyle, sahiplikleriyle birlikte) **tek bir
> dosyaya paketlemek**tir — amaç taşınabilirlik, boyut küçültme değil. `tar`
> ("tape archive" — adı, ismini kaset teyplerine yedek almaktan alır) bunu yapar;
> `tar` ile oluşturduğun `.tar` dosyası, içindeki dosyalarla neredeyse aynı toplam
> boyuttadır, sadece hepsi tek dosya haline gelmiştir. **Sıkıştırma** ise verinin
> içindeki tekrar eden örüntüleri matematiksel olarak daha az bitle ifade edip **boyutu
> küçültmek**tir — `gzip`, `bzip2`, `xz` bunu yapar, ama bunlar **tek bir dosyayı**
> sıkıştırır, birden fazla dosyayı bir araya getirmezler. `tar`'ın `z`/`j`/`J`
> bayrakları, aslında `tar` arşivini oluşturduktan hemen sonra otomatik olarak
> ilgili sıkıştırma aracını da çalıştırır — yani `tar -czf` iki işlemi (paketle +
> sıkıştır) tek komutta yapar.

**Kavram ayrımı:** `tar` arşivler (birçok dosyayı tek dosya yapar, sıkıştırmaz).
`gzip`/`bzip2`/`xz` sıkıştırır (tek dosyayı küçültür). `tar` ikisini birleştirebilir.

```bash
# Oluştur
tar -cvf arsiv.tar dizin/           # sadece arşiv
tar -czvf arsiv.tar.gz dizin/       # gzip ile      (hızlı, orta oran)
tar -cjvf arsiv.tar.bz2 dizin/      # bzip2 ile     (yavaş, iyi oran)
tar -cJvf arsiv.tar.xz dizin/       # xz ile        (en yavaş, en iyi oran)

# Aç
tar -xvf arsiv.tar
tar -xzvf arsiv.tar.gz
tar -xvf arsiv.tar.gz               # modern tar tipi otomatik algılar
tar -xzvf arsiv.tar.gz -C /hedef/   # belirli dizine aç

# İçine bakmadan listele  ← AÇMADAN ÖNCE HEP YAP
tar -tvf arsiv.tar.gz

# Tek dosya çıkar
tar -xzvf arsiv.tar.gz yol/icindeki/dosya.txt
```

> [!TIP]
> **gzip / bzip2 / xz arasında nasıl seçim yaparsın?**
> Üçü de aynı işi yapar (sıkıştırma) ama hız/oran dengesi farklıdır — bu bir mühendislik
> tercihi meselesidir. **gzip**: en hızlı, orta sıkıştırma oranı — sık erişilen, hızlı
> açılması gereken log yedeklerinde tercih edilir. **bzip2**: daha yavaş ama daha iyi
> sıkıştırır — özellikle metin ağırlıklı büyük verilerde işe yarar. **xz**: en yavaş
> ama en küçük dosyayı üretir — bir kere sıkıştırıp uzun süre saklayacağın, nadiren
> açacağın arşivler (yıllık yedekler, dağıtım ISO'ları) için idealdir çünkü sıkıştırma
> süresi bir kereliğine ödenir, kazanılan disk alanı kalıcıdır. Kısacası: "hız mı
> önemli, alan mı" sorusuna göre seçersin.

### Bayrakları hatırlama

| Harf | Anlamı |
|---|---|
| `c` | **c**reate — oluştur |
| `x` | e**x**tract — çıkar |
| `t` | **t**est/list — listele |
| `v` | **v**erbose — ne yaptığını yaz |
| `f` | **f**ile — dosya adı gelecek (**hep sonuncu** olmalı) |
| `z` | g**z**ip |
| `j` | b**j**zip2 |
| `J` | **x**z |
| `C` | dizin değiştir (**C**hange dir) |

> ⚠️ `f` bayrağından hemen sonra dosya adı gelmeli. `tar -cfz x.tar.gz dizin/`
> yazarsan tar arşivi "z" adlı dosyaya yazmaya çalışır. Doğrusu `tar -czf`.

**Sahada örnek — yapılandırma yedeği:**
```bash
sudo tar -czvf /root/etc-$(date +%F).tar.gz /etc
# tar: Removing leading `/' from member names   ← normal, mutlak yolu göreliye çevirir
```

> [!NOTE]
> **"Removing leading /" uyarısı neden veriyor, endişelenmeli miyim?**
> Hayır, bu tamamen normal ve **istenen** bir davranıştır. `tar`, mutlak bir yolla
> (`/etc` gibi, başında `/` olan) arşiv oluşturduğunda, bu arşivi başka bir yerde
> (`tar -xzvf` ile) açtığında dosyaların **gerçek sistem konumlarının üzerine
> yazılmasını** önlemek için baştaki `/`'yi kaldırıp yolu göreli hale getirir
> (`etc/ssh/sshd_config` gibi, `/etc/ssh/sshd_config` değil). Böylece arşivi
> `/tmp/test` dizininde açarsan dosyalar `/tmp/test/etc/...` altına gelir, yanlışlıkla
> gerçek `/etc` dizinin üzerine yazılmaz. Arşivi gerçekten sistemin kök dizinine
> geri yüklemek istiyorsan `tar -xzvf arsiv.tar.gz -C /` ile hedefi açıkça belirtirsin.

### Diğer sıkıştırma araçları

```bash
gzip dosya           # dosya.gz oluşur, ORİJİNAL SİLİNİR
gunzip dosya.gz      # geri aç
gzip -k dosya        # orijinali koru
zcat dosya.gz        # açmadan içeriğini oku ← log incelerken çok kullanışlı
zgrep "hata" *.gz    # sıkıştırılmış loglarda ara

zip -r arsiv.zip dizin/    # Windows uyumluluğu için
unzip arsiv.zip
```
> `zip`/`unzip` minimal kurulumlarda **yoktur**, ayrıca kurmak gerekir.

---

## 🧪 Lab

1. `/srv/paylasim` dizini oluştur, `proje` grubuna ver, SGID + sticky bit ata (`chmod 3775`).
   İki farklı kullanıcı ile dosya oluştur, grup sahipliğinin otomatik `proje` olduğunu ve
   birbirlerinin dosyasını silemediklerini doğrula.
2. `umask 077` yap, dosya ve dizin oluştur, izinlerini `ls -l` ile hesabınla karşılaştır.
3. Sistemdeki tüm SUID dosyaları listele. `/usr/bin/passwd` üzerinde `ls -l` yap, `s` bitini gör.
4. `/etc` dizinini `xz` ile sıkıştır. `gzip`, `bzip2`, `xz` üç sürümünün boyut ve
   süresini `time` ile ölç, tabloya dök.
5. Bir dizini `755`, içindeki dosyaları `644` yap — **tek komutla** (`find -exec` veya `chmod -R a+rX`).
6. `/tmp`'in izinlerini `ls -ld /tmp` ile incele, sondaki `t`nin ne olduğunu kendi cümlenle yaz.
7. `stat` ile bir dosyanın 3 zaman damgasını gör. `chmod` yap, tekrar bak — hangisi değişti?

---

## ❓ Kendini test et

**S1.** `chmod 644 /var/www/html` yaptın, site çöktü. Neden?

<details><summary>Cevap</summary>
Dizinden `x` iznini aldın. `x` olmadan dizine girilemez, içindeki dosyalara erişilemez.
Dizinler `755` olmalı. Düzeltme: `chmod 755 /var/www/html`.
</details>

**S2.** SUID biti `/usr/bin/passwd` üzerinde neden var?

<details><summary>Cevap</summary>
`passwd`, sadece root'un yazabildiği `/etc/shadow` dosyasını değiştirmek zorunda.
SUID sayesinde program, çalıştıran kullanıcının değil sahibinin (root) yetkisiyle çalışır.
</details>

**S3.** `umask 027` iken oluşturulan yeni dizinin izni ne olur?

<details><summary>Cevap</summary>
777 − 027 = **750** (`rwxr-x---`). Dosya için: 666 − 027 = 640 (`rw-r-----`).
</details>

**S4.** `tar -tvf yedek.tar.gz` komutunu açmadan önce neden çalıştırırsın?

<details><summary>Cevap</summary>
Arşivin mutlak yol mu (`/etc/...`) göreli yol mu (`etc/...`) içerdiğini görmek için.
Mutlak yollu bir arşivi açarsan gerçek sistem dosyalarının üzerine yazabilir.
Ayrıca "tar bomb" — tek dizin yerine yüzlerce dosyayı bulunduğun dizine saçan arşiv — riski var.
</details>

**S5.** `/proc/meminfo` dosyasının boyutu `ls -l`'de 0 görünüyor ama `cat` ettiğinde içerik var. Nasıl?

<details><summary>Cevap</summary>
`/proc` diskteki gerçek bir dosya sistemi değil, kernel'in sanal arayüzü.
İçerik okunduğu anda kernel tarafından üretilir, önceden var olan bir boyutu yoktur.
</details>

---

## 📋 Hızlı referans

```bash
chmod 755 DIZIN            # rwxr-xr-x — dizin standardı
chmod 644 DOSYA            # rw-r--r-- — dosya standardı
chmod 600 ~/.ssh/id_rsa    # gizli anahtar — başka türlüsü kabul edilmez
chmod -R a+rX /yol         # akıllı özyineleme (dizine x, dosyaya değil)
chmod 2775 DIZIN           # SGID — ekip paylaşım dizini
chmod 1777 DIZIN           # sticky — /tmp benzeri
chown -R user:grup /yol
umask 022                  # sonuç: dosya 644, dizin 755
find / -perm -4000 2>/dev/null   # SUID denetimi
tar -czvf a.tar.gz dizin/  # oluştur
tar -tvf  a.tar.gz         # aç MADAN listele
tar -xzvf a.tar.gz -C /hedef
zcat / zgrep               # sıkıştırılmış log okuma
stat DOSYA                 # inode + 3 zaman damgası
```
