---
tags: [linux, egitim, paket, dnf, apt]
modul: 07
durum: tamamlandi
---

# 07 — Paket Yönetimi

> **Ön koşul:** [01-sunucu-kurulumu](01-sunucu-kurulumu.md)
> **Süre:** ~2.5 saat

## Hedefler

- [ ] Paket ve bağımlılık kavramını anlıyorum
- [ ] `rpm`/`dpkg` (düşük seviye) ile `dnf`/`apt` (yüksek seviye) farkını biliyorum
- [ ] Paket kurma/kaldırma/arama/güncelleme işlemlerini iki ailede de yapıyorum
- [ ] Depo (repository) ekleyip yönetebiliyorum
- [ ] "Bu dosya hangi paketten geldi?" sorusunu cevaplayabiliyorum

---

## 1. Paket nedir?

**Benzetme:** Bir paketi, mobilya mağazasından aldığın **kutulu bir mobilya**
gibi düşün. Kutunun içinde sadece parçalar (program dosyaları) yok — bir montaj
talimatı (kurulum betiği), "bu ürünü monte etmek için şu vidalara ihtiyacın var"
notu (bağımlılıklar) ve ürünün ne olduğunu, kaç numara olduğunu söyleyen bir
etiket (metadata: ad, sürüm, mimari) de var. Paket yöneticisi, bu kutuyu açıp
talimata göre doğru yerlere yerleştiren, gereken diğer parçaları da otomatik
sipariş eden bir montaj ekibi gibi çalışır.

Bir paket şunları içeren arşivdir:
- Program dosyaları (binary, kütüphane, yapılandırma, man sayfası)
- **Metadata**: ad, sürüm, mimari, bağımlılıklar, hangi dosyayı nereye koyacağı
- Kurulum öncesi/sonrası çalışacak betikler (scriptlet)

**Bağımlılık (dependency):** A paketi B kütüphanesine ihtiyaç duyar. Paket yöneticisi
bunu otomatik çözer. Elle `.rpm` kurmaya çalışırsan "dependency hell"e düşersin —
işte bu yüzden `dnf`/`apt` var.

"Dependency hell" (bağımlılık cehennemi) tam olarak ne demek, somutlaştıralım:
Diyelim `nginx` paketini kurmak istiyorsun, ama `nginx` çalışabilmek için
`openssl-libs` kütüphanesine ihtiyaç duyuyor. Sen sadece `nginx.rpm` dosyasını
elle kurmaya çalışırsan (`rpm -ivh nginx.rpm`), sistem "openssl-libs
bulunamadı" diye hata verir ve kurulumu reddeder. Sen şimdi gidip
`openssl-libs`'i bulman gerekir — ama o da başka bir kütüphaneye ihtiyaç
duyuyor olabilir. Bu zincir büyüdükçe elle takip etmesi imkânsız hale gelir.
`dnf`/`apt` gibi yüksek seviye araçlar, bu zinciri **otomatik olarak** çözüp,
gereken her şeyi sırayla indirip kurar — sen sadece "nginx istiyorum" dersin.

### İki katman

| Katman | RHEL ailesi | Debian ailesi | Ne yapar |
|---|---|---|---|
| **Düşük seviye** | `rpm` | `dpkg` | Tek paketi kurar/sorgular. **Bağımlılık ÇÖZMEZ** |
| **Yüksek seviye** | `dnf` (eski: `yum`) | `apt` | Depodan indirir, **bağımlılıkları çözer** |

Bu iki katmanın neden ayrı tutulduğunu anlamak faydalı: **düşük seviye**
araçlar (`rpm`, `dpkg`), sadece elindeki **tek bir paket dosyasıyla** ne
yapacağını bilir — kur, kaldır, hangi dosyaları içerdiğini söyle. İnternete
çıkıp "bu paketin ihtiyaç duyduğu diğer paketleri bul" gibi bir iş yapmazlar,
çünkü bu onların işi değildir; onlar "montaj ekibi" değil, "kutuyu açıp
içindekini yerleştiren" basit bir araçtır. **Yüksek seviye** araçlar (`dnf`,
`apt`) bunun üzerine inşa edilir: bir **depo** (repository — internetteki ya
da yerel bir paket deposu) ile konuşurlar, bağımlılık ağacını hesaplarlar,
gereken her şeyi indirip doğru sırayla düşük seviye araca (`rpm`/`dpkg`)
kurdururlar.

Günlük iş `dnf`/`apt` ile yapılır. `rpm`/`dpkg` sorgulama ve yerel dosya kurulumu için.

### Paket adı anatomisi

```
nginx-1.24.0-1.el9.x86_64.rpm
  │      │    │  │     └─ mimari (x86_64, aarch64, noarch)
  │      │    │  └─ dağıtım etiketi (Enterprise Linux 9)
  │      │    └─ release (paketleme revizyonu)
  │      └─ upstream sürüm
  └─ paket adı

nginx_1.24.0-2_amd64.deb
  │     │      │    └─ mimari (amd64, arm64, all)
  │     │      └─ Debian revizyonu
  │     └─ upstream sürüm
  └─ paket adı
```

Bu isim parçalarının her biri farklı bir soruya cevap verir:

- **Upstream sürüm** (`1.24.0`), yazılımın **kendi geliştiricilerinin**
  verdiği sürüm numarasıdır — nginx'in kendisi "1.24.0" der, dağıtımdan
  bağımsızdır.
- **Release/revizyon** (`el9` ailesinde `-1`, Debian'da `-2`), aynı upstream
  sürümün, **dağıtımın kendi paketleme ekibi tarafından** kaç kez yeniden
  paketlendiğini gösterir — örneğin bir güvenlik yaması sadece paketleme
  betiğinde değişiklik gerektiriyorsa (yazılımın kendisi değişmeden), release
  numarası artar ama upstream sürüm aynı kalır.
- **Dağıtım etiketi** (`el9`), paketin **hangi dağıtım sürümü için**
  derlendiğini belirtir — bir RHEL 8 paketini RHEL 9'a kurmaya çalışmak
  genelde çalışmaz, kütüphane sürümleri uyuşmayabilir.
- **Mimari** (`x86_64`, `aarch64`, `noarch`), paketin hangi işlemci mimarisi
  için derlendiğini gösterir. `noarch`, o paketin makine koduna
  **derlenmemiş** olduğu, herhangi bir mimaride çalışabilecek (script,
  yapılandırma dosyası gibi) içerik taşıdığı anlamına gelir.

---

## 2. RHEL ailesi: rpm, yum, dnf

> `yum` → `dnf` geçişi RHEL 8 ile oldu. RHEL 8/9'da `yum` bir **symlink**'tir, `dnf`'i
> çağırır. Kurstaki tüm `yum` komutları `dnf` ile birebir aynı çalışır.
> RHEL 9'da altta `libdnf5` var, `dnf5` Fedora'da varsayılan olmaya başladı.

Bu geçişin pratik bir sonucu var: eski dokümantasyonda veya internette
`yum install X` yazan bir talimat görürsen, korkma — RHEL 8/9'da `yum`
komutunu yazdığında sistem sessizce `dnf`'i çalıştırır, ikisi arasında
davranış farkı yoktur, sadece isim farkı vardır (symlink, bir dosya adının
başka bir dosyaya "takma ad" olarak işaret etmesidir — Gün 1'de sembolik
link kavramını görmüştün, bu onun sistem seviyesinde bir uygulamasıdır).

### dnf — günlük kullanım

```bash
sudo dnf install nginx                 # kur
sudo dnf install -y nginx httpd        # onaysız, çoklu
sudo dnf remove nginx                  # kaldır
sudo dnf update                        # tümünü güncelle
sudo dnf update nginx                  # tek paketi
sudo dnf check-update                  # güncelleme var mı (kurmaz)
sudo dnf upgrade --refresh             # önbelleği tazeleyip güncelle

dnf search web server                  # ada/açıklamaya göre ara
dnf info nginx                         # detaylı bilgi
dnf list installed                     # kurulu paketler
dnf list available                     # depoda mevcut olanlar
dnf provides /usr/sbin/nginx           # ⭐ bu dosya hangi pakette
dnf provides "*/htpasswd"              # komutu bulamıyorsan bunu kullan
dnf repoquery -l nginx                 # paketin içerdiği dosyalar
dnf deplist nginx                      # bağımlılıklar

sudo dnf clean all                     # önbellek temizle
sudo dnf autoremove                    # artık gerekmeyen bağımlılıkları sil
```

Bu komutlardan bazılarının **neden** ayrı ayrı var olduğunu açalım, çünkü
ilk bakışta benzer görünüyorlar:

- **`check-update` ile `update` farkı** — `check-update` sadece "şunlar
  güncellenebilir" diye **raporlar**, hiçbir şeyi değiştirmez; `update` ise
  fiilen indirip kurar. `check-update`, otomatik izleme betiklerinde ("yeni
  güncelleme var mı, varsa bana haber ver ama kurma") kullanışlıdır.
- **`dnf provides` neden önemli** — bazen bir komutun adını bilirsin
  (`htpasswd` gibi) ama bu komutun hangi **pakette** geldiğini bilmezsin;
  paket adı komutla aynı olmayabilir (`htpasswd` aslında `httpd-tools`
  paketinden gelir). `provides`, dosya yolundan geriye doğru gidip "bu dosyayı
  hangi paket sağlıyor" sorusuna cevap verir — kurulum öncesi araştırma için
  vazgeçilmezdir.
- **`autoremove`** — bir paketi kurarken onunla birlikte otomatik olarak
  bağımlılık paketleri de kurulur. Sen ana paketi kaldırdığında, o
  bağımlılıklar **otomatik silinmez** (belki başka bir paket de onları
  kullanıyordur diye sistem temkinlidir) — zamanla artık kimsenin
  kullanmadığı "yetim" bağımlılıklar birikir. `autoremove`, artık hiçbir
  paketin ihtiyaç duymadığı bu yetim paketleri temizler.

### Grup ve modüller

```bash
dnf group list
sudo dnf group install "Development Tools"     # derleme araçları
sudo dnf groupinstall "Server with GUI"

# Modüler içerik (RHEL 8/9) — aynı yazılımın farklı sürüm akışları
dnf module list nodejs
sudo dnf module install nodejs:20
sudo dnf module reset nodejs           # akış değiştirmeden önce
```

"Modüler içerik" kavramı RHEL 8 ile geldi ve şu sorunu çözer: bazı yazılımlar
(Node.js, PHP, PostgreSQL gibi) çok sık sürüm çıkarır, ama bir RHEL sürümü
(örneğin RHEL 9) yıllarca aynı kalır. Eskiden bu, RHEL'in deposunda o
yazılımın sadece **tek, sabit** bir sürümünün bulunabileceği anlamına
gelirdi. Modüller, aynı RHEL sürümü içinde birden fazla "akış" (stream) —
yani birden fazla sürüm seçeneği (nodejs:18, nodejs:20 gibi) — sunmayı
mümkün kılar; sen hangi akışı istediğini seçip onu kurarsın.

### Geçmiş ve geri alma — dnf'in süper gücü

```bash
dnf history                            # yapılan işlemler
dnf history info 15                    # 15 numaralı işlemin detayı
sudo dnf history undo 15               # ⭐ o işlemi GERİ AL
sudo dnf history rollback 12           # 12'ye kadar geri sar
```
Bu, `apt`'ta olmayan çok değerli bir özelliktir. Bir güncelleme sistemi bozarsa
`dnf history undo` ile geri dönebilirsin.

Bunun nasıl çalıştığını biraz açalım: `dnf`, çalıştırdığın **her** işlemi
(kurulum, kaldırma, güncelleme) numaralandırılmış bir işlem geçmişinde tutar
— hangi paketlerin hangi sürümden hangi sürüme değiştiğini, hangilerinin
eklendiğini/kaldırıldığını hatırlar. `history undo 15`, sadece "15 numaralı
işlemde ne olduysa tersini yap" der — eğer o işlemde `nginx` 1.24'ten 1.26'ya
yükseltildiyse, `undo` onu tekrar 1.24'e indirir (paket önbelleğinde eski
sürüm hâlâ varsa, yoksa depodan tekrar indirmeye çalışır). Bu, "bir
güncelleme sistemi bozdu, ama tam olarak neyi değiştirdiğini hatırlamıyorum"
durumunda hayat kurtarıcıdır.

### rpm — düşük seviye sorgulama

```bash
rpm -qa                       # tüm kurulu paketler
rpm -qa | grep nginx
rpm -qi nginx                 # paket bilgisi
rpm -ql nginx                 # paketin dosyaları
rpm -qc nginx                 # sadece YAPILANDIRMA dosyaları ⭐
rpm -qd nginx                 # dokümantasyon dosyaları
rpm -qf /etc/nginx/nginx.conf # ⭐ bu dosya hangi paketten geldi
rpm -q --changelog nginx      # değişiklik geçmişi
rpm -V nginx                  # ⭐ dosyalar değiştirilmiş mi (bütünlük kontrolü)

sudo rpm -ivh paket.rpm       # kur (bağımlılık çözmez!)
sudo rpm -Uvh paket.rpm       # yükselt
sudo rpm -e paket             # kaldır
rpm2cpio paket.rpm | cpio -idmv   # kurmadan içeriğini çıkar
```

`rpm -q` ailesindeki bayrakların ortak mantığı: `q` "query" (sorgula)
demektir, sonuna eklenen harf **neyi** sorgulayacağını belirler — `a` (all,
tüm kurulu paketler), `i` (info, bilgi), `l` (list, dosya listesi), `c`
(config, sadece yapılandırma dosyaları), `f` (file, "bu dosya hangi
paketten" — burada `-q` normal paket adı yerine bir **dosya yolu** bekler).

`rpm -V nginx` çıktısı: `S` boyut, `M` izin, `5` MD5, `T` zaman değişmiş demektir.
Değiştirilmiş yapılandırma dosyalarını bulmak ve güvenlik denetimi için kullanılır.

Bunun nasıl çalıştığı ilginçtir: paket **kurulurken**, `rpm` her dosyanın
"orijinal hâlinin" bir özetini (boyut, izin, MD5 özeti, zaman damgası gibi)
kendi veritabanında saklar. `rpm -V` sonradan, o dosyaların **şu anki**
hâlini bu kayıtlı orijinal hâlle karşılaştırır; fark varsa ilgili harfi
basar. Bu, "bir yönetici bu yapılandırma dosyasını elle değiştirmiş mi" ya
da (güvenlik açısından daha ciddisi) "bir saldırgan sistem dosyalarını
değiştirmiş mi" sorularına cevap verir — hiçbir fark yoksa `rpm -V` sessiz
kalır (çıktı vermez), bu da "her şey orijinal hâliyle duruyor" demektir.

### Depo yönetimi

```bash
dnf repolist                          # etkin depolar
dnf repolist --all                    # devre dışılar dahil
ls /etc/yum.repos.d/                  # depo tanım dosyaları
```

Depo dosyası (`/etc/yum.repos.d/ornek.repo`):
```ini
[ornek]
name=Ornek Depo
baseurl=https://repo.ornek.com/el9/$basearch/
enabled=1
gpgcheck=1
gpgkey=https://repo.ornek.com/RPM-GPG-KEY-ornek
```

Bu depo tanımının her satırının bir amacı var: `baseurl`, paketlerin
**nereden** indirileceğidir (`$basearch` değişkeni, sistemin mimarisine göre
otomatik `x86_64` gibi bir değerle değiştirilir — aynı `.repo` dosyası farklı
mimarilerde çalışabilir). `enabled=1`, bu deponun **aktif** olduğunu belirtir
— `0` yaparsan depo tanımlı kalır ama `dnf` onu göz ardı eder. `gpgcheck=1` +
`gpgkey`, **çok önemli bir güvenlik önlemidir**: her indirilen paketin,
belirtilen GPG anahtarıyla **imzalanmış** olduğunu doğrular — bu, paketin
gerçekten o depo sahibi tarafından yayınlandığını, yolda (örneğin bir
ortadaki-adam saldırısıyla) değiştirilmediğini garanti eder. `gpgcheck=0`
yapmak (imza kontrolünü kapatmak) ciddi bir güvenlik riskidir, sadece tam
güvendiğin ve GPG anahtarı olmayan iç/test depolarında yapılmalıdır.

```bash
sudo dnf config-manager --add-repo https://.../ornek.repo
sudo dnf config-manager --set-enabled crb          # RHEL 9: CodeReady Builder
sudo dnf config-manager --set-disabled ornek
sudo dnf install epel-release                      # EPEL: ekstra paketler ⭐
sudo rpm --import https://.../RPM-GPG-KEY
sudo dnf --enablerepo=epel install htop            # sadece bu komut için etkinleştir
```

> **EPEL nedir?** Extra Packages for Enterprise Linux. RHEL'de olmayan çok sayıda
> paket (htop, iftop, ncdu, fail2ban) buradan gelir. Rocky/Alma'da neredeyse
> her zaman ilk kurulan şeydir.

EPEL'in neden var olduğunu anlamak faydalı: RHEL ve türevleri (Rocky, Alma),
**kararlılığı** önceliklendirir — resmi depolarına sadece uzun süre test
edilmiş, kurumsal destek verilebilecek paketleri koyarlar. Bu yüzden birçok
popüler ama "temel olmayan" araç (htop gibi basit bir izleme aracı bile)
resmi depoda **yoktur**. EPEL, Fedora projesi tarafından yönetilen, RHEL ile
uyumlu, ekstra paketler sağlayan **resmi olmayan ama güvenilir** bir ek
depodur — pratikte neredeyse her Rocky/Alma kurulumunda ilk yapılan iş bu
deponun eklenmesidir.

### Sürüm sabitleme

```bash
sudo dnf install python3-dnf-plugin-versionlock
sudo dnf versionlock add nginx-1.24.0
sudo dnf versionlock list
sudo dnf versionlock delete nginx
```
Üretimde bir paketin güncellenmesini istemiyorsan (ör. veritabanı sürümü) bu kullanılır.

Bunun neden gerekli olduğunu somutlaştıralım: diyelim üretim veritabanı
sunucunda PostgreSQL 15 çalışıyor ve uygulaman bu sürüme göre test edilmiş,
kararlı çalışıyor. Bir `dnf update` çalıştırdığında, depo PostgreSQL 16'yı
sunuyorsa, güncelleme bunu da yükseltmeye çalışabilir — ama sen bunu **henüz**
istemiyorsun (test edilmemiş, uygulamanı bozabilir). `versionlock`, o paketi
"dondurur": `dnf update` her çalıştığında diğer her şeyi günceller ama
kilitlenmiş paketi atlar, sen hazır olduğunda bilinçli olarak
`versionlock delete` edip elle güncellersin.

---

## 3. Debian ailesi: dpkg, apt

### apt — günlük kullanım

```bash
sudo apt update                    # ⭐ DEPO LİSTESİNİ günceller (paketleri DEĞİL)
sudo apt upgrade                   # paketleri günceller
sudo apt full-upgrade              # gerekirse paket kaldırarak günceller
sudo apt install nginx
sudo apt install -y nginx curl
sudo apt remove nginx              # kaldır, YAPILANDIRMA kalır
sudo apt purge nginx               # ⭐ yapılandırma dahil TEMİZ kaldır
sudo apt autoremove                # gereksiz bağımlılıkları sil
sudo apt clean                     # indirilen .deb önbelleğini sil

apt search "web server"
apt show nginx
apt list --installed
apt list --upgradable
apt-cache policy nginx             # hangi sürüm nereden gelecek ⭐
apt-file search /usr/sbin/nginx    # dosya→paket (apt-file kurulmalı)
```

`apt update` komutunun adı en çok yanlış anlaşılan komutlardan biridir —
"update" kelimesi "paketleri güncelle" gibi hissettirir ama **değildir**.
Şunu düşün: `apt`'ın, "hangi paketin hangi sürümü var, hangi depoda"
bilgisini tutan **yerel bir katalog kopyası** vardır (`/var/lib/apt/lists/`
altında). `apt update`, sadece bu **kataloğu** internetteki depolarla
senkronize eder — hiçbir paketi indirip kurmaz, sadece "artık depoda neler
var" bilgisini tazeler. Gerçek güncellemeyi yapan komut `apt upgrade`'dir, o
da bu tazelenmiş kataloğa bakarak hangi paketlerin yeni sürümü olduğunu
bulur ve indirir.

> ⚠️ **RHEL'den gelenlerin en sık hatası:** `apt install` demeden önce `apt update`
> demezsen depo listesi eski kalır, "paket bulunamadı" veya eski sürüm gelir.
> `dnf`'te bu gerekmez (otomatik tazeler). Alışkanlık: `sudo apt update && sudo apt install X`

Bu farkın kaynağı, iki ailenin farklı tasarım felsefesidir: `dnf`, her
kurulum komutunda depo metadata'sının **yeterince** güncel olup olmadığını
kendisi kontrol edip gerekirse arka planda tazeler — sen bunu düşünmek
zorunda kalmazsın. `apt` ise bu iki adımı (katalog tazeleme ve paket kurma)
kasıtlı olarak **ayrı** tutar; bu, kullanıcıya "ne zaman tazelensin"
konusunda daha fazla kontrol verir ama alışkanlık gerektirir.

> `apt` ile `apt-get` farkı: `apt` insan içindir (renkli, ilerleme çubuğu),
> `apt-get` betikler için kararlı arayüzdür. **Betiklerde `apt-get` kullan** —
> `apt` çıktı biçimini değiştirebilir ve uyarır.

Bu ayrımın sebebi: `apt`, terminalde oturan bir insan için tasarlanmıştır —
renkli çıktı, ilerleme çubukları, okunabilir özetler verir; ama tam bu
sebeple, geliştiricileri bu çıktının **biçimini** (kullanıcı deneyimini
iyileştirmek için) önceden haber vermeden değiştirebileceğini açıkça
belirtir. Bir otomasyon betiği, çıktının satır satır hep aynı formatta
kalacağına güvenmek zorundadır — bu yüzden betikler, arayüzü kasıtlı olarak
**sabit tutulan** `apt-get`'i kullanmalıdır.

### dpkg — düşük seviye

```bash
dpkg -l                        # kurulu paketler
dpkg -l | grep nginx
dpkg -L nginx                  # paketin dosyaları
dpkg -s nginx                  # paket durumu/bilgisi
dpkg -S /etc/nginx/nginx.conf  # ⭐ bu dosya hangi paketten
dpkg -c paket.deb              # .deb içeriğini kurmadan listele

sudo dpkg -i paket.deb         # kur (bağımlılık çözmez)
sudo apt install -f            # ⭐ dpkg sonrası eksik bağımlılıkları çöz
sudo apt install ./paket.deb   # ⭐ daha iyisi: apt ile yerel .deb kur (bağımlılık çözer)
sudo dpkg -r nginx             # kaldır
sudo dpkg -P nginx             # purge
sudo dpkg --configure -a       # yarım kalmış kurulumları tamamla
```

`dpkg -i paket.deb` ile `apt install ./paket.deb` arasındaki fark, RHEL
tarafındaki `rpm -ivh` / `dnf install ./x.rpm` farkının birebir aynısıdır:
`dpkg`, düşük seviye bir araç olduğu için sadece elindeki `.deb` dosyasını
kurar, eksik bağımlılık varsa hata verip durur. `apt install -f`
("fix-broken"), bu yarım kalmış durumu tespit edip eksik bağımlılıkları
depodan tamamlar. Ama daha temiz yol baştan `apt install ./paket.deb`
kullanmaktır — bu, `apt`'a "bu yerel dosyayı kur ama bağımlılıklarını depodan
çöz" der, tek adımda hallolur.

### Depo yönetimi

```bash
cat /etc/apt/sources.list
ls /etc/apt/sources.list.d/
```

Klasik biçim:
```
deb https://deb.debian.org/debian bookworm main contrib non-free
```

**Modern (deb822) biçim** — Debian 12 / Ubuntu 24.04 `.sources` dosyaları:
```
Types: deb
URIs: https://deb.debian.org/debian
Suites: bookworm
Components: main contrib
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
```

Bu iki biçimin taşıdığı bilgi aslında aynıdır, sadece yazım tarzı farklıdır.
Klasik biçimde tek satırda her şey (URL, dağıtım kod adı, bileşenler) yan
yana yazılır — okunması biraz zordur, özellikle çok satır olduğunda. Modern
`deb822` biçimi (Debian 12+/Ubuntu 24.04+'ta varsayılan), her bilgiyi ayrı
bir `Anahtar: Değer` satırına ayırır — daha okunabilir, düzenlemesi daha az
hataya açıktır. İkisi de işlevsel olarak eşdeğerdir, `apt` her ikisini de
okuyabilir.

Üçüncü parti depo ekleme (**güncel, doğru yöntem**):
```bash
# 1. GPG anahtarını keyring'e al
curl -fsSL https://ornek.com/key.gpg | sudo gpg --dearmor \
  -o /usr/share/keyrings/ornek.gpg

# 2. Depoyu anahtara bağlayarak ekle
echo "deb [signed-by=/usr/share/keyrings/ornek.gpg] https://ornek.com/apt stable main" \
  | sudo tee /etc/apt/sources.list.d/ornek.list

sudo apt update
```

Bu iki adımın **her ikisi de** güvenlik için gereklidir ve birbirinden
ayrılamaz: 1. adım, deponun sahibinin yayınladığı GPG **açık anahtarını**
indirip sistemde bir "keyring" dosyasına kaydeder (`--dearmor`, anahtarın
metin biçimini `apt`'ın anlayacağı ikili biçime çevirir). 2. adım, depo
tanımını eklerken `signed-by=...` ile "bu depodan gelen her paket, **sadece
bu spesifik anahtarla** imzalanmışsa güven" der. Bu ikili yapı sayesinde,
sistemdeki **başka** bir depo için eklenmiş bir anahtar, yanlışlıkla bu yeni
depodan gelen sahte paketleri onaylayamaz — her depo kendi anahtarına
bağlıdır.

> ⚠️ `apt-key add` **kullanılmıyor artık** (Debian 11+/Ubuntu 22.04+ deprecated).
> İnternette bulacağın eski rehberlerin çoğu bunu söyler; `signed-by` yöntemini kullan.

Eski `apt-key add` yönteminin terk edilmesinin sebebi tam olarak yukarıda
bahsedilen zafiyetti: `apt-key`, eklenen anahtarı **sistem genelinde geçerli,
her depoyu onaylayabilen** ortak bir havuza koyardı — yani üçüncü parti bir
depo için eklediğin bir anahtar, teorik olarak başka (ilgisiz) bir deponun
paketlerini de "güvenilir" olarak imzalayabilirdi. `signed-by`, her deponun
kendi anahtarıyla sınırlı kalmasını sağlayarak bu riski ortadan kaldırır.

```bash
sudo add-apt-repository ppa:kullanici/ppa     # Ubuntu PPA
sudo add-apt-repository --remove ppa:...
```

### Paket sabitleme (hold)

```bash
sudo apt-mark hold nginx        # güncelleme
sudo apt-mark unhold nginx
apt-mark showhold
```

Bu, RHEL tarafındaki `versionlock`'un Debian karşılığıdır — aynı amaca
hizmet eder: bir paketin `apt upgrade` sırasında dokunulmadan, olduğu
sürümde kalmasını sağlar.

---

## 4. İki aile karşılaştırma tablosu

| İşlem | RHEL / Rocky / Alma | Debian / Ubuntu |
|---|---|---|
| Depo listesini güncelle | (otomatik) | `apt update` |
| Paketleri güncelle | `dnf update` | `apt upgrade` |
| Kur | `dnf install X` | `apt install X` |
| Kaldır | `dnf remove X` | `apt remove X` |
| Yapılandırmayla kaldır | `dnf remove X` | `apt purge X` |
| Ara | `dnf search X` | `apt search X` |
| Bilgi | `dnf info X` | `apt show X` |
| Kurulu listesi | `dnf list installed` | `dpkg -l` |
| Paketin dosyaları | `rpm -ql X` | `dpkg -L X` |
| Dosya → paket | `dnf provides YOL` | `dpkg -S YOL` |
| Yerel dosya kur | `dnf install ./x.rpm` | `apt install ./x.deb` |
| Gereksizleri temizle | `dnf autoremove` | `apt autoremove` |
| Sürüm sabitle | `dnf versionlock` | `apt-mark hold` |
| Geçmişi geri al | `dnf history undo N` | ❌ yok |
| Depo dizini | `/etc/yum.repos.d/` | `/etc/apt/sources.list.d/` |
| Log | `/var/log/dnf.log` | `/var/log/apt/history.log` |

Bu tablodaki en çarpıcı satır **"Yapılandırmayla kaldır"** satırıdır ve iki
ailenin felsefe farkını gösterir: RHEL tarafında `dnf remove` **her zaman**
yapılandırma dosyalarını da siler (ayrı bir "purge" kavramı yoktur). Debian
tarafında ise `remove` **kasıtlı olarak** yapılandırmayı bırakır — mantık
şudur: belki paketi geçici olarak kaldırıp sonra tekrar kuracaksın, o zaman
eski ayarların (saatlerce yaptığın özelleştirmelerin) hâlâ orada durması
işine yarar. Gerçekten **hiçbir iz bırakmadan** silmek istiyorsan Debian'da
açıkça `purge` demen gerekir — bu farkı bilmeyen biri `apt remove` sonrası
"neden hâlâ /etc/nginx duruyor" diye şaşırabilir.

Bir diğer önemli satır: **"Geçmişi geri al"** — `dnf`'in `history undo`
özelliği `apt`'ta **yoktur**. Debian tarafında bir güncelleme sorun
çıkardığında, `/var/log/apt/history.log` dosyasını okuyup hangi paketin
hangi eski sürümden geldiğini bulman, sonra o sürümü elle
(`apt install paket=eski-surum`) tekrar kurman gerekir — `dnf`'teki gibi
tek komutluk bir "geri al" yoktur. Bu, RHEL ailesinin operasyonel açıdan
sunduğu somut bir avantajdır.

**Diğer aileler (bilgi):**
- Arch: `pacman -S paket`, `pacman -Syu`
- SUSE: `zypper install`, `zypper up`
- Alpine: `apk add paket`

---

## 5. Dağıtımdan bağımsız paketler

| Sistem | Komut | Not |
|---|---|---|
| **Snap** | `snap install X` | Ubuntu'da varsayılan, izole, otomatik güncellenir |
| **Flatpak** | `flatpak install X` | Masaüstü uygulamaları için yaygın |
| **AppImage** | `chmod +x x.AppImage && ./x.AppImage` | Tek dosya, kurulum yok |

Bu üç sistemin ortak noktası, **dağıtımdan bağımsız çalışabilmeleridir** —
bir Snap paketi hem Ubuntu'da hem (destekleniyorsa) Fedora'da aynı şekilde
çalışır, çünkü kendi bağımlılıklarını (kütüphanelerini) **kendi içinde**
taşır, sistemin paket yöneticisine (apt/dnf) güvenmez. Bunun bedeli, aynı
kütüphanenin sistemde zaten kurulu olan sürümüyle birlikte **tekrar tekrar**
(her Snap/Flatpak uygulaması için ayrı ayrı) diskte yer kaplamasıdır —
klasik paket yönetiminden daha az verimli ama daha taşınabilirdir.

Sunucu tarafında bunlar nadiren kullanılır; masaüstünde yaygındır.

---

## 6. Yapılandırma dosyası çakışması

Bir paketi güncellediğinde, sen o paketin config'ini değiştirmişsen ne olur?

Bu, üretim sunucularında sık karşılaşılan ama az bilinen bir durumdur: sen
`/etc/nginx/nginx.conf`'u elle özelleştirdin (belirli ayarlar ekledin). Paket
yöneticisi nginx'i güncellediğinde, yeni paket sürümü **kendi**
`nginx.conf`'unu getiriyor olabilir. Paket yöneticisi burada seninkini
sessizce ezip **senin özelleştirmelerini kaybetmeni** istemez — bunun yerine
iki aile de farklı ama benzer bir "çakışma bildirimi" stratejisi izler:

**RHEL:** Paketin yeni sürümü `.rpmnew` uzantısıyla yanına konur, senin dosyan durur.
(Bazı durumlarda tersi: seninki `.rpmsave` olur, yenisi yerine geçer.)
```bash
find /etc -name "*.rpmnew" -o -name "*.rpmsave"
```

**Debian:** İnteraktif olarak sorar — "keep local / install package maintainer's version /
show diff". `D` ile farkı görüp karar ver.
```bash
find /etc -name "*.dpkg-dist" -o -name "*.dpkg-old"
```

Debian'ın interaktif sorması ile RHEL'in sessizce `.rpmnew` bırakması
arasındaki fark, iki ailenin otomasyon felsefesini de yansıtır: RHEL
yaklaşımı, betiklerde/otomasyonda kesintisiz çalışmayı önceliklendirir (soru
sormaz, iki dosyayı da yan yana bırakır, sen ne zaman istersen elle
karşılaştırırsın). Debian yaklaşımı ise interaktif bir terminalde
çalıştığını varsayıp anında karar vermeni ister — bu, otomatik/denetimsiz
güncellemelerde (örneğin bir cron ile çalışan `apt upgrade`) sorun
çıkarabilir, bu tür senaryolarda genelde önceden bir "her zaman eski
dosyayı koru" politikası (`--force-confold` gibi bayraklarla) ayarlanır.

Güncelleme sonrası bu dosyaları taramak iyi bir alışkanlıktır — yeni sürüm
önemli ayarlar getirmiş olabilir.

---

## 7. Kaynaktan derleme (klasik üçlü)

Paket bulunamadığında son çare:

```bash
# Derleme araçları
sudo dnf groupinstall "Development Tools"       # RHEL
sudo apt install build-essential                # Debian

tar -xzf yazilim-1.0.tar.gz && cd yazilim-1.0
./configure --prefix=/usr/local     # bağımlılıkları denetler, Makefile üretir
make                                # derle
sudo make install                   # kur
sudo make uninstall                 # (varsa) kaldır
```

Bu üç adımın ("classic triplet" — `./configure && make && make install`)
her biri ayrı bir işi yapar: **`./configure`**, senin sisteminin hangi
kütüphanelere sahip olduğunu tarar, derleme için gereken ayarları
(kurulacak yol, hangi opsiyonel özelliklerin dahil edileceği gibi) belirler
ve `Makefile` denen, derleme adımlarını tarif eden bir dosya üretir.
**`make`**, bu `Makefile`'ı okuyup kaynak kodu (`.c` dosyaları gibi) gerçek
çalıştırılabilir programa (makine koduna) **derler**. **`make install`**,
derlenen dosyaları `configure` sırasında belirtilen konuma (`--prefix`)
kopyalar.

> ⚠️ Kaynaktan kurulan yazılım **paket yöneticisinin bilgisi dışındadır**: güncellenmez,
> `rpm -qf` ile bulunamaz, kaldırması zordur. Mecbur kalmadıkça yapma. Mecbursan
> `--prefix=/usr/local` veya `/opt` kullan, sistem dizinlerini kirletme.
> Daha iyisi: `checkinstall` ile paket üretmek veya kendi RPM/DEB'ini paketlemek.

Bunun neden riskli olduğunu netleştirelim: `dnf`/`apt` ile kurulan her dosya,
paket yöneticisinin **veritabanında kayıtlıdır** — hangi paketin hangi
dosyaları kurduğunu, o dosyaların orijinal izinlerini/boyutlarını bilir; bu
sayede güncelleyebilir, temiz kaldırabilir, bütünlük kontrolü yapabilirsin
(yukarıda `rpm -V` ile gördüğün gibi). `./configure && make install` ile
kurulan bir yazılım bu veritabanına **hiç girmez** — dosyalar diske
kopyalanır ama sistem "bu dosyalar bir arada bir paketi oluşturuyor, şu
paketin parçası" bilgisini tutmaz. Bu yazılımı kaldırmak istediğinde
(`make uninstall` her zaman tanımlı olmayabilir), hangi dosyaların nereye
kopyalandığını **elle** takip etmen gerekebilir. `--prefix=/usr/local`
kullanmak, en azından bu dosyaların sistemin kendi (`/usr/bin`,
`/etc` gibi) kritik dizinleriyle karışmasını, paket yöneticisinin kontrol
ettiği dosyaların üzerine yazılmasını önler.

---

## 🧪 Lab

1. Rocky'de EPEL deposunu ekle, `htop` kur, `dnf repolist` ile depoyu doğrula.
2. `dnf provides` ile `/usr/bin/dig` komutunun hangi pakette olduğunu bul, kur.
   (İpucu: paket adı `dig` değil.)
3. `rpm -qc nginx` ile nginx'in yapılandırma dosyalarını listele, `rpm -qf` ile
   `/etc/nginx/nginx.conf`'un hangi paketten geldiğini doğrula.
4. Bir paket kur, `dnf history` ile işlem numarasını bul, `dnf history undo N` ile geri al.
5. Debian'da `apt update` yapmadan bir paket kurmayı dene, farkı gözlemle.
6. Debian'da `apt install nginx`, sonra `apt remove nginx` yap. `/etc/nginx`'in durduğunu
   gör. `apt purge nginx` ile tamamen temizle.
7. `dpkg -S /bin/ls` ve `rpm -qf /bin/ls` ile aynı sorunun iki ailedeki cevabını al.
8. Debian'da doğru yöntemle (`signed-by` ile) bir üçüncü parti depo ekle.
9. Bir paketi `hold`/`versionlock` ile sabitle, `apt upgrade`/`dnf update` çalıştırıp
   atlandığını gör.
10. `dnf list installed | wc -l` ve `dpkg -l | wc -l` ile iki sistemdeki paket sayısını karşılaştır.

---

## ❓ Kendini test et

**S1.** `apt update` ile `apt upgrade` arasındaki fark nedir?

<details><summary>Cevap</summary>
`update` **depo metadata'sını** indirir (hangi paketin hangi sürümü var bilgisini tazeler),
hiçbir paketi değiştirmez. `upgrade` bu bilgiye göre paketleri günceller.
Sıralama her zaman `update` → `upgrade`.
</details>

**S2.** `rpm -ivh paket.rpm` ile `dnf install paket.rpm` arasındaki en önemli fark?

<details><summary>Cevap</summary>
`rpm` bağımlılık çözmez — eksik bağımlılık varsa hata verip durur.
`dnf install ./paket.rpm` eksik bağımlılıkları depodan indirip kurar.
</details>

**S3.** `apt remove nginx` yaptın ama `/etc/nginx/nginx.conf` hâlâ duruyor. Neden, nasıl silinir?

<details><summary>Cevap</summary>
`remove` yapılandırma dosyalarını kasten bırakır (yeniden kurunca ayarların kaybolmasın diye).
Tamamen silmek için `apt purge nginx`.
</details>

**S4.** `htpasswd` komutunu arıyorsun ama hangi pakette olduğunu bilmiyorsun. RHEL'de ne yaparsın?

<details><summary>Cevap</summary>
`dnf provides "*/htpasswd"` — dosya yolundan paket bulur (`httpd-tools`).
Debian'da karşılığı `apt-file search htpasswd` (önce `apt install apt-file && apt-file update`).
</details>

**S5.** Bir güncelleme sonrası sistem bozuldu. RHEL'de elinde hangi kurtarma aracı var?

<details><summary>Cevap</summary>
`dnf history` ile işlemi bul, `sudo dnf history undo <N>` ile geri al.
Debian tarafında bu özellik yoktur; `/var/log/apt/history.log`'tan eski sürümleri
okuyup elle `apt install paket=surum` yapmak gerekir.
</details>

**S6.** Bir depo tanımında `gpgcheck=0` görüyorsun. Bu neden risklidir?

<details><summary>Cevap</summary>
`gpgcheck`, indirilen her paketin depo sahibinin imzasıyla imzalandığını doğrular —
paketin gerçekten iddia ettiği kaynaktan geldiğini ve yolda değiştirilmediğini garanti
eder. `gpgcheck=0` bu doğrulamayı tamamen kapatır; bir saldırgan depoyu (veya
aradaki ağ trafiğini) ele geçirirse, sahte/zararlı bir paketi fark etmeden kurabilirsin.
</details>

**S7.** `dnf autoremove` çalıştırmadan önce ne yaptığını anlamak istiyorsun. Neden bazı
paketler "artık gereksiz" sayılır, halbuki sen onları hiç elle kaldırmadın?

<details><summary>Cevap</summary>
Bir paket kurulurken, o paketin ihtiyaç duyduğu bağımlılıklar da otomatik kurulur
ve "otomatik kurulan" olarak işaretlenir. Sen asıl paketi (`remove` ile) kaldırdığında,
o bağımlılıklar sistemde kalır çünkü belki başka paketler de onlara ihtiyaç duyuyordur.
`autoremove`, artık hiçbir kurulu paketin ihtiyaç duymadığı bu "otomatik kurulmuş,
şimdi yetim kalmış" paketleri tarayıp temizler.
</details>

---

## 📋 Hızlı referans

```bash
# RHEL / Rocky / Alma
dnf install|remove|update|search|info X
dnf provides /yol/dosya          # dosya → paket
dnf history ; dnf history undo N # geri alma
rpm -qa|-ql|-qc|-qf|-V X
dnf config-manager --add-repo URL
dnf install epel-release

# Debian / Ubuntu
apt update && apt upgrade
apt install|remove|purge|search|show X
apt install ./yerel.deb          # bağımlılıkla birlikte
dpkg -l|-L|-S|-i
apt-cache policy X               # hangi sürüm nereden
apt-mark hold X
```
