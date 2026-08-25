---
tags:
  - egitim/linux-sistem-yonetimi
tarih: 2026-08-24
konular:
  - Symlink/hardlink derinleştirme (relative path çözünürlüğü, inode bulma)
  - mv iç mekanizması (aynı dosya sistemi vs farklı dosya sistemi)
  - Disk aygıtı vs karakter aygıtı
  - Dosya sistemi oluşturma (mkfs), MBR/GPT
  - FHS dizin yapısı, kütüphane bağımlılıkları (ldd), /proc ve /sys
---
A
# Gün 3 Raporu

Bağlantı: [Linux Sistem Yönetimi Eğitimi](../README.md) · [00 - Eğitim Planı](../00%20-%20Eğitim%20Planı.md) · [Gün 2](Gün%202.md)

## İşlenen Konular

- 2. Gün tekrarı yapıldı
	- inode mantığı
	- Relative path ile symlink
		- Örnek;
		  `/root` içinde `dosya.txt` dosyası oluştur
		  `/tmp` içine `ln -s ../root/dosya.txt dosya2.txt` ile linkle
		  dosyayı `/root` içinden `/etc` altına taşırsam link kırılır mı?
		  `dosya2.txt`'yi `/etc/network` altına taşırsam çalışır mı?

		  Neden;
		  1. Soru için: hedef dosya (`dosya.txt`) taşınıyor. Symlink hâlâ eski yolu (`/root/dosya.txt`) arıyor, orası artık boş → **kırılır.**
		  2. Soru için: symlink'in kendisi (`dosya2.txt`) taşınıyor. Relative hedef (`../root/dosya.txt`) artık **yeni konuma göre** (`/etc/network`) yeniden hesaplanır → bir üst dizine çıkınca `/etc`'ye gelir, orada `root` diye bir şey aramaya başlar, bulamaz → **çalışmaz.**

		  Bu örnekte önemli olan linkin relative `"../"` ile verilmesi:
		  ```
		  ln -s ../root/dosya.txt dosya2.txt   # relative — nereye taşınırsa taşınsın YENİDEN hesaplanır
		  ln -s /root/dosya.txt dosya2.txt     # absolute — sabit tam yol, symlink taşınsa bile değişmez
		  ```

```
dosya2.txt -----------> dosya.txt
    |                        |
inode=432255          inode=665533
    |                        |
   Veri                     Veri
```

Hardlink:
```
dosya4.txt          dosya.txt
    |                    |
    |------------------->|
       (ikisi de aynı)
        inode=665533
             |
            Veri
```

`ln /root/dosya.txt dosya4.txt`

- `dosya4.txt`'nin yetkisi değişirse `dosya.txt`'de de değişir mi?
- Bu iki dosya aynı inode'u kullanıyorsa, ilk orijinal dosyayı nasıl bulurum?
- `dosya.txt`'nin farklı pathlerde bulunan hardlink'lerini nasıl bulursun?

  `ls -i` ile `dosya.txt`'nin inode değerini bulup `find / -inum <inode_değeri>` komutunu kullanarak tüm kök dizin içinde `dosya.txt` ile aynı inode'a sahip hardlink'leri bulabilirsin.

  `ls` kullanmak yerine `stat dosya.txt` ile de inode değeri bulunabilir.
  `find` içinde: `find / -samefile dosya.txt`

Neden hardlink, neden symlink kullanılır?
Dizinler birbirine hardlink ile bağlanamaz — `ln /var /etc` yapamazsın, ama neden?

Sorun/Ödev: Bir dosyaya bağlanan diskin farklı symlink'lerini nasıl bulurum?

`mv` komutu ile taşınan dosyanın hızlı taşınmasının nedeni nedir? Bu komutla birlikte neler değişir?
`vi /etc` komutu ile dizin içinde bulunan dosya ve klasörlerin listelenmesi, `mv` komutu ile bu adreslerin değişimi.

`mv /etc/dosya.txt /var` dediğimizde `/etc` içinden bu dosya ismi silinir ve `/var` altına yazılır. Disk üzerinde ya da veride bir değişiklik olmaz. Fakat `cp` komutu ile yapılan işlemlerde bu geçerli değildir; çünkü `cp` ile yapılan işlemlerde disk üzerinde yeni bir inode kullanılır, `dosya.txt` artık farklı bir inode'a sahip olur.

```
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
sda      8:0    0  1.2G  0 disk
└─sda1   8:1    0  1.2G  0 part
sdb      8:16   0   20G  0 disk
├─sdb1   8:17   0 18.9G  0 part /
├─sdb2   8:18   0    1K  0 part
└─sdb5   8:21   0  1.1G  0 part [SWAP]
sr0     11:0    1 1024M  1 rom
```

`sdb1` içinde `/home/dosya.txt`'yi `sda1` içine atarsam inode ID değişir mi? Değişir. Kanıt:

```
root@debian-egitim:/home/ucp# lsblk
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
sda      8:0    0  1.2G  0 disk
└─sda1   8:1    0  1.2G  0 part
sdb      8:16   0   20G  0 disk
├─sdb1   8:17   0 18.9G  0 part /
├─sdb2   8:18   0    1K  0 part
└─sdb5   8:21   0  1.1G  0 part [SWAP]
sr0     11:0    1 1024M  1 rom
root@debian-egitim:/home/ucp# mount /dev/sda1 /tmp/
root@debian-egitim:/home/ucp# cd /tmp/
root@debian-egitim:/tmp# ls
lost+found
root@debian-egitim:/tmp# cd ../home
root@debian-egitim:/home# touch dosya.txt
root@debian-egitim:/home# nano dosya.txt
root@debian-egitim:/home# stat dosya.txt
 File: dosya.txt
 Size: 25              Blocks: 8          IO Block: 4096   regular file
Device: 8,17    Inode: 261482      Links: 1
Access: (0644/-rw-r--r--)  Uid: (    0/    root)   Gid: (    0/    root)
Access: 2026-08-24 19:57:08.214969171 +0300
Modify: 2026-08-24 19:57:20.156936621 +0300
Change: 2026-08-24 19:57:20.156936621 +0300
Birth: 2026-08-24 19:57:03.632679382 +0300
root@debian-egitim:/home# mv dosya.txt /tmp/
root@debian-egitim:/home# cd ../tmp/
root@debian-egitim:/tmp# ls
dosya.txt  lost+found
root@debian-egitim:/tmp# stat dosya.txt
 File: dosya.txt
 Size: 25              Blocks: 8          IO Block: 4096   regular file
Device: 8,1     Inode: 13          Links: 1
Access: (0644/-rw-r--r--)  Uid: (    0/    root)   Gid: (    0/    root)
Access: 2026-08-24 19:57:08.214969171 +0300
Modify: 2026-08-24 19:57:20.156936621 +0300
Change: 2026-08-24 19:57:47.090395381 +0300
Birth: 2026-08-24 19:57:47.090395381 +0300
root@debian-egitim:/tmp#
```

---

Dosya sistemi:
`mkfs /dev/sdb1`

Dosya sistemleri farkları, avantaj ve dezavantajları.

`parted` komut kullanımı araştırılacak.
`fsck` komutu kullanımı araştırılacak.

Disk aygıtı ve karakter aygıtı nedir, farkları nedir?

Disk bölmek için:
MBR örneği yapıldı.
GPT örneği yapıldı.

---

Dizinler:
Tüm dizinler ne amaçla kullanılır, neyi barındırır.

Dizinler binary çalışmak için hangi kütüphanelere ihtiyaç duyuyor, bunu nasıl bulurum?
Uygulamanın kullandığı kütüphaneyi herhangi bir dizine kopyalayıp, kopyalanmış dizin içinde o uygulamayı kopyalanan kütüphane ile çalıştır.

`/proc` ve `/sys` dizinleri içinde gezinme.

## Genişletilmiş Anlatım (Öğrenme İçin Ek Açıklamalar)

> [!WARNING]
> **Yukarıda bulunan kısa notların AI ile genişletilmiş halidir. Bilgiler sadece o gün işlenen konular ile sınırlandırılmış olup referans olması için eklenmiştir. Lütfen bu genişletilmiş metni kendi araştırmalarınıza bir ön bilgi olarak kullanın ve testlerinizi sadece burayı kullanarak değil, farklı kaynaklardan da yararlanarak yapın.**

### Relative symlink çözünürlüğü — tek altın kural

Kafa karışıklığının kaynağı genelde şu: "relative yol neye göre hesaplanır — benim şu an bulunduğum dizine mi, yoksa symlink'in kendi konumuna mı?" Cevap kesin: **her zaman symlink dosyasının kendisinin bulunduğu dizine göre.** `cd` ile nerede olduğun, hangi dizinden o symlink'e eriştiğin hiç önemli değil.

Bunu iki farklı olayla ayırt etmek gerekiyor — notundaki 1. ve 2. soru tam olarak bu ikisini test ediyor:

| Olay | Ne olur | Neden |
|---|---|---|
| **Hedef dosya taşınır/silinir** (`dosya.txt` `/root`'tan `/etc`'ye taşınır) | Link **her zaman kırılır** (relative/absolute fark etmez) | Symlink'in içinde yazan yol artık gerçek dünyada karşılık bulmuyor |
| **Symlink'in kendisi taşınır** (`dosya2.txt` `/tmp`'ten `/etc/network`'e taşınır) | **Relative** ise genelde kırılır, **absolute** ise etkilenmez | Relative yol yeni konuma göre yeniden hesaplanır; absolute yol zaten konumdan bağımsız sabit bir string'dir |

Adım adım 2. senaryo: `dosya2.txt` içinde saklanan metin **değişmez**, hep `../root/dosya.txt` yazar (bunu `readlink dosya2.txt` ile görebilirsin). Ama bu metin bir "hesaplama talimatı" gibi çalışır — her erişimde, **o an symlink'in durduğu dizinden başlayarak** yeniden yorumlanır. `/etc/network` içine taşındığında: `..` → `/etc`, sonra `root/dosya.txt` → `/etc/root/dosya.txt`. Böyle bir yol yoktur, dolayısıyla kırılır.

```bash
readlink dosya2.txt        # symlink'in İÇİNDE yazan ham hedefi gösterir (değişmemiştir)
readlink -f dosya2.txt      # o an nereye ÇÖZÜLDÜĞÜNÜ (varsa gerçek dosyayı) gösterir
```

> [!TIP]
> **Pratik kural: Bir symlink'i sık taşımayacağın ya da hedefiyle "birlikte hareket etmesini" istediğin kısayollarda relative kullan (örn. bir proje klasörü içindeki iç referanslar — klasörü başka yere kopyaladığında da çalışmaya devam eder). Sabit, sistem geneli bir hedefe işaret ediyorsa (örn. `/usr/bin/python -> /usr/bin/python3.12`) absolute daha güvenlidir.**

### Hardlink derinleştirme — bir dosyanın tüm isimlerini bulmak

`ls -al` çıktısındaki izin bloğunun hemen sağındaki sayı (Gün 1'de gördüğün "link sayısı") tam olarak şunu söyler: **bu inode'a kaç farklı dizin girdisi (isim) işaret ediyor.** Hardlink oluşturduğunda bu sayı artar; bir ismi sildiğinde azalır. Sayı `0`'a düştüğünde (son isim de silindiğinde) kernel veriyi gerçekten diskten serbest bırakır.

Bu yüzden `dosya4.txt`'nin izinlerini değiştirirsen `dosya.txt`'nin izinleri de **aynı anda** değişir — çünkü izin bilgisi dosya adında değil, ikisinin de paylaştığı **tek bir inode**'da tutulur. İki isim değil, tek dosya, iki etiket.

**Orijinali bulmak / tüm hardlink'leri bulmak:**
```bash
ls -i dosya.txt                     # inode numarasını öğren
stat dosya.txt                      # aynı bilgiyi + tüm meta veriyi göster (Links: alanı kaç isim olduğunu söyler)

find / -inum 665533 2>/dev/null     # bu inode'a işaret eden TÜM isimleri, tüm dosya sisteminde ara
find / -samefile dosya.txt 2>/dev/null   # aynı şeyi, inode numarasını elle yazmadan yap
```
`-inum` ile `-samefile` aynı işi yapar, `-samefile` daha pratiktir çünkü inode numarasını ezbere bilmene gerek kalmaz. **"İlk orijinal" diye bir kavram yoktur** — hardlink'ler arasında hiyerarşi yok, hepsi eşdeğer isim. `find` sonucu sana birden fazla yol listelerse, hangisinin "asıl" olduğunu söyleyemezsin çünkü hepsi aynı veriye eşit derecede sahiptir.

**Neden dizinler hardlink'lenemez?**
İki sebep var:
1. **Sonsuz döngü riski:** Eğer `ln /var /etc` gibi bir şey mümkün olsaydı, bir dizin kendi alt dizinine (ya da bir üst dizine) hardlink'lenebilir, bu da dizin ağacında **kapanmayan bir döngü** yaratabilirdi (`/a/b/a/b/a/b/...` sonsuza kadar). `find`, `du`, yedekleme araçları gibi ağacı gezen her program böyle bir yapıda sonsuz döngüye girer.
2. **Bütünlük (`fsck`) karmaşıklığı:** Dosya sistemi bütünlük denetleyicisi (`fsck`), her dosya sisteminin bir **ağaç** (her düğümün tek bir ebeveyni olduğu yapı) olduğunu varsayarak çalışır. Dizinler çoklu hardlink alabilseydi bu bir **graf**'a dönüşürdü, tutarlılık denetimi ve kurtarma algoritmaları çok daha karmaşık hâle gelirdi.

Bu yüzden dizinler arası "kısayol" ihtiyacı **symlink** ile çözülür — symlink döngü oluştursa bile (`ln -s a a`), kernel sembolik linkleri belli bir derinlikten (`ELOOP`) sonra takip etmeyi reddeder, güvenlidir.

### `mv`'nin hız sırrı — neden bazen anlık, bazen yavaş?

Notundaki gerçek `stat` çıktısı bunu kanıtla gösteriyor, üzerinden gidelim:

- **Aynı dosya sistemi içinde** (`/home` içindeyken `mv dosya.txt oradaki-baska-isim.txt`, ikisi de aynı bölümde): `mv`, verinin **tek bir baytını bile diskte hareket ettirmez.** Sadece dizin girdisindeki ismi (ve gerekirse hangi dizine ait olduğunu) günceller — bu, `rename()` denen tek bir sistem çağrısıyla, dosya kaç GB olursa olsun **O(1)** sürede (anlık) biter. İnode numarası **aynı kalır**, `Birth` (oluşturulma) zamanı **değişmez**.
- **Farklı dosya sistemleri arasında** (senin örneğinde `/home` → `Device: 8,17` yani `sdb1`, `/tmp` → `Device: 8,1` yani `sda1` — iki ayrı bölüm): `rename()` çağrısı burada **işe yaramaz**, çünkü hedef inode tablosu tamamen farklı bir dosya sistemine ait. Kernel bu durumda gerçekte şunu yapar: hedefte **yeni bir inode ayır**, kaynaktaki veriyi oku, hedefe yaz (yani içten içe bir `cp` gibi davranır), başarılıysa kaynaktaki eski ismi/inode'u sil. Bu yüzden büyük bir dosyada bu **yavaştır** ve dosya boyutuyla orantılıdır.

Senin çıktında tam bunu görüyoruz: `Inode: 261482` (sdb1, cihaz `8,17`) → `Inode: 13` (sda1, cihaz `8,1`) — **inode değişti**, çünkü iki farklı dosya sistemi arasında taşındı. `Birth` zamanı da değişti (`19:57:03` → `19:57:47`) çünkü hedefte fiziksel olarak **yeni bir dosya** (yeni inode) yaratıldı; bu artık "taşınan" değil, "kopyalanıp eskisi silinen" bir dosyadır — `cp` ile pratik olarak aynı maliyete sahiptir, tek farkı `mv`'nin bunu senin için otomatik yapıp kaynağı silmesidir.

> [!TIP]
> **Pratik sonuç: Aynı diskte devasa bir dosyayı taşımak "anlık" görünür (spinner beklemezsin); farklı diske/bölüme taşımak dosya boyutuna göre zaman alır — bu bir hata değil, mekanizmanın doğal sonucudur. `df -h` ile `mv` etmek istediğin iki yolun **aynı `Filesystem` sütununda** olup olmadığına bakarsan hangi durumda olduğunu önceden tahmin edebilirsin.**

### Disk aygıtı (block device) ve karakter aygıtı (character device)

Linux'ta donanım, `/dev` altında dosya gibi görünen özel dosyalarla temsil edilir. `ls -l /dev` çıktısındaki ilk karakter bunu ayırt eder:

```bash
ls -l /dev/sda /dev/tty1
brw-rw---- 1 root disk 8, 0 ... /dev/sda     # b = block (blok) aygıtı
crw--w---- 1 root tty  4, 1 ... /dev/tty1    # c = character (karakter) aygıtı
```

- **Blok aygıtı (`b`):** Veriye **sabit boyutlu bloklar (parçalar)** hâlinde, **rastgele erişimle** (herhangi bir noktadan okuma/yazma yapılabilir) ulaşılır. Diskler (`/dev/sda`), SSD'ler, USB bellekler bu kategoridedir — işletim sistemi bunları arabelleğe (buffer/cache) alarak, verimli okuma-yazma için optimize eder. `mount`/`mkfs`/`fdisk` hep blok aygıtlar üzerinde çalışır.
- **Karakter aygıtı (`c`):** Veri, **byte byte, sıralı bir akış** olarak okunur/yazılır — geri sarma ya da "5. bayta atla" gibi rastgele erişim genelde yoktur. Klavyeler, seri portlar, terminaller (`/dev/tty*`), `/dev/null`, `/dev/zero`, `/dev/random` bu kategoridedir.

**Neden önemli:** Bir dosya sistemi (ext4/xfs) sadece blok aygıtların üzerine kurulabilir — bu yüzden `mkfs.ext4 /dev/tty1` anlamsızdır ama `mkfs.ext4 /dev/sdb1` anlamlıdır. `MAJ:MIN` sütunu (örn. `8,0`), kernel'in bu aygıtı hangi sürücüyle (major) ve hangi spesifik birim olarak (minor) tanıdığını gösterir.

### Dosya sistemi oluşturma — `mkfs`, MBR ve GPT

`mkfs` (make filesystem), boş/ham bir bölümün üzerine bir dosya sistemi **iskeletini** (inode tablosu, boş blok haritası, kök dizin yapısı vb.) yazar — Gün 2'de gördüğün ext4/XFS/Btrfs farkları burada devreye girer, hangisini seçtiğine göre komut değişir:

```bash
sudo mkfs.ext4 /dev/sdb1
sudo mkfs.xfs /dev/sdb1
```

> [!WARNING]
> **`mkfs`, hedef bölümün **tüm içeriğini geri dönüşü olmayan şekilde siler.** Doğru aygıt adını (`lsblk` ile teyit ederek) verdiğinden emin ol.**

**MBR vs GPT — disk bölümleme tablosu farkı:**

| | MBR (Master Boot Record) | GPT (GUID Partition Table) |
|---|---|---|
| Yaş / uyumluluk | Eski standart, BIOS sistemlerle uyumlu | Modern standart, UEFI ile birlikte gelişti |
| Maksimum disk boyutu | ~2 TB (32-bit sektör adresleme sınırı) | Pratikte sınırsıza yakın (64-bit adresleme) |
| Birincil bölüm sayısı | En fazla 4 (ya da 3 birincil + 1 "extended" içinde mantıksal bölümler) | 128'e kadar (pratik sınır yok denecek kadar çok) |
| Yedeklilik | Bölüm tablosu diskin başında **tek kopya** — bozulursa disk okunamaz hale gelebilir | Tablo hem başta hem sonda **yedekli** tutulur, checksum ile bütünlük doğrulanır |

`fdisk`, hem MBR hem GPT ile çalışabilir (bölüm tablosu tipini interaktif menüde `g` ile GPT'ye çevirebilirsin); `parted` ise komut satırından/script'lenebilir şekilde ikisini de yönetir ve büyük disklerde (>2TB) GPT gerektiğinde daha rahat kullanılır. `fsck` (file system check) ise bölümlemeyle değil, **var olan** bir dosya sisteminin iç tutarlılığını (bozuk inode, yetim blok, çapraz bağlı dosyalar vb.) denetler/onarır — güvenli çalışması için ilgili bölümün **mount edilmemiş** olması gerekir (kök bölüm gibi mount'suz çalıştırılamayan durumlarda kurtarma/canlı ortamından çalıştırılır).

```bash
sudo fsck /dev/sdb1        # bölüm mount'lu DEĞİLKEN çalıştır
sudo fsck -f /dev/sdb1     # temiz görünse bile ZORLA tam denetim yap
```

### Dizin yapısı (FHS) — hangi dizin ne işe yarar

Linux'ta kök dizinin (`/`) altındaki klasör isimleri rastgele değil; **Filesystem Hierarchy Standard (FHS)** adlı bir kurala göre standartlaşmıştır — bu yüzden hangi dağıtımı kullanırsan kullan, `/etc` hep yapılandırma, `/var` hep değişken veri anlamına gelir:

| Dizin | Ne barındırır |
|---|---|
| `/bin`, `/usr/bin` | Temel/kullanıcı çalıştırılabilir komutları (`ls`, `cat`, `bash`...) |
| `/sbin`, `/usr/sbin` | Sistem yönetimi komutları (genelde root gerektirir: `fdisk`, `mkfs`...) |
| `/etc` | Sistem geneli **yapılandırma dosyaları** (`/etc/fstab`, `/etc/passwd`...) — burada çalıştırılabilir dosya olmaz, sadece config |
| `/var` | Sık **değişen** veri: loglar (`/var/log`), önbellek, mail kuyrukları |
| `/home` | Kullanıcıların kişisel dizinleri |
| `/root` | root kullanıcısının ev dizini (`/home` altında değil, ayrıcalıklıdır) |
| `/tmp` | Geçici dosyalar — genelde yeniden başlatınca temizlenir |
| `/lib`, `/usr/lib` | Programların ihtiyaç duyduğu paylaşımlı kütüphaneler (`.so` dosyaları) |
| `/dev` | Donanımı temsil eden aygıt dosyaları (yukarıda gördüğün `/dev/sda` gibi) |
| `/proc`, `/sys` | Gerçek disk verisi DEĞİL — kernel'in çalışma zamanı bilgisini dosya gibi sunduğu **sanal** dosya sistemleri (aşağıda ayrı anlatıyorum) |
| `/mnt`, `/media` | Manuel / çıkarılabilir aygıtların geçici mount noktaları |

### Bir programın ihtiyaç duyduğu kütüphaneleri bulmak — `ldd`

Çoğu Linux programı **dinamik olarak bağlanır (dynamic linking):** binary'nin içinde tüm kod yoktur, çalışırken ortak/paylaşımlı kütüphaneleri (`.so` — "shared object") diskten yükler. Bir binary'nin hangi kütüphanelere ihtiyaç duyduğunu görmek için:

```bash
ldd /bin/ls
#   linux-vdso.so.1 (...)
#   libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x...)
#   ...
```
Her satır, "bu isimde bir kütüphane lazım, sistemde şu tam yolda bulundu" demektir. Eğer bir satırda `=> not found` görürsen, o program çalışmayacaktır — kayıp kütüphane hatası (`error while loading shared libraries`) tam olarak budur.

**Notundaki deney** ("kütüphaneyi başka bir dizine kopyalayıp, kopyalanan kütüphaneyle çalıştır") tam olarak bunu test etmenin yoludur: bir programı, sistemdeki normal kütüphane yerine **kendi belirlediğin** bir kopyayı kullanmaya zorlayabilirsin:
```bash
LD_LIBRARY_PATH=/senin/kopya/dizinin ./program
```
`LD_LIBRARY_PATH`, dinamik bağlayıcıya "önce buraya bak" der (Gün 1'de gördüğün tek-seferlik `VAR=deger komut` mantığıyla aynı — sadece o çalıştırma için geçerli, kalıcı değil). Bu teknik hem hata ayıklamada (hangi kütüphane sürümü kullanılıyor?) hem de güvenlik testlerinde (kütüphane enjeksiyonu / farklı sürüm izolasyonu) kullanılır.

### `/proc` ve `/sys` — diskte olmayan dosyalar

Bu iki dizin, `ls -l` ile bakınca sıradan dosya/dizin gibi görünür ama **diskte hiçbir karşılıkları yoktur** — tamamen **kernel'in bellekte tuttuğu bilgiyi, dosya arayüzü üzerinden** sunan sanal dosya sistemleridir (`procfs`, `sysfs`). Bir dosyayı "okumak", aslında o an kernel'e "bu bilgiyi bana ver" demektir; dosya boyutları genelde `0` görünür çünkü içerik önceden diskte durmaz, **istendiğinde üretilir.**

```bash
cat /proc/cpuinfo        # CPU bilgisi (çekirdek sayısı, model...)
cat /proc/meminfo        # anlık RAM kullanımı
ls /proc/                # çalışan her sürecin PID'si kadar sayısal dizin görürsün
cat /proc/1/status       # PID 1'in (init/systemd) durumu
cat /proc/sys/kernel/hostname   # bazı kernel parametreleri buradan hem OKUNUR hem YAZILIR

ls /sys/class/net/        # sistemdeki ağ arayüzlerinin listesi
cat /sys/class/thermal/thermal_zone0/temp   # donanım sıcaklık sensörü (varsa)
```

**Fark:** `/proc` daha çok **süreç (process) ve genel kernel durumu** içindir (adı da buradan gelir); `/sys` ise daha yapılandırılmış biçimde **aygıt/sürücü (device/driver)** modelini dışa vurur — `udev` gibi araçlar aygıt olaylarını (USB takıldı/çıkarıldı) `/sys` üzerinden takip eder. İkisi de root olmadan çoğunlukla **okunabilir**, bazı dosyalara yazmak (örn. `/proc/sys/...` altındaki kernel parametreleri) canlı sistemin davranışını değiştirebileceğinden dikkat ister.

## Notlar

- Bugünün ana teması: Gün 2'nin inode/link konusunun **derinleştirilmesi** (relative symlink çözünürlüğü, hardlink bulma), `mv`'nin gerçek maliyetinin **dosya sistemi sınırına bağlı** olduğunun kanıtlanması, ve disk yönetiminden **dizin yapısı/aygıt modeline** geçiş (block vs character device, FHS, `/proc`/`/sys`).
- En kritik pratik çıkarım: bir `mv` işleminin "anlık" mı "yavaş" mı olacağını önceden tahmin etmek istiyorsan, kaynak ve hedefin **aynı `df -h` `Filesystem` sütununda** olup olmadığına bak.
- `/proc` ve `/sys`'in "gerçek dosya değil" olması ilk başta kafa karıştırıcı gelebilir — bunları normal dosya gibi `cat`/`ls` ile kullanabilirsin ama arkasında disk yok, kernel'in canlı durumu var.

## Komutlar / Örnekler

```bash
# symlink çözünürlüğü
readlink dosya2.txt          # symlink'in içindeki ham hedef
readlink -f dosya2.txt        # o an çözüldüğü gerçek yol

# hardlink bulma
ls -i dosya.txt
find / -samefile dosya.txt 2>/dev/null

# mv iç mekanizması karşılaştırması
df -h /home /tmp             # aynı Filesystem mi, farklı mı önceden kontrol et
stat dosya.txt                # taşımadan önce inode/Device'ı not al
mv dosya.txt /baska/yer/
stat /baska/yer/dosya.txt     # inode/Device değişti mi karşılaştır

# aygıt tipi
ls -l /dev/sda /dev/tty1      # ilk karakter b (block) mü c (character) mı

# dosya sistemi / bölümleme
sudo mkfs.ext4 /dev/sdb1
sudo fsck /dev/sdb1           # sadece unmount iken

# kütüphane bağımlılıkları
ldd /bin/ls
LD_LIBRARY_PATH=/ozel/dizin ./program

# /proc ve /sys keşfi
cat /proc/cpuinfo
cat /proc/meminfo
ls /sys/class/net/
```

## Sorular / Takip Edilecekler

- [ ] `parted` komutunun `fdisk`'e göre tam kullanım farkları (özellikle script'lenebilir mod, `parted -s`).
- [ ] `fsck`'in mount'lu bir bölümde neden çalıştırılmaması gerektiği (canlı tutarsızlık riski) — eğitmenle teyit edilecek.
- [ ] Bir dosyaya bağlanan tüm symlink'leri (hardlink değil, symlink) sistem genelinde bulmanın yolu — `find / -lname 'dosya.txt'` veya `find / -xtype l -lname '*dosya.txt*'` araştırılacak.
