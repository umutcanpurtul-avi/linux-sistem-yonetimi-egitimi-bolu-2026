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

Bağlantı: [Linux Sistem Yönetimi Eğitimi](../README.md) · [00 - Eğitim Planı](../00%20-%20Eğitim%20Planı.md) · [Gün 4](Gün%204.md)

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

Linux'ta "kullanıcı" ve "grup" kavramları, süslü bir veritabanı değil — **düz metin, iki nokta üst üste (`:`) ile ayrılmış** dört basit dosyadır. Bu dört dosyayı satır satır okuyabilmek, sistem yönetiminin en temel becerisidir çünkü `useradd`, `passwd`, `groupadd` gibi komutların **hepsi** aslında bu dosyaları düzenleyen sarmalayıcılardan (wrapper) ibarettir.

**`/etc/passwd`** — her satır bir kullanıcı, 7 alan:

```
ucp:x:1000:1000:UCP Kullanici:/home/ucp:/bin/bash
```

| Sıra | Alan            | Anlamı                                                                                                                              |
| ---- | --------------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| 1    | `ucp`           | kullanıcı adı (login name)                                                                                                          |
| 2    | `x`             | parola alanı — **artık kullanılmıyor**, sadece "gerçek hash `/etc/shadow`'da" işareti; tarihsel olarak burada gerçek hash tutulurdu |
| 3    | `1000`          | UID (kullanıcı numarası)                                                                                                            |
| 4    | `1000`          | GID — bu kullanıcının **birincil (primary)** grubu                                                                                  |
| 5    | `UCP Kullanici` | GECOS alanı — tam ad/açıklama, isteğe bağlı serbest metin                                                                           |
| 6    | `/home/ucp`     | home dizini                                                                                                                         |
| 7    | `/bin/bash`     | giriş (login) shell'i                                                                                                               |

**`/etc/shadow`** — gerçek parola hash'lerinin ve parola yaşlandırma (aging) kurallarının tutulduğu dosya, 9 alan:

```
ucp:$y$j9T$...hash...:19960:0:99999:7:::
```

| Sıra | Alan | Anlamı |
|---|---|---|
| 1 | kullanıcı adı | |
| 2 | hash'lenmiş parola (`$algoritma$salt$hash` biçiminde) — `!` veya `*` ise **parola ile giriş kilitli/devre dışı** demektir |
| 3 | son parola değişiminin 1 Ocak 1970'ten bu yana geçen **gün sayısı** |
| 4 | min. gün — bu kadar gün geçmeden parola tekrar değiştirilemez |
| 5 | max. gün — bu kadar gün sonra parola değişimi zorunlu olur |
| 6 | uyarı süresi — süre dolmadan kaç gün önce kullanıcı uyarılır |
| 7 | inaktiflik süresi — süre dolduktan sonra hesabın kilitlenmesine kaç gün var |
| 8 | hesabın **kesin olarak** devre dışı kalacağı tarih (epoch gün) |
| 9 | rezerve alan, kullanılmıyor |

**Neden `/etc/shadow` diye ayrı bir dosya var, hash'ler neden `/etc/passwd` içinde kalmadı?** Tarihsel olarak `/etc/passwd` **herkes tarafından okunabilir (world-readable)** olmak zorundaydı — çünkü `ls -l` gibi komutlar UID'den kullanıcı adına çevirmek için bu dosyayı okur. Ama bu, hash'lerin de herkese açık olması demekti — 1980'lerde offline brute-force/dictionary saldırıları yaygınlaşınca hash'ler **sadece root'un okuyabildiği** `/etc/shadow`'a (izinleri genelde `640`, sahibi `root:shadow`) taşındı — "shadow password suite" bu yüzden var.

**`/etc/group`** — `/etc/passwd`'nin grup karşılığı, 4 alan:

```
sudo:x:27:ucp,ege
```

| Sıra | Alan | Anlamı |
|---|---|---|
| 1 | grup adı |
| 2 | `x` — grup parolası alanı (neredeyse hiç kullanılmaz, `/etc/gshadow`'a taşınmıştır) |
| 3 | GID |
| 4 | bu grubu **ikincil (supplementary)** grup olarak kullanan kullanıcıların virgülle ayrılmış listesi |

> [!TIP]
> **Bir kullanıcının birincil grubu burada listelenmez — birincil grup zaten `/etc/passwd`'nin 4. alanında (GID) tanımlıdır. `/etc/group`'taki liste sadece o kişinin **ek olarak** üye olduğu grupları gösterir.**

**`/etc/gshadow`** — grup parolaları ve grup yöneticileri için (çok nadir kullanılır): `grup_adi:hash:yoneticiler:uyeler`.

### Dosya izinleri — `chmod`, `chown`, `chgrp`

Klasik Unix izin modeli her dosya için **üç sahiplik sınıfı** (owner/user, group, other) ve her sınıf için **üç izin biti** (read=4, write=2, execute=1) tanımlar — toplam 9 bit, `rwxrwxrwx` şeklinde okunur.

```bash
chmod 750 dosya          # sayısal (octal) gösterim: owner=rwx(7), group=rx(5), other=hiçbiri(0)
chmod u+x,g-w dosya      # sembolik gösterim: owner'a execute EKLE, group'tan write ÇIKAR
chmod -R 755 dizin/      # -R: dizin ve altındaki HER ŞEYİ recursive uygula

chown ucp:sudo dosya     # sahibi ucp, grubu sudo yap (kullanıcı:grup birlikte)
chown ucp dosya          # sadece sahibi değiştir, grup dokunulmaz
chgrp sudo dosya         # sadece grubu değiştir — chown'un grup-only kısayolu
```

Üç ana bitin dışında iki özel bit daha önemlidir: **setuid** (`chmod u+s`) — çalıştırılabilir bir dosyaya konursa, o programı **kim çalıştırırsa çalıştırsın**, program **sahibinin** UID'siyle çalışır (`passwd` komutunun kendisi root'a ait ve setuid'lidir — bu sayede normal kullanıcı `/etc/shadow`'a yazabilir); **sticky bit** (`chmod +t`) — bir dizine konursa, o dizindeki dosyaları **sadece dosyanın sahibi** (dizinin sahibi değil) silebilir (`/tmp`'nin `drwxrwxrwt` izninin sonundaki `t` budur — herkes yazabilsin ama birbirinin dosyasını silemesin diye).

### ACL — `setfacl` ve `getfacl`

Klasik `rwx` modelinin temel bir kısıtı var: bir dosyaya **tam olarak bir** sahip ve **tam olarak bir** grup tanımlayabilirsin. "Bu dosyayı sahibi dışında **başka belirli bir kullanıcıya da** yazma izni ver, ama geri kalan herkese kapalı kalsın" gibi bir isteği klasik izinlerle karşılayamazsın — bunun için ya kullanıcıyı gruba eklemen (ki bu grubun DİĞER tüm dosyalarına da erişim açar, istenmeyen yan etki) ya da **ACL (Access Control List)** kullanman gerekir. ACL, klasik 3 sınıfın üzerine **istediğin sayıda ek kullanıcı/grup kuralı** ekleyebilmeni sağlar.

```bash
getfacl dosya.txt                         # o dosyanın tüm ACL girdilerini göster
setfacl -m u:ege:rwx dosya.txt            # kullanıcı 'ege'ye özel olarak rwx ver (-m = modify)
setfacl -m g:proje-ekibi:rx dosya.txt     # 'proje-ekibi' grubuna özel olarak rx ver
setfacl -x u:ege dosya.txt                # ege'nin özel kuralını kaldır (-x = remove entry)
setfacl -b dosya.txt                      # dosyadaki TÜM ACL girdilerini temizle (-b = remove all)

setfacl -d -m u:ege:rwx dizin/            # -d = "default" ACL: dizinin ALTINDA yeni oluşan
                                           # her dosya/alt dizin bu kuralı OTOMATİK devralır
setfacl -R -m u:ege:rwx dizin/            # -R = recursive, mevcut tüm içeriğe uygula
```

`ls -l` çıktısında izin bitlerinin sonunda bir **`+`** işareti görürsen ("`rwxr-x---+`"), bu dosyada klasik 9 bitin **ötesinde** ek ACL kuralları olduğunun işaretidir — `getfacl` ile detayını görürsün. ACL'de ayrıca bir **mask** girdisi vardır: grup ve ek kullanıcı/grup kurallarının **üst sınırını** belirler (bir kuralda `rwx` yazsa bile mask `r-x` ise etkin izin `r-x`'e düşer) — bu, `chmod g=...` komutunun ACL'li bir dosyada aslında mask'ı değiştirdiğini anlamak için önemlidir.

### Zorunlu erişim kontrolü — SELinux ve AppArmor

Buraya kadar gördüğümüz her şey (`chmod`, `chown`, ACL) **DAC (Discretionary Access Control — isteğe bağlı erişim kontrolü)** kategorisindedir: dosyanın **sahibi** izinleri istediği gibi belirler, hatta root her şeyi görmezden gelebilir. **MAC (Mandatory Access Control — zorunlu erişim kontrolü)** ise bunun üstüne, **kullanıcının/sahibin isteğinden bağımsız**, sistem çapında merkezi bir politika ekler — root olsan bile MAC politikası izin vermiyorsa o işlemi yapamazsın. Bunun amacı: bir servis (örn. web sunucusu) açık bulunup ele geçirilse bile, MAC politikası o sürecin **sadece** kendi ait olduğu dosyalara dokunabilmesini garanti eder.

- **SELinux** (RHEL/Fedora/Rocky/Alma'nın varsayılanı): **etiket (label) tabanlı**. Her dosyaya ve her sürece bir **context** (`kullanici:rol:tip:seviye`) atanır; politika, hangi **tip**in hangi **tip**le nasıl etkileşebileceğini tanımlar (örn. `httpd_t` tipi süreç sadece `httpd_sys_content_t` etiketli dosyaları okuyabilir). Çok güçlü ve granüler ama politika yazımı/hata ayıklaması karmaşıktır.
  ```bash
  getenforce            # Enforcing / Permissive / Disabled durumunu göster
  setenforce 0           # geçici olarak Permissive moda al (engellemez, sadece loglar) — hata ayıklarken kullanılır
  ls -Z dosya             # dosyanın SELinux context'ini göster
  ```
- **AppArmor** (Debian/Ubuntu'nun varsayılanı): **yol (path) tabanlı**. Her uygulama için ayrı, insan tarafından okunabilir bir **profil** dosyası (`/etc/apparmor.d/` altında) hangi dosya yollarına hangi izinlerle erişebileceğini listeler. SELinux'e göre daha basit yazılır/okunur, ama dosya yolu değişirse (örn. symlink ile) etrafından dolanılabilme riski SELinux'e göre biraz daha fazladır.
  ```bash
  aa-status              # hangi profillerin yüklü/enforce/complain modda olduğunu göster
  aa-complain /path/prog  # bir profili "complain" moduna al — sadece loglar, engellemez (hata ayıklama)
  aa-enforce /path/prog   # profili tekrar zorlayıcı (enforce) moda al
  ```

> [!TIP]
> **İkisi de aynı anda tek sistemde çalışmaz — dağıtım ailesine göre biri etkindir. Bir "Permission denied" hatası aldığında ve `ls -l`/ACL tarafında hiçbir sorun görünmüyorsa, bir sonraki şüpheli her zaman SELinux/AppArmor olmalı (`getenforce` ya da `aa-status` ile hemen kontrol edilir).**

### Kullanıcı ekleme/silme — `adduser`/`useradd`, `deluser`/`userdel`

Debian ailesinde **iki katman** vardır: `useradd`/`userdel` düşük seviyeli, minimal C binary'leridir (hiçbir soru sormaz, home dizini bile oluşturmaz — parametre vermezsen). `adduser`/`deluser` ise bunların üzerine yazılmış, **interaktif ve dostane** Perl script'leridir (otomatik home dizini açar, otomatik uygun UID/GID seçer, kullanıcıyla aynı adda bir grup oluşturur, parola sorar). RHEL ailesinde ise `adduser` genelde `useradd`'a giden bir symlink'ten ibarettir — o dostane katman yoktur.

**`useradd` sık kullanılan parametreler:**

| Parametre | Anlamı |
|---|---|
| `-m` | home dizinini oluştur (vermezsen sadece `/etc/passwd`'ye kayıt açılır, dizin açılmaz) |
| `-s /bin/bash` | giriş shell'i belirle |
| `-u 1500` | UID'yi elle belirle (vermezsen sıradaki boş UID otomatik seçilir) |
| `-g grup` | birincil grubu belirle (vermezsen genelde kullanıcı adıyla aynı yeni bir grup açılır) |
| `-G grup1,grup2` | ikincil (supplementary) gruplara ekle, virgülle ayrılmış |
| `-c "Açıklama"` | GECOS alanı (tam ad/açıklama) |
| `-d /ozel/yol` | home dizini için özel bir yol belirle |
| `-e YYYY-AA-GG` | hesabın **kesin sona ereceği** tarih |
| `-r` | **sistem hesabı** oluştur — normal UID aralığının altından (genelde <1000) bir UID atanır, parola yaşlandırma uygulanmaz; servis hesapları için kullanılır |

**`userdel` sık kullanılan parametreler:**

| Parametre | Anlamı |
|---|---|
| `-r` | home dizinini ve mail spool'unu da **birlikte** sil (vermezsen sadece kullanıcı kaydı silinir, dosyaları kalır) |
| `-f` | kullanıcı hâlâ oturum açmış/dosyaları başka yerde kullanılıyor olsa bile **zorla** sil |

`adduser kullanici` ve `deluser --remove-home kullanici` bu ikisinin Debian'daki dostane karşılıklarıdır.

### UID/GID ve farklı ID çeşitleri

- **UID 0** her zaman **root**'tur — isim değil, bu **numara** kontrol edilir; UID'si 0 olan HERHANGİ bir kullanıcı adı root yetkisine sahiptir.
- **Sistem/servis hesapları:** genelde `1-999` aralığında (Debian) UID'ler — bir servis kendi dosyalarının sahibi olsun diye açılır, login shell'i genelde `/usr/sbin/nologin`'dir (biri o hesapla giriş yapamasın diye).
- **Normal kullanıcılar:** `1000` ve üzeri (Debian ve modern RHEL8+; eski RHEL'de `500`+). Bu eşik `/etc/login.defs` içindeki `UID_MIN`/`UID_MAX` ile tanımlıdır.
- **Birincil (primary) grup:** `/etc/passwd`'nin 4. alanı — yeni oluşturduğun bir dosyanın **otomatik grubu** budur.
- **İkincil (supplementary) gruplar:** `/etc/group`'ta listelenen, `usermod -aG` veya `useradd -G` ile eklenen ek gruplar — o kullanıcının **ilave olarak** sahip olduğu yetkiler.

Bir sürecin içinde aslında **üç farklı** UID kavramı vardır (bunu `id` komutu ile hepsi bir arada görülür):
```bash
id
# uid=1000(ucp) gid=1000(ucp) groups=1000(ucp),27(sudo),... 
```
- **real UID** — süreci **kimin başlattığı**.
- **effective UID** — süreç şu an **hangi kimliğin yetkileriyle** çalışıyor (setuid bir binary çalıştırdığında real ve effective farklılaşır — `passwd` örneğinde real=sen, effective=root).
- **saved UID** — bir setuid programın, yetkiyi geçici olarak bırakıp (`seteuid`) sonra tekrar geri alabilmesi için sakladığı yedek kimlik.

```bash
whoami         # sadece etkin kullanıcı adını göster
id -un         # aynı şey, id komutuyla
groups         # kullanıcının üye olduğu TÜM grupları listele
```

### `sudo` ile `su` arasındaki fark

Bu ikisi sık karıştırılır ama **felsefeleri tamamen farklıdır**:

| | `su` | `sudo` |
|---|---|---|
| Ne yapar | **Tüm oturumu** hedef kullanıcıya devret | **Tek bir komutu** başka kullanıcı olarak çalıştır |
| Hangi parola istenir | **hedef** kullanıcının parolası (`su -` ile root'a geçmek için root'un parolasını bilmen gerekir) | **kendi** parolan (root'un parolasını hiç bilmene gerek yok) |
| Yetki kapsamı | ya tam yetki ya hiç — ince ayar yok | `/etc/sudoers` ile **komut bazlı**, çok ince ayarlanabilir (bkz. aşağıdaki uygulamalı örnek) |
| Denetim (audit) | sistemde sadece "X, Y'ye su yaptı" görünür, sonrasında ne yaptığı ayrı loglanmaz | **her çağrı** `/var/log/auth.log` (Debian) / `journalctl` üzerinden kaydedilir — kim, ne zaman, hangi komutu çalıştırdı |
| Neden tercih edilir | tek kullanıcılı, kısa ömürlü sistemlerde hızlı bir yol | çok kullanıcılı gerçek sistemlerde **standart pratiktir** — root parolasını kimseyle paylaşmadan, kimin ne yaptığını denetlenebilir tutarak yetki devri sağlar |

`su -` ile `su` arasındaki fark da önemli: `-` (ya da `--login`) **tam bir login shell** ister — ortam değişkenlerini sıfırlar, hedef kullanıcının `.bashrc`/`.profile` dosyalarını çalıştırır, dizini onun home'una taşır. `-` olmadan **yetkiler** hedef kullanıcıya geçer ama **kendi** ortam değişkenlerin/çalışma dizinin kalır — bu bazen beklenmedik `PATH` sorunlarına yol açabilir.

### `sudoers` ve `visudo`

`sudoers`, `sudo` komutunun **kim neyi yapabilir** sorusunu cevapladığı kural dosyasıdır (`/etc/sudoers` ve `/etc/sudoers.d/` altındaki ek dosyalar). Bu dosyayı **asla** doğrudan `nano`/`vi` ile açma — bunun yerine `visudo` kullanılır, çünkü `visudo` dosyayı diske yazmadan önce **syntax kontrolü** yapar; sözdizimi bozuk bir `sudoers` dosyası, sistemde **kimsenin sudo kullanamamasına** yol açabilir (kilitlenme riski) — `visudo` bu felaketi engelleyen güvenlik ağıdır. Aşağıdaki uygulamalı örnekte bu dosyanın gerçek satır sözdizimini ayrıntılı görüyoruz.

### Metin editörleri — `vi`, `vim`, `nano`

- **`vi`**: 1976'dan kalma, **modal** (kip tabanlı) bir editördür — "Normal mod" (komutlar çalışır, harf tuşları metne yazılmaz) ve "Insert modu" (yazdığın gerçekten metne girer) arasında geçiş yaparak çalışılır. POSIX standardının bir parçası olduğu için **her Unix/Linux sisteminde garanti olarak bulunur** — bu yüzden bir sistem yöneticisi, hangi ortamda olursa olsun (minimal container, kurtarma modu, bozuk bir sunucu) en azından temel `vi` komutlarını bilmek zorundadır.
- **`vim`** ("vi improved"): `vi`'nin sözdizimi vurgulama (syntax highlighting), çoklu geri alma (undo tree), eklenti (plugin) desteği gibi özelliklerle genişletilmiş hâlidir; modern dağıtımlarda `vi` komutu genelde doğrudan `vim`'e yönlendirilmiştir.
- **`nano`**: kipsiz (modeless) çalışır — yazdığın her şey doğrudan metne girer, ekranın altında hangi tuşun ne işe yaradığı (`^X` = Ctrl+X gibi) sürekli görünür durur. Öğrenmesi çok daha kolaydır ama `vi`/`vim`'in klavyeden elini kaldırmadan hızlı düzenleme gücüne sahip değildir.

**Hayatta kalma komutları (`vi`/`vim`):**
```
i          # Insert moduna geç (yazmaya başla)
Esc        # Normal moda geri dön
:wq        # kaydet ve çık (write + quit)
:q!        # kaydetmeden zorla çık
dd         # bulunduğun satırı sil
yy         # satırı kopyala (yank)
p          # kopyalanan/silinen satırı yapıştır
/kelime    # ileri doğru ara
```

**`nano` temelleri:** `Ctrl+O` (kaydet — "Write Out"), `Ctrl+X` (çık), `Ctrl+K` (satırı kes), `Ctrl+U` (yapıştır), `Ctrl+W` (ara).

### `less` / `more`

İkisi de bir dosyayı ekrana **sayfa sayfa** basan "pager" programlarıdır ama `more` çok daha kısıtlıdır: sadece **ileri** doğru sayfalar, geri gitmek zordur/desteklenmez, dosya sonuna gelince otomatik çıkar. `less` ("less is more" şakalı isim), hem **ileri hem geri** kaydırma yapabilir (ok tuşları, Page Up/Down), dosyanın tamamını hafızaya önceden yüklemediği için **çok büyük dosyalarda/loglarda** bile hızlıdır, ve arama yapabilirsin:

```bash
less /var/log/syslog
# içindeyken:  /hata     ileri doğru "hata" ara
#              ?hata     geri doğru "hata" ara
#              n         bir sonraki eşleşme
#              G         dosyanın sonuna git
#              g         dosyanın başına git
#              q         çık
less +F dosya.log        # tail -f gibi, dosyaya eklenen yeni satırları canlı takip et
```

### `history` — kullanım ve tips&trick'ler

`history` komutu, o oturumda (ve `~/.bash_history` dosyasında kalıcı olarak) çalıştırdığın komutları **numaralı** listeler. Bu numarayı `!` ile birleştirerek uzun bir komutu **yeniden yazmadan** çağırabilirsin:

```bash
history           # numaralı komut geçmişini göster
!245               # 245 numaralı komutu ÇALIŞTIR (aynen, düzenlemeden)
!245:p             # sadece YAZDIR, çalıştırma — önce göz ile kontrol etmek için
!!                 # bir önceki komutu tekrar çalıştır
!-3                # şu anki konumdan 3 komut GERİYE git
!find              # 'find' ile BAŞLAYAN en son komutu çalıştır
```

Gün 5'in kendi transkriptinde de tam olarak bu kullanılmış: `history` çıktısındaki 23 numaralı `nano ~/.bashrc` komutu, `!23` ile tekrar çağrılmış (satır ~300 civarı).

> [!WARNING]
> **`!N` yazıp Enter'a bastığında komut **önce sana göstermeden, doğrudan çalışır** — numarayı yanlış hatırlarsan riskli olabilir (örn. istemeden bir `rm` komutunu tetiklemek). `shopt -s histverify` (`~/.bashrc`'ye eklenebilir) bunu güvenli hâle getirir: `!N` yazınca komut hemen çalışmaz, genişletilmiş hâli komut satırına yazılır, sen tekrar Enter'a basmadan (istersen düzenleyerek) çalışmaz.**

Diğer faydalı bir yöntem: **`Ctrl+R`** — geçmişte yazdıkça canlı arama yapar (reverse-i-search), bulduğun komutu Enter'a basmadan önce düzenleyebilirsin; numarayı hatırlamana hiç gerek kalmaz.

### `locate`

`find` gibi dosya arar ama **tamamen farklı bir mantıkla** çalışır: `find`, çalıştığı anda dosya sistemini **canlı olarak** tarar (her seferinde yavaş ama her zaman güncel); `locate` ise önceden **oluşturulmuş bir indeks veritabanını** (`/var/lib/mlocate/mlocate.db`) sorgular — bu yüzden **çok hızlıdır** ama veritabanı genelde günde bir kez `cron` ile güncellendiği için, **az önce oluşturulmuş** bir dosyayı bulamayabilir (indeks henüz güncellenmediyse).

```bash
locate dosya_adi        # indeksten ara (hızlı ama güncelliği garanti değil)
sudo updatedb            # indeksi elle, hemen güncelle
locate -i rapor          # büyük/küçük harf duyarsız ara
```

### `curl` ve `wget` — ikisi de önemli, ama farklı amaçlar için

İkisi de HTTP(S)/FTP üzerinden veri çeker ama tasarım amaçları farklıdır:

- **`wget`**: **dosya indirmek** için tasarlanmıştır — varsayılan davranışı, aldığı içeriği doğrudan **diske kaydetmektir**. Bir siteyi bütünüyle (recursive) indirip yerel bir kopyasını çıkarmak gibi işlerde güçlüdür.
- **`curl`**: çok daha genel amaçlı bir **veri transfer** aracıdır — çok daha fazla protokolü destekler, ve varsayılan olarak aldığı içeriği **ekrana (stdout) basar**, dosyaya değil — bu onu script'lerde, API'lerle konuşurken (özel header/method/body gönderme) kullanmaya uygun hale getirir.

```bash
# curl
curl -O https://site.com/dosya.tar.gz   # -O: uzak dosyanın adıyla KAYDET
curl -o yerel_ad.tar.gz https://...     # -o: özel bir isimle kaydet
curl -L https://kisa.link/x              # -L: yönlendirmeleri (redirect) TAKİP ET
curl -I https://site.com                 # -I: sadece HTTP header'ları al (HEAD isteği)
curl -X POST -H "Content-Type: application/json" -d '{"k":"v"}' https://api.site.com
                                          # -X: HTTP metodu, -H: özel header, -d: gönderilecek veri (POST body)
curl -s https://site.com                 # -s: sessiz (ilerleme çubuğunu/hata çıktısını gizle)
curl -v https://site.com                 # -v: verbose — istek/yanıt detaylarını (header dahil) göster

# wget
wget https://site.com/dosya.iso          # varsayılan: uzak dosya adıyla diske kaydet
wget -O ozel_ad.iso https://...          # -O: özel bir isimle kaydet
wget -c https://.../buyuk_dosya.iso      # -c: yarım kalan indirmeye KALDIĞI YERDEN devam et
wget -r -np https://site.com/dizin/      # -r: recursive indir, -np: üst dizinlere ÇIKMA
```

### `diff`

İki dosyayı satır satır karşılaştırır, sadece **farkları** gösterir — özdeş satırları tekrar basmaz.

```bash
diff dosya1 dosya2          # varsayılan format: '<' ilk dosyada, '>' ikinci dosyada olan satırlar
diff -u dosya1 dosya2        # unified format: '-'/'+' işaretli, git/patch'in kullandığı standart format
diff -Nur dizin1/ dizin2/    # -r: dizinleri recursive karşılaştır, -N: bir tarafta OLMAYAN dosyayı boşmuş gibi say,
                              # -u: unified format — iki dizin ağacını topluca karşılaştırmak için klasik kombinasyon
```

Gün 5'in transkriptinde tam olarak `diff -Nur /home/ege/test ~/.bashrc` şeklinde kullanılmış — burada aslında bir dosya ile bir dosya karşılaştırılıyor (dizin değil), `-r`/`-N` bu durumda etkisiz kalır ama zarar da vermez; `-u` kısmı gerçek işi yapan, okunabilir fark çıktısını üreten bayraktır.

### Uygulamalı Örnek 1 — Kısıtlı sudo yetkisi (1. ödevin çözümü)

Standart bir "kısıtlı sudo yetkisi" (privilege delegation) senaryosu: belirli bir kullanıcıya, sadece belirli bir komutu (ve sadece belirli bir argümanla) root yetkisiyle çalıştırma izni vermek. Debian 13'te adım adım:

**Adım 1 — Kullanıcıyı oluştur:**
```bash
sudo useradd -m -s /bin/bash kisitli_kullanici
sudo passwd kisitli_kullanici
```
- `-m` → home dizinini otomatik oluştur (`/home/kisitli_kullanici`). Bu olmadan `useradd` sadece `/etc/passwd`'ye kayıt açar, dizin yaratmaz.
- `-s /bin/bash` → giriş shell'i olarak bash ata; belirtmezsen dağıtıma göre `/bin/sh` ya da hiç shell (`/usr/sbin/nologin`) atanabilir.

**Önemli:** Bu kullanıcı **hiçbir grupla** (özellikle `sudo` grubuyla) ilişkilendirilmiyor — `sudo` grubuna eklemek zaten sınırsız yetki verir; onun yerine `sudoers` dosyasında **komut bazlı** izin tanımlanıyor.

**Adım 2 — sudoers kuralını yaz (asıl kısım):**

`visudo` kullanmak zorunludur — doğrudan `/etc/sudoers`'ı `nano`/`vi` ile açma, çünkü `visudo` kaydetmeden önce syntax kontrolü yapar; sözdizimi hatalı bir sudoers dosyası **herkesin sudo kullanamamasına** yol açabilir.

```bash
sudo visudo -f /etc/sudoers.d/kisitli_kullanici
```

**Neden `/etc/sudoers.d/` altında ayrı dosya, ana `/etc/sudoers` değil?**
- Modülerlik: her kullanıcı/kural için ayrı dosya, karışıklığı önler.
- Ana `/etc/sudoers` dosyasına hiç dokunulmaz, hata riski azalır.
- Silmek istendiğinde sadece o dosya kaldırılır.

Dosyaya şu satır yazılır:
```
kisitli_kullanici ALL=(root) NOPASSWD: /usr/bin/rnano /etc/wgetrc
```

| Parça | Anlamı |
|---|---|
| `kisitli_kullanici` | kurala tabi olan kullanıcı |
| `ALL=` | bu kuralın geçerli olduğu **host** — sudoers dosyaları birden fazla makine arasında paylaşılabildiği için host bazlı çalışır; tek makinede `ALL` sorun olmaz |
| `(root)` | komut **hangi kullanıcı kimliğiyle** çalıştırılacak |
| `NOPASSWD:` | bu komut için parola sorulmasın (çıkarılırsa her seferinde kendi parolasını girmesi zorunlu olur — güvenlik açısından genelde parola istemek daha iyidir) |
| `/usr/bin/rnano /etc/wgetrc` | çalıştırılmasına izin verilen **tam komut yolu ve argüman** — kritik nokta burası |

**Neden tam yol + tam argüman, sadece `/usr/bin/rnano` değil?** Sadece `/usr/bin/rnano` yazılsaydı, kullanıcı `sudo rnano <herhangi_bir_dosya>` ile **sistemdeki istediği dosyayı** açabilirdi. Argümanı sabitlemek, kullanıcının başka dosyaları düzenlemesini engeller.

**Adım 3 — komutun gerçek yolunu doğrula:** sudoers path eşleşmesi tam ve kesin olduğu için:
```bash
which rnano
```

**Adım 4 — test et:**
```bash
su - kisitli_kullanici
sudo rnano /etc/wgetrc      # çalışmalı
sudo rnano /etc/passwd      # reddedilmeli — doğru komut, YANLIŞ dosya
sudo nano /etc/wgetrc       # reddedilmeli — doğru dosya, YANLIŞ komut (nano ≠ rnano, tam eşleşme gerekir)
sudo apt install nano       # reddedilmeli — tamamen alakasız komut
```

**Adım 5 — doğrulama komutu:**
```bash
sudo -l -U kisitli_kullanici    # o kullanıcıya tanımlı tüm sudo kurallarını listele
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

Beklenen tam olarak gerçekleşmiş: `sudo rnano /etc/wgetrc` sessizce (parola sormadan, `NOPASSWD` sayesinde) çalışmış; hem yanlış komut (`nano`) hem yanlış dosya (`/etc/passwd`) denemeleri reddedilmiş — sudoers'ın **komut + argüman birlikte tam eşleşme** kuralı iki farklı senaryoda da doğru çalıştığını kanıtlıyor.

### Kaynaklar

`/etc/passwd`/`/etc/shadow`/`/etc/group` alan yapısı, `chmod`/`chown`/ACL mekaniği, `sudo`/`su` farkı ve `sudoers` sözdizimi `man 5 passwd`/`man 5 shadow`/`man 5 sudoers`/`man 1 setfacl` ile doğrudan doğrulanabilir genel bilgilerdir — ayrıca kaynak gösterilmedi. Dağıtım-spesifik olan tek iddia MAC sisteminin hangi ailede varsayılan olduğudur:

- **SELinux'ün RHEL/Fedora/Rocky/AlmaLinux'ta, AppArmor'ın Debian (10'dan itibaren)/Ubuntu'da varsayılan olması:**
  - [AppArmor vs SELinux: Compare the Differences in Linux Security — TuxCare](https://tuxcare.com/blog/selinux-vs-apparmor/)

> [!TIP]
> **Bu tek kaynak ikincil (blog) niteliğinde — kendi sisteminde `getenforce`/`aa-status` ile doğrulaman, ya da dağıtımının resmi release notlarına bakman daha güvenilir olur.**

### Uygulamalı Örnek 2 — umask ile varsayılan 666 izin (2. ödevin çözümü)

Dosyaların varsayılan izni **umask** değeriyle belirlenir. `chmod`/ACL, **mevcut** bir dosyanın iznini sonradan değiştirmeye yarar; `umask` ise **yeni oluşturulan her dosyanın hangi izinle doğacağını** belirler.

**umask mantığı:** Linux'ta bir dosya oluşturulduğunda sistemin **maksimum varsayılan izni** dosyalar için `666`'dır (dizinler için `777`'dir, çünkü dizin oluşturma varsayılanı farklıdır). `umask` değeri, bu maksimumdan **hangi bitlerin çıkarılacağını** belirler:
```
Maksimum izin (dosya):  666
umask:                - 022
Sonuç:                   644
```
`umask`, izin **ekleyen** değil, izin **kısıtlayan** bir değerdir. `666` istemek (hem owner hem group hem other için read+write, execute hariç) aslında **hiçbir kısıtlama yapmamak** demektir: `666 (maksimum) - 000 (umask) = 666`. Yani hedef kullanıcı için `umask` değeri **`000`** olmalı.

> [!WARNING]
> **Güvenlik uyarısı: `umask 000`, kullanıcının oluşturduğu **her dosyayı sistemdeki herkesin okuyup yazabileceği** hale getirir — sadece kendisi değil, sunucudaki diğer TÜM kullanıcılar da (group ve other izinleri de 6 olduğu için) dosyayı değiştirebilir. Konfigürasyon dosyaları, script'ler veya hassas veri söz konusuysa ciddi bir risktir. Amaç sadece "aynı grup içindeki kullanıcılar birlikte çalışsın" ise `umask 002` (sonuç: `664` — group de yazabilir, other sadece okur) genelde yeterli ve daha güvenlidir.**

**Uygulama — sadece bu kullanıcı için kalıcı hale getirmek:**
```bash
echo "umask 000" | sudo tee -a /home/egee/.bashrc
```
- **Neden `.bashrc`'ye ekleniyor:** `umask`, oturuma özgü bir shell ayarıdır, kalıcı bir sistem dosyası değildir. Kullanıcı her `bash` oturumu açtığında (SSH ile de, `su - kullanici` ile de) bu dosya otomatik okunur, `umask 000` çalıştırılır.
- **`-a` neden şart:** `tee` tek başına dosyanın **üzerine yazar**; `-a` (append) `.bashrc`'nin mevcut içeriğini silmeden **sona ekler**.

**Doğrulama:**
```bash
su - egee
umask                    # 0000 çıkmalı
touch test.txt
ls -l test.txt           # -rw-rw-rw- (666) görülmeli
```

**Kapsam notu:** `.bashrc` sadece **interaktif** shell'lerde okunur — bir cron job ya da servis bu dosyayı hiç okumaz. Daha kapsayıcı olmak için `.profile`'a da eklenebilir; cron job'lar için ise crontab'ın (`crontab -u kullanici -e`) en üstüne doğrudan `umask 000` satırı eklenmesi gerekir.

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
> **Dikkat çeken bir nokta: `test2`/`test3.txt` (`.bashrc`'ye ilk `umask 000` eklenmeden ÖNCE, eski oturumda açılmış) `644` çıkıyor — bu beklenen, çünkü o satır henüz `.bashrc`'de yokken oluşturulmuşlar. Ama en sonda, `.bashrc`'de `umask 000` satırı zaten varken açılan **yeni** bir `su - egee` oturumunda oluşturulan `test47.txt` yine `644` çıkıyor — bu, `umask`'ın oturuma özgü olduğunu ve `.bashrc` içeriğinin **o an ne ise** onun uygulandığını gösteren iyi bir kontrol noktası. Kendi ortamınızda benzer bir tutarsızlık görürseniz ilk bakılacak yer `cat ~/.bashrc | grep umask` — dosyada aynı satırın (`sed` ile silinmeye çalışılan ama yanlış yazıldığı için silinemeyen bir `umask 009` gibi) birden fazla, çelişen kopyası olup olmadığını kontrol edin; bash `.bashrc`'yi baştan sona sırayla çalıştırır, dosyadaki **en son** `umask` satırı geçerli olur.**

## Notlar

- Bugünün ana teması: DAC (chmod/chown/ACL — sahip karar verir) ile MAC (SELinux/AppArmor — merkezi politika, sahip bile aşamaz) arasındaki kavramsal ayrım, ve `sudo`'nun `su`'dan farkının aslında "tam oturum devri" ile "tek komutluk, denetlenebilir yetki delegasyonu" arasındaki fark olduğu.
- `sudoers` kuralları yazarken en kritik nokta: sadece binary yolunu değil, **argümanı da** sabitlemek — aksi halde "sadece bu dosyayı düzenlesin" niyeti, "her şeyi düzenleyebilsin" sonucuna dönüşür.
- `umask`, mevcut dosyaların değil, **gelecekte oluşacak** dosyaların varsayılan iznini belirler — `chmod` ile karıştırılmamalı; oturuma özgüdür, `.bashrc`/`.profile`/crontab gibi doğru başlangıç dosyasına yazılmazsa kalıcı olmaz.
- `/etc/shadow`'un var olma nedeni tek cümleyle özetlenebilir: "herkesin okuyabildiği bir dosyada parola hash'i tutmak güvenli değildir" — bu prensip, ACL/SELinux gibi daha ileri erişim kontrol katmanlarının da temel motivasyonuyla aynıdır: erişimi mümkün olan en dar çevreye indirmek.

## Komutlar / Örnekler

```bash
# kullanıcı/grup veritabanı dosyaları
cat /etc/passwd | grep kullanici
sudo cat /etc/shadow
cat /etc/group

# izinler
chmod 750 dosya
chmod -R 755 dizin/
chown ucp:sudo dosya
chgrp sudo dosya

# ACL
getfacl dosya
setfacl -m u:ege:rwx dosya
setfacl -x u:ege dosya
setfacl -d -m u:ege:rwx dizin/

# SELinux / AppArmor
getenforce
setenforce 0
aa-status

# kullanıcı yönetimi
sudo useradd -m -s /bin/bash kullanici
sudo userdel -r kullanici
id
groups

# sudo / sudoers
sudo visudo -f /etc/sudoers.d/kullanici
sudo -l -U kullanici

# editörler / pager
nano dosya
vi dosya
less /var/log/syslog

# history
history
!245
!245:p
!!

# locate / curl / wget / diff
locate dosya_adi
curl -O https://site.com/dosya
wget -c https://site.com/buyuk_dosya.iso
diff -u dosya1 dosya2
diff -Nur dizin1/ dizin2/
```

## Sorular / Takip Edilecekler

- [ ] `test47.txt`'nin neden `644` çıktığını (yukarıdaki tip kutusundaki gözlem) `~/.bashrc` içeriğini `grep umask` ile inceleyerek doğrula.
