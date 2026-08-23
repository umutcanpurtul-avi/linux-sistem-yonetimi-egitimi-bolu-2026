---
tags: [linux, egitim, disk, depolama]
modul: 09
durum: tamamlandi
---

# 09 — Disk Yönetimi

> **Ön koşul:** [04-dosya-sistemi](04-dosya-sistemi.md)
> **Süre:** ~4 saat
> ⚠️ **Bu modülün tamamını mutlaka ikinci diskte (`/dev/sdb`) çalış. Snapshot al.**

## Hedefler

- [ ] Disk/bölüm/dosya sistemi katmanlarını ayırt ediyorum
- [ ] MBR ve GPT farkını biliyorum, doğru aracı seçiyorum
- [ ] Disk ekleyip bölümleyip biçimlendirip kalıcı bağlayabiliyorum
- [ ] `mount` işleminin ne yaptığını, neden gerektiğini ve nasıl geri alınacağını biliyorum
- [ ] Swap alanı oluşturabiliyorum
- [ ] Kota uygulayabiliyorum
- [ ] `dd`, `rsync`, `cp` ile yedek alıp geri dönebiliyorum
- [ ] `fsck` ile dosya sistemi onarabiliyorum

---

## 1. Katmanlar — kafa karışıklığının kaynağı

Disk yönetimindeki en büyük kafa karışıklığı, insanların "disk", "bölüm", "dosya
sistemi" ve "dizin" kelimelerini birbirinin yerine kullanmasından gelir. Bunlar
**dört ayrı katmandır** ve her biri ayrı bir komutla, ayrı bir adımda kurulur:

```
Fiziksel disk        /dev/sdb
      ↓ bölümleme (fdisk / parted)
Bölüm                /dev/sdb1
      ↓ biçimlendirme (mkfs)
Dosya sistemi        ext4 / xfs
      ↓ bağlama (mount)
Dizin                /veri
```

Bunu bir bina gibi düşün:

1. **Fiziksel disk** = boş bir arsa. Henüz üzerinde hiçbir şey yok, sadece "burada
   yer var" bilgisi var (`lsblk` bunu gösterir).
2. **Bölümleme (partitioning)** = arsayı parsellere ayırmak. "Bu köşe 2 GB'lık bir
   parsel, şu köşe 1 GB'lık başka bir parsel" demek. Henüz üzerine bina (dosya
   sistemi) yapılmadı, sadece sınırlar çizildi.
3. **Biçimlendirme (`mkfs`)** = parselin üzerine bina inşa etmek. Artık içine dosya
   koyabileceğin bir yapı (ext4, xfs gibi bir dosya sistemi) var. Ama binanın hâlâ
   bir sokak adresi yok — şehir haritasına (dizin ağacına) bağlı değil.
4. **Bağlama (`mount`)** = binaya bir sokak adresi vermek (`/veri` gibi). Artık o
   binaya "git /veri'ye" diyerek ulaşabilirsin.

Her katman **ayrı bir işlemdir ve birbirinin yerine geçmez.** "Disk ekledim ama
görünmüyor" diye şikayet edenlerin neredeyse tamamı bu zincirin bir halkasını
atlamıştır — en sık atlanan halka da son adım olan **mount**'tur: disk bölümlenmiş,
biçimlendirilmiş ama hiçbir dizine bağlanmamıştır, bu yüzden `ls /veri` boş görünür
çünkü `/veri` aslında hâlâ eski, boş bir dizindir.

> [!NOTE]
> **Bu modülde en çok kafa karıştıran adım — mount — ayrıca 3. bölümde tek**
> başına, çok daha ayrıntılı ele alınıyor. Orayı atlamadan oku.

### Aygıt adları

Linux'ta her disk `/dev/` altında bir dosya olarak görünür (Unix felsefesi: "her şey
bir dosyadır" — bir disk sürücüsü bile). Hangi ismin ne anlama geldiğini bilmek,
yanlış diske komut çalıştırmamak için hayati önemdedir:

| Ad | Tip |
|---|---|
| `/dev/sda`, `/dev/sdb` | SATA / SAS / USB disk |
| `/dev/nvme0n1` | NVMe SSD (bölümü: `nvme0n1p1` — `p` var!) |
| `/dev/vda` | KVM/QEMU sanal disk (virtio) |
| `/dev/xvda` | Xen / AWS EC2 |
| `/dev/mapper/vg-lv` | LVM mantıksal birim |

Bu isimlendirmenin mantığı şöyle işler: `sda` sistemin bulduğu ilk SCSI/SATA
diskidir, `sdb` ikincisidir, vs. Bir diskin **bölümleri** ise disk adının sonuna
sayı eklenerek adlandırılır: `/dev/sdb1` = `sdb` diskinin 1. bölümü, `/dev/sdb2` =
2. bölümü. NVMe'de isimlendirme biraz farklıdır çünkü NVMe diskler zaten sayı
içerir (`nvme0n1`); bölüm eklerken karışıklık olmasın diye araya bir `p` konur
(`nvme0n1p1`).

Bu isimlere güvenerek kalıcı yapılandırma **yazma** — aşağıda "Neden UUID"
bölümünde bunun neden tehlikeli olduğunu ayrıntılı anlatıyoruz.

```bash
lsblk                    # ⭐ en okunaklı disk/bölüm ağacı
lsblk -f                 # + dosya sistemi ve UUID
blkid                    # UUID ve tip
fdisk -l                 # tüm diskler ve bölüm tabloları
cat /proc/partitions
lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT,UUID
```

Her komutun ne işe yaradığını netleştirelim, çünkü ilk bakışta hepsi "aynı şeyi"
yapıyor gibi görünür:

- **`lsblk`** ("list block devices") — disk ve bölümleri **ağaç** halinde gösterir,
  hangi bölümün hangi diske ait olduğunu görsel olarak en net veren komuttur. Günlük
  kullanımda ilk başvuracağın komut budur.
- **`lsblk -f`** — aynı ağaca dosya sistemi tipini (ext4/xfs/swap) ve UUID'i ekler.
  "Bu bölüm zaten biçimlendirilmiş mi, hangi UUID'e sahip?" sorusunun cevabı.
- **`blkid`** — ağaç göstermez, düz bir liste olarak her aygıtın UUID'ini ve tipini
  basar. `/etc/fstab` yazarken UUID'i buradan kopyalarsın.
- **`fdisk -l`** — bölüm **tablosunun** kendisini (başlangıç/bitiş sektörleri, boyut,
  tip kodu) gösterir; `lsblk`'ten daha ham/teknik bir görünümdür.
- **`cat /proc/partitions`** — kernel'in o an gördüğü bölümlerin en ham hâli;
  diğer araçlar çalışmıyorsa (nadiren) son çare.

---

## 2. MBR vs GPT

Bir bölüm tablosu oluşturmadan önce **hangi formatta** bir tablo oluşturacağına
karar vermelisin. Bunu, bir defterin sayfa düzenini seçmeye benzet: MBR eski,
sınırlı satır sayısı olan küçük bir not defteri; GPT ise modern, sınırsız sayfa
ekleyebildiğin, yedek kopyası da olan bir defter.

| | MBR (msdos) | GPT |
|---|---|---|
| Maksimum disk | **2 TB** | 9.4 ZB (pratikte sınırsız) |
| Bölüm sayısı | 4 birincil (veya 3 + genişletilmiş) | 128 |
| Yedek tablo | Yok | Var (diskin sonunda) |
| Önyükleme | BIOS | UEFI (BIOS de olur) |
| Araç | `fdisk` | `gdisk`, `parted` (modern `fdisk` de destekler) |

Bu tablodaki her satırın pratikte ne anlama geldiğini açalım:

- **Maksimum disk boyutu:** MBR, disk adreslerini 32 bit ile tutar; bu matematiksel
  olarak 2 TB'tan büyük bir diski tanıyamaman anlamına gelir — disk 4 TB olsa bile
  MBR ile bölümlersen sadece ilk 2 TB'ını kullanabilirsin, gerisi "görünmez" kalır.
  GPT 64 bit adresleme kullanır, bu yüzden pratikte hiçbir zaman sınıra çarpmazsın.
- **Bölüm sayısı:** MBR tablosunda fiziksel olarak sadece 4 "birincil bölüm" slotu
  vardır. Daha fazla bölüm istiyorsan bunlardan birini "genişletilmiş bölüm" yapıp
  içine "mantıksal bölümler" eklemek zorunda kalırsın — karmaşık ve eski bir çözüm.
  GPT'de böyle bir sınırlama yok, doğrudan 128 bölüme kadar tanımlayabilirsin.
- **Yedek tablo:** MBR'de bölüm tablosu sadece diskin en başındaki 512 baytta
  tutulur — o sektör bozulursa **tüm disk verisine erişimi kaybedersin**, veri
  aslında hâlâ orada olsa bile hangi bölümün nerede başladığını bilemezsin. GPT
  tabloyu hem diskin başına hem sonuna yazar; biri bozulursa diğerinden otomatik
  onarılabilir.
- **Önyükleme:** MBR sadece eski BIOS önyüklemesini destekler. GPT, modern UEFI
  önyüklemesi için gereklidir (ama "hybrid" modda BIOS ile de çalışabilir). Bu
  yüzden yeni bir bilgisayara/VM'e Linux kurarken firmware UEFI ise disk GPT
  olmalıdır — aksi halde kurulum ya başarısız olur ya da garip şekilde önyüklenmez.

> **Kural:** Yeni sistemde her zaman **GPT** kullan. 2 TB üstü diskte MBR zaten
> mümkün değil. Modern `util-linux` `fdisk`'i GPT destekler, ama `parted`/`gdisk`
> daha nettir.

Peki MBR halen neden var? Çünkü çok eski sistemlerle (örneğin BIOS-only, UEFI
desteklemeyen donanım) uyumluluk gerekebilir. Sen bir eğitim/lab ortamında
çalışıyorsan bu senin sorunun olmayacak — her zaman GPT seç.

---

## 3. Yeni disk ekleme — uçtan uca

Bu bölüm, 1. bölümdeki dört katmanı (disk → bölüm → dosya sistemi → mount) sırayla,
gerçek komutlarla uygulamandır. Her adımı atlamadan, önceki adımın çıktısını
doğrulayarak ilerle.

### Adım 0: Diski gör

Önce eklediğin diskin sistem tarafından **görüldüğünden** emin ol. Bir VM'e disk
eklemek fiziksel dünyada bir SATA kablosunu takmaya benzer — kabloyu taktın ama
işletim sistemi henüz "yeni bir cihaz var" diye fark etmemiş olabilir, özellikle
sistemi kapatmadan (VM açıkken) disk eklediysen.

```bash
lsblk                                    # sdb var mı
# Hipervizörde disk ekledin ama görünmüyorsa yeniden tarat:
echo "- - -" | sudo tee /sys/class/scsi_host/host0/scan
sudo partprobe
```

`lsblk` çıktısında `sdb` diye bir satır **yoksa**, kernel'in SCSI veri yolunu
yeniden taramasını istersin (`echo "- - -" > .../scan` — bu üç tire "herhangi bir
kanal, herhangi bir hedef, herhangi bir LUN" anlamına gelir, yani "her şeyi
yeniden tara" demektir). `partprobe` ise kernel'e mevcut disklerdeki bölüm
tablosunu yeniden okumasını söyler — bir sonraki adımda bölüm oluşturduktan sonra
da bu komutu tekrar kullanacaksın.

### Adım 1: Bölüm oluştur

Artık boş arsamız (`/dev/sdb`) görünür durumda. Şimdi üzerine parsel (bölüm)
çizeceğiz. İki yol var: `parted` (betiklenebilir, tek satırda çalışır) veya
`fdisk` (etkileşimli, menüden seçim yaparsın). İkisi de aynı sonucu üretir, tercih
meselesidir.

**parted ile (GPT, önerilen):**
```bash
sudo parted /dev/sdb --script mklabel gpt
sudo parted /dev/sdb --script mkpart primary ext4 1MiB 100%
sudo parted /dev/sdb print
```
Satır satır: `mklabel gpt` diske boş bir GPT tablosu yazar (bölüm tablosunun
"türünü" belirler — henüz bölüm yok, sadece boş bir defter açılmış olur).
`mkpart primary ext4 1MiB 100%` bu tablonun içine, 1MiB'den (ilk 1MiB hizalama
için boş bırakılır, performans/uyumluluk nedeniyle) diskin **sonuna kadar
(`100%`)** tek bir bölüm ekler; `ext4` burada sadece bölüme "bu tip için ayrıldı"
etiketini koyar, gerçek biçimlendirme değildir — biçimlendirme bir sonraki adımda
`mkfs` ile yapılır. `--script` bayrağı, `parted`'ı etkileşimli soru sormadan,
verdiğin komutları doğrudan uygulayacak şekilde çalıştırır.

**fdisk ile (etkileşimli):**
```bash
sudo fdisk /dev/sdb
```
| Tuş | İşlev |
|---|---|
| `m` | Yardım |
| `g` | Yeni **GPT** tablosu (`o` = MBR) |
| `n` | Yeni bölüm |
| `p` | Bölümleri listele |
| `t` | Bölüm tipini değiştir (`8e` LVM, `82` swap) |
| `d` | Bölüm sil |
| `w` | **Yaz ve çık** ⭐ |
| `q` | Kaydetmeden çık ⭐ kurtarıcı |

`fdisk` açıldığında bir komut istemi (`Command (m for help):`) görürsün ve
yukarıdaki harfleri tek tek basarak ilerlersin: önce `g` ile boş bir GPT tablosu
oluşturursun, sonra `n` ile yeni bir bölüm eklersin (bölüm numarası, başlangıç
sektörü, bitiş sektörü/boyut soracak — çoğunlukla varsayılanları Enter'la
geçebilirsin, boyut için `+2G` gibi bir değer de girebilirsin), `p` ile o ana
kadar ne yaptığını **diske yazmadan** önizleyebilirsin.

> `w` demeden hiçbir şey diske yazılmaz. Yanlış yaptıysan `q` ile çık.

Bu, `fdisk`'in en değerli özelliğidir: `n`, `d`, `t` gibi komutlarla istediğin
kadar "prova" yapabilirsin, hiçbiri diske dokunmaz. Sadece `w` tuşuna bastığın an
değişiklikler kalıcı olarak yazılır. Bir hata yaptığını fark edersen `q` ile hiçbir
şey kaydetmeden çıkarsın — disk `fdisk`'e girmeden önceki hâliyle kalır.

```bash
sudo partprobe /dev/sdb      # kernel'e yeni bölüm tablosunu okut
lsblk                        # /dev/sdb1 göründü mü
```
`partprobe`'u burada tekrar çalıştırmanın sebebi: bölüm tablosunu diske yazdın
ama çalışan kernel'in bellekteki bölüm haritası hâlâ eski olabilir. `partprobe`
kernel'e "git bölüm tablosunu tekrar oku" der. Bunu atlarsan bazen `mkfs.ext4
/dev/sdb1` komutu "böyle bir aygıt yok" hatası verir, çünkü kernel `/dev/sdb1`'in
var olduğunu henüz bilmiyordur.

### Adım 2: Dosya sistemi oluştur

Bölüm artık var ama içi boş, kullanılamaz durumda — tıpkı boş bir parselin
üzerinde henüz bina olmaması gibi. `mkfs` ("make filesystem") bu boş alanın
üzerine, dosya ve dizinleri organize edecek gerçek bir yapı (dosya sistemi) inşa
eder: hangi baytların hangi dosyaya ait olduğunu takip eden tablolar, dizin
girdileri, boş alan haritası gibi iç mekanizmaları oluşturur.

```bash
sudo mkfs.ext4 /dev/sdb1
sudo mkfs.xfs  /dev/sdb1
sudo mkfs.xfs -f /dev/sdb1              # üzerinde FS varsa zorla
sudo mkfs.ext4 -L VERI /dev/sdb1        # etiketle
sudo mkfs.vfat -F32 /dev/sdb1           # Windows uyumlu (USB)
```

`-f` bayrağı önemlidir: `mkfs`, üzerinde zaten bir dosya sistemi izi bulduğu bir
bölümü **varsayılan olarak reddeder** (yanlışlıkla dolu bir diski silmeni
engellemek için bir güvenlik freni). Gerçekten üzerine yazmak istediğinden
eminsen `-f` ile bu freni bilerek aşarsın. `-L` bir etiket (isim) verir; bu ismi
sonradan `lsblk -f` çıktısında veya `/dev/disk/by-label/VERI` yolunda görürsün —
UUID kadar güvenilir değildir (iki bölüme aynı etiketi verebilirsin, bu çakışmaya
yol açar) ama insan gözüyle tanımayı kolaylaştırır.

| Dosya sistemi | Kullanım | Küçültme | Not |
|---|---|---|---|
| **ext4** | Debian/Ubuntu varsayılanı, genel amaçlı | ✅ | En olgun, her yerde çalışır |
| **XFS** | RHEL 7+ varsayılanı | ❌ | Büyük dosya ve paralel I/O'da hızlı |
| **Btrfs** | Snapshot, checksum, subvolume | ✅ | SUSE varsayılanı, Fedora masaüstü |
| **ZFS** | Kurumsal depolama, RAID+FS | ✅ | Lisans nedeniyle kernel'de değil |
| **vfat/exfat** | USB, Windows paylaşımı | — | İzin/sahiplik desteklemez |

"Küçültme" sütunu kritik bir ayrımdır ve genelde göz ardı edilir: bir dosya
sistemini **büyütmek** (genişletmek) hemen hemen her zaman mümkündür (disk
alanı boşsa), ama bazı dosya sistemlerini sonradan **küçültmek** mümkün
değildir. XFS bu konuda kesin: küçültme fonksiyonu dosya sistemine hiç
eklenmemiştir, geliştiricileri bunu bilinçli bir tasarım kararı olarak
belirtir. Yani bir XFS bölümünü 100 GB yaptıktan sonra "aslında 50 GB
yetermiş" deyip küçültemezsin.

> ⚠️ **XFS küçültülemez.** RHEL'de LVM birimini fazla büyüttüysen geri dönüş yok:
> yedek al, yeniden oluştur, geri yükle. Bu tek fark, kurulum aşamasında dosya
> sistemi seçimini önemli kılar.

Peki hangisini seçmelisin? Pratik kural: **RHEL/Rocky/Alma ailesinde XFS ile
git** (dağıtımın varsayılanı, en çok test edilen, kurumsal destek dokümanlarının
hedeflediği FS budur). **Debian/Ubuntu ailesinde ext4 ile git** (varsayılan,
olgun, geniş araç desteği var). Kendi başına bir sunucu kuruyorsan ve gelecekte
küçültme ihtimali varsa (ör. bir LV'yi test amaçlı büyük açtın, sonra
"toparlamak" isteyebilirsin) ext4/Btrfs tercih et.

### Adım 3: Bağla (mount) — bu modülün en kritik adımı

Buraya kadar diskin var, bölümlendi, üzerine bir dosya sistemi de inşa edildi.
Ama şu an bu dosya sistemine **hiçbir şekilde erişemezsin** — çünkü dizin
ağacında (yani `/` ile başlayıp `cd` ile gezdiğin o tanıdık hiyerarşide) hiçbir
yere bağlı değil. `mount` tam olarak bunu çözer.

**Benzetme:** `/dev/sdb1`'i bir USB bellek gibi düşün. USB'yi bilgisayara
taktığında (bu = disk sistemde görünür hale geldi, `lsblk` ile görürsün) henüz
"içine giremezsin" — önce bir sürücü harfi/bağlama noktası ataması gerekir.
`mount`, bu USB'nin içeriğini, dizin ağacındaki **var olan boş bir klasörün**
üzerine "yansıtır". O klasöre (`/veri` diyelim) girdiğinde, aslında oradaki
dosyalar `/veri` dizininde fiziksel olarak durmuyor — sen `/dev/sdb1`'in
içeriğine bakıyorsun, sadece `/veri` üzerinden erişiyorsun.

```bash
sudo mkdir -p /veri
sudo mount /dev/sdb1 /veri
df -h /veri
mount | grep sdb1
```

Adım adım ne oluyor:

1. **`mkdir -p /veri`** — bağlama noktası (mount point) olacak boş bir dizin
   oluşturursun. Bu dizin **zorunlu olarak önceden var olmalıdır**; `mount` senin
   için dizin oluşturmaz. `-p` bayrağı, üst dizinler yoksa onları da oluşturur ve
   dizin zaten varsa hata vermez.
2. **`mount /dev/sdb1 /veri`** — asıl bağlama işlemi. Sözdizimi her zaman
   `mount KAYNAK HEDEF` şeklindedir: önce hangi aygıtı/dosya sistemini
   bağlayacağını (`/dev/sdb1`), sonra nereye bağlayacağını (`/veri`) söylersin.
3. **`df -h /veri`** — bağlamanın gerçekten işe yarayıp yaramadığını doğrularsın.
   `df` ("disk free") o dizinin hangi aygıta ait olduğunu ve ne kadar boş yer
   kaldığını gösterir; eğer `/veri` hâlâ kök dosya sisteminin (`/dev/sda1` gibi)
   bir parçası olarak görünüyorsa mount **başarısız olmuştur**.
4. **`mount | grep sdb1`** — sistemdeki tüm aktif bağlamaları listeleyen `mount`
   komutunu, sadece ilgilendiğin aygıta göre filtrelersin; bağlama seçeneklerini
   (rw, relatime vb.) burada görürsün.

**Çok kritik bir nokta — boş dizin şartı:** Bağlama noktası olarak seçtiğin dizin
zaten dosya içeriyorsa (örneğin `/veri` dizininde daha önce oluşturduğun bir
`notlar.txt` varsa), mount işleminden sonra o dosyalar **silinmez** ama
**görünmez** hale gelir — çünkü artık `/veri` üzerinden `/dev/sdb1`'in içeriğine
bakıyorsun, eski içerik "altta", erişilemez durumda kalır. `umount` yaptığında
eski dosyalar tekrar ortaya çıkar. Bu yüzden pratikte mount noktası olarak hep
**boş** dizinler kullanılır, kafa karışıklığını önlemek için.

Bu bağlama **geçicidir** — reboot'ta kaybolur. Yani şu an yaptığın işlem sadece
"şu an çalışan sistemin belleğindeki" bağlama tablosuna bir girdi ekledi. Sistemi
kapatıp açtığında bu bilgi sıfırlanır, `/veri` tekrar boş, hiçbir şeye bağlı
olmayan sıradan bir dizine döner. Bunu kalıcı yapmak için 4. adıma geçmen gerekir.

### Adım 4: Kalıcı yap — `/etc/fstab`

Az önce yaptığın mount'un reboot'ta kaybolmaması için, sisteme "her açılışta bu
aygıtı otomatik olarak şu dizine bağla" demen gerekir. Bunun için kullanılan
dosya `/etc/fstab`'tır ("file systems table" — dosya sistemleri tablosu).
Sistem her açıldığında bu dosyayı okur ve içindeki her satır için otomatik bir
`mount` komutu çalıştırır; yani bu dosya aslında "açılışta çalıştırılacak mount
komutlarının" bir listesidir, sadece komut satırı yerine tablo formatında yazılır.

```bash
sudo blkid /dev/sdb1
# /dev/sdb1: UUID="a1b2c3d4-..." TYPE="ext4"

sudo cp /etc/fstab /etc/fstab.bak        # ⭐ ÖNCE YEDEK
sudo vi /etc/fstab
```

Yedek almayı asla atlama: `/etc/fstab` bozulursa sistem açılışta ciddi sorun
yaşar (aşağıda "En tehlikeli hata" kutusunda tam olarak ne olduğunu anlatıyoruz).
Bir satırı yanlış yazıp reboot edersen, `fstab.bak`'tan eski hâline dönebilmen
seni kurtarır.

```
UUID=a1b2c3d4-...   /veri   ext4   defaults   0 2
      │              │       │       │        │ └─ fsck sırası (0=kontrol etme, 1=kök, 2=diğer)
      │              │       │       │        └─ dump (neredeyse hep 0)
      │              │       │       └─ seçenekler
      │              │       └─ dosya sistemi tipi
      │              └─ bağlama noktası
      └─ aygıt (UUID kullan!)
```

Bu satırın altı sütununu birer birer açalım, çünkü her biri sistemin açılış
davranışını etkiler:

1. **Aygıt (UUID)** — hangi bölümün bağlanacağı. `/dev/sdb1` yerine neden UUID
   kullanıldığını aşağıda ayrıca anlatıyoruz.
2. **Bağlama noktası** — hangi dizine bağlanacağı (`/veri`). Bu dizin sistem
   açılırken otomatik olarak var olmalıdır; genelde zaten yoksa oluşturman
   gerekir (yukarıdaki `mkdir -p` adımı).
3. **Dosya sistemi tipi** — `mount`'a "bunu ext4 olarak yorumla" der. Yanlış
   yazarsan (örn. `xfs` bölümüne `ext4` yazarsan) bağlama başarısız olur.
4. **Seçenekler** — bağlamanın davranışını ince ayarlar (aşağıdaki tabloda
   ayrıntılı).
5. **Dump** — çok eski bir yedekleme aracının (`dump` komutu) kullandığı bir
   bayraktır; günümüzde neredeyse hiç kullanılmaz, gelenek olarak `0` yazılır.
6. **fsck sırası** — sistem açılırken bu dosya sistemi otomatik kontrol
   (`fsck`) edilsin mi, edilecekse hangi sırada? `0` = hiç kontrol etme, `1` =
   kök dosya sistemi için ayrılmıştır (ilk kontrol edilen), `2` = diğer tüm
   dosya sistemleri için kullanılır (kökten sonra kontrol edilirler). XFS zaten
   kendi tutarlılık mekanizmasına sahip olduğu için genelde bu alana `0`
   yazılır, `fsck.xfs` gerçek bir kontrol yapmaz.

> ⚠️ **Neden UUID, neden `/dev/sdb1` değil?** Aygıt adları açılışta değişebilir
> (disk ekledin, sıra kaydı, USB taktın). UUID dosya sistemine gömülüdür, sabittir.
> `/dev/sdb1` yazarsan bir gün sistem yanlış diski `/veri`'ye bağlar.

Bunu somutlaştıralım: Diyelim sistemin iki diski var, `sda` (sistem diski) ve
`sdb` (senin `/veri` bölümün). Bir gün bu sunucuya üçüncü bir disk eklendi ve o
disk, boot sırasında `sdb` olarak algılandı; senin eski `sdb`'in ise `sdc` oldu.
Eğer `/etc/fstab`'a `/dev/sdb1` yazmışsan, sistem artık **yanlış diski**
`/veri`'ye bağlar — hiçbir hata vermeden, sessizce. UUID ise dosya sisteminin
kendi içine, biçimlendirme sırasında gömülen, o dosya sistemine özel, değişmeyen
bir kimliktir; disk hangi SATA portuna takılırsa takılsın, hangi sırada
algılanırsa algılansın aynı kalır. Bu yüzden **her zaman UUID kullan.**

**Sık kullanılan mount seçenekleri:**

| Seçenek | Anlamı |
|---|---|
| `defaults` | rw, suid, dev, exec, auto, nouser, async |
| `noexec` | İçindeki dosyalar çalıştırılamaz — `/tmp` için güvenlik ⭐ |
| `nosuid` | SUID bitleri yok sayılır |
| `nodev` | Aygıt dosyaları yok sayılır |
| `ro` | Salt okunur |
| `noatime` | Erişim zamanını yazma — **performans** ⭐ |
| `nofail` | Disk yoksa açılış takılmasın ⭐ |
| `_netdev` | Ağ diski, ağ hazır olunca bağla (NFS/iSCSI) |

Bu seçeneklerin her biri, aslında bir güvenlik veya performans kararıdır:

- **`defaults`** aslında tek bir seçenek değil, yedi seçeneğin kısayoludur
  (satırın altında açık şekilde yazılmıştır). Çoğu zaman bunu yazmak yeterlidir.
- **`noexec`** — o bölümdeki hiçbir dosyanın program olarak çalıştırılamayacağı
  anlamına gelir. `/tmp` gibi herkesin yazabildiği dizinlerde, birinin oraya
  kötü amaçlı bir çalıştırılabilir dosya koyup çalıştırmasını engellemek için
  kullanılır — bir güvenlik önlemidir.
- **`noatime`** — normalde Linux, bir dosyayı sadece **okuduğunda bile** o
  dosyanın "son erişim zamanı" bilgisini diske yazar. Çok sık okunan dosyalarda
  (log dizinleri, veritabanı dosyaları) bu gereksiz bir disk yazma yüküdür.
  `noatime` bu davranışı kapatır, performans kazandırır. Çoğu üretim sunucusunda
  varsayılan olarak eklenir.
- **`nofail`** — bu seçenek olmadan, eğer açılış sırasında fstab'daki bir aygıt
  **bulunamazsa** (disk çıkarılmış, USB takılı değil, ağ diski erişilemez),
  sistem açılışı **durur ve emergency mode'a düşer**. `nofail` ile, o aygıt
  bulunamasa bile sistem normal açılmaya devam eder, sadece o mount atlanır. USB
  disk, harici depolama gibi "her zaman takılı olmayabilecek" aygıtlarda bunu
  kullanmak neredeyse zorunludur.
- **`_netdev`** — ağ üzerinden erişilen dosya sistemleri (NFS, iSCSI) için,
  sistemin ağ arayüzü hazır olana kadar bağlamayı ertelemesini sağlar. Bu
  olmadan sistem, ağ henüz ayağa kalkmadan o mount'u denemeye çalışıp
  başarısız olabilir.

```
UUID=...  /veri  ext4  defaults,noatime,nofail  0 2
```

### Adım 5: **Test et — bu adımı atlama**

```bash
sudo umount /veri
sudo mount -a          # ⭐ fstab'daki her şeyi bağlamayı DENE
df -h
```

Neden önce `umount` yapıp sonra `mount -a` ile tekrar bağlıyoruz? Çünkü Adım
3'te elle yaptığın `mount` komutu **hâlâ bellekte aktif** — fstab'a yazdığın
satırın gerçekten doğru olup olmadığını, mevcut elle-yapılmış bağlantı üzerinden
değil, **fstab'ın kendisinden** okuyarak test etmek istiyorsun. `umount` ile
önce mevcut bağlantıyı kaldırıyorsun, sonra `mount -a` ("all" — fstab'daki her
satırı bağlamayı dener) ile fstab'ın senin için doğru şekilde otomatik
bağlanabildiğini kanıtlıyorsun. Eğer `mount -a` bir hata verirse (yanlış UUID,
yazım hatası, var olmayan dizin), bunu **şimdi**, sistemi yeniden başlatmadan
öğrenmiş olursun — reboot'ta öğrenmek çok daha maliyetlidir.

> 🔥 **En tehlikeli hata:** Bozuk `/etc/fstab` ile reboot etmek. Sistem emergency
> mode'a düşer, konsol erişimi olmadan (uzak sunucuda) kurtaramazsın.
> **Her fstab değişikliğinden sonra reboot etmeden `mount -a` çalıştır.**
> Hata vermezse güvendesin. `nofail` seçeneği de bu riski azaltır.

Bunun neden bu kadar ciddi olduğunu açalım: `systemd`, açılış sırasında
`/etc/fstab`'taki her satır için bir bağlama birimi (mount unit) oluşturur ve
`nofail` verilmemiş bir satır bağlanamazsa, systemd o dosya sistemine bağımlı
olan diğer tüm hedefleri (targets) bekletir, sonunda "emergency mode" adı
verilen, sadece kök dosya sistemini salt-okunur açan, minimal bir kurtarma
kabuğuna düşer. Fiziksel olarak makinenin başındaysan bu bir sorun değildir
(konsoldan `fstab`'ı düzeltip reboot edersin), ama **uzaktaki bir sunucuda**,
SSH dışında erişimin yoksa (SSH de açılmayan bir sistemde çalışmaz!) bu ciddi
bir kilitlenme demektir — sağlayıcının web tabanlı "console/KVM" erişimine
ihtiyaç duyarsın. `mount -a` testi bu senaryoyu tamamen önler.

### Sistemd otomatik bağlama

```bash
systemctl daemon-reload      # fstab değişince systemd'ye haber ver
findmnt                      # bağlı FS'leri ağaç halinde gör
findmnt --verify             # ⭐ fstab'ı doğrula (RHEL 8+)
```

`systemd`, `/etc/fstab`'ı sistem açılışında okur ama bazı sürümlerinde çalışan
bir sistemde dosyayı değiştirdiğinde bunu otomatik fark etmeyebilir; `daemon-reload`
ile systemd'ye "yapılandırma dosyaları değişti, tekrar oku" dersin — birçok
systemd işleminde (servis dosyası değiştirdiğinde de) tekrar tekrar
karşılaşacağın bir alışkanlıktır. `findmnt --verify`, `mount -a`'dan bir adım
öteye geçip fstab söz dizimini analiz eder ve olası sorunları (var olmayan
UUID, çakışan mount noktaları) raporlar — mümkünse `mount -a`'dan önce bunu da
çalıştır.

---

## 4. Swap alanı

**Benzetme:** RAM'i masanın üzeri, swap'ı ise masanın altındaki bir kutu gibi
düşün. Masa (RAM) doluysa ve yeni bir şeye yer açman gerekiyorsa, en az kullanılan
eşyaları kutuya (swap'a, yani diske) kaldırırsın. Diskteki bu alan RAM kadar
hızlı değildir (kutudan bir şey çıkarmak, masadan almaktan çok daha yavaştır) ama
"hiç yer yok, işlem başarısız" (out-of-memory çökmesi) durumuna düşmeni engeller.

Swap, RAM dolduğunda kullanılan disk alanıdır. Ayrıca hazırda bekletme (hibernate)
için gerekir — hibernate, o anki tüm RAM içeriğini diske (swap alanına) kopyalayıp
bilgisayarı tamamen kapatmak, sonra açılışta bu içeriği geri RAM'e yükleyerek
kaldığın yerden devam etmektir; bunun çalışabilmesi için swap alanının en az RAM
kadar büyük olması gerekir.

### Bölüm olarak

```bash
sudo mkswap /dev/sdb2
sudo swapon /dev/sdb2
swapon --show
free -h
```

`mkswap`, tıpkı `mkfs` gibi, bir bölümün üzerine swap için özel bir yapı yazar
(bu bir "dosya sistemi" değildir, dosya/dizin tutmaz — sadece bellek sayfalarını
saklamak için organize edilmiş ham bir alandır). `swapon` bu alanı **aktif hale
getirir**, yani kernel'e "gerekirse burayı kullan" der — `mount` işleminin swap
karşılığı budur. `swapon --show` hangi swap alanlarının aktif olduğunu, `free -h`
ise o anki RAM/swap kullanım özetini gösterir.

### Dosya olarak (daha esnek — sonradan büyütülebilir)

Bir bölüm yerine, normal dosya sisteminin içinde sıradan bir **dosyayı** da swap
olarak kullanabilirsin. Bunun avantajı esnekliktir: bir bölümün boyutunu
değiştirmek (yeniden bölümlemek) zahmetliyken, bir dosyayı silip daha büyüğünü
oluşturmak çok daha kolaydır.

```bash
sudo fallocate -l 2G /swapfile
# fallocate desteklenmezse (bazı FS'lerde):
# sudo dd if=/dev/zero of=/swapfile bs=1M count=2048

sudo chmod 600 /swapfile          # ⭐ ZORUNLU, aksi halde mkswap uyarır
sudo mkswap /swapfile
sudo swapon /swapfile
swapon --show
```

`fallocate -l 2G` diskte hızlıca (içini sıfırla doldurmadan, sadece alanı
ayırarak) 2 GB'lık boş bir dosya oluşturur. `chmod 600` bu dosyayı sadece
root'un okuyup yazabileceği şekilde kilitler — bunun **zorunlu** olmasının
sebebi güvenliktir: swap dosyası, RAM'de o an neyin olduğunun bir kopyasını
tutar, bu da şifreler, özel anahtarlar gibi hassas verileri içerebilir. İzinleri
gevşek bırakırsan, sistemdeki herhangi bir kullanıcı bu dosyayı okuyup başka
kullanıcıların bellek içeriğini görebilir.

fstab'a ekle:
```
/swapfile   none   swap   sw   0 0
UUID=...    none   swap   sw   0 0
```

Bu satırda "bağlama noktası" sütunu (`none`) diğer mount satırlarından farklıdır
— swap bir dizine bağlanmaz, sadece kernel'e "kullanılabilir" olarak işaretlenir,
bu yüzden ikinci sütun anlamsızdır ve gelenek olarak `none` yazılır.

```bash
sudo swapoff /swapfile        # kapat
sudo swapoff -a               # tüm swap'ı kapat
```

**Ne kadar swap?**

| RAM | Önerilen swap |
|---|---|
| ≤ 2 GB | RAM × 2 |
| 2–8 GB | RAM kadar |
| 8–64 GB | 4–8 GB |
| > 64 GB | 4 GB (veya hibernate için RAM kadar) |

Bu tablonun mantığı: RAM azken (≤2GB), sistemin nefes alabilmesi için swap'a
büyük oranda ihtiyacı vardır, bu yüzden RAM'in iki katı önerilir. RAM arttıkça,
swap'a **oransal olarak** daha az ihtiyaç duyulur — 64 GB RAM'li bir sunucunun
zaten neredeyse hiç swap'a düşmemesi beklenir, o birkaç GB'lık swap sadece
beklenmedik bir bellek sıçramasında sistemin çökmesini önleyen bir emniyet
supabıdır, sürekli kullanılan bir alan değildir.

**Swappiness** — kernel ne kadar istekli swap kullansın (0–100):
```bash
cat /proc/sys/vm/swappiness       # varsayılan genelde 60 (RHEL 9'da 30)
sudo sysctl vm.swappiness=10      # geçici
echo "vm.swappiness=10" | sudo tee /etc/sysctl.d/99-swap.conf   # kalıcı
```
Bu değer 0 ile 100 arasında bir "istek düzeyi"dir: yüksek değer (60'a yakın),
kernel'in RAM tamamen dolmadan, henüz biraz boş RAM varken bile bazı verileri
proaktif olarak swap'a taşımaya istekli olduğu; düşük değer (10'a yakın) ise
kernel'in mümkün olduğunca RAM'de kalmaya çalışıp, sadece gerçekten zorunlu
kaldığında swap'a başvurduğu anlamına gelir. `sysctl` ile yapılan değişiklik
**geçicidir**, reboot'ta kaybolur; kalıcı olması için `/etc/sysctl.d/` altına bir
dosya yazman gerekir (yukarıdaki örnekte olduğu gibi).

Veritabanı sunucularında düşük (1–10) tercih edilir — swap'a düşen veritabanı çok yavaşlar.
Bunun sebebi basit: veritabanları saniyede binlerce küçük bellek erişimi yapar;
bu erişimlerden biri swap'a (yani diske) düşerse, o tek işlem RAM'e göre binlerce
kat yavaşlar ve tüm veritabanının performansını bloke edebilir.

> **Not:** Btrfs'te swap dosyası özel işlem ister (`chattr +C`, no-COW).
> ZFS'te swap dosyası önerilmez.

---

## 5. Kota (quota)

**Benzetme:** Kota, bir ofis binasındaki her kiracıya "en fazla şu kadar metrekare
kullanabilirsin" demeye benzer. Disk paylaşılan bir kaynaktır; bir kullanıcı
(kasıtlı ya da kazayla) tüm alanı doldurursa, aynı diski paylaşan diğer
kullanıcılar ve hatta sistemin kendisi (log yazamaz, geçici dosya oluşturamaz)
çalışamaz hale gelir. Kota, kullanıcı/grup başına disk kullanımını sınırlayarak
bunu önler.

```bash
# 1. Paketi kur
sudo dnf install quota          # RHEL
sudo apt install quota          # Debian

# 2. fstab'a seçenek ekle
#    ext4:  usrquota,grpquota
#    xfs :  uquota,gquota   (XFS'te mount anında etkinleşir, quotacheck YOK)
```
```
UUID=...  /veri  ext4  defaults,usrquota,grpquota  0 2
```
```bash
sudo mount -o remount /veri

# 3. (sadece ext4) kota veritabanını oluştur
sudo quotacheck -cugm /veri
sudo quotaon /veri

# 4. Kullanıcıya kota ver
sudo edquota -u ali            # editör açılır
```

Bu akışı adım adım anlayalım: Önce `quota` paketini kurarsın (kota işlevselliği
temel sistemde gelmez, ayrı bir araç setidir). Sonra fstab'daki ilgili satıra
`usrquota`/`grpquota` (ext4) ya da `uquota`/`gquota` (xfs) seçeneğini eklersin —
bu, kernel'e "bu dosya sisteminde kota takibi aktif olsun" der. `mount -o
remount /veri` ile diski umount/mount etmeden, sadece seçeneklerini yeniden
uygulayarak yeni ayarı devreye sokarsın. `quotacheck` (sadece ext4'te gerekir),
o an dosya sisteminde kimin ne kadar yer kullandığını tarayıp bir "kota
veritabanı" oluşturur — bunu yapmadan kota sistemi kimin ne kullandığını
bilemez. `quotaon` kota takibini fiilen açar. Son olarak `edquota -u ali` ile
"ali" kullanıcısı için bir metin editörü açılır, orada limitleri belirlersin.

```
Filesystem  blocks  soft    hard   inodes  soft  hard
/dev/sdb1    1024  512000 1024000     20    0     0
                    │       │
                    │       └─ hard: kesinlikle aşılamaz
                    └─ soft: aşılabilir ama grace süresi başlar
```
```bash
sudo setquota -u ali 512000 1024000 0 0 /veri    # betikle
sudo edquota -t                                   # grace süresi ayarla
quota -u ali                                      # kullanıcı kotası
sudo repquota -a                                  # ⭐ tüm kota raporu
sudo repquota -s /veri                            # okunur birimlerle
```

**soft vs hard:** Soft limiti aşan kullanıcı uyarılır ve `grace period`
(varsayılan 7 gün) içinde düşürmezse yazamaz hale gelir. Hard limit anında
bloklar. Bunu somut bir örnekle düşün: Ali'nin soft limiti 500 MB, hard limiti
1000 MB olsun. Ali 600 MB'a çıkarsa (soft'u aştı ama hard'ı aşmadı), sistem onu
uyarır ama yazmaya devam edebilir — 7 gün içinde 500 MB'ın altına inmezse, 7
gün sonra artık **hiç** yazamaz hale gelir (soft limit onun için hard limit
gibi davranmaya başlar). Ama Ali doğrudan 1000 MB'a ulaşırsa, grace süresi
beklemeden **anında** yazamaz hale gelir. Bu iki kademeli sistem, kullanıcıya
"toparlanman için birkaç günün var" demenin bir yoludur, sert bir duvara
çarpmadan önce.

> XFS için `xfs_quota -x -c 'limit bsoft=500m bhard=1g ali' /veri` sözdizimi kullanılır,
> ayrıca **proje kotası** (dizin bazlı) destekler — ext4'te yoktur.

---

## 6. dd — blok seviyesinde kopyalama

**Benzetme:** `dd`, bir kitabı **sayfa içeriğini anlamadan**, harfleri tek tek,
baştan sona kopyalayan bir fotokopi makinesi gibidir. `cp` gibi araçlar "bu bir
dosya, şu kadar bayt" diye dosya sistemi seviyesinde düşünür; `dd` ise hiçbir şey
"anlamaz" — sadece kaynaktaki her baytı, olduğu gibi, hedefe yazar. Bu yüzden
diskin tamamını (bölüm tablosu dahil, boş alanlar dahil) birebir kopyalamak
istediğinde `dd` doğru araçtır; ama aynı sebeple **hedefte önceden var olan her
şeyin üzerine sessizce yazar**, onay sormaz.

`dd` bayt bayt kopyalar; dosya sistemini tanımaz, ne verirsen onu yazar.
Bu yüzden hem çok güçlü hem çok tehlikelidir ("disk destroyer").

```bash
dd if=KAYNAK of=HEDEF bs=BLOKBOYUTU [count=ADET] [status=progress]
```

Bu dört parametre `dd`'nin tüm mantığıdır: `if` ("input file") nereden
okunacağı, `of` ("output file") nereye yazılacağı, `bs` ("block size") her
seferinde ne kadarlık bir parça okunup yazılacağı, `count` kaç tane böyle
parça işleneceği (verilmezse kaynağın sonuna kadar devam eder).

```bash
# Test dosyası oluştur
dd if=/dev/zero of=test.img bs=1M count=100 status=progress

# Rastgele veriyle
dd if=/dev/urandom of=rastgele.bin bs=1M count=10

# Disk klonlama (aynı boyut şart)
sudo dd if=/dev/sdb of=/dev/sdc bs=4M status=progress conv=noerror,sync

# Diskin imajını dosyaya al
sudo dd if=/dev/sdb of=/yedek/sdb.img bs=4M status=progress

# Sıkıştırarak imaj
sudo dd if=/dev/sdb bs=4M | gzip -c > /yedek/sdb.img.gz

# Geri yükleme
gunzip -c /yedek/sdb.img.gz | sudo dd of=/dev/sdb bs=4M status=progress

# MBR yedeği (ilk 512 bayt)
sudo dd if=/dev/sda of=/yedek/mbr.bak bs=512 count=1

# USB'ye ISO yazma
sudo dd if=linux.iso of=/dev/sdX bs=4M status=progress oflag=sync

# Diski sıfırla (silme)
sudo dd if=/dev/zero of=/dev/sdb bs=1M status=progress

# Disk okuma hızı testi
sudo dd if=/dev/sdb of=/dev/null bs=1M count=1024
```

Bu örneklerin her biri aslında aynı dört parametrenin farklı kombinasyonlarıdır.
`/dev/zero` ve `/dev/urandom`, sırasıyla "sonsuz sıfır" ve "sonsuz rastgele
bayt" üreten sanal aygıtlardır — test dosyası oluşturmak veya bir diski
"temizlemek" için kaynak olarak kullanılırlar. `if=/dev/sdb of=/dev/null`
kombinasyonunda hedef `/dev/null` — "çöp kutusu", hiçbir yere yazmayan sanal bir
aygıt — olduğu için bu komut aslında hiçbir şeyi değiştirmez, sadece diskin ne
kadar hızlı **okunabildiğini** ölçer.

> 🔥 **`of=` parametresini iki kere kontrol et.** `of=/dev/sda` yazıp Enter'a bastığında
> sistem diskini geri dönüşsüz siler. Onay sormaz, "emin misin" demez.
> Komutu yazdıktan sonra Enter'dan önce `lsblk` çıktısıyla karşılaştırma alışkanlığı edin.

Bunun neden bu kadar vurgulandığını anlamak için: `dd` bir "silme" komutu bile
değildir, sadece "yaz" der; ama `if=/dev/zero of=/dev/sda` yazarsan, `/dev/sda`
diskinin başındaki bölüm tablosunu (ve istersen tamamını) sıfırlarla ezersin —
bu, o diskteki tüm bölümlerin, tüm dosyaların "var olduğu bilgisinin" anında yok
olması demektir. Geri dönüşü yoktur, `dd` hiçbir onay istemez, "emin misin"
sormaz — sen komutu yazıp Enter'a bastığın an iş biter. Bu yüzden her zaman,
komutu çalıştırmadan hemen önce `lsblk` ile `of=` hedefinin gerçekten
hedeflediğin disk olduğunu son bir kez doğrulamak, alışkanlık haline
getirilmesi gereken bir güvenlik adımıdır.

**Faydalı bayraklar:**
- `bs=4M` — blok boyutu; büyük olması hızlandırır (varsayılan 512 bayt çok yavaş)
- `status=progress` — ilerleme göster (yoksa hiçbir çıktı vermez)
- `conv=noerror,sync` — okuma hatasında devam et, eksiği sıfırla doldur (arızalı disk kurtarma)
- `oflag=direct` — sayfa önbelleğini atla (gerçek disk hızı ölçümü)

`bs` neden hız için önemli? Her okuma/yazma işlemi bir miktar "sabit maliyet"
taşır (disk kafasının konumlanması, sistem çağrısı yükü gibi). Küçük bloklarla
(512 bayt gibi) çalışırsan aynı miktarda veriyi taşımak için çok daha fazla
sayıda işlem yapman gerekir, bu da toplam süreyi ciddi şekilde uzatır. 1M-4M
gibi büyük bloklar, aynı işi çok daha az sayıda, daha "verimli" işlemle
tamamlar.

`dd` çalışırken ilerlemeyi görmek:
```bash
sudo kill -USR1 $(pgrep ^dd$)      # dd o anki durumu basar
```
Bu, `status=progress` eklemeyi unuttuğun, `dd` zaten çalışmaya başlamış bir
komuta sonradan ilerleme durumu sorma yoludur — `dd` sürecine `SIGUSR1` sinyali
gönderirsin (`kill` burada "öldürmez", sadece sinyal gönderir — bu kavramı 08.
modülde ayrıntılı göreceksin), `dd` bu sinyali özel olarak yakalayıp o ana
kadarki durumunu ekrana basacak şekilde yazılmıştır.

---

## 7. rsync — akıllı yedekleme

**Benzetme:** `dd` fotokopi makinesiyse, `rsync` iki dolabı karşılaştırıp
**sadece farklı olan kısımları** güncelleyen titiz bir taşımacı gibidir. İki
dolap da (kaynak ve hedef) büyük ölçüde aynıysa, `rsync` sadece değişen
dosyaları (hatta bir dosyanın sadece değişen kısımlarını) aktarır — bu da onu
`dd`'den kat kat daha hızlı ve pratik yapar, özellikle tekrar tekrar alınan
yedeklerde.

`dd` blok kopyalar, `rsync` **dosya** kopyalar ve sadece **değişenleri** aktarır.
Günlük yedeklemenin doğru aracı budur.

```bash
rsync -avh /kaynak/ /hedef/
#      ││││
#      │││└─ human-readable
#      ││└─ verbose
#      │└─ archive: -rlptgoD (özyineleme + izin + sahip + zaman + link + aygıt) ⭐
#      └─ 
```

`-a` ("archive") aslında yedi ayrı seçeneğin (`-rlptgoD`) kısayoludur ve
`rsync`'in "doğru şekilde yedekle" moduna girmesini sağlar: `-r` alt dizinlere
iner, `-l` sembolik linkleri link olarak kopyalar (hedefteki dosyanın kopyası
değil), `-p` izinleri korur, `-t` zaman damgalarını korur, `-g`/`-o` grup/sahip
bilgisini korur, `-D` aygıt dosyalarını korur. Bunların hepsini tek tek
yazmak yerine `-a` yazman yeterlidir — bu yüzden neredeyse her `rsync`
komutunda görürsün.

```bash
rsync -avh --progress /veri/ /yedek/          # ilerleme göster
rsync -avzh /veri/ user@sunucu:/yedek/        # -z sıkıştır (ağ üzerinden)
rsync -avh -e "ssh -p 2222" /veri/ user@sunucu:/yedek/

rsync -avh --delete /kaynak/ /hedef/          # ⭐ hedefte fazlalıkları SİL (tam ayna)
rsync -avhn --delete /kaynak/ /hedef/         # ⭐ -n = DRY RUN, ne olacağını göster
rsync -avh --exclude='*.tmp' --exclude='cache/' /kaynak/ /hedef/
rsync -avh --exclude-from=haric.txt /kaynak/ /hedef/
rsync -avh --bwlimit=5000 /kaynak/ /hedef/    # 5 MB/s ile sınırla
rsync -avh --partial --append-verify ...      # kesilen aktarımı sürdür
```

`--delete` seçeneğinin ne yaptığını netleştirelim: normalde `rsync`, kaynakta
olup hedefte olmayan dosyaları hedefe **ekler**, ama hedefte olup kaynakta
**olmayan** dosyalara dokunmaz — onları olduğu gibi bırakır. `--delete` bu
davranışı değiştirir: hedefi kaynağın **birebir aynası** yapmaya çalışır, yani
kaynakta artık olmayan bir dosya hedefte varsa onu **siler**. Bu güçlü ama
tehlikeli bir seçenektir (aşağıda ayrıca ele alıyoruz).

### ⚠️ Sondaki `/` — rsync'in en kritik detayı

```bash
rsync -av /kaynak  /hedef/     # → /hedef/kaynak/... oluşur
rsync -av /kaynak/ /hedef/     # → /kaynak'ın İÇİ /hedef/'e gider
```

Bu fark her yeni başlayanın en az bir kere düştüğü bir tuzaktır. Kaynağın
sonunda `/` **yoksa**, `rsync` kaynak dizinin **kendisini** (bir klasör olarak)
hedefin içine kopyalar — yani `/kaynak` içindeki her şey, hedefte
`/hedef/kaynak/...` yolunda biter, bir klasör seviyesi daha derine iner.
Kaynağın sonunda `/` **varsa**, `rsync` bunu "bu dizinin içeriğini kopyala,
kendisini değil" olarak yorumlar — `/kaynak` içindeki dosyalar doğrudan
`/hedef/...` altına gider, ekstra bir klasör seviyesi oluşmaz. Bu ayrım özellikle
`--delete` ile birleşince kritik hale gelir:

`--delete` ile birlikte yanlış `/` kullanmak veri kaybıdır. **Her zaman önce `-n`
(dry run) çalıştır.**

`-n` ("dry run" — kuru çalıştırma), `rsync`'e "hiçbir şeyi gerçekten
kopyalama/silme, sadece ne yapacağını bana söyle" der. Özellikle `--delete`
kullandığın her komutu önce `-n` ile çalıştırıp çıktıyı okumak, "hangi
dosyaların silineceğini" gerçek işlemden **önce** görmeni sağlar — beklenmedik
bir sonuç görürsen (örneğin binlerce dosyanın silineceği yazıyorsa, muhtemelen
`/` hatası yaptın demektir) gerçek komutu hiç çalıştırmadan durabilirsin.

**Artımlı yedek (hard link ile — çok az yer kaplar):**
```bash
rsync -avh --delete --link-dest=/yedek/dun /veri/ /yedek/bugun/
```
Değişmeyen dosyalar için hard link kurulur, sadece değişenler yer kaplar.
Bunun mantığı şu: `--link-dest` ile "dünkü yedeğin" konumunu belirtirsin;
`rsync`, bugünkü kaynaktaki bir dosya dünkünden **değişmemişse**, onu tekrar
kopyalamak yerine dünkü kopyaya bir **hard link** (aynı içeriği gösteren ikinci
bir isim — 09. modülde daha önce Gün 1'de link sayısı kavramını görmüştün, bu
onun pratik bir uygulamasıdır) oluşturur. Sonuç: her gün, sanki tam bir kopya
almışsın gibi eksiksiz bir "bugün" klasörün olur, ama diskte sadece o gün
değişen dosyalar kadar ekstra yer kaplanır.

---

## 8. cp ile yedekleme

```bash
cp -a /kaynak /hedef            # ⭐ arşiv modu: izin, sahip, zaman, link korunur
cp -au /kaynak/. /hedef/        # sadece daha yeni olanları güncelle
cp --reflink=auto kaynak hedef  # CoW dosya sistemlerinde (Btrfs/XFS) anlık kopya
```

`cp -a` mi `rsync -a` mı? Yerel, tek seferlik, küçük işler için `cp -a` yeterli ve hızlı.
Tekrarlanan, uzak, büyük veya kesintiye uğrayabilecek işler için `rsync`.

Bu ayrımın sebebi: `cp`, `rsync`'in aksine "sadece farkı kopyala" mantığına
sahip değildir (özel `-u` bayrağı hariç, o da dosya bazında karşılaştırır,
`rsync` kadar akıllı değildir) ve ağ üzerinden kesintiye uğrayan bir aktarımı
"kaldığı yerden devam ettirme" yeteneği yoktur. Küçük, tek seferlik, aynı
makine içindeki kopyalarda bu fark önemsizdir; ama büyük veya tekrarlanan
işlerde `rsync`'in verimliliği kritik hale gelir.

---

## 9. initramfs ve RAM disk

### initramfs

Kernel açılırken gerçek kök dosya sistemini bağlayabilmek için sürücülere (disk denetleyici,
RAID, LVM, şifreleme) ihtiyaç duyar. Bu sürücüler kök FS'in içindedir → tavuk-yumurta problemi.
Çözüm: **initramfs** — RAM'e yüklenen geçici bir kök dosya sistemi.

Bunu biraz daha açalım, çünkü "tavuk-yumurta problemi" ifadesi ilk okuyuşta
soyut kalabilir: Kernel'in `/` (kök) dosya sistemini bağlayabilmesi için, o
dosya sisteminin bulunduğu diski **okuyabilmesi** gerekir. Ama diski okumak
için gereken sürücü (driver) kodu da normalde... kök dosya sisteminin içinde
bulunur (`/lib/modules/` altında). Yani "diski okumak için önce diski okumam
lazım" gibi imkânsız bir döngüye girilir — özellikle disk LVM, RAID veya
şifreleme (LUKS) gibi ekstra bir katman içeriyorsa bu sorun daha da büyür.
Çözüm, kök dosya sistemine hiç ihtiyaç duymadan, doğrudan RAM'e yüklenen
**küçük, geçici** bir dosya sistemi (initramfs) hazırlamaktır; bu geçici
sistem sadece gerçek kökü bağlamak için gereken minimum sürücüleri içerir.

```
Açılış: GRUB → kernel + initramfs RAM'e → initramfs sürücüleri yükler
        → gerçek kök bağlanır → switch_root → systemd başlar
```

```bash
ls -lh /boot/initramfs-$(uname -r).img        # RHEL
ls -lh /boot/initrd.img-$(uname -r)           # Debian

# İçeriğini listele
lsinitrd /boot/initramfs-$(uname -r).img      # RHEL
lsinitramfs /boot/initrd.img-$(uname -r)      # Debian

# Yeniden oluştur
sudo dracut -f                                # RHEL — mevcut kernel için
sudo dracut -f --regenerate-all               # tüm kernel'ler
sudo update-initramfs -u                      # Debian/Ubuntu
sudo update-initramfs -u -k all
```

> **Ne zaman yeniden oluşturursun?** Disk sürücüsü değiştirdiğinde, LVM/RAID/LUKS
> yapılandırmasını değiştirdiğinde, `/etc/fstab`'ta kök ile ilgili değişiklik yaptığında.
> Yapmazsan sistem açılışta "cannot find root device" ile kalır.

Bu üç durumun ortak noktası şu: initramfs, oluşturulduğu **o anki** disk
yapılandırmasının bir "fotoğrafını" içerir (hangi sürücüler gerekli, hangi
LVM/RAID birimleri var). Sen sonradan disk yapılandırmasını değiştirirsen ama
initramfs'i yeniden oluşturmazsan, initramfs hâlâ **eski** yapılandırmayı
bilir — yeni disk düzenini tanımadığı için kök dosya sistemini bulamaz ve
açılış burada tıkanır.

### RAM disk (tmpfs)

```bash
sudo mkdir /mnt/ramdisk
sudo mount -t tmpfs -o size=512M tmpfs /mnt/ramdisk
df -h /mnt/ramdisk
```
fstab:
```
tmpfs  /mnt/ramdisk  tmpfs  size=512M,mode=1777  0 0
```

Burada dikkat çekici olan şey, bu `mount` komutunun **hiçbir gerçek disk
aygıtı kullanmamasıdır** — `-t tmpfs`, "kaynağın bir disk değil, doğrudan RAM
olduğu" özel bir dosya sistemi tipini belirtir. `mount` komutunun genel
sözdizimi (`mount KAYNAK HEDEF`) burada da geçerlidir, sadece "kaynak" bu sefer
fiziksel bir aygıt değil, kernel'in kendi bellek yönetiminin bir parçasıdır.

tmpfs RAM'de yaşar — çok hızlıdır ama **reboot'ta kaybolur** ve RAM'ini yer.
Kullanım: derleme geçici dosyaları, yoğun okunan cache, hassas geçici veri
(diske hiç yazılmasın diye).

---

## 10. fsck — dosya sistemi kontrolü ve onarımı

**Benzetme:** `fsck` ("file system check"), bir kütüphanenin kataloğunu
denetleyen bir görevli gibi düşünülebilir. Normalde her kitap (dosya) kataloğa
(dosya sisteminin iç tablolarına) doğru şekilde kayıtlıdır. Ama elektrik kesintisi,
ani kapanma gibi durumlarda, bir kitap rafa konurken (bir yazma işlemi
tamamlanmadan) sistem aniden kapanabilir — bu, kataloğun gerçek raf durumuyla
**tutarsız** hale gelmesine yol açar. `fsck`, tüm rafları (dosya sisteminin
tüm iç yapılarını) tarayıp kataloğu gerçek duruma göre düzeltir.

```bash
sudo umount /dev/sdb1               # ⭐ ÖNCE UMOUNT — bağlıyken çalıştırma!
sudo fsck /dev/sdb1
sudo fsck -y /dev/sdb1              # tüm sorulara evet
sudo fsck -n /dev/sdb1              # salt okunur kontrol (güvenli)
sudo fsck.ext4 -f /dev/sdb1         # temiz görünse bile zorla kontrol et
sudo e2fsck -f -y /dev/sdb1

# XFS ayrı araç kullanır
sudo xfs_repair /dev/sdb1
sudo xfs_repair -n /dev/sdb1        # sadece kontrol
```

Neden önce `umount` şart? Çünkü bağlı (mounted) bir dosya sistemi **aktif
olarak kullanılıyor** olabilir — kernel o an dosya sisteminin bazı bölümlerini
bellekte tutuyor, yazma işlemleri sırada bekliyor olabilir. `fsck` diski
tararken bu "canlı", henüz diske işlenmemiş değişikliklerden habersizdir; hem
`fsck`'in gördüğü hem de kernel'in bellekte tuttuğu durum çakışabilir, bu da
veri bozulmasına yol açabilir. `umount`, o dosya sistemiyle ilgili tüm bellek
etkinliğinin durup her şeyin diske yazıldığından emin olunmasını sağlar — ancak
o zaman `fsck` güvenle çalışabilir.

`-y` ve `-n` bayrakları iki uç davranışı temsil eder: `-y` bulunan her soruna
otomatik "evet, düzelt" der (denetimsiz, otomatik betiklerde kullanılır); `-n`
ise hiçbir şeyi değiştirmez, sadece "şunlar şunlar bozuk" diye raporlar —
gerçekte ne olduğunu önce görmek istediğinde güvenli bir ilk adımdır.

> ⚠️ **Bağlı (mounted) bir dosya sistemine `fsck` çalıştırma** — veri bozarsın.
> Kök dosya sistemi için: kurtarma modunda başlat veya `sudo touch /forcefsck`
> yapıp reboot et (bir sonraki açılışta kontrol edilir).

Kök dosya sistemi (`/`) özel bir durumdur, çünkü sistem çalışırken onu
`umount` edemezsin (sistemin kendisi o dosya sisteminden çalışıyor). Bu yüzden
iki seçeneğin var: ya kurtarma/tek kullanıcı modunda başlatıp kökü salt-okunur
tutarak kontrol edersin, ya da `/forcefsck` diye boş bir dosya oluşturup reboot
edersin — açılış sürecinin erken bir aşaması, kök henüz "yazılabilir" moda
geçmeden önce, bu dosyanın varlığını kontrol edecek şekilde tasarlanmıştır ve
onu görünce otomatik bir `fsck` tetikler.

**Kurtarılan dosyalar `lost+found` dizinine konur** (ext ailesinde). Adları kaybolur,
inode numarasına göre isimlendirilir.

Bunun sebebi: `fsck`, bir dosyanın **verisini** (inode'unu, yani içeriğine
işaret eden kaydı) bulur ama o veriye işaret eden **dizin girdisi** (yani
dosyanın adı) kayıpsa, veriyi tamamen silmek yerine `lost+found` dizinine,
inode numarasını isim olarak vererek koyar — böylece veri kaybolmaz ama hangi
dosyanın hangi içerik olduğunu genelde elle (dosya içeriğine bakarak) tekrar
anlaman gerekir.

**Disk sağlığı:**
```bash
sudo dnf install smartmontools
sudo smartctl -a /dev/sda           # SMART verisi
sudo smartctl -H /dev/sda           # sadece sağlık özeti
sudo smartctl -t short /dev/sda     # kısa test başlat
sudo badblocks -sv /dev/sdb         # bozuk blok taraması (yavaş)
```

`fsck` dosya sistemi **yapısındaki** tutarsızlıkları düzeltir ama diskin
fiziksel olarak arızalı olup olmadığını söylemez. `smartctl`, disklerin
kendi içine gömülü S.M.A.R.T. (Self-Monitoring, Analysis and Reporting
Technology) verisini okur — üretici tarafından diske gömülen, disklerin
kendi sağlık göstergelerini (yeniden ayrılan sektör sayısı, çalışma saati,
sıcaklık gibi) izleyen bir sistemdir. `badblocks` ise diski gerçekten okuyup
(isteğe bağlı yazıp) fiziksel olarak bozuk sektörleri arar — çok daha
yavaştır çünkü diskin tamamını taramak zorundadır.

**Alan sorunları:**
```bash
df -h                     # alan doluluk
df -i                     # ⭐ inode doluluk — "no space left" ama df boş gösteriyorsa
du -sh /* 2>/dev/null | sort -rh | head
ncdu /                    # interaktif disk analizi (ayrıca kurulur)
sudo lsof +L1             # ⭐ SİLİNMİŞ ama hâlâ açık dosyalar
```

`df -i` neden ayrıca gereklidir? Çünkü bir dosya sisteminde iki farklı kaynak
tükenebilir: **alan** (byte cinsinden yer) ve **inode** (dosya/dizin
kayıtlarının sayısı). Milyonlarca küçük dosya oluşturan bir sistemde (örneğin
çok fazla küçük log/cache dosyası), disk hâlâ %90 boş görünse bile inode'lar
tükenebilir — çünkü her dosya, boyutundan bağımsız olarak bir inode "harcar".
Bu durumda `df -h` yanıltıcı şekilde "bolca yer var" derken, sistem yine de
"no space left on device" hatası verir; gerçek sorunu `df -i` ile görürsün.

> **Klasik senaryo:** Log dosyasını sildin ama `df` hâlâ dolu gösteriyor.
> Sebep: süreç dosyayı hâlâ açık tutuyor, inode serbest kalmıyor.
> `lsof +L1` ile bul, ilgili servisi `restart`/`reload` et. Alan anında boşalır.

Bu, Linux dosya sisteminin çok temel ama sezgisel olmayan bir davranışıdır:
`rm` bir dosyayı sildiğinde, aslında yaptığı şey o dosyaya işaret eden **dizin
girdisini kaldırmaktır** — dosyanın gerçek verisi, diskte, **hiçbir süreç onu
açık tutmadığı sürece** hemen serbest bırakılır. Ama bir süreç (örneğin bir log
yazan servis) o dosyayı hâlâ açık dosya tanımlayıcısı (file descriptor) olarak
tutuyorsa, kernel o veriyi silmez — çünkü süreç hâlâ o tanımlayıcı üzerinden
veriye erişebilir olmalıdır. Sonuç: dosya "görünmez" (dizin listesinde yok) ama
alan hâlâ "işgal edilmiş" durumdadır. `lsof +L1`, tam olarak bu durumdaki
dosyaları (link sayısı 1'in altına düşmüş ama hâlâ açık olanları) listeler; o
dosyayı tutan süreci bulup yeniden başlatman (`restart` ya da `reload`), o
süreç dosyayı kapattığı an alanın gerçekten boşalmasını sağlar.

---

## 🧪 Lab

> Tüm adımları **`/dev/sdb`** üzerinde yap. `lsblk` ile doğrula, sistem diskine dokunma.

1. `/dev/sdb`'ye GPT tablosu oluştur, 3 bölüm yap: 2 GB, 1 GB, kalan.
2. Birinciyi `ext4`, ikinciyi `xfs` ile biçimlendir. `lsblk -f` ile doğrula.
3. `/veri1` ve `/veri2` dizinlerine bağla, `blkid` ile UUID'leri al, `/etc/fstab`'a
   `nofail,noatime` seçenekleriyle yaz. **`mount -a` ile test et.**
4. Kasten `/etc/fstab`'a hatalı bir satır yaz, `mount -a` ile hatayı gör, düzelt.
   (Reboot etme — hatanın nasıl yakalandığını öğren.)
5. Üçüncü bölümü swap yap, `swapon --show` ve `free -h` ile doğrula, fstab'a ekle.
6. Ayrıca 1 GB'lık bir **swap dosyası** oluştur, izinlerini `600` yap, aktif et.
   `swapon --show` ile ikisini birden gör.
7. `/veri1` üzerinde `usrquota` etkinleştir, bir kullanıcıya 100 MB soft / 200 MB hard
   kota ver. O kullanıcıyla `dd` ile büyük dosya oluşturmayı dene, limitin çalıştığını gör.
   `repquota -s /veri1` ile raporla.
8. `dd` ile 200 MB'lık test dosyası oluştur, `status=progress` ile hızını ölç.
   Sonra `bs=512` ile aynısını yap, süre farkını karşılaştır.
9. `/etc` dizinini `rsync -avh` ile `/veri1/etc-yedek/` altına al. Bir dosya değiştir,
   tekrar çalıştır — sadece o dosyanın aktarıldığını gör.
10. `rsync -avhn --delete` (dry run) ile ne silineceğini gör, sonra gerçeğini çalıştır.
11. `/veri1`'i `umount` edip `fsck -f` çalıştır. Çıktıyı oku.
12. 256 MB'lık bir tmpfs RAM disk oluştur, içine dosya yaz, `umount` edip verinin
    gittiğini doğrula.
13. Bir dosyayı sil ama `tail -f` ile açık tut. `df` ve `lsof +L1` çıktılarını karşılaştır.

---

## ❓ Kendini test et

**S1.** `/etc/fstab`'ta neden `/dev/sdb1` yerine UUID kullanılır?

<details><summary>Cevap</summary>
Aygıt adları açılış sırasına göre değişebilir (disk eklenmesi, USB, denetleyici sırası).
UUID dosya sistemine gömülüdür, disk nereye takılırsa takılsın aynı kalır.
Yanlış diskin `/veri`'ye bağlanmasını önler.
</details>

**S2.** fstab'ı düzenledin. Reboot etmeden önce hangi tek komutu çalıştırırsın ve neden?

<details><summary>Cevap</summary>
`sudo mount -a` — fstab'daki tüm girdileri bağlamayı dener. Hata verirse düzeltirsin.
Bozuk fstab ile reboot edilirse sistem emergency mode'a düşer ve uzak sunucuda
konsol erişimi olmadan kurtarılamaz. `nofail` seçeneği de bu riski azaltır.
</details>

**S3.** `df -h` diskin %45 dolu olduğunu gösteriyor ama bir dosyayı sildiğin halde
alan boşalmadı. Ne oldu?

<details><summary>Cevap</summary>
Bir süreç dosyayı hâlâ açık tutuyor; dosya silinmiş ama inode serbest bırakılmamış.
`sudo lsof +L1` ile bul, ilgili süreci restart/reload et.
</details>

**S4.** RHEL sunucusunda LVM birimini gereğinden fazla büyüttün, küçültmek istiyorsun. Mümkün mü?

<details><summary>Cevap</summary>
Dosya sistemi XFS ise **hayır** — XFS küçültmeyi desteklemez. Yedek al, LV'yi yeniden
oluştur, geri yükle. ext4 ise mümkündür (önce `resize2fs` küçült, sonra `lvreduce`).
</details>

**S5.** `dd if=/dev/sdb of=/dev/sdc` çalıştırmadan önce yapman gereken tek şey nedir?

<details><summary>Cevap</summary>
`lsblk` ile `of=` hedefinin gerçekten boş/hedeflenen disk olduğunu doğrulamak.
`dd` onay sormaz, geri alınamaz; yanlış hedefte tüm veriyi yok eder.
Ayrıca hedefin kaynaktan küçük olmadığını kontrol et.
</details>

**S6.** `mount /dev/sdb1 /veri` komutunu çalıştırdın, hiçbir hata almadın. Ama sistemi
yeniden başlattığında `/veri` yine boş. Neden, nasıl kalıcı yaparsın?

<details><summary>Cevap</summary>
Elle yapılan `mount` sadece o an çalışan sistemin belleğindeki bağlama tablosuna
yazılır, kalıcı bir yapılandırma dosyasına yazılmaz. Reboot'ta bu bilgi sıfırlanır.
Kalıcı olması için aynı bağlamayı `/etc/fstab`'a bir satır olarak (UUID ile) eklemek
ve `mount -a` ile test etmek gerekir.
</details>

**S7.** Bir USB diski `/veri2`'ye mount ettin, sonra USB'yi diskten çıkarmadan önce ne yapman gerekir?

<details><summary>Cevap</summary>
`sudo umount /veri2` ile bağlantıyı kaldırmak. Mount aktifken diski fiziksel olarak
çıkarmak, henüz diske yazılmamış (kernel önbelleğinde bekleyen) verilerin kaybolmasına
ve dosya sistemi bozulmasına yol açabilir. `umount` tüm bekleyen yazmaları diske
işleyip bağlantıyı güvenle sonlandırır.
</details>

---

## 📋 Hızlı referans

```bash
lsblk -f ; blkid ; findmnt --verify
parted /dev/sdX --script mklabel gpt
parted /dev/sdX --script mkpart primary ext4 1MiB 100%
partprobe /dev/sdX
mkfs.ext4|mkfs.xfs /dev/sdX1
mount /dev/sdX1 /yol
umount /yol                    # geri almak için
# fstab:  UUID=...  /yol  ext4  defaults,noatime,nofail  0 2
mount -a                       # ⭐ REBOOT ÖNCESİ TEST

fallocate -l 2G /swapfile && chmod 600 /swapfile
mkswap /swapfile && swapon /swapfile ; swapon --show

edquota -u KULLANICI ; repquota -as

dd if=X of=Y bs=4M status=progress      # of= İKİ KERE KONTROL
rsync -avhn --delete /kaynak/ /hedef/   # ⭐ önce -n
rsync -avh --link-dest=/yedek/dun /veri/ /yedek/bugun/

umount /dev/sdX1 && fsck -f /dev/sdX1
xfs_repair /dev/sdX1
dracut -f | update-initramfs -u
lsof +L1                       # silinmiş ama açık dosyalar
```
