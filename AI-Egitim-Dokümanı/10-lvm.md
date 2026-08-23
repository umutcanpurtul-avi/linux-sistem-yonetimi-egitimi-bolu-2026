---
tags: [linux, egitim, lvm, depolama]
modul: 10
durum: tamamlandi
---

# 10 — LVM (Logical Volume Manager)

> **Ön koşul:** [09-disk-yonetimi](09-disk-yonetimi.md)
> **Süre:** ~3 saat
> ⚠️ Tüm lab'ı ek disklerde yap. Snapshot al.

## Hedefler

- [ ] PV / VG / LV katmanlarını anlatabiliyorum
- [ ] Sıfırdan LVM kurabiliyorum
- [ ] VG'ye disk ekleyip LV büyütebiliyorum (çevrimiçi)
- [ ] Snapshot alıp geri dönebiliyorum
- [ ] LVM'i izleyip temizleyebiliyorum

---

## 1. LVM neden var? — Önce klasik bölümlemenin sorununu gör

[09-disk-yonetimi](09-disk-yonetimi.md) modülünde `/dev/sdb1`'i doğrudan `mkfs` ile biçimlendirip `mount`
ettin. Bu **klasik (classic) bölümleme**dir ve bir sorunu vardır: **katıdır**.

Somut örnek: `/veri` için 50 GB'lık bir bölüm açtın. Altı ay sonra doldu, 20 GB daha
lazım. Klasik bölümlemede yapabileceğin şeyler:

- Diskin üzerinde bitişik boş alan varsa bölümü büyütebilirsin (nadiren mümkün olur,
  çünkü diskteki bölümler yan yana dizilidir, aralarına yer sıkıştıramazsın).
- Yoksa: yeni, daha büyük bir disk al → veriyi oraya kopyala → eski diski çıkar.
  Bu işlem sırasında sistemi durdurman (kesinti) neredeyse kaçınılmazdır.

LVM bu sorunu, disk ile dosya sistemi arasına **esnek bir ara katman** koyarak çözer.
Şu benzetmeyi düşün:

> **Benzetme — LEGO tuğlaları ve ortak havuz:**
> - Her fiziksel disk/bölüm bir **LEGO tuğlası** (**PV** — Physical Volume) gibidir.
> - Bu tuğlaları bir **ortak kutuya** (**VG** — Volume Group) atarsın. Kutunun
>   toplam kapasitesi, içindeki tüm tuğlaların toplamıdır.
> - Sonra o kutudan istediğin boyutta **esnek dilimler** (**LV** — Logical Volume)
>   kesersin. Bu dilimleri biçimlendirip (`mkfs`) bağlarsın (`mount`) — kullanıcı
>   için normal bir disk bölümünden farksız görünür.
>
> Kutuya (VG) yeni bir tuğla (disk) attığında kutunun kapasitesi büyür, ve o büyümüş
> kapasiteden dilimlerine (LV) **çalışırken, kesintisiz** daha fazla pay ayırabilirsin.
> Tuğlaların hangi sırada, hangi fiziksel diskte olduğu LV'yi ilgilendirmez — LVM
> bunu senin için soyutlar.

Bu soyutlama sayesinde LVM üç somut şey kazandırır:

1. **Birden çok fiziksel diski tek havuzda birleştirme** — 3 tane 2 TB disk aldın,
   hepsini tek bir 6 TB'lık havuzda kullanabilirsin, dosya sistemi tek bir diskmiş
   gibi görür.
2. **Mantıksal birimleri çalışırken büyütme** — `/veri` doldu, havuzda yer varsa
   veya yeni disk eklersen, sistemi kapatmadan `/veri`'yi büyütürsün (aşağıda 4. bölüm).
3. **Snapshot alma** — bir andaki durumu "dondurup" güvenlik ağı oluşturma (aşağıda 5. bölüm).

> [!WARNING]
> **LVM RAID değildir**
> Bu, LVM'e yeni başlayanların en sık yaptığı yanlış varsayımdır. LVM sadece
> **esneklik** sağlar, **yedeklilik** sağlamaz. VG'ye 3 disk attın diyelim; bunlardan
> biri fiziksel olarak bozulursa, o diskte depolanan veri blokları (extent'ler) da
> gider — tıpkı tek bir diskte olduğu gibi. LVM'in kendi RAID desteği vardır
> (`lvcreate --type raid1`) ama pratikte bunun yerine donanım RAID veya `mdadm`
> tercih edilir. **LVM = esneklik. RAID = yedeklilik. İkisi ayrı problemi çözer,
> birbirinin yerine geçmez.**

---

## 2. Katmanlar — kim kimin içinde?

Yukarıdaki LEGO benzetmesini komut satırı karşılıklarıyla birlikte görelim:

```
   /dev/sdb1   /dev/sdc1   /dev/sdd1        ← Fiziksel bölümler
        │           │           │
        ▼           ▼           ▼
      [PV]        [PV]        [PV]           ← Physical Volume  (pvcreate)
        └───────────┼───────────┘
                    ▼
             ┌─────────────┐
             │  VG: vgdata │                 ← Volume Group     (vgcreate)
             │  (havuz)    │
             └──────┬──────┘
          ┌─────────┼─────────┐
          ▼         ▼         ▼
      [lv_web]  [lv_db]   [lv_log]           ← Logical Volume   (lvcreate)
          │         │         │
        ext4      xfs       ext4             ← Dosya sistemi    (mkfs)
          │         │         │
       /var/www  /var/lib  /var/log          ← Bağlama noktası  (mount)
```

Bu resmi adım adım, aşağıdan yukarıya okumak yerine **yukarıdan aşağıya, "ne işe
yarıyor" mantığıyla** okuyalım:

| Terim | Ne olduğu | Somut karşılığı |
|---|---|---|
| **PV** (Physical Volume) | LVM'e "seni kullanabilirim" dediğin ham disk/bölüm | Tek bir LEGO tuğlası |
| **VG** (Volume Group) | Bir veya daha fazla PV'nin oluşturduğu tek büyük havuz | Tuğlaların atıldığı ortak kutu |
| **LV** (Logical Volume) | Havuzdan kestiğin, biçimlendirip bağladığın parça | Kutudan kesilen esnek dilim |
| **PE** (Physical Extent) | VG'nin dağıttığı en küçük parça birimi (varsayılan **4 MiB**) | Kutunun içindeki en küçük "lego birimi" |
| **LE** (Logical Extent) | Bir LV'nin, PE'lerle 1:1 eşleşen kendi muhasebe birimi | LV'nin hangi PE'leri kullandığının kaydı |

**Neden PE/LE diye ayrı bir birim var, neden doğrudan byte kullanılmıyor?**
Çünkü LVM, bir LV'yi büyütürken/küçültürken/taşırken teker teker byte değil, **4 MiB'lik
bloklar** halinde tahsis yapar (bu boyut değiştirilebilir ama pratikte nadiren
dokunulur). Bir LV "5 GB" dediğinde, aslında arka planda "1280 tane 4 MiB'lik PE"
demektir (5120 MiB ÷ 4 MiB). `lvcreate -l 100` dediğinde ise byte değil, doğrudan
**extent sayısı** vermiş olursun.

LV'ler iki farklı ama birbirine eşdeğer yoldan erişilir:
```
/dev/vgdata/lv_web
/dev/mapper/vgdata-lv_web
```
İkisi de aynı aygıta işaret eder (`/dev/mapper/...` device-mapper'ın gerçek yoludur,
`/dev/VGADI/LVADI` ona giden bir sembolik bağlantıdır — [09-disk-yonetimi](09-disk-yonetimi.md)'de
işlediğimiz `l` (symlink) türünü hatırla).

---

## 3. Kurulum — adım adım, her adımda "neden bu adım var?"

```bash
# 0. LVM araçları
sudo dnf install lvm2       # RHEL
sudo apt install lvm2       # Debian
```

### Adım 1 — Bölümleri LVM tipine ayarla (isteğe bağlı ama düzenli)

```bash
sudo parted /dev/sdb --script mklabel gpt
sudo parted /dev/sdb --script mkpart primary 1MiB 100%
sudo parted /dev/sdb --script set 1 lvm on
```

**Neden bölüm oluşturuyoruz, doğrudan `pvcreate /dev/sdb` diyemez miyiz?**
Diyebilirsin — LVM tüm diski de PV yapabilir. Ama bir bölüm oluşturup onu "lvm"
tipiyle işaretlemek (`set 1 lvm on`), `lsblk`/`fdisk -l` çıktısına bakan başka bir
yöneticiye "bu disk LVM için ayrılmış, elleme" mesajı verir. Yani zorunlu değil,
**okunabilirlik ve niyet belirtme** amaçlı bir alışkanlıktır.

### Adım 2 — PV oluştur (diski LVM'e tanıt)

```bash
sudo pvcreate /dev/sdb1 /dev/sdc1
sudo pvs                       # kısa liste
sudo pvdisplay                 # detaylı
sudo pvscan
```

`pvcreate`, bölümün başına küçük bir **LVM metadata etiketi** yazar — bu etiket
"bu bölüm bir LVM üyesidir" bilgisini taşır. Bu adımdan sonra bölüm artık normal
bir `mkfs` hedefi olarak kullanılamaz; LVM'in bir parçası olmuştur.

### Adım 3 — VG oluştur (havuzu kur)

```bash
sudo vgcreate vgdata /dev/sdb1 /dev/sdc1
sudo vgs
sudo vgdisplay vgdata
```

`vgdisplay` çıktısında neye bakacağını bil:

| Alan | Ne anlatır |
|---|---|
| `VG Size` | Havuzun toplam kapasitesi (tüm PV'lerin toplamı) |
| `PE Size` | Bir extent'in boyutu (genelde 4 MiB) |
| `Total PE` | Havuzdaki toplam extent sayısı |
| `Free PE / Size` | Henüz hiçbir LV'ye verilmemiş, kullanılabilir alan |

`vgs` her seferinde bu detayları tekrar tekrar `vgdisplay` ile aramamak için
tek satırlık özet verir — günlük kullanımda asıl başvuracağın komut budur.

### Adım 4 — LV oluştur (havuzdan dilim kes)

```bash
sudo lvcreate -L 5G   -n lv_web vgdata      # boyutla
sudo lvcreate -l 100  -n lv_db  vgdata      # extent sayısıyla
sudo lvcreate -l 100%FREE -n lv_log vgdata  # ⭐ kalan TÜM alan
sudo lvcreate -l 50%VG -n lv_yedek vgdata   # VG'nin %50'si

sudo lvs
sudo lvdisplay /dev/vgdata/lv_web
```

> [!WARNING]
> **`-L` ile `-l` karışıklığı**
> `-L` (büyük L) = **boyut** (5G, 500M gibi insan-okunur birim).
> `-l` (küçük l) = **extent sayısı veya yüzde** (100, 100%FREE, 50%VG gibi).
> İkisi görsel olarak neredeyse aynı harf, anlamları tamamen farklı. Bir `lvcreate`
> komutu yazdıktan sonra mutlaka `lvs` ile gerçekte ne boyut oluştuğunu doğrula —
> "yanlış harfi kullandım, LV'yi yanlış boyutta açtım" çok sık yaşanan bir hatadır.

### Adım 5 — Biçimlendir ve bağla (artık normal bir disk gibi davran)

```bash
sudo mkfs.xfs  /dev/vgdata/lv_web
sudo mkfs.ext4 /dev/vgdata/lv_db

sudo mkdir -p /var/www /var/lib/veritabani
sudo mount /dev/vgdata/lv_web /var/www
```

Bu noktadan sonra `lv_web`, [09-disk-yonetimi](09-disk-yonetimi.md)'de öğrendiğin `/dev/sdb1` ile
**birebir aynı şekilde** davranır: `mkfs` ile biçimlendirilir, `mount` ile bağlanır,
`mount`u atlarsan `/var/www` boş kalır. LVM'in tek farkı, bu "disk"in aslında bir
havuzdan kesilmiş esnek bir dilim olmasıdır.

fstab'a eklerken bir fark var — LVM yollarında **UUID kullanman gerekmez**:

```
/dev/vgdata/lv_web        /var/www              xfs   defaults,noatime  0 2
/dev/mapper/vgdata-lv_db  /var/lib/veritabani   ext4  defaults          0 2
```

**Neden burada UUID şart değil ama normal bölümde şarttı?**
[09-disk-yonetimi](09-disk-yonetimi.md)'de UUID kullanma sebebimiz, aygıt adının (`/dev/sdb1`) açılış
sırasına göre değişebilmesiydi. LVM'de ise `/dev/vgdata/lv_web` adı **VG ve LV
isminden** üretilir, hangi fiziksel diskte olduğuna bakmaz — sen VG'yi `vgrename`
etmediğin sürece bu yol hep aynı kalır. Yani LVM, bu kararsızlık problemini kendi
isimlendirme katmanıyla zaten çözmüştür.

```bash
sudo mount -a       # ⭐ test — reboot etmeden fstab'ın doğru olduğunu doğrula
lsblk               # ağacı gör: PV → VG → LV hiyerarşisi görsel olarak burada
```

---

## 4. Büyütme — LVM'in var olma sebebinin pratikteki karşılığı

### Senaryo A: VG'de zaten boş alan var

Bu en basit durum: havuzda (VG'de) henüz hiçbir LV'ye verilmemiş boş extent'ler var,
sadece bir LV'ye daha fazlasını atamak istiyorsun.

```bash
sudo vgs                                   # VFree sütununa bak — ne kadar boş var?

# 1. LV'yi büyüt
sudo lvextend -L +5G /dev/vgdata/lv_web        # mevcut boyuta 5 GB EKLE
sudo lvextend -L 20G /dev/vgdata/lv_web        # toplamı 20 GB'A TAMAMLA (fark eder!)
sudo lvextend -l +100%FREE /dev/vgdata/lv_web  # havuzda kalan her şeyi bu LV'ye ver

# 2. DOSYA SİSTEMİNİ büyüt  ← BU ADIMI ATLAMA, en sık unutulan adım
sudo xfs_growfs /var/www                   # XFS — BAĞLAMA NOKTASI verilir
sudo resize2fs /dev/vgdata/lv_db           # ext4 — AYGIT verilir

df -h                                      # doğrula
```

> [!WARNING]
> **İki ayrı katman, iki ayrı komut — neden?**
> Şunu hatırla: LV, disk bloklarının bir soyutlamasıdır; dosya sistemi (ext4/xfs)
> ise o bloklar üzerine yazılmış bir **kayıt defteri**dir ("şu bloklar şu dosyaya
> ait" bilgisini tutar). `lvextend` sadece LV'nin **blok alanını** büyütür — LV artık
> daha büyük, ama üzerindeki dosya sistemi hâlâ "ben eskisi kadar büyüğüm" sanıyor,
> çünkü kayıt defteri güncellenmedi. Bu yüzden `df -h` hâlâ eski boyutu gösterir.
> Dosya sistemini büyütme komutu (`xfs_growfs` / `resize2fs`), o kayıt defterine
> "aslında daha fazla alanın var, kullanabilirsin" der.
>
> **Tek komutta yapmak (günlük kullanımda önerilen yol):**
> ```bash
> sudo lvextend -r -L +5G /dev/vgdata/lv_web
> ```
> `-r` (`--resizefs`) bayrağı, LV'yi büyüttükten hemen sonra üzerindeki dosya
> sistemi tipini (ext4 mü xfs mi) kendi anlayıp doğru büyütme komutunu otomatik
> çalıştırır. İki adımı tek komuta indirir, "unuttum" riskini ortadan kaldırır.

Bunların hepsi **LV bağlıyken, sistem çalışırken** yapılır — kesinti gerekmez. Bu,
LVM'in klasik bölümlemeye göre en somut avantajıdır.

### Senaryo B: VG dolu — yeni disk ekleyerek havuzu büyüt

VFree sıfıra yaklaştıysa, önce havuzun kendisini büyütmen gerekir:

```bash
# 1. Yeni diski hazırla (2. bölümdeki PV adımının aynısı)
sudo pvcreate /dev/sdd1

# 2. Havuza (VG'ye) ekle
sudo vgextend vgdata /dev/sdd1
sudo vgs                                    # VFree arttı mı, doğrula

# 3. Artık büyümüş havuzdan LV'yi genişlet
sudo lvextend -r -l +100%FREE /dev/vgdata/lv_web
df -h
```

Görüldüğü gibi bu, LEGO benzetmesindeki "kutuya yeni bir tuğla atmak" işleminin
birebir karşılığıdır — havuz büyür, sonra o büyümüş havuzdan istediğin dilime pay
verirsin.

### Küçültme — sırayı ters çevirirsen veri kaybedersin

Büyütme sırasında önce LV'yi büyütüp sonra dosya sistemini büyüttük ("alttan
yukarı"). Küçültürken bu sıra **tam tersine döner**:

```bash
# ⚠️ SADECE ext4. XFS'in küçültme desteği yoktur, hiçbir yolla küçültülemez.
sudo umount /var/lib/veritabani
sudo e2fsck -f /dev/vgdata/lv_db          # 1. ÖNCE kontrol ZORUNLU (bozuk FS'i küçültme)
sudo resize2fs /dev/vgdata/lv_db 10G      # 2. ÖNCE dosya sistemini 10G'a küçült
sudo lvreduce -L 10G /dev/vgdata/lv_db    # 3. SONRA LV'yi de 10G'a indir
sudo mount /var/lib/veritabani
```

> [!WARNING]
> **Neden sıra bu kadar kritik?**
> Dosya sistemi, verilerini LV'nin **başından sonuna kadar** dağıtmış durumdadır —
> belki en son dosyalardan biri tam da LV'nin son bloklarında oturuyordur. Eğer
> önce `lvreduce` ile LV'yi küçültürsen, LV'nin sonundaki bloklar (üzerindeki veriyle
> birlikte) **fiziksel olarak yok olur** — dosya sistemi bundan habersizdir, kayıt
> defterinde hâlâ o blokların var olduğunu sanır. Sonuç: bozuk, kurtarılamaz bir
> dosya sistemi.
>
> Bu yüzden önce dosya sistemine "küçüleceksin, verilerini önce güvenli bölgeye
> topla" dersin (`resize2fs ... 10G`), o bunu yaptıktan **sonra** LV'yi güvenle
> küçültürsün. Ezberlemenin en kolay yolu:
> **"Büyütürken alttan yukarı (LV → FS), küçültürken yukarıdan aşağı (FS → LV)."**
>
> `lvreduce -r` bu sırayı senin için otomatik doğru uygular; ama elle yapıyorsan
> sırayı asla karıştırma — bu, LVM'de gerçek veri kaybına yol açabilecek nadir
> işlemlerden biridir.

---

## 5. Snapshot — "anlık fotoğraf" mantığı

Snapshot, bir LV'nin **belirli bir andaki halinin** dondurulmuş bir kopyasıdır.
Ama dikkat: dosyaların tam bir kopyasını ayrı bir yere kopyalamaz (o zaman anında
oluşamaz, LV boyutu kadar yer kaplardı). Bunun yerine **Copy-on-Write (CoW — yazarken
kopyala)** denen bir teknikle çalışır.

> **Benzetme — silinebilir kalemle not tutmak:**
> Bir kitabın (origin LV'nin) üzerine düz kalemle (CoW) not almak yerine, kitabın
> tamamını fotokopi çekmek (tam kopya) yerine şunu yaparsın: kitabın kendisine
> hiç dokunmazsın; sadece **değiştirmek istediğin sayfanın orijinalini** ayrı bir
> deftere (snapshot alanına) kopyalarsın, sonra kitaptaki o sayfayı değiştirirsin.
> "Snapshot alındığı andaki hal" dediğinde, aslında şuna bakarsın: kitabın
> değişmeyen sayfaları (hâlâ kitaptalar) + değişen sayfaların deftere kopyalanmış
> **eski halleri**. İkisi birleşince o anki tam görüntü ortaya çıkar.
>
> Bu yüzden: (1) snapshot alma anında **hiçbir şey fiilen kopyalanmaz**, bu yüzden
> anında tamamlanır ve başlangıçta yer kaplamaz; (2) sadece origin LV'de bir şey
> **değiştikçe**, değişen kısmın eski hali deftere (snapshot alanına) yazılır —
> defter zamanla dolar.

```bash
sudo lvcreate -L 2G -s -n lv_db_snap /dev/vgdata/lv_db
#             │     │  └─ snapshot'ın adı
#             │     └─ bunun bir snapshot olduğunu belirt (-s / --snapshot)
#             └─ "defter"in (CoW alanı) boyutu — origin'in boyutu DEĞİL

sudo lvs                        # Origin ve Data% sütunlarına bak
```

`lvs` çıktısında `Origin` sütunu bu LV'nin hangi LV'nin snapshot'ı olduğunu, `Data%`
ise "defter"in yüzde kaç dolduğunu gösterir. `Data%` arttıkça snapshot'ın tehlikeye
girdiğini anlarsın (aşağıya bak).

### Kullanım senaryosu 1 — Yükseltme öncesi güvenlik ağı (en yaygın kullanım)

```bash
sudo lvcreate -L 5G -s -n kok_snap /dev/vgsystem/lv_root
sudo dnf update -y
# İyi gitti → snapshot artık gereksiz, sil, defter yer kaplamasın
sudo lvremove /dev/vgsystem/kok_snap
# Kötü gitti → aşağıdaki "geri dönme" adımlarıyla eski haline dön
```

Mantık: büyük bir sistem güncellemesi öncesi "eğer bir şey ters giderse geri
döneceğim bir kapı" bırakıyorsun. Sanal makinelerdeki "snapshot al" özelliğiyle
(VirtualBox'ta gördüğün) kavramsal olarak aynı şeydir — sadece LVM burada disk
seviyesinde, VM hipervizörü değil.

### Kullanım senaryosu 2 — Çalışan bir sistemde tutarlı yedek alma

```bash
sudo lvcreate -L 2G -s -n snap /dev/vgdata/lv_db
sudo mkdir /mnt/snap
sudo mount -o ro /dev/vgdata/snap /mnt/snap     # ext4 — salt okunur bağla
# XFS ise, origin ile snapshot'ın UUID'si aynı olduğundan çakışma çıkar:
sudo mount -o ro,nouuid /dev/vgdata/snap /mnt/snap

tar -czf /yedek/db-$(date +%F).tar.gz /mnt/snap
sudo umount /mnt/snap
sudo lvremove -y /dev/vgdata/snap
```

**Neden doğrudan orijinal LV'yi yedeklemek yerine bu yolu izliyoruz?** Çünkü
veritabanı gibi sürekli yazan bir servis çalışırken doğrudan onun dosyalarını
kopyalarsan, kopyalama süresince dosyalar değişebilir — yedek dosya içi tutarsız
(bir kısmı eski, bir kısmı yeni veri) çıkabilir. Snapshot alma anı **donmuş bir
kare**dir; o kareyi ayrı bir yerden okuyup yedeklersin, bu sırada veritabanı normal
çalışmaya devam eder, hiç durmaz.

### Geri dönme (merge) — snapshot'taki hale dönmek

```bash
sudo umount /var/lib/veritabani
sudo lvconvert --merge /dev/vgdata/lv_db_snap
sudo mount /var/lib/veritabani
```

`--merge`, snapshot'ta "defterde" tuttuğun eski sayfaları geri kitaba (origin LV'ye)
yazar — yani origin, snapshot alındığı andaki haline döner, snapshot'ın kendisi de
bu işlemle birlikte yok olur. LV o an bağlıysa (mounted), merge işlemi hemen değil,
**bir sonraki etkinleştirmede** (pratikte reboot'ta) gerçekleşir — kök dosya sistemi
için `lvconvert --merge` + `reboot` gerekir.

> [!WARNING]
> **Snapshot'ın boyutu neden kritik?**
> "Defter" (CoW alanı) sabit boyutludur (`-L 2G` gibi verdiğin değer). Origin LV'de
> ne kadar çok veri **değişirse**, defter o kadar dolar. Defter tamamen dolarsa
> (`Data%` 100'e ulaşırsa) snapshot **geçersiz** olur — artık merge edilemez,
> okunamaz, tamamen kullanılamaz hale gelir. Bunu önlemek için:
> - Değişecek veri miktarı kadar boyut ver — genelde origin'in **%10-20**'si
>   makul bir başlangıç noktasıdır (ne kadar yazma olacağına göre değişir).
> - Doluluğu izle: `watch -n5 'sudo lvs'`
> - Dolmadan büyüt: `sudo lvextend -L +2G /dev/vgdata/lv_db_snap`
>
> Ayrıca unutma: **snapshot bir yedek değildir.** Aynı VG'de, çoğu zaman aynı
> fiziksel disklerde durur. Disk fiziksel olarak bozulursa origin de snapshot da
> birlikte gider. Gerçek yedek için `tar`/`rsync` ile veriyi **başka bir diske veya
> makineye** çıkarman gerekir (yukarıdaki senaryo 2 tam olarak bunu yapar).
>
> Son bir performans notu: snapshot açıkken origin'e her yazma işlemi **iki kat**
> işe dönüşür (asıl yazma + defterin CoW kopyalaması). Bu yüzden snapshot'ı işin
> bitince hemen silmek (uzun süre açık bırakmamak) hem alan hem performans açısından
> önemlidir.

---

## 6. İzleme, taşıma, silme

### İzleme — "şu an sistemde ne var, ne durumda?"

```bash
sudo pvs ; sudo vgs ; sudo lvs          # ⭐ hızlı üçlü — üç katmanı tek bakışta gör
sudo lvs -o +devices                    # LV hangi PV'lerde (fiziksel yerleşim)
sudo lvs -a -o +seg_pe_ranges           # extent'lerin tam dağılımı
sudo pvdisplay -m /dev/sdb1             # PV'nin extent haritası
sudo vgdisplay -v vgdata
lsblk                                   # görsel ağaç — PV/VG/LV hiyerarşisi net görünür
sudo dmsetup ls                         # device-mapper'ın gördüğü ham aygıtlar
```

### Disk değiştirme (`pvmove`) — sistem çalışırken bir diski boşaltma

Senaryo: elindeki bir fiziksel disk eskiyor/arızalanmaya başlıyor, onu sistemden
çıkarman gerekiyor, ama üzerinde canlı veri var ve sunucuyu kapatamıyorsun.

```bash
sudo pvmove /dev/sdb1                   # sdb1 üzerindeki verileri VG'deki diğer PV'lere taşı
sudo pvmove /dev/sdb1 /dev/sdd1         # belirli bir hedefe taşımak istersen
sudo pvmove -b /dev/sdb1                # arka planda çalıştır (uzun sürebilir)
sudo pvs                                # sdb1 boşaldı mı, doğrula

sudo vgreduce vgdata /dev/sdb1          # artık boş olan sdb1'i havuzdan çıkar
sudo pvremove /dev/sdb1                 # üzerindeki LVM etiketini sil
# Artık diski fiziksel olarak sistemden çıkarabilirsin
```

**Nasıl çalışır?** `pvmove`, `sdb1` üzerindeki her extent'i, VG'deki diğer PV'lerde
boş bulduğu extent'lere teker teker kopyalar, kopyalama bitince o extent'in
"gerçek adresi"ni günceller — bütün bu süreçte LV bağlı ve kullanımda kalabilir,
uygulamalar kesinti yaşamaz. Bu, LVM'in en etkileyici, klasik bölümlemede karşılığı
olmayan özelliklerinden biridir.

### Silme — kurulumun tam tersi sırayla

```bash
sudo umount /var/www
# fstab'daki ilgili satırı da sil, yoksa bir sonraki mount -a hata verir
sudo lvremove /dev/vgdata/lv_web        # önce LV
sudo vgremove vgdata                    # sonra VG (içindeki tüm LV'ler silinmiş olmalı)
sudo pvremove /dev/sdb1 /dev/sdc1       # en son PV etiketlerini kaldır
```

Mantık kurulumun aynadaki yansımasıdır: kurarken PV→VG→LV sırasıyla ilerledin,
silerken LV→VG→PV sırasıyla geri sarıyorsun — her katman, üstündeki katman
temizlenmeden silinemez (bir VG içinde hâlâ LV varken `vgremove` hata verir).

### Yeniden adlandırma / etkinleştirme

```bash
sudo lvrename vgdata lv_eski lv_yeni
sudo vgrename vgeski vgyeni
sudo vgchange -a y vgdata               # VG'yi etkinleştir (LV'leri kullanıma aç)
sudo vgchange -a n vgdata               # devre dışı bırak (LV'lere erişimi kapat)
sudo vgimport / vgexport                # bir VG'yi başka bir sisteme taşırken kullanılır
```

### Yapılandırma yedeği — LVM kendi metadata'sını zaten yedekler

```bash
ls /etc/lvm/backup/ /etc/lvm/archive/
sudo vgcfgbackup vgdata                 # elle yedek al
sudo vgcfgrestore -l vgdata             # geçmiş yedekleri listele
sudo vgcfgrestore -f /etc/lvm/archive/vgdata_00003.vg vgdata   # eski bir metadata haline dön
```

LVM, her yapısal değişiklikte (LV oluşturma, silme, VG büyütme...) **metadata'nın**
(hangi PV'lerin hangi VG'de olduğu, hangi LV'lerin nerede durduğu bilgisi) otomatik
bir yedeğini `/etc/lvm/archive/` altına yazar. Yanlışlıkla bir `lvremove` yaptıysan
ve **veri hâlâ diskte fiziksel olarak duruyorsa** (üzerine yeni bir şey yazılmadıysa),
bu dosyalardan eski metadata'yı geri yükleyip LV'yi "yeniden var etmek" mümkün
olabilir. Bu bir kurtarma senaryosudur, günlük iş akışı değildir — ama var olduğunu
bilmek, panik anında hayat kurtarır.

---

## 7. Thin provisioning (bilgi düzeyinde)

Normal bir LV oluşturduğunda (`lvcreate -L 5G`), o 5 GB anında havuzdan **rezerve
edilir** — başka hiçbir LV o alanı kullanamaz, LV boş bile olsa.

**Thin (ince) LV** farklı çalışır: alanı **kullandıkça** ayırır. Bu, bir havuzda
fiilen 100 GB varken, toplamı 500 GB'a varan LV'ler tanımlayabileceğin anlamına
gelir (**overcommit** — "vaat edilen toplam, gerçek kapasiteyi aşıyor" demek).

> **Benzetme:** Bir bankanın, elindeki mevduatın tamamından fazlasını kredi olarak
> vermesi gibi düşün — herkesin aynı anda parasını çekmeyeceği varsayımıyla çalışır.
> Thin LV'lerde de "herkesin aynı anda tüm alanını doldurmayacağı" varsayılır.

```bash
sudo lvcreate -L 50G --thinpool havuz vgdata
sudo lvcreate -V 100G --thin -n lv_ince vgdata/havuz
sudo lvs -a
```

> [!WARNING]
> **Overcommit'in riski**
> Havuz (gerçek 50 GB) dolarsa, **o havuzu paylaşan tüm thin LV'ler** yazma hatası
> vermeye başlar — banka örneğindeki "herkes aynı anda parasını çekmeye kalkarsa"
> senaryosunun karşılığı. Bu yüzden izleme şarttır:
> `/etc/lvm/lvm.conf` içindeki `thin_pool_autoextend_threshold` ayarı, havuz belli
> bir doluluğa ulaştığında otomatik büyümesini sağlayabilir.
> İyi haber: thin snapshot'lar (normal snapshot'ın aksine) önceden hiç alan
> ayırmaz, bu yüzden thin havuzlarda çok sayıda snapshot almak neredeyse bedavadır —
> kurumsal ortamlarda thin provisioning'in asıl çekiciliği budur.

---

## 8. Dağıtım farkları

| Konu | RHEL / Rocky / Alma | Debian / Ubuntu |
|---|---|---|
| Kurulumda varsayılan | **LVM ile gelir** (Anaconda kurulumcusu otomatik VG/LV kurar) | Manuel seçilir (Ubuntu kurulumcusunda kutu var, işaretlemezsen düz bölüm) |
| Kök VG adı | genelde `rl` / `rocky` / `almalinux` | genelde `vgubuntu`, `debian-vg` |
| Kök FS | **XFS** — küçültülemez ⚠️ | **ext4** — küçültülebilir |
| Büyütme komutu | `xfs_growfs /bağlama/noktası` | `resize2fs /dev/vg/lv` |
| Paket | `lvm2` (kurulu gelir) | `lvm2` (kurulmalı olabilir) |
| Alternatif | Stratis (RHEL 8+, LVM+XFS'i basitleştiren sarmalayıcı) | ZFS (Ubuntu'da resmi destekleniyor) |

> XFS'te `xfs_growfs` **bağlama noktası** ister ("hangi dizine bağlıysa onu büyüt"),
> `resize2fs` ise **aygıt yolu** ister ("hangi LV/bölümü büyütüyorsan onu ver").
> Bu ayrım komutları birbirine karıştırıp yanlış argüman vermeye çok müsaittir.
> `lvextend -r` kullanırsan bu farkı hiç düşünmene gerek kalmaz — otomatik doğrusunu
> seçer.

---

## 🧪 Lab

> Hipervizörden VM'e **3 adet 5 GB** ek disk ekle: `sdb`, `sdc`, `sdd`.

1. `sdb` ve `sdc` üzerinde birer bölüm oluştur, LVM tipine ayarla, `pvcreate` yap.
2. `vgdata` adında bir VG oluştur. `vgs` ile toplam boyutu doğrula.
3. 3 GB'lık `lv_web` (xfs) ve 2 GB'lık `lv_db` (ext4) oluştur, `/srv/web` ve `/srv/db`'ye
   bağla, fstab'a ekle, `mount -a` ile test et.
4. `lv_web`'i 2 GB büyüt — **önce `-r` bayrağı olmadan** yap ve `df -h`'ın değişmediğini gör.
   Sonra `xfs_growfs` ile dosya sistemini büyüt. İki katmanı gözlemle.
5. `lv_db`'yi bu sefer `lvextend -r -L +1G` ile tek komutta büyüt.
6. VG'yi doldur. `sdd`'yi `pvcreate` + `vgextend` ile havuza ekle, `lv_web`'i
   `-l +100%FREE` ile kalan her şeye genişlet.
7. `/srv/db` içine dosyalar koy. `lv_db`'nin 1 GB'lık snapshot'ını al.
   Orijinaldeki dosyaları sil. Snapshot'ı `/mnt/snap`'e salt okunur bağla,
   dosyaların orada durduğunu gör.
8. `lvconvert --merge` ile snapshot'tan geri dön, dosyaların geri geldiğini doğrula.
9. Bir snapshot al, `dd` ile origin'e çok veri yaz, `lvs` ile `Data%`'in yükselişini
   `watch -n2 'sudo lvs'` ile izle. Snapshot'ı doldurup geçersiz kılmayı dene — sonucu gör.
10. `pvmove /dev/sdb1` ile veriyi diğer disklere taşı, `vgreduce` + `pvremove` ile
    `sdb1`'i havuzdan tamamen çıkar. Sistemin kesintisiz çalıştığını doğrula.
11. `lvs -o +devices` ile hangi LV'nin hangi fiziksel diskte olduğunu çıkar.
12. (İleri) `lv_db`'yi (ext4) 1 GB'a küçült — doğru sırayla: `umount` → `e2fsck -f` →
    `resize2fs` → `lvreduce`. Sonra `lv_web`'i (xfs) küçültmeyi dene, neden olmadığını gör.

---

## ❓ Kendini test et

**S1.** `lvextend -L +10G` yaptın ama `df -h` hâlâ eski boyutu gösteriyor. Neden?

<details><summary>Cevap</summary>
`lvextend` sadece blok aygıtını büyüttü; dosya sistemi hâlâ eski boyutunu biliyor.
`xfs_growfs /bağlama/noktası` (XFS) veya `resize2fs /dev/vg/lv` (ext4) gerekir.
Ya da baştan `lvextend -r` kullanılır.
</details>

**S2.** LV küçültürken sıra neden önemlidir?

<details><summary>Cevap</summary>
Önce dosya sistemi küçültülmeli (`resize2fs`), sonra LV (`lvreduce`).
Ters yaparsan dosya sisteminin sonundaki veriyi kesmiş olursun — **veri kaybı**.
Büyütmede sıra tersidir: önce LV, sonra FS.
</details>

**S3.** Snapshot'ın `Data%` değeri 100'e ulaştı. Ne oldu?

<details><summary>Cevap</summary>
CoW alanı doldu, snapshot **geçersiz** oldu — artık kullanılamaz, merge edilemez.
Origin'e yapılan değişiklikler snapshot alanına sığmadı.
Önlem: yeterli boyut vermek, `lvs` ile izlemek, dolmadan `lvextend` ile büyütmek,
snapshot'ı uzun süre açık bırakmamak.
</details>

**S4.** LVM RAID yerine geçer mi?

<details><summary>Cevap</summary>
Hayır. Varsayılan (linear) LVM yedeklilik sağlamaz — VG'deki bir disk ölürse
o diskteki extent'lerde duran veri kaybolur. Yedeklilik için altta donanım RAID
veya `mdadm` olmalı (LVM'in `--type raid1` desteği vardır ama yaygın kullanım bu değildir).
</details>

**S5.** Çalışan bir sunucudan bir diski çıkarman gerekiyor ve üzerinde LVM verisi var. Nasıl?

<details><summary>Cevap</summary>
`pvmove /dev/sdX1` ile verileri VG'deki diğer PV'lere **çevrimiçi** taşı,
`vgreduce vg /dev/sdX1` ile VG'den çıkar, `pvremove /dev/sdX1` ile PV işaretini sil.
VG'de yeterli boş alan olması şart. Kesinti gerekmez.
</details>

---

## 📋 Hızlı referans

```bash
# Kurulum
pvcreate /dev/sdb1
vgcreate vgdata /dev/sdb1
lvcreate -L 5G -n lv_web vgdata
lvcreate -l 100%FREE -n lv_log vgdata
mkfs.xfs /dev/vgdata/lv_web

# Büyütme (tek komut — tercih et)
lvextend -r -L +5G /dev/vgdata/lv_web
# veya iki adım:
lvextend -L +5G /dev/vgdata/lv_web
xfs_growfs /var/www          # XFS → BAĞLAMA NOKTASI
resize2fs /dev/vgdata/lv_db  # ext4 → AYGIT

# Disk ekleme
pvcreate /dev/sdd1 && vgextend vgdata /dev/sdd1

# Snapshot
lvcreate -L 2G -s -n snap /dev/vgdata/lv_db
mount -o ro[,nouuid] /dev/vgdata/snap /mnt/snap
lvconvert --merge /dev/vgdata/snap
lvremove -y /dev/vgdata/snap

# Disk çıkarma
pvmove /dev/sdb1 && vgreduce vgdata /dev/sdb1 && pvremove /dev/sdb1

# İzleme
pvs ; vgs ; lvs ; lvs -o +devices ; lsblk
vgcfgrestore -l vgdata       # metadata geçmişi
```
