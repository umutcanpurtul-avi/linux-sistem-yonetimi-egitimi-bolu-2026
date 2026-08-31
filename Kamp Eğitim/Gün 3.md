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

# Gün 3 Raporu

Bağlantı: [Linux Sistem Yönetimi Eğitimi](../README.md) · [00 - Eğitim Planı](../00%20-%20Eğitim%20Planı.md) · [Gün 2](Gün%202.md) · [Gün 4](Gün%204.md)

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

**Kafa karışıklığının kaynağı:** "relative yol neye göre hesaplanır — benim şu an bulunduğum dizine mi, yoksa symlink'in kendi konumuna mı?" Cevap kesin: **her zaman symlink dosyasının kendisinin bulunduğu dizine göre.** `cd` ile nerede olduğun, hangi dizinden eriştiğin hiç önemli değil.

**Mekanizma — neden kesin?** Bir yolu (`/tmp/dosya2.txt`) açtığında kernel bunu tek seferde çözmez; **bileşen bileşen, soldan sağa** yürür (Gün 2'de gördüğün path resolution / `namei`). Yürüyüş sırasında bir isim bir **symlink inode'una** işaret ediyorsa, kernel o symlink'in içeriğini (zaten sadece bir hedef yol string'idir) **yürüyüşün ortasına ekler** ve **symlink'in bulunduğu dizinden** devam eder. `man 7 path_resolution` bunu açıkça der: symlink çözülürken başlangıç noktası "the current lookup directory" — yani o an symlink'in durduğu dizin, senin `cd`'in değil. `../root/dosya.txt` gibi bir hedef görüldüğünde bu ekleme `/tmp` noktasında yapılır. "Kural" değil, algoritmanın doğrudan sonucu.

**5N1K çerçevesinde:**
- **Ne:** relative symlink, içinde `/` ile başlamayan bir hedef string tutan symlink'tir; bu string her erişimde yeniden yorumlanır.
- **Nasıl:** path resolution, symlink'in bulunduğu dizini başlangıç alarak string'i çözer.
- **Ne zaman:** her açılışta yeniden — symlink taşındıysa yeni konuma göre.
- **Neden bu tasarım:** relative symlink "hedefiyle birlikte hareket etsin" istenen durumlar için (bir proje klasörünü kopyalarsan iç referanslar hâlâ çalışır); absolute symlink "sabit sistem yolu" için.
- **Kim:** kernel, her `open()`/`stat()` sırasında.

**Notundaki iki senaryo:**

| Olay | Ne olur | Neden |
|---|---|---|
| **Hedef dosya taşınır/silinir** (`dosya.txt` `/root`'tan `/etc`'ye) | Link **her zaman kırılır** (relative/absolute fark etmez) | Symlink'in içindeki yol artık gerçek dünyada karşılık bulmuyor |
| **Symlink'in kendisi taşınır** (`dosya2.txt` `/tmp`'ten `/etc/network`'e) | **Relative** ise genelde kırılır, **absolute** ise etkilenmez | Relative yol yeni konuma göre yeniden hesaplanır; absolute zaten konumdan bağımsız sabit string |

Adım adım 2. senaryo: `dosya2.txt` içindeki string **değişmez**, hep `../root/dosya.txt` (bunu `readlink dosya2.txt` ile görürsün). `/etc/network` içine taşındığında: `..` → `/etc`, sonra `root/dosya.txt` → `/etc/root/dosya.txt`. Böyle bir yol yok → kırılır.

```bash
readlink dosya2.txt        # symlink'in İÇİNDE yazan ham hedef (değişmemiştir)
readlink -f dosya2.txt      # o an nereye ÇÖZÜLDÜĞÜNÜ (varsa gerçek dosyayı) gösterir
```

> [!TIP]
> **Pratik kural: bir symlink'i sık taşımayacağın ya da hedefiyle "birlikte hareket etmesini" istediğin kısayollarda relative; sabit sistem geneli bir hedefe işaret ediyorsa (örn. `/usr/bin/python -> /usr/bin/python3.13`) absolute daha güvenlidir.**

### Hardlink derinleştirme — bir dosyanın tüm isimlerini bulmak

`ls -al` çıktısındaki izin bloğunun hemen sağındaki sayı (Gün 1/Gün 2'deki "link sayısı", inode'daki `st_nlink`) şunu söyler: **bu inode'a kaç farklı dizin girdisi (isim) işaret ediyor.** Hardlink oluşturunca artar, isim silince azalır; `0`'a düşünce (ve açık fd kalmayınca) kernel veriyi diskten serbest bırakır.

Bu yüzden `dosya4.txt`'nin izinlerini değiştirirsen `dosya.txt`'ninkiler de **aynı anda** değişir — izin bilgisi dosya adında değil, ikisinin de paylaştığı **tek inode**'da.

**Orijinali / tüm hardlink'leri bulmak:**
```bash
ls -i dosya.txt                     # inode numarasını öğren
stat dosya.txt                      # + tüm meta veri (Links: alanı kaç isim var)
find / -inum 665533 2>/dev/null     # bu inode'a işaret eden TÜM isimleri tüm dosya sisteminde ara
find / -samefile dosya.txt 2>/dev/null   # aynı şey, inode numarasını elle yazmadan
```
`-inum` ve `-samefile` aynı işi yapar; `-samefile` daha pratik. **"İlk orijinal" diye bir kavram yoktur** — hardlink'ler arası hiyerarşi yok, hepsi eşdeğer isim.

> [!WARNING]
> **`find / -inum` **inode numarasını her dosya sisteminde ayrı ayrı** anlamlı sayar — farklı bir bölümde aynı numaralı, tamamen ilgisiz bir dosya çıkabilir. `-samefile` bu tuzağa düşmez (hem cihaz hem inode'u karşılaştırır); mümkünse onu kullan.**

**Neden dizinler hardlink'lenemez? (`man 2 link`: `EPERM`, "oldpath is a directory")**
1. **Sonsuz döngü riski:** `ln /var /etc` mümkün olsaydı, bir dizin kendi altına/üstüne hardlink'lenebilir, ağaçta kapanmayan döngü oluşabilirdi (`/a/b/a/b/...`). `find`, `du`, yedekleme araçları sonsuz döngüye girerdi.
2. **`fsck` / bütünlük karmaşıklığı:** dosya sistemi bir **ağaç** (her düğümün tek ebeveyni) varsayılarak tasarlandı; dizinler çoklu hardlink alsaydı bu bir **graf** olur, tutarlılık denetimi ve kurtarma çok karmaşıklaşırdı. `..` de belirsizleşirdi (hangi ebeveyn?).

Dizinler arası kısayol ihtiyacı **symlink** ile çözülür — symlink döngü yapsa bile kernel belli bir derinlikten (`ELOOP`, 40 seviye) sonra takip etmeyi reddeder.

**`ln` çalıştırınca kernel'in içinde ne oluyor?**
Bir dizinin "içeriği" `(isim, inode_numarası)` çiftlerinden oluşan bir tablodur (*dizin girdisi / dirent*). `ln dosya.txt dosya4.txt`:
1. `dosya.txt`'nin inode'unu bulur (örn. `665533`),
2. bulunduğun dizine yeni bir `("dosya4.txt", 665533)` satırı ekler — **hiçbir veri kopyalanmaz**,
3. `665533` inode'unun `st_nlink`'ini bir artırır.

`rm dosya.txt`: satır silinir, `st_nlink` bir azalır — **veri bloklarına dokunulmaz**. Kernel veriyi ancak `st_nlink == 0` **VE** o inode'u açık tutan hiçbir süreç kalmadığında serbest bırakır. Sonuç: bir dosyayı `rm` ile silsen bile onu açık tutan bir program varsa disk alanı **hemen boşalmaz** — `lsof | grep deleted` ile "silinmiş ama açık" dosyaları görürsün; "disk doldu ama `du` boş gösteriyor" bulmacasının klasik nedeni (Gün 4'te bu doğrudan bir kurtarma senaryosuna dönüşüyor: [Gün 4#mp3 çalarken silinen dosya — "hayalet dosya" senaryosu ve kurtarma yöntemi](Gün%204.md#mp3-çalarken-silinen-dosya-hayalet-dosya-senaryosu-ve-kurtarma-yöntemi)).

### `mv`'nin hız sırrı — neden bazen anlık, bazen yavaş?

**Mekanizma (`man 2 rename`):**
- **Aynı dosya sistemi içinde** `mv`, verinin **tek baytını bile hareket ettirmez.** Sadece dizin girdisindeki ismi/konumu günceller — `rename()` sistem çağrısıyla, dosya kaç GB olursa olsun **O(1)** (anlık). İnode numarası **aynı kalır**, `Birth` (oluşturulma) zamanı **değişmez**.
- **Farklı dosya sistemleri arasında** `rename()` **çalışmaz** (`EXDEV` — "not on the same mounted filesystem"). `mv` bu durumda içten içe **kopyala-sonra-sil** yapar: hedefte yeni inode ayır, veriyi oku-yaz, başarılıysa kaynağı sil. Büyük dosyada **yavaştır** ve boyutla orantılıdır.

**Notundaki `stat` çıktısı bunu kanıtlıyor:** `/home` → `Device: 8,17` (sdb1), `/tmp` → `Device: 8,1` (sda1) — iki ayrı bölüm. `Inode: 261482` → `Inode: 13` (**değişti**), `Birth` de değişti (`19:57:03` → `19:57:47`). Yani bu "taşınan" değil, "kopyalanıp eskisi silinen" bir dosya — `cp` ile aynı maliyet, tek farkı `mv`'nin kaynağı senin için silmesi.

**5N1K:**
- **Ne:** `mv`, bir dosya adını başka bir konuma taşıyan işlem.
- **Nasıl:** aynı FS'te `rename()` (metadata); farklı FS'te kopyala+sil.
- **Ne zaman fark eder:** hedef ve kaynak `df -h`'de aynı `Filesystem` sütununda mı? Aynıysa anlık, farklıysa boyuta bağlı.
- **Neden `rename()` özellikle önemli — sadece hız değil, güvenlik de:**
  Aynı FS'te `rename()` **atomik**tir — `man 2 rename`: *"If newpath already exists, it will be atomically replaced, so that there is no point at which another process attempting to access newpath will find it missing."* Ya tamamen olur ya hiç olmaz; "yarı tamamlanmış" ara hâl yok (journaled FS'te bu, işlemin journal'a tek kayıt olarak yazılmasıyla garanti — elektrik kesilse bile disk ya eski ya yeni hâlde, asla bozuk ortada değil). Bu yüzden sunucu yazılımlarında (config güncelleme, log rotasyonu, DB checkpoint) klasik kalıp: **önce geçici dosyaya tam içerikle yaz, sonra `mv gecici.tmp hedef.conf` ile aynı dizin içinde adını değiştir.** Okuyan başka süreç asla "yarı yazılmış" hâl görmez. Çalışması için taşımanın **aynı dosya sisteminde** olması şart — farklı diske `mv` atomik değildir.
- **Kim:** senin sürecin; hedef dizinde yazma izni gerekir.

> [!TIP]
> **`df -h ./ hedef/` ile iki yolun **aynı `Filesystem` sütununda** olup olmadığına bakarsan `mv`'nin anlık mı yavaş mı olacağını önceden tahmin edersin.**

### Disk aygıtı (block device) ve karakter aygıtı (character device)

Linux'ta donanım, `/dev` altında dosya gibi görünen özel dosyalarla temsil edilir. `ls -l /dev` çıktısındaki ilk karakter ayırt eder:

```bash
ls -l /dev/sda /dev/tty1
brw-rw---- 1 root disk 8, 0 ... /dev/sda     # b = block (blok) aygıtı
crw--w---- 1 root tty  4, 1 ... /dev/tty1    # c = character (karakter) aygıtı
```

- **Blok aygıtı (`b`):** veriye **sabit boyutlu bloklar** hâlinde, **rastgele erişimle** ulaşılır (herhangi bir noktadan oku/yaz). Diskler, SSD'ler, USB bellekler. Kernel bunları **buffer/page cache** üzerinden verimli erişim için optimize eder. `mount`/`mkfs`/`fdisk` hep blok aygıtlar üzerinde çalışır.
- **Karakter aygıtı (`c`):** veri **byte byte, sıralı akış** olarak okunur/yazılır — "5. bayta atla" genelde yoktur. Klavyeler, seri portlar, terminaller (`/dev/tty*`), `/dev/null`, `/dev/zero`, `/dev/random`.

**Neden önemli:** bir dosya sistemi (ext4/xfs) sadece **blok aygıtların** üzerine kurulabilir — `mkfs.ext4 /dev/tty1` anlamsız, `mkfs.ext4 /dev/sdb1` anlamlı. `MAJ:MIN` (örn. `8,0`), kernel'in bu aygıtı hangi sürücüyle (major) ve hangi spesifik birim olarak (minor) tanıdığını gösterir.

**`/dev/sda`'yı `cat` ya da `mount` edince kernel'in içinde ne oluyor? (mekanizma)**
`/dev` altındaki dosyalar normal dosyalar gibi diskte veri bloklarına sahip **değildir** — her biri sadece **major + minor** numara taşır. Kernel açılışta her sürücüyü bir major numarayla kaydeder (`8` → SCSI/SATA disk, `4` → terminal) ve bu kaydı, sürücünün "okuma isteği gelince ne yapacağını" tanımlayan fonksiyon tablosuyla (`file_operations`) ilişkilendirir. `/dev/sda`'yı açtığında VFS (Virtual File System — tüm dosya erişimlerini yönlendiren ortak katman) bunun bir **aygıt düğümü** olduğunu görür, `MAJ:MIN`'e bakıp doğru sürücünün fonksiyonuna **doğrudan atlar** — yani `/dev/sda`'yı okumak = disk sürücüsünün "şu sektörden şu kadar oku" fonksiyonunu çağırmak; ext4/xfs bu seviyede devrede bile değil. `mount` ise bu ham blok erişiminin **üstüne** bir dosya sistemi sürücüsü yerleştirir. Katmanlar: **VFS → dosya sistemi sürücüsü (ext4/xfs) → blok aygıt sürücüsü (SATA/NVMe) → donanım.**

### Dosya sistemi oluşturma — `mkfs`, MBR ve GPT

`mkfs` (make filesystem), boş/ham bir bölümün üzerine bir dosya sisteminin **iskeletini** yazar. Gün 2'de gördüğün ext4/XFS farkları burada devreye girer:

```bash
sudo mkfs.ext4 /dev/sdb1
sudo mkfs.xfs /dev/sdb1
```

> [!WARNING]
> **`mkfs`, hedef bölümün **tüm içeriğini geri dönüşü olmayan şekilde geçersiz kılar.** Doğru aygıt adını (`lsblk` ile teyit ederek) verdiğinden emin ol.**

**`mkfs` diske gerçekte ne yazar?**
"Biçimlendirme" yanıltıcıdır — `mkfs` bölümün **tamamını sıfırlamaz** (saatler sürerdi). Sadece **iskelet yapıları** sabit konumlara yazar:
- **Superblock:** dosya sisteminin künyesi — blok boyutu, toplam blok/inode sayısı, tip, son mount zamanı. ext4'te **birden fazla yedek kopya** disk boyunca serpiştirilir (`dumpe2fs` ile konumları görülür).
- **Inode tablosu:** **önceden ayrılmış, sabit boyutlu** inode dizisi — bu yüzden ext4'te toplam inode sayısı `mkfs` anında sabitlenir (Gün 2).
- **Blok grupları (ext4):** disk yönetilebilir parçalara bölünür, her grup kendi küçük inode/boş-blok haritasına sahiptir (locality → performans).
- **Kök dizin girdisi:** boş kökün ilk hâli.

Geri kalan milyarlarca veri bloğuna **dokunulmaz** — sadece "boş" işaretlenir. Sonuç: `mkfs`'ten hemen sonra eski verinin **çoğu hâlâ fiziksel olarak diskte durur**, sadece haritası sıfırlanmıştır — biçimlendirilmiş disklerden adli veri kurtarmanın (forensics) temel nedeni.

**MBR vs GPT — bölüm tablosu farkı:**

| | MBR (Master Boot Record) | GPT (GUID Partition Table) |
|---|---|---|
| Standart | Eski PC/BIOS standardı | **UEFI spesifikasyonunun parçası** |
| Maks. disk (512-bayt sektör) | **~2 TiB** (bölüm girdileri 32-bit LBA: 2³² × 512 bayt) | 64-bit LBA — pratik sınır yok (~9.4 ZB) |
| Birincil bölüm sayısı | En fazla **4** (ya da 3 birincil + 1 "extended" içinde mantıksal bölümler) | Varsayılan **128** (bölüm girdi dizisine ayrılan alan ≥ 16.384 bayt / 128 bayt) |
| Yedeklilik / bütünlük | Bölüm tablosu diskin başında **tek kopya**, checksum yok | Tablo **hem başta (LBA 1) hem sonda** yedekli; header ve girdi dizisi **CRC32** ile korunur |

`fdisk`, hem MBR hem GPT ile çalışır (etkileşimli menüde `g` ile GPT'ye çevirirsin); `parted` komut satırından/script'lenebilir şekilde ikisini de yönetir ve büyük disklerde daha rahattır. `fsck` (file system check) ise bölümlemeyle değil, **var olan** bir dosya sisteminin iç tutarlılığını (bozuk inode, yetim blok, çapraz bağlı dosyalar) denetler/onarır.

**Neden `fsck` mount'lu bir bölümde çalıştırılmaz? (derste "araştırılacak" not düşüldü)**
`fsck`, bölümü **doğrudan blok aygıt seviyesinde** okur/yazar — dosya sistemi sürücüsünü atlar. Bölüm mount'luyken, çekirdeğin dosya sistemi sürücüsünün **bellekte** güncel ama henüz diske yazılmamış (dirty) metadata'sı vardır. `fsck` diskteki eski hâli "bozuk" sanıp "düzeltince", çekirdek daha sonra kendi bellekteki hâlini geri yazınca dosya sistemi **gerçekten bozulur**. Bu yüzden `fsck` yalnızca **unmount** ya da **salt-okunur** mount edilmiş bölümde güvenlidir; kök bölüm için kurtarma ortamından (live USB) ya da boot sırasında `mount` edilmeden önce çalıştırılır.

```bash
sudo fsck /dev/sdb1        # bölüm mount'lu DEĞİLKEN çalıştır
sudo fsck -f /dev/sdb1     # temiz görünse bile ZORLA tam denetim
```

### Dizin yapısı (FHS) — hangi dizin ne işe yarar, ve **neden** böyle ayrılmış

Linux'ta `/` altındaki klasör isimleri rastgele değil; **Filesystem Hierarchy Standard (FHS)** ile standartlaşmıştır — bu yüzden hangi dağıtımı kullanırsan kullan `/etc` hep yapılandırma, `/var` hep değişken veri. Asıl önemli soru "ne barındırır" değil, **"bu ayrım neden bu şekilde"** — her ayrımın arkasında bir sistem yönetimi gerekçesi var:

| Dizin | Ne barındırır | Neden ayrı/böyle tasarlanmış |
|---|---|---|
| `/bin`, `/sbin` | Temel komutlar (`ls`, `cat`, `bash`) / sistem yönetimi (`fdisk`, `mkfs`) | **Tarihsel:** `/usr` eskiden ayrı, bazen geç bağlanan (hatta ağ üzerinden mount edilen) bir bölümdü. Sistem `/usr` yokken **kurtarma moduna** girebilsin diye en temel komutlar kök bölümde (`/bin`) durmalıydı. Modern dağıtımlar `usr-merge` ile bunları birleştirdi (`/bin` artık `/usr/bin`'e symlink; Debian 13 ve Rocky/RHEL bu yapıda) ama tarihsel ayrım komut isimlerinde/dokümanlarda yaşıyor. |
| `/etc` | Yapılandırma dosyaları (`/etc/fstab`, `/etc/passwd`) — çalıştırılabilir yok | Yapılandırmanın **program kodundan ayrı** tutulması, paket güncellemesi (`/usr` altını değiştirir) senin ayarlarını ezmez; ayrıca `/usr` salt-okunur/paylaşımlı bağlanabilse bile her makinenin kendi `/etc`'si olur. Bu prensip Gün 6'da systemd unit dizinlerinde (`/etc` > `/run` > `/usr/lib`) tekrar karşına çıkacak. |
| `/var` | Sık **değişen** veri: loglar, önbellek, mail kuyrukları | Loglar/cache sürekli büyür — kök bölümdeyse taşan bir log **tüm kök dosya sistemini doldurup sistemi çökertebilir**. `/var`'ı ayrı bölüm yapmak taşmayı sınırlar (üretim pratiği). |
| `/tmp` | Geçici dosyalar | Genelde `tmpfs` (RAM'de) — hızlı ve reboot'ta temizlenir. |
| `/home` | Kullanıcı dizinleri | Genelde ayrı bölüm — OS'i sıfırdan kurup `/`'yi formatlasan bile kullanıcı verisi korunur. |
| `/lib`, `/usr/lib` | Paylaşımlı kütüphaneler (`.so`) | Aynı kütüphane (örn. `libc`) her program için kopyalanmak yerine **tek yerde** tutulup paylaşılır — disk + RAM tasarrufu (aşağıda `ldd` mekanizması). |
| `/dev` | Aygıt dosyaları | Donanımı dosya arayüzüyle erişilebilir kılar; kendisi `devtmpfs` (RAM'de), diskte yer kaplamaz. |
| `/proc`, `/sys` | Kernel'in çalışma zamanı bilgisi | Disk verisi DEĞİL — aşağıda ayrı bölüm. |
| `/mnt`, `/media` | Geçici/çıkarılabilir aygıt mount noktaları | Sadece **kural gereği** boş dizinler — `/mnt` elle yönetim, `/media` otomatik-bağlama için; teknik zorunluluk yok, ortak anlaşma. |
| `/opt` | Dağıtım paket yöneticisi dışından kurulan bağımsız yazılımlar | FHS, dağıtım paketleri `/usr`'ı, üçüncü parti "bütün paket" yazılımlar `/opt/<üretici>`'yi kullansın der — çakışma olmaz. |

> [!TIP]
> **"Ayrı bölüm olarak mount edilir" notları teoride kalmasın: Gün 2'deki `mount` mekanizmasını hatırla — `/var`'ı ayrı bölüme koymak = `/etc/fstab`'a bir satır ekleyip her açılışta o bölümü `/var` dizinine `mount` etmek. Kavramsal olarak hiçbir şey değişmez, sadece "hangi dosyalar hangi fiziksel diskte" değişir.**

Bu konu Gün 4'te bir kez daha "derinlemesine tekrar" olarak geçiyor — orada sıfırdan anlatılmıyor, bu tabloya link veriliyor: [Gün 4#FHS'nin derinlemesine tekrarı — Gün 3'ün üzerine](Gün%204.md#fhsnin-derinlemesine-tekrarı-gün-3ün-üzerine).

**`ls` bir dizini nasıl listeler?** Yukarıdaki her dizin bir dizindir; `ls /etc` yazınca kernel listeyi **nereden** getiriyor — bunun tam mekanizmasını (dizinlerin aslında `(isim, inode)` tablosu tutan dosyalar olduğu, `ls`'in `readdir`/`getdents64` ile oradan okuduğu) Gün 2'nin inode bölümüne ekledim: [Gün 2#`ls` bir dizini listelerken gerçekte ne oluyor — mekanizma](Gün%202.md#ls-bir-dizini-listelerken-gerçekte-ne-oluyor-mekanizma).

### Bir programın ihtiyaç duyduğu kütüphaneleri bulmak — `ldd`

**Mekanizma:**
Çoğu Linux programı **dinamik olarak bağlanır (dynamic linking):** binary'nin içinde tüm kod yoktur, çalışırken paylaşımlı kütüphaneleri (`.so` — "shared object") yükler. `./program` yazdığında kernel dosyayı doğrudan çalıştırmaz: her ELF binary'nin içinde bir "yorumlayıcı" (interpreter) alanı vardır — genelde `/lib64/ld-linux-x86-64.so.2`. Kernel `execve()` ile **önce bu yorumlayıcıyı** (dinamik bağlayıcı / `ld.so`) belleğe yükler. `ld.so` sonra:
1. Programın "bana şu kütüphaneler lazım" listesini (`DT_NEEDED` girdileri) okur,
2. Her biri için sırayla arar: programa gömülü `RPATH`/`RUNPATH` → `LD_LIBRARY_PATH` ortam değişkeni → önceden derlenmiş önbellek (`/etc/ld.so.cache`, `ldconfig` ile `/etc/ld.so.conf`'tan üretilir) → varsayılan `/lib`, `/usr/lib`,
3. Bulduğu her `.so`'yu belleğe eşler (`mmap`), fonksiyon adreslerini çözer,
4. Sonra **asıl programı** başlatır.

```bash
ldd /bin/ls
#   linux-vdso.so.1 (...)
#   libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x...)
```
Her satır: "bu isimde bir kütüphane lazım, şu tam yolda bulundu". Bir satırda `=> not found` görürsen program çalışmaz (`error while loading shared libraries`).

**`ldd` nasıl çalışır — ve neden güvenmediğin binary'de tehlikeli?**
`ldd` ayrı bir araç değildir; arka planda dinamik bağlayıcıyı `LD_TRACE_LOADED_OBJECTS=1` ile çalıştırıp "ben şunları yükleyeceğim" listesini bastırır. Ama `man 1 ldd` uyarır: *"you should never employ ldd on an untrusted executable, since this may result in the execution of arbitrary code"* — bazı durumlarda (örn. program standart dışı bir ELF yorumlayıcı belirtmişse) `ldd` bilgiyi almak için **programı gerçekten çalıştırmayı** deneyebilir. Güvenli alternatif:
```bash
objdump -p /path/program | grep NEEDED     # programı çalıştırmadan doğrudan bağımlılıkları göster
```

**Notundaki deney** ("kütüphaneyi başka dizine kopyalayıp o kopyayla çalıştır"):
```bash
LD_LIBRARY_PATH=/senin/kopya/dizinin ./program
```
`LD_LIBRARY_PATH`, `ld.so`'ya "önce buraya bak" der (Gün 1'deki tek-seferlik `VAR=deger komut` mantığı — sadece o çalıştırma için). Hem hata ayıklamada (hangi kütüphane sürümü?) hem güvenlik testlerinde (kütüphane enjeksiyonu / sürüm izolasyonu) kullanılır.

### `/proc` ve `/sys` — diskte olmayan dosyalar

`man 5 proc`: *"The proc filesystem is a pseudo-filesystem which provides an interface to kernel data structures."* Yani `/proc` ve `/sys`, `ls -l` ile sıradan görünse de **diskte hiçbir karşılıkları yoktur** — kernel'in bellekteki bilgisini dosya arayüzü üzerinden sunan **sanal (pseudo) dosya sistemleridir** (`procfs`, `sysfs`).

**`cat /proc/cpuinfo` yazınca gerçekte ne oluyor? (mekanizma)**
Normal bir dosyada `cat`, VFS aracılığıyla dosya sistemi sürücüsüne "şu inode'un şu bloklarını oku" der; sürücü diskten getirir. `/proc/cpuinfo`'da böyle bir "blok" yoktur — arkasında kernel içinde **bir fonksiyon** vardır. `cat` bu dosyayı `open()`+`read()` ile açtığında VFS isteği normal disk sürücüsüne değil `procfs` sanal dosya sistemi sürücüsüne yönlendirir; o da "CPU bilgisini formatla ve bu buffer'a yaz" diyen fonksiyonunu **o an, senin okuma isteğine cevap olarak** çalıştırır. Sonuç: her `cat /proc/cpuinfo`'da çıktı **yeniden üretilir** (diskten "okunmaz", kernel'in o anki durumundan hesaplanır) — bu yüzden `stat` ile boyutuna baktığında genelde `Size: 0` görürsün: dosyanın önceden bilinen sabit bir boyutu yoktur, içerik **istek anında üretilir**.

```bash
cat /proc/cpuinfo        # CPU bilgisi (çekirdek sayısı, model...)
cat /proc/meminfo        # anlık RAM kullanımı (Gün 6'da `free` bunu okuyor)
ls /proc/                # çalışan her sürecin PID'si kadar sayısal dizin
cat /proc/1/status       # PID 1'in (init/systemd) durumu
cat /proc/sys/kernel/hostname   # bazı kernel parametreleri buradan hem OKUNUR hem YAZILIR

ls /sys/class/net/        # sistemdeki ağ arayüzleri
cat /sys/class/thermal/thermal_zone0/temp   # donanım sıcaklık sensörü (varsa)
```

**Fark:** `/proc` daha çok **süreç (process) + genel kernel durumu** içindir (adı da buradan); `/sys` daha yapılandırılmış biçimde **aygıt/sürücü (device/driver)** modelini dışa vurur — `udev` aygıt olaylarını (USB takıldı/çıkarıldı) `/sys` üzerinden takip eder. İkisi de root olmadan çoğunlukla **okunabilir**; bazı dosyalara yazmak (`/proc/sys/...` kernel parametreleri) canlı sistemin davranışını değiştirir, dikkat ister.

### Kaynaklar

**Bu başlık her zaman Genişletilmiş Anlatım'ın SON `###` bölümüdür** — hemen ardından `## Notlar` gelir.

- **Relative symlink çözünürlüğü (symlink yürüyüşün ortasında, kendi konumundan çözülür):**
  - [path_resolution(7) — man7.org](https://man7.org/linux/man-pages/man7/path_resolution.7.html) — "we first resolve this symbolic link (with the current lookup directory as starting lookup directory)"; 40 symlink sınırı (`ELOOP`).
- **Hardlink bulma, dizin hardlink yasağı, `EXDEV`/`EPERM`:**
  - [link(2) — man7.org](https://man7.org/linux/man-pages/man2/link.2.html) — `EPERM` "oldpath is a directory", `EXDEV` "not on the same mounted filesystem".
  - [find(1) — GNU findutils](https://www.gnu.org/software/findutils/manual/html_mono/find.html) — `-inum`, `-samefile` semantiği; `-inum`'un dosya sistemi başına anlamlı olması.
- **`mv` / `rename()` atomikliği ve `EXDEV`:**
  - [rename(2) — man7.org](https://man7.org/linux/man-pages/man2/rename.2.html) — "If newpath already exists, it will be atomically replaced..."; `EXDEV` farklı dosya sistemi.
- **Block vs character device, VFS katmanları:**
  - [inode(7) — man7.org](https://man7.org/linux/man-pages/man7/inode.7.html) — dosya tipi bitleri (S_IFBLK, S_IFCHR), major/minor.
- **`mkfs` iskelet yapıları (superblock, inode tablosu, blok grupları):**
  - [ext4 Data Structures and Algorithms — The Linux Kernel documentation](https://www.kernel.org/doc/html/latest/filesystems/ext4/) — superblock yedekleri, blok grupları, statik inode tablosu.
  - [mke2fs(8) — man7.org](https://man7.org/linux/man-pages/man8/mke2fs.8.html) — inode oranının `mkfs` sonrası değiştirilememesi.
- **MBR vs GPT (4 birincil bölüm, ~2 TiB / 32-bit LBA; GPT UEFI'nin parçası, 128 girdi, başta+sonda yedek, CRC32):**
  - [GUID Partition Table — Wikipedia](https://en.wikipedia.org/wiki/GUID_Partition_Table) (tersiyer — UEFI spesifikasyonundan alıntılar ve tam sayılar): "For hard disks with 512-byte sectors, the MBR partition table entries allow a maximum size of 2 TiB (2³² × 512 bytes)"; GPT header LBA 1 + backup at end; header ve girdi dizisi için ayrı CRC-32; girdi dizisine ≥ 16.384 bayt (= 128 × 128 bayt).
  - [Windows and GPT FAQ — Microsoft Learn](https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/windows-and-gpt-faq) (birincil/vendor — MBR 2.2 TB sınırı, 4 birincil bölüm; GPT 128 bölüm varsayılanı).
  - [GPT fdisk / gdisk — Rod Smith (gdisk yazarı)](https://www.rodsbooks.com/gdisk/) — GPT'nin "UEFI 2.x specifications"ta tanımlı olması, MBR sınırlarını aşma.
- **usr-merge (`/bin` → `/usr/bin` symlink), Debian 13 / Rocky durumu:**
  - [UsrMerge — Debian Wiki](https://wiki.debian.org/UsrMerge)
  - bkz. [Gün 6#Kaynaklar](Gün%206.md#kaynaklar) (systemd unit dizinleri bağlamında yeniden doğrulandı).
- **FHS:**
  - [Filesystem Hierarchy Standard 3.0 — Linux Foundation Refspecs](https://refspecs.linuxfoundation.org/FHS_3.0/fhs/index.html) — `/etc`, `/var`, `/opt`, `/mnt` vs `/media` tanımları ve gerekçeleri.
- **`ldd` mekaniği ve güvenlik uyarısı, dinamik bağlayıcı arama sırası:**
  - [ldd(1) — man7.org](https://man7.org/linux/man-pages/man1/ldd.1.html) — "never employ ldd on an untrusted executable"; `LD_TRACE_LOADED_OBJECTS=1`.
  - [ld.so(8) — man7.org](https://man7.org/linux/man-pages/man8/ld.so.8.html) — `RPATH`/`RUNPATH` → `LD_LIBRARY_PATH` → `ld.so.cache` → varsayılan dizinler arama sırası.
- **`/proc` ve `/sys` sanal dosya sistemi mantığı (içerik istek anında üretilir):**
  - [proc(5) — man7.org](https://man7.org/linux/man-pages/man5/proc.5.html) — "a pseudo-filesystem which provides an interface to kernel data structures".
  - [sysfs(5) — man7.org](https://man7.org/linux/man-pages/man5/sysfs.5.html) — sysfs'in aygıt/sürücü modelini dışa vurması.

Tekil bayrak/sözdizimi anlamları (`readlink -f`, `fdisk -l`, `mkfs.ext4` çağrısı vb.) ilgili `man` sayfalarıyla doğrulanabilir; bunlar için ayrıca kaynak gösterilmedi.

## Notlar

- Bugünün ana teması: Gün 2'nin inode/link konusunun **kanıtla derinleştirilmesi** (relative symlink çözünürlüğü path-resolution'ın sonucu; `mv`'nin `stat` çıktısında görülen dosya-sistemi-sınırı davranışı) ve disk yönetiminden **dizin yapısı / aygıt modeline** geçiş (block vs character device, FHS'nin *neden*i, `/proc`-`/sys`'in sanal doğası).
- En kritik pratik çıkarımlar: (1) bir `mv`'nin "anlık" mı "yavaş" mı olacağı kaynak+hedefin aynı `df -h` `Filesystem` sütununda olup olmamasına bağlı; (2) `rename()`'in atomikliği "geçici dosyaya yaz → `mv` ile taşı" güvenli güncelleme kalıbının temeli; (3) `fsck` yalnızca mount'suz bölümde güvenli.
- `find / -inum` ile `-samefile` farkı: `-inum` inode numarasını dosya sistemi başına anlamlı sayar, farklı bölümde yanlış eşleşme çıkarabilir; `-samefile` cihaz+inode karşılaştırır.
- `/etc` > `/run` > `/usr/lib` önceliği (Gün 6, systemd) ile `/etc`'nin `/usr`'dan ayrı olması (FHS) aynı prensibin tekrarı: **paket güncellemesi yerel özelleştirmeyi ezmemeli**.

## Komutlar / Örnekler

```bash
# symlink çözünürlüğü
readlink dosya2.txt          # symlink'in içindeki ham hedef
readlink -f dosya2.txt        # o an çözüldüğü gerçek yol

# hardlink bulma
ls -i dosya.txt
find / -samefile dosya.txt 2>/dev/null     # -inum yerine tercih et

# mv iç mekanizması karşılaştırması
df -h ./ /tmp                # aynı Filesystem mi, farklı mı önceden kontrol et
stat dosya.txt                # taşımadan önce inode/Device'ı not al
mv dosya.txt /baska/yer/
stat /baska/yer/dosya.txt     # inode/Device değişti mi karşılaştır

# aygıt tipi
ls -l /dev/sda /dev/tty1      # ilk karakter b (block) mü c (character) mı

# dosya sistemi / bölümleme
sudo mkfs.ext4 /dev/sdb1
sudo fsck -f /dev/sdb1        # SADECE unmount iken

# kütüphane bağımlılıkları
ldd /bin/ls
objdump -p /bin/ls | grep NEEDED    # güvenmediğin binary'de ldd yerine
LD_LIBRARY_PATH=/ozel/dizin ./program

# /proc ve /sys keşfi
cat /proc/cpuinfo
cat /proc/meminfo
ls /sys/class/net/
```

## Sorular / Takip Edilecekler

- [ ] `parted` komutunun `fdisk`'e göre tam kullanım farkları (özellikle script'lenebilir mod, `parted -s ... mkpart`).
- [x] `fsck`'in mount'lu bir bölümde neden çalıştırılmaması gerektiği → Cevaplandı: [Gün 3#Dosya sistemi oluşturma — `mkfs`, MBR ve GPT](Gün%203.md#dosya-sistemi-oluşturma-mkfs-mbr-ve-gpt) içindeki "Neden `fsck` mount'lu bir bölümde çalıştırılmaz?" alt başlığı (kernel'in bellekteki dirty metadata'sı ile diskteki hâl çelişir).
- [ ] Bir dosyaya bağlanan tüm **symlink**'leri (hardlink değil) sistem genelinde bulmak: `find / -type l -lname '*dosya.txt' 2>/dev/null` (`-lname` symlink hedefine göre eşleşir) — kendi VM'inde dene, `readlink -f` ile doğrula.
