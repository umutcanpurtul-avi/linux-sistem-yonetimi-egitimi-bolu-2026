---
tags:
  - egitim/linux-sistem-yonetimi
tarih: 2026-08-23
konular:
  - Yol kavramı (mutlak/bağıl)
  - grep / find / diff
  - hardlink ve symlink
  - Disk bölme, mount/unmount
  - Dosya sistemi ve inode
---

# Gün 2 Raporu

Bağlantı: [Linux Sistem Yönetimi Eğitimi](../README.md) · [00 - Eğitim Planı](../00%20-%20Eğitim%20Planı.md) · [Gün 1](Gün%201.md)

## İşlenen Konular

- CD komutları ve parametreleri.
	- ../../ ile / arasında bulunan farklar.
	- cd .. ile cd . arasında farklar
	- Bu kombinasyonların farklı kombinasyonlarının kullanılması.
- Grep ve Find Komutunun kullanımı.
- Diff komutu kullanımı
- hardlink ve symlink arasındaki farklar.
	- ln kullanımı.
	- ln -s  kullanımı.
- Disk bölme / Disk ekleme / Disk mount/unmount etme yapıldı.
- dosya sistemi 
	- dosya sistemlerinin avantaj ve dezavantajları
- Linux dosya sistemi nedir
	- inode nedir
		- dosya sistemine göre inode kullanımı
	- lsblk / fdisk kullanımı.

## Genişletilmiş Anlatım (Öğrenme İçin Ek Açıklamalar)

> [!WARNING]
> **Yukarıda bulunan kısa notların AI ile genişletilmiş halidir. Bilgiler sadece o gün işlenen konular ile sınırlandırılmış olup referans olması için eklenmiştir. Lütfen bu genişletilmiş metni kendi araştırmalarınıza bir ön bilgi olarak kullanın ve testlerinizi sadece burayı kullanarak değil, farklı kaynaklardan da yararlanarak yapın.**

### `cd` ve yol (path) kavramı

Önce temel ayrımı netleştirelim: Linux'ta bir dosyaya/dizine giden **iki türlü yol** vardır.

- **Mutlak yol (absolute path):** Her zaman `/` (kök dizin) ile başlar. Bulunduğun yerden bağımsızdır — nerede olursan ol aynı sonucu verir. Örnek: `/home/ucp/Belgeler`.
- **Bağıl yol (relative path):** `/` ile başlamaz, **şu an bulunduğun dizine göre** hesaplanır. Aynı komutu farklı dizinlerden çalıştırırsan farklı bir hedefe gidebilir. Örnek: `Belgeler/rapor.txt` (bulunduğun dizinin altındaki `Belgeler` klasörü).

**`.` ve `..` nedir?**
Her dizinin içinde görünmeyen iki özel girdi vardır (bunları `ls -a` ile görebilirsin):
- `.` → "şu an bulunduğum dizinin kendisi". `cd .` çalıştırırsan hiçbir yere gitmemiş olursun, çünkü hedef zaten bulunduğun yerdir. Asıl kullanım alanı `cd` değil, "bu dizinin kendisini" bir argüman olarak başka komuta vermektir: `ls .` (bulunduğun dizini listele), `./script.sh` (bulunduğun dizindeki script'i çalıştır — `./` olmadan yazarsan kabuk `script.sh`'i `$PATH` içinde arar, bulamaz).
- `..` → "bir üst (ebeveyn) dizin". `cd ..` seni hiyerarşide bir seviye yukarı taşır. `..` bağıl bir ifadedir; her zaman "şu anki konumuma göre bir yukarı" anlamına gelir, mutlak bir hedefi yoktur.

**`../../` ile `/` arasındaki fark — bu genelde kafa karıştıran nokta:**
- `../../` → bağıldır, "şu an bulunduğum yerden **iki seviye yukarı çık**" demektir. Nereden çalıştırdığına göre farklı bir dizine iner. Örnek: `/home/ucp/proje/src` içindeyken `cd ../../` yaparsan `/home/ucp`'ye gidersin (src → proje → ucp, iki adım).
- `/` → mutlaktır, "bulunduğun yeri unut, doğrudan **dosya sisteminin en köküne** git" demektir. Nereden çalıştırırsan çalıştır her zaman aynı yere (kökün kendisine) gider.

Kısacası: `..` göreceli bir "geri adım", `/` ise mutlak bir "sıfırlama"dır. `cd /` ile `cd ..`'yi art arda 5-6 kez yazmak **aynı sonucu vermeyebilir** — `cd ..`'yi kaç kez tekrarlaman gerektiği, o an dizin ağacında ne kadar derinde olduğuna bağlıdır; `cd /` ise konumdan bağımsız olarak tek seferde köke götürür.

**Sık kullanılan kombinasyonlar:**
```bash
cd /etc/nginx        # mutlak: nerede olursan ol nginx dizinine gider
cd ../config          # bağıl: bir üst dizinin içindeki config'e gider
cd ../../var/log       # bağıl: iki üst dizine çık, sonra var/log'a in
cd ~                  # ev dizinine git (kısayol, mutlak yolun kısaltması)
cd ~/Belgeler          # ev dizini altındaki Belgeler'e git
cd -                  # bir önceki bulunduğun dizine dön (Gün 1'de işlendi)
cd                   # parametresiz cd de ev dizinine götürür (cd ~ ile aynı)
```

> [!TIP]
> **Hızlı test: `pwd` her zaman senin **mutlak** konumunu gösterir. Bir `cd` komutundan sonra nereye gittiğinden emin değilsen `pwd` çalıştırma alışkanlığı edin.**

### `grep` — dosya **içeriğinde** arama

`grep`, bir veya birden fazla dosyanın **içindeki metinde** belirli bir deseni (kelime, ifade, düzenli ifade/regex) arar ve eşleşen satırları bastırır. "Bu kelime hangi dosyada, hangi satırda geçiyor?" sorusunun cevabıdır.

```bash
grep "hata" log.txt              # log.txt içinde "hata" geçen satırları bas
grep -i "hata" log.txt           # büyük/küçük harf duyarsız (Hata, HATA da yakalanır)
grep -n "hata" log.txt           # satır numarasıyla birlikte göster
grep -r "TODO" .                 # bulunduğun dizinden başlayarak TÜM alt dizinlerde ara
grep -v "debug" log.txt          # TERSİ: "debug" GEÇMEYEN satırları göster
grep -c "hata" log.txt           # kaç satırda eşleşme var, sayısını ver (satırları basma)
grep -l "TODO" *.py              # eşleşme içeren dosya adlarını listele (içerik değil)
grep -E "hata|error" log.txt     # genişletilmiş regex: "hata" VEYA "error"
```

**Neden önemli:** Bir sunucuda binlerce satırlık log dosyasında elle "hata" arayamazsın; `grep` bunu saniyeler içinde yapar. Genelde `|` (pipe, Gün 1'de işlendi) ile başka komutlarla zincirlenir: `ps aux | grep nginx` gibi.

### `find` — dosya sistemi ağacında dosya/dizin **arama**

`grep` içerik arar, `find` ise **dosyanın kendisini** (adına, tipine, boyutuna, tarihine göre) dizin ağacında arar. İkisi karıştırılmamalı: "hangi dosyanın içinde X kelimesi var" → `grep`; "hangi dosyanın adı X, ya da 30 gün önce değişmiş, ya da 100MB'tan büyük" → `find`.

```bash
find /home -name "*.txt"            # /home altında adı .txt ile biten her şey
find . -type f                       # bulunduğun yerden başlayarak sadece dosyalar (d=dizin, l=symlink)
find . -type d -name "cache"         # adı "cache" olan dizinler
find /var/log -mtime -7              # son 7 gün içinde değişmiş dosyalar
find /var/log -mtime +30 -name "*.log"   # 30 günden ESKİ .log dosyaları
find . -size +100M                   # 100MB'tan büyük dosyalar
find . -name "*.tmp" -delete         # ⚠️ bulunanları DOĞRUDAN SİL — önce -delete'siz çalıştırıp kontrol et
find . -name "*.sh" -exec chmod +x {} \;   # bulunan her dosyaya bir komut uygula ({} = bulunan dosya)
```

> [!WARNING]
> **`-delete` veya `-exec rm` kullanmadan önce mutlaka aynı `find` komutunu bu bayraklar OLMADAN çalıştırıp hangi dosyaların eşleştiğini gözden geçir. `find` geri alma sunmaz.**

### `diff` — iki dosyayı karşılaştırma

İki dosya (veya iki dizin) arasındaki farkı satır satır gösterir. Config dosyalarını karşılaştırmak, bir değişiklikten önce/sonra ne değişti görmek için kullanılır.

```bash
diff dosya1.txt dosya2.txt
# < ile başlayan satırlar → sadece dosya1.txt'de var
# > ile başlayan satırlar → sadece dosya2.txt'de var

diff -u eski.conf yeni.conf     # "unified" format — patch dosyası üretmek için standart biçim
diff -r dizin1/ dizin2/         # iki dizini recursive (alt dizinler dahil) karşılaştır
diff -q dizin1/ dizin2/         # sadece HANGİ dosyaların farklı olduğunu söyle, içeriği basma
```

Çıktı boşsa (`diff` hiçbir şey basmadan çıkış kodu 0 ile bittiyse) iki dosya **birebir aynıdır**. Bunu betiklerde kontrol için kullanabilirsin: `diff -q a b >/dev/null && echo "aynı"`.

### Hardlink ve symlink arasındaki fark — inode üzerinden düşünmek gerekir

Bunu anlamak için önce **inode** kavramını bilmek gerekiyor (aşağıda ayrıca anlatıyorum) ama kısaca: her dosyanın gerçek içeriği ve meta verisi bir **inode**'da tutulur; dosya adı ise sadece dizindeki bir "etiket"tir, o etiket bir inode numarasına işaret eder.

**Hardlink (`ln kaynak hedef`):** Var olan bir dosyanın inode'una, ikinci bir isim/etiket daha ekler. İki isim de **tamamen eşdeğerdir** — hangisinin "asıl", hangisinin "link" olduğu yoktur, ikisi de aynı veriye işaret eder. Birini silersen veri silinmez, çünkü inode'un hâlâ en az bir ismi (link) kalmıştır — Gün 1'de gördüğün "link sayısı" tam olarak budur. Veri gerçekten silinir ancak o inode'a işaret eden **son isim de** silindiğinde.

**Kısıtlamalar:** Hardlink farklı disk/bölüm arasında kurulamaz (inode numarası sadece kendi dosya sistemi içinde anlamlıdır) ve dizinler için oluşturulamaz (kernel, sonsuz döngü riski nedeniyle buna izin vermez).

**Symlink (`ln -s kaynak hedef`):** Kendi **ayrı bir inode'u olan**, içinde sadece "hedef dosyanın yolu" yazan küçük özel bir dosyadır — Windows'taki kısayola çok benzer. Symlink'i açtığında sistem otomatik olarak hedefe yönlendirir. Hedef dosya silinirse symlink kendisi durmaya devam eder ama artık hiçbir yere işaret etmeyen **"kırık" (broken) bir link** hâline gelir — açmaya çalışırsan "No such file or directory" alırsın.

**Symlink'in avantajı:** Farklı disk/bölümler arasında çalışır, dizinlere de yapılabilir, `ls -l` çıktısında `l` ile başlar ve hedefi açıkça gösterir (`kısayol -> /gerçek/yol`).

```bash
ln ucptest.txt ucp.js            # hardlink: ikisi de aynı inode'u paylaşır
ln -s ucptest.txt ucp-link.js    # symlink: ayrı inode, sadece yol bilgisi tutar

ls -li ucptest.txt ucp.js        # -i ile inode numaralarını göster — ikisi AYNIysa hardlink doğrulanmış olur
ls -l ucp-link.js                # symlink satırı l ile başlar, "-> ucptest.txt" hedefi gösterir
```

**Hangisini ne zaman kullanmalı?** Aynı diskte, dosyanın "gerçekten aynı veri" olmasını istiyorsan (örn. eski bir dosya adının hâlâ çalışmasını istiyorsan) hardlink; farklı disk/dizinler arası kısayol, ya da "hedef değişebilir/silinebilir, sorun değil" durumunda symlink (örn. `/usr/bin/python -> python3.12`) tercih edilir.

### Disk bölme / ekleme / mount-unmount

Bu konuyu tam olarak Gün 1'in devamında `CL-Egitim/09-disk-yonetimi.md` dosyasında uçtan uca (GPT/MBR, `fdisk`/`parted`, `mkfs`, `mount`, `/etc/fstab`, `umount`) çok ayrıntılı işledik — orada `mount`'un "USB bellek benzetmesi" ile neden gerektiğini, `/etc/fstab`'ın her sütununu, `umount`'un nasıl yapıldığını satır satır bulabilirsin. Burada sadece bugünkü akışın kısa özetini tekrar edelim:

```
Fiziksel disk (/dev/sdb)
   ↓ fdisk/parted ile BÖLME   → /dev/sdb1
   ↓ mkfs ile BİÇİMLENDİRME   → içine ext4/xfs dosya sistemi yazılır
   ↓ mount ile BAĞLAMA        → /veri gibi bir dizinden erişilir hale gelir
   ↓ umount ile ÇÖZME         → dizinden erişim koparılır, disk güvenle çıkarılabilir
```

`umount` (dikkat: "unmount" değil, **`umount`** — n harfi yok) bağlamayı geri alır:
```bash
sudo umount /veri
sudo umount /dev/sdb1     # aynı işi aygıt adıyla da yapabilirsin
```
"target is busy" hatası alırsan, o dizinin içinde biri duruyor ya da bir süreç orada açık bir dosya tutuyor demektir — `lsof +D /veri` ile kimin kullandığını bulabilirsin (Gün 1'de bu konuyu da işlemiştik).

### Dosya sisteminin avantaj ve dezavantajları

"Dosya sistemi", diskteki ham baytları "dosya ve dizin" kavramına çeviren yazılım katmanıdır (disk kendisi sadece sektörlerden oluşan düz bir alan bilir, "dosya" diye bir şey bilmez — bu soyutlamayı dosya sistemi sağlar). Farklı dosya sistemlerinin farklı tasarım öncelikleri vardır:

| Dosya sistemi | Avantajı | Dezavantajı |
|---|---|---|
| **ext4** | Çok olgun, her yerde desteklenir, hem büyütülebilir hem küçültülebilir | Bazı çok büyük dosya / yoğun paralel yazma senaryolarında XFS kadar hızlı değil |
| **XFS** | Büyük dosyalarda ve paralel I/O'da (çok sayıda eşzamanlı yazma) çok hızlı, RHEL ailesinin varsayılanı | **Küçültülemez** — bir kez büyütünce geri dönüş yok, yedek alıp yeniden oluşturman gerekir |
| **Btrfs** | Anlık görüntü (snapshot), checksum ile veri bütünlüğü doğrulama, subvolume desteği | Daha karmaşık, bazı iş yüklerinde performansı öngörülebilir değil |
| **vfat/exfat** | Windows/Mac ile evrensel uyumluluk (USB bellek vb.) | Linux izin sistemini (owner/group/rwx) **desteklemez** — herkes her şeyi yapabilir gibi davranır |

Kısacası "en iyi dosya sistemi" diye bir şey yok — sunucuda büyük dosyalarla çalışıyorsan XFS, genel amaçlı ve esneklik istiyorsan ext4, anlık görüntü/veri bütünlüğü öncelikliyse Btrfs, sadece taşınabilir USB için vfat/exfat mantıklıdır.

### Linux dosya sistemi ve inode nedir

**inode nedir, neden var?**
Bir dosyayı düşün: onun bir sahibi, izinleri, boyutu, oluşturulma/değiştirilme tarihi ve diskteki hangi bloklarda durduğu bilgisi vardır. Bütün bu meta veri, **inode** adı verilen bir yapıda saklanır — ama **dosyanın adı inode'un içinde tutulmaz.** Dosya adı, sadece bir dizinin içeriğinde "bu isim şu inode numarasına işaret ediyor" şeklinde bir kayıttır.

**Benzetme:** inode, bir kitabın ISBN numarasıyla ilişkilendirilmiş kütüphane kaydı gibidir (yazar, sayfa sayısı, raf konumu — ama kitabın "adı" değil, sadece künyesi). Kitaba farklı kütüphanelerden farklı isimlerle atıfta bulunabilirsin (hardlink), ama hepsi aynı ISBN'e (inode'a) işaret eder. Bu yüzden bir dosyanın adını değiştirmek (`mv eski yeni`) aslında veriyi hiç taşımaz — sadece dizindeki etiketi değiştirir, inode ve içindeki veri yerinde kalır.

```bash
ls -i dosya.txt          # dosyanın inode numarasını göster
stat dosya.txt           # inode'daki TÜM meta veriyi ayrıntılı gör (izin, sahip, zaman damgaları, link sayısı)
```

**Dosya sistemine göre inode kullanımı — kritik bir ayrıntı:**
ext4 gibi dosya sistemlerinde, **toplam inode sayısı** disk `mkfs` ile biçimlendirilirken **sabitlenir** ve sonradan artırılamaz (disk boyutuna göre otomatik hesaplanır ama sabit bir sayıdır). Bunun pratik sonucu: eğer diskinde milyonlarca **küçük** dosya oluşturursan (örn. küçük önbellek/log dosyaları), disk alanı hâlâ boşken bile **inode'lar tükenebilir** — çünkü her dosya, boyutundan bağımsız olarak bir inode tüketir. Bu durumda `df -h` sana "%40 dolu" gibi bolca boş alan gösterir ama yeni dosya oluşturmaya çalıştığında "No space left on device" hatası alırsın. Gerçek nedeni görmek için:
```bash
df -h        # disk ALAN doluluğu — burada boş görünebilir
df -i        # inode doluluğu — asıl sorun genelde burada görünür (IUse% %100)
```
XFS bu sorunu farklı çözer: inode'ları dinamik olarak (b-tree yapısıyla) ihtiyaç oldukça ayırır, bu yüzden pratikte "inode tükenmesi" XFS'te neredeyse hiç yaşanmaz — bu da XFS'in disk yönetimi modülünde neden öne çıktığının bir başka nedenidir.

### `lsblk` ve `fdisk` kullanımı

```bash
lsblk                     # tüm blok cihazlarını (disk/bölüm) ağaç halinde listeler — SALT OKUNUR, güvenli
lsblk -f                  # + dosya sistemi tipi ve UUID bilgisi ekler
sudo fdisk -l              # tüm disklerin bölüm tablolarını (salt okunur) listeler
sudo fdisk /dev/sdb          # ETKİLEŞİMLİ mod — bölüm oluşturma/silme burada yapılır (Gün 1/09'da tuş tuş anlatıldı)
```

`lsblk` sadece **görmek** içindir, hiçbir şeyi değiştirmez — bu yüzden çekinmeden istediğin kadar çalıştırabilirsin. `fdisk` ise (parametresiz, sadece aygıt adıyla çağrıldığında) **etkileşimli düzenleme moduna** girer; `w` (write) demeden hiçbir değişiklik diske yazılmaz, yanlış yaptıysan `q` ile kaydetmeden çıkabilirsin.

## Notlar

- Bugünün ana teması: **yol (path) okuryazarlığı** (mutlak vs bağıl, `.`/`..`/`/` farkı), metin/dosya **arama araçları** (`grep` içerik, `find` dosya meta verisi), **link mekanizması** (hardlink = aynı inode'a ikinci isim, symlink = ayrı inode'lu kısayol) ve dünkü disk konusunun **inode** seviyesinde derinleşmesi.
- `grep` ve `find` sık karıştırılır: "içinde ne yazıyor" sorusu `grep`'e, "hangi dosya/nerede/ne zaman" sorusu `find`'a aittir. İkisi genelde birlikte kullanılır: `find . -name "*.log" -exec grep -l "hata" {} \;`
- inode kavramı, hardlink'in neden dosyalar arasında "eşdeğer" olduğunu ve `df -h` boşken bile "disk dolu" hatası alınabileceğini açıklayan temel kavramdır — bu konuyu Gün 1'deki `ls -al` çıktısındaki **link sayısı** ile birlikte düşünmek konuyu pekiştirir.

## Komutlar / Örnekler

```bash
# cd ve yol kombinasyonları
cd /var/log            # mutlak yol
cd ../..                # iki üst dizine bağıl çıkış
cd -                   # önceki dizine dön
pwd                    # her zaman mutlak konumunu doğrula

# grep — içerik arama
grep -rni "error" /var/log/
grep -v "^#" /etc/fstab      # yorum satırlarını (# ile başlayanlar) HARİÇ TUT, geri kalanı göster

# find — dosya arama
find /home -type f -name "*.sh"
find . -mtime -1 -type f            # son 24 saatte değişen dosyalar

# diff — karşılaştırma
diff -u eski.conf yeni.conf > degisiklik.patch

# hardlink / symlink
ln ucptest.txt ucp.js         # hardlink
ln -s ucptest.txt ucp-sym.js  # symlink
ls -li ucptest.txt ucp.js     # inode numaralarını karşılaştır

# inode / disk bilgisi
stat ucptest.txt
df -i /veri
lsblk -f
sudo fdisk -l

# mount / umount özet (ayrıntı: CL-Egitim/09-disk-yonetimi.md)
sudo mount /dev/sdb1 /veri
sudo umount /veri
```

## Sorular / Takip Edilecekler

- [ ] Oluşturulan diskin içine veri ekleyip bu diski mount edersek eklenen verileri mount sonrasında gizlenecek bunu nasıl görebiliriz.

> [!TIP]
> **Ön araştırma notu (eğitmenle teyit edilmeli)**
> Burada aslında Gün 1'de de değindiğimiz "boş dizin şartı" senaryosunun tam tersini soruyorsun; net bir örnekle açalım:
>
> Diyelim `/veri` dizini, kök diskin (`/dev/sda1`) sıradan bir klasörü. İçine `notlarim.txt` diye bir dosya koydun. Sonra `sudo mount /dev/sdb1 /veri` çalıştırdın (ikinci diski aynı dizine bağladın). Bu andan itibaren `/veri` içine baktığında artık `/dev/sdb1`'in içeriğini görürsün — **`notlarim.txt` görünmez olur** (silinmemiştir, sadece "altta", erişilemez durumdadır, çünkü artık o dizin ismi üzerinden başka bir dosya sistemine bakıyorsun).
>
> **Gizlenen veriyi görmenin iki yolu var:**
> 1. **En basit yol — geçici olarak `umount` et:** `sudo umount /veri` çalıştırdığın an, üstteki disk kaldırılır ve altındaki eski `notlarim.txt` tekrar görünür hale gelir. İşin bitince tekrar `sudo mount /dev/sdb1 /veri` ile eski hâline dönebilirsin.
> 2. **Diski kaldırmadan görmek istiyorsan:** Altındaki verinin bulunduğu **asıl bölümü** (örn. kök dosya sistemi `/dev/sda1`), başka **boş bir dizine** geçici olarak tekrar mount edersin: `sudo mount /dev/sda1 /mnt/gecici` — böylece `/mnt/gecici/veri/notlarim.txt` yolundan, `/veri`'yi hiç bozmadan, gizli kalan dosyaya ulaşırsın. (Bu yöntem sadece `/dev/sda1` ayrı bir bölümse işe yarar; `/veri` doğrudan kök bölümdeyse ve kök zaten mount'lu haldeyse bu adım gerekmeyebilir — kökü zaten normal şekilde görürsün, sorun sadece `/veri` **üzerine başka bir şey mount'landığında** ortaya çıkar.)
>
> Özetle: mount, veriyi **silmez**, sadece o an için **erişilemez** kılar; veriye ulaşmanın yolu ya üstteki mount'u kaldırmak ya da altındaki gerçek bölümü başka bir noktadan görmektir.
