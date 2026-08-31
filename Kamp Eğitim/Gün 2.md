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

Bağlantı: [Linux Sistem Yönetimi Eğitimi](../README.md) · [00 - Eğitim Planı](../00%20-%20Eğitim%20Planı.md) · [Gün 1](Gün%201.md) · [Gün 3](Gün%203.md)

## İşlenen Konular

- `cd` komutu ve parametreleri.
	- `../../` ile `/` arasındaki farklar.
	- `cd ..` ile `cd .` arasındaki fark.
	- Bu ifadelerin farklı kombinasyonlarının kullanılması.
- `grep` ve `find` komutlarının kullanımı.
- `diff` komutunun kullanımı.
- Hardlink ve symlink arasındaki farklar.
	- `ln` kullanımı.
	- `ln -s` kullanımı.
- Disk bölme / disk ekleme / disk mount-unmount etme yapıldı.
- Dosya sistemi nedir.
	- Dosya sistemlerinin avantaj ve dezavantajları.
- Linux dosya sistemi nedir.
	- inode nedir.
		- Dosya sistemine göre inode kullanımı.
	- `lsblk` / `fdisk` kullanımı.

## Genişletilmiş Anlatım (Öğrenme İçin Ek Açıklamalar)

> [!WARNING]
> **Yukarıda bulunan kısa notların AI ile genişletilmiş halidir. Bilgiler sadece o gün işlenen konular ile sınırlandırılmış olup referans olması için eklenmiştir. Lütfen bu genişletilmiş metni kendi araştırmalarınıza bir ön bilgi olarak kullanın ve testlerinizi sadece burayı kullanarak değil, farklı kaynaklardan da yararlanarak yapın.**

### `cd` ve yol (path) kavramı

**Mekanizma — bir yol string'i kernel'in gözünde ne ifade eder?**
Bir yol (`/etc/nginx/nginx.conf` ya da `../log/app.log`) tek parça bir adres değildir; kernel bunu **bileşen bileşen, soldan sağa yürüyerek** çözer. Bu işleme *path resolution* (ya da eski Unix kaynaklarında `namei` — "name to inode") denir ve `man 7 path_resolution` bu algoritmayı adım adım tanımlar. Her `/` işareti bir bileşen sınırıdır; kernel her adımda "şu an baktığım dizinin içinde bu isim var mı, varsa hangi inode'a işaret ediyor" sorusunu sorar (bu eşleme dizinin veri bloklarındaki `(isim, inode_no)` tablosunda durur — aşağıdaki inode bölümünde ayrıntısı var). Yürüyüşün **başlangıç noktası** yolun ilk karakterine bağlıdır:

- Yol `/` ile başlıyorsa → yürüyüş **kök dizinden** (`/`'nin inode'undan) başlar. Bu yüzden mutlak yol, sürecin o an nerede olduğundan bağımsızdır.
- Yol `/` ile başlamıyorsa → yürüyüş **sürecin o anki çalışma dizininden** (current working directory — kernel bunu her sürecin `task_struct`'ında `pwd` olarak tutar) başlar. Bu yüzden bağıl yol "nereden çalıştırdığına" göre farklı hedefe çıkar.

**5N1K çerçevesinde `cd`:**
- **Ne:** `cd`, sürecin çalışma dizinini değiştiren bir işlemdir — ama harici bir program **değildir**, kabuğun (bash) kendi içinde çalışan bir *builtin*'dir. Çünkü çalışma dizini **sürece özeldir**; harici bir program çalışsaydı, o çocuk süreç kendi dizinini değiştirip biterdi, kabuğun dizini hiç değişmezdi.
- **Nasıl:** bash arka planda `chdir()` sistem çağrısını yapar; kernel de yeni yolu yukarıdaki path-resolution ile çözüp sürecin çalışma dizini kaydını günceller.
- **Ne zaman:** her `cd` komutunda, anında.
- **Neden builtin:** yukarıda — dizin değişikliğinin **kabuğun kendi sürecinde** kalıcı olması gerektiği için.
- **Kim:** kabuk, senin adına, senin yetkilerinle. Hedef dizinde **search (`x`) izni** yoksa `chdir()` `EACCES` ile döner ("Permission denied").

**`.` ve `..` nedir?**
Her dizinin içinde görünmeyen iki özel girdi vardır (`ls -a` ile görülür):
- `.` → "şu an bulunduğum dizinin kendisi". `cd .` hiçbir yere götürmez. Asıl kullanımı `cd` değil, "bu dizini" bir argüman olarak vermektir: `./script.sh` (bulunduğun dizindeki script — `./` olmadan yazarsan kabuk `script.sh`'i `$PATH` içinde arar, bulamaz).
- `..` → "bir üst (ebeveyn) dizin". Path resolution `..`'ye geldiğinde bir seviye yukarı çıkar; `/`'nin `..`'si yine `/`'dir (kökün üstüne çıkılamaz — `man 7 path_resolution` bunu açıkça belirtir).

**`../../` ile `/` arasındaki fark:**
- `../../` → bağıldır, "şu an bulunduğum yerden **iki seviye yukarı**". Nereden çalıştırdığına göre farklı bir dizine iner. `/home/ucp/proje/src` içindeyken `cd ../../` → `/home/ucp`.
- `/` → mutlaktır, "bulunduğun yeri unut, **dosya sisteminin köküne** git". Konumdan bağımsız, tek adımda.

`cd ..`'yi art arda 5-6 kez yazmak `cd /` ile **aynı sonucu vermeyebilir** — `..`'yi kaç kez tekrarlaman gerektiği o an ağaçta ne kadar derinde olduğuna bağlıdır; `cd /` her zaman tek seferde köke götürür.

**Sık kullanılan kombinasyonlar:**
```bash
cd /etc/nginx        # mutlak: nerede olursan ol nginx dizinine gider
cd ../config          # bağıl: bir üst dizinin içindeki config'e gider
cd ../../var/log       # bağıl: iki üst dizine çık, sonra var/log'a in
cd ~                  # ev dizinine git (kısayol)
cd ~/Belgeler          # ev dizini altındaki Belgeler'e git
cd -                  # bir önceki bulunduğun dizine dön (Gün 1'de işlendi)
cd                   # parametresiz cd de ev dizinine götürür (cd ~ ile aynı)
```

> [!TIP]
> **`pwd` her zaman senin **mutlak** konumunu gösterir. Bir `cd` komutundan sonra nereye gittiğinden emin değilsen `pwd` çalıştırma alışkanlığı edin.**

### `grep` — dosya **içeriğinde** arama

**Mekanizma + tarihsel gerekçe (asıl anlatılması gereken):**
`grep`, adını `ed` metin editöründeki `g/re/p` komutundan alır — **g**lobal / **r**egular **e**xpression / **p**rint. `ed`'de `g/re/p` yazınca, verilen düzenli ifadeyle eşleşen tüm satırlar basılırdı. Ken Thompson, `ed`'in bu regex motorunu **ayrı bir araca** çıkardı (Unix 4. sürüm, ~1973). Neden ayırdı? Çünkü `ed`, düzenlemeye rastgele erişim sağlamak için **dosyanın tamamını belleğe yüklüyordu** — devasa bir log dosyasında arama yapmak için bu israftı. `grep` ise dosyayı **akış olarak (streaming), satır satır** okur; belleğe aynı anda sadece işlediği satırı (artı biraz tampon) alır. Bu yüzden `grep`, boyutu RAM'den büyük dosyalarda bile çalışır — sunucuda GB'larca log dosyasında saniyeler içinde arama yapabilmesinin sebebi doğrudan bu tasarım kararıdır.

**5N1K:**
- **Ne:** bir veya birden fazla dosyanın (ya da stdin'den gelen akışın) **içindeki metinde** bir deseni arayıp eşleşen satırları basan filtre.
- **Nasıl:** her satırı okur, deseni (sabit metin ya da regex) o satıra uygular, eşleşiyorsa basar. Regex derlemesi bir kez yapılır, sonra her satırda tekrar kullanılır.
- **Ne zaman:** talep üzerine, sen çağırdığında; bir daemon değildir.
- **Neden:** `ed`/editör içi aramanın bellek sınırını aşmak; "hangi dosyada, hangi satırda bu ifade geçiyor" sorusunu ölçeklenebilir cevaplamak.
- **Kim:** senin sürecin, senin yetkilerinle — okuma izni olmayan dosyalarda "Permission denied" satırı basar.

`fgrep` (sabit metin, regex yorumlamaz — `-F`) ve `egrep` (genişletilmiş regex — `-E`) tarihsel olarak ayrı binary'lerdi; bugün ikisi de `grep`'in bayrağıdır (`egrep`/`fgrep` komutları modern `grep`'te uyarı verir, kullanımdan kaldırılmıştır).

```bash
grep "hata" log.txt              # log.txt içinde "hata" geçen satırları bas
grep -i "hata" log.txt           # büyük/küçük harf duyarsız (Hata, HATA da yakalanır)
grep -n "hata" log.txt           # satır numarasıyla birlikte göster
grep -r "TODO" .                 # bulunduğun dizinden başlayarak TÜM alt dizinlerde ara
grep -v "debug" log.txt          # TERSİ: "debug" GEÇMEYEN satırları göster
grep -c "hata" log.txt           # kaç satırda eşleşme var, sayısını ver
grep -l "TODO" *.py              # eşleşme içeren dosya adlarını listele (içerik değil)
grep -E "hata|error" log.txt     # genişletilmiş regex: "hata" VEYA "error"
grep -F "1.2.3.4" log.txt        # sabit metin — noktalar regex "herhangi karakter" değil, gerçek nokta
```

Her parametre bir problemi çözer: `-r` "elle her dosyayı gezmekten" kurtarır, `-v` "istisnaları görmek" içindir (örn. yorum olmayan satırlar), `-c` "kaç kez oldu" sayımını script'e verir, `-l` "hangi dosyalar" sorusunu (içeriği basmadan) cevaplar. `grep` genelde `|` ile zincirlenir: `ps aux | grep nginx`.

### `find` — dosya sistemi ağacında dosya/dizin **arama**

**Mekanizma:**
`grep` **içerik** arar; `find` ise **dosyanın kendisini** (adı, tipi, boyutu, tarihi, sahibi, izni, inode'u...) dizin ağacında arar. `find` bir dizini `opendir()`+`readdir()` (kernel tarafında `getdents64` syscall'ı) ile açıp içindeki `(isim, inode_no)` girdilerini okur; her alt dizin için bunu **özyinelemeli (recursive)** tekrarlar. Bir dosyanın adı dışındaki özelliğini (boyut, tarih...) test etmesi gerektiğinde ek olarak o dosya için `stat()` çağırır — bu yüzden `find . -name "*.log"` (sadece isme bakar) ile `find . -size +100M` (her aday için `stat()` gerektirir) arasında büyük dizinlerde hız farkı olur.

**5N1K / tasarım gerekçesi:**
- **Ne:** dosya sistemi ağacını gezip, verdiğin ölçütlere uyan yolları bulan (ve isteğe bağlı üzerlerinde komut çalıştıran) araç.
- **Neden `grep`'ten ayrı:** iki farklı soru — "içinde ne yazıyor" (grep) vs "hangi dosya / nerede / ne zaman değişti / kaç MB" (find). Karıştırılırsa yanlış araca sarılırsın.
- **Neden `locate`'ten farklı (Gün 5'te işlenecek):** `find` **canlı** tarar (her seferinde güncel ama yavaş); `locate` önceden üretilmiş indeksi sorgular (hızlı ama güncelliği garanti değil).
- **Kim:** senin sürecin; okuma/search izni olmayan dizinlerde "Permission denied" satırı basıp o dalı atlar.

```bash
find /home -name "*.txt"            # /home altında adı .txt ile biten her şey
find . -type f                       # sadece dosyalar (d=dizin, l=symlink)
find . -type d -name "cache"         # adı "cache" olan dizinler
find /var/log -mtime -7              # son 7 gün içinde değişmiş dosyalar
find /var/log -mtime +30 -name "*.log"   # 30 günden ESKİ .log dosyaları
find . -size +100M                   # 100MB'tan büyük dosyalar
find . -name "*.tmp" -delete         # ⚠️ bulunanları DOĞRUDAN SİL — önce -delete'siz çalıştır
find . -name "*.sh" -exec chmod +x {} \;   # bulunan her dosyaya komut uygula ({} = bulunan dosya)
find . -name "*.sh" -exec chmod +x {} +     # + : bulunanları TEK komuta toplu ver (daha hızlı)
```

> [!WARNING]
> **`-delete` veya `-exec rm` kullanmadan önce mutlaka aynı `find` komutunu bu bayraklar OLMADAN çalıştırıp hangi dosyaların eşleştiğini gözden geçir. `find` geri alma sunmaz.**

### `diff` — iki dosyayı karşılaştırma

**Mekanizma + tarihsel gerekçe:**
`diff`, 1974'te Bell Labs'te Douglas McIlroy ve James Hunt tarafından yazıldı; algoritması 1976'daki "An Algorithm for Differential File Comparison" makalesinde yayımlandı. Çözdüğü matematiksel problem **en uzun ortak alt dizi** (longest common subsequence, LCS): iki dosyada da **aynı sırada** geçen en büyük satır kümesini bulur; bu kümede olmayan satırlar "silinmiş" (`<`) veya "eklenmiş" (`>`) olarak raporlanır. Naif LCS çözümü iki dosyanın satır sayısının çarpımı kadar iş yapar; Hunt–McIlroy, sadece "kritik aday eşleşmeler"e bakarak bunu pratikte çok daha hızlı hale getirir. `diff` **satır** temellidir (karakter değil) çünkü kaynak kod / config dosyaları satır satır anlamlıdır ve satır granülerliği hem hızlı hem insan-okunur çıktı verir.

**5N1K:**
- **Ne:** iki metin dosyası (ya da iki dizin) arasındaki farkı, ortak kısımları tekrar basmadan gösteren araç.
- **Nasıl:** LCS hesaplar, farkları hunk'lar halinde raporlar.
- **Neden:** "bu config değişikliğinden önce/sonra ne değişti", "iki sunucudaki dosya neden farklı davranıyor" sorularını gözle taramadan cevaplamak; ayrıca `patch` ile uygulanabilir yamalar üretmek.
- **Kim:** senin sürecin. Çıkış kodu: `0` = birebir aynı, `1` = fark var, `2` = hata — bu yüzden script'lerde `diff -q a b >/dev/null && echo aynı` kalıbı çalışır.

```bash
diff dosya1.txt dosya2.txt
# < ile başlayan satırlar → sadece dosya1.txt'de
# > ile başlayan satırlar → sadece dosya2.txt'de

diff -u eski.conf yeni.conf     # "unified" format — git/patch'in kullandığı standart biçim
diff -r dizin1/ dizin2/         # iki dizini recursive karşılaştır
diff -q dizin1/ dizin2/         # sadece HANGİ dosyalar farklı, içeriği basma
diff --color -u a b             # farkları renklendir
```

`diff` Gün 5'te tekrar geçecek (`curl`/`wget`/`diff` bloğunda) — orada aynı sıfırdan anlatım yerine yeni bayrak kombinasyonları (`-Nur`) ele alınıyor.

### Hardlink ve symlink — inode üzerinden düşünmek gerekir

**Mekanizma:**
Her dosyanın gerçek içeriği ve meta verisi bir **inode**'da tutulur (aşağıda ayrıntısı var); dosya adı ise sadece bir dizin girdisinde `(isim → inode_no)` eşlemesidir.

**Hardlink (`ln kaynak hedef`):** var olan bir inode'a **ikinci bir isim** ekler. Kernel bunu `link()` syscall'ıyla yapar: bulunulan dizine yeni bir `(isim, inode_no)` satırı ekler ve inode'un **link sayacını (`st_nlink`)** bir artırır — **hiçbir veri kopyalanmaz**. İki isim de **tamamen eşdeğerdir**; "asıl" ve "kopya" diye bir hiyerarşi yoktur. Bir ismi `rm` ile silmek `st_nlink`'i bir azaltır; veri **ancak** `st_nlink` 0'a düşünce **ve** o inode'u açık tutan hiçbir süreç kalmayınca serbest bırakılır (Gün 1'deki "link sayısı" tam olarak bu sayaçtır).

**Hardlink'in iki katı kısıtı (`man 2 link`):**
1. **Farklı dosya sistemleri arasında kurulamaz** (`EXDEV`). Neden: inode numarası **sadece kendi dosya sistemi içinde** anlamlıdır; `/dev/sda1`'deki 4242 numaralı inode ile `/dev/sdb1`'deki 4242 tamamen farklı dosyalardır. Bir dizin girdisi başka bir dosya sistemindeki inode numarasına işaret edemez.
2. **Dizinler için oluşturulamaz** (`EPERM`, `oldpath is a directory`). Neden: dizin ağacı **her düğümün tek ebeveyni olan bir ağaç** olarak tasarlanmıştır. Dizinlere hardlink serbest olsaydı bu bir **graf**a dönüşür, `..` belirsizleşir, `find`/`du`/yedekleme araçları kapanmayan döngülere girer, `fsck`'in tutarlılık algoritmaları çok karmaşıklaşırdı.

**Symlink (`ln -s kaynak hedef`):** kendi **ayrı bir inode'u olan**, içeriği sadece "hedef yol string'i" olan küçük özel bir dosyadır. Path resolution bir symlink inode'una geldiğinde, o string'i yürüyüşe ekleyip devam eder (`man 7 path_resolution`; art arda en fazla 40 symlink çözülür, sonra `ELOOP`). Hedef silinirse symlink **kırık (broken)** kalır — açmaya çalışınca "No such file or directory".

**5N1K — hangisi ne zaman:**
- **Ne:** hardlink = aynı inode'a ikinci isim; symlink = başka bir yolu gösteren ayrı bir mini dosya.
- **Neden hardlink:** aynı dosya sisteminde, dosyanın **gerçekten aynı veri** olması gerektiğinde; hedef silinse bile veri (başka isim varken) kaybolmasın istendiğinde.
- **Neden symlink:** farklı disk/bölümler arası kısayol gerektiğinde, dizinlere link gerektiğinde, "hedef değişebilir/silinebilir" durumunda (örn. `/usr/bin/python -> python3.13`).
- **Kim:** her ikisini de sıradan kullanıcı kendi yazma izni olan dizinde kurabilir.

```bash
ln ucptest.txt ucp.js            # hardlink: aynı inode, st_nlink artar
ln -s ucptest.txt ucp-link.js    # symlink: ayrı inode, sadece yol string'i

ls -li ucptest.txt ucp.js        # -i ile inode numaraları — AYNIysa hardlink doğrulanmış olur
ls -l ucp-link.js                # symlink satırı l ile başlar, "-> ucptest.txt" hedefi gösterir
readlink ucp-link.js             # symlink'in içindeki ham hedef string'i
```

Bu konu Gün 3'te relative/absolute symlink çözünürlüğü ve hardlink bulma (`find -inum` / `-samefile`) ile derinleştiriliyor: [Gün 3#Relative symlink çözünürlüğü — tek altın kural](Gün%203.md#relative-symlink-çözünürlüğü-tek-altın-kural).

### Disk bölme / ekleme / mount-unmount

Bu konu Gün 1'in devamında `CL-Egitim/09-disk-yonetimi.md` içinde uçtan uca (GPT/MBR, `fdisk`/`parted`, `mkfs`, `mount`, `/etc/fstab`, `umount`) satır satır işlendi — `mount`'un neden gerektiği, `/etc/fstab`'ın her sütunu, `umount` adımları orada. Burada sadece bugünkü akışın özeti:

```
Fiziksel disk (/dev/sdb)
   ↓ fdisk/parted ile BÖLME   → /dev/sdb1
   ↓ mkfs ile BİÇİMLENDİRME   → içine ext4/xfs dosya sistemi yazılır
   ↓ mount ile BAĞLAMA        → /veri gibi bir dizinden erişilir hale gelir
   ↓ umount ile ÇÖZME         → dizinden erişim koparılır, disk güvenle çıkarılabilir
```

`umount` (dikkat: "un**m**ount" değil, **`umount`** — ilk `n` yok):
```bash
sudo umount /veri
sudo umount /dev/sdb1     # aynı işi aygıt adıyla da yapabilirsin
```
"target is busy" hatası: o dizinin içinde biri duruyor ya da bir süreç orada açık bir dosya tutuyor demektir — `lsof +D /veri` ile kimin kullandığını bul (Gün 1'de işlendi).

### Bir dizinin üzerine mount edince "altta kalan" veri ne olur? (derste sorulan takip)

Diyelim `/veri`, kök diskin sıradan bir klasörü ve içine `notlarim.txt` koydun. Sonra `sudo mount /dev/sdb1 /veri` çalıştırdın. Bu andan itibaren `/veri`'ye baktığında `/dev/sdb1`'in kök dizinini görürsün; `notlarim.txt` **görünmez** olur.

**Mekanizma:** mount, veriyi **silmez** ve **taşımaz**. Kernel'in VFS katmanında her dizinin bir *mount point* olarak işaretlenip işaretlenmediği tutulur. `/veri` bir mount point olduğunda, path resolution `/veri`'ye ulaştığında **o dizinin kendi inode'unu değil, üzerine bağlanan dosya sisteminin kök inode'unu** takip eder. Alttaki eski `/veri` inode'u (ve `notlarim.txt` girdisi) yerinde durur, sadece o isim üzerinden **erişilemez** hale gelir (kavramsal olarak "üstü örtülür").

**Gizlenen veriyi görmenin yolları:**
1. **En basit — geçici `umount`:** `sudo umount /veri` çalıştırınca üstteki dosya sistemi ayrılır, alttaki `notlarim.txt` tekrar görünür. İş bitince `sudo mount /dev/sdb1 /veri` ile geri bağlanır.
2. **Diski ayırmadan — alttaki bölümü başka noktaya bağla:** eğer `/veri` ayrı bir bölümde değil kök dosya sistemindeyse, `mount --bind` ile kökün başka bir kopyasını görebilirsin: `sudo mkdir /mnt/kok && sudo mount --bind / /mnt/kok` → `/mnt/kok/veri/notlarim.txt` yolundan, `/veri`'yi hiç bozmadan gizli dosyaya ulaşırsın. (`mount --bind` bir dizini ikinci bir noktadan daha erişilebilir kılar; alttaki mount point'ler bu ikinci kopyada "örtülü" olmaz.)

### Dosya sisteminin avantaj ve dezavantajları — ve **neden** böyle tasarlanmışlar

"Dosya sistemi", diskteki ham baytları "dosya ve dizin" kavramına çeviren yazılım katmanıdır — disk kendisi sadece numaralı sektörlerden oluşan düz bir alan bilir, "dosya" diye bir şey bilmez. Farklı dosya sistemleri farklı tasarım öncelikleriyle doğdu:

| Dosya sistemi | Tasarım önceliği / **neden** | Avantaj | Dezavantaj |
|---|---|---|---|
| **ext4** | Uzun yıllık ext2/ext3 soyunun devamı — "her yerde çalışan, öngörülebilir, kurtarılabilir" hedefi | Çok olgun, en geniş araç/kurtarma desteği, **hem büyütülebilir hem küçültülebilir** | Toplam inode sayısı `mkfs` anında sabitlenir (aşağıda); çok yoğun paralel yazmada XFS kadar ölçeklenmez |
| **XFS** | 1990'larda SGI'da **çok işlemcili, çok diskli** iş istasyonları için; disk "allocation group"lara bölünür, her grup **bağımsız** yönetilir → paralel I/O | Büyük dosyalarda ve çok sayıda eşzamanlı yazmada çok hızlı; inode'ları **dinamik** ayırır (inode tükenmesi pratikte yaşanmaz); RHEL/Rocky varsayılanı | **Küçültülemez** (sadece büyütülebilir) — metadata operasyonlarında ext4'ten biraz daha CPU harcar |
| **Btrfs** | Copy-on-write tasarımı — veri asla yerinde üzerine yazılmaz, yeni bloğa yazılır | Anlık görüntü (snapshot), checksum ile veri bütünlüğü, subvolume, şeffaf sıkıştırma | Daha karmaşık; bazı iş yüklerinde performans öngörülebilir değil |
| **vfat / exfat** | Taşınabilirlik önceliği — Windows/macOS dahil her yerde okunabilsin | USB bellek / kart için evrensel uyumluluk | Linux izin modelini (owner/group/rwx), sahiplik, symlink **desteklemez** |

**Dağıtım varsayılanları (2026, güncel sürümlerde doğrulandı):**
- **Debian 13 (trixie)** ve **Ubuntu 26.04 LTS** kurulumu kök dosya sistemi için varsayılan **ext4** kullanır (XFS/Btrfs/ZFS ek paketlerle desteklenir ama varsayılan değil).
- **Rocky Linux 10 / RHEL 10** kurulumu varsayılan **XFS** kullanır (ext4 kurulumda seçenek olarak sunulur). Red Hat'in genel önerisi: "özel bir ext4 gerekçen yoksa XFS kullan."

> Eğitim notlarında "Ubuntu 24" geçiyor; güncel LTS artık **Ubuntu 26.04** (Nisan 2026). Dosya sistemi varsayılanı açısından davranış farkı yok — Ubuntu hâlâ ext4.

Kısacası "en iyi dosya sistemi" yok: büyük dosyalar/paralel I/O → XFS; genel amaç ve küçültme esnekliği → ext4; snapshot/bütünlük → Btrfs; taşınabilir USB → exfat.

### Linux dosya sistemi ve inode nedir

**Ne / neden var:**
Bir dosyanın sahibi, izinleri, boyutu, zaman damgaları ve diskteki hangi bloklarda durduğu bilgisi **inode** adlı sabit boyutlu bir yapıda saklanır. **Dosya adı inode'un içinde yoktur** — ad, bir dizinin içeriğindeki `(isim → inode_no)` kaydından ibarettir.

**Benzetme:** inode, bir kütüphane kaydı gibidir (yazar, sayfa sayısı, raf konumu — künye). Aynı kayda farklı kataloglardan farklı isimlerle atıf yapılabilir (hardlink), hepsi aynı künyeye işaret eder. Bu yüzden `mv eski yeni` (aynı dosya sisteminde) veriyi hiç taşımaz — sadece dizindeki etiketi değiştirir; inode ve veri yerinde kalır (Gün 3'te `mv`'nin bu davranışı kanıtla işleniyor).

- **Nasıl (nasıl bulunur):** kernel bir yolu path resolution ile inode'a çözer; `stat()` inode alanlarını döndürür.
- **Kim:** inode'ları dosya sistemi sürücüsü yönetir; kullanıcı doğrudan görmez, `stat`/`ls -i` ile okur.

```bash
ls -i dosya.txt          # inode numarasını göster
stat dosya.txt           # inode'daki TÜM meta veriyi ayrıntılı gör (izin, sahip, zamanlar, link sayısı)
```

### `ls` bir dizini listelerken gerçekte ne oluyor — mekanizma

`ls` bir dizini listeler; ama "listeyi nereden alıyor" sorusunun cevabı yukarıdaki inode fikrinin doğrudan uzantısıdır ve sunucu yönetiminde önemlidir.

**Bir dizinin "içeriği" nedir?** Bir dizin de **bir dosyadır**, kendi inode'u vardır, ve bu inode'un veri blokları **somut bir tablo** tutar: her satırı `(dosya adı, inode numarası)` çifti olan bir liste (buna *dizin girdisi / dirent* denir). `/etc` içinde gördüğün "fstab, passwd, hostname..." listesi kelimenin tam anlamıyla `/etc` inode'unun veri bloklarında durur.

**`ls` adım adım:**
1. `ls /etc` — kernel `/etc`'nin inode'unu path resolution ile bulur.
2. `ls`, dizini `opendir()` ile açar, `readdir()` (kernel: `getdents64`) ile `(isim, inode_no)` çiftlerini **tek tek** okur. Bu **ucuzdur** — sadece bir dosyanın içeriğini okumak gibi; isimleri almak için başka yere bakmak gerekmez.
3. Düz `ls` burada durur. Ama `ls -l`'de ekrana gelen izin/sahip/boyut/tarih **dizin girdisinde yoktur** — bunlar her dosyanın **kendi inode'unda**. Bu yüzden `ls -l`, `readdir()` ile aldığı **her isim için ayrıca bir `stat()`** yapmak zorundadır → "1 dizin okuma + N ayrı meta veri sorgusu".

**Pratik/sunucu sonucu:** bir dizinde **milyonlarca dosya** varsa, düz `ls` hızlı kalır ama `ls -l` **çok yavaşlar** (milyonlarca ekstra `stat()`). Büyük dizinlerde (`/var/spool/`, log arşivleri) `ls -l` yerine `find`'ı tercih etmenin bir nedeni budur.

```bash
strace -c ls -l /etc 2>&1 | tail -15   # ls -l'in arka planda kaç kez stat/newfstatat çağırdığını GÖZLEMLE
```

> [!TIP]
> **`strace`, bir programın kernel'e yaptığı sistem çağrılarını canlı gösterir — `ls -l`'in `getdents64` (dizin okuma) + çok sayıda `newfstatat` (her dosya için meta veri) çağrısını **gözlerinle** görürsün. Merak ettiğin herhangi bir komutta deneyebilirsin.**

### Dosya sistemine göre inode kullanımı — kritik ayrıntı

**ext4:** toplam inode sayısı `mkfs` anında **sabitlenir** ve sonradan artırılamaz. `man mke2fs`: bytes-per-inode oranı için *"it is not possible to change this ratio on a file system after it is created"*. Disk boyutuna göre otomatik hesaplanır ama sabit bir sayıdır.

**Pratik sonuç:** diskte milyonlarca **küçük** dosya oluşturursan (küçük cache/log dosyaları), disk alanı hâlâ boşken bile **inode'lar tükenebilir** — her dosya boyutundan bağımsız bir inode tüketir. Bu durumda `df -h` "%40 dolu" gösterir ama yeni dosyada "No space left on device" alırsın.

```bash
df -h        # disk ALAN doluluğu — burada boş görünebilir
df -i        # inode doluluğu — asıl sorun genelde burada (IUse% %100)
```

**XFS** bunu farklı çözer: inode'ları **dinamik** ayırır — dosyalar oluştukça ihtiyaç kadar. İnode'ların toplam dosya sistemi alanının belirli bir yüzdesini geçmesi engellenir ve bu yüzde `mkfs` sonrası ayarlanabilir. Bu yüzden "inode tükenmesi" XFS'te neredeyse hiç yaşanmaz — XFS'in disk yönetimi modülünde öne çıkmasının bir başka nedeni.

### `lsblk` ve `fdisk` kullanımı

**Mekanizma:**
- `lsblk`, verisini **sysfs**'ten (`/sys/block/` ve `/sys/class/block/`) alır — kernel'in blok aygıt modelini dışa vurduğu sanal dosya sistemi. Hiçbir diske dokunmaz, hiçbir şeyi mount etmez → **tamamen güvenlidir**, istediğin kadar çalıştırabilirsin.
- `fdisk -l`, disklerin ilk sektöründeki **bölüm tablosunu** (MBR ya da GPT) okuyup çözerek listeler — salt okunur.
- `fdisk /dev/sdb` (sadece aygıt adıyla), **etkileşimli düzenleme moduna** girer. Buradaki değişiklikler **bellekte** birikir; `w` (write) demeden diske **hiçbir şey yazılmaz**, yanlış yaptıysan `q` ile kaydetmeden çıkarsın.

```bash
lsblk                     # tüm blok cihazlarını ağaç halinde — SALT OKUNUR, güvenli
lsblk -f                  # + dosya sistemi tipi, UUID, mount noktası
lsblk -o NAME,SIZE,TYPE,MOUNTPOINTS,FSTYPE   # istediğin sütunları seç
sudo fdisk -l              # tüm disklerin bölüm tablolarını (salt okunur) listele
sudo fdisk /dev/sdb          # ETKİLEŞİMLİ mod — bölüm oluşturma/silme (CL-Egitim/09'da tuş tuş anlatıldı)
```

`lsblk` "ne var" sorusunu güvenle cevaplar; `fdisk` (etkileşimli) "değiştir" işini yapar ama `w`'ye kadar geri dönülebilir. MBR/GPT bölüm tablosu farkları Gün 3'te ayrıntılı işleniyor: [Gün 3#Dosya sistemi oluşturma — `mkfs`, MBR ve GPT](Gün%203.md#dosya-sistemi-oluşturma-mkfs-mbr-ve-gpt).

### Kaynaklar

**Bu başlık her zaman Genişletilmiş Anlatım'ın SON `###` bölümüdür** — hemen ardından `## Notlar` gelir.

- **Path resolution / `.` / `..` / mutlak-bağıl başlangıç noktası:**
  - [path_resolution(7) — man7.org](https://man7.org/linux/man-pages/man7/path_resolution.7.html) — bileşen bileşen yürüme, cwd vs kök başlangıcı, symlink'in yürüyüş ortasında çözülmesi, `/..` = `/`, 40 symlink sınırı.
- **`grep` tarihi ve tasarımı (g/re/p, `ed`'den ayrılma, streaming):**
  - [grep — Wikipedia](https://en.wikipedia.org/wiki/Grep) — `g/re/p`, Ken Thompson, Unix v4 (~1973), `ed`'in dosyayı belleğe yüklemesi vs `grep`'in akış işlemesi, `fgrep`/`egrep` → `-F`/`-E`.
  - [grep - GNU Project manual](https://www.gnu.org/software/grep/manual/grep.html) — güncel bayrak semantiği; `egrep`/`fgrep`'in kullanımdan kaldırılması.
- **`diff` algoritması ve tarihi (LCS, Hunt–McIlroy):**
  - [An Algorithm for Differential File Comparison — J. W. Hunt, M. D. McIlroy (Bell Labs, 1976)](https://www.cs.dartmouth.edu/~doug/diff.pdf) — LCS problemi, "kritik aday eşleşme" optimizasyonu.
  - [diff — Wikipedia](https://en.wikipedia.org/wiki/Diff) — 1974 Unix 5. sürüm, McIlroy & Hunt, satır temelli karşılaştırma.
- **Hardlink kısıtları (`EXDEV` = farklı dosya sistemi, `EPERM` = dizin):**
  - [link(2) — man7.org](https://man7.org/linux/man-pages/man2/link.2.html) — "Hard links... cannot span filesystems", `EXDEV` ve `EPERM` (oldpath is a directory) tanımları.
- **ext4 inode sayısının `mkfs` anında sabitlenmesi:**
  - [mke2fs(8) — man7.org](https://man7.org/linux/man-pages/man8/mke2fs.8.html) — `-i` seçeneği: "it is not possible to change this ratio on a file system after it is created".
- **XFS'in dinamik inode ayırması, küçültülememesi, RHEL/Rocky varsayılanı; ext4'ün 2³² inode sınırı:**
  - [Chapter 1. Overview of available file systems — Red Hat Enterprise Linux 10 Documentation](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/10/html-single/managing_file_systems/index) — XFS varsayılan; XFS küçültülemez; ext4 > 2³² inode desteklemez.
  - [Why is total inodes count of XFS filesystem not constant? — Red Hat Customer Portal](https://access.redhat.com/solutions/5687161) — XFS dinamik inode ayırma, yüzde ayarı `mkfs` sonrası değiştirilebilir.
- **Dağıtım varsayılan dosya sistemleri (Debian/Ubuntu ext4, Rocky XFS) ve güncel sürümler:**
  - [Debian 13 vs Ubuntu 24.04 vs Rocky Linux 10 — ComputingForGeeks](https://computingforgeeks.com/debian-ubuntu-rocky-comparison/) (ikincil — pratik karşılaştırma; birincil için yukarıdaki Red Hat dokümanı ve Debian kurulum kılavuzu).
  - [Debian Releases](https://www.debian.org/releases/) — Debian 13 "trixie" güncel stable (13.6, Temmuz 2026).
  - [Ubuntu release cycle](https://ubuntu.com/about/release-cycle) — Ubuntu 26.04 LTS güncel LTS (Nisan 2026).
  - [Rocky Linux Release and Version Guide](https://wiki.rockylinux.org/rocky/version/) — Rocky Linux 10 / 9 güncel sürümler.
- **`lsblk`/`fdisk` mekaniği (sysfs, MBR/GPT tablo okuma, etkileşimli `w`):**
  - [lsblk(8) — man7.org](https://man7.org/linux/man-pages/man8/lsblk.8.html) — sysfs'ten okuma, salt okunur.
  - [fdisk(8) — man7.org](https://man7.org/linux/man-pages/man8/fdisk.8.html) — değişikliklerin `w`'ye kadar diske yazılmaması.

Tekil bayrak/sözdizimi anlamları (örn. `grep -n` satır numarası, `find -type f`) `man grep` / `man find` / `man diff` ile doğrulanabilir; bunlar için ayrıca kaynak gösterilmedi — bu istisna sadece bu tür sabit, değişmeyen tekil ayrıntılar içindir.

## Notlar

- Bugünün ana teması: **yol (path) okuryazarlığı** (mutlak vs bağıl'ın kernel'deki path-resolution karşılığı), metin/dosya **arama araçlarının tasarım felsefesi** (`grep` `ed`'den akış işlemek için ayrıldı; `find` meta veri arar; `diff` LCS çözer), **link mekanizması** (hardlink = aynı inode'a ikinci isim + iki katı kısıt; symlink = ayrı inode'lu yol string'i) ve dünkü disk konusunun **inode/dizin-girdisi** seviyesinde derinleşmesi.
- `grep` ve `find` sık karıştırılır: "içinde ne yazıyor" → `grep`; "hangi dosya/nerede/ne zaman/kaç MB" → `find`. Birlikte de kullanılırlar: `find . -name "*.log" -exec grep -l "hata" {} +`.
- inode kavramı üç ayrı olguyu birden açıklar: hardlink'in neden "eşdeğer" olduğunu (`st_nlink`), `df -h` boşken "disk dolu" alınabileceğini (`df -i`), ve bir dizini üzerine mount edince alttaki verinin neden "kaybolmadan gizlendiğini" (VFS mount point). Bunu Gün 1'deki `ls -al` link sayısıyla birlikte düşün.

## Komutlar / Örnekler

```bash
# cd ve yol kombinasyonları
cd /var/log            # mutlak yol
cd ../..                # iki üst dizine bağıl çıkış
cd -                   # önceki dizine dön
pwd                    # her zaman mutlak konumunu doğrula

# grep — içerik arama
grep -rni "error" /var/log/
grep -v "^#" /etc/fstab      # yorum satırlarını HARİÇ TUT, geri kalanı göster
grep -F "1.2.3.4" access.log # sabit metin (nokta = gerçek nokta)

# find — dosya arama
find /home -type f -name "*.sh"
find . -mtime -1 -type f            # son 24 saatte değişen dosyalar
find . -name "*.log" -exec grep -l "hata" {} +

# diff — karşılaştırma
diff -u eski.conf yeni.conf > degisiklik.patch
diff -q a b >/dev/null && echo "aynı"

# hardlink / symlink
ln ucptest.txt ucp.js         # hardlink
ln -s ucptest.txt ucp-sym.js  # symlink
ls -li ucptest.txt ucp.js     # inode numaralarını karşılaştır
readlink ucp-sym.js

# inode / disk bilgisi
stat ucptest.txt
df -i /veri
lsblk -f
sudo fdisk -l

# mount / umount özet (ayrıntı: CL-Egitim/09-disk-yonetimi.md)
sudo mount /dev/sdb1 /veri
sudo umount /veri
sudo mount --bind / /mnt/kok   # bir dizini üzerine mount edilmiş noktanın altını görmek için
```

## Sorular / Takip Edilecekler

- [x] Oluşturulan diskin içine veri ekleyip bu diski aynı dizine mount edersek eklenen veriler gizlenir — nasıl görülür? → Cevaplandı: [Gün 2#Bir dizinin üzerine mount edince "altta kalan" veri ne olur? (derste sorulan takip)](Gün%202.md#bir-dizinin-üzerine-mount-edince-altta-kalan-veri-ne-olur-derste-sorulan-takip) (geçici `umount` ya da `mount --bind` ile alttaki bölümü ikinci noktadan görmek).
- [ ] `strace -c ls -l` çıktısını kendi VM'inde çalıştırıp, dosya sayısı arttıkça `newfstatat` çağrı sayısının nasıl büyüdüğünü gözlemle (küçük dizin vs `/usr/bin`).
