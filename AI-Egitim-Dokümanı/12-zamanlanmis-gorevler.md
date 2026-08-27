---
tags: [linux, egitim, cron, otomasyon]
modul: 12
durum: tamamlandi
---

# 12 — Zamanlanmış Görevler (Crontab)

> **Ön koşul:** [06-kabuk-shell](06-kabuk-shell.md)
> **Süre:** ~2 saat

## Hedefler

- [ ] Cron sözdizimini yazıp okuyabiliyorum
- [ ] Kullanıcı ve sistem crontab'ını ayırt ediyorum
- [ ] Cron'un neden "elle çalışıyor ama cron'da çalışmıyor" tuzağına düştüğünü biliyorum
- [ ] `at` ile tek seferlik görev planlayabiliyorum
- [ ] systemd timer yazabiliyorum ve cron'a göre avantajlarını biliyorum

---

## 0. Neden böyle bir araca ihtiyaç var?

Şimdiye kadar öğrendiğin her komutu **sen** çalıştırdın — terminale yazdın, Enter'a
bastın. Ama gerçek bir sunucuda, "her gece 03:00'te yedek al", "her 15 dakikada
bir disk doluluğunu kontrol et" gibi işler var — ve sen o saatte uyuyor olacaksın.
Cron (ve `at`, ve systemd timer), bu işi **senin yerine, senin belirlediğin bir
zamanda** çalıştıran bir arka plan servisidir (`crond`/`cron` daemon'ı). Sistem
açık olduğu sürece, saniyesi saniyesine, sen orada olmasan bile çalışır.

---

## 1. Cron sözdizimi — beş alanı, birer birer

Cron satırı, ilk beş alanda "**ne zaman**" bilgisini, sonrasında da "**ne
çalıştırılacağını**" taşır. Alanların sırası **sabittir**, asla değişmez:

```
┌───────────── dakika       (0-59)
│ ┌─────────── saat         (0-23)
│ │ ┌───────── ayın günü    (1-31)
│ │ │ ┌─────── ay           (1-12)
│ │ │ │ ┌───── haftanın günü (0-7, 0 ve 7 = Pazar)
│ │ │ │ │
* * * * *  çalıştırılacak komut
```

Sırayı hatırlamanın kolay yolu: soldan sağa **küçükten büyüğe** gidiyorsun —
dakika (en küçük birim) → saat → gün → ay → haftanın günü (en "geniş" kavram,
çünkü hafta ay ve günü aşan bir kavram). Her alana koyduğun değer, "bu alan
şu değere **eşit olduğunda** çalıştır" anlamına gelir; `*` ise "bu alanın
değeri ne olursa olsun, fark etmez" demektir.

| Operatör | Anlamı | Örnek |
|---|---|---|
| `*` | "Her değer" — bu alanda fark etmez | `* * * * *` → her dakika (hiçbir alan kısıtlamıyor) |
| `,` | Liste — birden fazla belirli değer | `0 8,12,18 * * *` → sadece 08:00, 12:00 ve 18:00 |
| `-` | Aralık — başlangıç-bitiş arası her değer | `0 9-17 * * *` → 09:00'dan 17:00'a kadar her saat başı |
| `/` | Adım — belirli aralıklarla tekrar | `*/15 * * * *` → 0, 15, 30, 45. dakikalarda (15 dakikada bir) |

### Örnekleri satır satır çöz

```cron
*/5 * * * *      komut     # dakika alanı "her 5'te bir" → 5 dakikada bir çalışır
0 * * * *        komut     # dakika=0, geri kalan * → her saatin 0. dakikasında = her saat başı
30 2 * * *       komut     # dakika=30, saat=2 → her gece 02:30
0 3 * * 0        komut     # dakika=0, saat=3, haftanın günü=0(Pazar) → her Pazar 03:00
0 0 1 * *        komut     # dakika=0, saat=0, ayın günü=1 → her ayın 1'inde gece yarısı
0 9-17 * * 1-5   komut     # saat 9'dan 17'ye, haftanın günü 1(Pazartesi)'den 5(Cuma)'ya → hafta içi mesai saatleri, her saat başı
15 2 1,15 * *    komut     # ayın günü listesi: 1 VEYA 15 → her ayın 1'i ve 15'i, saat 02:15
*/10 8-18 * * 1-5 komut    # hafta içi, 08-18 saatleri arasında, 10 dakikada bir
```

### Özel kısayollar — sık kullanılan kalıplar için hazır isimler

```cron
@reboot     komut     # her sistem açılışında BİR KEZ çalışır ⭐ (belirli bir zaman değil, "olay")
@hourly     komut     # = 0 * * * *  (her saat başı)
@daily      komut     # = 0 0 * * *  (her gece yarısı)
@weekly     komut     # = 0 0 * * 0  (her Pazar gece yarısı)
@monthly    komut     # = 0 0 1 * *  (her ayın ilk günü gece yarısı)
@yearly     komut     # = 0 0 1 1 *  (her yılın ilk günü)
```

`@reboot` diğerlerinden farklıdır — bir "zaman" değil, bir "**olay**" tanımlar.
Sistem her açıldığında (ya da cron servisi her yeniden başladığında) bir kez
tetiklenir. Açılışta otomatik başlaması gereken küçük bakım görevleri için
kullanışlıdır.

> [!WARNING]
> **En kafa karıştırıcı cron davranışı: gün VE haftanın-günü birlikte yazılırsa**
> Normalde tüm alanlar **VE (AND)** mantığıyla birleşir — "bu VE şu VE öbürü de
> doğruysa çalıştır". Ama **ayın günü** ile **haftanın günü** alanları birlikte,
> ikisi de `*` olmadan yazılırsa, cron aralarında istisnai olarak **VEYA (OR)**
> mantığı uygular.
>
> `0 0 13 * 5` şu demektir: "her ayın **13'ünde** VEYA her **Cuma**" — yani ayın
> 13'ü de çalışır, o hafta Cuma da çalışır, bunlar **iki ayrı, bağımsız
> tetiklenme**dir. Bunu "ayın 13'üne denk gelen Cuma günü" (yani her ikisinin
> AYNI ANDA doğru olduğu, nadir gün) sanmak en yaygın cron hatasıdır.
> Eğer gerçekten "13'üne denk gelen Cuma" istiyorsan, cron sözdizimiyle bunu
> doğrudan ifade edemezsin — betiğin içine `date +%d` ve `date +%u` kontrolü
> eklemen gerekir.

Sözdizimini elle hesaplamak yerine doğrulamak istersen: `crontab.guru` sitesi
(çevrimdışıysan yukarıdaki tabloyu referans al).

---

## 2. Kullanıcı crontab'ı — her kullanıcının kendi görev listesi

Her kullanıcının **kendine ait** bir crontab dosyası vardır; `root`un crontab'ı
`ali`nin crontab'ından tamamen bağımsızdır, birbirini görmez.

```bash
crontab -e            # ⭐ kendi crontab'ını düzenle ($EDITOR ile açılır)
crontab -l            # listele (list)
crontab -r            # ⚠️ TÜMÜNÜ SİL — hiçbir onay sormaz!
crontab -i -r         # silmeden önce sor (-i = interactive)
sudo crontab -u ali -e  # başka bir kullanıcının crontab'ını düzenle
sudo crontab -u ali -l
```

> [!WARNING]
> **`-r` ile `-e` klavyede yan yana — bu gerçek bir tehlike**
> `crontab -e` yazayım derken parmak kayıp `crontab -r` yazarsan, **hiçbir
> onay istemeden** tüm görev listen anında silinir, geri alınamaz. Bunun tek
> pratik çözümü **alışkanlık**: crontab'ını düzenli olarak bir dosyaya da
> yedekle ve o dosyayı sürüm kontrolüne (git gibi) koy:
> ```bash
> crontab -l > ~/crontab.yedek
> ```
> Böylece `-r` felaketi olsa bile, `crontab ~/crontab.yedek` ile eski haline
> saniyeler içinde dönebilirsin.

Crontab dosyasının gerçek konumu: `/var/spool/cron/ali` (RHEL ailesi) veya
`/var/spool/cron/crontabs/ali` (Debian ailesi). **Bu dosyayı asla doğrudan bir
editörle açıp düzenleme** — `crontab -e` kullan, çünkü o komut dosyayı
kaydettiğinde hem sözdizimi hatası olup olmadığını kontrol eder hem de cron
servisine "bu kullanıcının listesi değişti, yeniden oku" diye haber verir.
Dosyayı elle değiştirirsen cron bundan haberdar olmayabilir.

`$EDITOR` değişkenini değiştirmek istersen (hangi metin editörünün açılacağını
belirler — [06-kabuk-shell](06-kabuk-shell.md)'de `export` kavramını işlemiştik):
```bash
export EDITOR=vim
echo 'export EDITOR=vim' >> ~/.bashrc
```

---

## 3. Sistem crontab'ı — "hangi kullanıcı olarak çalışsın" bilgisi ekleniyor

Kullanıcı crontab'ı sadece kendi kullanıcısı için çalışır. Ama sistem genelinde,
farklı kullanıcılar adına çalışması gereken görevler için ayrı bir mekanizma var:

```bash
sudo vi /etc/crontab
```
```
# dakika saat gün ay hafta  KULLANICI  komut
0 3 * * *                    root       /usr/local/bin/yedek.sh
```

> [!WARNING]
> **Tek yapısal fark: bir sütun daha var**
> Kullanıcı crontab'ında (`crontab -e` ile açtığın) **kullanıcı alanı yoktur** —
> zaten senin kendi kullanıcın olarak çalışacağı bellidir. Ama `/etc/crontab` ve
> `/etc/cron.d/*` dosyalarında zaman alanlarından hemen sonra **hangi kullanıcı
> olarak çalıştırılacağı** yazılır. Bu iki formatı karıştırıp kullanıcı sütununu
> unutursan, cron o sütunu komutun bir parçası (ilk kelimesi) sanır ve genelde
> "command not found" hatası verir — çünkü `root` diye bir komut çalıştırmaya
> çalışır.
> crontab 



### Hazır dizinler — paket yöneticilerinin kullandığı yol

```
/etc/cron.d/          # ayrı dosyalar, kullanıcı alanı İÇEREN format ⭐ paketler genelde burayı kullanır
/etc/cron.hourly/     # saatlik çalışacak BETİKLER — dikkat, cron satırı DEĞİL
/etc/cron.daily/
/etc/cron.weekly/
/etc/cron.monthly/
```

Bir paket kurduğunda (örneğin `logrotate`), o paket kendi zamanlanmış görevini
senin kişisel crontab'ına yazmaz — `/etc/cron.d/` altına kendi dosyasını bırakır.
Bu, paketlerin birbirinin crontab'ını bozmadan kendi görevlerini eklemesini sağlar.

`cron.daily` gibi dizinler ise **crontab satırı değil, doğrudan çalıştırılabilir
betik** bekler:
```bash
sudo cp temizlik.sh /etc/cron.daily/temizlik
sudo chmod +x /etc/cron.daily/temizlik
sudo run-parts --test /etc/cron.daily     # hangi betiklerin çalışacağını, gerçekten çalıştırmadan gör
```
> [!WARNING]
> **Betiğin uzantısı olmamalı**
> `run-parts` (bu dizinlerdeki betikleri sırayla çalıştıran araç), `.sh`, `.bak`,
> `.disabled` gibi uzantılı dosyaları **bilerek atlar** — özellikle Debian'da bu
> davranış katıdır. Yani `temizlik.sh` diye bir dosya koyarsan hiç çalışmaz,
> sessizce atlanır. Dosya adı uzantısız olmalı: `temizlik`.

### anacron — "sunucu kapalıyken kaçırılan görev ne olacak?"

Standart cron, belirlediğin saatte makine **kapalıysa**, o çalıştırmayı basitçe
**atlar ve bir daha telafi etmez** — 03:00'teki yedek görevi, makine o saatte
kapalıysa o gün hiç çalışmamış olur. `anacron`, bu boşluğu doldurur: makine
tekrar açıldığında, "kaçırdığım günlük/haftalık görevler var mı" diye kontrol
eder ve varsa onları o an çalıştırır. Bu, özellikle sürekli açık kalmayan
dizüstü bilgisayarlarda ya da düzenli kapatılan test makinelerinde önemlidir.
Yapılandırması `/etc/anacrontab` içindedir.

### Erişim kontrolü — kim crontab kullanabilir?

```
/etc/cron.allow    # bu dosya varsa: SADECE içinde listelenen kullanıcılar crontab kullanabilir
/etc/cron.deny     # cron.allow YOKSA: bu dosyada listelenenler crontab KULLANAMAZ
```
Çok kullanıcılı bir sunucuda, her kullanıcının kendi başına zamanlanmış görev
eklemesini istemiyorsan (örneğin sadece adminlerin), bu iki dosyayla kontrol
edersin.

---

## 4. Cron tuzakları — "elle çalışıyor, cron'da çalışmıyor"

Bu cümle, cron ile ilgili yaşanan sorunların **büyük çoğunluğunun** ortak
başlangıç noktasıdır. Sebep neredeyse her zaman aynıdır: **cron, senin
interaktif terminal oturumunla aynı ortamda çalışmaz.** Sen bir terminal
açtığında, kabuğun (`bash`) `~/.bashrc`, `~/.profile` gibi dosyaları okuyup
zengin bir ortam (PATH, değişkenler, alias'lar) kurar. Cron ise bunların
**hiçbirini okumadan**, çok yalın/minimal bir ortamda betiğini çalıştırır.
Aşağıdaki altı tuzak, bu tek temel gerçeğin farklı görünümleridir.

### Tuzak 1: PATH farklı ⭐ en yaygın tuzak

Cron çok dar bir PATH ile çalışır — genelde sadece `/usr/bin:/bin`. Senin kendi
kabuğunda `echo $PATH` çalıştırdığında görebileceğin `/usr/local/bin`,
`~/.local/bin`, `/opt/...` gibi ek dizinler cron'un PATH'inde **yoktur**. Bu
yüzden sen terminalde `yedek.sh` yazınca çalışan bir komut, cron içinde "böyle
bir komut bulunamadı" hatası verebilir — cron o dosyanın nerede olduğunu
bilmiyordur.

```cron
# ✗ YANLIŞ — cron "yedek.sh" adında bir komutu PATH'inde arar, bulamayabilir
0 3 * * * yedek.sh

# ✓ DOĞRU — mutlak (tam) yol, aramaya gerek bırakmaz
0 3 * * * /usr/local/bin/yedek.sh

# ✓ ya da crontab dosyasının en başında kendi PATH'ini tanımla
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
0 3 * * * yedek.sh
```
**Altın kural: cron satırlarında her zaman mutlak yol kullan** — hem çalıştırılan
komut hem de o komutun okuyacağı/yazacağı dosyalar için.

### Tuzak 2: Ortam değişkenleri yok

`~/.bashrc` ve `~/.bash_profile` cron tarafından **hiç okunmaz**. Bu dosyalarda
tanımladığın `JAVA_HOME`, `PYTHONPATH`, dil ayarı (`LANG`), Python sanal ortamının
(`venv`) yolu — bunların hiçbiri cron'un çalıştırdığı sürece otomatik gelmez.

```cron
# Betiğin içinde gerekli değişkenleri tanımla, ya da profili "kaynak göster" (source):
0 3 * * * . /home/ali/.profile && /home/ali/betik.sh
0 3 * * * /opt/venv/bin/python /opt/app/gorev.py     # venv'in python'unu DOĞRUDAN, tam yolla çağır
```

### Tuzak 3: `%` işareti cron'da özeldir

Normal kabukta `%` sıradan bir karakterdir. Ama cron satırında `%` **yeni satır**
anlamına gelir — komutun geri kalanını farklı yorumlar.

```cron
# ✗ çalışmaz — %Y-%m-%d cron tarafından "yeni satır" olarak parçalanır
0 3 * * * echo $(date +%Y-%m-%d) >> /tmp/log

# ✓ doğru — % işaretini ters eğik çizgiyle kaçır (09-disk-yonetimi'ndeki \ mantığının aynısı)
0 3 * * * echo $(date +\%Y-\%m-\%d) >> /tmp/log
```
> **En temiz, en güvenli çözüm:** Cron satırına hiç karmaşık komut yazma. Ayrı
> bir betik dosyası yaz, cron'dan sadece o betiği çağır. Böylece `%` gibi cron'a
> özgü kaçış kurallarını hiç düşünmene gerek kalmaz, betiği elle çalıştırıp test
> etmek de kolaylaşır.

### Tuzak 4: Çıktı sessizce kaybolur

Cron, çalıştırdığı komutun çıktısını (hem normal çıktıyı hem hata mesajlarını —
[09-disk-yonetimi](09-disk-yonetimi.md)'de gördüğümüz stdout/stderr ayrımını hatırla) o kullanıcıya
**e-posta olarak göndermeye çalışır**. Sunucuda çalışan bir mail sistemi yoksa
(çoğu modern sunucuda yoktur), bu e-posta hiçbir yere ulaşmaz — çıktı da hata da
sessizce kaybolur. Görevin başarısız olduğunu **fark bile etmezsin**.

```cron
MAILTO=ali@ornek.com                      # bu adrese e-posta gönder
MAILTO=""                                 # e-posta gönderme (mail sistemi yoksa anlamsız uyarı üretmesin diye)

0 3 * * * /betik.sh >> /var/log/betik.log 2>&1   # ⭐ hem çıktıyı hem hatayı log dosyasına yaz
0 3 * * * /betik.sh > /dev/null 2>&1              # tamamen sustur — DİKKAT, hatalar da kaybolur!
```
**Öneri:** Her cron görevinin çıktısını mutlaka bir log dosyasına yönlendir
(`>> log 2>&1`). "Sessizce başarısız olma" ihtimalini bu tek satır ortadan kaldırır.

### Tuzak 5: Satır sonu ve dosyanın son satırı

Crontab dosyası **son satırın sonunda bir yeni satır (newline) karakteri** ile
bitmelidir. Eğer dosyanın en son satırında bu karakter yoksa, bazı cron
sürümleri o son satırı hiç okumaz, sessizce yok sayar. `crontab -e` ile
düzenlersen editör bunu genelde otomatik halleder; ama bir crontab dosyasını
başka bir araçla (script, kopyala-yapıştır) oluşturuyorsan bu detaya dikkat et.

### Tuzak 6: Saat dilimi (timezone) beklenmedik olabilir

Cron, **sistemin ayarlı olduğu saat dilimini** kullanır — senin kendi bilgisayarının
saat dilimini değil. Sunucu UTC olarak ayarlıysa ve sen yerel saatinle (örneğin
UTC+3) düşünüp `0 3 * * *` yazdıysan, bu aslında yerel saatle 06:00'da çalışır,
senin sandığın 03:00'te değil.
```bash
timedatectl     # sistemin hangi saat diliminde olduğunu gösterir
```

### Hata ayıklama — "gerçekte ne oldu, neden çalışmadı?"

```bash
# Cron gerçekten tetiklendi mi, sistem loguna bak
sudo journalctl -u crond -f          # RHEL
sudo journalctl -u cron -f           # Debian
sudo grep CRON /var/log/syslog       # Debian
sudo grep CRON /var/log/cron         # RHEL

# ⭐ Cron'un çalıştırdığı minimal ortamı birebir taklit ederek betiğini test et
env -i /bin/sh -c '/usr/local/bin/betik.sh'
```
**`env -i /bin/sh -c '...'` ne yapıyor?** `env -i` neredeyse tüm ortam
değişkenlerini temizler (boş bir ortam başlatır), `/bin/sh -c` de betiği
`bash` yerine daha yalın bir kabukla çalıştırır — cron'un gerçek çalışma
koşullarına oldukça yakın bir simülasyon kurar. Betiğin terminalinde çalışıp bu
komutla çalışmadığını görürsen, sorunun kaynağının **ortam farkı** olduğunu
kanıtlamış olursun.

```bash
# Cron'un GERÇEKTEN gördüğü ortamı doğrudan yakalamak istersen:
* * * * * env > /tmp/cron-env.txt
# Bir dakika bekle, sonra kendi ortamınla karşılaştır:
diff <(env | sort) <(sort /tmp/cron-env.txt)
```
Bu, en kesin teşhis yöntemidir — tahmin etmek yerine cron'un gördüğü gerçek
ortamı elinle karşılaştırırsın.

---

## 5. `at` — tek seferlik görev (cron'dan farkı: TEKRARLAMAZ)

Cron, **düzenli tekrar eden** görevler için tasarlanmıştır (her gün, her hafta...).
`at` ise tam tersi bir ihtiyacı çözer: "bu görevi **bir kez**, belirli bir zamanda
çalıştır, sonra unut." Örnek: "bu gece 22:00'de bir bakım komutu çalışsın, ama bu
sadece bu geceye özel, her gece tekrarlanmasın."

```bash
sudo dnf install at ; sudo systemctl enable --now atd
sudo apt install at ; sudo systemctl enable --now atd

at 22:00
> /usr/local/bin/bakim.sh
> <Ctrl+D>

at now + 2 hours
at 09:00 tomorrow
at 14:00 next friday
at 10:00 2026-09-01

echo "/betik.sh" | at 03:00           # etkileşimli girmeden, tek satırda tanımlama

atq                                    # bekleyen (henüz çalışmamış) işleri listele
atrm 5                                 # kuyruktaki 5 numaralı işi iptal et
at -c 5                                # 5 numaralı işin tam olarak ne çalıştıracağını göster
```

`at` da cron'la aynı ortam sorunlarını yaşayabilir (mutlak yol kullanmak burada
da geçerlidir). Ancak önemli bir fark var: `at`, işi **tanımladığın anda**
mevcut ortam değişkenlerinin bir **kopyasını saklar** ve iş çalıştığında o
kopyayı kullanır — cron'un aksine, sıfırdan minimal bir ortamla başlamaz.

**`batch`** — "sistem müsait olduğunda çalıştır" (yük düşünce):
```bash
echo "/agir-is.sh" | batch
```
Bu, ağır bir işi belirli bir saate değil, **sistem yükü düşük olduğu ilk ana**
erteler — sistem meşgulken kaynak kapmasını önlemek için kullanışlıdır.

---

## 6. systemd timer — cron'un modern alternatifi

> Orijinal kurs bunu içermiyordu ama sahada giderek daha sık karşına çıkacak.
> RHEL 9'da bazı yerleşik bakım görevleri artık cron satırı olarak değil,
> timer olarak tanımlı geliyor.

**Neden ayrıca bir sistem daha öğreniyoruz, cron yetmiyor mu?** Cron basit ve
her yerde çalışır, ama bazı ihtiyaçları hiç karşılamaz: görevin loglarını takip
etmek (mail'e güvenmeden), görevin bir öncekine bağımlı olmasını sağlamak,
görevin ne kadar CPU/bellek kullanacağını sınırlamak gibi. systemd zaten her
modern dağıtımda servisleri yönetmek için var olduğundan, aynı altyapıyı
zamanlama için de kullanmak mantıklı oldu.

### İki ayrı dosya gerekir — "ne çalışacak" ile "ne zaman çalışacak" ayrılır

Cron'da tek satırda hem "ne zaman" hem "ne" bilgisi vardı. systemd timer'da
bu ikisi **bilinçli olarak ayrılır**: bir `.service` dosyası "ne çalışacağını"
tanımlar, bir `.timer` dosyası da "ne zaman tetikleneceğini" tanımlar ve o
service dosyasına işaret eder.

**`/etc/systemd/system/yedek.service`** — "ne çalışacak"
```ini
[Unit]
Description=Gunluk yedekleme

[Service]
Type=oneshot
User=root
Environment="PATH=/usr/local/bin:/usr/bin:/bin"
ExecStart=/usr/local/bin/yedek.sh /etc /var/backups
```
`Type=oneshot`, bu servisin sürekli çalışan bir arka plan süreci değil, "başlar,
işini yapar, biter" tipinde bir görev olduğunu belirtir — tam cron görevlerinin
doğasına uyar. `Environment=` satırı, cron'un Tuzak 1'de yaşadığın "dar PATH"
sorununu **açıkça, görünür şekilde** çözmeni sağlar — burada ortam tahmine
bağlı değil, dosyada yazılı.

**`/etc/systemd/system/yedek.timer`** — "ne zaman çalışacak"
```ini
[Unit]
Description=Gunluk yedeklemeyi 03:00'te calistir

[Timer]
OnCalendar=*-*-* 03:00:00
Persistent=true              # kaçırılan çalıştırmayı telafi et (anacron'un yaptığının aynısı)
RandomizedDelaySec=300       # 0-5 dakika arası rastgele gecikme ekle (yük dağıtımı)

[Install]
WantedBy=timers.target
```
`Persistent=true`, sistem 03:00'te kapalıysa, bir sonraki açılışta kaçırılan
çalıştırmayı telafi eder — yani `anacron`'un çözdüğü sorunu systemd'nin kendi
içinde çözmüş oluyorsun, ayrı bir araca ihtiyaç duymadan.
`RandomizedDelaySec`, yüzlerce sunucun aynı anda (tam 03:00:00'da) aynı işi
yapmaya kalkışıp merkezi bir kaynağı (örneğin bir yedekleme sunucusunu)
boğmasını önlemek için her sunucuya rastgele birkaç dakikalık bir gecikme
ekler.

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now yedek.timer

systemctl list-timers --all              # ⭐ tanımlı tüm timer'lar, her birinin bir sonraki çalışma zamanı
systemctl status yedek.timer
sudo systemctl start yedek.service       # ⭐ ELLE, HEMEN çalıştır — cron'da bu kadar kolay değildi
journalctl -u yedek.service -f           # loglar doğrudan journald'de — mail derdi yok
```

**`systemctl start yedek.service` neden önemli bir kolaylık?** Cron'da bir
görevi test etmek için ya saatinin gelmesini beklerdin ya da geçici olarak
zamanı "şimdi"ye çekip test edip sonra geri alırdın. systemd'de servis ve
zamanlama ayrı olduğu için, zamanlamaya hiç dokunmadan sadece `.service`'i
elle tetikleyip anında test edebilirsin.

### `OnCalendar` sözdizimi — cron'a göre daha okunaklı

```
OnCalendar=hourly | daily | weekly | monthly
OnCalendar=*-*-* 03:00:00           # her gün 03:00
OnCalendar=Mon *-*-* 09:00:00       # her Pazartesi 09:00
OnCalendar=*-*-01 00:00:00          # her ayın 1'i
OnCalendar=*-*-* *:0/15             # 15 dakikada bir
OnBootSec=5min                      # açılıştan 5 dakika sonra (belirli saatte değil, "olaydan sonra")
OnUnitActiveSec=1h                  # bu servis son çalıştığından 1 saat sonra tekrar çalıştır
```
`OnBootSec` ve `OnUnitActiveSec`, cron'da hiç karşılığı olmayan bir esneklik
sunar: "belirli bir saatte değil, belirli bir **olaydan (açılış, önceki
çalıştırma) sonraki bir süre geçince**" çalıştırma imkânı.

```bash
systemd-analyze calendar "Mon *-*-* 09:00:00"    # ⭐ yazdığın sözdizimini DOĞRULA + bir sonraki gerçek tetiklenme zamanını gör
```
Bu komut, cron'da olmayan bir güvenlik ağıdır — sözdizimini yanlış yazıp
yanlış zamanda çalışmasını (ya da hiç çalışmamasını) beklemek yerine, dosyayı
kaydetmeden **önce** doğrulayabilirsin.

### Neden timer, neden cron? — ne zaman hangisini seçmelisin

| | cron | systemd timer |
|---|---|---|
| Kurulum kolaylığı | ✅ Tek satır | ❌ İki dosya yazman gerekir |
| Log | ❌ Mail'e bağımlı / elle yönlendirme şart | ✅ `journalctl -u` ile hazır, aranabilir |
| Kaçırılanı telafi | ❌ Ancak ayrı bir araçla (anacron) | ✅ Yerleşik: `Persistent=true` |
| Elle test | ❌ Zaman ayarını geçici değiştirmek gerekir | ✅ `systemctl start x.service` ile anında |
| Bağımlılık (X bitince çalış) | ❌ Yok | ✅ `After=`, `Requires=` ile tanımlanır |
| Kaynak sınırı | ❌ Yok | ✅ `MemoryMax=`, `CPUQuota=` ile sınırlanabilir |
| Yük dağıtımı (rastgele gecikme) | ❌ Yok | ✅ `RandomizedDelaySec=` |
| Her sistemde var mı | ✅ Neredeyse her Unix/Linux'ta | ✅ systemd'li her modern dağıtımda |

**Pratik karar kuralı:** Basit, tek satırlık, tekrarlayan bir iş için (log
temizleme, basit bir betik çağırma) cron hâlâ yeterli ve hızlıdır — iki dosya
yazmaya değmez. Ama loglama, başka bir servise bağımlılık, kaçırılan çalıştırmayı
telafi etme veya kaynak sınırlama gerekiyorsa, ya da bu kritik bir üretim görevi
ise, systemd timer tercih edilmelidir — özellikle yeni yazdığın önemli
otomasyonlar için.

---

## 🧪 Lab

1. Her dakika tarih yazan bir cron görevi ekle (`* * * * * /bin/date >> /tmp/cron.log 2>&1`),
   5 dakika bekle, log'u kontrol et, sonra sil.
2. `~/yedek.sh` adında `/etc`'yi yedekleyen bir betik yaz (Modül 06'daki `yedek.sh`'ı kullan).
   Cron'a **göreli yolla** (`yedek.sh`) ekle — çalışmadığını gör. Mutlak yola çevir — çalıştığını gör.
   Bu deneyi bilerek yaşa, unutmazsın.
3. `env -i /bin/sh -c '/home/$USER/yedek.sh'` ile betiğini cron ortamında test et.
   Eksik değişken varsa betiğin başında tanımla.
4. Geçici bir `* * * * * env > /tmp/cron-env.txt` satırıyla cron ortamını yakala,
   kendi `env` çıktınla `diff`le. Farkları listele.
5. `%` içeren bir tarih komutunu cron'a ekle, kaçırmadan çalışmadığını gör, `\%` ile düzelt.
6. `/etc/cron.daily/` altına uzantısız, çalıştırılabilir bir temizlik betiği koy.
   `run-parts --test /etc/cron.daily` ile doğrula.
7. `at now + 5 minutes` ile bir görev planla, `atq` ile gör, `at -c` ile içeriğini incele.
8. Aynı yedekleme görevini **systemd timer** olarak kur (`.service` + `.timer`).
   `systemctl list-timers` ile sonraki çalışma zamanını gör.
9. Timer'ı `systemctl start yedek.service` ile elle çalıştır, `journalctl -u yedek.service`
   ile loglarını oku. Cron'daki log derdiyle karşılaştır.
10. `systemd-analyze calendar "*-*-* 03:00:00"` ile sözdizimini doğrula.
11. Modül 06'da yazdığın disk kontrol betiğini 15 dakikada bir çalışacak şekilde zamanla,
    çıktısını `/var/log/disk-kontrol.log`'a yönlendir.

---

## ❓ Kendini test et

**S1.** Betiğin elle çalışıyor ama cron'dan çalışmıyor. İlk üç şüphelin?

<details><summary>Cevap</summary>
1. **PATH** — cron dar bir PATH kullanır, mutlak yol gerekir.
2. **Ortam değişkenleri** — `.bashrc`/`.profile` okunmaz.
3. **İzinler / kullanıcı** — betik çalıştırılabilir mi, hangi kullanıcı olarak çalışıyor.
Test yöntemi: `env -i /bin/sh -c '/yol/betik.sh'`
</details>

**S2.** `0 0 13 * 5` ne zaman çalışır?

<details><summary>Cevap</summary>
Her ayın 13'ünde **veya** her Cuma. "13'üne denk gelen Cuma" **değil**.
Gün-ay ve haftanın-günü alanları birlikte yazıldığında cron VEYA mantığı uygular.
</details>

**S3.** `0 3 * * * echo $(date +%F) >> /tmp/log` neden çalışmaz?

<details><summary>Cevap</summary>
`%` cron'da özel karakterdir (yeni satır anlamına gelir). `\%` ile kaçırılmalı:
`echo $(date +\%F)`. Daha temiz çözüm: komutu betiğe koyup cron'dan betiği çağırmak.
</details>

**S4.** Sunucu her gece 02:00–04:00 arası bakım için kapalı. `0 3 * * *` görevin ne olur?

<details><summary>Cevap</summary>
Cron o çalıştırmayı **atlar ve telafi etmez**. Çözümler: `anacron` kullanmak,
saati değiştirmek, veya `Persistent=true` ayarlı bir systemd timer'a geçmek.
</details>

**S5.** Cron görevinin çıktısını neden bir dosyaya yönlendirmelisin?

<details><summary>Cevap</summary>
Cron çıktıyı kullanıcıya mail atmaya çalışır. Mail sistemi kurulu değilse çıktı ve
hatalar kaybolur — görev sessizce başarısız olur, haberin bile olmaz.
`>> /var/log/gorev.log 2>&1` ile hem çıktıyı hem hataları kaydet.
</details>

---

## 📋 Hızlı referans

```bash
crontab -e|-l              # düzenle / listele  (-r TÜMÜNÜ SİLER!)
crontab -l > ~/cron.yedek  # yedekle

# dak saat gün ay hafta  komut
*/15 * * * *   /mutlak/yol/betik.sh >> /var/log/betik.log 2>&1
0 3 * * *      ...         # her gece 03:00
0 3 * * 0      ...         # her Pazar 03:00
@reboot        ...         # her açılışta
# %  →  \%   |  MAILTO=""  |  PATH=... crontab başında

/etc/crontab , /etc/cron.d/*     # kullanıcı ALANLI
/etc/cron.{hourly,daily,weekly}/ # uzantısız, +x betikler

env -i /bin/sh -c '/yol/betik.sh'      # cron ortamını taklit et
journalctl -u crond|cron -f            # cron çalıştı mı

at 22:00 ; atq ; atrm N

# systemd timer
systemctl list-timers --all
systemctl start ISIM.service           # elle test
journalctl -u ISIM.service -f
systemd-analyze calendar "*-*-* 03:00:00"
```
