---
tags: [linux, egitim, bash, script]
modul: 06
durum: tamamlandi
---

# 06 — Kabuk (Shell) ve Bash Programlama

> **Ön koşul:** [02-temel-komutlar](02-temel-komutlar.md), [03-vim-editoru](03-vim-editoru.md)
> **Süre:** ~5 saat — setin en uzun ve en getirisi yüksek modülü

## Hedefler

- [ ] Kabuk kavramını ve çevresel değişkenleri anlıyorum
- [ ] Yönlendirme ve pipe'ı akıcı kullanıyorum
- [ ] grep / cut / awk / sed dörtlüsüyle metin işleyebiliyorum
- [ ] Değişkenli, koşullu, döngülü bash betiği yazabiliyorum
- [ ] Fonksiyon yazıp betiğimi güvenli (`set -euo pipefail`) hale getirebiliyorum

---

## 1. Kabuk kavramı

> [!NOTE]
> **Kabuk tam olarak ne, kernel'in kendisi neden komutlarımı doğrudan almıyor?**
> Kernel (çekirdek), donanımla konuşan, süreçleri yöneten, dosya sistemini sunan
> alçak seviyeli bir programdır — kullanıcı dostu bir arayüzü yoktur, doğrudan onunla
> "komut yazarak" konuşamazsın. **Kabuk (shell)**, senin yazdığın metni (`ls -la /etc`
> gibi) alıp, bunu kernel'in anlayacağı sistem çağrılarına (bir program başlatma,
> dosya açma gibi) çeviren bir **yorumlayıcı (interpreter)** programdır. Yani kabuk,
> kernel'in kendisi değil, kernel'in üstünde çalışan sıradan bir programdır — tıpkı
> `firefox` ya da `vim` gibi. Farkı, kabuğun **komut çalıştırmak için özel olarak**
> tasarlanmış olmasıdır: senin yazdığın satırı ayrıştırır (parse eder — hangi kısım
> komut, hangi kısım argüman, hangi kısım özel karakter), gerekiyorsa değişkenleri
> ve joker karakterleri (glob) genişletir, sonra ilgili programı bu genişletilmiş
> haliyle çalıştırır.

Kabuk, kullanıcı ile kernel arasındaki yorumlayıcıdır. Komutunu alır, ayrıştırır,
genişletir, çalıştırır.

```bash
echo $SHELL          # Giriş kabuğun (login shell)
ps -p $$             # ŞU AN çalışan kabuk (farklı olabilir!)
cat /etc/shells      # Sistemde tanımlı kabuklar
chsh -s /bin/zsh     # Kendi kabuğunu değiştir
```

> [!NOTE]
> **`$SHELL` ile "şu an çalışan kabuk" neden farklı olabilir?**
> `$SHELL` değişkeni, `/etc/passwd`'deki senin **giriş kabuğun** olarak kayıtlı
> değeri tutar — bu, sistem sana hangi programı "varsayılan kabuğun" olarak
> atadığını söyler, ama bu bir **statik kayıt**tır, o an gerçekten hangi kabukta
> olduğunu göstermez. Mesela giriş kabuğun `bash` olsa bile, sonradan terminalde
> elle `zsh` yazıp yeni bir zsh süreci başlatabilirsin — bu durumda `$SHELL` hâlâ
> `/bin/bash` yazar (çünkü o değişken zsh tarafından miras alınmış, güncellenmemiştir)
> ama sen fiilen zsh içindesindir. `ps -p $$` bunun tam tersini yapar: `$$` "şu an
> çalışan kabuk sürecinin PID'i" demektir, `ps -p $$` de o PID'in **gerçekten** hangi
> programa ait olduğunu sorgular — bu yüzden anlık gerçeği gösterir, `$SHELL`'in
> statik kaydını değil.

| Kabuk | Not |
|---|---|
| `sh` | POSIX standardı, en yalın |
| `bash` | Bourne Again Shell — Linux'ta fiili standart |
| `zsh` | macOS varsayılanı, gelişmiş tamamlama |
| `dash` | Hızlı, küçük |

> **Dağıtım farkı — kritik tuzak:** Debian/Ubuntu'da `/bin/sh` → **`dash`**'e symlink'tir,
> `bash` değil. `#!/bin/sh` ile başlayan betiğinde `[[ ]]`, `array`, `source` gibi
> bash'e özgü şeyler kullanırsan **Debian'da çalışmaz, RHEL'de çalışır** (RHEL'de
> `/bin/sh` → `bash`). Betiğin bash gerektiriyorsa shebang'i `#!/bin/bash` yaz.

> [!NOTE]
> **Neden Debian `dash`'i tercih ediyor, `bash` yeterli değil mi?**
> `dash`, `bash`'in aksine POSIX standardının **sadece** gerektirdiği özellikleri
> içeren, çok daha küçük ve hızlı başlayan bir kabuktur — `bash`'in sahip olduğu
> zengin özellikler (dizi/array desteği, `[[ ]]` gelişmiş test, string manipülasyon
> genişletmeleri) `dash`'te yoktur çünkü bunlar POSIX standardının parçası değildir.
> Debian, sistem açılışında (`/etc/init.d` betikleri gibi) ve paket kurulum
> betiklerinde çalışan yüzlerce küçük betiğin **hızlıca** başlayıp bitmesini istediği
> için `/bin/sh`'i `bash` yerine `dash`'e bağlar — `bash`'in başlatma süresi (kendi
> yapılandırma dosyalarını okuması, ek özellikleri yüklemesi) `dash`'e göre gözle
> görülür derecede daha yavaştır, bu sistem genelinde binlerce kez tekrarlandığında
> ciddi bir fark yaratır. Bunun senin için pratik sonucu: `#!/bin/sh` yazdığın bir
> betik "POSIX uyumlu, sade" olmalı sözü verir; içine bash'e özgü bir şey koyarsan
> bu sözü bozmuş olursun ve Debian'da (dash `[[ ]]`'i tanımadığı için) betiğin
> patlar. Güvenli kural: bash özellikleri kullanacaksan her zaman `#!/bin/bash` yaz,
> `#!/bin/sh` yalnızca gerçekten sade, POSIX'e sadık kalacağın betiklerde kullan.

### Başlangıç dosyaları — hangisi ne zaman okunur?

| Dosya | Ne zaman |
|---|---|
| `/etc/profile` | Login shell — sistem geneli |
| `/etc/profile.d/*.sh` | Login shell — modüler eklemeler ⭐ doğru yer burası |
| `~/.bash_profile` | Login shell — kullanıcıya özel (RHEL) |
| `~/.profile` | Login shell — kullanıcıya özel (Debian/Ubuntu) |
| `~/.bashrc` | **Her interaktif kabuk** — alias'lar buraya |
| `~/.bash_logout` | Çıkışta |

Login shell = SSH ile bağlanmak, `su -`, konsol girişi.
Non-login interaktif = `bash` yazmak, terminal emülatöründe yeni sekme.

> [!NOTE]
> **"Login" ile "non-login" ayrımı neden var, tek bir başlangıç dosyası yetmez miydi?**
> Bir kabuk açılırken iki farklı senaryo söz konusu olabilir: (1) sen **gerçekten
> sisteme yeni giriş yapıyorsun** (SSH ile bağlandın, konsoldan giriş yaptın, `su -`
> ile kullanıcı değiştirdin) — bu durumda ortamının **sıfırdan, eksiksiz** kurulması
> gerekir: `$PATH`, `$HOME`, dil ayarları, her şey baştan hesaplanmalı. (2) sen
> **zaten** bir oturum içindesin ve sadece **yeni bir kabuk penceresi/sekmesi**
> açıyorsun (terminal emülatöründe yeni tab, ya da bir betik içinde `bash` çağırmak)
> — bu durumda ortamın zaten doğru kurulmuştur (üst süreçten miras alınır), sadece
> o pencereye özel küçük ayarların (alias'lar, prompt rengi gibi) yüklenmesi yeterlidir,
> tüm ortamı yeniden hesaplamak gereksiz bir maliyettir. Bash bu iki senaryo için
> **farklı dosya kümeleri** okur: login shell'de `/etc/profile` ve kullanıcının
> profil dosyası (bir kere, ortamı tam kurmak için), her interaktif kabukta ise
> (login olsun olmasın) `~/.bashrc` (hafif, tekrar tekrar çalıştırılabilir ayarlar
> için). Bu yüzden alias'ları `~/.bash_profile`'a koyarsan, sadece login anında
> çalışır — yeni bir terminal sekmesi açtığında (non-login) o alias'lar **görünmez**,
> kafanı karıştırır. `~/.bashrc`'ye koymak her durumda çalışmasını garanti eder.

> RHEL'de `~/.bash_profile` içinde `~/.bashrc`'yi çağıran bir satır vardır, o yüzden
> alias'ları `~/.bashrc`'ye yazmak her durumda çalışır. Sistem geneli değişiklikleri
> `/etc/profile`'a değil `/etc/profile.d/isim.sh` içine yaz — güncellemede ezilmez.

> [!NOTE]
> **`/etc/profile.d/isim.sh` neden `/etc/profile`'dan daha iyi bir yer?**
> `/etc/profile`, dağıtımın kendi paket yöneticisi tarafından bakımı yapılan bir
> dosyadır — bir sistem güncellemesi bu dosyayı kendi varsayılan haliyle **üzerine
> yazabilir**, sen elle eklediğin satırları kaybedebilirsin. `/etc/profile.d/`
> dizini ise tam olarak bu sorunu çözmek için vardır: `/etc/profile`'ın sonunda,
> bu dizindeki **her** `.sh` dosyasını otomatik olarak çalıştıran bir döngü bulunur.
> Yani kendi eklemeni `/etc/profile.d/kendi-ayarlarim.sh` gibi **ayrı, isimlendirilmiş
> bir dosyaya** koyarsan, dağıtımın kendi `/etc/profile`'ını güncellemesi senin
> dosyana hiç dokunmaz — paket yöneticisinin bilmediği, senin sisteme eklediğin bir
> dosya olarak kalır, güncellemelerden etkilenmez.

---

## 2. Değişkenler

> [!NOTE]
> **Kabuk değişkenleri neden var, sadece komut çalıştırmak yetmiyor mu?**
> Değişkenler, kabuğa **hafıza** kazandırır — bir değeri (bir dosya yolu, bir sayı,
> bir metin) bir isme bağlayıp sonra tekrar tekrar kullanabilmeni sağlar. Bu, hem
> etkileşimli kullanımda (bir dizin yolunu bir değişkende tutup tekrar tekrar
> yazmak zorunda kalmamak) hem betik yazarken (bir betiğin farklı girdilerle
> çalışabilmesi için parametrelerini değişkenlerde tutmak) temel bir ihtiyaçtır.
> Ayrıca **çevresel değişkenler** (environment variables), programların birbirleriyle
> "konuşmadan" bilgi paylaşmasının standart yoludur — bir program `$PATH`'e bakarak
> hangi dizinlerde çalıştırılabilir dosya arayacağını bilir, `$HOME`'a bakarak
> kullanıcının ayar dosyalarını nerede arayacağını bilir. Bu paylaşılan sözleşme
> olmasa, her program kendi rastgele yöntemiyle bu bilgileri bulmaya çalışırdı.

```bash
ad="Ali"              # ⚠️ = etrafında BOŞLUK YOK
echo $ad
echo ${ad}nin         # Süslü parantez sınırı belirler
echo "$ad"            # Tırnak içinde genişler
echo '$ad'            # Tek tırnakta genişlemez → literal $ad

export ad             # Alt süreçlere de geçsin (çevresel değişken yap)
unset ad              # Sil
readonly PI=3.14      # Değiştirilemez
```

> [!WARNING]
> **`ad = "Ali"` (boşluklu) neden hata veriyor?**
> Bu, bash'e yeni başlayan hemen herkesin düştüğü bir tuzaktır. Bash, bir satırı
> kelimelere ayırırken (parse ederken) boşlukları **kelime ayıracı** olarak kullanır.
> `ad = "Ali"` yazdığında bash bunu "atama" olarak değil, **üç ayrı kelimeden oluşan
> bir komut** olarak okur: `ad` adında bir komutu, `=` ve `"Ali"` argümanlarıyla
> çalıştırmaya çalışır. Sistemde `ad` diye bir komut olmadığı için "command not
> found" hatası alırsın. `ad="Ali"` (boşluksuz) ise bash'e "bu tek bir atama
> ifadesidir" der — atama sözdiziminde `=`'nin etrafında boşluk **olmaması**, o
> satırın bir kelime değil bir atama olduğunu bash'e bildiren işarettir.

> [!NOTE]
> **`$ad`, `${ad}`, `"$ad"`, `'$ad'` — bu dört gösterim arasındaki fark tam olarak ne?**
> - `$ad` → en yalın genişletme, değişkenin değerini yerine koyar. Ama sonrasında
>   bitişik bir harf/rakam gelirse (`echo $adnin` gibi) bash bunu "adnin" adında
>   **tek bir değişken** sanır, senin istediğin "ad değişkeninin değeri + nin"
>   olmaz.
> - `${ad}` → süslü parantez, değişken isminin **nerede bittiğini** açıkça
>   belirtir. `${ad}nin` bash'e "değişken adı sadece `ad`, ondan sonraki `nin`
>   düz metin" der — bu belirsizliği çözer.
> - `"$ad"` → çift tırnak içinde değişken **genişler** (değerine dönüşür) ama
>   boşluklar korunur — eğer `$ad` içinde boşluk varsa (`ad="Ali Veli"`), tırnaksız
>   `$ad` bunu iki ayrı kelimeye böler (bir komuta iki ayrı argüman gibi geçer),
>   tırnaklı `"$ad"` ise tek bir bütün olarak geçirir. Bu yüzden betik yazarken
>   değişkenleri **her zaman çift tırnak içinde kullanmak** en temel güvenlik
>   alışkanlıklarından biridir (boşluklu dosya adlarıyla çalışırken özellikle kritik).
> - `'$ad'` → tek tırnak içinde **hiçbir şey genişlemez**, `$` işareti bile düz
>   metin olarak kalır. Bunu, bir metni olduğu gibi (değişken içeriği koymadan)
>   yazdırmak istediğinde kullanırsın.

```bash
dosya="/var/log/app.log"
echo ${dosya##*/}    # app.log      (basename)
echo ${dosya%/*}     # /var/log     (dirname)
echo ${dosya%.log}   # /var/log/app
```

### Önemli çevresel değişkenler

```bash
echo $PATH        # Komutların aranacağı dizinler (: ile ayrılır)
echo $HOME $USER $PWD $OLDPWD
echo $LANG        # Dil/locale ← script çıktısını bozabilir
echo $PS1         # Prompt biçimi
echo $?           # ⭐ Son komutun çıkış kodu (0 = başarı)
echo $$           # Mevcut kabuğun PID'i
echo $!           # Arka plana atılan son sürecin PID'i
env               # Tüm çevresel değişkenler
set               # Değişkenler + fonksiyonlar
```

> [!NOTE]
> **`$PATH` mekanizması tam olarak nasıl işliyor?**
> Sen `ls` yazdığında, bash bunu çalıştırmak için `$PATH`'te listelenen dizinleri
> **sırayla, soldan sağa** tarar (`/usr/local/bin:/usr/bin:/bin` gibi `:` ile
> ayrılmış bir liste) ve `ls` adında çalıştırılabilir bir dosya bulduğu **ilk**
> dizinde durur, onu çalıştırır. Bu şu anlama gelir: eğer `/usr/local/bin` ve
> `/usr/bin`'de aynı isimli iki farklı program varsa, `$PATH`'te **önce gelen**
> dizindeki çalışır — bu yüzden `export PATH="/opt/araclar/bin:$PATH"` ile bir
> dizini **başa** eklemek, o dizindeki programların sistem programlarının önüne
> geçmesini (öncelikli olmasını) sağlar; sona eklemek ise sadece sistemde
> bulunmayan komutlar için bir "yedek" konumu ekler.

**PATH'e dizin ekleme:**
```bash
export PATH="$PATH:/opt/araclar/bin"     # sona ekle
export PATH="/opt/araclar/bin:$PATH"     # başa ekle (öncelikli)
```
Kalıcı için `~/.bashrc` veya `/etc/profile.d/araclar.sh`.

> ⚠️ `PATH`'e `.` (mevcut dizin) **ekleme**. `/tmp`'te `ls` adlı kötü niyetli bir dosya
> varsa onu çalıştırırsın.

> [!WARNING]
> **Bu saldırı senaryosunu somutlaştır**
> `.` (nokta), "şu an bulunduğun dizin" anlamına gelir. `$PATH`'e `.` eklersen,
> bash her komut ararken **mevcut çalışma dizinini de** tarar. Bir saldırgan (ya
> da paylaşımlı bir sunucudaki kötü niyetli başka bir kullanıcı), herkesin girip
> çıktığı `/tmp` gibi bir dizine, sık kullanılan bir komutla **aynı isimde** (`ls`,
> `cd`, hatta `sudo`) kötü niyetli bir betik bırakabilir. Eğer `.`, `$PATH`'inde
> gerçek `/bin` dizininden **önce** geliyorsa, sen o dizindeyken masum bir şekilde
> `ls` yazdığında, aslında gerçek `ls` yerine saldırganın bıraktığı sahte betik
> çalışır — o betik senin yetkilerinle (belki root'la, `sudo` içindeysen) istediği
> her şeyi yapabilir, sonra gerçek `ls`'i çağırıp normal görünmeye devam edebilir,
> sen fark bile etmezsin. Bu yüzden `.`'i asla `$PATH`'e ekleme; bir betiği mevcut
> dizinden çalıştırmak istediğinde her zaman açıkça `./betik.sh` yaz.

### Özel genişletmeler

```bash
${degisken:-varsayilan}    # boşsa varsayılanı kullan (atama YAPMAZ)
${degisken:=varsayilan}    # boşsa ata
${degisken:?hata mesaji}   # boşsa hata verip çık ⭐ scriptte güvenlik
${#degisken}               # uzunluk
${degisken:0:5}            # alt dizgi (0'dan 5 karakter)
${dosya%.txt}              # sondan kırp → uzantı atma
${dosya##*/}               # baştan en uzun eşleşmeyi kırp → basename
${degisken/eski/yeni}      # ilk eşleşmeyi değiştir
${degisken//eski/yeni}     # tüm eşleşmeleri
```

> [!NOTE]
> **Bu genişletmeler neden var — elle `if` yazmak yerine bunu kullanmanın faydası ne?**
> Her biri, betik yazarken sık karşılaşılan bir kalıbı **tek satıra** sığdırır ve
> bu, hem okunabilirlik hem güvenilirlik kazandırır. `${degisken:-varsayilan}`,
> "eğer bu parametre verilmediyse şu varsayılanı kullan" demenin `if [ -z "$degisken" ];
> then degisken=varsayilan; fi` yazmaktan çok daha kısa yoludur — ama **atama
> yapmaz**, sadece o an için varsayılan değeri kullanır, değişkenin kendisi hâlâ
> boştur; `:=` ise aynı zamanda gerçekten atama da yapar, kalıcı olarak değeri
> ayarlar. `${degisken:?hata mesaji}` özellikle betik güvenliği için kritiktir:
> zorunlu bir parametrenin (mesela silinecek dizinin adı) verilmediği durumda,
> betiğin **sessizce boş bir değerle devam edip** yanlışlıkla tehlikeli bir işlem
> yapmasını (`rm -rf /` gibi bir felakete dönüşebilecek bir boş değişken durumu)
> önler — parametre boşsa betik anında, açık bir hata mesajıyla durur. `%` ve `##`
> ile başlayan kırpma genişletmeleri (`${dosya%.txt}`, `${dosya##*/}`) ise bir
> dosya yolundan uzantı veya dizin adı çıkarmak için ayrı bir `basename`/`dirname`
> komutu çağırmadan (bu ayrı bir süreç başlatmak demektir, kabuğun kendi
> genişletmesinden daha yavaştır), doğrudan kabuğun kendi içinde, hızlıca aynı
> işi yapmanı sağlar.

> [!NOTE]
> **`%` ile `##` arasındaki fark — "sondan mı baştan mı, en kısa mı en uzun mu"**
> Dört kırpma operatörü vardır ve ikisi yön (baştan/sondan), ikisi açgözlülük
> (en kısa/en uzun eşleşme) belirtir: `#` baştan en kısa eşleşmeyi kırpar, `##`
> baştan **en uzun** eşleşmeyi kırpar; `%` sondan en kısa, `%%` sondan **en uzun**
> eşleşmeyi kırpar. `${dosya##*/}` örneğinde `*/` deseni "herhangi bir şey, sonunda
> bir `/`" demektir; `##` (en uzun eşleşme) kullanıldığı için, yolda birden fazla
> `/` varsa (`/var/log/app.log` gibi) en **son** `/`'e kadar olan her şey kırpılır,
> geriye sadece dosya adı (`app.log`) kalır — bu tam olarak `basename` komutunun
> yaptığı iştir. `${dosya%/*}` ise tam tersini yapar: sondan, `/` ile başlayan en
> kısa parçayı kırpar, geriye dizin yolu (`/var/log`) kalır — `dirname` komutunun
> karşılığı.

```bash
dosya="/var/log/app.log"
echo ${dosya##*/}    # app.log      (basename)
echo ${dosya%/*}     # /var/log     (dirname)
echo ${dosya%.log}   # /var/log/app
```

---

## 3. Wildcard (glob) ve özel karakterler

> [!NOTE]
> **Glob nedir, kabuk mu bunu genişletiyor yoksa komutun kendisi mi?**
> Bu, çoğu yeni başlayanın kafasının karıştığı önemli bir noktadır: `ls *.log`
> yazdığında, `.log` uzantılı dosyaları **bulan `ls` değildir**. `ls` çalışmadan
> **önce**, kabuğun kendisi `*.log` desenini o an bulunduğun dizindeki gerçek dosya
> adlarıyla eşleştirir ve `*.log`'u eşleşen dosya adlarının **tam listesiyle**
> değiştirir — `ls` komutu, `*.log` diye bir argüman hiç görmez, doğrudan
> `ls dosya1.log dosya2.log dosya3.log` gibi genişletilmiş hâliyle çağrılır. Bu
> ayrımı bilmek önemlidir çünkü eşleşen dosya yoksa (glob "boş" genişlerse), bazı
> kabuklarda `*.log` **olduğu gibi** (genişletilmemiş, düz metin olarak) komuta
> geçer — bu da beklenmedik hatalara yol açabilir.

```bash
*         herhangi sayıda karakter      ls *.log
?         tek karakter                  ls dosya?.txt
[abc]     kümeden biri                  ls dosya[123].txt
[a-z]     aralık                        ls [a-m]*
[!abc]    kümede OLMAYAN                ls [!0-9]*
{a,b,c}   küme genişletmesi             touch dosya{1,2,3}.txt
{1..10}   aralık genişletmesi           mkdir gun{1..10}
```

```bash
mkdir -p proje/{src,doc,test}/{eski,yeni}    # 6 dizini tek komutta
cp dosya.conf{,.bak}                          # → cp dosya.conf dosya.conf.bak ⭐
```

> [!NOTE]
> **`{a,b,c}` küme genişletmesi ile `[abc]` küme eşleşmesi neden karıştırılmamalı?**
> İkisi de köşeli/süslü parantez kullanıyor gibi görünse de tamamen farklı işler
> yapar. `[abc]` (köşeli parantez) bir **dosyanın adında o pozisyonda** `a`, `b`
> veya `c` harflerinden **birinin** olup olmadığını kontrol eder — var olan dosya
> adlarıyla eşleşme yapar, eşleşen yoksa hiçbir şey üretmez. `{a,b,c}` (süslü
> parantez) ise dosya sistemine hiç bakmadan, **saf metin üretimi** yapar — var
> olsun olmasın, `dosya{1,2,3}.txt` yazdığında kabuk bunu üç ayrı kelimeye
> (`dosya1.txt dosya2.txt dosya3.txt`) genişletir, bu üç dosya sistemde olmasa bile.
> Bu yüzden `{ }` genişletmesi **oluşturma** işlemlerinde (yeni dizin/dosya
> yaratmak) kullanışlıdır — `mkdir -p proje/{src,doc,test}/{eski,yeni}` sistemde
> henüz var olmayan 6 dizini tek komutta üretir; `[ ]` ise **var olan** dosyalar
> arasında **seçim/filtreleme** yaparken kullanılır.
>
> `cp dosya.conf{,.bak}` özellikle şık bir kullanımdır: `{,.bak}` iki parçadan
> oluşur — biri **boş** (`dosya.conf` olduğu gibi kalır), diğeri `.bak` ekler
> (`dosya.conf.bak` olur). Sonuç: `cp dosya.conf dosya.conf.bak` — dosya adını iki
> kere yazmadan hızlı bir yedek kopyası alma kalıbıdır.

**Glob ≠ regex.** Glob dosya adlarında, regex metin içeriğinde çalışır.
Glob'da `*` = "herhangi sayıda karakter". Regex'te `*` = "önceki karakterin 0+ tekrarı".
Karıştırmak çok yaygındır.

> [!WARNING]
> **Bu karışıklığın somut bir örneği**
> `ls *.log` yazdığında `*` "her şey" demektir — herhangi sayıda, herhangi karakter.
> Ama `grep` içinde `*` kullandığında (`grep a*b dosya`), regex kuralı geçerlidir:
> `*` **kendinden önceki tek karakterin** sıfır veya daha fazla tekrarı demektir —
> yani `a*b` deseni "sıfır veya daha fazla `a`'dan sonra bir `b`" arar (`b`, `ab`,
> `aab`, `aaab` gibi eşleşir, ama `xb` eşleşmez, `axb` de eşleşmez çünkü `x` bir
> `a` değil). Bu iki `*` birbirinden **tamamen bağımsız kurallardır**, sadece
> aynı sembolü paylaşırlar — hangi bağlamda (dosya adı mı, metin arama mı)
> olduğunu bilmeden `*`'i yorumlamaya çalışmak hataya yol açar.

### Kaçış ve tırnaklar

```bash
echo "Merhaba $USER"     # çift tırnak: $ ve ` genişler
echo 'Merhaba $USER'     # tek tırnak: hiçbir şey genişlemez
echo "Fiyat: \$100"      # ters bölü ile kaçır
echo `date`              # eski komut ikamesi
echo $(date)             # ⭐ modern komut ikamesi — iç içe kullanılabilir
```

> [!NOTE]
> **`` `date` `` yerine neden `$(date)` tercih edilir?**
> İkisi de aynı işi yapar: bir komutu çalıştırıp, o komutun **çıktısını** o
> noktaya bir metin olarak yerleştirir (komut ikamesi/substitution). Ama `` ` ` ``
> (backtick) sözdizimi eski ve kısıtlıdır — **iç içe** kullanmak zorlaşır çünkü
> backtick'in kendisi hem başlangıç hem bitiş işaretidir, iç içe bir backtick
> nerede başlayıp nerede bittiğini ayırt etmek bash için (ve senin gözün için)
> zordur, kaçış karakterleri gerektirir. `$( )` sözdizimi ise açılış (`$(`) ve
> kapanış (`)`) farklı karakterler olduğu için, `$(echo $(date))` gibi iç içe
> kullanımlar doğal ve okunaklı kalır — parantezler eşleşerek netlik sağlar. Bu
> yüzden modern bash yazımında `` ` ` `` neredeyse hiç kullanılmaz, `$( )` standart
> hâle gelmiştir.

---

## 4. Yönlendirme ve pipe

> [!NOTE]
> **Bu konuyu Gün 1'de zaten işlemiştik — burada aynı temeli daha derin bir bağlamda tekrar kur**
> Her Unix sürecinde üç standart kanal açıktır: `0` (stdin, girdi kaynağı), `1`
> (stdout, normal çıktı), `2` (stderr, hata çıktısı). Bunların **neden ayrı ayrı
> tutulduğunu** anlamak önemli: bir komutun normal çıktısını bir dosyaya kaydetmek
> isteyebilirsin ama hataları yine ekranda görmek isteyebilirsin (ya da tam tersi)
> — eğer stdout ve stderr tek bir kanal olsaydı, bunları birbirinden ayırmanın
> hiçbir yolu olmazdı. Bu ayrım, otomasyon yazarken (bir cron işinin normal
> çıktısını sessizce yutup sadece hataları e-posta ile bildirmesi gibi) hayati
> önem taşır.

```
0 = stdin    1 = stdout    2 = stderr
```

```bash
komut > dosya           # stdout'u dosyaya yaz (ÜZERİNE)
komut >> dosya          # sona ekle
komut 2> hata.log       # sadece hataları
komut > cikti 2> hata   # ayrı ayrı
komut > hepsi 2>&1      # ikisini birden aynı dosyaya
komut &> hepsi          # bash kısayolu, aynısı
komut > /dev/null 2>&1  # tamamen sustur
komut 2>/dev/null       # sadece hataları sustur ← find'da çok kullanılır
```

> [!NOTE]
> **`2>&1` sözdizimini gerçekten çöz — `&` burada ne işe yarıyor?**
> Bu sözdizimi ilk bakışta garip görünür: `2>&1` neden `2>1` değil? Fark kritiktir.
> `2>1` yazsaydın, bash bunu "stderr'i, `1` adında bir **dosyaya** yönlendir" olarak
> yorumlardı — mevcut dizinde `1` adında bir dosya oluşturmaya çalışırdı, senin
> istediğin bu değil. `&` işareti burada "bu bir dosya adı değil, bir **dosya
> tanımlayıcı numarasıdır**" der — yani `2>&1`, "stderr'i (2), stdout'un (1) **şu
> an yönlendirildiği yere** gönder" demektir; `1`'in kendisi değil, `1`'in **o an
> işaret ettiği hedef** kopyalanır. Bu yüzden sıralama önemlidir: `komut > dosya
> 2>&1` yazdığında, bash soldan sağa işler — önce `1`'i (stdout) `dosya`'ya
> yönlendirir, sonra `2>&1` ile stderr'i "stdout'un o an gittiği yere" (yani artık
> `dosya`'ya) gönderir — ikisi de `dosya`'ya yazılır. Eğer sırayı ters yazsaydın
> (`komut 2>&1 > dosya`), önce stderr stdout'un o anki hedefine (henüz terminale
> gidiyor) yönlendirilir, sonra stdout dosyaya yönlendirilir — ama stderr zaten
> "terminale" bağlanmıştı, bu bağlantı değişmez, sonuç olarak stderr **terminalde**
> kalır, dosyaya gitmez.

> `2>&1` sırası önemli: `komut > dosya 2>&1` doğru, `komut 2>&1 > dosya` yanlış
> (stderr terminale gider). Sağdan sola değil, **soldan sağa** değerlendirilir.

```bash
komut < girdi.txt       # stdin'i dosyadan al
komut <<< "metin"       # here-string
komut <<EOF             # here-document
satir1
satir2
EOF
```

> [!NOTE]
> **Here-document (`<<EOF`) ne işe yarar, neden `echo` yeterli değil?**
> `<<EOF ... EOF` kalıbı, **çok satırlı** bir metni bir komutun girdisi olarak
> vermenin temiz yoludur — özellikle bir dosyanın içeriğini bir betik içinden
> doğrudan tanımlamak istediğinde (`cat > dosya.txt <<EOF ... EOF` gibi) her satırı
> ayrı `echo >> dosya.txt` komutlarıyla eklemek yerine, tüm bloğu tek seferde,
> okunaklı bir şekilde yazmanı sağlar. `EOF` (End Of File) burada özel bir anahtar
> kelime değildir, senin seçtiğin **herhangi bir işaretçi**dir — bash, aynı kelimeyi
> tek başına bir satırda tekrar gördüğünde bloğun bittiğini anlar. Here-string
> (`<<<`) ise tek satırlık, basit bir metni bir komutun stdin'ine vermek için daha
> kısa bir yoldur (`grep "ali" <<< "$degisken"` gibi, dosya oluşturmadan bir
> değişkenin içeriğini grep'e girdi olarak verir).

### Pipe

```bash
komut1 | komut2                  # komut1'in çıktısı komut2'nin girdisi
ps aux | grep nginx | wc -l
cat /var/log/syslog | tail -20   # gereksiz cat — doğrusu: tail -20 /var/log/syslog

komut | tee dosya                # ekrana YAZ ve dosyaya da kaydet
komut | tee -a dosya             # ekle modunda
```

> [!NOTE]
> **Pipe (`|`) ile redirection (`>`) arasındaki temel fark ne?**
> İkisi de bir çıktıyı "başka bir yere" gönderir ama hedefleri farklıdır: `>`
> çıktıyı bir **dosyaya** yazar (kalıcı, diskte duran bir şey), `|` ise çıktıyı
> başka bir **çalışan sürece** (başka bir komuta) doğrudan, hiç diske dokunmadan
> aktarır. Bunun pratik önemi performans ve akıştır: `ps aux | grep nginx | wc -l`
> yazdığında, üç program **aynı anda** çalışır ve veriler bellek içi bir kanal
> (pipe buffer) üzerinden akar — hiçbir ara sonuç diske yazılmaz. Bu, Unix
> felsefesinin özüdür: her komut tek bir işi iyi yapar (`ps` süreçleri listeler,
> `grep` süzer, `wc` sayar), pipe bunları birbirine bağlayarak küçük araçlardan
> karmaşık işler kurmanı sağlar — ayrı ayrı bir "hepsi bir arada nginx sayacı"
> programı yazmana gerek kalmaz.

`tee` sahada çok işe yarar:
```bash
sudo dnf update 2>&1 | tee /tmp/guncelleme.log
echo "192.168.1.5 sunucu" | sudo tee -a /etc/hosts   # sudo ile >> çalışmaz!
```
> `sudo echo "x" >> /etc/dosya` **çalışmaz**, çünkü yönlendirmeyi sudo değil kabuk yapar.
> Doğrusu `| sudo tee -a`.

> [!WARNING]
> **Bu `sudo` + yönlendirme tuzağını mutlaka anla, çok sık karşına çıkacak**
> `sudo echo "x" >> /etc/dosya` yazdığında, şunu düşünürsün: "sudo ile çalıştırıyorum,
> root yetkim var, yazabilmeliyim." Ama gerçekte olan şu: bash, bu satırı **iki
> ayrı parçaya** ayırır — `sudo echo "x"` (çalıştırılacak komut) ve `>> /etc/dosya`
> (yönlendirme). Yönlendirmeyi **`sudo` değil, seni çağıran kabuğun kendisi**
> kurar — ve o kabuk **root olarak çalışmıyor**, sen (normal kullanıcı) olarak
> çalışıyor. `sudo`, sadece `echo "x"` komutunun kendisini root olarak çalıştırır;
> ama `echo`'nun ürettiği çıktının `/etc/dosya`'ya yazılması işlemi kabuğun işidir
> ve kabuk hâlâ senin normal yetkindedir — `/etc/dosya`'ya yazma izni yoksa
> "Permission denied" alırsın, `sudo` yazmış olman fark etmez.
> `echo "x" | sudo tee -a /etc/dosya` bu sorunu çözer çünkü burada yönlendirme
> **yok**, `tee` adında gerçek bir **program** var — ve bu program `sudo` ile
> (root olarak) çalıştırılıyor. `tee`, stdin'den okuduğu her şeyi hem ekrana hem
> belirttiğin dosyaya yazan bir programdır; `sudo tee` dediğinde `tee` programının
> kendisi root yetkisiyle dosyaya yazma işlemini **kendi içinde** yapar, bu da
> `sudo`'nun kapsamı içindedir.

### xargs — çıktıyı parametreye çevirme

```bash
find /tmp -name "*.log" | xargs rm
find /tmp -name "*.log" -print0 | xargs -0 rm      # ⭐ boşluklu adlar için
cat sunucular.txt | xargs -I{} ssh {} "uptime"     # her satır için
cat liste.txt | xargs -P4 -I{} komut {}            # 4 paralel
```

`komut $(...)` ile `xargs` farkı: `$( )` çıktıyı tek seferde argüman yapar, çok uzunsa
"Argument list too long" hatası verir. `xargs` parça parça çalıştırır.

> [!NOTE]
> **`xargs` gerçekte hangi problemi çözüyor?**
> `find` gibi komutlar çıktı olarak bir **dosya listesi** üretir, ama bu çıktı
> stdout'a yazılan **metin**tir — bir sonraki komutun (`rm` gibi) **argümanı**
> olamaz, çünkü pipe (`|`) sadece stdin/stdout bağlar, argüman listesini
> doldurmaz. `xargs`, tam olarak bu köprüyü kurar: stdin'den satır satır (veya
> boşlukla ayrılmış olarak) okuduğu metni alıp, bunları bir sonraki komutun
> **argümanlarına** dönüştürür. `-print0` / `-0` çifti özel bir problem çözer:
> normal `xargs` girdiyi boşluk ve satır sonlarına göre ayırır, ama dosya adında
> boşluk varsa (`benim dosyam.txt` gibi) bu, tek dosyayı yanlışlıkla iki ayrı
> argüman sanmasına yol açar. `-print0`, `find`'a dosya adlarını boşluk yerine
> **null bayt** (`\0`) ile ayırmasını söyler — null bayt bir dosya adında asla
> geçerli bir karakter olamayacağı için, bu %100 güvenilir bir ayraçtır; `-0`
> bayrağı `xargs`'a bu null-bayrılmış girdiyi doğru ayrıştırmasını söyler.
> `-P4` ise paralellik ekler: normalde `xargs` her argümanı sırayla, birer birer
> işler; `-P4` dört işi **aynı anda** başlatır — mesela 100 sunucuya sırayla SSH
> ile bağlanıp bir komut çalıştırmak yerine, 4'ünü aynı anda yapmak toplam süreyi
> ciddi şekilde kısaltır.

---

## 5. Metin işleme dörtlüsü: grep, cut, awk, sed

> [!NOTE]
> **Bu dört araç neden ayrı ayrı var, hepsini yapan tek bir araç olsa olmaz mıydı?**
> Unix felsefesi, "her araç bir işi iyi yapsın, karmaşık işler bu araçları
> birleştirerek yapılsın" prensibine dayanır. Her biri farklı bir soruya
> odaklanır: `grep` **"hangi satırlar"** sorusuna (bir deseni içeren satırları
> bul), `cut` **"hangi sütun"** sorusuna (sabit bir ayraca göre bölünmüş metinden
> belirli bir alanı al), `awk` **"sütun + hesap + koşul"** sorusuna (hem sütun
> ayıklama hem sayısal işlem hem koşullu filtreleme, tek bir mini programlama
> dilinde), `sed` ise **"değiştir"** sorusuna (bir akıştaki metni bulup değiştir,
> sil, ekle) cevap verir. Bunları tek bir dev araçta birleştirmek yerine ayrı
> tutmak, her birinin öğrenilmesini kolaylaştırır ve pipe ile istediğin
> kombinasyonda birleştirebilmeni sağlar — büyük, hepsi-bir-arada bir araç bu
> esnekliği sağlayamazdı.

### grep — satır süzme

```bash
grep "hata" dosya
grep -i "hata"          # büyük/küçük harf duyarsız
grep -v "INFO"          # eşleşMEYEN satırlar
grep -r "kelime" /etc   # dizinde özyinelemeli
grep -n                 # satır numarası
grep -c                 # sayı
grep -w "ali"           # tam kelime (aliye eşleşmez)
grep -A3 -B3 "hata"     # 3 satır sonra/önce bağlam
grep -E "hata|uyari"    # genişletilmiş regex (= egrep)
grep -o "[0-9]\+"       # sadece eşleşen KISMI bas
```

**Temel regex:**
```
^abc     satır başı        abc$      satır sonu
.        tek karakter      [0-9]     rakam
*        0+ tekrar         \+        1+ tekrar (temel regex'te kaçışlı)
{2,4}    2-4 tekrar        \|        veya
\b       kelime sınırı
```

> [!NOTE]
> **"Temel regex" ile "genişletilmiş regex" (`-E`) arasındaki fark nereden geliyor?**
> Tarihsel nedenlerle `grep` iki farklı regex lehçesi destekler. **Temel regex
> (BRE)**'de bazı özel karakterler (`+`, `?`, `|`, `{}`) **özel anlamlarını
> kaybeder**, düz metin olarak eşleşirler — özel anlamlarını geri kazanmaları için
> önlerine ters bölü (`\+`, `\|`) koyman gerekir. **Genişletilmiş regex (ERE, `-E`
> bayrağıyla ya da `egrep` komutuyla)**'de ise bu karakterler **doğrudan** özel
> anlamlarını taşır, kaçış işaretine gerek yoktur (`+`, `|` doğrudan çalışır).
> Bu yüzden `grep -E "hata|uyari"` ile "hata veya uyari" ararken `|`'yi doğrudan
> yazabilirsin, ama `-E` olmadan aynı işi yapmak için `grep "hata\|uyari"` yazman
> gerekirdi (ki bu bazı `grep` sürümlerinde bile desteklenmeyebilir). Pratik
> tavsiye: karmaşık desenler yazarken hep `-E` kullan, kafanı BRE/ERE ayrımıyla
> yorma.

```bash
grep -E "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" access.log   # IP ile başlayan
grep -E "^#" /etc/ssh/sshd_config       # yorum satırları
grep -Ev "^#|^$" /etc/ssh/sshd_config   # ⭐ yorumsuz ve boşsuz — config okumanın en hızlı yolu
```

> [!NOTE]
> **`grep -Ev "^#|^$"` kalıbını gerçekten çöz, çok kullanacaksın**
> Bu tek satır üç fikri birleştirir. `-v` "eşleşMEYEN satırları göster" demektir
> (normal grep'in tersi — filtre mantığını ters çevirir). Desen `^#|^$` iki
> alternatifin **birleşimidir** (`|` = veya): `^#` "satır `#` ile başlıyor" (yorum
> satırı), `^$` "satır başı hemen satır sonuyla bitiyor" yani **tamamen boş satır**.
> `-v` ile birleştiğinde: "yorum olan VEYA boş olan satırları **gösterme**" —
> geriye sadece gerçek, anlamlı yapılandırma satırları kalır. Büyük bir
> yapılandırma dosyasında (`sshd_config` gibi genelde yüzlerce satır yorum ve
> boşluk içerir) gerçekten **aktif olan** ayarları görmek için bu, en hızlı ve
> en sık kullanılan kalıplardan biridir — birçok sistem yöneticisi bunu neredeyse
> refleks halinde yazar.

### cut — sabit ayraçlı sütun

```bash
cut -d: -f1     /etc/passwd
cut -d: -f1,6   /etc/passwd
cut -d' ' -f2   dosya         # tek boşluk ayraç — ARDIŞIK boşlukta bozulur
cut -c1-10      dosya
```
`cut` basittir ama çoklu boşlukla baş edemez. Orada `awk` gerekir.

> [!NOTE]
> **"Çoklu boşlukla baş edemez" ne demek, somut örnek ver**
> `cut -d' ' -f2` komutu, metni **tam olarak tek bir boşluk karakterine** göre
> böler — eğer aradaki boşluk sayısı değişkense (birçok komutun çıktısı, sütunları
> hizalamak için birden fazla boşluk kullanır, örneğin `ps aux` çıktısı), `cut`
> her boşluğu ayrı bir "boş alan" sayar ve senin 2. sütun dediğin şey aslında
> gerçek 2. sütun olmayabilir — belki iki boşluk arasındaki **boş bir alanı**
> 2. sütun sanır. `awk`, buna karşılık, **ardışık boşlukları tek bir ayraç gibi**
> ele alır (varsayılan davranışında) — bu yüzden hizalanmış, değişken sayıda
> boşluk içeren çıktılarla çalışırken `cut` yerine `awk '{print $2}'` kullanmak
> çok daha güvenilirdir. `cut` sadece **gerçekten sabit** bir ayraca (örneğin
> `/etc/passwd`'deki `:` gibi, her zaman tam olarak bir tane) sahip verilerde
> güvenle kullanılmalıdır.

### awk — sütun + koşul + hesap

```bash
awk '{print $1}' dosya              # 1. alan (ardışık boşlukları doğru yönetir)
awk '{print $1, $3}' dosya
awk '{print $NF}' dosya             # SON alan
awk -F: '{print $1}' /etc/passwd    # ayraç belirt
awk 'NR==5' dosya                   # 5. satır
awk 'NR>1' dosya                    # başlığı atla
awk '$3 > 1000' /etc/passwd -F:     # koşullu
awk '{toplam+=$1} END {print toplam}' sayilar.txt
awk '{print NR": "$0}' dosya        # satır numarala
```

> [!NOTE]
> **`awk`'ın çalışma mantığını gerçekten kur — bu bir "komut" değil, mini bir programlama dili**
> `awk`, her satırı otomatik olarak okuyup, o satırı **alanlara böler** (varsayılan
> ayraç: boşluk/tab), her alana `$1`, `$2`, `$3`... gibi numaralı bir isim verir
> (`$0` ise **satırın tamamı**), ve senin verdiğin `{ }` bloğunu **her satır için
> bir kez** çalıştırır. `$NF` özel bir değişkendir: `NF` "Number of Fields" (alan
> sayısı) demektir, `$NF` de "son alan" anlamına gelir — kaç alan olduğunu
> önceden bilmesen bile her zaman son sütunu almanı sağlar. `NR` ise "Number of
> Record" (satır numarası) — `NR==5` demek "sadece 5. satırda bu bloğu çalıştır",
> `NR>1` demek "1. satırdan sonraki her satırda çalıştır" (başlık satırını atlamak
> için klasik bir kalıp). `END { }` bloğu özeldir: normal `{ }` bloğu her satırda
> çalışırken, `END` bloğu **tüm satırlar bittikten sonra, bir kez** çalışır — bu
> yüzden `{toplam+=$1} END {print toplam}` kalıbı "her satırda 1. sütunu toplama
> ekle, en sonunda toplamı yazdır" der; klasik bir toplama/özetleme kalıbıdır.

**Sahada gerçek kullanımlar:**
```bash
# UID 1000 üstündeki kullanıcılar
awk -F: '$3>=1000 {print $1, $3}' /etc/passwd

# Disk kullanımı %80 üstü olan bölümler
df -h | awk 'NR>1 && $5+0 > 80 {print $6, $5}'

# En çok bellek tüketen 5 süreç
ps aux | awk '{print $4, $11}' | sort -rn | head -5

# Log'da en çok geçen IP'ler
awk '{print $1}' access.log | sort | uniq -c | sort -rn | head
```

> [!NOTE]
> **`$5+0 > 80` içindeki `+0` neden orada, gereksiz görünüyor**
> Değil — bu bilinçli bir hile. `df -h` çıktısında kullanım yüzdesi `%` işaretiyle
> birlikte gelir (`"80%"` gibi), yani bu bir **metin (string)**, doğrudan sayısal
> karşılaştırma yapmak için uygun değildir. `awk`'a `"80%" + 0` yazdırdığında,
> `awk` metni sayısal bir bağlamda kullanmaya çalışır ve **metnin başındaki
> sayısal kısmı** (`80`) alıp, sayısal olmayan kısmı (`%`) yok sayar — sonuç saf
> sayı `80` olur. Bu, "metnin başındaki sayıyı çıkar" için yaygın kullanılan bir
> `awk` hilesidir; `+0` eklemeden `"80%" > 80` yazsaydın, karşılaştırma metin
> bazlı yapılırdı ve beklediğin sonucu vermezdi.

### sed — akış düzenleyici

```bash
sed 's/eski/yeni/' dosya         # her satırda İLK eşleşme
sed 's/eski/yeni/g' dosya        # tüm eşleşmeler
sed -i 's/eski/yeni/g' dosya     # ⭐ DOSYAYI DEĞİŞTİR (in-place)
sed -i.bak 's/a/b/g' dosya       # önce .bak yedeği al ⭐⭐ bunu kullan
sed -n '5p' dosya                # sadece 5. satırı bas
sed -n '10,20p' dosya            # 10-20 arası
sed '3d' dosya                   # 3. satırı sil
sed '/^#/d' dosya                # yorum satırlarını sil
sed '/^$/d' dosya                # boş satırları sil
sed 's|/eski/yol|/yeni/yol|g'    # ayraç değiştirme (yol içinde / varsa)
```

> [!NOTE]
> **`sed`'in adı "stream editor" (akış düzenleyici) — bu isim ne anlatıyor?**
> `sed`, bir dosyayı açıp interaktif olarak (senin `vim` yaptığın gibi) düzenleyen
> bir araç **değildir**. Onun yerine, girdiyi (bir dosya veya stdin) **satır satır
> bir akış olarak** okur, her satıra verdiğin komutu (bul-değiştir, sil, göster
> gibi) uygular, ve sonucu stdout'a **yeni bir akış olarak** yazar — orijinal
> dosyaya varsayılan olarak hiç dokunmaz. `s/eski/yeni/` komutundaki `s`
> "substitute" (yerine koy) demektir; `g` bayrağı olmadan **sadece o satırdaki ilk
> eşleşmeyi** değiştirir (çünkü klasik `sed`'in kökeni tek seferlik düzeltmelerdir),
> `g` (global) eklediğinde **o satırdaki tüm eşleşmeleri** değiştirir. `-i`
> bayrağı bu "akış" davranışını kırar — normalde stdout'a yazılacak sonucu,
> doğrudan **orijinal dosyanın üzerine** yazmasını söyler; bu yüzden `-i` olmadan
> `sed` güvenlidir (sadece ekrana gösterir, dosyayı bozmaz), `-i` ile ise geri
> dönüşü olmayan bir değişiklik yaparsın.

**Yapılandırma değiştirme kalıbı:**
```bash
sudo sed -i.bak 's/^PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sudo sshd -t                     # sözdizimini DOĞRULA
sudo systemctl reload sshd
```
> `sed -i` geri alınamaz. `-i.bak` alışkanlığını edin. Otomasyonda config
> değiştirmeden önce `cp` + değişiklik sonrası `-t`/`--test` doğrulaması altın kuraldır.

> [!WARNING]
> **`-i` ile `-i.bak` arasındaki fark neden hayat kurtarır**
> `sed -i` (uzantısız), değişikliği doğrudan dosyanın üzerine yazar — eğer
> regex'in yanlışsa, yanlış dosyayı hedeflediysen, ya da beklenenden fazla satırı
> etkilediyse, **orijinal içerik kalıcı olarak kaybolur**, geri alma yolu yoktur
> (dosya sistemi seviyesinde bir "geri al" yoktur). `sed -i.bak` ise değişikliği
> uygulamadan **önce**, orijinal dosyanın `.bak` uzantılı bir kopyasını otomatik
> olarak oluşturur — değişiklik yanlış çıkarsa `mv dosya.bak dosya` ile saniyeler
> içinde eski haline dönebilirsin. Kritik sistem yapılandırma dosyalarında (`sshd_config`
> gibi, yanlış bir değişiklik seni sunucudan tamamen kilitleyebilir) bu alışkanlık
> opsiyonel değil, **zorunlu** olmalıdır. `sshd -t` gibi bir doğrulama komutunun
> ardından çağrılması da aynı mantığın devamıdır: değişikliği servise **yeniden
> yükletmeden önce**, sözdiziminin bozuk olmadığını doğrula — bozuksa servisi
> yeniden başlatman (`restart`, `reload` değil) SSH erişimini tamamen kesebilir.

---

## 6. Bash betik yazımı

> [!NOTE]
> **Bir betik ile bir dizi komutu terminale tek tek yazmak arasındaki fark ne?**
> Terminale komutları tek tek yazmak **etkileşimlidir** — her komutun sonucunu
> görüp bir sonrakine karar verirsin, ama bu süreç **tekrarlanabilir değildir**:
> aynı işi yarın tekrar yapman gerekirse, tüm adımları hatırlayıp yeniden yazman
> gerekir. Bir **betik (script)**, bu komut dizisini bir dosyaya yazıp, o dosyayı
> tek bir komut gibi çalıştırılabilir hale getirmektir — böylece bir işlemi bir
> kere doğru şekilde tanımlarsın, sonra istediğin kadar, hatasız ve tutarlı şekilde
> tekrarlayabilirsin. Bu, sistem yönetiminin otomasyon temelidir: elle yapılan her
> tekrar eden iş, potansiyel bir betiktir.

### İskelet

```bash
#!/bin/bash
#
# Ad     : yedek.sh
# Amaç   : /etc dizinini yedekler
# Kullanım: ./yedek.sh <hedef-dizin>
#
set -euo pipefail
IFS=$'\n\t'
```

> [!NOTE]
> **`#!/bin/bash` (shebang) satırı olmasa ne değişir?**
> Bu satıra "shebang" (`#!` karakterlerinin okunuşundan) denir ve dosyanın **ilk
> satırı** olmak zorundadır. İşlevi şudur: sen `./betik.sh` yazıp dosyayı doğrudan
> bir program gibi çalıştırdığında, kernel dosyanın içeriğine bakmadan önce bu
> ilk satırı okur ve "bu dosyayı hangi yorumlayıcıyla çalıştıracağımı" öğrenir —
> `#!/bin/bash` demek "bu dosyanın geri kalanını `/bin/bash` programına ver, o
> yorumlasın" demektir. Eğer shebang olmasaydı, `./betik.sh` çalıştırdığında kernel
> dosyayı **doğrudan bir ikili (binary) program** gibi çalıştırmaya çalışırdı ve
> muhtemelen "Exec format error" gibi bir hatayla karşılaşırdın — bash betiği,
> kendi başına çalıştırılabilir bir program değildir, her zaman bir yorumlayıcıya
> ihtiyaç duyar, shebang o yorumlayıcıyı belirtir.

**`set` seçenekleri — her ciddi betiğe koy:**
| Seçenek | Etkisi |
|---|---|
| `-e` | Herhangi bir komut hata verirse betiği durdur |
| `-u` | Tanımsız değişken kullanımı hata olsun |
| `-o pipefail` | Pipe zincirinde herhangi biri hata verirse zincir hata dönsün |
| `-x` | Her komutu çalıştırmadan önce ekrana yaz (**hata ayıklama**) |

`bash -x betik.sh` ile betiği değiştirmeden izleyebilirsin.

> [!NOTE]
> **Bu üç ayar (`-e`, `-u`, `-o pipefail`) olmadan bash'in **varsayılan** davranışı nasıl, neden tehlikeli?**
> Bash'in varsayılan davranışı, betik yazmak için değil, **etkileşimli kullanım**
> için tasarlanmıştır ve bu, betiklerde ciddi tehlikelere yol açar. Varsayılan
> olarak: (1) bir komut başarısız olsa bile (hata kodu döndürse), betik **durmaz**,
> bir sonraki satıra devam eder — bu, örneğin `cd /hedef-dizin` başarısız olsa
> (dizin yoksa) bile betiğin devam edip **yanlış dizinde** tehlikeli işlemler
> yapmasına yol açabilir (`cd yoktur-dizin; rm -rf *` gibi bir kalıp, `cd`
> başarısız olursa mevcut dizindeki her şeyi siler — klasik bir felaket senaryosu).
> `-e` bunu önler: herhangi bir komut sıfırdan farklı bir çıkış koduyla dönerse,
> betik **anında durur**. (2) Tanımsız (hiç atanmamış, ya da yazım hatasıyla yanlış
> yazılmış) bir değişkeni kullanmak varsayılan olarak **sessizce boş bir metin**
> olarak değerlendirilir — `rm -rf "$DIZN"` yazdın ama değişken adı aslında `$DIZIN`
> olmalıydı (yazım hatası); `$DIZN` tanımsız olduğu için boş metne dönüşür, komut
> `rm -rf ""` olur ki bu bazı durumlarda mevcut dizini hedefleyebilir. `-u` bunu
> önler: tanımsız bir değişken kullanıldığı an betik hata verip durur. (3) Bir
> pipe zincirinde (`komut1 | komut2 | komut3`), varsayılan olarak zincirin **çıkış
> kodu sadece son komutunkidir** — `komut1` başarısız olsa bile `komut2` ve `komut3`
> başarılı çalışırsa, zincirin tamamı "başarılı" sayılır, `-e` bile bunu yakalamaz.
> `-o pipefail`, zincirdeki **herhangi bir** komut başarısız olursa tüm zincirin
> başarısız sayılmasını sağlar. Üçü birlikte, bir betiği "sessizce yanlış bir şey
> yapmak" yerine "bir şey ters giderse hemen dur" moduna sokar — bu, betik
> yazarken güvenlik ağıdır.

### Çalıştırma

```bash
chmod +x betik.sh
./betik.sh              # shebang'deki yorumlayıcı ile
bash betik.sh           # açıkça bash ile
source betik.sh         # MEVCUT kabukta çalıştır (değişkenler kalır)
. betik.sh              # source'un kısası
```
> `source` ile `./` farkı: `./` alt süreçte çalıştırır, değişkenler kaybolur.
> `source` mevcut kabuğu değiştirir. `.bashrc` yeniden yüklerken `source ~/.bashrc`.

> [!NOTE]
> **"Alt süreçte çalıştırmak" ile "mevcut kabukta çalıştırmak" arasındaki fark neden önemli?**
> `./betik.sh` çalıştırdığında, bash senin için **tamamen yeni, ayrı bir süreç**
> başlatır — bu yeni sürecin kendi belleği, kendi değişkenleri vardır, seni
> çağıran kabuktan (ana terminalinden) tamamen bağımsızdır. Betik içinde
> `cd /baska/yer` yazsan bile, bu sadece o **alt sürecin** çalışma dizinini
> değiştirir; betik bitip alt süreç kapandığında, sen hâlâ **eski dizinindesin**
> — hiçbir değişiklik ana kabuğuna yansımaz, çünkü alt süreç tamamen ayrı bir
> "dünya"dır. `source betik.sh` (veya kısası `.`) ise yeni bir süreç **açmaz** —
> betiğin içindeki her komutu, sanki sen onları doğrudan **mevcut** kabuğuna
> yazmışsın gibi çalıştırır. Bu yüzden `source` edilen bir betikteki `cd`,
> `export`, değişken atamaları **kalıcı olarak** senin mevcut oturumunu etkiler.
> `source ~/.bashrc` yazmanın anlamı tam olarak budur: `.bashrc` içindeki yeni
> alias'ları, yeni değişkenleri **ayrı bir süreçte değil, şu an içinde bulunduğun
> kabukta** etkinleştirmek — eğer `./`  ile çalıştırsaydın (`bash ~/.bashrc` gibi),
> değişiklikler o alt süreçte kalır, senin terminalin hiç etkilenmezdi.

### Parametreler

```bash
$0        # betiğin adı
$1 $2 $3  # parametreler
$#        # parametre sayısı
$@        # tüm parametreler (ayrı ayrı) ← "$@" tırnaklı kullan
$*        # tüm parametreler (tek dizgi)
$?        # son komutun çıkış kodu
```

```bash
if [ $# -lt 1 ]; then
    echo "Kullanım: $0 <dosya>" >&2
    exit 1
fi
```

> [!NOTE]
> **`"$@"` ile `"$*"` arasındaki fark neden önemli — bu ayrım çoğu kaynakta yeterince vurgulanmaz**
> Betiğe üç parametre geçtin diyelim: `./betik.sh "dosya bir.txt" ikinci.txt`.
> Burada `$1` = `dosya bir.txt` (boşluklu, tek bir parametre), `$2` = `ikinci.txt`.
> `"$@"` bu parametreleri **ayrı ayrı, orijinal sınırlarını koruyarak** genişletir
> — bir döngüde `for p in "$@"` yazdığında, döngü **iki** kez çalışır, ilk turda
> `p="dosya bir.txt"` (boşluklu ama tek parça), ikinci turda `p="ikinci.txt"`
> olur. `"$*"` ise tüm parametreleri **tek bir metin** haline getirir (aralarına
> `$IFS`'in ilk karakterini, genelde boşluk, koyarak) — `for p in "$*"` yazdığında
> döngü sadece **bir** kez çalışır, `p` tüm parametrelerin birleşimi olan tek bir
> uzun metin olur. Bir betiğin aldığı parametreleri başka bir komuta olduğu gibi
> aktarman gerektiğinde (mesela bir wrapper betik), neredeyse her zaman `"$@"`
> istersin — orijinal parametre sınırlarını korur; `"$*"` yanlışlıkla kullanılırsa
> boşluklu bir parametrenin ayrışmasına ya da yanlış birleşmesine yol açar.

### Koşullar

```bash
if [ KOSUL ]; then
    ...
elif [ KOSUL ]; then
    ...
else
    ...
fi
```

**Test operatörleri:**

| Dosya | Anlam |
|---|---|
| `-f dosya` | Normal dosya var mı |
| `-d dizin` | Dizin var mı |
| `-e yol` | Var mı (tip fark etmez) |
| `-r/-w/-x` | Okunabilir/yazılabilir/çalıştırılabilir |
| `-s dosya` | Var ve boyutu 0'dan büyük |

| Sayı | Dizgi |
|---|---|
| `-eq` eşit | `=` veya `==` eşit |
| `-ne` eşit değil | `!=` eşit değil |
| `-gt -ge -lt -le` | `-z` boş mu, `-n` boş değil mi |

```bash
if [ -f /etc/passwd ]; then echo "var"; fi
if [ "$sayi" -gt 10 ]; then echo "büyük"; fi
if [ "$ad" = "ali" ]; then echo "merhaba"; fi
if [ -z "$degisken" ]; then echo "boş"; fi
```

> [!WARNING]
> **Değişkenleri neden her zaman tırnak içine almalısın — somut bir kaza senaryosu**
> `[ "$ad" = "ali" ]` yazmak yerine tırnaksız `[ $ad = "ali" ]` yazdığını
> düşün, ve `$ad` boş bir değişken olsun (tanımsız ya da boş atanmış). Bash bunu
> genişlettiğinde satır `[ = "ali" ]` haline gelir — `[` komutu (ki bu aslında
> `test` komutunun bir takma adıdır) bu sözdizimini **anlayamaz**, çünkü ilk
> argüman eksik, "eşittir" operatöründen önce karşılaştırılacak bir şey yok. Sonuç
> bir sözdizimi hatasıdır ve koşul beklenmedik şekilde davranabilir. Daha da kötüsü,
> `$ad` boşluk içeren bir değer taşıyorsa (`ad="Ali Veli"`), tırnaksız kullanım
> bunu **birden fazla argümana** böler, `[` komutu "çok fazla argüman" hatası
> verir. Tırnak içine almak (`"$ad"`), değişken boş olsa bile `[ "" = "ali" ]`
> gibi **geçerli, tek bir argümanlı** bir karşılaştırma üretir — hata yerine
> beklenen "eşit değil" sonucunu alırsın. Bu, bash betiklerinde en sık yapılan
> hatalardan biridir ve alışkanlık haline getirilmesi gereken bir kuraldır.

> ⚠️ Değişkenleri **her zaman tırnak içine al**: `[ "$ad" = "ali" ]`.
> Tırnaksız ve değişken boşsa `[ = "ali" ]` olur → sözdizimi hatası.

**`[ ]` vs `[[ ]]`:** `[[ ]]` bash'e özgüdür, daha güvenlidir (tırnaksız değişken
sorun çıkarmaz), regex destekler (`=~`), `&&` `||` içeride kullanılabilir.
Betiğin `#!/bin/bash` ise `[[ ]]` kullan.

> [!NOTE]
> **`[[ ]]`'in "daha güvenli" olması teknik olarak nereden geliyor?**
> `[` aslında bir **komuttur** (aynı zamanda `test` adıyla da çağrılabilir) — kabuk
> onu diğer komutlar gibi işler, yani argümanlarına önce **kelime bölme ve glob
> genişletme** uygulanır, bu da yukarıda gördüğün tırnak tuzaklarına yol açar.
> `[[ ]]` ise bir komut değil, bash'in kendi **sözdizimine gömülü** özel bir
> yapıdır (keyword) — bu yüzden bash, `[[ ]]` içindeki değişkenlere kelime bölme
> ve glob genişletme **uygulamaz**, tırnaksız `$ad` kullansan bile güvenlidir
> (yine de alışkanlık için tırnaklamak iyi bir pratiktir). Ayrıca `[[ ]]` gelişmiş
> özellikler sunar: `=~` operatörü ile tam regex eşleşmesi yapabilirsin (`[ ]`'de
> bu yoktur), `&&`/`||` doğrudan içeride kullanılabilir (`[ ]`'de bunun yerine
> `-a`/`-o` kullanman ya da ayrı `[ ]` blokları birleştirmen gerekirdi, ki bu
> daha hataya açıktır).

```bash
if [[ "$dosya" == *.log ]]; then ... fi          # glob eşleşmesi
if [[ "$ip" =~ ^[0-9]+\.[0-9]+ ]]; then ... fi   # regex
if [[ -f "$d" && -r "$d" ]]; then ... fi
```

**Aritmetik:**
```bash
sonuc=$((5 + 3))
((sayac++))
if (( sayi > 10 )); then ... fi     # sayısal karşılaştırmada en okunaklısı
```

> [!NOTE]
> **`$(( ))` ve `(( ))` arasındaki fark ne?**
> `$(( ))` bir **genişletmedir** — içindeki aritmetik ifadeyi hesaplayıp, **sonucu
> bir değer olarak döndürür**, bu değeri bir değişkene atayabilir ya da bir yere
> yazdırabilirsin (`sonuc=$((5+3))` gibi). `(( ))` ise bir **komuttur** — aritmetik
> ifadeyi hesaplar ama bir değer döndürmez, bunun yerine ifadenin sonucuna göre
> bir **çıkış kodu** (0 = "doğru/başarı" eğer sonuç sıfırdan farklıysa, 1 = "yanlış"
> eğer sonuç sıfırsa) üretir — bu yüzden `if` içinde doğrudan koşul olarak
> kullanılabilir (`if (( sayi > 10 ))`), tıpkı `[[ ]]` gibi. `((sayac++))` de aynı
> mantıkla, bir atama/artırma **işlemi** yapar, değer döndürmeye ihtiyaç duymaz.

### case

```bash
case "$1" in
    start)
        echo "Başlatılıyor..."
        ;;
    stop)
        echo "Durduruluyor..."
        ;;
    restart|reload)
        echo "Yeniden başlatılıyor..."
        ;;
    *)
        echo "Kullanım: $0 {start|stop|restart}" >&2
        exit 1
        ;;
esac
```

> [!NOTE]
> **`case` ne zaman `if/elif` zincirinden daha iyidir?**
> Tek bir değeri (`$1` gibi) birden fazla **sabit** olasılıkla karşılaştırıyorsan
> (`start`, `stop`, `restart`), `case` hem daha okunaklı hem bash'in glob desenlerini
> (`*`, `?`, `[abc]`) doğal olarak destekler — `restart|reload)` gibi bir satırla
> "ikisinden biri eşleşirse aynı işi yap" demek `if [ "$1" = "restart" ] || [ "$1" = "reload" ]`
> yazmaktan çok daha temizdir. Sondaki `*)` deseni her zaman eşleşir (glob'da `*`
> "her şey" demek), bu yüzden **hiçbir önceki desenle eşleşmeyen her durumu**
> yakalayan bir "varsayılan/else" görevi görür — burada genelde kullanım mesajı
> gösterip hatayla çıkmak standart bir kalıptır.

### Döngüler

```bash
# for — liste
for renk in kirmizi yesil mavi; do
    echo "$renk"
done

# for — dosyalar
for dosya in /var/log/*.log; do
    echo "İşleniyor: $dosya"
done

# for — sayı
for i in {1..10}; do echo $i; done
for ((i=0; i<10; i++)); do echo $i; done

# while — koşul
sayac=0
while [ $sayac -lt 5 ]; do
    echo $sayac
    ((sayac++))
done

# while — SATIR SATIR DOSYA OKUMA ⭐ en çok kullanacağın kalıp
while IFS= read -r satir; do
    echo "Satır: $satir"
done < dosya.txt

# until — koşul sağlanana kadar
until ping -c1 sunucu &>/dev/null; do
    echo "Bekleniyor..."
    sleep 5
done

break      # döngüden çık
continue   # sonraki tura geç
```

> [!NOTE]
> **`while IFS= read -r satir; do ... done < dosya.txt` kalıbının HER parçası neden orada?**
> Bu, satır satır dosya okumanın "doğru" yoludur ve her parçası bilinçli bir
> tuzağı önler:
> - `IFS=` (boş) — `IFS` (Internal Field Separator), bash'in bir metni kelimelere
>   nasıl böleceğini belirler, varsayılan olarak boşluk/tab/satır-sonu içerir.
>   `read` komutu satırı okurken varsayılan `IFS` ile çalışsaydı, satırın **başındaki
>   ve sonundaki boşlukları otomatik olarak kırpardı** — bu, girintili (indented)
>   satırları ya da anlamlı boşluklu veriyi bozar. `IFS=` ile bunu boşaltmak,
>   `read`'in satırı **olduğu gibi**, hiç kırpmadan almasını sağlar.
> - `-r` — `read`'in varsayılan davranışı, ters bölü (`\`) karakterini bir **kaçış
>   işareti** olarak yorumlamaktır (satır sonuna `\` koyup bir sonraki satırla
>   birleştirmek gibi). Eğer okuduğun dosyada gerçek ters bölü karakterleri varsa
>   (bir Windows dosya yolu gibi, `C:\Users\ali`), `-r` olmadan bunlar bozulur.
>   `-r` "raw" (ham) modudur — ters bölüyü özel bir karakter olarak görmez, olduğu
>   gibi okur.
> - `done < dosya.txt` — döngünün **sonuna** yönlendirme koymak (döngünün başına
>   değil), tüm `while` bloğunun stdin'ini bu dosyaya bağlar; döngü içindeki her
>   `read` çağrısı bu akıştan bir sonraki satırı çeker.
>
> Bu üçü birlikte, herhangi bir içerikteki (garip boşluklu, ters bölülü) bir
> dosyayı bile güvenle, satır satır işlemenin standart, güvenilir yoludur.

> ⚠️ `for satir in $(cat dosya)` **kullanma** — boşlukta böler, glob genişletir.
> Doğrusu yukarıdaki `while IFS= read -r` kalıbıdır.

> [!WARNING]
> **`for satir in $(cat dosya)` tam olarak nasıl bozuluyor?**
> `$(cat dosya)` önce dosyanın **tüm içeriğini** okur ve tek bir uzun metin olarak
> döndürür. Bu metin `for ... in` yapısına **tırnaksız** geçtiği için, bash ona
> normal kelime bölme ve glob genişletmesi uygular — yani metin sadece satır
> sonlarına göre değil, **her boşluk ve tab karakterine göre de** parçalanır. Bir
> satırda "İstanbul Türkiye" gibi boşluk içeren bir değer varsa, döngü bunu **iki
> ayrı** öğe olarak işler, senin "tek satır" beklentini bozar. Ayrıca dosyada `*`
> gibi bir karakter varsa, bu glob olarak genişletilmeye çalışılır — dosya
> sisteminde eşleşen dosyalar varsa, döngü öğesi beklenmedik şekilde dosya
> adlarına dönüşebilir. `while IFS= read -r` kalıbı bu iki sorunu da (kelime
> bölme ve glob genişletme) tamamen ortadan kaldırır çünkü `read` satırı bir
> bütün olarak, hiç yeniden ayrıştırmadan alır.

### Fonksiyonlar

```bash
log() {
    echo "[$(date '+%F %T')] $*"
}

hata() {
    echo "[$(date '+%F %T')] HATA: $*" >&2
    exit 1
}

kontrol_et() {
    local dosya="$1"           # local ← fonksiyon dışına sızmaz, HEP kullan
    if [[ ! -f "$dosya" ]]; then
        return 1
    fi
    return 0
}

# Kullanım
log "Başlıyor"
kontrol_et "/etc/passwd" || hata "Dosya yok"
```

Fonksiyon **değer döndürmez**, çıkış kodu döndürür (0-255). Veri döndürmek için
`echo` + `$(fonksiyon)` kullanılır.

> [!NOTE]
> **`local` neden bu kadar önemli, koymazsan ne olur?**
> Bash'te varsayılan olarak, bir fonksiyon içinde tanımladığın bir değişken
> **global** olur — yani fonksiyon bittikten sonra bile o değişken, onu çağıran
> kodun geri kalanında görünmeye devam eder. Bu, özellikle birden fazla fonksiyonun
> aynı isimde bir değişken kullandığı durumlarda (mesela her ikisi de `dosya` adlı
> bir değişken kullanıyorsa) **birbirinin değerini sessizce ezmesine** yol açar —
> bir fonksiyon çalışırken başka bir fonksiyonun beklediği değişken değeri
> beklenmedik şekilde değişmiş olabilir, bu hatayı bulmak çok zordur çünkü hiçbir
> hata mesajı vermez, sadece yanlış davranır. `local dosya="$1"` yazmak, bu
> değişkenin **sadece bu fonksiyonun içinde** var olmasını, fonksiyon bitince
> otomatik olarak yok olmasını sağlar — tıpkı programlama dillerindeki fonksiyon
> içi yerel değişkenler gibi. Ciddi bir betikte, fonksiyon içindeki her değişkeni
> `local` ile tanımlamak, istisnasız uygulanması gereken bir alışkanlık olmalıdır.

> [!NOTE]
> **"Fonksiyon değer döndürmez, çıkış kodu döndürür" ne demek, veri nasıl alırsın?**
> Diğer programlama dillerinde alıştığın `return deger` kalıbı bash'te farklı
> çalışır — `return` sadece **0-255 arası bir tam sayı** döndürebilir ve bu sayı
> geleneksel olarak "başarı/hata durumu" anlamına gelir (0 = başarı, sıfır
> olmayan = çeşitli hata kodları), gerçek bir **veri** (metin, karmaşık bir değer)
> döndürmek için tasarlanmamıştır. Bir fonksiyondan gerçek bir veri (bir metin,
> hesaplanmış bir değer) almak istediğinde, fonksiyon bu veriyi `echo` ile
> **stdout'a yazar**, sen de bu fonksiyonu çağırırken `$(fonksiyon)` komut ikamesi
> ile o stdout çıktısını yakalarsın — `sonuc=$(fonksiyon_adi arg1 arg2)` gibi.
> Bu, bash'in "her şey aslında bir komuttur, komutların çıktısı stdout'tur"
> felsefesinin doğal bir uzantısıdır: fonksiyon da bir çeşit komuttur, verisini
> aynı stdout mekanizmasıyla dışarı verir; `return`'ün ayrı, sayısal çıkış kodu
> kanalı ise sadece "başarılı mı değil mi" bilgisini taşımak için vardır.

### Kullanıcıdan girdi

```bash
read -p "Adınız: " ad
read -s -p "Parola: " parola; echo      # -s gizli
read -t 10 -p "10 sn içinde: " cevap    # zaman aşımı
```

### Çıkış kodları ve tuzaklar

```bash
exit 0      # başarı
exit 1      # genel hata

komut && echo "başarılı"      # önceki 0 dönerse
komut || echo "başarısız"     # önceki 0 dönmezse
komut1 && komut2 || komut3

# Temizlik garantisi — betik nasıl biterse bitsin çalışır
gecici=$(mktemp)
trap 'rm -f "$gecici"' EXIT
```

> [!NOTE]
> **`trap ... EXIT` neyi garanti ediyor, normal bir temizlik satırından farkı ne?**
> Bir betiğin sonunda `rm -f "$gecici"` yazmak, sadece betik **normal şekilde,
> baştan sona** çalışırsa işe yarar. Ama betik `set -e` yüzünden ortada bir yerde
> hata verip durursa, ya da kullanıcı Ctrl+C ile keserse, ya da bir sinyal
> (`kill` gibi) gelirse, betiğin **sonundaki** temizlik satırına asla ulaşılmaz —
> geçici dosya diskte terk edilmiş halde kalır. `trap 'komut' EXIT`, bash'e
> "betik hangi sebeple biterse bitsin — normal bitiş, hata, kesme, sinyal, fark
> etmez — bu komutu **mutlaka** çalıştır" der. Bu, tıpkı diğer dillerdeki
> `finally` bloğuna benzer bir garanti sağlar: kaynak temizliği (geçici dosyalar,
> kilit dosyaları, açık bağlantılar) için `trap ... EXIT`, betiğin ortasında bir
> yere `rm` yazmaktan çok daha güvenilirdir çünkü betiğin **nasıl** sonlanacağından
> bağımsız çalışır.

---

## 7. Tam örnek betik

```bash
#!/bin/bash
#
# yedek.sh — Bir dizini tarihli arşive alır, eskileri temizler
#
set -euo pipefail

KAYNAK="${1:?Kullanım: $0 <kaynak-dizin> [hedef-dizin]}"
HEDEF="${2:-/var/backups}"
SAKLAMA_GUN=7
LOG="/var/log/yedek.log"

log()  { echo "[$(date '+%F %T')] $*" | tee -a "$LOG"; }
hata() { echo "[$(date '+%F %T')] HATA: $*" | tee -a "$LOG" >&2; exit 1; }

[[ -d "$KAYNAK" ]] || hata "Kaynak dizin yok: $KAYNAK"
mkdir -p "$HEDEF" || hata "Hedef oluşturulamadı: $HEDEF"

ARSIV="$HEDEF/$(basename "$KAYNAK")-$(date +%F-%H%M).tar.gz"

log "Yedek başlıyor: $KAYNAK -> $ARSIV"

if tar -czf "$ARSIV" -C "$(dirname "$KAYNAK")" "$(basename "$KAYNAK")" 2>>"$LOG"; then
    BOYUT=$(du -h "$ARSIV" | cut -f1)
    log "Başarılı. Boyut: $BOYUT"
else
    hata "tar başarısız oldu"
fi

# Eski yedekleri temizle
SILINEN=$(find "$HEDEF" -name "*.tar.gz" -mtime +$SAKLAMA_GUN -print -delete | wc -l)
log "$SILINEN eski yedek silindi"

exit 0
```

> [!NOTE]
> **Bu betiği baştan sona, satır satır neden böyle yazıldığını anla**
> - `KAYNAK="${1:?Kullanım: ...}"` — daha önce gördüğün `:?` genişletmesi burada
>   iş başında: eğer betik hiç parametre almadan çalıştırılırsa (`$1` boşsa),
>   betik sessizce boş bir `KAYNAK` ile devam etmek yerine, anında anlamlı bir
>   hata mesajıyla durur. Bu, "zorunlu parametre" desenlerinin standart yoludur.
> - `HEDEF="${2:-/var/backups}"` — burada `:-` kullanılmış (`:?` değil), çünkü
>   hedef dizin **isteğe bağlı**: verilmezse makul bir varsayılana (`/var/backups`)
>   düşer, hata vermez.
> - `log()` ve `hata()` fonksiyonları, her mesajı **hem** ekrana **hem** log
>   dosyasına yazan (`tee -a`) ve tutarlı bir zaman damgası formatı ekleyen
>   ortak bir kalıp sağlar — her satırda tekrar tekrar `date` ve `tee` yazmak
>   yerine, tek satırlık bir fonksiyon çağrısı yeterli olur.
> - `[[ -d "$KAYNAK" ]] || hata "..."` — daha önce gördüğün `komut || komut2`
>   kalıbı: "eğer bu test **başarısız** olursa (dizin yoksa, çıkış kodu sıfırdan
>   farklı olur), hata fonksiyonunu çağır." Bu, `if` yazmadan tek satırda bir
>   ön koşul kontrolü yapmanın kısa yoludur.
> - `$(dirname "$KAYNAK")` ve `$(basename "$KAYNAK")` ile `tar -C` birlikte
>   kullanımı bilinçli bir tercih: `tar`'a doğrudan `tar -czf arsiv.tar.gz
>   $KAYNAK` deseydin, arşivin içindeki yollar `$KAYNAK`'ın tam yolunu
>   (`/etc/nginx/...` gibi) taşırdı; `-C` ile önce kaynağın **üst dizinine**
>   geçip sadece **son bileşenini** arşivlemek, arşiv içindeki yolları daha
>   temiz (göreli, sadece `nginx/...`) tutar.
> - `2>>"$LOG"` — `tar`'ın hata çıktısını log dosyasına **ekler** (append,
>   `>>`), böylece daha önceki log girdilerinin üzerine yazılmaz, sorun
>   giderirken tüm geçmiş görünür kalır.
> - `find "$HEDEF" -name "*.tar.gz" -mtime +$SAKLAMA_GUN -print -delete` —
>   `-mtime +7`, "değişim tarihi 7 günden **eski** olan" dosyaları bulur (`+`
>   işareti "den daha fazla" demektir); `-print` bulunan her dosyayı önce
>   yazdırır, `-delete` sonra siler — `-print` olmadan `wc -l` ile kaç dosya
>   silindiğini sayamazdın, çünkü `-delete`'in kendisi ekrana bir şey yazmaz.

Test:
```bash
chmod +x yedek.sh
./yedek.sh /etc /tmp/yedekler
bash -x ./yedek.sh /etc /tmp/yedekler      # adım adım izle
```

---

## 8. Kullanışlı alias'lar ve püf noktaları

```bash
alias ll='ls -alh'
alias ..='cd ..'
alias grep='grep --color=auto'
alias rm='rm -i'          # onay sor (alışkanlık kırıcı, tercih meselesi)
alias df='df -h'
alias ports='ss -tulnp'

alias                     # tanımlıları listele
unalias ll                # kaldır
\ls                       # alias'ı BYPASS et
```
Kalıcı için `~/.bashrc`'ye yaz.

> [!NOTE]
> **`\ls` başındaki ters bölü ne işe yarıyor?**
> Eğer `ls` için bir alias tanımlıysa (`alias ls='ls --color=auto'` gibi), sen
> `ls` yazdığında bash **önce alias'a bakar**, gerçek `ls` komutunu değil, alias'ın
> genişlemiş halini çalıştırır. Çoğu zaman bu istediğin davranıştır, ama bazen
> alias'ı **atlayıp orijinal komutu** çalıştırmak istersin. `\` (ters bölü) ön
> eki, bash'e "bu kelimeyi bir alias olarak değil, doğrudan gerçek komut olarak
> ara" der — bu, herhangi bir komutun önüne konarak o komutun alias'ını devre
> dışı bırakmanın standart yoludur (`\rm dosya`, `rm -i` alias'ını atlayıp
> doğrudan gerçek `rm`'i, onay sormadan çalıştırır).

**Kabuk kısayolları (kas hafızasına al):**
```
Ctrl+A / Ctrl+E    satır başı / sonu
Ctrl+U / Ctrl+K    imleçten başa / sona sil
Ctrl+W             önceki kelimeyi sil
Ctrl+L             ekranı temizle (= clear)
Ctrl+R             ⭐ geçmişte ara (bir daha bırakmazsın)
Ctrl+C / Ctrl+D    iptal / EOF-çıkış
Ctrl+Z             durdur (fg ile geri getir)
!!                 son komut          → sudo !!
!$                 son komutun son argümanı
Alt+.              aynısı
history            geçmiş
```

**`sudo !!`** — komutu sudo'suz yazdın, hata aldın. `sudo !!` yaz, tekrarlar.

> [!NOTE]
> **`!!` ve `!$` bash'in "geçmiş genişletmesi" (history expansion) özelliğinin parçası**
> `!` işaretiyle başlayan bu kısayollar, bash'in komut geçmişinden bir şey
> **çekip yerine koyma** mekanizmasıdır. `!!` "son çalıştırdığın komutun tamamı"
> demektir — `sudo !!` yazdığında bash bunu önce `sudo <son komut>` haline
> genişletir, sonra çalıştırır; `apt update` yazıp "Permission denied" aldıysan,
> tekrar tüm komutu yazmak yerine `sudo !!` ile aynı komutu başına `sudo` ekleyerek
> tekrarlarsın. `!$` ise "son komutun **son argümanı**" demektir — mesela
> `mkdir /tmp/yeni-proje` yazdıktan sonra `cd !$` yazarsan, bu `cd /tmp/yeni-proje`
> olarak genişler; yeni oluşturduğun bir dizine hemen girmek istediğinde dizin
> adını iki kere yazmaktan kurtarır.

### `history` ve numarayla komut çağırma — uzun bir komutu yeniden yazmadan çalıştırmak

```bash
history                # numaralı komut geçmişini göster, örn: 245  find / -name "*.log"
!245                    # 245 numaralı komutu AYNEN çalıştır
!245:p                  # ':p' (print) — ÇALIŞTIRMAZ, sadece komutu yazdırır (önce kontrol için)
!-3                     # şu anki konumdan 3 komut GERİYE git, onu çalıştır
!find                   # 'find' ile BAŞLAYAN en son komutu çalıştır
```
`history` çıktısındaki numarayı `!` ile birleştirmek, bash'in **history
expansion** (geçmiş genişletme) mekanizmasıdır: `!245` bir komut değil, satırı
**parse etmeden önce** uygulanan bir metin ikamesidir — bash, geçmişteki 245
numaralı komutun ham metnini oraya yapıştırıp öyle çalıştırır, sanki sen o
uzun komutu elle yeniden yazmışsın gibi.

> [!WARNING]
> **`!245` yazıp Enter'a bastığında komut **önce göstermeden,**
> doğrudan çalışır** — numarayı yanlış hatırlarsan (örn. istemeden bir
> `rm -rf` komutunu tetiklemek) geri dönüşü olmayabilir. Bunu güvenli hâle
> getiren ayar:
> ```bash
> shopt -s histverify        # ~/.bashrc'ye eklenirse kalıcı olur
> ```
> Bu açıkken `!245` yazınca komut **hemen çalışmaz** — genişletilmiş hâli
> komut satırına yazılır, sen tekrar Enter'a basmadan (istersen düzenleyerek)
> çalışmaz. Numarayı bilmiyorsan `history | grep find` ile arayabilir, ya da
> yukarıdaki `Ctrl+R` (canlı arama) ile numaraya hiç ihtiyaç duymadan aynı
> işi yapabilirsin.

---

## 🧪 Lab

1. `~/.bashrc`'ye 5 alias ve bir `PATH` eklemesi yap, `source` ile yükle.
2. `/etc/passwd`'den UID ≥ 1000 olan kullanıcıların adını ve kabuğunu **awk ile** listele.
3. `df -h` çıktısından doluluk %50 üstü bölümleri yazdıran tek satırlık komut yaz.
4. `sed -i.bak` ile `/tmp/test.conf` içindeki tüm yorum satırlarını sil, `.bak` ile `diff`le.
5. Bir dizindeki tüm `.txt` dosyalarını `.bak` uzantılı kopyalayan `for` döngüsü yaz.
6. `while IFS= read -r` kalıbıyla `/etc/passwd`'i satır satır oku, her satırdaki
   kullanıcı adını ve UID'yi bas.
7. Parametre olarak dizin alan, dizin yoksa hata verip 1 ile çıkan, varsa içindeki
   dosya sayısını basan bir betik yaz. `set -euo pipefail` kullan.
8. `case` ile `start|stop|status` alan basit bir servis kontrol betiği yaz.
9. Yukarıdaki `yedek.sh`'ı kendi makinene uyarla, çalıştır, `bash -x` ile izle.
10. Disk %80'i geçerse log'a yazan bir kontrol betiği yaz (Modül 12'de cron'a bağlayacaksın).

---

## ❓ Kendini test et

**S1.** `sudo echo "test" >> /etc/hosts` neden "Permission denied" veriyor?

<details><summary>Cevap</summary>
Yönlendirmeyi (`>>`) `sudo` değil, **kabuk** yapar ve kabuk normal kullanıcı yetkisindedir.
Doğrusu: `echo "test" | sudo tee -a /etc/hosts`.
</details>

**S2.** `#!/bin/sh` ile başlayan betiğin RHEL'de çalışıyor, Ubuntu'da `[[: not found` hatası veriyor. Neden?

<details><summary>Cevap</summary>
Ubuntu/Debian'da `/bin/sh` → `dash`. `[[ ]]` bash'e özgüdür, dash desteklemez.
RHEL'de `/bin/sh` → `bash` olduğu için sorun çıkmaz. Çözüm: shebang'i `#!/bin/bash` yap.
</details>

**S3.** `for satir in $(cat liste.txt)` neden kötü bir kalıp?

<details><summary>Cevap</summary>
Kelime bölme (word splitting) yapar: boşluk içeren satırlar parçalanır. Ayrıca `*`
içeren satırlar glob olarak genişler. Doğrusu: `while IFS= read -r satir; do ... done < liste.txt`
</details>

**S4.** `komut 2>&1 > dosya` ile `komut > dosya 2>&1` arasındaki fark?

<details><summary>Cevap</summary>
İlkinde `2>&1` çalıştığı anda stdout hâlâ terminaldir, stderr terminale gider;
sonra stdout dosyaya yönlenir. İkincisinde stdout önce dosyaya gider, sonra stderr onu
takip eder — **ikisi de dosyaya** yazılır. Doğru olan ikincisi.
</details>

**S5.** `set -e` var ama betiğin hata veren komuttan sonra devam ediyor. Muhtemel sebep?

<details><summary>Cevap</summary>
Komut bir `if`, `while`, `&&`/`||` zinciri içinde ya da pipe'ın son elemanı değil.
`set -e` bu bağlamlarda devreye girmez; pipe için `set -o pipefail` de gerekir.
</details>

---

## 📋 Hızlı referans

```bash
set -euo pipefail              # her betiğin başına
bash -x betik.sh               # adım adım izle
"${1:?Kullanım: $0 <arg>}"     # zorunlu parametre
${dosya##*/}  ${dosya%.*}      # basename / uzantı at
komut | sudo tee -a DOSYA      # sudo ile ekleme
sed -i.bak 's/a/b/g' DOSYA     # yedekli in-place
awk -F: '$3>=1000 {print $1}'  # koşullu sütun
grep -Ev "^#|^$" CONFIG        # config'in özü
while IFS= read -r s; do ... done < DOSYA
trap 'rm -f "$tmp"' EXIT       # temizlik garantisi
Ctrl+R                         # geçmişte ara
sudo !!                        # son komutu sudo ile tekrarla
```
