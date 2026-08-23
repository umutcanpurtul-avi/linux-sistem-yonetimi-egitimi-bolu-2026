---
tags: [linux, egitim, vim]
modul: 03
durum: tamamlandi
---

# 03 — Vim Editörü

> **Ön koşul:** [02-temel-komutlar](02-temel-komutlar.md)
> **Süre:** ~1.5 saat + günlük pratik

## Hedefler

- [ ] Vim'in mod mantığını anlıyorum ve modlar arasında rahat geçiyorum
- [ ] Kaydetmeden çıkma / kaydedip çıkma / zorla çıkma refleksi oturdu
- [ ] Satır silme, kopyalama, yapıştırma, geri alma yapabiliyorum
- [ ] Arama ve toplu değiştirme yapabiliyorum
- [ ] Root yetkisi olmadan açtığım dosyayı `:w !sudo tee` ile kaydedebiliyorum

---

## Neden Vim?

Her Linux sisteminde `vi` **vardır** — bu bir gelenek değil, POSIX standardının
gerektirdiği bir garantidir. Kurtarma modunda (sistem açılmıyor, sadece minimal bir
kabuk var), konteynerde (Docker imajları genelde sadece en gerekli araçları içerir),
ilk kurulumda, sadece SSH ile eriştiğin uzak bir sunucuda `nano` kurulu **olmayabilir**
ama `vi` **her zaman** oradadır. Bu yüzden Vim, "beğenmesen de bilmek zorunda olduğun"
tek editördür — bir gün elin-kolun bağlıyken (grafik arayüz yok, internet yok, sadece
minimal bir kurtarma kabuğu var) tek çaren o olacak.

> **Dağıtım farkı:**
> - RHEL/Rocky minimal kurulumda `vim` yok, sadece `vi` (`vim-minimal` paketi) vardır.
>   `dnf install vim-enhanced` ile tam sürüm gelir (renklendirme, `:help` vb.).
> - Debian minimalde `vim-tiny` vardır — ok tuşları insert modda garip davranır!
>   `apt install vim` ile düzelir.
> - Ubuntu'da varsayılan editör `nano`'dur (`EDITOR` değişkeni). Değiştirmek için:
>   `sudo update-alternatives --config editor`

---

## 1. Modlar — Vim'i anlamanın anahtarı

**Bu bölüm Vim'in tamamının temelidir — atlarsan geri kalan hiçbir şey mantıklı gelmez.**

Diğer editörlerde (nano, Not Defteri, VS Code) klavyeye bastığın her tuş doğrudan
metne yazılır — tek bir "mod" vardır. Vim'de ise **yazmak** ve **komut vermek**
tamamen ayrı iki moddur; aynı `d` tuşu, bulunduğun moda göre ya "d harfini yaz" ya da
"bir şey sil" anlamına gelir. Bu tasarımın nedeni tarihsel ve pratiktir: Vim, klavyeden
ellerini hiç kaldırmadan (fare veya ok tuşlarına uzanmadan) hızlı düzenleme yapabilmek
için tasarlanmıştır — normal modda her harf tuşu bir "komut" olarak kullanılabildiği
için (yazma modunda olsaydı bu mümkün olmazdı), düzenleme işlemleri çok daha hızlı
gerçekleşir. Karışıklığın %90'ı, "hangi moddayım" sorusunu unutup NORMAL modda
harfleri "yazmaya" çalışmaktan (ki bunlar komut olarak yorumlanır, metni bozar) veya
INSERT modda komut yazmaya çalışmaktan (ki metne öylece yazılır) gelir.

```
                 i, a, o, I, A, O
    NORMAL  ──────────────────────►  INSERT
      ▲                                 │
      │             ESC                 │
      └─────────────────────────────────┘
      │
      │  :  (iki nokta)
      ▼
  KOMUT SATIRI (ex)      ── :w  :q  :wq  :%s/a/b/g

      │  v / V / Ctrl+v
      ▼
    GÖRSEL (visual)      ── seçim yapıp işlem
```

- **NORMAL mod** (varsayılan, Vim'i her açtığında buradasın): Tuşlar **komut**
  anlamına gelir — `h j k l` hareket, `dd` satır sil, `yy` kopyala gibi. Metin
  doğrudan yazılmaz.
- **INSERT mod**: Tuşlar doğrudan **metin** olarak yazılır — diğer editörlerdeki
  gibi normal yazma modu.
- **KOMUT SATIRI (ex) mod**: `:` ile başlar, dosya kaydetme/çıkma, arama-değiştirme
  gibi "cümle halinde" komutlar buradan girilir.
- **GÖRSEL (visual) mod**: Metni fare gibi seçip (klavye ile) toplu işlem (sil,
  kopyala, girintile) uygulamak için.

**Kural:** Ne yaptığından emin değilsen **ESC**'e bas. Seni her zaman NORMAL moda
getirir — Vim'de kaybolduğunda dönülecek "ana üs" NORMAL moddur, ESC de oraya giden
evrensel tuştur.

### INSERT moduna girme yolları

INSERT moduna giden altı farklı tuş var, hepsi seni yazma moduna sokar ama **imlecin
nereye konumlanacağı** farklıdır — doğru tuşu seçmek, sonradan imleci taşımak zorunda
kalmamanı sağlar.

| Tuş | Ne yapar |
|---|---|
| `i` | İmlecin **önüne** ekle (insert) |
| `a` | İmlecin **sonrasına** ekle (append) |
| `I` | Satırın **başına** git ve ekle |
| `A` | Satırın **sonuna** git ve ekle |
| `o` | **Alta** yeni satır aç |
| `O` | **Üste** yeni satır aç |

Yapılandırma dosyasının sonuna satır ekleyeceksen: `G` (dosya sonu) → `o` (yeni satır) → yaz → `ESC`.
Bu üç adım tek başına Vim'in en sık kullanılan iş akışlarından biridir — bir config
dosyasına yeni bir ayar satırı eklemek istediğinde hep bu sırayı izlersin.

---

## 2. Çıkış — önce bunu ezberle

**Neden çıkış komutlarını her şeyden önce öğrenmelisin?** Vim'i ilk açan biri, nano/
Not Defteri alışkanlığıyla `Ctrl+X` veya `Ctrl+C` gibi tuşlara basar — hiçbiri işe
yaramaz (ya da NORMAL moddaysa istenmeyen bir komut tetiklenir), kişi Vim'in içinde
"mahsur kalmış" hisseder. Bu, Vim'e dair en yaygın ilk deneyimdir ve internette
esprisi yapılır. Çıkış tuşlarını bilmek, bu tuzağa düşmemenin tek yoludur.

```
:w        kaydet
:q        çık
:wq       kaydet ve çık
:x        aynısı (sadece değişiklik varsa yazar)
ZZ        :wq'nun kısayolu (NORMAL modda, iki büyük Z)
:q!       KAYDETMEDEN çık ← "yanlış şey yaptım" kurtarıcısı
:w!       zorla kaydet
:wq!      zorla kaydet ve çık
```
Bu komutların hepsi **KOMUT SATIRI modunda** girilir — yani önce `ESC` ile NORMAL
moda dönüp sonra `:` yazman gerekir (INSERT moddayken `:w` yazarsan, bu harfler
metnin içine yazılır, komut olarak çalışmaz — sık yapılan bir hatadır).
`!` işareti Vim'de genel olarak "zorla, sorgusuz yap" anlamına gelir: `:q!` dosyada
kaydedilmemiş değişiklik olsa bile Vim'in normalde vereceği "kaydetmeden çıkmak
istediğine emin misin" uyarısını atlayıp doğrudan çıkar; `:w!` salt-okunur bir dosyaya
bile yazmayı **dener** (izin varsa).

**Yeni başlayan senaryosu:** Yapılandırma dosyasını bozdun, ne yaptığını bilmiyorsun.
→ `ESC` `:q!` → dosya el değmemiş kaldı. Bu ikiliyi kas hafızasına al — bu iki tuş
kombinasyonu, Vim'de yaptığın her hatayı sıfırlayan evrensel "geri dön" düğmesidir.

---

## 3. Gezinme (NORMAL modda)

**Neden ok tuşları yerine `hjkl`?** Tarihsel bir sebebi var: Vim'in atası `vi`,
1970'lerde ok tuşu olmayan terminallerde geliştirildi; `hjkl` klavyenin ana satırında
(home row) olduğu için eller hiç yer değiştirmeden gezinme sağlar — bu yüzden hâlâ
tercih edilir, hız kazandırır. Ok tuşları da modern terminallerde çalışır ama
`hjkl`'ye alışmak uzun vadede daha hızlıdır çünkü parmakların ana konumdan hiç
ayrılmasına gerek kalmaz.

```
h j k l      sol, aşağı, yukarı, sağ (ok tuşları da çalışır)
w            sonraki kelimenin başı
b            önceki kelimenin başı
0            satır başı
^            satırdaki ilk karakter (boşluklar hariç)
$            satır sonu
gg           dosyanın başı
G            dosyanın sonu
25G          25. satıra git      ← hata mesajı satır numarası verdiğinde
:25          aynısı
Ctrl+f       sayfa aşağı
Ctrl+b       sayfa yukarı
```
`0` ile `^` arasındaki fark küçük ama işe yarar: `0` satırın **gerçek** ilk
karakterine gider (satır başında boşluk/tab varsa oraya), `^` ise baştaki
boşlukları atlayıp **ilk anlamlı karaktere** gider — girintili kod satırlarında
`^` genelde istediğin yerdir.

---

## 4. Düzenleme

```
x            imleçteki karakteri sil
dd           satırı sil (aslında "kes" — yapıştırılabilir)
3dd          3 satır sil
dw           kelimeyi sil
D            imleçten satır sonuna kadar sil
yy           satırı kopyala (yank)
3yy          3 satır kopyala
p            imlecin ALTINA/sağına yapıştır
P            imlecin ÜSTÜNE/soluna yapıştır
u            geri al (undo) ← istediğin kadar
Ctrl+r       ileri al (redo)
.            son işlemi TEKRARLA ← Vim'in en güçlü tuşu
r<karakter>  tek karakter değiştir
cw           kelimeyi değiştir (siler ve insert moda geçer)
J            alt satırı bu satıra birleştir
>>  <<       satırı sağa / sola girintile
```

**`dd`'nin aslında "kes (cut)" olması ne demek?** `dd` ile sildiğin bir satır
kaybolmaz, Vim'in dahili bir "kayıt defterine (register)" gider — hemen ardından
`p` ile yapıştırabilirsin. Bu yüzden `dd` + `p`, başka editörlerdeki kes-yapıştır
(cut-paste) işlemine karşılık gelir; sadece silmek istiyorsan bu bir yan etki, ama
taşımak istiyorsan asıl mekanizma budur.

**Sayı + komut mantığı:** Vim'de neredeyse her komutun önüne sayı yazabilirsin —
bu, "bu komutu N kere uygula" anlamına gelen genel bir kural, ezberlenecek ayrı bir
komut değil. `5dd` = 5 satır sil, `3p` = 3 kere yapıştır, `10j` = 10 satır aşağı,
`3yy` = 3 satır kopyala. Bu mantığı bir kere kavradığında, öğrendiğin her yeni
komutu otomatik olarak sayılarla da kullanabilirsin.

**Nokta (`.`) örneği:** Bir kelimeyi sildin (`dw`). Aynı işlemi 4 yerde daha
yapacaksın. Her seferinde `dw` yazmak yerine hedefe git, `.` bas — `.`, **son yapılan
değişikliği** (silme, ekleme, değiştirme — hareket komutları hariç) olduğu gibi
tekrarlar. Tekrarlayan düzenleme işlerinde (aynı kelimeyi 10 yerde silmek/değiştirmek
gibi) `.` tuşu, tek tuşla otomasyon gibi çalışır ve Vim'in en çok zaman kazandıran
özelliklerinden biridir.

---

## 5. Arama ve değiştirme

```
/kelime       ileri ara
?kelime       geri ara
n             sonraki eşleşme
N             önceki eşleşme
*             imleçteki kelimeyi ara
```
`/` ve `?` arasındaki fark sadece **yön**dür: `/` imleçten dosyanın sonuna doğru
arar, `?` imleçten dosyanın başına doğru arar. İkisinde de `n` "aynı yönde devam et",
`N` "ters yönde devam et" anlamına gelir — yani `?` ile arama yaptıysan `n` geriye
doğru gitmeye devam eder. `*` imlecin üzerinde durduğun kelimeyi otomatik olarak
arama kutusuna yazıp arar — bir değişken/fonksiyon adının dosyada başka nerede
geçtiğini görmek için elle yazmadan tek tuşla arama yapmanı sağlar.

### Toplu değiştirme (`substitute`)

**`substitute` komutu ne işe yarar?** Bir metin editörünün "bul ve değiştir" (find &
replace) özelliğinin Vim'deki karşılığıdır, ama çok daha ayrıntılı kontrol sağlar —
hangi satır aralığında, kaç kez, onay isteyerek mi yoksa otomatik mi çalışacağını
komutun kendi sözdiziminde belirtirsin.

```vim
:s/eski/yeni/          " sadece bu satırda, İLK eşleşme
:s/eski/yeni/g         " bu satırda TÜM eşleşmeler
:%s/eski/yeni/g        " TÜM dosyada tüm eşleşmeler   ← en çok kullanılan
:%s/eski/yeni/gc       " her birinde ONAY sor          ← en güvenlisi
:%s/eski/yeni/gi       " büyük/küçük harf duyarsız
:10,20s/eski/yeni/g    " sadece 10-20. satırlar arası
```
Sözdizimi `:[satır_araligi]s/ara/degistir/[bayraklar]` şeklinde okunur. Başındaki
`%` "dosyanın tamamı" anlamına gelen özel bir aralıktır (1'den son satıra kadar
kısaltması); yazmazsan komut sadece **imlecin bulunduğu satırda** çalışır — bu en
sık yapılan hatalardan biridir ("değiştirmedi" sanılan durumların çoğu aslında sadece
o an bulunulan satırda çalışıp diğer satırlara dokunmamıştır). Sondaki `g` (global)
olmazsa her satırda sadece **ilk** eşleşme değişir, satırdaki diğer tüm eşleşmeler
olduğu gibi kalır. `c` (confirm) bayrağı, her eşleşmede "değiştireyim mi? (y/n/a/q)"
diye sorar — emin olmadığın toplu değişikliklerde `gc` kullanmak, yanlışlıkla
istemediğin bir yeri değiştirmeni önler.

Yol içeren metinlerde `/` çakışır, ayraç değiştir:
```vim
:%s#/eski/yol#/yeni/yol#g
```
**Neden `#` kullanılıyor?** `substitute` komutu, ayraç olarak `/` yerine hemen hemen
her karakteri kabul eder — dosya yollarını değiştirirken `/eski/yol` içindeki her
`/`, komutun kendi ayracıyla (`/`) karışır ve Vim nerede "ara" kısmının bittiğini
şaşırır. `#` (veya `,`, `@` gibi metinde geçmeyen başka bir karakter) seçerek bu
çakışmayı önlersin.

**Sahada gerçek örnek** — tüm `SELINUX=enforcing` satırını değiştirmek:
```vim
:%s/^SELINUX=enforcing/SELINUX=permissive/g
```
Buradaki `^` satır başını işaret eden bir düzenli ifade (regex) sembolüdür —
"sadece satırın **başında** bu metin varsa değiştir" der; bu sayede satırın
ortasında/yorumunda geçen benzer bir metni yanlışlıkla değiştirmezsin.

---

## 6. Görsel mod (visual)

```
v            karakter seçimi
V            SATIR seçimi         ← en çok kullanılan
Ctrl+v       BLOK seçimi (dikdörtgen)  ← sütun düzenlemek için
```
Görsel mod, fare ile metin sürükleyip seçmenin klavye karşılığıdır. Üç türü,
**neyi seçtiğine** göre ayrışır: `v` tek tek karakterleri (satır sonunu aşıp devam
edebilir), `V` bütün satırları (karakter seçimi umursamaz, hep tam satır), `Ctrl+v`
ise sütun bazlı, **dikdörtgen** bir alan seçer — bu üçüncüsü diğer çoğu editörde
bile bulunmayan, Vim'e özgü güçlü bir özelliktir.

Seçtikten sonra: `d` sil, `y` kopyala, `>` girintile, `u` küçük harfe çevir.

**Blok modun süper gücü — çoklu satır başına `#` ekleme (toplu yorum):**
1. İlk satırın başına git
2. `Ctrl+v`
3. `j` ile aşağı inerek satırları seç
4. `Shift+i` (büyük I) bas
5. `#` yaz
6. `ESC` — tüm seçili satırların başına `#` eklenir

**Neden 6. adımda `ESC`'e basmadan önce hiçbir şey değişmiş gibi görünmez?** Blok
modda yapılan ekleme işlemi, teknik olarak sadece **ilk satıra** uygulanır; `ESC`'e
bastığın an Vim bu değişikliği **seçtiğin tüm diğer satırlara da** otomatik olarak
uygular. Bu yüzden `ESC`'e basana kadar sabırla beklemek gerekir — erken çıkarsan
sadece ilk satır değişir.

Geri alma (yorumları kaldırma): `Ctrl+v` → satırları seç → `x`.

---

## 7. Sistem yöneticisi için kritik numaralar

### `sudo` unutmuşsun, dosya salt okunur

**Bu neden olur, neden önemlidir?** Root'a ait bir yapılandırma dosyasını (ör.
`/etc/fstab`) `sudo` **eklemeden** `vim /etc/fstab` ile açtın diyelim; Vim dosyayı
açar ama sıradan kullanıcının o dosyaya yazma izni olmadığı için 20 dakika süren
düzenlemenin sonunda `:w` dediğinde "E212: Can't open file for writing" hatası alırsın.
Vim'den çıkıp `sudo vim` ile yeniden açmak, yaptığın tüm değişiklikleri kaybetmek
anlamına gelirdi — ama gelmiyor, çünkü aşağıdaki numara var:

```vim
:w !sudo tee % > /dev/null
```
Bu komut Vim'in kendi kaydetme mekanizmasını kullanmaz; bunun yerine dosyanın o anki
içeriğini (Vim'in belleğindeki hali) bir kabuk komutuna (`!`) **borudan (pipe)**
gönderir. `%` Vim'de "şu an açık olan dosyanın adı" demektir. `sudo tee dosya`,
`sudo` yetkisiyle o dosyaya yazan bir komuttur (`tee`, girdiği stdin'i hem ekrana
hem belirttiğin dosyaya yazar — burada ekrana yazdığı kısmı `/dev/null`'a atarak
bastırıyoruz). Yani özetle: "Vim'in içindeki metni, sudo yetkisiyle bu dosyaya yaz"
demiş oluyorsun — Vim'i kapatmadan, hiçbir değişikliği kaybetmeden.

Ardından `L` (reload) veya `e!`. Bu satır seni "20 dakikalık düzenlemeyi baştan yapma"
kaderinden kurtarır. Ezberle.

### Faydalı `:set` ayarları

```vim
:set number         " satır numarası göster (:set nu)
:set nonumber       " kapat
:set paste          " yapıştırırken otomatik girintiyi kapat ← YAML'de hayat kurtarır
:set nopaste
:set hlsearch       " arama sonuçlarını renklendir
:noh                " renklendirmeyi temizle
:syntax on          " sözdizimi renklendirme
```

> `:set paste` neden kritik? Vim, `autoindent` gibi ayarlar açıkken, yeni bir satıra
> geçtiğinde **otomatik olarak** bir önceki satırın girintisini tekrarlar — bu, elle
> yazarken faydalıdır. Ama terminale çok satırlı bir metin (ör. bir YAML/config
> bloğunu) **yapıştırdığında**, Vim bu yapıştırmayı "elle yazma" sanıp her satıra
> kendi otomatik girintisini **ekstra olarak** ekler; sonuçta her satır bir öncekinden
> biraz daha fazla girintili çıkar ("merdiven" görünümü) ve özellikle girintiye çok
> duyarlı YAML dosyaları anlam olarak bozulur. `:set paste`, yapıştırma sırasında bu
> otomatik girintilemeyi geçici olarak kapatır; yapıştırma bitince `:set nopaste` ile
> normale dönersin.

### Kalıcı ayar: `~/.vimrc`

**Neden her seferinde `:set number` yazmak yerine bir dosyaya koyarsın?** `:set`
komutları sadece o anki Vim oturumu için geçerlidir — Vim'i kapatıp tekrar
açtığında sıfırlanır. `~/.vimrc`, Vim'in **her açılışında otomatik olarak okuduğu**
bir yapılandırma dosyasıdır; buraya yazdığın ayarlar kalıcı olur, her dosya açışında
elle tekrar girmene gerek kalmaz.

```bash
cat > ~/.vimrc <<'EOF'
set number
set expandtab
set tabstop=4
set shiftwidth=4
set hlsearch
set incsearch
syntax on
EOF
```

### Diğer faydalı komutlar

```vim
:e dosya           " başka dosya aç
:e!                " kaydedilmemişleri at, diskteki hali yeniden yükle
:r dosya           " başka dosyanın içeriğini buraya ekle
:r !komut          " bir komutun ÇIKTISINI dosyaya ekle (ör: :r !date)
:!komut            " Vim'den çıkmadan kabuk komutu çalıştır
:sp dosya          " yatay böl
:vsp dosya         " dikey böl  (Ctrl+w w ile pencereler arası geç)
```
`:!komut` ile `:w !sudo tee %` arasındaki fark: `:!komut` sadece bir kabuk komutunu
çalıştırıp çıktısını gösterir (dosyaya bir şey yazmaz), `:r !komut` ise o komutun
çıktısını **doğrudan dosyaya, imlecin bulunduğu yere ekler** — örneğin bir config
dosyasına "bu değişikliği şu tarihte yaptım" notu düşmek için `:r !date` yazıp
tarihi otomatik ekleyebilirsin.

### Çökme kurtarma (swap dosyası)

**Vim'in swap dosyası nedir, `.cache` gibi bir şey mi?** Vim, bir dosyayı düzenlerken
yaptığın her değişikliği, olası bir çökme/elektrik kesintisi durumunda kurtarabilmek
için **arka planda `.dosyaadı.swp` adında gizli bir dosyaya** sürekli yazar. Normal
şartlarda `:wq` ile çıktığında bu swap dosyası otomatik silinir. Ama oturumun
(terminal/SSH bağlantısı) beklenmedik şekilde koparsa, swap dosyası diskte **kalır**
— ve aynı dosyayı tekrar açtığında Vim "bir swap dosyası buldum, bu dosya düzgün
kapatılmamış, kurtarmak ister misin" diye uyarır:
- `R` (recover) — swap dosyasındaki son değişiklikleri kurtar
- `D` (delete) — swap'ı sil, normal aç
- Kurtardıktan sonra `:w` yap, sonra `.dosya.swp` dosyasını manuel sil (Vim onu
  otomatik silmez, kurtarma sonrası elle temizlik senin sorumluluğundadır).

---

## Vim yerine alternatifler

| Editör | Ne zaman |
|---|---|
| `nano` | Hızlı tek satır düzeltme, Vim bilmeyene ait sunucu |
| `vim` | Her yerde var, güçlü, standart |
| `micro` | Modern tuş kombinasyonları (Ctrl+S kaydet), ayrıca kurulur |
| `sed -i` | Etkileşimsiz, script içinden düzenleme (Modül 06) |

`nano` temel tuşları: `Ctrl+O` kaydet, `Ctrl+X` çık, `Ctrl+W` ara, `Ctrl+K` satır kes.
`nano`'nun avantajı, ekranın altında hangi tuşun ne yaptığını **sürekli göstermesi**
— Vim'de bu bilgi yoktur, ezber gerektirir. Bu yüzden tek seferlik, basit bir
düzenleme yapacaksan ve Vim'e henüz alışmadıysan `nano` daha hızlı sonuç verir; ama
sistem yöneticisi olarak her sunucuda `nano` bulamayacağın için Vim'i öğrenmek
zorunludur.

---

## 🧪 Lab

1. `vimtutor` komutunu çalıştır ve **tamamını bitir** (~25 dk). Bu modülün en değerli tek adımı.
2. `/etc/ssh/sshd_config` dosyasını `/tmp/test.conf` olarak kopyala. Üzerinde:
   - `:set number` yap
   - `Port` satırını bul (`/Port`), `2222` yap
   - Tüm `#` ile başlayan ilk 20 satırı görsel blok modla seçip sil
   - `:%s/yes/no/gc` yap, birkaçında `y` birkaçında `n` de
   - `:q!` ile çık, dosyanın değişmediğini `diff` ile doğrula
3. Root'a ait bir dosyayı **sudo'suz** `vim` ile aç, bir şey ekle, `:w !sudo tee % > /dev/null` ile kaydet.
4. Kendine bir `~/.vimrc` yaz.
5. `Ctrl+v` blok moduyla 10 satırlık bir dosyanın hepsinin başına `# ` ekle, sonra geri al.

---

## ❓ Kendini test et

**S1.** Yanlışlıkla 50 satır sildin ve kaydettin. Ne yaparsın?

<details><summary>Cevap</summary>
Vim hâlâ açıksa `u` ile geri al (undo geçmişi kayıttan sonra da durur), sonra tekrar `:w`.
Kapattıysan `:e dosya` ile aç, Vim persistent undo açıksa `u` çalışır; değilse yedeğe dönmen gerekir.
Bu yüzden düzenlemeden önce `cp dosya dosya.bak`.
</details>

**S2.** Ok tuşlarına bastığında INSERT modda `A B C D` harfleri yazılıyor. Neden?

<details><summary>Cevap</summary>
`vim-tiny` / eski `vi` uyumluluk modunda çalışıyorsun (tipik: Debian minimal). Bu modda
terminal, ok tuşu bastığında aslında `ESC` + `[A` gibi bir kaçış (escape) dizisi
gönderir; tam Vim bunu "yukarı git" komutu olarak yorumlar, ama uyumluluk modundaki
kısıtlı `vi` bunu tek tek harfler (`A`, `[`, vs.) olarak INSERT moda yazar.
Çözüm: `apt install vim` veya `~/.vimrc` içine `set nocompatible`.
</details>

**S3.** YAML dosyasına dışarıdan kopyaladığın blok, yapıştırınca merdiven gibi kaydı. Ne unuttun?

<details><summary>Cevap</summary>
`:set paste`. Yapıştırmadan önce aç, sonra `:set nopaste` ile kapat. Aksi halde Vim'in
otomatik girintileme özelliği, yapıştırılan her satıra kendi girintisini de ekleyerek
metni bozar.
</details>

**S4.** Sadece 40-60. satırlar arasındaki `debug` kelimelerini `info` yapmak istiyorsun. Komut?

<details><summary>Cevap</summary>

```vim
:40,60s/debug/info/g
```
Satır aralığı belirtilmezse (`%` veya sayı olmadan) komut sadece imlecin bulunduğu
tek satırda çalışır — bu yüzden başında `40,60` aralığını açıkça yazmak gerekir.
</details>

**S5.** `:%s/eski/yeni/g` yazdın ama hiçbir şey değişmedi gibi görünüyor, dosyada "eski" kelimesi kesin var. Ne olmuş olabilir?

<details><summary>Cevap</summary>
Büyük/küçük harf duyarlılığı ("Eski" yazmışsın, aramaya "eski" yazdın) ya da satır
başında/ortasında beklenmeyen boşluk/özel karakter olabilir. `gi` bayrağıyla
(`:%s/eski/yeni/gi`) büyük/küçük harf duyarsız arama dene, ya da önce `/eski` ile
arayıp gerçekten eşleşme buluyor mu kontrol et.
</details>

---

## 📋 Hızlı referans

```
ESC              her zaman güvenli liman
:q!              kaydetmeden çık
:wq / ZZ         kaydet ve çık
i a o / I A O    insert moduna gir
dd yy p u .      sil kopyala yapıştır gerial tekrarla
gg G 25G         başa, sona, 25. satıra
/ara  n  N       ara ve gez
:%s/a/b/gc       tüm dosyada onaylı değiştir
V / Ctrl+v       satır / blok seçimi
:set number|paste|hlsearch
:w !sudo tee % > /dev/null    sudo'suz açtığını kaydet
vimtutor         resmi 25 dakikalık kurs
```
