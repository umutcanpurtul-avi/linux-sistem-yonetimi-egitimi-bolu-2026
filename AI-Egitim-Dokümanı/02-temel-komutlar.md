---
tags: [linux, egitim, komutlar]
modul: 02
durum: tamamlandi
---

# 02 — Temel Komutlar

> **Ön koşul:** [01-sunucu-kurulumu](01-sunucu-kurulumu.md)
> **Süre:** ~3 saat

## Hedefler

- [ ] Bilmediğim bir komutun kullanımını yardım sisteminden kendim bulabiliyorum
- [ ] Dosya/dizin oluşturma, kopyalama, taşıma, silme işlemlerini akıcı yapıyorum
- [ ] Hard link ve soft link farkını anlatabiliyorum
- [ ] Metin dosyalarını okuma ve parçalama araçlarını kullanıyorum
- [ ] Sistem durumu hakkında hızlıca bilgi alabiliyorum

---

## 1. Yardım sistemi — en önemli bölüm

Linux öğrenmenin sırrı komut ezberlemek değil, **yardımı okuyabilmektir.** Hiçbir
sistem yöneticisi yüzlerce komutun tüm bayraklarını (flag) ezbere bilmez — bildiği,
"nereye bakarsam bulurum" refleksidir. Bu bölüm, komut ezberlemek yerine bu refleksi
kazandırmayı hedefler.

```bash
man ls              # Kılavuz sayfası. q ile çık, / ile ara, n sonraki
man 5 passwd        # 5. bölüm: dosya biçimi (komut değil!)
man -k parola       # Anahtar kelimeyle ara (= apropos)
apropos network     # Aynı şey
whatis ls           # Tek satırlık özet
info coreutils      # GNU'nun uzun formatlı dokümanı
ls --help           # Çoğu komutta en hızlı yol
```

**Bu dört yol arasındaki fark ne, hangisini ne zaman kullanırsın?**
- `man` — bir komutu (veya dosya biçimini) **zaten adını biliyorsan** ayrıntılı
  kılavuzunu okumak için. En yaygın kullanılan, ilk başvurulacak yer.
- `man -k` / `apropos` — bir konuyu biliyorsun ama **hangi komutun** o işi yaptığını
  bilmiyorsun. Örneğin "parola değiştirmek için hangi komutlar var" diye arama yapmak
  istediğinde `man -k parola` sana ilgili tüm man sayfalarının başlıklarını listeler.
- `whatis` — komutun adını biliyorsun, sadece "bu ne işe yarıyordu" diye tek satırlık
  hatırlatma istiyorsun; `man`'ın uzun metnini okumaya gerek yok.
- `info` — GNU araçları (özellikle coreutils, bash, gcc, emacs) için `man`'dan daha
  ayrıntılı, konular arası bağlantılı (hiper-metin gibi) bir belgeleme sistemidir.
  `man`'da bulamadığın ayrıntı genelde `info`'da vardır.
- `komut --help` — çoğu GNU/Linux komutunun kendi içinde taşıdığı, sadece o komutun
  kullanılabilir bayraklarını listeleyen kısa özet; internet yokken veya hızlıca bir
  bayrağı hatırlamak istediğinde en az efor isteyen yol.

### man bölümleri (numaraların anlamı)

`man` kılavuzu tek bir büyük kitap değildir — konuya göre **bölümlere (section)**
ayrılmıştır. Aynı kelime (`passwd` gibi) hem bir komut hem bir dosya biçimi olabilir;
bölüm numarası hangisini istediğini belirtir.

| Bölüm | İçerik | Örnek |
|---|---|---|
| 1 | Kullanıcı komutları | `man 1 passwd` → passwd komutu |
| 5 | Dosya biçimleri | `man 5 passwd` → /etc/passwd dosyasının yapısı |
| 8 | Sistem yönetimi komutları | `man 8 useradd` |

`man passwd` sana varsayılan olarak **en düşük numaralı** bölümü (genelde 1'i) verir.
Dosya yapısını arıyorsan `man 5 passwd` demen gerekir — aksi halde "passwd komutu nasıl
kullanılır" sayfasını okur, `/etc/passwd` dosyasının sütunlarını hiç göremezsin. Bu
ayrımı bilmeyen çok kişi var — bilmek, aradığını bulma süreni ciddi kısaltır.

### Komut nerede?

```bash
which ls        # PATH içinde çalıştırılabilir dosyanın yolu
whereis ls      # Binary + kaynak + man sayfası konumları
type ls         # ← En doğrusu: alias mı, builtin mi, dosya mı?
type cd         # "cd is a shell builtin" — cd'nin dosyası yoktur!
```

Bir komut yazdığında kabuk (shell), o ismi çalıştırmak için birkaç yerde arama yapar:
önce kendi tanımladığın **alias**'lara (kısayollara) bakar, sonra kabuğun kendi içine
gömülü **builtin** komutlara (`cd`, `echo`, `export` gibi — bunlar diskte ayrı birer
dosya değildir, kabuğun kendisinin bir parçasıdır), sonra da `$PATH` değişkeninde
listeli dizinlerdeki **gerçek dosyalara** (`/usr/bin/ls` gibi) bakar. `which` ve
`whereis` sadece son kategoriyi (disk üzerindeki dosyaları) görebilir; alias ve
builtin'leri göremez, bu yüzden yanıltıcı olabilirler.

> `which cd` boş döner çünkü `cd` bir kabuk builtin'idir, disk üzerinde dosyası yok.
> `type` bunu doğru söyler — hangi kategoriden olduğunu (alias/builtin/dosya) açıkça
> belirtir. Refleksin `type` olsun.

> **Dağıtım farkı:** Minimal kurulumlarda `man` sayfaları kurulu gelmeyebilir.
> RHEL: `dnf install man-pages man-db`, Debian: `apt install man-db manpages`.
> Ayrıca Debian/Ubuntu'da `/etc/dpkg/dpkg.cfg.d/excludes` man sayfalarını konteynerlerde eler.

---

## 2. Gezinme ve dosya işlemleri

**Neden bu bölüm önemli?** Bir işletim sistemi, temelde bir ağaç yapısındaki
dizinler/dosyalar üzerinde çalışır. Bu ağaçta gezinmeyi ve temel dosya işlemlerini
(oluşturma, kopyalama, taşıma, silme) hızlı yapamıyorsan, her şey diğer araçlardan
önce burada tıkanır.

```bash
pwd                    # Neredeyim
cd /var/log            # Mutlak yol
cd ../..               # İki üst dizin
cd ~                   # Ev dizini (= cd, tek başına)
cd -                   # Bir önceki dizine dön ← çok işe yarar
```
`pwd` ("print working directory") her zaman bir **mutlak yol** (kökten `/` başlayan
tam yol) döndürür — nerede olursan ol, tam konumunu söyler. `cd` iki tür yol kabul
eder: **mutlak** (`/var/log` gibi, hep `/`'den başlar, bulunduğun yerden bağımsız
çalışır) ve **bağıl/göreli (relative)** (`../..` gibi, bulunduğun yere göre yorumlanır
— `..` bir üst dizin demektir). `cd -` kabuğun `$OLDPWD` değişkeninde tuttuğu bir
önceki dizini hatırlar; iki dizin arasında sık gidip geliyorsan tam yolu tekrar
yazmaktan seni kurtarır.

```bash
ls                     # Listele
ls -l                  # Uzun format (izin, sahip, boyut, tarih)
ls -la                 # Gizli dosyalar dahil (nokta ile başlayanlar)
ls -lh                 # İnsan okunur boyut (1.5G yerine 1610612736 değil)
ls -lt                 # Tarihe göre sırala (en yeni üstte)
ls -ltr                # Tersine — en yeni EN ALTTA. Log dizininde altın değerinde
ls -ld /var/log        # Dizinin KENDİSİ hakkında bilgi, içeriği değil
```
`ls -ld` özellikle karıştırılır: `ls -l /var/log` o dizinin **içindeki** dosyaları
uzun formatta listeler; `ls -ld /var/log` ise `/var/log`'un **kendisinin** (bir dizin
olarak) izinlerini, sahibini, değişim tarihini gösterir — `-d` (directory) bayrağı
"içine girme, kendisine bak" demektir.

`ls -l` çıktısını okumak:

```
-rw-r--r--. 1 root root  1024 Aug 20 14:32 dosya.txt
│└┬┘└┬┘└┬┘  │ │    │      │    │            │
│ │  │  │   │ │    │      │    │            └─ isim
│ │  │  │   │ │    │      │    └─ değişim zamanı
│ │  │  │   │ │    │      └─ boyut (bayt)
│ │  │  │   │ │    └─ grup
│ │  │  │   │ └─ sahip
│ │  │  │   └─ hard link sayısı
│ │  │  └─ diğerleri (other) izinleri
│ │  └─ grup izinleri
│ └─ sahip izinleri
└─ dosya tipi (- normal, d dizin, l link, b blok, c karakter)
```

Sütun sütun açalım:
- **Dosya tipi (1. karakter):** `-` normal dosya (metin, program, resim — sıradan
  içerik), `d` dizin (klasör), `l` sembolik link (başka bir dosyaya işaret eden
  kısayol), `b`/`c` aygıt dosyaları (disk, terminal gibi donanıma erişim noktaları),
  `s` soket, `p` named pipe.
- **İzin üçlüsü (2-10. karakterler):** Her biri `rwx` sırasıyla okuma/yazma/çalıştırma
  hakkı anlamına gelir, sırasıyla **sahip**, **grup**, **diğerleri** için tekrarlanır.
  Yukarıdaki örnekte sahip `rw-` (okur, yazar, çalıştıramaz), grup ve diğerleri sadece
  `r--` (sadece okuyabilir).
- **Hard link sayısı:** Dosyalarda genelde `1`dir (kaç farklı isim aynı veriye işaret
  ediyor). Dizinlerde en az `2`dir çünkü dizinin kendisi (`.`) ve içindeki her alt
  dizinin üst dizine işaret eden `..`'si bu sayıyı artırır — bu konuyu Bölüm 3'te
  (Bağlantılar) derinlemesine işleyeceğiz.
- **Sahip / grup:** Dosyayı kimin/hangi grubun sahiplendiğini gösterir; izin
  kontrolünde bu isimler kullanılır (Modül 05'te ayrıntılı).
- **Boyut:** Bayt cinsindendir, `-h` bayrağıyla insan okunur (K/M/G) hale gelir.
- **Değişim zamanı:** Dosya içeriğinin **son değiştirilme** zamanıdır (oluşturma
  zamanı değil — Linux dosya sistemlerinin çoğu "oluşturma zamanı"nı standart olarak
  saklamaz, `stat` komutuyla farklı zaman damgalarına bakılabilir).

### Oluştur / kopyala / taşı / sil

```bash
touch dosya.txt              # Boş dosya oluştur (veya zaman damgasını güncelle)
mkdir dizin                  # Dizin
mkdir -p a/b/c/d             # Ara dizinleri de oluştur ← -p'yi hep kullan
```
`mkdir a/b/c/d` eğer `a` ve `a/b` zaten yoksa **hata verir** — `mkdir` varsayılan
olarak sadece tek bir seviye dizin oluşturur, ara dizinlerin zaten var olduğunu
varsayar. `-p` (parents) bayrağı "gerekiyorsa aradaki tüm dizinleri de sen oluştur"
der; bu yüzden pratikte neredeyse her zaman `-p` ile kullanılır.

```bash
cp kaynak hedef              # Kopyala
cp -r dizin/ hedef/          # Dizin kopyalarken -r şart
cp -a dizin/ hedef/          # Arşiv modu: izin+sahip+zaman korunur ← yedeklemede bunu kullan
cp -i kaynak hedef           # Üzerine yazmadan önce sor
cp dosya.conf dosya.conf.bak # Değiştirmeden önce YEDEK AL. Kas hafızası yap.
```
`cp` varsayılan olarak sadece **düz dosyaları** kopyalar; bir dizin verirsen "omitting
directory" hatası alırsın çünkü dizin kopyalamak, içindeki her şeyi tek tek kopyalamayı
gerektirir — `-r` (recursive) bayrağı bunu açıkça ister. `-a` (archive), `-r`'nin
üstüne izinleri, sahiplik bilgisini ve zaman damgalarını da koruyarak kopyalar — normal
`cp -r` ile kopyaladığında yeni dosyaların sahibi/zamanı **senin şu anki
kullanıcın/şu an** olur, orijinal bilgiler kaybolur; `-a` bunu önler, bu yüzden
yedeklemede tercih edilir.

```bash
mv eski yeni                 # Taşı VEYA yeniden adlandır (aynı komut)
mv *.log /var/log/eski/      # Toplu taşıma
```
`mv` aslında tek bir işlemdir: hedefin aynı dosya sisteminde olup olmamasına göre ya
sadece bir dizin girdisini günceller (çok hızlı, veriyi hiç taşımaz — bu yüzden
"yeniden adlandırma" da `mv` ile yapılır) ya da farklı bir dosya sistemine taşıyorsan
önce kopyalar sonra orijinali siler (daha yavaş, çünkü gerçek veri fiziksel olarak
taşınır).

```bash
rm dosya                     # Sil
rm -r dizin                  # Dizini içeriğiyle sil
rm -f dosya                  # Sormadan zorla
rmdir bosdizin               # Sadece BOŞ dizini siler — güvenli seçenek
```
`rm` (ve Linux'ta genel olarak silme işlemi) **çöp kutusuna atmaz** — GUI dosya
yöneticilerinin aksine, komut satırında sildiğin bir dosya doğrudan ve geri dönüşsüz
kaybolur (kurtarma, karmaşık disk-adli-tıp araçlarıyla bile garanti değildir). `rmdir`
bilinçli olarak sadece **boş** dizinleri siler — dolu bir dizini `rmdir` ile silmeye
çalışırsan hata alırsın; bu, "yanlışlıkla dolu bir dizini sildim" riskine karşı bir
güvenlik freni gibi düşünülebilir.

> ⚠️ `rm -rf /` ve `rm -rf $DEGISKEN/` — değişken boşsa `rm -rf /` olur.
> Script yazarken **her zaman** `rm -rf "${DIZIN:?DIZIN tanımsız}"/` kullan;
> değişken boşsa komut hata verip durur. **Neden bu kadar tehlikeli?** `$DEGISKEN`
> boşsa `rm -rf $DEGISKEN/` komutu gerçekte `rm -rf /` haline gelir — yani kök dizinden
> başlayarak **tüm dosya sistemini** siler. `-f` (force) bayrağı hiçbir onay sormadan
> çalışır. Modern `rm` sürümleri `/`'yi doğrudan hedeflemeyi reddeder ama değişken içinde
> gizliyse (`$DEGISKEN/` gibi) bu koruma devreye girmeyebilir — bu yüzden scriptte
> değişkenin boş olmadığını garanti altına almak (`:?` sözdizimi) hayati önemdedir.

### cp -r vs cp -a — sondaki `/` meselesi

```bash
cp -r kaynak  hedef/    # hedef/kaynak/ oluşur
cp -r kaynak/ hedef/    # kaynak'ın İÇİ hedef/'e kopyalanır
```
**Neden fark var?** `cp`, kaynak yolunun sonunda `/` olup olmamasına bakarak "bu ismin
kendisini mi, yoksa içeriğini mi kastediyorsun" ayrımını yapar. `kaynak` (sonunda `/`
yok) dizinin **kendisini** bir birim olarak ele alır — hedefin içine `kaynak` adında
yeni bir dizin oluşturup içine kopyalar. `kaynak/` (sonunda `/` var) ise "bu dizinin
içindekiler" anlamına gelir — kaynak dizinin kendisi değil, **içeriği** doğrudan
hedefe kopyalanır. Aynı incelik `rsync`'te de var (Modül 09). Yanlış yerde `/` koymak,
yanlış yere terabaytlarca veri kopyalatabilir ya da beklenmedik iç içe dizinler
(`hedef/kaynak/kaynak/...`) oluşturabilir.

---

## 3. Bağlantılar (link)

**Link nedir, neden var?** Normalde bir dosyaya tek bir isimle, tek bir yoldan
erişirsin. Bazen aynı veriye **birden fazla isimle** veya birden fazla **konumdan**
erişmek istersin — dosyayı fiziksel olarak kopyalamadan (yer kaplamadan, iki ayrı
kopya senkron kalmadan). Link, tam olarak bunu çözer: aynı veriye işaret eden ek bir
"yol" yaratır.

```bash
ln    hedef  linkadi     # Hard link
ln -s hedef  linkadi     # Symbolic (soft) link
```

Bir dosyanın gerçek içeriği diskte bir **inode** (dosyanın meta verisini — boyut,
izin, veri bloklarının konumu — tutan bir kayıt) ile temsil edilir. Dosya adı ise
sadece bir dizinin içinde "bu isim şu inode'a işaret eder" diyen bir kayıttır.
- **Hard link**, doğrudan aynı **inode**'a işaret eden yeni bir isim yaratır — orijinal
  dosya ile hard link, aynı verinin iki farklı ismidir, aralarında "asıl" ve "kopya"
  ayrımı yoktur, ikisi de eşit derecede gerçektir.
- **Soft link (symlink)**, ayrı bir küçük dosyadır; içinde sadece hedef dosyanın
  **yolunu (metin olarak)** tutar — Windows'taki kısayola benzer. Hedefe "işaret eder"
  ama kendisi ayrı bir inode'dur.

| | Hard link | Soft link (symlink) |
|---|---|---|
| Neyi işaret eder | **inode**'u (verinin kendisi) | dosya **yolunu** (metin) |
| Orijinal silinirse | Veri durur, link çalışır | Link kırılır (dangling) |
| Farklı dosya sistemi | ❌ Olmaz | ✅ Olur |
| Dizine link | ❌ Olmaz | ✅ Olur |
| `ls -l` görünümü | normal dosya gibi | `linkadi -> hedef` |

**Neden bu farklar var?** Hard link doğrudan inode numarasına bağlıdır; inode
numaraları her dosya sistemi içinde ayrı ayrı sayılır, bu yüzden hard link farklı bir
disk/bölüme (farklı dosya sistemine) kurulamaz — "bu inode numarası" ifadesi başka bir
dosya sisteminde anlamsızdır. Soft link ise sadece bir metin yolu tuttuğu için dosya
sistemi sınırını umursamaz, hatta var olmayan bir hedefe bile işaret edebilir (kırık/
dangling link). Orijinal dosya silindiğinde: hard link'te veri hâlâ diskte durur çünkü
inode, ona işaret eden **en az bir isim** kaldığı sürece silinmez (silme aslında "bu
isimle olan bağı kopar" demektir, inode'un son bağı koptuğunda gerçek veri silinir) —
bu yüzden hard link "orijinal"i hayatta tutar. Soft link'te ise link, artık var olmayan
bir yola işaret ettiği için kırılır (dangling).

```bash
echo "veri" > orijinal.txt
ln orijinal.txt hard.txt
ln -s orijinal.txt soft.txt
ls -li                       # -i inode numarasını gösterir

rm orijinal.txt
cat hard.txt                 # "veri" — hâlâ çalışır
cat soft.txt                 # No such file or directory — kırıldı
```

Sahada nerede görürsün: `/etc/alternatives/` (java sürümü seçimi — birden fazla java
sürümü kurulu olabilir, symlink hangisinin "aktif" olduğunu belirler),
`/etc/nginx/sites-enabled/` (sites-available'a symlink — bir siteyi etkinleştirmek/
devre dışı bırakmak, dosyayı silmeden sadece symlink eklemek/kaldırmakla yapılır),
`/usr/bin/python3` → `python3.11` (sistemdeki "python3" komutunun aslında hangi
sürüme işaret ettiğini symlink belirler).

---

## 4. Dosya okuma ve metin araçları

```bash
cat dosya                # Tümünü bas
cat -n dosya             # Satır numaralı
tac dosya                # Ters sırayla (satır satır) — cat'in tersi
rev dosya                # Her satırı karakter bazında ters çevir

less dosya               # Sayfa sayfa oku (q çık, / ara, G son, g baş, F takip modu)
more dosya               # less'in ilkel atası. less kullan.
```
`cat` tüm dosyayı **anında** terminale döker — küçük dosyalar için idealdir ama
büyük bir log dosyasında (milyonlarca satır) ekranı doldurur, geçmişe kaydıramazsın.
`less` bunun yerine dosyayı **sayfalar halinde**, tembel yükleme (lazy loading) ile
gösterir — dosyanın tamamını belleğe okumaz, sadece gördüğün kısmı okur, bu yüzden
devasa dosyalarda bile anında açılır. `more` `less`'in tarihsel atasıdır ve geriye
kaydırma gibi temel özellikleri eksiktir; `less`'in adı da "less is more" (Unix
esprisi) ifadesinden gelir, `more`'un yapamadığını yapar.

```bash
head dosya                # İlk 10 satır
head -n 20 dosya          # İlk 20
tail dosya                # Son 10 satır
tail -n 50 dosya          # Son 50
tail -f /var/log/messages  # ← CANLI TAKİP. Sistem yöneticisinin en çok kullandığı komut
tail -F dosya              # Dosya döndürülse (logrotate) bile takibe devam et
```
`tail -f` (follow), dosyanın sonuna **yeni eklenen** satırları anlık olarak ekrana
basmaya devam eder — dosyayı kapatmaz, sürekli izler. Bir uygulamayı çalıştırıp aynı
anda log dosyasının canlı aktığını görmek istediğinde (hata ayıklama sırasında en çok
kullanılan yöntemlerden biridir) budur. `-F` (büyük harf), `logrotate` gibi bir araç
log dosyasını döndürüp (eskisini `.1` yapıp) yeni bir dosya açtığında bile eski
dosyayı değil **yeni dosyayı** takip etmeye devam eder — küçük `-f` bu durumda eski
(artık büyümeyen) dosyayı izlemeye devam eder, sessizce "kör" kalır.

> `less` içinde `Shift+F` = `tail -f` davranışı, `Ctrl+C` ile geri dön. Tek araçta ikisi.

### Sütun ve satır işleme

```bash
cut -d: -f1 /etc/passwd        # : ile ayır, 1. alanı al → kullanıcı adları
cut -d: -f1,7 /etc/passwd      # 1. ve 7. alan
cut -c1-10 dosya               # Karakter 1-10 arası
```
`cut`, bir satırı belirttiğin ayraca (`-d`, delimiter) göre sütunlara böler ve
istediğin sütun numaralarını (`-f`, field) seçer. `/etc/passwd` dosyasının her satırı
`:` ile ayrılmış 7 alan içerir (kullanıcı adı, parola yer tutucu, UID, GID, açıklama,
ev dizini, kabuk) — bu yüzden `cut -d: -f1` dosyadaki tüm kullanıcı adlarını tek
sütun halinde çıkarır.

```bash
sort dosya                     # Alfabetik sırala
sort -n dosya                  # Sayısal sırala (10, 2, 1 değil 1, 2, 10)
sort -k3 -n -t: /etc/passwd    # : ayraçlı, 3. alana göre sayısal → UID sırası
sort -r dosya                  # Ters
```
**Neden `-n` gerekiyor, `sort` sayıları neden yanlış sıralar?** Varsayılan `sort`,
satırları **metin (string) olarak, karakter karakter** karşılaştırır — "10" ile "2"yi
karşılaştırırken ilk karaktere bakar (`1` < `2`), bu yüzden "10" "2"den önce gelir
(alfabetik olarak doğru ama sayısal olarak yanlış). `-n` bayrağı sıralamayı
**sayısal değer** olarak yapmasını söyler, o zaman `1, 2, 10` doğru sırayla çıkar.

```bash
uniq dosya                     # ARDIŞIK tekrarları sil ← önce sort şart!
sort dosya | uniq              # Doğru kullanım
sort dosya | uniq -c           # Kaç kere tekrarlandığını say
sort dosya | uniq -d           # Sadece tekrar edenleri göster
```
`uniq`'in kritik bir sınırlaması var: sadece **birbirine bitişik (ardışık)** aynı
satırları tek satıra indirir. Dosyada "elma" satırı 1. ve 50. satırlarda ayrı ayrı
geçiyorsa (arada başka satırlar varsa), `uniq` bunları **tekrar olarak görmez** çünkü
yan yana değiller. Bu yüzden `uniq`'ten önce **her zaman** `sort` çalıştırılır —
sıralama, aynı değerleri birbirine bitiştirir, ancak o zaman `uniq` doğru çalışır.

```bash
wc -l dosya                    # Satır sayısı
wc -w dosya                    # Kelime sayısı

paste a.txt b.txt              # İki dosyayı yan yana birleştir (sütun)
join a.txt b.txt               # Ortak alana göre birleştir (SQL JOIN gibi)
split -l 1000 buyuk.log parca_ # 1000'er satırlık parçalara böl
```

### diff — iki dosyayı karşılaştırma

```bash
diff eski.conf yeni.conf         # varsayılan format
diff -u eski.conf yeni.conf      # "unified" format — patch/git'in kullandığı standart
diff -r dizin1/ dizin2/          # iki dizini özyinelemeli karşılaştır
diff -q dizin1/ dizin2/          # sadece HANGİ dosyaların farklı olduğunu söyle
```
`diff`'in varsayılan çıktısında `<` ile başlayan satır **sadece ilk dosyada**,
`>` ile başlayan satır **sadece ikinci dosyada** vardır. `-u` (unified) bunun
yerine değişen satırların **etrafındaki birkaç bağlam satırıyla birlikte**,
silinenleri `-`, eklenenleri `+` ile gösteren, çok daha okunaklı bir format
üretir — `git diff` ve `patch` komutunun beklediği format tam olarak budur.
Çıktı **hiç basılmadan** çıkarsa (çıkış kodu `0`) iki dosya birebir aynıdır;
bu bir betikte kontrol amaçlı kullanılabilir: `diff -q a b >/dev/null && echo aynı`.

### xxd — ikilik veriyi onaltılık (hex) döküm olarak görmek

```bash
xxd dosya                  # her baytı hex + yanında ASCII karşılığıyla göster
xxd -p dosya                # "plain" — sadece art arda hex çiftleri, adres/ASCII sütunu yok
echo -n "A" | xxd           # 00000000: 41   ← 'A' harfinin ASCII kodu, hex olarak
xxd -r -p sifreli.hex        # -r (reverse) + -p: hex metni GERİ, ham baytlara çevir
```
Bir dosyayı `cat` ile açtığında terminal, baytları **karakter kodlama tablosuna**
(ASCII/UTF-8) göre insan-okunur harflere çevirip gösterir — ama ikili (binary)
bir dosyada (bir resim, bir derlenmiş program) bu baytların çoğu yazdırılabilir
bir karaktere karşılık gelmez, terminalde anlamsız/bozuk semboller çıkar. `xxd`,
her baytı olduğu gibi, **onaltılık (hex) tabanda** iki karakterle (`0x00`-`0xFF`)
gösterir — 2 hex hanesi tam olarak 1 bayta karşılık geldiği için bu, ham veriyi
kaybetmeden okunabilir kılmanın en kompakt yoludur. `-p` (plain) adres ve ASCII
sütunlarını atıp sadece art arda hex çiftlerini basar — bu format `-r` (reverse)
ile geri okunabilir, yani `xxd -p` ile ürettiğin bir hex metni `xxd -r -p` ile
tekrar orijinal baytlara çevrilebilir; iki komut birbirinin tam tersidir.

**Klasik kombinasyon** — en çok yer kaplayan 5 log dosyası:
```bash
du -a /var/log | sort -rn | head -5
```
Burada `|` (pipe), her komutun çıktısını bir sonrakinin girdisine bağlar: `du -a`
her dosyanın boyutunu satır satır listeler → `sort -rn` bu satırları **sayısal**
(`-n`) ve **ters** (`-r`, büyükten küçüğe) sıralar → `head -5` sadece ilk 5 satırı
gösterir. Her komut kendi başına basit bir iş yapar; boru hattı (pipeline) onları
zincirleyerek karmaşık bir sonuç üretir — bu, Unix felsefesinin özüdür.

**Klasik kombinasyon** — bir log'da en çok geçen 10 IP:
```bash
awk '{print $1}' access.log | sort | uniq -c | sort -rn | head -10
```
Akış: `awk '{print $1}'` her satırın **ilk sütununu** (genelde log formatında IP
adresi orada olur) alır → `sort` aynı IP'leri yan yana getirir → `uniq -c` her IP'nin
kaç kez geçtiğini sayar → `sort -rn` en çok geçenden aza doğru sıralar → `head -10`
ilk 10'u gösterir.

---

## 5. Arama

```bash
locate dosya.conf        # Veritabanından ara — ÇOK hızlı ama güncel olmayabilir
sudo updatedb            # Veritabanını güncelle
```
`locate` diskte gerçek zamanlı tarama yapmaz — periyodik olarak (genelde günde bir
kez, cron ile) oluşturulan bir **indeks veritabanına** bakar, bu yüzden ışık hızında
sonuç verir. Ama bu hız bir bedel getirir: son birkaç dakikada oluşturduğun bir dosya,
veritabanı henüz güncellenmediyse `locate` ile bulunamaz — `sudo updatedb` ile elle
tazeleyebilirsin.

```bash
find /etc -name "*.conf"                 # İsme göre
find / -name "sshd_config" 2>/dev/null   # Hataları gizle
find /var -size +100M                    # 100 MB'tan büyük
find /home -mtime -7                     # Son 7 günde değişmiş
find /tmp -type f -mtime +30 -delete     # 30 günden eski dosyaları sil
find / -perm -4000 2>/dev/null           # SUID bitli dosyalar (güvenlik denetimi)
find /var/log -name "*.log" -exec gzip {} \;   # Bulup her birine komut çalıştır
```
`find`, `locate`'ün aksine diski **o an, gerçek zamanlı** tarar — bu yüzden daha
yavaştır ama her zaman günceldir ve çok daha zengin filtreler (boyut, tarih, izin,
tip) destekler. `2>/dev/null` sık görülür çünkü `find /` gibi tüm sistemi tarayan
komutlar, erişim izni olmayan dizinlerde ("Permission denied") sürekli hata
basar — bu hataları (stderr, kanal `2`) `/dev/null`'a (hiçbir şeyin gitmediği, "veri
çöplüğü" özel aygıt dosyası) yönlendirmek, sadece gerçek sonuçları (stdout) ekranda
bırakır. `-exec ... \;` bulunan her dosya için ayrı ayrı bir komut çalıştırır — `{}`
o an bulunan dosyanın adıyla değişir.

> **Dağıtım farkı:** `locate` artık varsayılan gelmiyor.
> RHEL 9: `dnf install mlocate` (veya `plocate`), Debian 12: `apt install plocate`.
> `plocate` daha hızlı ve modern; komut adı yine `locate`.

`grep` ile içerik arama:
```bash
grep "hata" dosya.log            # Satır içinde ara
grep -i "hata" dosya.log         # Büyük/küçük harf duyarsız
grep -r "SearchMe" /etc/         # Dizin içinde özyinelemeli
grep -v "INFO" app.log           # INFO İÇERMEYEN satırlar ← çok kullanışlı
grep -n "hata" dosya             # Satır numarasıyla
grep -c "hata" dosya             # Sadece adet
grep -A3 -B3 "hata" dosya        # Eşleşmenin 3 satır öncesi ve sonrası
```
`find` dosya **isimlerinde**, `grep` ise dosya **içeriğinde** arama yapar — ikisi
birbirini tamamlar. `-v` (invert) özellikle kullanışlıdır: bir log dosyasında binlerce
"normal" (INFO seviyeli) satır arasından sadece "anormal" olanları görmek istediğinde,
"INFO içermeyenleri göster" demek, "hata/uyarı içerenleri filtrelemekten" çoğu zaman
daha pratiktir. `grep` detayı Modül 06'da (düzenli ifadelerle birlikte).

---

## 6. İzin ve sahiplik (giriş)

```bash
chmod 644 dosya          # rw-r--r--
chmod +x script.sh       # Çalıştırma izni ekle
chown ali:gelistirici dosya   # Sahip ve grubu değiştir
umask                    # Yeni dosyaların varsayılan izin maskesi
chattr +i dosya          # Değiştirilemez yap (root bile silemez!)
lsattr dosya             # Öznitelikleri gör
chattr -i dosya          # Geri al
```
`chmod` (change mode) sahip/grup/diğerleri izinlerini değiştirir; `644` gibi üç
haneli sayı, her hanenin `r=4, w=2, x=1` değerlerinin toplamı olduğu bir kısayoldur
(6 = rw, 4 = r). `chown` (change owner) dosyanın **kime ait olduğunu** değiştirir —
bu, izinlerden ayrı bir kavramdır: izinler "ne yapılabilir" der, sahiplik "kimin
hesabına yapılabilir" belirler. `chattr +i` ise klasik izin sisteminin bile
üstündedir — dosyayı **immutable (değiştirilemez)** yapar; root bile bu bayrak
kaldırılmadan dosyayı silemez/değiştiremez, çünkü bu kısıtlama dosya sistemi
seviyesinde, izin kontrolünden önce devreye girer. Ayrıntısı Modül 04 ve 05'te.
`chattr +i` kritik dosyaları (ör. `/etc/resolv.conf`'un bir servis tarafından
üzerine yazılmasını engellemek) korumak için sahada işe yarar ama unuttuğunda
saatlerini yer — "silinmiyor, izin var ama silinmiyor" durumunda `lsattr` bak.

---

## 7. Sistem bilgisi ve durum

```bash
uname -a                 # Kernel, mimari, hostname — hepsi
df -h                    # Disk doluluk (insan okunur)
df -i                    # inode doluluk ← disk boş görünüp "no space left" alırsan buraya bak
du -sh /var/log          # Bir dizinin toplam boyutu
du -sh * | sort -rh      # Bulunduğun dizindeki en büyükler
```
`df` (disk free) dosya sistemi seviyesinde **ne kadar alan** kaldığını gösterir; `du`
(disk usage) belirli bir dizinin **ne kadar yer kapladığını** hesaplar. İkisi farklı
sorulara cevap verir: "diskte genel olarak yer var mı" (df) ile "bu dizin ne kadar
yer yiyor" (du). `df -i` özel bir durumu kontrol eder: her dosya sisteminde, dosya
sayısı için ayrılmış sınırlı sayıda **inode** vardır (dosya içeriği için ayrılan alan
gibi değil, dosya *kayıtları* için ayrılan sınırlı bir havuz) — çok sayıda küçük
dosya (binlerce boş dosya, e-posta kuyruğu gibi) diskte yer kaplamasa bile inode'ları
tüketebilir; bu durumda `df -h` boş yer gösterirken sistem yine de "No space left on
device" hatası verir çünkü tükenen aslında bayt değil, inode kotasıdır.

```bash
free -h                  # RAM kullanımı
uptime                   # Ne kadardır açık + yük ortalaması
top                      # Canlı süreç izleme
htop                     # top'un güzeli (ayrıca kurulur)

blkid                    # Blok cihazların UUID ve dosya sistemi tipi
lsblk                    # Disk/bölüm ağacı ← blkid'den daha okunaklı
stat dosya                # Dosya hakkında her şey (inode, 3 zaman damgası, izin)
file dosya                # Dosyanın GERÇEK tipi (uzantıya bakmaz!)
iostat                   # Disk I/O istatistikleri (sysstat paketi)
```

> `file` neden önemli? Linux'ta uzantı **tamamen anlamsızdır** — Windows'un aksine,
> dosya adının sonundaki `.jpg`, `.txt` gibi ekler sistem için hiçbir işlevsel anlam
> taşımaz, tamamen kozmetiktir. `resim.jpg` adında bir dosya aslında çalıştırılabilir
> bir betik olabilir. `file` dosyanın ilk baytlarına (her dosya biçiminin kendine özgü
> "imzası" olan magic number) bakarak gerçek tipi tespit eder — uzantıya değil,
> içeriğe güvenir.

### Sistemi kapatma

```bash
sudo shutdown -h now             # Hemen kapat
sudo shutdown -r now             # Hemen yeniden başlat
sudo shutdown -h +10 "Bakım"     # 10 dk sonra, kullanıcılara mesaj
sudo shutdown -c                 # Zamanlanmışı iptal et
sudo reboot
sudo poweroff
sudo systemctl reboot            # systemd karşılığı
```
`shutdown -h +10 "mesaj"` özellikle çok kullanıcılı sunucularda önemlidir: anlık
`poweroff` yerine gecikmeli kapatma, o an sistemde oturum açmış diğer kullanıcılara
(bağlı SSH oturumları, çalışan işlemler) hazırlanma süresi tanır ve terminallerine
uyarı mesajı basar.

---

## 8. curl ve wget — ağdan dosya/veri çekme

`curl` ve `wget` ikisi de HTTP(S)/FTP üzerinden veri çeker ama tasarım
amaçları farklıdır. **`wget`**, **dosya indirmek** için tasarlanmıştır —
varsayılan davranışı aldığı içeriği doğrudan **diske kaydetmektir**, ve bir
siteyi bütünüyle (bağlantılarını takip ederek) indirmek gibi işlerde
güçlüdür. **`curl`** çok daha genel amaçlı bir veri transfer aracıdır — çok
daha fazla protokolü destekler ve varsayılan olarak aldığı içeriği **ekrana
(stdout) basar**, dosyaya değil — bu onu script'lerde, bir API'yle
(REST çağrıları, özel header/method/body ile) konuşurken kullanmaya uygun
hale getirir.

```bash
curl -O https://site.com/dosya.tar.gz   # -O: uzak dosyanın adıyla KAYDET
curl -o yerel-ad.tar.gz https://...     # -o: özel bir isimle kaydet
curl -L https://kisa.link/x              # -L: yönlendirmeleri (redirect) TAKİP ET
curl -I https://site.com                 # -I: sadece HTTP header'ları al (HEAD isteği)
curl -s https://site.com                 # -s: sessiz — ilerleme çubuğunu gizle
curl -v https://site.com                 # -v: verbose — istek/yanıt detaylarını göster

curl -X POST -H "Content-Type: application/json" \
     -d '{"kullanici":"ali"}' https://api.site.com/giris
#    -X: HTTP metodu   -H: özel header   -d: gönderilecek veri (POST body)
```

> [!NOTE]
> **`curl -O` ile `curl -o` arasındaki fark**
> Büyük `-O` (remote name), sunucudan gelen dosya adını **olduğu gibi** kullanarak
> diske kaydeder — URL'nin sonundaki dosya adını sen tekrar yazmak zorunda kalmazsın.
> Küçük `-o` ise **senin belirlediğin** bir isimle kaydeder; URL'nin adı ile senin
> istediğin dosya adı farklıysa (ya da URL'de anlamlı bir dosya adı yoksa,
> API çağrılarında olduğu gibi) bunu kullanırsın.

```bash
wget https://site.com/dosya.iso          # varsayılan: uzak dosya adıyla diske kaydet
wget -O ozel-ad.iso https://...          # -O: özel bir isimle kaydet (curl'ün -o'suna denk)
wget -c https://.../buyuk-dosya.iso      # -c: yarım kalan indirmeye KALDIĞI YERDEN devam et
wget -r -np https://site.com/dizin/      # -r: özyinelemeli indir, -np: üst dizinlere ÇIKMA
wget -q https://site.com/dosya           # -q: sessiz
```

> [!TIP]
> **Hangisini ne zaman kullanmalısın?**
> "Bu URL'deki dosyayı diske indir" gibi basit bir iş için `wget` genelde daha
> az yazım gerektirir (varsayılanı zaten kaydetmektir) ve kesilen büyük
> indirmeleri `-c` ile kaldığı yerden sürdürmede güçlüdür. Bir API'yle konuşmak,
> özel header/method/body göndermek, ya da yanıtı doğrudan bir sonraki komuta
> (`| jq`, `| grep` gibi) `pipe` etmek istiyorsan `curl` doğru araçtır — çünkü
> çıktıyı varsayılan olarak stdout'a basar, bir ara dosyaya yazıp sonra onu
> okumana gerek kalmaz.

---

## 🧪 Lab

1. `/tmp/lab02` altında `a/b/c` dizin ağacını **tek komutla** oluştur.
2. `/etc/passwd`'i buraya kopyala. Hem hard hem soft link oluştur, `ls -li` ile inode'ları karşılaştır. Orijinali sil, ikisini `cat` ile dene, sonucu not al.
3. `/etc/passwd`'den sadece **kullanıcı adı ve kabuk** alanlarını çıkar, kabuğa göre sırala.
4. Sistemde `/bin/bash` kullanan kullanıcı sayısını **tek satırda** bul.
5. `/var/log` altındaki en büyük 5 dosyayı boyutuyla listele.
6. `/etc` altında son 7 günde değişmiş tüm `.conf` dosyalarını bul.
7. `/tmp`'te 10 satırlık bir dosya oluştur, `split` ile 3'er satırlık parçalara böl, sonra `cat` ile birleştirip aslıyla `diff`le.

---

## ❓ Kendini test et

**S1.** `which cd` neden boş dönüyor?

<details><summary>Cevap</summary>
`cd` bir kabuk builtin'i, diskte çalıştırılabilir dosyası yok. `type cd` doğru cevabı verir.
</details>

**S2.** `df -h` diski %60 dolu gösteriyor ama dosya oluşturamıyorsun, "No space left on device" alıyorsun. Ne oldu?

<details><summary>Cevap</summary>
inode'lar bitmiş. `df -i` ile kontrol et. Çok sayıda küçük dosya (mail kuyruğu, session dosyaları,
oturum cache) inode tüketir. Çözüm: gereksiz küçük dosyaları temizlemek.
</details>

**S3.** `sort dosya | uniq -c` yerine doğrudan `uniq -c dosya` yazsan ne olur?

<details><summary>Cevap</summary>
`uniq` sadece **ardışık** tekrarları görür. Sıralanmamış dosyada dağınık tekrarları
saymaz, yanlış sonuç verir. `uniq` öncesi `sort` neredeyse her zaman gereklidir.
</details>

**S4.** `ls -ltr` niye `ls -lt`'den daha kullanışlı, özellikle log dizininde?

<details><summary>Cevap</summary>
`-r` sıralamayı tersine çevirir, en yeni dosya **en altta** çıkar — yani terminal
imlecinin hemen üstünde. Uzun listelerde yukarı kaydırmadan görürsün.
</details>

**S5.** Bir dosya `rm` ile silinmiyor, root'sun, izinler de tam. Ne kontrol edersin?

<details><summary>Cevap</summary>
`lsattr dosya` — immutable (`i`) bayrağı konmuş olabilir. `chattr -i dosya` ile kaldırılır.
</details>

**S6.** `cp -r kaynak hedef/` ile `cp -r kaynak/ hedef/` arasındaki fark nedir?

<details><summary>Cevap</summary>
Sonunda `/` olmayan `kaynak`, dizinin kendisini hedefe kopyalar → `hedef/kaynak/` oluşur.
Sonunda `/` olan `kaynak/`, dizinin içeriğini doğrudan hedefe kopyalar. Bu fark
`rsync`'te de aynen geçerlidir ve yanlış kullanımı veri kaybına yol açabilir.
</details>

---

## 📋 Hızlı referans

```bash
type KOMUT                 # Bu tam olarak ne?
man 5 DOSYA                # Dosya biçimi kılavuzu
ls -ltrh                   # En sık kullanacağın ls kombinasyonu
cp -a KAYNAK HEDEF         # Öznitelikleri koruyarak kopya
ln -s HEDEF LINK           # Symlink
tail -F /var/log/...       # Canlı log takibi (rotate'a dayanıklı)
find /yol -name "*.log" -mtime +30 -delete
du -sh * | sort -rh | head # Yer kim yiyor
df -h ; df -i              # Alan VE inode
lsblk ; blkid              # Disk yapısı ve UUID
file DOSYA                 # Gerçek dosya tipi
```
