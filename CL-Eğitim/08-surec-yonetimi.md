---
tags: [linux, egitim, surec, systemd]
modul: 08
durum: tamamlandi
---

# 08 — Süreç Yönetimi

> **Ön koşul:** [06-kabuk-shell](06-kabuk-shell.md)
> **Süre:** ~3 saat

## Hedefler

- [ ] Süreç, PID, PPID ve süreç durumlarını anlıyorum
- [ ] Süreç listeleyip filtreleyebiliyorum
- [ ] Doğru sinyalle süreç sonlandırabiliyorum
- [ ] Öncelik (nice) ayarlayabiliyorum
- [ ] Arka plan işleri ve `nohup`/`screen`/`tmux` kullanabiliyorum
- [ ] systemd ile servis yönetebiliyorum

---

## 1. Süreç kavramı

**Benzetme:** Bir program, diskte duran bir **tarif** (yemek tarifi) gibidir —
kendi başına hiçbir şey yapmaz, sadece "şu adımları şu sırayla uygula" diye
yazılı bir talimattır. **Süreç (process)** ise o tarifin fiilen **mutfakta
uygulanmaya başlanmış hâlidir** — malzemeler (bellek) ayrılmış, ocak (CPU)
tahsis edilmiş, adım adım ilerleyen canlı bir iştir. Aynı tarifi (aynı programı)
aynı anda birden fazla mutfakta (birden fazla süreç olarak) uygulayabilirsin —
mesela iki farklı terminalde aynı anda iki `bash` çalıştırman gibi; ikisi de
aynı "tarife" dayanır ama birbirinden bağımsız, ayrı süreçlerdir.

**Süreç (process):** Çalışan bir programın bellekteki örneği. Program diskte durur,
süreç RAM'de çalışır. Aynı programdan birden çok süreç olabilir.

Her sürecin:
- **PID** — benzersiz süreç numarası
- **PPID** — kendisini başlatan sürecin PID'i
- Sahibi (UID/GID), önceliği, açık dosyaları, bellek alanı vardır.

**PID neden benzersiz olmalı?** Çünkü sistemin, "kill 4521 komutunu çalıştır"
dediğinde tam olarak **hangi** çalışan işi kastettiğini bilebilmesi gerekir.
Eğer iki süreç aynı PID'e sahip olsaydı, sistem hangisini hedeflediğini
bilemezdi. PID'ler sınırlı bir sayı havuzundan (genelde 0-4194304 arası)
atanır ve bir süreç bittiğinde onun PID'i havuza geri döner, başka bir süreç
tarafından yeniden kullanılabilir — bu yüzden aynı PID numarasını bugün bir
programda, yarın tamamen başka bir programda görebilirsin.

**PPID ne işe yarar?** Linux'ta hiçbir süreç "kendiliğinden" doğmaz — her
süreç, zaten çalışan başka bir süreç tarafından, `fork()` denen bir sistem
çağrısıyla "çoğaltılarak" oluşturulur (yeni doğan süreç, onu doğuran sürecin
neredeyse birebir kopyasıdır, sonra genelde farklı bir programı çalıştırmak
üzere kendini değiştirir — buna `exec()` denir). PPID, "beni kim doğurdu"
bilgisidir ve bu ilişkiler zinciri bir **ağaç** oluşturur.

**Süreç ağacı:** Her süreç bir başkası tarafından başlatılır (`fork`).
En tepede **PID 1** vardır — modern sistemlerde `systemd`, eskiden `init`.

PID 1'in özel olmasının sebebi: sistem açılırken kernel, ilk kullanıcı-alanı
(userspace) programı olarak tek bir süreç başlatır — bu, tüm diğer süreçlerin
doğrudan ya da dolaylı olarak atasıdır. PID 1'in bir başka özel görevi de
"yetim kalan" süreçleri (ebeveyni ölmüş ama kendisi hâlâ çalışan süreçleri)
devralmaktır — normal koşullarda her sürecin bir ebeveyni olmalıdır, ebeveyni
ölürse PID 1 onu evlat edinir.

```bash
pstree              # ağaç görünümü
pstree -p           # PID'lerle
ps -ef --forest     # aynısı ps ile
ls -l /proc/1/exe   # PID 1 gerçekte hangi program
```

### Süreç durumları (`ps` çıktısındaki STAT sütunu)

Bir süreç, yaşam döngüsü boyunca farklı "durumlar" arasında geçiş yapar. Bunu,
bir kişinin gün içindeki hâllerine benzetebilirsin: aktif çalışıyor, bir şey
bekliyor (telefon çalmasını), durdurulmuş (uyuyor), ya da işi bitmiş ama henüz
resmi olarak "kapanmamış" (biri onu görene kadar). `ps` çıktısındaki `STAT`
sütunu, o anki bu durumu tek harfle gösterir:

| Kod | Durum | Anlamı |
|---|---|---|
| `R` | Running | Çalışıyor veya çalışmaya hazır |
| `S` | Sleeping | Bir olayı bekliyor (kesilebilir) — **çoğu süreç burada** |
| `D` | Uninterruptible sleep | Disk/IO bekliyor, **kill edilemez** ⚠️ |
| `T` | Stopped | Durdurulmuş (Ctrl+Z) |
| `Z` | Zombie | Bitmiş ama ebeveyni durumunu okumamış |
| `<` | Yüksek öncelik | |
| `N` | Düşük öncelik | |
| `s` | Oturum lideri | |
| `+` | Ön planda | |

- **`R` (Running):** Süreç ya o an fiilen CPU üzerinde işlem yapıyor, ya da
  CPU'nun kendisine sıra vermesini bekliyor (kuyrukta). Bir sistemde aynı anda
  çekirdek sayısından fazla `R` durumunda süreç varsa, bazıları CPU sırası
  bekliyor demektir.
- **`S` (Sleeping):** En yaygın durumdur. Süreç bir şey **olana kadar** kendini
  "uyutur" — klavyeden girdi, ağdan veri, bir zamanlayıcının dolması gibi. "Kesilebilir"
  (interruptible) demek, bir sinyal geldiğinde bu uykudan hemen uyanıp sinyali
  işleyebileceği anlamına gelir.
- **`D` (Uninterruptible sleep):** Bu durum özellikle önemlidir çünkü davranışı
  `S`'den köklü şekilde farklıdır. Süreç, kernel'in düşük seviye bir işlemini
  (genelde disk G/Ç'si) tamamlamasını bekliyordur ve bu bekleme sırasında
  **hiçbir sinyal işleyemez** — `kill -9` gönderilse bile.
- **`T` (Stopped):** Süreç bilinçli olarak duraklatılmıştır (terminalde
  `Ctrl+Z` bastığında olan budur) — CPU zamanı almaz ama bellekte, "devam et"
  sinyalini bekler şekilde durur.
- **`Z` (Zombie):** Aşağıda ayrıca ayrıntılı anlatılıyor.

> **`D` durumu neden önemli?** NFS bağlantısı kopmuş veya disk arızalıysa süreçler `D`'ye
> düşer ve `kill -9` bile işe yaramaz. Tek çare sorunun kaynağını (mount, disk) düzeltmek
> ya da yeniden başlatmaktır. `ps aux | awk '$8 ~ /D/'` ile bulunur.

Bunun **neden** böyle olduğunu anlamak, bu durumu bir "bug" olarak değil bir
tasarım kararı olarak görmeni sağlar: kernel, bir disk okuma/yazma işlemini
yarıda bırakırsa (sinyal geldi diye), o işlemin ortasında kalan veri
tutarsızlığa yol açabilir — dosya sistemi bozulabilir. Bu yüzden kernel bu tür
kritik G/Ç işlemlerini **kesilemez** yapar; işlem bitene (ya da donanım hata
verene) kadar süreç sinyallere kapalıdır. Pratikte gördüğün "kill -9 işe
yaramıyor" şikayetlerinin büyük kısmı aslında bu durumdadır — çözüm süreci
öldürmeye çalışmak değil, altındaki disk/ağ sorununu gidermektir.

> **Zombie süreçler:** Kaynak tüketmez, sadece PID tablosunda yer kaplar. `kill` işe
> yaramaz (zaten ölü). Çözüm: **ebeveynini** (`PPID`) düzeltmek/yeniden başlatmak.
> Az sayıda zombie normaldir; binlercesi ebeveyn programda bug demektir.

Zombie kavramını netleştirelim çünkü ismi ürkütücü ama aslında zararsız bir
durumu tarif eder: Bir süreç işini bitirip sonlandığında, kernel onun **çıkış
kodunu** (0 = başarılı, başka bir sayı = hata) hemen silmez — bu bilgiyi
ebeveyn süreç `wait()` çağrısıyla "okuyana" kadar bir tabloda tutar (çünkü
ebeveyn genelde "çocuğum nasıl bitti" bilgisiyle ilgilenir). Eğer ebeveyn bu
bilgiyi hiç okumazsa (kötü yazılmış bir program, ya da ebeveyn zaten
meşgulse), o süreç "öldü ama kaydı hâlâ tabloda duruyor" hâlinde takılı kalır
— buna zombie denir. Zombie bir süreç RAM veya CPU harcamaz (zaten hiçbir kod
çalıştırmıyor), sadece PID tablosunda bir satır işgal eder; `kill` ona hiçbir
etki yapmaz çünkü ona gönderilen sinyali işleyecek çalışan bir kod yoktur.
Tek gerçek çözüm, o zombiyi doğuran **ebeveyn** süreci düzeltmek ya da yeniden
başlatmaktır — ebeveyn öldüğünde, zombisi PID 1'e (systemd'ye) miras kalır ve
PID 1 bunları düzenli olarak temizler.

---

## 2. Süreç listeleme

```bash
ps                      # sadece bu terminaldeki süreçler
ps aux                  # ⭐ BSD sözdizimi — tüm sistem, en yaygın
ps -ef                  # ⭐ UNIX sözdizimi — aynı bilgi, farklı format
ps -ef --forest         # ağaç görünümü
ps -u ali               # belirli kullanıcının süreçleri
ps -p 1234              # belirli PID
ps -C nginx             # komut adına göre
ps aux --sort=-%mem | head -10    # en çok bellek tüketen 10
ps aux --sort=-%cpu | head -10    # en çok CPU tüketen 10
ps -eo pid,ppid,user,%cpu,%mem,stat,etime,cmd   # kendi sütunlarını seç
```

`ps aux` ve `ps -ef` neden ikisi de var, aynı şeyi göstermiyorlar mı? Tarihsel
bir sebepten: `ps`'in BSD Unix ve System V Unix soylarından gelen iki farklı
seçenek sözdizimi vardır. `aux` (tire olmadan yazılır — BSD stili) ve `-ef`
(tire ile — System V stili) neredeyse aynı bilgiyi, sadece farklı sütun
düzeninde verir. Modern Linux'ta `ps` her iki söz dizimini de destekler, hangi
alışkanlığa sahipsen onu kullanabilirsin — genelde `ps aux` biraz daha yaygındır.

`ps aux` çıktısı:
```
USER  PID %CPU %MEM    VSZ   RSS TTY  STAT START TIME COMMAND
root    1  0.0  0.3 172000 13456 ?    Ss   09:12 0:03 /usr/lib/systemd/systemd
```
- **VSZ** — sanal bellek (ayrılmış, hepsi kullanılmıyor olabilir)
- **RSS** — fiziksel bellek (**gerçekten kullanılan**) ⭐ bakman gereken bu
- **TTY** — `?` ise terminale bağlı değil (daemon)
- **TIME** — toplam CPU süresi (duvar saati değil)

Bu dört sütunun her biri farklı bir soruya cevap verir, bunları ayırt etmek
önemlidir:

- **VSZ (Virtual Size)** — sürece **adres alanı olarak ayrılmış** toplam
  bellek miktarıdır; bu, sürecin şu an fiilen kullandığı bellekten çok daha
  büyük olabilir, çünkü bir program başlarken kütüphaneleri, gelecekte
  kullanabileceği alanları "ayırır" ama hemen dokunmaz. Bu yüzden VSZ **gerçek
  bellek baskısını ölçmek için yanıltıcıdır.**
- **RSS (Resident Set Size)** — o an fiziksel RAM'de gerçekten tutulan bellek
  miktarıdır. Bir sunucunun RAM'i dolmaya mı başladı diye kontrol ederken
  bakman gereken sütun budur, VSZ değil.
- **TTY** — sürecin bir terminale (klavye/ekrana) bağlı olup olmadığını
  gösterir. `?` işareti, o sürecin bir daemon (arka planda, kullanıcı
  oturumundan bağımsız çalışan servis) olduğunu — hiçbir terminale bağlı
  olmadığını gösterir; örneğin `systemd`'nin kendisi, `sshd` ana süreci gibi.
- **TIME** — bu sütun **duvar saati** (o süreç ne zamandır çalışıyor) değil,
  o sürecin **CPU üzerinde fiilen harcadığı toplam süredir**. Bir süreç 3
  saattir açık olabilir ama çoğu zamanı `S` (uyku) durumunda geçirip toplamda
  sadece 5 saniye CPU kullanmış olabilir — TIME sütunu bu 5 saniyeyi gösterir.

### pgrep / pkill

```bash
pgrep nginx                # PID'leri bul
pgrep -u ali               # ali'nin süreçleri
pgrep -a nginx             # PID + tam komut satırı
pgrep -f "python app.py"   # ⭐ TAM komut satırında ara
pkill nginx                # ada göre öldür
pkill -u ali               # ali'nin tüm süreçlerini öldür
pkill -f "python app.py"
```

`ps aux | grep nginx` yerine `pgrep -a nginx` kullan — grep'in kendisi çıktıda
görünmez, daha temiz.

Bu neden bir sorun? `ps aux | grep nginx` çalıştırdığında, `grep` komutunun
kendisi de o anlık çalışan bir süreçtir ve komut satırında "nginx" kelimesi
geçtiği için (grep'e argüman olarak verdiğin için) genelde kendi kendini de
sonuca dahil eder — çıktıda `grep nginx` diye bir satır fazladan görürsün, bu
kafa karıştırıcıdır. `pgrep`, `ps`'in çıktısını satır satır aramaz; doğrudan
kernel'in süreç listesini sorgular ve sadece gerçekten eşleşen süreçleri
(kendisi hariç) döndürür.

### Canlı izleme

```bash
top
#  Tuşlar:  M = belleğe göre sırala    P = CPU'ya göre
#           k = kill (PID sorar)        u = kullanıcı filtresi
#           1 = CPU çekirdeklerini ayrı göster
#           c = tam komut satırı        q = çık

htop        # renkli, fare destekli, ağaç görünümü (F5)
             # EPEL/apt ile ayrıca kurulur
```

`ps` bir "fotoğraf" çeker — çalıştırdığın anki durumu gösterir, sonra biter.
`top` ise sürekli kendini yenileyen, canlı bir "video" gibidir — belirli
aralıklarla (varsayılan 3 saniye) ekranı tazeleyerek sistemin o anki yükünü
takip etmeni sağlar. `htop`, `top`'un daha okunaklı, renkli, fare ile de
etkileşilebilen, süreç ağacını daha net gösteren modern bir alternatifidir;
temel sistemde gelmez, ayrıca kurulması gerekir.

`top` başlığında:
- **load average** — 1, 5, 15 dakikalık ortalama yük. **CPU çekirdek sayısıyla karşılaştır.**
  4 çekirdekli makinede 4.0 = tam kapasite, 8.0 = 2 kat yüklü.
- **%wa (iowait)** — CPU'nun disk beklemekle geçirdiği süre. Yüksekse darboğaz disktedir.
- **%st (steal)** — sanal makinede hipervizörün CPU'yu başkasına verdiği süre.
  Yüksekse komşu VM'ler kaynağını yiyor.

"Load average" kavramını biraz daha açalım çünkü sık yanlış yorumlanır: bu
sayı, "CPU kullanım yüzdesi" değildir — o anda **çalışmaya hazır ama CPU sırası
bekleyen** (yani `R` durumundaki) süreçlerin ortalama sayısıdır (bazı Linux
sürümlerinde `D` durumundaki süreçler de dahil edilir). Tek çekirdekli bir
makinede load average 1.0, "her an tam olarak bir iş CPU'yu meşgul ediyor, kimse
sırada beklemiyor" demektir — tam kapasite ama aşırı yük değil. Aynı 1.0 değeri,
4 çekirdekli bir makinede sadece "%25 kapasitede çalışıyor" anlamına gelir.
Bu yüzden load average'ı **her zaman** `nproc` ile öğrendiğin çekirdek sayısına
bölerek yorumlamalısın — çıplak sayı tek başına anlamsızdır.

```bash
uptime                # load average'ı hızlıca gör
nproc                 # CPU çekirdek sayısı
```

---

## 3. Sinyaller ve süreç sonlandırma

`kill` aslında "öldür" değil, **sinyal gönder** demektir.

Bu, bu modüldeki en sık yanlış anlaşılan kavramdır: `kill` komutunun adı
"öldür" olsa da, teknik olarak yaptığı şey bir sürece **bir sinyal
göndermektir** — sinyal, işletim sisteminin bir sürece "şu oldu, buna göre
davran" demesinin standart yoludur. Bazı sinyaller (SIGTERM, SIGINT gibi)
sürecin kendi kodunda "bu sinyali alırsam şunu yap" diye **yakalanabilir** ve
sürecin düzgün kapanma fırsatı olur; bazı sinyaller (SIGKILL, SIGSTOP) ise
doğrudan **kernel seviyesinde** uygulanır, sürecin haberi bile olmaz — bu
ayrım aşağıdaki tablonun son sütununda gösteriliyor.

| Sinyal | No | Anlamı | Yakalanabilir mi |
|---|---|---|---|
| `SIGHUP` | 1 | Terminal kapandı / **yapılandırmayı yeniden oku** | ✅ |
| `SIGINT` | 2 | Kesme (Ctrl+C) | ✅ |
| `SIGQUIT` | 3 | Çık + core dump | ✅ |
| `SIGKILL` | **9** | **Zorla öldür** — süreç haberdar olmaz | ❌ |
| `SIGTERM` | **15** | **Nazikçe sonlan** (varsayılan) | ✅ |
| `SIGSTOP` | 19 | Duraklat | ❌ |
| `SIGCONT` | 18 | Devam ettir | ✅ |

Bu tablodaki her sinyali biraz açalım:

- **SIGHUP (1)** — tarihsel olarak "hangup" (telefon hattının kapanması)
  anlamına gelir: bir terminal oturumu koptuğunda, o terminale bağlı süreçlere
  gönderilirdi. Günümüzde çoğu daemon bu sinyali farklı, kullanışlı bir amaçla
  "yeniden kullanır": SIGHUP alınca **yeniden başlamadan, yapılandırma
  dosyasını yeniden okumak** için bir tetikleyici olarak kullanırlar (aşağıda
  ayrıca anlatılıyor).
- **SIGINT (2)** — klavyede Ctrl+C bastığında terminal, ön plandaki sürece bu
  sinyali gönderir; "kesme" isteğidir, çoğu program bunu görünce düzgünce
  durur.
- **SIGKILL (9) ile SIGTERM (15) arasındaki fark** kritik: SIGTERM bir
  **istektir** — "lütfen kapan" der, süreç bunu görmezden gelebilir ya da
  önce temizlik yapıp (açık dosyaları kapatmak, ağ bağlantılarını düzgün
  sonlandırmak, veritabanı işlemini commit etmek gibi) sonra kapanabilir.
  SIGKILL ise bir **emirdir**, doğrudan kernel süreci bellekten siler; sürecin
  buna itiraz etme ya da hazırlık yapma şansı yoktur.

```bash
kill 1234              # SIGTERM (15) gönderir — VARSAYILAN
kill -15 1234          # aynısı, açıkça
kill -9 1234           # SIGKILL — son çare
kill -HUP 1234         # yapılandırmayı yeniden okut
kill -l                # tüm sinyalleri listele

killall nginx          # ada göre hepsini
pkill -9 -f "app.py"
```

> ⚠️ **`kill -9` ilk hamle olmamalı.** SIGTERM süreç temizlik yapıp (dosya kapatma,
> tampon boşaltma, veritabanı commit) düzgün kapanır. SIGKILL kernel seviyesinde
> anında öldürür — bozuk veri, kilitli dosya, tutarsız durum bırakabilir.
>
> Doğru sıra: `kill` → 10 sn bekle → `kill -9`.
> `kill -9` da işe yaramıyorsa süreç `D` durumundadır, sorun disktedir.

Somut bir örnekle: bir veritabanı sürecine doğrudan `kill -9` gönderirsen, o
an yarım kalmış bir yazma işlemi diskte tutarsız bir durumda kalabilir —
sonraki açılışta veritabanı "kurtarma modunda" (recovery) başlamak zorunda
kalır, bazen veri kaybı bile yaşanabilir. Aynı süreç SIGTERM alırsa, kendi
kodunda "SIGTERM geldi, önce şu anki işlemi bitir, dosyaları kapat, sonra
çık" mantığı çalışır — güvenli bir kapanma olur. Bu yüzden pratik kural: önce
her zaman düz `kill` (SIGTERM), 5-10 saniye bekle, süreç hâlâ ayaktaysa ancak
o zaman `kill -9`'a başvur.

**SIGHUP kullanımı:** Birçok daemon (nginx, sshd, rsyslog) SIGHUP alınca yapılandırmayı
yeniden okur, servisi kesmez. `systemctl reload` bunu yapar.

Bu neden değerlidir: bir web sunucusunun (nginx gibi) yapılandırmasını
değiştirdiğinde, servisi tamamen **yeniden başlatmak** (`restart`) o an
sunucuya bağlı olan tüm istemcilerin bağlantısını keser — kısa bir kesinti
yaşanır. SIGHUP ile tetiklenen `reload` ise çalışan sürecin, mevcut
bağlantıları koparmadan, sadece yapılandırma dosyasını baştan okumasını
sağlar — kullanıcı hiçbir kesinti hissetmez.

---

## 4. Öncelik: nice / renice

**Benzetme:** `nice` değeri, bir sıradaki insanların "ne kadar nazik/ısrarcı"
olduğunu belirleyen bir ölçek gibi düşünülebilir — ismi de tam olarak buradan
gelir: yüksek nice değeri, o sürecin CPU sırasında **daha nazik/geri planda**
davranacağı, düşük (hatta negatif) nice değeri ise **daha ısrarcı, öncelikli**
davranacağı anlamına gelir. Linux zamanlayıcısı, aynı anda çalışmaya hazır
birden fazla süreç olduğunda kime öncelik vereceğine bu değere bakarak karar
verir.

Linux zamanlayıcısı **nice değeri** ile önceliği belirler.

```
-20 ────────── 0 ────────── +19
en yüksek   varsayılan   en düşük öncelik
öncelik
```

Bu ölçeğin ters gibi görünen mantığı ("düşük sayı = yüksek öncelik") ilk
bakışta kafa karıştırabilir ama isimden gelir: "ben ne kadar nice (naziğim,
uysalım)" sorusuna verilen cevaptır — -20 "hiç nazik değilim, önceliği hep ben
alacağım" demek, +19 ise "çok naziğim, herkes benden önce geçebilir" demektir.

```bash
nice -n 10 komut               # düşük öncelikle başlat
nice -n -5 komut               # yüksek öncelik (root gerekir)
renice -n 10 -p 1234           # çalışan sürecin önceliğini değiştir
renice -n 5 -u ali             # kullanıcının tüm süreçlerini
ps -eo pid,ni,cmd | head       # nice değerlerini gör
```

`nice` ile `renice` arasındaki fark önemli: `nice`, **henüz başlamamış** bir
komutu belirli bir öncelikle **başlatmak** için kullanılır — komutun önüne
eklenir. `renice` ise **zaten çalışan** bir sürecin önceliğini sonradan
değiştirmek için kullanılır, PID veya kullanıcı adı ile hedeflenir.

> Negatif nice (öncelik artırma) sadece root'a açıktır. Pozitif nice'i herkes verebilir
> ama **geri alamaz** — normal kullanıcı `nice 10` verdiği bir süreci `renice 5` yapamaz.

Bu kısıtlamanın mantığı bir güvenlik önlemidir: eğer sıradan kullanıcılar
kendi süreçlerinin önceliğini serbestçe **artırabilseydi**, herkes kendi
işini "en yüksek öncelik" yapıp sistemi adaletsizce paylaşırdı — bu yüzden
önceliği artırmak (negatif nice vermek) sadece root'a tanınmıştır. Ama
önceliği **azaltmak** (kendi işini bilerek geri plana atmak) zararsızdır,
herkes yapabilir; sadece bunu bir kere yaptıktan sonra "aslında pişman oldum,
tekrar yükselteyim" diyemezsin — bu da geri artırmanın root yetkisi
gerektirmesinden kaynaklanır.

Pratik kullanım: uzun süren bir yedekleme veya derleme işini `nice -n 19` ile başlatarak
sunucunun asıl işini etkilememesini sağlarsın.

```bash
nice -n 19 tar -czf /yedek/buyuk.tar.gz /veri
ionice -c3 -p 1234              # disk I/O önceliğini düşür (idle sınıfı)
```

`nice`'in sadece **CPU** önceliğini etkilediğini unutma — bir yedekleme işi
CPU'yu az ama diski çok kullanabilir, bu durumda `nice` tek başına yeterli
olmaz, `ionice` ile disk G/Ç önceliğini de düşürmen gerekir (`-c3` = "idle"
sınıfı, yani sistemde başka hiçbir disk isteği yokken çalış).

---

## 5. İş kontrolü ve arka plan

**Benzetme:** Terminalinde bir komut çalıştırdığında, o komut normalde
terminali "kilitler" — komut bitene kadar başka bir şey yazamazsın, tıpkı bir
telefon görüşmesi sırasında aynı hatla başka birini arayamaman gibi. İş
kontrolü (job control), bu görüşmeyi "beklemede tut" (arka plana at),
"görüşmeye geri dön" (ön plana getir) gibi yönetmeni sağlayan mekanizmadır.

```bash
komut &              # arka planda başlat
Ctrl+Z               # ön plandaki süreci DURDUR (T durumu)
jobs                 # arka plandaki işleri listele
jobs -l              # PID'lerle
fg                   # son işi ön plana getir
fg %2                # 2 numaralı işi
bg                   # durdurulmuş işi arka planda ÇALIŞTIRMAYA devam et
bg %2
kill %1              # iş numarasıyla öldür
```

Burada iki farklı kavram karışabilir, ayrı ayrı netleştirelim:

- **`&` ile başlatmak** — komutu **baştan itibaren** arka planda çalıştırır,
  terminal hiç kilitlenmez, hemen bir sonraki komutu yazabilirsin. Süreç `R`
  veya `S` durumunda, fiilen çalışmaya devam eder, sadece terminali işgal
  etmez.
- **`Ctrl+Z`** — hâlihazırda **ön planda çalışan** bir komutu tamamen
  **duraklatır** (`T` durumuna sokar) — komut çalışmayı durdurur, hiçbir CPU
  zamanı almaz, "askıya alınmış" gibi bekler. Bu, `&` ile arka plana atmaktan
  farklıdır: `&` süreci çalışır durumda arka plana atarken, `Ctrl+Z` süreci
  tamamen durdurur.

Tipik akış: uzun bir komut başlattın, terminali kullanman gerekti →
`Ctrl+Z` (durur) → `bg` (arka planda devam eder) → `jobs` ile takip → `fg` ile geri al.

Bu akışı adım adım açalım: `Ctrl+Z` ile komutu durdurdun (`T` durumunda,
hiçbir iş yapmıyor). `bg` komutu ona "duraklat modundan çık ama arka planda
kal" der — süreç `T`'den tekrar `R`/`S`'ye döner, çalışmaya devam eder, ama
artık terminali işgal etmiyordur, sen aynı anda başka komutlar
çalıştırabilirsin. `jobs` o an arka planda kaç iş olduğunu, hangi numarayla
(`%1`, `%2` gibi) anıldıklarını gösterir. İşin bittiğini görmek veya onunla
tekrar doğrudan etkileşmek (örneğin çıktısını izlemek, Ctrl+C ile kesmek)
istersen `fg` ile onu tekrar ön plana çekersin.

### Oturum kapanınca süreç ölmesin: nohup

```bash
nohup uzun-komut &                    # çıktı nohup.out'a gider
nohup ./betik.sh > cikti.log 2>&1 &   # ⭐ doğru kullanım
disown -h %1                          # mevcut arka plan işini oturumdan kopar
```

Neden bu gerekli? Az önce gördüğümüz `&` ile arka plana atma, süreci
terminalden **bağımsız çalıştırır** ama tamamen **koparmaz** — o süreç hâlâ
aynı oturuma (SSH bağlantına, terminal penceresine) bağlıdır. Sen SSH
bağlantını kapattığında (ya da terminal penceresini kapattığında), kabuk o
oturumdaki tüm arka plan işlerine **SIGHUP** sinyali gönderir (üstteki
sinyaller bölümünde gördüğün "hangup" — tarihsel anlamıyla, "hattın koptuğu"
sinyal) ve bu sinyali yakalamayan çoğu program bu sinyalle birlikte ölür.
`nohup` ("no hangup"), sürecin SIGHUP sinyalini **görmezden gelmesini**
sağlayan bir sarmalayıcıdır — bu sayede SSH bağlantın kopsa bile, o süreç
çalışmaya devam eder.

`nohup` süreci SIGHUP'tan korur; SSH bağlantın kopsa bile çalışmaya devam eder.

### Daha iyisi: terminal çoğaltıcı (screen / tmux)

`nohup` tek yönlüdür — sürece geri dönemezsin. `tmux`/`screen` oturumun tamamını saklar.

Bu ayrımı netleştirelim: `nohup` ile başlattığın bir sürecin sadece **çıktısını
bir dosyaya yönlendirebilirsin** (`> log 2>&1`), ama o sürecin çalıştığı
"terminal ekranına" bir daha asla geri dönemezsin — mesela içinde `top` veya
etkileşimli bir kurulum sihirbazı çalıştırdıysan, `nohup` ile bunu göremezsin.
`tmux`/`screen` ise tamamen farklı bir yaklaşımdır: gerçek bir **terminal
oturumunu**, sunucu üzerinde, senin bağlantından bağımsız olarak canlı tutar
— sen bağlantını kesip (detach) saatler sonra tekrar bağlandığında (attach),
o terminali tam olarak bıraktığın yerden, ekran görüntüsüyle birlikte
görebilirsin.

```bash
# tmux (modern, önerilen)
tmux new -s isim          # yeni oturum
Ctrl+b d                  # oturumdan ayrıl (detach) — süreç çalışmaya devam
tmux ls                   # oturumları listele
tmux attach -t isim       # geri bağlan
Ctrl+b c                  # yeni pencere
Ctrl+b %                  # dikey böl
Ctrl+b "                  # yatay böl
Ctrl+b ok                 # bölmeler arası geç

# screen (klasik)
screen -S isim
Ctrl+a d                  # ayrıl
screen -ls
screen -r isim
```

`Ctrl+b` (tmux'ta) ve `Ctrl+a` (screen'de) birer "önek tuşu"dur (prefix key)
— tmux/screen'e "şimdi bir komut geliyor" der, sonrasında basılan tuş (`d`,
`c`, `%` gibi) o komutu belirler. Bu, tmux/screen içindeyken normal
klavye girdisi ile kendi komutlarını birbirinden ayırmasının yoludur.

> **Sahada altın kural:** Uzak sunucuda 30 saniyeden uzun sürecek bir iş
> (güncelleme, taşıma, derleme) başlatacaksan **önce `tmux` aç**. Bağlantı koparsa
> iş yarıda kalmaz. Bunu yapmayanlar bir kere yanar, sonra hep yapar.

---

## 6. systemd ile servis yönetimi

> Kurs SysV-init anlatıyor (`service`, `chkconfig`). Bu **CentOS 6 dünyasıdır**.
> RHEL 7+, Debian 8+, Ubuntu 15.04+ — hepsi **systemd** kullanır. Sahada göreceğin budur.

**Benzetme:** SysV-init dönemindeki servisler, her biri kendi başına yazılmış,
birbirinden habersiz çalışan bağımsız betiklere benziyordu — hangisinin
hangisinden önce başlaması gerektiğini genelde dosya adlarındaki sayılarla
(`S10network`, `S20sshd` gibi) elle belirtirdin. `systemd`, bunun yerine
servisler arasındaki **bağımlılıkları** ("ben ağdan sonra başlamalıyım" gibi)
açıkça tanımlayan, servisleri paralel başlatabilen (bağımlılık yoksa aynı anda
başlatarak açılışı hızlandıran) merkezi bir yönetim sistemidir.

| İşlem | systemd (bugün) | SysV-init (CentOS 6) |
|---|---|---|
| Başlat | `systemctl start nginx` | `service nginx start` |
| Durdur | `systemctl stop nginx` | `service nginx stop` |
| Yeniden başlat | `systemctl restart nginx` | `service nginx restart` |
| Yapılandırmayı yeniden oku | `systemctl reload nginx` | `service nginx reload` |
| Durum | `systemctl status nginx` | `service nginx status` |
| Açılışta başlat | `systemctl enable nginx` | `chkconfig nginx on` |
| Açılıştan çıkar | `systemctl disable nginx` | `chkconfig nginx off` |
| Açılışta mı? | `systemctl is-enabled nginx` | `chkconfig --list nginx` |

Bu tablodaki `start`/`stop` ile `enable`/`disable` arasındaki fark, sık
karıştırılan bir noktadır — netleştirelim: `start`/`stop`, servisin **şu an**
çalışıp çalışmadığını değiştirir (anlık durum). `enable`/`disable` ise
servisin **sistem her açıldığında otomatik başlayıp başlamayacağını**
belirler (kalıcı yapılandırma). Bu ikisi **birbirinden bağımsızdır**: bir
servisi `start` edebilirsin ama `enable` etmezsen, o an çalışır ama bir
sonraki reboot'ta otomatik başlamaz. Tam tersi de mümkündür: `enable` edilmiş
ama şu an `stop` edilmiş (çalışmayan) bir servis, bir sonraki açılışta yine
de başlayacaktır.

```bash
systemctl start|stop|restart|reload nginx
systemctl enable --now nginx           # ⭐ enable + start tek komutta
systemctl disable --now nginx
systemctl status nginx                 # durum + son log satırları
systemctl is-active nginx              # betiklerde kullanışlı
systemctl mask nginx                   # başlatılmasını TAMAMEN engelle
systemctl unmask nginx

systemctl list-units --type=service            # çalışan servisler
systemctl list-units --type=service --state=failed   # ⭐ ARIZALI olanlar
systemctl list-unit-files --state=enabled      # açılışta başlayanlar
systemctl daemon-reload                        # unit dosyası değiştirdiysen ŞART
```

`mask` ile `disable` arasındaki fark da önemlidir: `disable`, sadece
"açılışta otomatik başlama" bağlantısını kaldırır ama servis yine de elle
(`systemctl start` ile) ya da başka bir servisin bağımlılığı olarak
başlatılabilir. `mask` ise çok daha kesindir — servisin unit dosyasını
`/dev/null`'a bağlar, bu servisin **hiçbir şekilde**, ne elle ne başka bir
bağımlılık üzerinden başlatılamamasını garantiler. Bir servisin asla
çalışmaması gerektiğinden eminsen (örneğin bilinen bir güvenlik açığı
nedeniyle) `mask` kullanılır.

`systemctl status` çıktısını okumayı öğren: `Active: active (running)`,
`Loaded: ... enabled`, en altta son log satırları. Bir servis çalışmıyorsa ilk bakılacak yer burası.

`status` çıktısı üç katmanlı bilgi verir ve bir servis sorununu teşhis
ederken sırayla bunlara bakmalısın: **`Loaded`** satırı, unit dosyasının
sistemde bulunup bulunmadığını ve `enabled`/`disabled` durumunu gösterir —
"loaded" değilse dosya hiç yok ya da bozuk demektir. **`Active`** satırı, o
anki fiili durumu gösterir (`active (running)` = çalışıyor, `failed` =
başlatılmaya çalışıldı ama çöktü, `inactive (dead)` = durdurulmuş). En alttaki
**log satırları**, servisin son birkaç saniyede/dakikada yazdığı çıktıdır —
bir servis neden başlayamadığını genelde doğrudan burada, ekstra bir komut
çalıştırmadan görürsün.

### Kendi servisini yazmak

```bash
sudo vi /etc/systemd/system/uygulamam.service
```
```ini
[Unit]
Description=Benim Uygulamam
After=network.target

[Service]
Type=simple
User=uygulama
WorkingDirectory=/opt/uygulamam
ExecStart=/opt/uygulamam/calistir.sh
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
```

Bu dosyanın üç bölümünü tek tek açalım, çünkü her `.service` dosyası aynı
iskeleti izler:

- **`[Unit]`** — servisin kimliği ve **diğer servislerle ilişkisi**.
  `Description` sadece `status` çıktısında görünen okunur bir açıklamadır.
  `After=network.target`, "bu servis, ağ hazır olmadan başlamaya çalışmasın"
  der — bir web sunucusu ağ olmadan anlamsız olacağı için bu tür bağımlılıklar
  önemlidir. (`After`, sıralama belirler ama zorunlu bağımlılık yapmaz; onun
  için `Requires`/`Wants` kullanılır.)
- **`[Service]`** — servisin **nasıl çalıştırılacağı**. `Type=simple`, "bu
  program başlatıldığı an, arka plana kendini atmadan, ön planda çalışmaya
  devam eder" demektir (en yaygın tip). `User`, servisin **root olarak değil**,
  belirtilen kısıtlı kullanıcı ile çalışmasını sağlar — bu bir güvenlik
  pratiğidir, servis ele geçirilirse zararı sınırlar. `ExecStart`, fiilen
  çalıştırılacak komuttur. `Restart=on-failure` + `RestartSec=5`, servis
  beklenmedik şekilde çökerse (sıfırdan farklı bir çıkış koduyla biterse)
  systemd'nin 5 saniye bekleyip otomatik olarak yeniden başlatmasını sağlar.
- **`[Install]`** — bu servis `enable` edildiğinde **hangi hedefe (target)**
  bağlanacağı. `multi-user.target`, "normal, çok kullanıcılı, ağ bağlantılı
  çalışma modu" anlamına gelir — sunucuların neredeyse tamamı bu hedefte
  açılır; bu satır olmadan `systemctl enable` çalışmaz (hangi açılış
  aşamasında başlatılacağını bilemez).

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now uygulamam
journalctl -u uygulamam -f          # loglarını canlı izle
```

`daemon-reload`'u neden her seferinde tekrar hatırlatıyoruz? Çünkü systemd,
unit dosyalarını **sadece belirli tetikleyicilerde** (sistem açılışı, ya da
sen açıkça `daemon-reload` dediğinde) okur; sen `/etc/systemd/system/` altına
yeni bir dosya koyduğunda ya da var olanı değiştirdiğinde, systemd bunu
**otomatik fark etmez** — hâlâ eski (ya da hiç var olmayan) tanımı bilir. Bu
komutu unutup `systemctl start uygulamam` çalıştırırsan "servis bulunamadı"
hatası alırsın, çünkü systemd henüz senin yeni dosyanı okumamıştır.

`Restart=on-failure` sayesinde uygulama çökerse systemd otomatik yeniden başlatır —
`nohup` ile elde edemeyeceğin bir güvence.

Bu, `nohup`/`tmux` ile systemd arasındaki temel farkı gösterir: `nohup` sadece
"oturum kapansa da süreç ölmesin" garantisi verir, ama süreç **kendi kendine
çökerse** (bir hata, bir exception, bellek yetersizliği) kimse onu tekrar
başlatmaz — sen fark edip elle yeniden çalıştırman gerekir. systemd'nin
`Restart=on-failure` özelliği, gerçek üretim servislerinin `nohup` yerine
neden systemd unit'i olarak yönetilmesi gerektiğinin ana sebebidir.

> **Dağıtım farkı — servis adları:** Aynı yazılım farklı adla gelir.
> SSH: RHEL'de `sshd`, Debian'da `ssh`. Apache: RHEL'de `httpd`, Debian'da `apache2`.
> Cron: RHEL'de `crond`, Debian'da `cron`. `systemctl list-units | grep -i ara`
> ile doğru adı bul.

### Kaynak sınırlama (cgroups)

```bash
systemctl set-property nginx.service MemoryMax=512M
systemctl set-property nginx.service CPUQuota=50%
systemd-cgtop                        # cgroup bazlı kaynak kullanımı
```

Bu komutlar `nice`'den farklı bir şeyi çözer: `nice` bir sürece **görece bir
öncelik** verir (diğerlerine göre daha az/çok CPU sırası alır) ama **kesin bir
üst sınır** koymaz — sistemde başka iş yoksa, düşük öncelikli bir süreç bile
CPU'nun tamamını kullanabilir. `MemoryMax`/`CPUQuota` ise cgroups (control
groups — kernel'in kaynak sınırlama mekanizması) üzerinden **kesin, aşılamaz**
bir tavan koyar: `CPUQuota=50%` demek, bu servis sistemde başka hiçbir iş
olmasa bile, asla bir çekirdeğin %50'sinden fazlasını kullanamaz demektir.

---

## 7. Süreç hata ayıklama araçları

```bash
lsof -p 1234              # sürecin açık tüm dosyaları
lsof /var/log/app.log     # bu dosyayı kim açmış
lsof -i :80               # ⭐ 80 portunu kim dinliyor
fuser -v /mnt/veri        # bu dizini kim kullanıyor (umount edemiyorsan)
fuser -km /mnt/veri       # kullananları öldür (dikkat!)

ss -tulnp                 # dinlenen portlar (netstat'ın modern hali)
strace -p 1234            # sistem çağrılarını izle (derin hata ayıklama)
strace -f -e trace=file komut   # dosya erişimlerini izle
cat /proc/1234/status     # sürecin ayrıntılı durumu
cat /proc/1234/limits     # kaynak limitleri
ls -l /proc/1234/cwd      # sürecin çalışma dizini
```

`lsof` ("list open files") aracının Unix felsefesiyle doğrudan bağlantısı
vardır: "her şey bir dosyadır" ilkesi hatırlarsan (Gün 1'de Unix'i
tanımlarken bahsetmiştik), Linux'ta sadece diskteki dosyalar değil, ağ
soketleri, aygıtlar, hatta bazı süreçler arası iletişim kanalları da birer
"dosya tanımlayıcı" (file descriptor) olarak temsil edilir. Bu yüzden `lsof`
hem "hangi süreç hangi dosyayı açmış" hem de "hangi süreç hangi ağ portunu
dinliyor" (`-i :80`) sorularına aynı araçla cevap verebilir — ikisi de
kernel'in gözünde "açık bir dosya tanımlayıcısı"dır.

`strace`, en derin hata ayıklama seviyesidir: bir programın kernel'e yaptığı
**her sistem çağrısını** (dosya açma, okuma, ağ bağlantısı kurma gibi
en temel işlemleri) satır satır gösterir. Bir program "neden hiçbir şey
yapmıyor" ya da "hangi dosyayı bulamıyor" gibi sorularda, uygulamanın kendi
loglarına güvenemeyeceğin durumlarda son çare olarak kullanılır.

**Klasik senaryo:** Servis "Address already in use" diyor.
```bash
sudo ss -tulnp | grep :80     # veya  sudo lsof -i :80
# PID'i bul, ne olduğuna bak, sonra kill
```

Bu hatanın sebebi genelde basittir: başlatmaya çalıştığın servis (örneğin
nginx), zaten başka bir sürecin (belki eski, kapanmamış bir nginx örneğinin,
belki tamamen farklı bir programın) dinlediği bir porta (80 gibi) bağlanmaya
çalışıyordur — bir port aynı anda sadece **bir** süreç tarafından dinlenebilir.
`ss -tulnp` ya da `lsof -i :80`, o portu şu an kimin tuttuğunu gösterir; PID'i
bulup ya o süreci düzgünce kapatır ya da gerçekten gereksizse `kill`
edersin.

**Klasik senaryo:** `umount /mnt/veri` "device is busy" diyor.
```bash
sudo fuser -vm /mnt/veri      # kim kullanıyor
sudo lsof +D /mnt/veri
# İlgili süreci düzgünce kapat, sonra umount
```

Bu, 09. modülde gördüğün `umount` işleminin neden bazen başarısız olduğunun
açıklamasıdır: bir dosya sistemini `umount` edebilmek için, o dosya
sistemindeki **hiçbir dosyanın açık olmaması, hiçbir sürecin o dizinde
"durmuyor" olması** gerekir (mesela bir terminalin `cd` ile o dizinde
bulunması bile yeterlidir). `fuser -vm`, tam olarak o mount noktasını kimin
"meşgul tuttuğunu" gösterir; `-km` bayrağı bu süreçleri doğrudan öldürür ama
bu tehlikelidir — o süreç ortasında bir yazma işlemi yapıyorsa veri kaybı
yaşanabilir, bu yüzden mümkünse önce süreci düzgünce durdurmayı tercih et.

---

## 🧪 Lab

1. `sleep 300 &` ile 3 arka plan işi başlat. `jobs`, `fg`, `Ctrl+Z`, `bg` döngüsünü uygula.
2. `ps aux --sort=-%mem | head -5` ile en çok bellek tüketen 5 süreci bul.
3. Bir `sleep 500` başlat, `kill` (SIGTERM) ile öldür. Yeni bir tane başlat, `kill -9` ile
   öldür. `strace` veya log ile farkı gözlemlemeye çalış.
4. `nice -n 19` ile bir `tar` işi başlat, `ps -eo pid,ni,cmd | grep tar` ile nice değerini doğrula.
   `renice` ile değiştir.
5. `tmux` oturumu aç, içinde `top` çalıştır, `Ctrl+b d` ile ayrıl, SSH'ı kapat, tekrar
   bağlan, `tmux attach` ile geri dön. Hâlâ çalıştığını gör.
6. `nohup ./uzun.sh > cikti.log 2>&1 &` ile bir betik başlat, terminali kapat, tekrar
   bağlanıp `ps -ef | grep uzun.sh` ile hâlâ çalıştığını doğrula.
7. `/etc/systemd/system/test.service` adında, her 30 saniyede tarihi log'a yazan bir
   servis yaz. `enable --now` yap, `journalctl -u test -f` ile izle, `Restart=on-failure`
   davranışını `kill` ile test et.
8. `sudo ss -tulnp` ile hangi servislerin hangi portları dinlediğini çıkar, tabloya dök.
9. `systemctl list-units --state=failed` çalıştır. Arızalı servis varsa `journalctl -xeu <ad>`
   ile sebebini bul.
10. `lsof -i :22` ile SSH'ı kimin dinlediğini bul.

---

## ❓ Kendini test et

**S1.** `kill -9` neden son çare olmalı?

<details><summary>Cevap</summary>
SIGKILL yakalanamaz — süreç haberdar olmaz, temizlik yapamaz. Açık dosyalar kapatılmaz,
tamponlar diske yazılmaz, kilit dosyaları kalır, veritabanı tutarsız durumda kalabilir.
SIGTERM (varsayılan `kill`) sürece "kapan" der, düzgün sonlanmasına izin verir.
</details>

**S2.** `kill -9` bile bir süreci öldürmüyor. Ne olmuş olabilir?

<details><summary>Cevap</summary>
Süreç `D` (uninterruptible sleep) durumunda — kernel içinde bir I/O işlemi bekliyor.
Genelde kopmuş NFS mount'u veya arızalı disk. Sinyal işlenemez.
Çözüm sorunun kaynağını gidermek (mount'u düzelt/lazy umount) veya yeniden başlatmak.
</details>

**S3.** 4 çekirdekli sunucuda `load average: 3.80, 3.60, 3.20`. Sorun var mı?

<details><summary>Cevap</summary>
Hayır, kapasite sınırına yakın ama üstünde değil (4 çekirdek ≈ 4.0 tam kapasite).
İzlenmeli. Aynı değerler tek çekirdekli makinede ciddi aşırı yük demektir.
Load average her zaman **çekirdek sayısına bölünerek** yorumlanır.
</details>

**S4.** SSH bağlantın kopunca çalıştırdığın uzun komut da öldü. Bir dahakine ne yaparsın?

<details><summary>Cevap</summary>
`tmux new -s is` içinde başlat (`Ctrl+b d` ile ayrıl, sonra `tmux attach` ile dön),
ya da en azından `nohup komut > log 2>&1 &`. SSH kopunca kabuk SIGHUP gönderir,
alt süreçler ölür; ikisi de bunu engeller.
</details>

**S5.** `systemctl restart` ile `systemctl reload` farkı?

<details><summary>Cevap</summary>
`restart` servisi durdurup yeniden başlatır — **kesinti olur**, bağlantılar düşer.
`reload` çalışan sürece yapılandırmayı yeniden okuması için sinyal (genelde SIGHUP)
gönderir — kesinti olmaz. Sadece config değiştiyse `reload` tercih edilir.
Emin değilsen `reload-or-restart`.
</details>

**S6.** `systemctl enable nginx` çalıştırdın ama `systemctl start` demedin. Sunucuyu şimdi
reboot edersen nginx açılır mı? Peki hiç reboot etmeden şu an nginx çalışıyor mu?

<details><summary>Cevap</summary>
Şu an çalışmıyor — `enable` sadece "gelecekteki açılışlarda otomatik başlat" bağlantısını
kurar, mevcut durumu değiştirmez (`start` gerekir). Ama reboot edersen, açılış sürecinde
systemd bu servisi otomatik başlatacaktır çünkü artık `enabled` durumdadır. İkisini
tek seferde yapmak için `systemctl enable --now nginx` kullanılır.
</details>

**S7.** `ps aux` çıktısında bir sürecin VSZ değeri çok yüksek ama RSS değeri düşük.
Sunucunun gerçekten bellek sıkıntısı var mı?

<details><summary>Cevap</summary>
Muhtemelen hayır. VSZ, sürece ayrılmış sanal adres alanıdır ve fiilen kullanılmayan
büyük rezervasyonları da içerebilir. RSS, o an fiziksel RAM'de gerçekten tutulan
miktardır — gerçek bellek baskısını değerlendirirken RSS'e (ve sistem genelinde
`free -h` çıktısına) bakılır, VSZ'e değil.
</details>

---

## 📋 Hızlı referans

```bash
ps aux --sort=-%mem | head       # bellek canavarları
ps -ef --forest                  # süreç ağacı
pgrep -a NAD ; pkill -f "desen"
top / htop                       # M bellek, P cpu, k kill
kill PID                         # SIGTERM önce
kill -9 PID                      # son çare
kill -HUP PID                    # config yeniden oku
nice -n 19 KOMUT ; renice -n 10 -p PID
komut & ; Ctrl+Z ; jobs ; fg ; bg
nohup KOMUT > log 2>&1 &
tmux new -s ad / Ctrl+b d / tmux attach -t ad
systemctl enable --now SERVIS
systemctl list-units --state=failed
systemctl daemon-reload          # unit değişince ŞART
journalctl -xeu SERVIS
lsof -i :PORT ; ss -tulnp
fuser -vm /mnt/YOL               # "device is busy" çözümü
```
