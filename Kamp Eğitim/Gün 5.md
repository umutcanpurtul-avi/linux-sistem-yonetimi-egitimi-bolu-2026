---
tags:
  - egitim/linux-sistem-yonetimi
tarih: 2026-08-26
konular:
  - Kullanıcı/grup veritabanı dosyaları (/etc/passwd, /etc/shadow, /etc/group, /etc/gshadow)
  - Dosya izinleri (chmod, chown, chgrp) ve ACL (setfacl/getfacl)
  - Zorunlu erişim kontrolü — SELinux ve AppArmor
  - Kullanıcı ekleme/silme (adduser/useradd, deluser/userdel)
  - UID/GID kavramları ve id çeşitleri
  - sudo ve su arasındaki fark, sudoers/visudo
  - Metin editörleri (vi, vim, nano)
  - less/more, history, locate, curl, wget, diff
---

# Gün 5 Raporu

Bağlantı: [Linux Sistem Yönetimi Eğitimi](../README.md) · [00 - Eğitim Planı](../00%20-%20Eğitim%20Planı.md) · [Gün 4](Gün%204.md) · [Gün 6](Gün%206.md)

## İşlenen Konular

- Yetkilendirme ve yetkiler konusu anlatıldı — Linux içinde kullanıcı yetkileri, grup yetkileri.
- `/etc/passwd`, `/etc/shadow`, `/etc/group`, `/etc/gshadow` pathleri üzerinde inceleme yapıldı — içerikleri nedir, alanlar neyi ifade eder.
- ACL tanımlama — `setfacl` ve `getfacl` nedir, ne için kullanılır, mimarisi ve mantığı nedir.
- Grup yetkileri nerede tanımlıdır.
- SELinux, AppArmor.
- `chmod`, `chown`, `chgrp`.
- Kullanıcı ekleme (`adduser`), kullanıcı silme (`deluser`) — parametreleri ve kullanımı.
- UID nedir, GID nedir — sistemde bulunan farklı id çeşitleri var mı.
- `sudo` ile `su` arasında fark ne, nasıl kullanılır, neden kullanılır, hangi durumlarda kullanılır.
- `sudoers` nedir?
- Editörler: `vi`, `nano`, `vim` — nedir, nasıl kullanılır.
- Kalan komutlar: `less`/`more` özellikleri ve kullanımı, `history` kullanımı ve tips&tricks, `locate`, `curl` (önemli), `wget` (önemli), `diff` komutu kullanımı.

**Ödevler:**
1. Bir kullanıcı oluştur; bu kullanıcı `sudo` ile sadece `rnano` çalıştırsın ve sadece `/etc/wgetrc` dosyasını editleyebilsin.
2. Bir kullanıcı oluştur (örnek: `egee`); bu kullanıcının oluşturduğu her dosyanın izni `666` olarak verilsin.

## Genişletilmiş Anlatım (Öğrenme İçin Ek Açıklamalar)

> [!WARNING]
> **Yukarıda bulunan kısa notların AI ile genişletilmiş halidir. Bilgiler sadece o gün işlenen konular ile sınırlandırılmış olup referans olması için eklenmiştir. Lütfen bu genişletilmiş metni kendi araştırmalarınıza bir ön bilgi olarak kullanın ve testlerinizi sadece burayı kullanarak değil, farklı kaynaklardan da yararlanarak yapın.**

### Kullanıcı/grup veritabanı dosyaları — `/etc/passwd`, `/etc/shadow`, `/etc/group`, `/etc/gshadow`

**Mekanizma:** "kullanıcı" ve "grup", Linux'ta süslü bir veritabanı değil — **düz metin, `:` ile ayrılmış** dört dosyadır. `useradd`, `passwd`, `groupadd` gibi komutların **hepsi** aslında bu dosyaları kilitleyip düzenleyen sarmalayıcılardır (kilitleme önemli: iki komut aynı anda `/etc/passwd`'yi bozmasın diye). Bir programın "ucp kimdir, UID'si kaç" sorusunu sorması, `getpwnam()` / `getpwuid()` çağrılarıyla olur; bunlar `/etc/nsswitch.conf`'a bakıp kaynağı belirler (yerelde `files` → bu dosyalar; ağ ortamında `sss`/`ldap` olabilir).

**`/etc/passwd`** — her satır bir kullanıcı, 7 alan:

```
ucp:x:1000:1000:UCP Kullanici:/home/ucp:/bin/bash
```

| Sıra | Alan | Anlamı |
| ---- | --------------- | --- |
| 1 | `ucp` | kullanıcı adı (login name) |
| 2 | `x` | parola alanı — **artık kullanılmıyor**, sadece "gerçek hash `/etc/shadow`'da" işareti; tarihsel olarak burada gerçek hash tutulurdu |
| 3 | `1000` | UID (kullanıcı numarası) |
| 4 | `1000` | GID — bu kullanıcının **birincil (primary)** grubu |
| 5 | `UCP Kullanici` | GECOS alanı — tam ad/açıklama, isteğe bağlı serbest metin |
| 6 | `/home/ucp` | home dizini |
| 7 | `/bin/bash` | giriş (login) shell'i — `/usr/sbin/nologin` ise o hesapla giriş yapılamaz |

**`/etc/shadow`** — gerçek parola hash'leri ve parola yaşlandırma kuralları, 9 alan:

```
ucp:$y$j9T$...hash...:19960:0:99999:7:::
```

| Sıra | Alan |
|---|---|
| 1 | kullanıcı adı |
| 2 | hash'lenmiş parola (`$algoritma$salt$hash`) — `!` veya `*` ise **parola ile giriş kilitli/devre dışı** |
| 3 | son parola değişiminin 1 Ocak 1970'ten bu yana geçen **gün sayısı** |
| 4 | min. gün — bu kadar geçmeden parola tekrar değiştirilemez |
| 5 | max. gün — bu kadar sonra parola değişimi zorunlu |
| 6 | uyarı süresi — süre dolmadan kaç gün önce uyarılır |
| 7 | inaktiflik süresi — süre dolduktan sonra hesap kilitlenene kadar kaç gün |
| 8 | hesabın **kesin olarak** devre dışı kalacağı tarih (epoch gün) |
| 9 | rezerve alan |

**Neden `/etc/shadow` diye ayrı bir dosya var? (tarihsel gerekçe — 5N1K'nın "neden"i)**
`/etc/passwd` **herkes tarafından okunabilir (world-readable)** olmak **zorundadır** — çünkü `ls -l` gibi araçlar UID→kullanıcı adı çevirisi için, giriş/kimlik doğrulama araçları da UID/home/shell için bu dosyayı okur; sadece root okuyabilse sistemin yarısı çalışmazdı. Ama bu, hash'lerin de herkese açık olması demekti. 1980'lerde CPU gücü artıp offline sözlük/brute-force saldırıları pratikleşince, "shadow password suite" çözümü doğdu: `/etc/passwd` world-readable kalsın, **hash'ler yalnızca root'un (ve `shadow` grubunun) okuyabildiği** `/etc/shadow`'a taşınsın (izin `640`, sahip `root:shadow`). Prensip: **erişimi mümkün olan en dar çevreye indirmek** — ACL, SELinux gibi ileri katmanların da temel motivasyonu bu.

**`/etc/group`** — grup karşılığı, 4 alan:

```
sudo:x:27:ucp,ege
```

| Sıra | Alan |
|---|---|
| 1 | grup adı |
| 2 | `x` — grup parolası alanı (neredeyse hiç kullanılmaz, `/etc/gshadow`'a taşındı) |
| 3 | GID |
| 4 | bu grubu **ikincil (supplementary)** grup olarak kullanan kullanıcıların virgülle listesi |

> [!TIP]
> **Bir kullanıcının **birincil** grubu burada listelenmez — o zaten `/etc/passwd`'nin 4. alanında (GID). `/etc/group`'taki liste sadece **ek** üyelikleri gösterir.**

**`/etc/gshadow`** — grup parolaları ve grup yöneticileri (çok nadir): `grup:hash:yoneticiler:uyeler`.

> [!NOTE]
> **Bu dört dosyayı elle düzenlemen gerekirse `nano` değil `vipw` / `vigr` kullan — `visudo` gibi bunlar da dosyayı kilitler ve kaydetmeden önce tutarlılık kontrolü yapar.**

### Dosya izinleri — `chmod`, `chown`, `chgrp`

**Mekanizma:** klasik Unix izin modeli her dosya için **üç sahiplik sınıfı** (owner/user, group, other) ve her sınıf için **üç izin biti** (read=4, write=2, execute=1) tutar — toplam 9 bit, inode'da saklanır, `rwxrwxrwx` şeklinde okunur. Kernel bir dosya erişiminde şu sırayla bakar: erişen kullanıcı dosyanın **sahibi mi** → owner bitleri; değilse dosyanın **grubunun üyesi mi** → group bitleri; hiçbiri değilse → other bitleri. **İlk uyan sınıf kazanır** (owner isen ve owner bitinde `x` yoksa, group'ta `x` olsa bile çalıştıramazsın).

- **5N1K:** *Ne* = dosyanın erişim politikası. *Nasıl* = inode'daki 9+3 bit; `chmod` `chmod()` syscall'ıyla değiştirir. *Ne zaman uygulanır* = her `open()`/`execve()` sırasında kernel tarafından. *Neden bu model* = 1970'lerin basit, hızlı, düşük maliyetli erişim kontrolü — çoğu senaryoya yeter; yetmeyince ACL/MAC devreye girer. *Kim* = izinleri sadece dosyanın **sahibi** ve **root** değiştirebilir; sahiplik (`chown`) değiştirmek **root** ister (aksi halde kullanıcı dosyayı başkasının üstüne yıkıp kota/sorumluluktan kaçabilirdi).

```bash
chmod 750 dosya          # octal: owner=rwx(7), group=rx(5), other=yok(0)
chmod u+x,g-w dosya      # sembolik: owner'a execute EKLE, group'tan write ÇIKAR
chmod -R 755 dizin/      # -R: dizin ve altındaki HER ŞEY
chmod g=rX dizin/        # büyük X: sadece zaten çalıştırılabilir olan / dizinlere x uygula (dosyaları atlar)

chown ucp:sudo dosya     # sahip ucp, grup sudo (kullanıcı:grup birlikte)
chown ucp dosya          # sadece sahibi değiştir
chown -R ucp:ucp /home/ucp   # recursive sahiplik düzeltme
chgrp sudo dosya         # sadece grubu değiştir — chown'un grup-only kısayolu
```

**Üç özel bit (mekanizması sık atlanan kısım):**
- **setuid (`chmod u+s`):** çalıştırılabilir bir dosyaya konursa, o programı **kim çalıştırırsa çalıştırsın effective UID'si dosyanın sahibinin** olur. `passwd` root'a ait ve setuid'lidir — bu sayede normal kullanıcı `/etc/shadow`'a (640, root:shadow) **kendi parolasını** yazabilir; program içeride sadece o kullanıcının satırını değiştirir. Kötüye kullanımı büyük risktir; `find / -perm -4000 2>/dev/null` ile sistemdeki tüm setuid binary'lerini denetle.
- **setgid:** bir **dizine** konursa, o dizinde oluşturulan dosyalar **oluşturanın birincil grubunu değil, dizinin grubunu** devralır — ekip paylaşımlı dizinlerin klasik kurulumu.
- **sticky bit (`chmod +t`):** bir dizine konursa, o dizindeki dosyaları **sadece dosyanın sahibi** (ya da dizin sahibi / root) silebilir. `/tmp`'nin `drwxrwxrwt` iznindeki `t` budur — herkes yazsın ama birbirinin dosyasını silemesin.

### ACL — `setfacl` ve `getfacl`

**Neden var (tasarım gerekçesi):** klasik modelin temel kısıtı — bir dosyaya **tam bir** sahip ve **tam bir** grup atanabilir. "Bu dosyaya sahibi dışında **bir belirli kullanıcıya daha** yazma izni ver, geri kalan herkese kapalı kalsın" isteğini klasik izinlerle karşılayamazsın: ya kullanıcıyı gruba eklersin (grubun **diğer tüm** dosyalarına da erişim açılır — istenmeyen yan etki), ya **ACL** kullanırsın. ACL, klasik 3 sınıfın üzerine **istediğin sayıda ek kullanıcı/grup kuralı** ekler.

**Mekanizma:** ACL girdileri, dosyanın bulunduğu dosya sisteminin **genişletilmiş öznitelik (extended attribute)** alanında (`system.posix_acl_access`) saklanır — dosya sisteminin ACL desteğiyle mount edilmiş olması gerekir (modern ext4/xfs varsayılan destekler). Linux uygulaması **POSIX 1003.1e taslak 17**'ye dayanır (standart resmen çekilse de Linux tam kümeyi uygular).

```bash
getfacl dosya.txt                         # tüm ACL girdilerini göster
setfacl -m u:ege:rwx dosya.txt            # kullanıcı 'ege'ye özel rwx (-m = modify)
setfacl -m g:proje-ekibi:rx dosya.txt     # 'proje-ekibi' grubuna özel rx
setfacl -x u:ege dosya.txt                # ege'nin özel kuralını kaldır (-x)
setfacl -b dosya.txt                      # TÜM ACL girdilerini temizle (-b)
setfacl -d -m u:ege:rwx dizin/            # -d = "default" ACL: dizin ALTINDA yeni oluşanlar bunu DEVRALIR
setfacl -R -m u:ege:rwx dizin/            # -R = mevcut tüm içeriğe uygula
```

`ls -l` çıktısında izin bitlerinin sonunda bir **`+`** ("`rwxr-x---+`") → bu dosyada klasik 9 bitin ötesinde ACL kuralları var; `getfacl` ile detay.

**`mask` girdisi (kritik):** grup + ek kullanıcı/grup kurallarının **etkin üst sınırını** belirler. Bir kuralda `rwx` yazsa bile `mask` `r-x` ise etkin izin `r-x`'e düşer. Adlandırılmış bir kullanıcı/grup girdisi eklediğinde `setfacl` mask'ı **otomatik** ekler. `chmod g=...` ACL'li bir dosyada aslında **mask'ı** değiştirir — bu yüzden ACL'li dosyalarda `chmod` beklenmedik görünebilir.

### Zorunlu erişim kontrolü — SELinux ve AppArmor

**DAC vs MAC (temel kavram):** buraya kadar her şey (`chmod`, `chown`, ACL) **DAC (Discretionary Access Control)** — dosyanın **sahibi** izinleri istediği gibi belirler, root her şeyi aşabilir. **MAC (Mandatory Access Control)** bunun üstüne, **sahibin/kullanıcının isteğinden bağımsız**, sistem çapında merkezi bir politika ekler — root olsan bile MAC izin vermiyorsa yapamazsın. Kernel bu kontrolü **LSM (Linux Security Modules)** çerçevesiyle yapar: her güvenlik-duyarlı işlemde (dosya aç, port bağla, süreç başlat) DAC kontrolü **geçtikten sonra** bir de LSM kancasına sorar. Amaç: bir servis (örn. web sunucusu) ele geçirilse bile, politika o sürecin **sadece** kendi ait olduğu kaynaklara dokunabilmesini garanti eder — "hasar sınırlama".

- **SELinux** (RHEL/Fedora/Rocky/Alma varsayılanı, **enforcing** modda): **etiket (label) tabanlı**. Her dosyaya ve sürece bir **context** (`kullanici:rol:tip:seviye`) atanır; politika hangi **tip**in hangi **tip**le nasıl etkileşebileceğini tanımlar (`httpd_t` süreci yalnız `httpd_sys_content_t` dosyaları okur). Çok granüler ama politika yazımı/hata ayıklaması karmaşık.
  ```bash
  getenforce            # Enforcing / Permissive / Disabled
  sudo setenforce 0      # geçici Permissive (engellemez, loglar) — hata ayıklarken
  ls -Z dosya             # dosyanın SELinux context'i
  ps -eZ | grep httpd     # süreç context'i
  sudo ausearch -m avc -ts recent   # son "engellendi" (AVC denial) kayıtları
  ```
- **AppArmor** (Debian **10 buster**'dan / Ubuntu'dan itibaren varsayılan): **yol (path) tabanlı**. Her uygulama için `/etc/apparmor.d/` altında, insan-okunur bir **profil** hangi yollara hangi izinle erişileceğini listeler. Yazması/okuması SELinux'ten kolay; ama koruma dosya **yoluna** bağlı olduğundan, yol değişebilen (hardlink/symlink/mount trick) senaryolarda teorik olarak SELinux'ten biraz daha atlatılabilir.
  ```bash
  sudo aa-status              # yüklü/enforce/complain profiller
  sudo aa-complain /path/prog  # profili "complain" moduna al (sadece loglar)
  sudo aa-enforce /path/prog   # tekrar zorlayıcı moda al
  ```

> [!TIP]
> **İkisi de aynı anda **tek sistemde etkin olmaz** — dağıtım ailesine göre biri. Bir "Permission denied" aldığında ve `ls -l`/ACL tarafında sorun yoksa, bir sonraki şüpheli **her zaman** SELinux/AppArmor: `getenforce` ya da `sudo aa-status` ile hemen kontrol et. SELinux'te "geçici olarak kapatıp test et" için `setenforce 0`, AppArmor'da tek profil için `aa-complain`.**

### Kullanıcı ekleme/silme — `adduser`/`useradd`, `deluser`/`userdel`

**İki katman (Debian ailesi):**
- `useradd` / `userdel` — düşük seviyeli, minimal C binary'leri; hiçbir soru sormaz, parametre vermezsen home dizini bile açmaz. POSIX'e yakın, her dağıtımda var.
- `adduser` / `deluser` — bunların üzerine yazılmış, **interaktif ve dostane** Perl script'leri: otomatik home açar, uygun UID/GID seçer, kullanıcıyla aynı adda grup oluşturur, parola sorar, `/etc/skel` içeriğini kopyalar.

RHEL ailesinde `adduser` genelde `useradd`'a **symlink**'tir — o dostane katman yoktur; RHEL'de standart yol doğrudan `useradd`'dır.

**5N1K:** *Ne* = yeni bir kimlik + home + grup üyeliği oluşturma. *Nasıl* = `/etc/passwd` + `/etc/shadow` + `/etc/group`'a satır ekleme, home dizini + `/etc/skel` kopyası. *Ne zaman* = insan kullanıcı (login'li) ya da servis hesabı (`-r`, nologin) gerektiğinde. *Neden iki araç* = alt katman script'lenebilir/öngörülebilir olsun, üst katman insan için pratik olsun. *Kim* = root (sistem dosyalarına yazma).

**`useradd` sık parametreler:** `-m` (home oluştur), `-s /bin/bash` (shell), `-u 1500` (UID), `-g grup` (birincil grup), `-G g1,g2` (ikincil gruplar), `-c "Açıklama"` (GECOS), `-d /ozel/yol` (özel home), `-e YYYY-AA-GG` (hesap bitiş tarihi), `-r` (**sistem hesabı** — <1000 UID, parola yaşlandırma yok, servisler için).

**`userdel`:** `-r` (home + mail spool'u da sil), `-f` (kullanıcı oturum açmış/dosyaları kullanımda olsa bile zorla).

`adduser kullanici` ve `deluser --remove-home kullanici` Debian'daki dostane karşılıklardır.

### UID/GID ve farklı ID çeşitleri

- **UID 0 = root** — kontrol edilen **isim değil, numaradır**; UID'si 0 olan **herhangi bir** kullanıcı adı tam yetkilidir.
- **Sistem/servis hesapları:** genelde `1-999` (Debian) — bir servis kendi dosyalarının sahibi olsun diye; login shell'i `/usr/sbin/nologin`.
- **Normal kullanıcılar:** `1000` ve üzeri (Debian ve modern RHEL 8+; eski RHEL'de `500`+). Eşik `/etc/login.defs`'teki `UID_MIN`/`UID_MAX`.
- **Birincil grup:** `/etc/passwd` 4. alan — yeni oluşturduğun dosyanın **otomatik grubu**.
- **İkincil gruplar:** `/etc/group`'ta listelenen, `usermod -aG` / `useradd -G` ile eklenenler — **ilave** yetkiler.

> [!WARNING]
> **`usermod -aG sudo ege` — **`-a` (append) olmadan** `-G` yazarsan kullanıcının **mevcut tüm ikincil gruplarını siler**, sadece yenisini bırakır. `-a` her zaman `-G` ile birlikte.**

**Bir sürecin içinde üç farklı UID vardır** (`id` hepsini gösterir):
```bash
id
# uid=1000(ucp) gid=1000(ucp) groups=1000(ucp),27(sudo),...
```
- **real UID** — süreci **kimin başlattığı**.
- **effective UID** — süreç şu an **hangi kimliğin yetkileriyle** çalışıyor (setuid binary'de real ≠ effective — `passwd`'de real=sen, effective=root).
- **saved UID** — setuid bir programın yetkiyi geçici bırakıp (`seteuid`) sonra geri alabilmesi için sakladığı yedek. İyi yazılmış setuid programlar "sadece kritik anda root ol, gerisinde düş" için bunu kullanır.

```bash
whoami         # sadece etkin kullanıcı adı
id -un         # aynı şey, id ile
groups         # üye olunan TÜM gruplar
newgrp proje   # geçici olarak birincil grubu değiştir (yeni oluşacak dosyalar için)
```

### `sudo` ile `su` arasındaki fark

**Tarihsel + tasarım gerekçesi:** `su` ("substitute user") Unix'in başından beri var — **tüm oturumu** başka bir kullanıcıya devreder. `sudo` ("superuser do" / "substitute user do") 1980'de SUNY/Buffalo'da Bob Coggeshall ve Cliff Spencer tarafından yazıldı; amacı **en az yetki (least privilege)** ilkesiydi: kullanıcı minimum yetkiyle çalışsın, sadece bir görev için gerektiğinde ve **sadece o komut süresince** yükselsin.

| | `su` | `sudo` |
|---|---|---|
| Ne yapar | **tüm oturumu** hedef kullanıcıya devret | **tek komutu** başka kullanıcı olarak çalıştır |
| Hangi parola | **hedef** kullanıcının parolası (root'a geçmek için root parolası gerekir) | **kendi** parolan (root parolasını bilmene gerek yok) |
| Yetki kapsamı | ya tam ya hiç | `/etc/sudoers` ile **komut bazlı**, çok ince ayar |
| Denetim (audit) | sadece "X, Y'ye su yaptı" görünür | **her çağrı** loglanır (`/var/log/auth.log` — Debian; `journalctl` / `/var/log/secure` — RHEL): kim, ne zaman, hangi komut |
| Neden tercih | tek kullanıcılı, kısa ömürlü sistemde hızlı | çok kullanıcılı gerçek sistemde **standart**: root parolası paylaşılmadan, kim ne yaptı denetlenebilir yetki devri |

**`su -` ile `su` farkı:** `-` (ya da `--login`) **tam login shell** başlatır — ortam değişkenlerini sıfırlar, hedefin `.bashrc`/`.profile`'ını çalıştırır, dizini onun home'una taşır. `-` olmadan **yetkiler** geçer ama **senin** ortam değişkenlerin/çalışma dizinin kalır — beklenmedik `PATH` sorunları çıkabilir (`sudo -i` = `su -` benzeri tam login; `sudo -s` = sadece shell).

### `sudoers` ve `visudo`

`sudoers` (`/etc/sudoers` + `/etc/sudoers.d/*`), `sudo`'nun "kim neyi yapabilir" kural dosyasıdır. **Asla** `nano`/`vi` ile doğrudan açma — `visudo` kullan: diske yazmadan önce **sözdizimi kontrolü** yapar. Bozuk bir `sudoers`, sistemde **hiç kimsenin sudo kullanamamasına** yol açar (kilitlenme) — `visudo` bu felaketi önleyen güvenlik ağıdır. `visudo -f /etc/sudoers.d/dosya` ile ayrı bir kural dosyası düzenlenir. Gerçek satır sözdizimi aşağıdaki Uygulamalı Örnek 1'de.

### Metin editörleri — `vi`, `vim`, `nano`

**Tarihsel bağlam / tasarım (asıl anlatılması gereken):**
- **`vi`** (1976, Bill Joy, Berkeley): önce `ex` adlı satır editörünü yazdı (`ed`'i geliştirerek), sonra 1977'de `ex`'e **tam ekran görsel mod** ekledi — `vi` aslında `ex`'in bir **modu**dur. **Modal** tasarımın nedeni o dönemin donanımıdır: yavaş seri terminaller ve **ok tuşu olmayan** klavyeler. İmleci `hjkl` ile, silmeyi `dd` ile yapmak, "her tuş bir komut" (Normal mod) ile "yazdığın metne girer" (Insert mod) ayrımı — az tuş vuruşuyla, ağ gecikmesine dayanıklı düzenleme için tasarlandı. `vi` + `ex` dili **POSIX / Single Unix Specification**'da standarttır — bu yüzden **her Unix/Linux'ta garanti** bulunur; minimal container, kurtarma modu, bozuk sunucu — sistem yöneticisi en azından temel `vi`'yi bilmek zorundadır.
- **`vim`** ("Vi IMproved", 1991, Bram Moolenaar): `vi`'nin sözdizimi vurgulama, çoklu geri alma (undo tree), eklenti, çoklu pencere ile genişletilmiş hâli. Modern dağıtımlarda `vi` komutu genelde `vim`'in küçük bir yapılandırmasına (`vim-tiny`) ya da doğrudan `vim`'e yönlenir.
- **`nano`** (1999, önce "TIP", Pine e-posta istemcisinin `pico` editörünün özgür klonu): **kipsiz (modeless)** — yazdığın her şey doğrudan metne girer; ekranın altında tuş kısayolları (`^X` = Ctrl+X) sürekli görünür. Öğrenmesi çok kolay; `vi`/`vim`'in "elini klavyeden kaldırmadan hızlı düzenleme" gücü yok. Modern dağıtımlarda `EDITOR`/`VISUAL` ayarlı değilse `nano` varsayılan editördür (`git commit`, `visudo` vb. onu açar).

**`vi`/`vim` hayatta kalma komutları:**
```
i          # Insert moduna geç
Esc        # Normal moda dön
:wq        # kaydet ve çık   (:x aynı)
:q!        # kaydetmeden zorla çık
:w !sudo tee %   # root yetkisi unutulduysa, çıkmadan sudo ile kaydet
dd / yy / p # satır sil / kopyala / yapıştır
/kelime    # ileri ara,  n = sonraki
:set nu    # satır numaralarını göster
```
**`nano`:** `Ctrl+O` (kaydet — Write Out), `Ctrl+X` (çık), `Ctrl+K` / `Ctrl+U` (satır kes / yapıştır), `Ctrl+W` (ara), `Ctrl+\` (ara-değiştir).

### `less` / `more`

**Tarihsel gerekçe (ikili — asıl anlatılacak):** `more` önce vardı (BSD, 1970'ler) — dosyayı **sayfa sayfa ileri** basar, geri gitmek yok/zor, dosya sonunda otomatik çıkar. Mark Nudelman 1983–85'te `less`'i yazdı; motivasyonu **`more`'un geri kaydıramamasıydı** — isim de "backwards more" şakasından ("less is more"). Kritik tasarım farkı: `less` dosyanın **tamamını okumadan** görüntülemeye başlar — bu yüzden GB'larca log dosyasında bile anında açılır (Gün 2'deki `grep`'in `ed`'den ayrılma gerekçesiyle aynı fikir: büyük veriyi belleğe almadan işlemek).

**5N1K:** *Ne* = dosyayı/akışı ekrana sığdırıp gezdiren "pager". *Nasıl* = sadece görünen kısmı + biraz tamponu okur; ileri/geri, arama, canlı takip. *Ne zaman* = uzun çıktıyı (log, `man`, `git log`, `journalctl`) incelerken — pek çok komut çıktısını otomatik `less`'e boru eder (`$PAGER`). *Neden `less`* = geri kaydırma + büyük dosyada hızlı açılış + arama. *Kim* = kullanıcı; salt görüntüler, dosyayı değiştirmez.

```bash
less /var/log/syslog
# içindeyken:
#   /hata     ileri "hata" ara      ?hata   geri ara      n / N   sonraki / önceki eşleşme
#   G / g     dosya sonu / başı
#   F         "canlı takip" moduna geç (tail -f gibi) — Ctrl+C ile geri çık
#   &hata     sadece "hata" GEÇEN satırları göster (grep gibi süz)
#   q         çık
less +F app.log       # doğrudan canlı takip modunda aç
less -N dosya         # satır numaralarıyla
journalctl -u ssh | less    # çoğu araç zaten otomatik less'e borular
```

### `history` — kullanım ve tips&trick'ler

**Mekanizma:** `history` bir program değil, kabuğun (bash) **builtin**'idir — çünkü geçmiş **kabuk sürecinin belleğindeki** bir listedir. Oturum kapanınca (ya da `history -a` ile) bu liste `~/.bash_history` dosyasına yazılır; yeni oturum açılışta okunur. `HISTSIZE` (bellekteki), `HISTFILESIZE` (dosyadaki) satır sayısını sınırlar; `HISTCONTROL=ignoredups:ignorespace` yinelenenleri ve boşlukla başlayan komutları (parola içeren komutları gizlemek için) atlar.

```bash
history           # numaralı komut geçmişi
!245               # 245 numaralı komutu ÇALIŞTIR (aynen)
!245:p             # sadece YAZDIR, çalıştırma — önce göz kontrolü
!!                 # bir önceki komut
sudo !!            # bir önceki komutu sudo ile tekrarla (çok sık)
!-3                # 3 komut geriye
!find              # 'find' ile BAŞLAYAN en son komut
^eski^yeni         # önceki komutta "eski"yi "yeni" ile değiştirip çalıştır
history -d 245     # geçmişten 245'i sil (yanlışlıkla parola yazdıysan)
```

> [!WARNING]
> **`!N` yazıp Enter'a basınca komut **önce göstermeden doğrudan çalışır** — numarayı yanlış hatırlarsan riskli (istemeden bir `rm`). `shopt -s histverify` (`~/.bashrc`'ye) bunu güvenli yapar: `!N` genişletilmiş hâli komut satırına yazılır, sen ikinci kez Enter'a basana (istersen düzenleyene) kadar çalışmaz.**

**Numara ezberlemeden:** **`Ctrl+R`** — yazdıkça geriye doğru canlı arama (reverse-i-search); bulunca Enter'dan önce düzenleyebilirsin. `Ctrl+G` ile aramadan çık.

### `locate`

**Mekanizma / tasarım (ikili: `find` vs `locate`):** `find` çalıştığı anda dosya sistemini **canlı** tarar — her zaman güncel ama her seferinde yavaş. `locate` ise önceden **`updatedb` ile üretilmiş bir indeks veritabanını** sorgular — **çok hızlı** (disk gezmez) ama veritabanı genelde günde bir `systemd timer` (`updatedb.timer`) ile güncellendiğinden, **az önce oluşturulan** bir dosyayı bulamayabilir.

- **5N1K:** *Ne* = önceden indekslenmiş dosya adı araması. *Nasıl* = `updatedb` tüm dosya sistemini gezip sıkıştırılmış bir isim veritabanı yazar; `locate` onu sorgular. *Ne zaman* = "şu isimli dosya sistemde nerede" sorusu, kesin güncellik gerekmiyorsa. *Neden `find` yerine* = interaktif hız (büyük diskte `find /` saniyeler-dakikalar sürer, `locate` milisaniye). *Kim* = `updatedb` root'la çalışır ama root'un göremeyeceği yolları veritabanından **kırpar** (`plocate`/`mlocate` her kullanıcıya sadece erişebileceği yolları gösterir).

> [!NOTE]
> **Modern Debian (12'den itibaren) ve Fedora artık `mlocate` yerine **`plocate`** kullanır — aynı komut arayüzü, çok daha hızlı ve küçük veritabanı. Kurulu olmayabilir: `sudo apt install plocate` / `sudo dnf install plocate`.**

```bash
locate dosya_adi        # indeksten ara
locate -i rapor          # büyük/küçük harf duyarsız
locate -e dosya_adi      # sadece HÂLÂ VAR OLAN sonuçları göster (silinmişleri ele)
sudo updatedb            # indeksi elle, hemen güncelle
```

### `curl` ve `wget` — ikisi de önemli, farklı amaçlar için

**Tasarım felsefesi farkı (asıl anlatılacak — ikili):**
- **`wget`** (GNU projesi): tek amacı **dosya indirmek** — aldığı içeriği varsayılan olarak **diske kaydeder**, `cp` gibi davranır. HTML'i **ayrıştırıp** bir siteyi özyinelemeli (recursive) indirebilir, yarım kalan indirmeyi sürdürebilir. Tek başına çalışan bir komut.
- **`curl`** (Daniel Stenberg, bağımsız proje): önce bir **kütüphane** (`libcurl`) olarak tasarlandı, komut satırı onun ince bir arayüzü. Onlarca protokol destekler, aldığı veriyi varsayılan olarak **stdout'a basar** (`cat` gibi, "her şey bir boru") — asıl gücü **API'lerle konuşmak** (özel method/header/body). "Veriyi asla ayrıştırmaz, ne dersen onu indirir."

Özetle: **`wget` ≈ `cp` (indir ve sakla, siteyi aynala); `curl` ≈ `cat` (akışı stdout'a ver, script/API)**.

```bash
# curl
curl -O https://site.com/dosya.tar.gz   # -O: uzak dosyanın adıyla KAYDET
curl -o yerel.tar.gz https://...        # -o: özel isimle kaydet
curl -L https://kisa.link/x              # -L: yönlendirmeleri (redirect) TAKİP ET
curl -I https://site.com                 # -I: sadece HTTP başlıkları (HEAD)
curl -fsSL https://site.com/script.sh    # -f hata kodunda sessizce başarısız ol, -sS ilerlemeyi gizle ama hatayı göster, -L redirect
curl -X POST -H "Content-Type: application/json" -d '{"k":"v"}' https://api.site.com
curl -w '%{http_code}\n' -o /dev/null -s https://site.com   # sadece HTTP durum kodunu al (sağlık kontrolü)

# wget
wget https://site.com/dosya.iso          # varsayılan: uzak ad ile diske kaydet
wget -O ozel.iso https://...             # -O: özel isim
wget -c https://.../buyuk.iso            # -c: yarım indirmeye KALDIĞI YERDEN devam
wget -r -np -k https://site.com/dizin/   # -r recursive, -np üst dizine çıkma, -k linkleri yerelde çalışır yap
wget -q -O- https://site.com | grep X    # -O- : stdout'a bas (curl gibi davrandır)
```

> [!WARNING]
> **`curl ... | sudo bash` (kur script'ini doğrudan çalıştırma) yaygın ama riskli — indirdiğin şeyi **önce oku**. `curl -fsSL URL -o kur.sh; less kur.sh; sudo bash kur.sh`.**

### `diff`

İki dosyayı satır satır karşılaştırır, sadece **farkları** gösterir. Mekanizması (LCS / Hunt–McIlroy) ve tarihi Gün 2'de işlendi: [Gün 2#`diff` — iki dosyayı karşılaştırma](Gün%202.md#diff-iki-dosyayı-karşılaştırma). Burada yeni olan bayrak kombinasyonu:

```bash
diff dosya1 dosya2          # varsayılan: '<' ilk dosyada, '>' ikinci dosyada
diff -u dosya1 dosya2        # unified format: '-'/'+', git/patch standardı
diff -Nur dizin1/ dizin2/    # -r recursive, -N bir tarafta OLMAYANI boş say, -u unified
                              # → iki dizin ağacını topluca karşılaştırmanın klasik kombinasyonu
diff -y dosya1 dosya2        # yan yana (side-by-side) göster
diff <(komut1) <(komut2)     # iki komutun ÇIKTISINI karşılaştır (process substitution)
```

Gün 5 transkriptinde `diff -Nur /home/ege/test ~/.bashrc` kullanılmış — burada aslında bir **dosya** ile bir **dosya** karşılaştırılıyor; `-r`/`-N` bu durumda etkisiz kalır (zarar da vermez), asıl işi yapan `-u` (okunabilir fark çıktısı).

### Uygulamalı Örnek 1 — Kısıtlı sudo yetkisi (1. ödevin çözümü)

Standart bir "yetki delegasyonu" senaryosu: belirli bir kullanıcıya, sadece belirli bir komutu (ve sadece belirli bir argümanla) root yetkisiyle çalıştırma izni. Debian 13'te adım adım:

**Adım 1 — Kullanıcıyı oluştur:**
```bash
sudo useradd -m -s /bin/bash kisitli_kullanici
sudo passwd kisitli_kullanici
```
- `-m` → home dizinini oluştur. Olmadan sadece `/etc/passwd`'ye kayıt açılır.
- `-s /bin/bash` → giriş shell'i; belirtmezsen dağıtıma göre `/bin/sh` ya da `nologin`.

**Önemli:** Bu kullanıcı **hiçbir gruba** (özellikle `sudo`'ya) eklenmiyor — `sudo` grubu zaten sınırsız yetki verir; onun yerine `sudoers`'ta **komut bazlı** izin tanımlanıyor (least privilege).

**Adım 2 — sudoers kuralı (asıl kısım):**
```bash
sudo visudo -f /etc/sudoers.d/kisitli_kullanici
```
**Neden `/etc/sudoers.d/` altında ayrı dosya:** modülerlik (her kural ayrı dosya), ana `/etc/sudoers`'a dokunmama (hata riski), kolay kaldırma (dosyayı sil) — `/etc/cron.d/`, `/etc/sudoers.d/` deseninin aynısı (Gün 6'da tekrar).

Dosyaya:
```
kisitli_kullanici ALL=(root) NOPASSWD: /usr/bin/rnano /etc/wgetrc
```

| Parça | Anlamı |
|---|---|
| `kisitli_kullanici` | kurala tabi kullanıcı |
| `ALL=` | kuralın geçerli olduğu **host** — sudoers dosyaları birden çok makinede paylaşılabildiği için host bazlı; tek makinede `ALL` sorun değil |
| `(root)` | komut **hangi kimlikle** çalışacak |
| `NOPASSWD:` | bu komut için parola sorulmasın (çıkarılırsa her seferinde kendi parolası — güvenlik açısından genelde parola istemek daha iyi) |
| `/usr/bin/rnano /etc/wgetrc` | izin verilen **tam komut yolu + argüman** — kritik nokta |

**Neden tam yol + tam argüman?** Sadece `/usr/bin/rnano` yazılsaydı, kullanıcı `sudo rnano /herhangi/dosya` ile **istediği dosyayı** açardı. Argümanı sabitlemek başka dosyaları engeller. (`rnano` = "restricted nano" — dosya sistemi gezmeyi, başka dosya açmayı zaten kısıtlar; sudoers'ın argüman kilidiyle birlikte iki kat koruma.)

**Adım 3 — komutun gerçek yolunu doğrula** (sudoers path eşleşmesi tam/kesin):
```bash
which rnano      # /usr/bin/rnano — sudoers'a bunu yaz
```

**Adım 4 — test:**
```bash
su - kisitli_kullanici
sudo rnano /etc/wgetrc      # çalışmalı
sudo rnano /etc/passwd      # reddedilmeli — doğru komut, YANLIŞ dosya
sudo nano /etc/wgetrc       # reddedilmeli — doğru dosya, YANLIŞ komut (nano ≠ rnano)
sudo apt install nano       # reddedilmeli — alakasız komut
sudo -l                     # o kullanıcıya tanımlı sudo kurallarını listele
```

**Gerçekleşen test (ödevin canlı çıktısı):**
```
ucp@debian-egitim:~$ sudo useradd -m -s /bin/bash ege
ucp@debian-egitim:~$ sudo su -
root@debian-egitim:~# passwd ege
root@debian-egitim:~# visudo -f /etc/sudoers.d/ege
root@debian-egitim:~# which rnano
/usr/bin/rnano
root@debian-egitim:~# su - ege
ege@debian-egitim:~$ sudo rnano /etc/wgetrc
ege@debian-egitim:~$ sudo nano /etc/passwd
Sorry, user ege is not allowed to execute '/usr/bin/nano /etc/passwd' as root on debian-egitim.local.
ege@debian-egitim:~$ sudo rnano /etc/passwd
Sorry, user ege is not allowed to execute '/usr/bin/rnano /etc/passwd' as root on debian-egitim.local.
```

Beklenen tam olarak gerçekleşmiş: `sudo rnano /etc/wgetrc` sessizce (`NOPASSWD`) çalışmış; hem yanlış komut (`nano`) hem yanlış dosya (`/etc/passwd`) reddedilmiş — sudoers'ın **komut + argüman birlikte tam eşleşme** kuralı iki senaryoda da doğru çalışmış.

### Uygulamalı Örnek 2 — `umask` ile varsayılan izin (2. ödevin çözümü)

**Mekanizma:** `chmod`/ACL **mevcut** bir dosyanın iznini değiştirir; **`umask`** ise **yeni oluşturulan her dosyanın hangi izinle doğacağını** belirler. `umask` sürecin bir özelliğidir (`umask()` syscall'ı), çocuk süreçlere miras kalır. Bir program dosya oluştururken bir "istenen mod" verir (çoğu program dosya için `666`, dizin için `777`); kernel bu moddan **`umask` bitlerini çıkarır**:
```
İstenen (dosya):  666
umask:          - 022
Sonuç:            644
```
`umask` izin **eklemez, kısıtlar**. Ödev "her dosya `666`" istiyor → hiçbir kısıtlama yok demek → `umask` değeri **`000`** olmalı (`666 - 000 = 666`).

> [!WARNING]
> **Güvenlik: `umask 000`, kullanıcının oluşturduğu **her dosyayı sistemdeki herkesin okuyup yazabileceği** hale getirir. Config/script/hassas veri için ciddi risk. Amaç "aynı grup birlikte çalışsın" ise `umask 002` (sonuç `664`) genelde yeterli ve daha güvenli.**

**Uygulama — sadece bu kullanıcı için kalıcı:**
```bash
echo "umask 000" | sudo tee -a /home/egee/.bashrc
```
- **Neden `.bashrc`:** `umask` oturuma özgü bir shell ayarı; kalıcı sistem dosyası değil. Kullanıcı her `bash` oturumunda (SSH, `su - egee`) `.bashrc` okunur, `umask 000` çalışır.
- **`-a` neden şart:** `tee` tek başına dosyanın üzerine yazar; `-a` (append) mevcut içeriği silmeden sona ekler.

**Doğrulama:**
```bash
su - egee
umask                    # 0000 çıkmalı
touch test.txt
ls -l test.txt           # -rw-rw-rw- (666) görülmeli
```

**Kapsam notu:** `.bashrc` sadece **interaktif** shell'lerde okunur — cron job / servis bunu okumaz. Daha geniş kapsam için `.profile`'a da ekle; cron için crontab'ın (`crontab -u egee -e`) en üstüne `umask 000` satırı; sistem geneli için `/etc/login.defs`'teki `UMASK` ya da bir `pam_umask` yapılandırması.

**Gerçekleşen test (ödevin canlı çıktısı, kısaltılmış):**
```
egee@debian-egitim:~$ echo "umask 000" >> ~/.bashrc
egee@debian-egitim:~$ ls -l
-rw-rw-r-- 1 egee egee 0 Aug 26 21:23 test2
-rw-rw-r-- 1 egee egee 0 Aug 26 21:24 test3.txt
-rw-rw-rw- 1 egee egee 0 Aug 26 21:26 test4.txt
...
egee@debian-egitim:~$ exit
ucp@debian-egitim:~$ su - egee
egee@debian-egitim:~$ touch test47.txt
egee@debian-egitim:~$ ls -l
-rw-rw-rw- 1 egee egee 0 Aug 26 21:31 test45.txt
-rw-rw-rw- 1 egee egee 0 Aug 26 21:31 test46.txt
-rw-rw-r-- 1 egee egee 0 Aug 26 21:32 test47.txt
```

> [!TIP]
> **Dikkat çeken nokta: `test2`/`test3.txt` (`.bashrc`'ye `umask 000` eklenmeden ÖNCE, eski oturumda açılmış) `644` çıkıyor — beklenen. Ama en sonda, `.bashrc`'de `umask 000` **zaten varken** açılan **yeni** bir `su - egee` oturumunda oluşturulan `test47.txt` **yine `644`** çıkıyor. İlk bakılacak yer: `grep -n umask ~/.bashrc` — dosyada aynı satırın birden fazla, **çelişen** kopyası (örn. `sed` ile silinmeye çalışılıp yanlış yazıldığı için silinemeyen bir `umask 022` / `umask 009`) olup olmadığını kontrol et. Bash `.bashrc`'yi baştan sona sırayla çalıştırır, **en son** `umask` satırı geçerli olur. (Bu, `## Sorular` altında takip maddesi olarak bırakıldı.)**

### Kaynaklar

**Bu başlık her zaman Genişletilmiş Anlatım'ın SON `###` bölümüdür** — hemen ardından `## Notlar` gelir; altında uygulamalı örnek ya da başka konu anlatımı gelmez.

- **`/etc/passwd`, `/etc/shadow`, `/etc/group` alan yapısı:**
  - [passwd(5) — man7.org](https://man7.org/linux/man-pages/man5/passwd.5.html), [shadow(5) — man7.org](https://man7.org/linux/man-pages/man5/shadow.5.html), [group(5) — man7.org](https://man7.org/linux/man-pages/man5/group.5.html) — alan tanımları.
- **Shadow password suite'in var olma nedeni (world-readable passwd + brute-force riski → hash'i root-only dosyaya taşı):**
  - [What is a shadow password file? — TechTarget](https://www.techtarget.com/cybersecurity/definition/shadow-password-file) (ikincil — tarihsel özet); [Shadow password — Wikipedia](https://en.wikipedia.org/wiki/Passwd#Shadow_file) (tersiyer, `passwd`'nin world-readable kalma zorunluluğu ve `/etc/shadow`'un 640/root:shadow olması).
- **`chmod`/`chown`, setuid/setgid/sticky, izin kontrol sırası:**
  - [chmod(1) — GNU coreutils manual](https://www.gnu.org/software/coreutils/manual/html_node/chmod-invocation.html) ve [inode(7) — man7.org](https://man7.org/linux/man-pages/man7/inode.7.html) — mod bitleri, `S_ISUID`/`S_ISGID`/`S_ISVTX`.
- **POSIX ACL (1003.1e taslak 17), `mask` girdisi:**
  - [acl(5) — man7.org](https://man7.org/linux/man-pages/man5/acl.5.html) — ACL girdi türleri, `mask`'ın "grup sınıfı için etkin üst sınır" tanımı.
  - [POSIX Access Control Lists on Linux — Andreas Grünbacher (USENIX)](https://www.usenix.org/legacyurl/posix-access-control-lists-linux) — Linux ACL'nin POSIX.1e taslak 17'ye uyumu, extended attribute'larda saklanması.
- **DAC vs MAC, LSM çerçevesi; SELinux'ün RHEL/Rocky'de enforcing varsayılan, AppArmor'ın Debian 10 (buster)'dan itibaren varsayılan olması:**
  - [Using SELinux — Red Hat Enterprise Linux 10 Documentation](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/10/html/using_selinux/index) — SELinux'ün varsayılan enforcing modu, context/tip modeli.
  - [SELinux Security — Rocky Linux Documentation](https://docs.rockylinux.org/10/guides/security/learning_selinux/) — Rocky'de SELinux'ün varsayılan etkin olması.
  - [AppArmor — Debian Wiki](https://wiki.debian.org/AppArmor) ve [Let's enable AppArmor by default — debian-devel arşivi](https://groups.google.com/g/linux.debian.devel/c/k4bWbaQ8Yqs) — AppArmor'ın Debian 10 buster'dan itibaren varsayılan etkin olması.
  - [Linux Security Modules — kernel.org](https://www.kernel.org/doc/html/latest/admin-guide/LSM/index.html) — DAC kontrolünden sonra çağrılan LSM kancaları.
- **`useradd`/`adduser` iki katman, `-r` sistem hesabı, `/etc/login.defs` UID eşiği:**
  - [useradd(8) — man7.org](https://man7.org/linux/man-pages/man8/useradd.8.html), [adduser(8) — Debian Manpages](https://manpages.debian.org/stable/adduser/adduser.8.en.html), [login.defs(5) — man7.org](https://man7.org/linux/man-pages/man5/login.defs.5.html).
- **`sudo` tarihi (Coggeshall & Spencer, ~1980, SUNY/Buffalo) ve least-privilege felsefesi; `su` ile farkı:**
  - [A Brief History of Sudo — sudo.ws](https://www.sudo.ws/about/history/) — kökeni ve tasarım amacı.
  - [sudoers(5) — sudo.ws](https://www.sudo.ws/docs/man/sudoers.man/) — kural sözdizimi, host/runas/komut+argüman eşleşmesi.
  - [su(1) — man7.org](https://man7.org/linux/man-pages/man1/su.1.html) — `su -` / `--login` tam login shell davranışı.
- **Editör tarihi (vi = Bill Joy 1976, ex'in görsel modu, POSIX standardı; vim 1991 Moolenaar; nano 1999, pico klonu):**
  - [Vi (text editor) — Wikipedia](https://en.wikipedia.org/wiki/Vi_(text_editor)) — `ex`'ten `vi`'ye, modal tasarımın donanım gerekçesi, POSIX/SUS standardı.
  - [GNU nano — official site](https://www.nano-editor.org/) — pico'nun özgür klonu, kipsiz tasarım.
- **`less`'in `more`'dan doğması (Mark Nudelman 1983–85, geri kaydırma; tüm dosyayı okumadan açma):**
  - [Less (Unix) — Wikipedia](https://en.wikipedia.org/wiki/Less_(Unix)) — "backwards more", dosyanın tamamını okumadan görüntüleme.
  - [less(1) — man7.org](https://man7.org/linux/man-pages/man1/less.1.html) — `F` canlı takip, `&` süzme, arama.
- **`locate`/`updatedb` indeks mantığı; `plocate`'in modern Debian/Fedora varsayılanı olması:**
  - [updatedb(8) / plocate — Debian Manpages](https://manpages.debian.org/testing/plocate/updatedb.8.en.html)
  - [Changes/Plocate as the default locate implementation — Fedora Project Wiki](https://fedoraproject.org/wiki/Changes/Plocate_as_the_default_locate_implementation)
- **`curl` vs `wget` tasarım felsefesi (curl = libcurl + stdout/"her şey boru"; wget = dosya indirici + recursive):**
  - [curl vs Wget — Daniel Stenberg (curl yazarı)](https://daniel.haxx.se/docs/curl-vs-wget.html) — birincil: recursive HTML ayrıştırma yalnız wget'te; curl veriyi ayrıştırmaz; curl `cat` gibi, wget `cp` gibi.
  - [GNU Wget Manual](https://www.gnu.org/software/wget/manual/wget.html) — `-c`, `-r`, `-np`, `-k`.
- **`umask` mekaniği:**
  - [umask(2) — man7.org](https://man7.org/linux/man-pages/man2/umask.2.html) ve [bash builtin `umask` — GNU Bash manual](https://www.gnu.org/software/bash/manual/bash.html) — istenen moddan umask bitlerinin çıkarılması, süreç özelliği ve miras.

Tekil bayrak/sözdizimi anlamları (`chmod 750`, `useradd -m`, `curl -O`, `less` içi tuşlar) ilgili `man` sayfalarıyla doğrulanabilir; bunlar için ayrıca kaynak gösterilmedi.

## Notlar

- Bugünün ana teması: **DAC** (chmod/chown/ACL — sahip karar verir, root aşar) ile **MAC** (SELinux/AppArmor — merkezi politika, root bile aşamaz) arasındaki kavramsal ayrım; ve `sudo`'nun `su`'dan farkının aslında "tam oturum devri" ile "tek komutluk, denetlenebilir, least-privilege yetki delegasyonu" arasındaki fark olduğu.
- `sudoers` yazarken en kritik nokta: sadece binary yolunu değil **argümanı da** sabitlemek — aksi halde "sadece bu dosyayı düzenlesin" niyeti "her şeyi düzenleyebilsin" sonucuna döner.
- `umask` mevcut dosyaların değil **gelecekte oluşacak** dosyaların varsayılan iznini belirler; oturuma özgüdür — `.bashrc`/`.profile`/crontab/`login.defs`'ten doğru olana yazılmazsa kalıcı olmaz. Aynı `.bashrc`'de çelişen iki `umask` satırı varsa **sonuncusu** kazanır.
- `/etc/shadow`'un var olma nedeni tek cümleyle: "herkesin okuyabildiği bir dosyada parola hash'i tutmak güvenli değil" — bu prensip (erişimi en dar çevreye indir) ACL, SELinux, sudoers'ın da temel motivasyonu. Aynı "referansı olan kaynak serbest bırakılmaz" fikri Gün 4'teki silinmiş-ama-açık dosya ve Gün 6'daki zombi/reap ile paralel.

## Komutlar / Örnekler

```bash
# kullanıcı/grup veritabanı dosyaları
grep '^ucp:' /etc/passwd
sudo grep '^ucp:' /etc/shadow
getent group sudo            # /etc/group + nsswitch kaynaklarını birlikte sorgula
sudo vipw ; sudo vigr        # bu dosyaları güvenli düzenle

# izinler
chmod 750 dosya
chmod -R g=rX dizin/
chown -R ucp:ucp /home/ucp
find / -perm -4000 2>/dev/null    # tüm setuid binary'leri denetle

# ACL
getfacl dosya
setfacl -m u:ege:rwx dosya
setfacl -x u:ege dosya
setfacl -d -m u:ege:rwx dizin/

# SELinux / AppArmor
getenforce ; ls -Z dosya ; sudo ausearch -m avc -ts recent
sudo aa-status ; sudo aa-complain /usr/sbin/something

# kullanıcı yönetimi
sudo useradd -m -s /bin/bash kullanici
sudo usermod -aG sudo kullanici       # -a ŞART
sudo userdel -r kullanici
id ; groups ; whoami

# sudo / sudoers
sudo visudo -f /etc/sudoers.d/kullanici
sudo -l -U kullanici
sudo !!

# editörler / pager
vi dosya      # :wq / :q!
nano dosya    # ^O ^X
less +F /var/log/syslog

# history
history ; !245 ; !245:p ; !! ; ^eski^yeni
# Ctrl+R : geriye doğru canlı arama

# locate / curl / wget / diff
locate -e dosya_adi ; sudo updatedb
curl -fsSL https://site.com/api | jq .
wget -c https://site.com/buyuk.iso
diff -u a b ; diff -Nur dizin1/ dizin2/ ; diff <(komut1) <(komut2)
```

## Sorular / Takip Edilecekler

- [ ] `test47.txt`'nin neden `644` çıktığını `grep -n umask ~/.bashrc` ile doğrula — dosyada birden fazla, çelişen `umask` satırı var mı, en sondaki hangisi?
- [ ] Kendi VM'inde bir setuid binary (`/usr/bin/passwd`) çalıştırırken başka terminalden `grep -E 'Uid|Gid' /proc/$(pgrep passwd)/status` ile real vs effective UID'nin farklılaştığını gözlemle.
- [ ] `getfacl` ile bir ACL kur, sonra `chmod g=r` uygula ve tekrar `getfacl` — `chmod`'un ACL'li dosyada `mask` girdisini değiştirdiğini doğrula.
