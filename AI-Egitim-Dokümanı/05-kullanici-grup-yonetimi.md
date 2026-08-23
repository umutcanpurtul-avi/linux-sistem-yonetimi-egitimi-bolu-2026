---
tags: [linux, egitim, kullanici, guvenlik]
modul: 05
durum: tamamlandi
---

# 05 — Kullanıcı ve Grup Yönetimi

> **Ön koşul:** [04-dosya-sistemi](04-dosya-sistemi.md)
> **Süre:** ~3 saat

## Hedefler

- [ ] `/etc/passwd`, `/etc/shadow`, `/etc/group` alanlarını okuyabiliyorum
- [ ] Kullanıcı ekleme/silme/düzenlemeyi bilinçli parametrelerle yapıyorum
- [ ] Toplu kullanıcı ekleyebiliyorum
- [ ] Parola politikası uygulayabiliyorum
- [ ] `su`, `sudo` ve `sudoers` yapılandırmasını doğru kullanıyorum

---

## 1. Kullanıcı bilgisi nerede tutulur?

> [!NOTE]
> **Neden bilgi üç ayrı dosyaya bölünmüş, tek dosya olsa olmaz mıydı?**
> Aslında tarihte tek dosyaydı — eskiden hem kullanıcı bilgisi hem parola hash'i
> `/etc/passwd` içindeydi. Ama `/etc/passwd`'nin **herkes tarafından okunabilir**
> olması gerekiyor: `ls -l` bir dosyanın sahibini isimle göstermek için, `id` bir
> kullanıcının UID'sini çözmek için, hemen hemen her program kullanıcı adı ↔ UID
> eşlemesini bilmek için bu dosyayı okur. Ama parola hash'lerinin herkes tarafından
> okunabilir olması güvenlik felaketidir — hash'i elde eden biri, çevrimdışı olarak
> onu kırmaya (brute-force) çalışabilir. Çözüm: bilgiyi ikiye böl. "Herkesin bilmesi
> gereken" kısım (`/etc/passwd`) herkese açık kalsın, "sadece root'un görmesi gereken"
> kısım (`/etc/shadow`, parola hash'leri ve parola yaşlandırma kuralları) sadece
> root'a kapalı olsun. `/etc/group` ise aynı mantıkla, grup üyeliklerini tutan ayrı
> bir dosyadır — kullanıcı bilgisiyle grup bilgisini birbirinden ayırmak, bir
> kullanıcının birden fazla gruba üye olabilmesini (passwd'de tek satırlık bir kayıt
> bunu ifade edemez) doğal olarak mümkün kılar.

### `/etc/passwd` — herkese okunabilir (644)

```
ali:x:1000:1000:Ali Yilmaz:/home/ali:/bin/bash
 │  │  │    │       │          │        └─ giriş kabuğu
 │  │  │    │       │          └─ ev dizini
 │  │  │    │       └─ GECOS (tam ad, telefon vb. — serbest metin)
 │  │  │    └─ GID (birincil grup)
 │  │  └─ UID
 │  └─ parola alanı: "x" = parola /etc/shadow'da
 └─ kullanıcı adı
```

> [!NOTE]
> **Bu satırı alan alan sök**
> Satır `:` ile ayrılmış **7 alandan** oluşur, sırasıyla:
> 1. **Kullanıcı adı** (`ali`) — sistemde giriş yaparken yazdığın isim.
> 2. **Parola alanı** (`x`) — tarihsel olarak burada parola hash'i olurdu; bugün
>    hemen her sistemde sabit `x` yazar, bu da "gerçek hash `/etc/shadow`'da ara"
>    demenin bir işaretidir. Eğer bu alan boşsa, o kullanıcı parolasız giriş
>    yapabilir demektir (ciddi bir güvenlik açığı — asla böyle bırakılmamalı).
> 3. **UID** (User ID, `1000`) — kullanıcının **gerçek kimliği** sistem için sayısal
>    bir numaradır. "ali" ismi sadece insanlar için bir kolaylıktır; kernel ve dosya
>    sistemi seviyesinde her şey UID ile takip edilir. Bir dosyanın sahibi aslında
>    diskte bir isim değil, bir UID sayısı olarak saklanır — `ls -l` o sayıyı
>    `/etc/passwd`'e bakıp isme çevirerek gösterir.
> 4. **GID** (Group ID, `1000`) — bu kullanıcının **birincil grubu**. Aşağıda
>    "birincil vs ek grup" bölümünde bunun ne anlama geldiğini ayrıntılı göreceksin.
> 5. **GECOS** (`Ali Yilmaz`) — serbest metin alanı, genelde tam ad, bazen telefon/oda
>    numarası gibi ek bilgiler (virgülle ayrılmış) tutar; sistemin işleyişini etkilemez,
>    sadece insan-okunabilirlik için vardır.
> 6. **Ev dizini** (`/home/ali`) — kullanıcı giriş yaptığında hangi dizinde başlayacağı,
>    `$HOME` değişkeninin değeri budur.
> 7. **Giriş kabuğu** (`/bin/bash`) — kullanıcı giriş yaptığında hangi programın
>    (kabuğun) çalıştırılacağı. Bu alanın `/sbin/nologin` veya `/bin/false` olması,
>    o kullanıcının **interaktif olarak giriş yapamayacağı** anlamına gelir — bu,
>    servis hesapları için kasıtlı bir güvenlik tercihidir (aşağıda göreceksin).

### `/etc/shadow` — sadece root (640 veya 000)

```
ali:$6$rounds=...$hash:19700:0:90:7:14::
 │        │           │   │  │  │  │
 │        │           │   │  │  │  └─ hesap devre dışı kalmadan önceki ek gün
 │        │           │   │  │  └─ uyarı: bitmeden kaç gün önce uyar
 │        │           │   │  └─ maksimum: kaç günde bir değişmeli
 │        │           │   └─ minimum: değiştirdikten sonra kaç gün geçmeli
 │        │           └─ son değişim (1 Ocak 1970'ten beri gün)
 │        └─ parola hash'i ($6 = SHA-512, $y = yescrypt)
 └─ kullanıcı
```

> [!NOTE]
> **Bu satırı da alan alan sök**
> `:` ile ayrılmış **9 alan** vardır (yukarıdaki örnekte sonuncu iki alan boş
> bırakıldığı için görünmüyor). Sırasıyla:
> 1. **Kullanıcı adı** — `/etc/passwd`'deki isimle eşleşir, iki dosyayı birbirine
>    bağlayan anahtar budur.
> 2. **Parola hash'i** (`$6$rounds=...$hash`) — parolanın kendisi **hiçbir zaman**
>    diskte saklanmaz, sadece tek yönlü bir matematiksel fonksiyondan (hash) geçmiş
>    hâli saklanır. `$6$` bunun SHA-512 algoritmasıyla hash'lendiğini gösterir (`$y$`
>    ise daha yeni ve güçlü olan yescrypt algoritmasını gösterir, modern dağıtımlarda
>    varsayılan olmaya başladı). Giriş yaparken yazdığın parola aynı fonksiyondan
>    geçirilip sonuç bu hash ile karşılaştırılır — eşleşirse giriş kabul edilir, orijinal
>    parolanın ne olduğu hiçbir zaman geri hesaplanmaz (tek yönlü fonksiyon budur).
> 3. **Son değişim** (`19700`) — 1 Ocak 1970'ten (Unix epoch) beri geçen **gün** sayısı
>    olarak, parolanın en son ne zaman değiştirildiği.
> 4. **Minimum yaş** (`0`) — parola değiştirildikten sonra tekrar değiştirilmeden önce
>    geçmesi gereken minimum gün. `0` = istediğin an tekrar değiştirebilirsin.
> 5. **Maksimum yaş** (`90`) — parolanın kaç günde bir zorunlu olarak değiştirilmesi
>    gerektiği.
> 6. **Uyarı süresi** (`7`) — parola süresi dolmadan kaç gün önce kullanıcıya
>    "parolan yakında sona erecek" uyarısı gösterileceği.
> 7. **Devre dışı kalma süresi** (`14`) — parola süresi dolduktan sonra, hesabın tam
>    olarak kilitlenmesine kadar (parolayı hâlâ değiştirmemişse) kaç gün tolerans
>    tanınacağı.
> 8. **Hesap bitiş tarihi** (boş) — epoch'tan beri gün cinsinden, hesabın tamamen
>    süresinin dolacağı mutlak tarih (`chage -E` ile ayarlanır — stajyer hesapları
>    gibi belirli bir tarihte tamamen kapanması gereken hesaplar için).
> 9. **Ayrılmış alan** (boş) — gelecekteki kullanım için ayrılmıştır, şu an işlevi yok.

Parola alanındaki özel değerler:
- `!` veya `!!` → hesap **kilitli**
- `*` → parola ile giriş yok (sistem hesapları)
- boş → parolasız giriş (**tehlikeli**)

> [!WARNING]
> **`!` ile `*` arasındaki fark neden önemli?**
> İkisi de "parola ile giriş yapılamaz" gibi görünür ama anlamları farklıdır. `!`
> (veya `!!`), hash'in **başına** eklenir — yani orijinal hash hâlâ oradadır, sadece
> önüne `!` konarak geçersiz kılınmıştır (`usermod -L` tam olarak bunu yapar). Bu
> **geri alınabilir**: `usermod -U` ile `!` kaldırılır, eski hash tekrar geçerli olur
> — kullanıcı eski parolasıyla tekrar giriş yapabilir. `*` ise sistem hesapları
> (örneğin `www-data`, `nginx` gibi bir servisin çalıştığı ama kimsenin giriş
> yapmayacağı hesaplar) için kullanılan, **hiçbir zaman parola atanmamış** anlamına
> gelen sabit bir işarettir — bu hesaplara zaten parola ile giriş yapılması hiç
> beklenmez.

### `/etc/group`

```
gelistirici:x:1001:ali,veli,ayse
     │       │  │        └─ ek üyeler
     │       │  └─ GID
     │       └─ grup parolası (neredeyse hiç kullanılmaz, gshadow'da)
     └─ grup adı
```

> [!NOTE]
> **"Ek üyeler" listesi neyi göstermiyor?**
> Bu satırdaki üye listesi (`ali,veli,ayse`) sadece bu grubu **ek (supplementary)
> grup** olarak kullanan kullanıcıları gösterir. Eğer `ali`'nin **birincil** grubu
> zaten `gelistirici` ise (yani `/etc/passwd`'deki GID alanı bu grubun GID'siyle
> eşleşiyorsa), `ali`'nin adı bu listede **görünmeyebilir** — çünkü birincil grup
> üyeliği `/etc/passwd`'den gelir, `/etc/group`'taki liste sadece "ek olarak buraya
> da dahil" anlamındadır. Bu, `groups ali` veya `id ali` komutuyla kontrol ederken
> kafa karıştırabilir: bir kullanıcının tüm gruplarını görmek için asla sadece
> `/etc/group`'a bakma, her zaman `id` veya `groups` komutunu kullan — onlar hem
> passwd hem group dosyasını birleştirerek doğru sonucu verir.

### UID aralıkları

| Aralık | Kim |
|---|---|
| 0 | root |
| 1–999 | Sistem/servis hesapları (RHEL 9, Debian 12) |
| 1000+ | Normal kullanıcılar |

> [!NOTE]
> **Neden bu ayrım var, sistem hesabı normal kullanıcıdan neden farklı?**
> Bir sunucuda çalışan her servis (web sunucusu, veritabanı, mail sunucusu) kendi
> ayrı kullanıcı kimliğiyle çalışmalıdır — hepsi `root` olarak çalışsaydı, o
> servislerden birinde bulunan bir güvenlik açığı, saldırgana doğrudan tam sistem
> yetkisi verirdi. Ama bu servis hesapları **insan değildir** — giriş yapmaz, parola
> girmez, sadece bir programı çalıştırmak için var olur. UID aralığını ayırmak, bu
> iki kategoriyi (gerçek insanlar vs. servis hesapları) birbirinden ayırt etmeyi
> kolaylaştırır: örneğin bir yönetim aracı "sadece 1000 ve üzeri UID'li hesapları
> listele" diyerek gerçek kullanıcıları servis hesaplarından otomatik ayırabilir
> (`awk -F: '$3>=1000 {print $1}' /etc/passwd` — 06. modülde bunu tekrar göreceksin).
> `0` (root) ayrı tutulur çünkü sistemde **sınırsız yetkiye** sahip tek hesap odur —
> UID 0 olan her hesap, adı ne olursa olsun root yetkisine sahiptir.

> **Dağıtım farkı:** Eski RHEL 6'da sistem hesapları 1–499'du, normal kullanıcılar
> 500'den başlardı. RHEL 7+ ve Debian'da sınır 1000. Eski bir sistemden veri
> taşıyorsan UID çakışması yaşarsın — `usermod -u` ile düzeltilir.

### Bilgi sorgulama

```bash
id ali                     # UID, GID, tüm gruplar
id                         # Kendin
groups ali                 # Sadece gruplar
getent passwd ali          # passwd kaydı (LDAP/AD dahil tüm kaynaklardan)
getent group gelistirici
who                        # Şu an giriş yapmışlar
w                          # who + ne yaptıkları
last                       # Giriş geçmişi
lastlog                    # Her kullanıcının son girişi
```

> `getent` neden `cat /etc/passwd`'den iyi? Sistem LDAP/AD/SSSD kullanıyorsa
> kullanıcı yerel dosyada yoktur. `getent` NSS zincirinin tamamına sorar.
> AD'ye bağlı bir sunucuda çalışırken bu ayrım kritik.

> [!NOTE]
> **"NSS zinciri" tam olarak ne demek?**
> NSS (Name Service Switch), Linux'a "bir kullanıcı adını çözerken hangi kaynaklara,
> hangi sırayla bakacağını" söyleyen bir yapılandırma katmanıdır (`/etc/nsswitch.conf`
> dosyasında tanımlanır). Basit bir masaüstünde bu zincir tek bir halkadan oluşur:
> `/etc/passwd`. Ama kurumsal bir ortamda sunucu genelde bir merkezi kimlik sunucusuna
> (LDAP veya Active Directory, SSSD servisi üzerinden) bağlıdır — bu durumda zincir
> "önce yerel dosyaya bak, yoksa SSSD'ye sor, o da LDAP/AD'ye sorar" şeklinde
> genişler. `cat /etc/passwd` sadece **yerel** dosyayı okur, zincirin diğer
> halkalarını görmez — bu yüzden AD'den gelen bir kullanıcı `cat /etc/passwd | grep`
> ile bulunamaz ama giriş yapabilir (çünkü giriş sırasında PAM/NSS zincirinin
> tamamı sorgulanır). `getent passwd kullanici`, tam olarak sistemin kendisinin
> kullandığı bu zinciri sorgular, bu yüzden her zaman `cat /etc/passwd`'den daha
> güvenilir bir kontrol yoludur.

---

## 2. Varsayılan ayarlar

> [!NOTE]
> **Bu üç dosya neden ayrı ayrı var, birleştirilemez miydi?**
> Yeni bir kullanıcı açtığında birçok "varsayılan" değer devreye girer — hangi UID
> aralığından numara verilecek, ev dizini nerede açılacak, hangi dosyalar o ev
> dizinine kopyalanacak. Bu üçü **farklı türde** bilgiler taşıdığı için ayrılmıştır:
> biri **sayısal politika** (UID aralığı, parola kuralları — `/etc/login.defs`),
> biri **komut davranışı** (useradd'ın varsayılan bayrakları — `/etc/default/useradd`),
> biri de **gerçek dosya şablonu** (yeni kullanıcının ev dizinine kopyalanacak
> gerçek `.bashrc` gibi dosyalar — `/etc/skel/`). Bu ayrım, sistem yöneticisinin
> her birini bağımsız olarak değiştirebilmesini sağlar — mesela sadece `/etc/skel`
> içindeki `.bashrc`'yi değiştirmek, UID politikasına hiç dokunmadan tüm yeni
> kullanıcılara farklı bir varsayılan kabuk ayarı dağıtmanı sağlar.

Yeni kullanıcı açarken değerler şu üç yerden gelir:

| Dosya | Ne belirler |
|---|---|
| `/etc/login.defs` | UID/GID aralığı, parola yaşlandırma, `UMASK`, ev dizini oluşturma |
| `/etc/default/useradd` | Varsayılan kabuk, ev dizini kökü, iskelet dizini, hesap süresi |
| `/etc/skel/` | Yeni ev dizinine **kopyalanacak** dosyalar (`.bashrc`, `.profile`) |

```bash
useradd -D                    # /etc/default/useradd içeriğini gösterir
useradd -D -s /bin/bash       # Varsayılan kabuğu kalıcı değiştir
grep -E "^(UID_MIN|PASS_MAX_DAYS|UMASK)" /etc/login.defs
ls -la /etc/skel
```

**`/etc/skel` işe yarar kullanım:** Tüm yeni kullanıcılara standart bir `.vimrc`,
`.bashrc` alias'ı veya kurumsal uyarı mesajı dağıtmak.

> [!NOTE]
> **Bu tam olarak nasıl işler?**
> `useradd -m` (ev dizini oluştur) çalıştırıldığında, sistem yeni ev dizinini
> **boş** oluşturmaz — `/etc/skel/` dizininin **içeriğinin tamamını** yeni ev
> dizinine kopyalar (gizli dosyalar dahil). Yani `/etc/skel/.bashrc` diye bir dosya
> varsa, bundan sonra oluşturulan **her** yeni kullanıcının ev dizininde de aynı
> `.bashrc` otomatik olarak hazır bulunur. Bu, kurum genelinde standart bir shell
> yapılandırması, güvenlik uyarısı mesajı, ya da hazır bir dizin yapısı (`~/Belgeler`,
> `~/Projeler` gibi) dağıtmanın en temiz yoludur — `/etc/skel`'e bir kez ekleme
> yaparsın, bundan sonra açılan her hesap otomatik olarak o düzeni miras alır.
> Önemli nokta: bu kopyalama sadece **yeni** kullanıcı açılırken olur — `/etc/skel`'i
> bugün değiştirsen, dün açılmış kullanıcıların ev dizinleri geriye dönük etkilenmez.

---

## 3. Kullanıcı işlemleri

```bash
# Ekleme
sudo useradd ali                       # Minimal (RHEL'de ev dizini açar, Debian'da AÇMAZ!)
sudo useradd -m -s /bin/bash -c "Ali Yilmaz" ali
#            │   │              └─ GECOS
#            │   └─ kabuk
#            └─ ev dizini oluştur

sudo useradd -m -G gelistirici,docker -s /bin/bash veli   # ek gruplarla
sudo useradd -r -s /sbin/nologin servishesap              # sistem hesabı, girişsiz
sudo useradd -e 2026-12-31 stajyer                        # son kullanma tarihli hesap

# Parola
sudo passwd ali                        # etkileşimli
echo "ali:Parola123" | sudo chpasswd   # script içinden (geçmişe düşer, dikkat)

# Düzenleme
sudo usermod -aG docker ali            # ⭐ -a (append) ŞART, yoksa eski grupları SİLER
sudo usermod -s /bin/zsh ali           # kabuk değiştir
sudo usermod -l yeniad eskiad          # kullanıcı adı değiştir
sudo usermod -d /yeni/ev -m ali        # ev dizinini taşı
sudo usermod -L ali                    # kilitle (shadow'a ! ekler)
sudo usermod -U ali                    # kilidi aç
sudo usermod -e 2026-01-01 ali         # hesap bitiş tarihi

# Silme
sudo userdel ali                       # kullanıcıyı sil, EV DİZİNİ KALIR
sudo userdel -r ali                    # ev dizini ve mail spool'u da sil
```

> [!WARNING]
> **`useradd ali` neden dağıtıma göre farklı davranıyor?**
> Bu, sık karşılaşılan ve kafa karıştıran bir farktır. RHEL ailesinde `useradd`'ın
> varsayılan davranışı (dağıtımın kendi `/etc/login.defs` ve `/etc/default/useradd`
> ayarları gereği) ev dizinini otomatik oluşturmaktır. Debian/Ubuntu'da ise `useradd`
> **çıplak, POSIX-uyumlu** bir davranış sergiler — `-m` bayrağı verilmediği sürece
> ev dizini açmaz (Debian ailesinde günlük kullanıcı yönetimi için asıl önerilen
> araç `adduser` betiğidir, `useradd`'ın üzerine daha "akıllı" ve etkileşimli bir
> katman koyar; ama iki dağıtım ailesinde de tutarlı çalışması için bu notlarda
> doğrudan `useradd` kullanılıyor). Bu farkı bilmeden Debian'da `useradd ali` yazıp
> "neden ev dizini yok" diye şaşırmak çok yaygın bir hatadır — **her zaman `-m`
> yazma alışkanlığı edin**, dağıtım farketmeksizin garanti eder.

> ⚠️ `usermod -G` ile `usermod -aG` farkı, sahada en sık yapılan hatadır.
> `-a` yazmazsan kullanıcının mevcut tüm ek gruplarını silip yalnızca yazdığını bırakır.
> Bir kullanıcıyı `wheel` grubundan istemeden çıkarmak = sudo erişimini kaybetmek.

> [!NOTE]
> **Bu neden böyle davranıyor, `-a` olmadan neden "silme" oluyor?**
> `usermod -G` komutunun temel mantığı **"bu kullanıcının ek grup üyeliklerini
> tam olarak şu listeye eşitle"**dir — yani mutlak bir atamadır, mevcut duruma
> bakmaz. `ali` şu an `wheel`, `docker`, `gelistirici` gruplarındaysa ve sen
> `usermod -G docker ali` yazarsan, sistem bunu "ali'nin ek grupları artık SADECE
> docker olsun" olarak yorumlar — `wheel` ve `gelistirici`'den çıkarır. `-a`
> (append) bayrağı bu davranışı "listeye ekle" moduna çevirir: mevcut grupları
> koru, sadece yeni belirtileni **de** ekle. Sonuç genelde şaşırtıcı olur çünkü
> hata anında görünmez — `ali` hâlâ giriş yapabiliyordur, ama bir sonraki `sudo`
> denemesinde "not in the sudoers file" hatasıyla karşılaşır, o an neden olduğunu
> anlamak zaman alır. Bu yüzden alışkanlık olarak **her zaman `-aG` yaz, asla
> yalnız `-G` yazma** — istisna, gerçekten bilinçli olarak "üyelikleri sıfırlayıp
> yeniden belirle" istediğin nadir durumdur.

### Kilitleme yöntemleri farkı

| Komut | Etkisi |
|---|---|
| `usermod -L` / `passwd -l` | Parola ile giriş engellenir. **SSH anahtarı hâlâ çalışır!** |
| `usermod -s /sbin/nologin` | Kabuk yok — interaktif giriş yok, ama SFTP/tünel olabilir |
| `usermod -e 1` | Hesap süresi dolmuş sayılır — **anahtar dahil her yol kapanır** ✅ |
| `chage -E 0 ali` | Aynısı |

> [!NOTE]
> **Bu dört yöntem neden farklı "katmanları" kapatıyor?**
> Bir kullanıcının sisteme girebileceği birden fazla **yol** vardır: parola ile
> interaktif giriş, SSH anahtarıyla giriş, ya da hiç kabuk çalıştırmadan sadece
> dosya transferi (SFTP) veya port yönlendirme (tünel). Her kilitleme yöntemi
> sadece **bir yolu** kapatır: `usermod -L`, `/etc/shadow`'daki hash'in başına `!`
> koyarak sadece "parola girip giriş yapma" yolunu kapatır — ama SSH anahtar
> doğrulaması hiç parola kontrolü yapmadığı için bu kilit onu etkilemez, kullanıcı
> anahtarıyla girmeye devam edebilir. `usermod -s /sbin/nologin`, kullanıcının
> giriş yaptığında çalıştırılacak programı "hiçbir şey yapma, sadece çık" yapan
> bir programa çevirir — interaktif kabuk (bash gibi) açılamaz, ama SSH protokolü
> seviyesinde SFTP veya port yönlendirme kabuk gerektirmediği için yine mümkün
> olabilir. `usermod -e 1` (ya da `chage -E 0`) ise **hesabın kendisini** "süresi
> dolmuş" olarak işaretler — bu, PAM seviyesinde kontrol edilir ve parola, anahtar,
> kabuk türü fark etmeksizin **her türlü** girişi engeller. Bir çalışanı işten
> çıkarırken güvenli olan tek yöntem budur; diğerleri kısmi önlemlerdir.

Bir çalışan işten ayrıldığında doğru hamle: `usermod -L ali && usermod -e 1 ali`
ve `~/.ssh/authorized_keys` kontrolü.

---

## 4. Toplu kullanıcı ekleme

> [!NOTE]
> **Neden toplu ekleme ayrı bir konu, tek tek useradd yeterli değil mi?**
> 5-10 kullanıcı için tek tek `useradd` çalıştırmak mantıklı olabilir, ama 50-100
> öğrenciye/çalışana hesap açman gerektiğinde elle tek tek yazmak hem zaman kaybı
> hem hata riskidir (bir parametreyi unutmak, bir grubu yanlış yazmak gibi). Toplu
> ekleme yöntemleri, aynı kalıbı **güvenilir ve tekrarlanabilir** şekilde bir listeye
> uygulamanı sağlar — otomasyonun temel prensibi budur: bir işlemi bir kere doğru
> yaz, sonra o doğruluğu istediğin kadar tekrarla.

### Yöntem 1 — `newusers` (hazır araç)

```bash
cat > kullanicilar.txt <<'EOF'
ali1:Gecici123!:1201:1201:Ali Bir:/home/ali1:/bin/bash
ali2:Gecici123!:1202:1202:Ali Iki:/home/ali2:/bin/bash
EOF

sudo newusers kullanicilar.txt
```
Biçim `/etc/passwd` ile aynı, sadece 2. alana açık parola yazılır.

> [!NOTE]
> **`newusers` ne yapıyor, `/etc/passwd`'yi doğrudan mı düzenliyor?**
> `newusers`, verdiğin dosyadaki her satırı okuyup, o satırdaki bilgilerle sanki
> sen `useradd` + `passwd` çalıştırmışsın gibi kullanıcıları tek tek, doğru şekilde
> (ev dizinleri açılarak, `/etc/skel` kopyalanarak, parola hash'lenerek) oluşturur.
> Dosyanın biçiminin `/etc/passwd` ile aynı olması bir tesadüf değil — bu satırların
> zaten "bir kullanıcıyı tam olarak tanımlayan" standart biçim olduğunu gösterir,
> `newusers` sadece bu biçimi girdi olarak kabul edip gerçek kullanıcı oluşturma
> işlemlerini senin yerine otomatik yapar. Tek fark: normalde `/etc/passwd`'de
> parola alanı `x` olur (gerçek hash shadow'da), ama bu girdi dosyasında 2. alana
> **açık metin** parola yazarsın — `newusers` bunu okuyup hash'leyip shadow'a
> kendisi yazar.

### Yöntem 2 — döngüyle (daha esnek, tercih edilen)

```bash
#!/bin/bash
# kullanicilar.csv:  kullaniciadi,tamad,grup
while IFS=, read -r kadi tamad grup; do
    # grup yoksa oluştur
    getent group "$grup" >/dev/null || sudo groupadd "$grup"

    if id "$kadi" &>/dev/null; then
        echo "ATLANDI: $kadi zaten var"
        continue
    fi

    sudo useradd -m -c "$tamad" -G "$grup" -s /bin/bash "$kadi"
    # rastgele parola üret
    parola=$(openssl rand -base64 12)
    echo "$kadi:$parola" | sudo chpasswd
    sudo chage -d 0 "$kadi"          # ilk girişte parola değiştirmeye zorla
    echo "$kadi,$parola" >> olusturulan-parolalar.csv
done < kullanicilar.csv

chmod 600 olusturulan-parolalar.csv
```

> [!NOTE]
> **Bu betiğin her satırı neden orada, ne sorunu önlüyor?**
> - `getent group "$grup" || groupadd` — grup zaten varsa tekrar oluşturmaya
>   **çalışmaz** (bu hata verirdi), yoksa oluşturur. Betiği güvenle tekrar tekrar
>   çalıştırabilmeni sağlar (idempotency — aynı betiği iki kere çalıştırsan da
>   sonuç bozulmaz).
> - `if id "$kadi" &>/dev/null; then ... continue` — kullanıcı zaten varsa
>   `useradd` hata verip betiği durdurmasın diye, o kullanıcıyı atlayıp devam eder.
>   Bu da aynı idempotency prensibinin bir parçası: yarıda kesilen bir toplu
>   ekleme işlemini güvenle yeniden çalıştırabilirsin, zaten eklenmiş olanlar
>   tekrar denenmez.
> - `openssl rand -base64 12` — her kullanıcı için **tahmin edilemez, benzersiz**
>   bir geçici parola üretir; herkese aynı sabit parolayı vermek (mesela hepsine
>   "Merhaba123") güvenlik açısından çok zayıftır çünkü biri bunu öğrenirse tüm
>   hesaplara girer.
> - `chage -d 0 "$kadi"` — bu satır kritik: "son parola değişim tarihi" alanını
>   epoch'un başlangıcı (0) olarak ayarlar, bu da sisteme "bu parola hiç
>   değiştirilmemiş, süresi zaten dolmuş" dedirtir — kullanıcı ilk girişinde
>   sistem otomatik olarak parola değiştirmeye zorlar. Böylece geçici parolayı
>   sen (ya da script) bilse bile, kullanıcı ilk girişte kendi gizli parolasını
>   belirlemek zorunda kalır.
> - `chmod 600 olusturulan-parolalar.csv` — bu dosya düz metin parolalar içeriyor;
>   herkes tarafından okunabilir kalırsa tüm o parolalar sızmış sayılır.

`chage -d 0` — bu satır önemli: kullanıcı ilk girişte parolasını değiştirmek zorunda kalır.

---

## 5. Grup işlemleri

```bash
sudo groupadd gelistirici
sudo groupadd -g 5000 ozelgrup       # belirli GID ile
sudo groupmod -n yeniad eskiad       # yeniden adlandır
sudo groupdel gelistirici            # sil (birincil grup ise silemez)

sudo gpasswd -a ali gelistirici      # kullanıcıyı gruba ekle
sudo gpasswd -d ali gelistirici      # gruptan çıkar
sudo gpasswd -M ali,veli gelistirici # üye listesini TAMAMEN değiştir

groups ali                           # ali hangi gruplarda
getent group gelistirici             # grubun üyeleri
```

### Birincil vs ek grup

> [!NOTE]
> **Bu ayrım pratikte ne fark yaratır?**
> Bir kullanıcının **tam olarak bir** birincil grubu vardır ama **birden fazla**
> ek grubu olabilir — bu, gerçek hayattaki "bir kişinin bir ana departmanı ama
> birden fazla proje ekibinde görevi olabilmesi" durumuna benzer. Birincil grubun
> pratikteki tek somut etkisi şudur: sen yeni bir dosya oluşturduğunda (SGID yoksa),
> o dosyanın grubu **otomatik olarak senin birincil grubun** olur — `touch dosya`
> yazdığında hangi grubun sahip olacağını sen belirtmezsin, sistem senin birincil
> grubunu kullanır. Ek gruplar ise sana **erişim yetkisi** kazandırır: bir dizin
> `gelistirici` grubuna `rwx` veriyorsa ve sen `gelistirici` grubunun ek üyesiysen,
> o dizine erişebilirsin — ama orada oluşturduğun yeni bir dosyanın grubu yine de
> senin birincil grubun olur (SGID dizin değilse).

- **Birincil (primary):** `/etc/passwd`'deki GID. Kullanıcı dosya oluşturduğunda
  dosyanın grubu bu olur. Bir tane olur.
- **Ek (supplementary):** `/etc/group`'ta listelenir. Yetki almak için. Kaç tane olursa.

> **Dağıtım farkı — UPG (User Private Group):**
> RHEL ailesi ve Debian, her kullanıcı için kendi adında bir grup açar (`ali:x:1000` +
> `ali` grubu GID 1000). Bu yüzden RHEL'de umask `002` güvenlidir — grup yazma izni
> sadece kullanıcının kendisini kapsar.
> Eski bazı sistemlerde herkes `users` grubuna atılırdı; orada `002` tehlikeliydi.

> [!NOTE]
> **UPG mantığını somutlaştır**
> "User Private Group" demek, her kullanıcının **sadece kendisinin üye olduğu**,
> kendi adını taşıyan bir grubu olması demektir (`ali` kullanıcısının birincil
> grubu, başka kimsenin üye olmadığı `ali` adlı bir gruptur — `gelistirici` gibi
> paylaşılan bir grup değil). Bunun faydası umask ile ilgili: umask `002` iken
> yeni bir dosya `664` (`rw-rw-r--`) izniyle oluşur — grup da yazabilir. Eğer
> birincil grubun `users` gibi **herkesin üye olduğu** bir grup olsaydı, bu `664`
> demek "sistemdeki herkes bu dosyayı değiştirebilir" demek olurdu — tehlikeli.
> Ama UPG'de birincil grubun sadece sen olduğun için, `664` aslında pratikte "sadece
> ben yazabilirim" ile aynı anlama gelir (grup = sadece sen), `002` umask'ı güvenli
> hale gelir. Bu yüzden RHEL ve Debian'ın ikisi de varsayılan olarak UPG kullanır.

> ⚠️ **Grup değişikliği anında geçerli olmaz.** `usermod -aG docker ali` yaptıktan
> sonra `ali` mevcut oturumunda hâlâ eski gruptadır. Çıkıp girmesi gerekir.
> Test için: `newgrp docker` veya `su - ali`. `id` çıktısı ile `groups` çıktısı
> farklıysa sebep budur.

> [!NOTE]
> **Neden anında geçerli olmuyor, sistem otomatik güncelleyemez mi?**
> Bir kullanıcının hangi gruplarda olduğu bilgisi, o kullanıcı **giriş yaptığı anda**
> hesaplanıp o oturumun (session) bir parçası olarak "yapıştırılır" — kabuk süreci
> ve onun altında çalışan her şey, o hesaplanmış grup listesini taşır. `/etc/group`
> dosyasını sonradan değiştirmek, o dosyanın kendisini günceller ama **hâlâ açık
> olan** oturumların belleğindeki grup listesini geriye dönük güncellemez — çünkü
> sistem sürekli olarak her komutta dosyayı yeniden okumaz, performans için
> oturum başında bir kere okur. `newgrp yenigrup` çalıştırmak, o an için yeni bir
> alt kabuk açıp grup listesini yeniden hesaplattırır — geçici bir çözümdür,
> sadece o kabukta işe yarar. Kalıcı çözüm oturumu tamamen kapatıp (`exit` ya da
> tamamen çıkış) tekrar (`su -` veya yeniden SSH ile) girmektir; böylece yeni oturum
> baştan itibaren güncel grup listesiyle açılır.

---

## 6. Parola politikası

> [!NOTE]
> **Neden tek bir "parola" ayarı yetmiyor, bu kadar çok parametre neden var?**
> Bir kurumsal/kritik sistemde parola güvenliği tek bir kuralla ("parola en az 8
> karakter olsun") sınırlı kalamaz — parolanın ne kadar **karmaşık** olduğu (uzunluk,
> karakter çeşitliliği), ne kadar **sık** değişmesi gerektiği (eskimesi), ve
> değiştirildikten sonra kullanıcının onu **hemen tekrar eski parolasına
> döndürememesi** (minimum yaş) gibi birbirinden bağımsız birçok boyut vardır.
> Her boyut, farklı bir saldırı senaryosuna karşı korur: karmaşıklık kaba kuvvet
> saldırılarına karşı, düzenli değişim sızmış ama henüz kullanılmamış bir hash'in
> ömrünü sınırlamaya karşı, minimum yaş ise "parolamı değiştir, hemen eskisine geri
> dön" gibi kural atlatma girişimlerine karşı korur.

### `chage` — hesap bazlı yaşlandırma

```bash
sudo chage -l ali                      # mevcut politikayı listele
sudo chage -M 90 ali                   # 90 günde bir değiştirsin
sudo chage -m 7 ali                    # değiştirdikten sonra 7 gün geçmeden değiştiremesin
sudo chage -W 14 ali                   # 14 gün önceden uyar
sudo chage -E 2026-12-31 ali           # hesap bitiş tarihi
sudo chage -d 0 ali                    # ⭐ ilk girişte değiştirmeye zorla
sudo chage -I 30 ali                   # parola süresi dolduktan 30 gün sonra devre dışı
```

`chage`, doğrudan yukarıda gördüğün `/etc/shadow` satırındaki alanları düzenleyen
kullanıcı dostu bir araçtır — `chage -M 90 ali` demek, `/etc/shadow`'da `ali`
satırının "maksimum yaş" alanını elle hesaplayıp düzenlemek yerine bunu senin adına
yapar.

### Sistem geneli varsayılan — `/etc/login.defs`

```ini
PASS_MAX_DAYS   90
PASS_MIN_DAYS   7
PASS_WARN_AGE   14
```
> Bu değerler **sadece yeni açılan** kullanıcılara uygulanır. Mevcutlar için `chage` gerekir.

> [!NOTE]
> **Neden geriye dönük uygulanmıyor?**
> `/etc/login.defs`'teki bu değerler, `useradd` yeni bir kullanıcı oluştururken
> `/etc/shadow`'a **başlangıç değeri olarak yazılır** — yani sadece "bundan sonra
> açılacak hesaplar için varsayılan ne olsun" sorusuna cevap verir. Bir kez
> `/etc/shadow`'a yazıldıktan sonra, o kullanıcının satırı artık bağımsızdır;
> `/etc/login.defs`'i sonradan değiştirmek zaten var olan `/etc/shadow` satırlarını
> **geriye dönük güncellemez** (dosya sadece bir şablon, aktif olarak bağlı bir
> ayar kaynağı değil). Mevcut kullanıcıların politikasını değiştirmek istiyorsan,
> her biri için (ya da bir döngüyle hepsi için) `chage` çalıştırman gerekir.

### Parola karmaşıklığı (PAM)

> **Dağıtım farkı — burası aileler arasında ciddi ayrışır**

**RHEL 8/9, Rocky, Alma — `authselect` + `pwquality`**
```bash
sudo vi /etc/security/pwquality.conf
```
```ini
minlen = 12
dcredit = -1      # en az 1 rakam
ucredit = -1      # en az 1 büyük harf
lcredit = -1      # en az 1 küçük harf
ocredit = -1      # en az 1 özel karakter
difok = 5         # eskisinden en az 5 karakter farklı
retry = 3
```
RHEL'de PAM dosyalarını **elle düzenleme** — `authselect` ezer.
```bash
sudo authselect current
sudo authselect select sssd with-faillock --force
```

> [!NOTE]
> **`dcredit = -1` gibi negatif sayılar neden kafa karıştırıyor?**
> Bu `pwquality`'nin biraz alışılmadık bir sözdizimidir: pozitif bir sayı "bu
> kadar karaktere **kredi** ver" (yani parolanın minimum uzunluk gereksinimini o
> kadar azalt) anlamına gelirken, **negatif** bir sayı "bu türden **en az** bu
> kadar karakter **zorunlu** kıl" anlamına gelir. `dcredit = -1` demek "en az 1
> rakam zorunlu", `ucredit = -1` "en az 1 büyük harf zorunlu" demektir. `minlen = 12`
> ile birlikte kullanıldığında: parola en az 12 karakter olmalı VE en az 1 büyük
> harf, 1 küçük harf, 1 rakam, 1 özel karakter içermeli. `difok = 5` ise parola
> değiştirirken yeni parolanın eski paroladan en az 5 karakter farklı olmasını
> zorunlu kılar — "Parola123" → "Parola124" gibi kozmetik değişiklikleri engeller.
> `authselect` konusundaki uyarı önemlidir: RHEL 8+'ta PAM yapılandırma dosyaları
> artık elle düzenlenen dosyalar değil, `authselect` aracının **ürettiği** dosyalardır
> — elle düzenlersen, `authselect` bir sonraki çalıştığında (ya da `authselect apply-changes`
> çağrıldığında) o düzenlemeleri sessizce **ezer**, kaybolur. Doğru yol, `authselect`'in
> kendi profil sistemini kullanmaktır.

**Debian/Ubuntu — `libpam-pwquality`**
```bash
sudo apt install libpam-pwquality
sudo vi /etc/pam.d/common-password
```
```
password requisite pam_pwquality.so retry=3 minlen=12 difok=5
```

**Parola geçmişi (eskisini tekrar kullanmayı engelleme):**
```
# RHEL: /etc/pam.d/system-auth
password sufficient pam_unix.so ... remember=5
# Debian: /etc/pam.d/common-password
```

**Başarısız giriş denemesinde kilitleme:**
```bash
# RHEL 8+
sudo vi /etc/security/faillock.conf
#   deny = 5
#   unlock_time = 900
faillock --user ali            # durumu gör
faillock --user ali --reset    # kilidi aç

# Debian/Ubuntu: pam_faillock veya pam_tally2 (eski)
```

> [!NOTE]
> **Bu kilitleme neyi önlüyor?**
> `faillock`, art arda başarısız giriş denemelerini sayar ve belirlenen sayıya
> (`deny = 5`) ulaşınca hesabı geçici olarak kilitler (`unlock_time = 900` saniye,
> yani 15 dakika sonra otomatik açılır). Bu, bir saldırganın parolayı **kaba kuvvetle
> (brute-force)** — yani binlerce olası parolayı otomatik olarak deneyerek — kırmaya
> çalışmasına karşı bir savunmadır. Kilitleme olmasaydı, saldırgan saniyede
> binlerce deneme yapabilirdi; kilitleme her birkaç yanlış denemeden sonra zorunlu
> bir bekleme süresi getirerek bu saldırıyı pratik olarak imkansız hale getirir.

---

## 7. su ve sudo

> [!NOTE]
> **İkisi de "root ol" gibi görünüyor, neden ikisi de var?**
> `su` ve `sudo`, aynı amaca (yükseltilmiş yetkiyle işlem yapmak) çok farklı
> **güvenlik felsefeleriyle** ulaşır ve bu farkın anlaşılması modern sistem
> yönetiminin temel taşlarından biridir. `su` "kullanıcı değiştir" (switch user)
> demektir — hedef kullanıcının (genelde root'un) **kendi parolasını** bilmeni
> gerektirir ve bir kere geçtiğinde o kabuk tamamen root olarak kalır, ne
> yaptığının ayrıntılı bir kaydı tutulmaz. `sudo` ("superuser do") ise **kendi**
> parolanla, **tek bir komutu**, yönetici tarafından önceden izin verilmiş bir
> çerçevede çalıştırmanı sağlar ve her çağrı loglanır. Fark, "kurumsal bir ekipte
> root parolasını kaç kişi bilsin" sorusunda somutlaşır: `su` yöntemiyle herkesin
> root işi yapabilmesi için root parolasını **paylaşman** gerekir (kim ne yaptı
> bilinmez, parola değiştirmek herkesi etkiler); `sudo` yöntemiyle root parolası
> **hiç kimseyle paylaşılmaz**, her kişi kendi hesabıyla, sadece yetkilendirildiği
> komutları, izlenebilir şekilde çalıştırır. Bu yüzden modern sistemlerde root
> parolası genelde hiç kullanılmaz hatta bazı bulut imajlarında hiç ayarlanmaz —
> her şey `sudo` üzerinden yürür.

### `su` — kullanıcı değiştir

```bash
su                # root ol (root PAROLASI ile) — ortam korunur
su -              # root ol ve TAM ortamını yükle (login shell)  ← doğru olan
su - ali          # ali kullanıcısına geç
su -c "komut" ali # ali olarak tek komut çalıştır
```

`su` ile `su -` farkı önemli: tire olmadan `PATH`, `HOME`, `.bashrc` eski kullanıcınınki
kalır. `sbin` dizinleri PATH'te olmaz, `fdisk` "command not found" der. **Her zaman `su -`.**

> [!NOTE]
> **Bu neden oluyor — "ortam korunur" ne demek?**
> Bir kabuk süreci açıldığında, kendi `$PATH`, `$HOME`, `$USER` gibi çevresel
> değişkenlerini miras alır. `su` (tiresiz), sadece **kimliğini** (UID/GID) root'a
> çevirir ama seni çağıran kabuğun **çevresel değişkenlerini olduğu gibi bırakır** —
> yani teknik olarak root olmuşsundur ama `$HOME` hâlâ eski kullanıcının ev dizini,
> `$PATH` hâlâ eski kullanıcının PATH'idir (ki normal kullanıcıların PATH'inde
> genelde `/sbin`, `/usr/sbin` gibi yönetim araçlarının bulunduğu dizinler yoktur).
> Bunun sonucu: root olmana rağmen `fdisk` gibi `/sbin` altındaki bir komutu
> yazdığında kabuk onu PATH'inde bulamaz, "command not found" der — komut sistemde
> var, ama kabuk nerede arayacağını bilmiyor. `su -` ("login shell" olarak) ise
> tam bir **yeniden giriş** simüle eder: hedef kullanıcının (root'un) tüm başlangıç
> dosyaları (`/etc/profile`, `~/.bash_profile`) yeniden çalıştırılır, `$PATH`,
> `$HOME` ve diğer her şey **root'un kendi değerleriyle** baştan kurulur. Bu yüzden
> "gerçekten root gibi davranmak" istediğinde her zaman tire ile (`su -`) geçmen
> gerekir.

### `sudo` — yetkiyi devret

```bash
sudo komut               # tek komutu root olarak (KENDİ parolanla)
sudo -i                  # root login shell (su - gibi)
sudo -s                  # root shell, ortam korunur
sudo -u ali komut        # ali olarak çalıştır
sudo -l                  # benim hangi yetkilerim var
sudo -k                  # parola önbelleğini temizle
```

| | `su` | `sudo` |
|---|---|---|
| Hangi parola | Hedef kullanıcının | **Kendi** parolan |
| Log | Az | Her komut loglanır ⭐ |
| Yetki granülerliği | Ya hep ya hiç | Komut bazında |
| Root parolası paylaşımı | Gerekir ❌ | Gerekmez ✅ |

Modern uygulamada root parolası hiç dağıtılmaz; `sudo` kullanılır ve loglar
`/var/log/secure` (RHEL) veya `/var/log/auth.log` (Debian) altında tutulur.

### Sudo grubu

> **Dağıtım farkı:**
> - RHEL/Rocky/Alma/Fedora: **`wheel`** grubu
> - Debian/Ubuntu: **`sudo`** grubu
>
> ```bash
> sudo usermod -aG wheel ali    # RHEL ailesi
> sudo usermod -aG sudo  ali    # Debian ailesi
> ```

> [!NOTE]
> **Bu grup mekanizması arka planda nasıl çalışıyor?**
> `wheel` veya `sudo` grubunun kendisinin sistem için "büyülü" bir anlamı yoktur —
> Linux çekirdeği bu isimleri özel olarak tanımaz. Asıl büyü `/etc/sudoers`
> dosyasındadır: o dosyada `%wheel ALL=(ALL) ALL` (RHEL) veya `%sudo ALL=(ALL:ALL) ALL`
> (Debian) gibi bir satır **önceden yazılmıştır** — bu satır "wheel/sudo grubundaki
> herkes, her komutu, herhangi bir kullanıcı olarak çalıştırabilir" demektir. Sen
> bir kullanıcıyı bu gruba eklediğinde, aslında bu önceden tanımlı kurala dahil
> olmuş olursun. Yani `wheel`/`sudo` grubunun özel olması, kendi başına değil,
> `sudoers` dosyasındaki o satırla eşleştirilmiş olmasından gelir — istersen aynı
> yetkiyi başka isimli bir gruba da `sudoers`'a benzer bir satır yazarak verebilirsin
> (aşağıdaki `sudoers` örneklerinde bunu göreceksin).

### `sudoers` düzenleme — **her zaman `visudo`**

```bash
sudo visudo                            # ana dosya, sözdizimi kontrolü yapar
sudo visudo -f /etc/sudoers.d/ekip     # ayrı dosya ← tercih edilen yöntem
```

> ⚠️ `/etc/sudoers`'ı `vi` ile açıp bozarsan **sudo tamamen çalışmaz**, root'a da
> geçemezsin. `visudo` kaydetmeden önce sözdizimini denetler. İstisnası yok.

> [!NOTE]
> **`visudo` normal `vi`'dan farklı olarak ne yapıyor?**
> `visudo`, aslında `/etc/sudoers`'ı geçici bir kopya üzerinde düzenletir (senin
> tercih ettiğin editörle — `EDITOR` değişkenine göre `vi`, `nano` ne olursa) ve
> **sen kaydedip çıktığında**, gerçek dosyanın üzerine yazmadan önce sözdizimini
> `visudo -c` ile denetler. Hata varsa "bu dosyayı ayarlamayı düşünüyor musun,
> yoksa değişiklikleri iptal mi edeyim" diye sorar — hatalı bir dosyanın gerçek
> `/etc/sudoers`'ın üzerine yazılmasını **engeller**. Bunun neden bu kadar kritik
> olduğunu anlamak için düşün: `/etc/sudoers` bozulursa, `sudo` komutunun kendisi
> çalışmaz hale gelir (çünkü `sudo` her çalıştığında bu dosyayı okur ve sözdizimi
> hatalıysa güvenlik gereği hiçbir izin vermez) — ve sen zaten `sudo` çalışmadığı
> için root'a geçip dosyayı düzeltemezsin (root parolasını biliyorsan `su -` ile
> hâlâ kurtarabilirsin, ama modern sistemlerde çoğu zaman root parolası hiç
> ayarlı değildir). Bu yüzden `/etc/sudoers`'a asla düz `vi` veya `nano` ile
> dokunma — `visudo` istisnasız kuraldır.

Örnek kurallar:
```
# kullanıcı  host = (kim olarak)  komutlar
ali          ALL = (ALL)          ALL
%gelistirici ALL = (ALL)          /usr/bin/systemctl restart nginx
yedek        ALL = (root)  NOPASSWD: /usr/bin/rsync
%dba         ALL = (postgres)     ALL

# Komut takma adı ile
Cmnd_Alias SERVIS = /usr/bin/systemctl start *, /usr/bin/systemctl stop *
%operator ALL = SERVIS
```

> [!NOTE]
> **Bu satırların sözdizimini çöz**
> Genel kalıp: `KİM   NEREDE = (KİM_OLARAK)   NE_ÇALIŞTIRABİLİR`.
> - `ali ALL=(ALL) ALL` → `ali`, **herhangi bir** makinede (`ALL` — çünkü aynı
>   sudoers dosyası birden fazla makineye dağıtılabilir), **herhangi bir**
>   kullanıcı kimliğiyle (`(ALL)`), **herhangi bir** komutu çalıştırabilir. Bu
>   pratikte "ali tam yetkili sudo kullanıcısı" demektir.
> - `%gelistirici ALL=(ALL) /usr/bin/systemctl restart nginx` → başındaki `%`
>   bunun bir **kullanıcı değil grup** olduğunu belirtir. Bu grubun üyeleri
>   **sadece** `systemctl restart nginx` komutunu çalıştırabilir, başka hiçbir
>   şeyi root olarak yapamaz — komut bazlı kısıtlı yetki budur.
> - `yedek ALL=(root) NOPASSWD: /usr/bin/rsync` → `yedek` kullanıcısı `rsync`'i
>   root olarak, **parola sormadan** çalıştırabilir. Bu genelde otomasyon
>   hesapları için kullanılır (bir cron işi ya da betik, etkileşimli parola
>   giremeyeceği için `NOPASSWD` gereklidir) — ama bu ayrıcalık genişletilirse
>   riski de artar, bu yüzden mümkün olan en dar komutla sınırlanmalı.
> - `Cmnd_Alias SERVIS = ...` → tekrar eden komut listelerini bir isimle
>   tanımlamanı sağlar (programlamadaki değişken gibi düşün), böylece birden
>   fazla kuralda aynı listeyi tekrar tekrar yazmak yerine `SERVIS` adını
>   kullanırsın — okunabilirliği ve bakımı kolaylaştırır.

`%` işareti gruba işaret eder. `NOPASSWD:` parola sormaz (otomasyon için, dikkatli kullan).

**Güvenlik notu:** `ali ALL=(ALL) /usr/bin/vim` vermek, `ali`'ye root vermekle aynıdır —
Vim içinden `:!bash` çalıştırıp root kabuğu alır. Aynısı `less`, `find`, `awk`,
`tar --to-command` için de geçerli. Kısıtlı sudo verirken kabuk kaçışı olan komutlardan kaçın.

> [!WARNING]
> **Bu "kabuk kaçışı" (shell escape) tam olarak nasıl bir açık?**
> Birçok metin editörü, sayfalayıcı (pager) ve metin işleme aracı, kullanıcı
> deneyimini kolaylaştırmak için kendi içinden **harici bir komut çalıştırma**
> özelliğine sahiptir — Vim'de `:!komut`, less'te `!komut`, find'da `-exec` bunun
> örnekleridir. Bu özellik normal kullanımda zararsızdır (mesela Vim içindeyken
> dosyanın satır sayısını görmek için `:!wc -l %` yazmak faydalıdır). Ama bu aracı
> `sudo` ile (root olarak) çalıştırmasına izin verirsen, o araç içinden çalıştırılan
> **herhangi bir komut da root yetkisiyle** çalışır — çünkü çalıştırılan alt komut,
> onu başlatan Vim sürecinin (ki root olarak çalışıyor) yetkilerini miras alır.
> Yani `ali`'ye "sadece Vim'i root olarak çalıştırabilsin, güvenli olur" diye
> düşünüp izin verdiğinde, aslında `ali`'ye `:!bash` yazarak **tam bir root kabuğu**
> açma imkanı vermiş olursun — verdiğin "kısıtlı" yetki, aslında sınırsız yetkiyle
> aynı kapıya çıkar. Bu yüzden sudoers kuralları yazarken, izin verdiğin programın
> kendi içinden harici komut çalıştırma özelliği olup olmadığını **her zaman**
> kontrol etmen gerekir.

---

## 🧪 Lab

1. `proje` grubunu oluştur. `dev1` ve `dev2` kullanıcılarını ev dizinli, bash kabuklu,
   `proje` ek grubunda olacak şekilde aç.
2. Her ikisine `chage -d 0` uygula. `su - dev1` ile giriş yap, parola değiştirme
   dayatmasını gör.
3. `dev1`'i `wheel`/`sudo` grubuna **`-aG` ile** ekle. `sudo -l` ile doğrula.
4. `/etc/sudoers.d/proje` dosyası oluştur (`visudo -f` ile): `proje` grubu parolasız
   `systemctl restart sshd` çalıştırabilsin, başka bir şey yapamasın. Test et.
5. `dev2` için `chage` ile 60 günlük parola ömrü, 7 gün uyarı, `2026-12-31` bitiş tarihi ayarla. `chage -l` ile doğrula.
6. 5 kullanıcılık bir CSV hazırla, yukarıdaki döngü scriptiyle toplu oluştur.
   Üretilen parolaları dosyaya yaz, izinlerini `600` yap.
7. `dev2`'yi kilitle. `/etc/shadow` satırındaki değişikliği gör. SSH anahtarı ile hâlâ
   girilebileceğini not al, `usermod -e 1` ile tam kapat.
8. `usermod -G` (a'sız) hatasını **kasten** yap: `dev1`'i sadece `proje` grubuna ata,
   `wheel` grubundan düştüğünü `id` ile gör, sonra düzelt.

---

## ❓ Kendini test et

**S1.** `usermod -G docker ali` ile `usermod -aG docker ali` arasındaki fark ne, hangisi tehlikeli?

<details><summary>Cevap</summary>
`-a` olmadan mevcut tüm ek grupları **siler**, yerine sadece `docker` koyar.
Kullanıcı `wheel`/`sudo` grubundaysa sudo yetkisini kaybeder. Her zaman `-aG`.
</details>

**S2.** `usermod -L ali` yaptın ama ali hâlâ SSH ile girebiliyor. Neden?

<details><summary>Cevap</summary>
`-L` sadece **parola** ile girişi engeller (shadow'a `!` ekler). SSH açık anahtar
kimlik doğrulaması parolayı kullanmaz. Tam kapatmak için `usermod -e 1 ali` (hesap
süresini doldur) ve `~/.ssh/authorized_keys` içeriğini temizle.
</details>

**S3.** Sunucu Active Directory'ye bağlı. `cat /etc/passwd | grep ahmet` boş dönüyor ama `ahmet` giriş yapabiliyor. Nasıl kontrol edersin?

<details><summary>Cevap</summary>
`getent passwd ahmet` — NSS zincirinin tamamına (dosya + SSSD/LDAP/AD) sorar.
`/etc/passwd` sadece yerel hesapları içerir.
</details>

**S4.** `su` yerine neden `su -` kullanmalısın?

<details><summary>Cevap</summary>
`-` login shell açar: hedef kullanıcının `PATH`, `HOME`, profil dosyaları yüklenir.
Tiresiz kullanımda `/sbin` ve `/usr/sbin` PATH'te olmayabilir; `fdisk`, `ip` gibi
komutlar "command not found" verir.
</details>

**S5.** Bir kullanıcıya `sudo vim /etc/hosts` yetkisi verdin. Güvenlik açısından sorun var mı?

<details><summary>Cevap</summary>
Evet, tam root yetkisi vermiş oldun. Vim içinden `:!bash` ile root kabuğu alınabilir.
Aynı sorun `less`, `find -exec`, `awk`, `tar`, `git` için de geçerli.
Bunun yerine `sudoedit` / `sudo -e` kullanılmalı — dosyayı geçici kopyada düzenletir.
</details>

---

## 📋 Hızlı referans

```bash
id KULLANICI ; getent passwd KULLANICI
useradd -m -s /bin/bash -c "Ad" -G grup1,grup2 KULLANICI
usermod -aG GRUP KULLANICI      # -a UNUTMA
usermod -L / -U KULLANICI       # kilitle / aç
usermod -e 1 KULLANICI          # tam devre dışı (anahtar dahil)
userdel -r KULLANICI            # ev dizini ile sil
passwd KULLANICI ; chage -d 0 KULLANICI
chage -l / -M 90 / -W 14 / -E TARIH KULLANICI
groupadd / gpasswd -a / getent group
visudo ; visudo -f /etc/sudoers.d/DOSYA
sudo -l                         # yetkilerimi listele
# sudo grubu: RHEL → wheel   |   Debian/Ubuntu → sudo
```
