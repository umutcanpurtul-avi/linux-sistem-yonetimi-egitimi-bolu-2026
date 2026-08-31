---
tags:
  - egitim/linux-sistem-yonetimi
tarih: 2026-08-24
konular:
  - Gün 1-9 pratik tekrarı (kabuk, dosya sistemi, süreç/servis, log, ağ, DNS, SSH)
---

# Gün 1-9 Pratik Challenge

Bağlantı: [Linux Sistem Yönetimi Eğitimi](../README.md) · [Gün 1](../Kamp%20Eğitim/Gün%201.md) · [Gün 2](../Kamp%20Eğitim/Gün%202.md) · [Gün 3](../Kamp%20Eğitim/Gün%203.md) · [Gün 4](../Kamp%20Eğitim/Gün%204.md) · [Gün 5](../Kamp%20Eğitim/Gün%205.md) · [Gün 6](../Kamp%20Eğitim/Gün%206.md) · [Gün 7](../Kamp%20Eğitim/Gün%207.md) · [Gün 8](../Kamp%20Eğitim/Gün%208.md) · [Gün 9](../Kamp%20Eğitim/Gün%209.md) · Cevaplar: [Cevaplar](Cevaplar.md)

> [!WARNING]
> **Bu challenge, sadece Gün 1 ile Gün 9 arasında **işlenen konularla sınırlıdır.** Her görevde bir **İpucu** kutusu var (küçük bir yönlendirme — hangi komut ailesine bakman gerektiğini söyler ama tam komutu vermez). Tam çözümler ayrı bir dosyada: [Cevaplar](Cevaplar.md) — önce kendin dene, sadece gerçekten takıldığında oraya bak.**

## Senaryo

Senden önce çalışmış bir sistem yöneticisi bu makineyi iki şekilde miras bıraktı:

1. **Bölüm A–F (Gün 1–5):** ev dizini **dağınık** — dosya adları gerçekçi ama neyin ne işe yaradığı adından belli değil. Görev metinleri de bilerek **hangi komutu kullanacağını söylemiyor**.
2. **Bölüm G–L (Gün 6–9):** aynı admin, **çalışan sunucuyu da bozuk teslim etmiş** — bir süreç CPU'yu yiyor, bir servis `failed` durumda, bir cron job çalışmıyor, `8080` portu kilitli, bir uygulama bağımlılığına ulaşamıyor, `sshd` sertleştirilmemiş, `apt update` hata veriyor. Bu bölümler ağırlıkla **"teşhis et → düzelt → doğrula"** formatında; çıktı çoğu zaman "servis artık `active`" gibi bir **durum** oluyor, sadece birkaç yerde erişim kanıtı olarak bir `KOD` var.

Her görevde ya bir `KOD-X` bulacaksın ya da bir ayar/işlem yapıp ortaya çıkan gerçek bir değeri (inode numarası, UUID, PID, subnet broadcast adresi, izin biti...) kaydedeceksin.

## Ortam

- **VM:** `Debian-Challenge` — ders makinesinden (`Debian-Egitim`) **tamamen ayrı**, sadece bu challenge için kurulmuş, tek amaçlı bir sanal makine. Debian 13 (Trixie), minimal (GUI'siz) kurulum.
- **Erişim:** `ssh -p 2224 ogrenci@127.0.0.1` — şifre `ogrenci123`.

  > [!tip] Bu, herkese açık/paylaşılabilir bir **pratik makinesi parolasıdır** — gerçek/kişisel hiçbir bilgi içermez. Aynı şekilde `raportor`/`raportor123` (Bölüm F) ve `sshtest`/`sshtest123` (Bölüm K) hesapları da sadece bu görev için üretilmiştir.
- Giriş yaptığında ev dizininde hazır bir **`~/gorev/`** klasörü (Bölüm A–L alt klasörleriyle) bulacaksın. Hiçbir şey senin oluşturman gerekmiyor.
- VM'e **ikinci bir disk zaten takılı** (~1.2 GB, boş, Bölüm C/D için). Disk/mount adımlarını ana diskte (`/dev/sda`) **denemeyin** — sadece ikinci diskte.
- Bölüm G–L için kurulmuş olanlar: `gorev-hog` / `gorev-zombi` / `gorev-rapor` / `gorev-bakim` / `gorev-hatali` / `gorev-fw` / `gorev-api` systemd servisleri, `/etc/cron.d/gorev-rapor`, `/var/log/gorev-app.log`, `/etc/apt/sources.list.d/gorev-ekstra.list`, `/etc/ssh/sshd_config.d/60-gorev.conf`.

  > [!warning] Firewall (Bölüm I) ve `sshd` (Bölüm K) görevleri **`2224` üzerinden SSH erişimini etkilemez** — nftables kuralı yalnızca `tcp/8080`, `sshd` drop-in'i yalnızca `PermitRootLogin`. Yine de: `sudo nft flush ruleset` gibi **topyekûn** komutlardan kaçın, sadece senaryo tablosunu (`inet gorev_fw`) hedefle.

```bash
ssh -p 2224 ogrenci@127.0.0.1
ls ~/gorev
```

---

## Bölüm A — Kabuk Temelleri (Gün 1)

**A1.** `~/gorev/bolum-a/yedekler/rapor_2026.txt` dosyasının içindeki `KOD-A` değerini öğren.
- [ ]

<details><summary>İpucu (korkaklar için)</summary>

Dosyayı doğrudan okumaya çalıştığında bir hata alacaksın — o hatanın sebebini gösteren bir komut var. Sebebi anladıktan sonra düzeltip okuyabilirsin.
</details>

**A2.** `~/gorev/bolum-a/env/` dizininde bir `KOD-B` değeri var, bul.

<details><summary>İpucu (korkaklar için)</summary>

O dizinde `ls` çıktısında gördüğünden daha fazlası olabilir.
</details>

**A3.** `~/gorev/bolum-a/calistir.sh` betiğini çalıştır — iki farklı türde çıktı üretiyor. Bunu, **terminalde hiçbir şey görünmeyecek şekilde**, iki çıktıyı da ayrı ayrı iki dosyaya kaydederek çalıştır. (2 dosya adı `basarili.log` ve `hatali.log` olması gerekiyor.)

Doğru komut :

<details><summary>İpucu (korkaklar için)</summary>

Bir komutun normal ve hatalı çıktısı için iki ayrı kanalı vardır; ikisini de ayrı ayrı bir dosyaya yönlendirebilirsin.
</details>

**A4.** `~/gorev/bolum-a/projeler/` altında üç proje dizini var, biri diğerlerinden farklı bir yapıya sahip. `ls -al` çıktısındaki bir sütun, dizine hiç girmeden hangisinin farklı olduğunu söyler. Doğru dizini bulup içindeki `ozet.txt`'den `KOD-J`'yi oku.

<details><summary>İpucu (korkaklar için)</summary>

Gün 1'de "link sayısı" diye bir kavram görmüştün. Bir dizinin altında başka alt dizinler varsa bu sayı normalden yüksek çıkar.
</details>

**A5.** `~/gorev/bolum-a/erisim.log` içinde yüzlerce satır var, aralarında tek bir farklı satır gizli. **`grep` KULLANMADAN** onu bulup içindeki `KOD-C`'yi çıkar.

<details><summary>İpucu (korkaklar için)</summary>

`head` ve `tail`'i zincirleyerek dosyanın herhangi bir satırını doğrudan okuyabilirsin (`head -n X | tail -n 1` gibi). Toplam satır sayısını öğren, aralığı ikiye bölerek daralt.
</details>

**A6.** `~/gorev/bolum-a/giris_kontrol.sh` betiğini çalıştır. İlk denemende muhtemelen istediğin sonucu almayacaksın — betiğin ne beklediğini anlayıp `KOD-D`'yi görecek şekilde tekrar çalıştır. Kabuğunda kalıcı bir değişiklik yapma.

<details><summary>İpucu (korkaklar için)</summary>

Bir betiğin çalışırken ne kontrol ettiğini anlamanın en kolay yolu, çalıştırmadan önce içeriğine bakmaktır. İçeride bir ortam değişkeni kontrolü olabilir.
</details>

---

## Bölüm B — Yol, Arama, Link (Gün 2)

**B1.** `~/gorev/bolum-b/loglar/` içindeki log dosyalarında normal kayıtlar arasına karışmış, gerçek bir kritik hata satırı var. Onu gürültüden ayırt edip `KOD-E`'yi bul.

<details><summary>İpucu (korkaklar için)</summary>

Önce tüm dosyalardaki "hata" geçen satırlara bak (büyük/küçük harf farkı gözetmeden). Sonra hangi satırların gerçek olmayan/test amaçlı kayıtlar olduğunu fark edip onları eleyebilirsin.
</details>

**B2.** `~/gorev/bolum-b/ayarlar/` içinde birkaç `.conf` dosyası var, biri yakın zamanda değiştirilmiş. O dosyayı bulup içindeki `KOD-F`'yi oku.

<details><summary>İpucu (korkaklar için)</summary>

Dosyaların değişim zamanını karşılaştırmanı sağlayan bir `find` seçeneği var (dakika cinsinden filtre yapabilirsin).
</details>

**B3.** `~/gorev/bolum-b/depo/` içinde üç dosya var, boyutları birbirinden farklı. Ortadaki boyuttaki dosyanın içinde bir kod saklı — onu bulup çıkar.

<details><summary>İpucu (korkaklar için)</summary>

`find`'ın `-size` seçeneğiyle bir aralık tanımlayabilirsin (bir değerden büyük VE başka bir değerden küçük). Büyük birimlerde (`M`) `find`'ın yuvarlama davranışı seni yanıltabilir — küçük birim (`k`) kullanmak daha güvenli.
</details>

**B4.** `~/gorev/bolum-b/config/httpd.conf.orig` ve `httpd.conf` iki farklı sürüm. Aralarında ne değişmiş, bul — değişen satırdaki sayı `KOD-H`'dır.

<details><summary>İpucu (korkaklar için)</summary>

İki dosya arasındaki farkı satır satır gösteren bir komut var.
</details>

**B5.** `~/gorev/bolum-b/belge/sozlesme.txt` dosyasının verisi, sistemde başka isimler altında da duruyor — ve ayrıca ona işaret eden dolaylı bir referans da bir yerde var. Tek tek klasör gezmek yerine bu dosyayla "aynı şey" olan diğer tüm isimleri ve ona işaret eden kısayolu bulup `KOD-I`'yı çıkar.

<details><summary>İpucu (korkaklar için)</summary>

`find`'ın "bu dosyayla aynı inode'u paylaşan her şeyi bul" diyen bir seçeneği var; sembolik linkleri bulmak için de ayrı bir seçeneği var.
</details>

---

## Bölüm C — Disk, Mount, inode (Gün 2)

> [!WARNING]
> **Bu bölümdeki her adımı yalnızca **ikinci diskte** yapın. `lsblk` çıktısında hangi diskin kök dosya sistemini (`/`) taşıdığını mutlaka önce tespit edin, ona dokunmayın.**

Sabit bir "KOD" yok — her adımda **kendi ürettiğin** gerçek bir değeri (aygıt adı, UUID, inode sayısı, byte miktarı) kaydedeceksin.

**C1.** İkinci (boş) diskin sistemdeki aygıt adını bul, üzerinde bir dosya sistemi olup olmadığını öğren.

<details><summary>İpucu (korkaklar için)</summary>

Blok aygıtlarını ağaç halinde listeleyen, dosya sistemi bilgisini de gösteren bir bayrağı olan komutu hatırla.
</details>

**C2.** İkinci diski GPT ile bölümle (MBR değil), tek bir bölüm oluştur, `ext4` ile biçimlendir. Bitince bu dosya sisteminin benzersiz kimliğini (UUID) bul ve not al.

<details><summary>İpucu (korkaklar için)</summary>

Bölümleme için `fdisk` (GPT etiketine geçiş tuşu `g`) ya da `parted`; biçimlendirme için `mkfs.ext4`; dosya sisteminin UUID/etiket bilgisini gösteren ayrı bir komut var.
</details>

**C3.** Bölümlediğin alanı bir dizine bağla (`~/gorev/bolum-c/veri`), sonra o an ne kadar boş yer olduğunu gösteren bir komutla kontrol et, değeri not al.

**C4.** İçine bir dosya yaz, bağlamayı kaldır (`umount`), dizine tekrar bak, sonra tekrar bağlayıp dosyanın geri geldiğini doğrula.

<details><summary>İpucu (korkaklar için)</summary>

Bağlamayı kaldırdığında dizin, altındaki (mount'tan önceki) haline döner.
</details>

**C5. (Gün 2'nin açık sorusu, kendin çöz.)** Diski geçici olarak `umount` et. Boşalan `veri` dizininin içine `notum.txt` diye bir dosya oluştur (içine bir şey yaz), sonra diski tekrar oraya `mount` et. `notum.txt` görünür mü? Görünmeyeni **diski unmount etmeden** görüp içeriğini okumanın bir yolu var mı?

<details><summary>İpucu (korkaklar için)</summary>

Aynı bölümü (kök dosya sistemini), farklı, boş bir dizine bir kez daha `mount` edebileceğini düşün.
</details>

**C6.** `~/gorev/bolum-c/veri/deneme.txt` dosyasının inode numarasını al ve yaz. Aynı disk içinde başka bir isimle yeniden adlandır, tekrar bak — inode numarası aynı mı çıktı?

**C7.** Bu dosya sisteminin toplam inode sayısını gösteren bir komut çalıştır, değeri not al. Aynı komutu kök dosya sistemi için de çalıştır, iki sayıyı karşılaştır.

<details><summary>İpucu (korkaklar için)</summary>

`df`'in alan yerine inode doluluğunu gösteren bir bayrağı var.
</details>

**C8.** İşin bitince bağlamayı kaldır, bölümü sil, diskin tekrar boş olduğunu doğrula.

---

## Bölüm D — Symlink, mv, Aygıtlar, Kütüphaneler (Gün 3)

`~/gorev/bolum-d/` altında hazır bir senaryo var: `belgeler/notlar.txt`, ona `masaustu/notlarim.txt` adında bir bağlantı, ve `belgeler/notlar_yedek.txt` adında başka bir bağlantı. Hangisinin symlink hangisinin hardlink olduğunu — ya da olup olmadığını — önce kendin tespit et.

**D1.** `masaustu/notlarim.txt` ile `belgeler/notlar.txt` arasındaki ilişkinin türünü (symlink mi, hardlink mi?) belirle. Sonra `belgeler/notlar.txt`'yi `~/gorev/bolum-d/harici/` altına taşı. `masaustu/notlarim.txt`'yi okumayı dene — ne oldu? Neden?

<details><summary>İpucu (korkaklar için)</summary>

`ls -l` çıktısının başındaki harf ve `->` işareti, bir dosyanın türü hakkında çok şey söyler. Bağlantı türüne göre, hedefin taşınması sonucu değiştirir.
</details>

**D2.** Dosyayı `belgeler/`'e geri taşı (bağlantı çalışır hale gelsin). Bu sefer **`masaustu/notlarim.txt`'nin kendisini** `~/gorev/bolum-d/` köküne taşı. Okumayı dene — bu sefer ne oldu, öncekinden farkı ne?

<details><summary>İpucu (korkaklar için)</summary>

Symlink içindeki hedef metni "değişmeyen bir ifade" gibi düşün — ama bu ifade her erişimde, symlink'in **o anki konumuna göre** yeniden yorumlanır.
</details>

**D3.** `belgeler/notlar.txt` ile `belgeler/notlar_yedek.txt` arasındaki ilişkiyi de belirle. Birinin izinlerini değiştir, diğerine ne olduğuna bak.

**D4.** `~/gorev/bolum-d/indirilenler/rapor.csv` dosyasını önce aynı disk içinde başka bir isimle taşı, sonra Bölüm C'de mount ettiğin ikinci diske taşı. Her adımdan önce/sonra dosyanın kimliğini karşılaştıracak bir komutla iki durumu da kaydet — hangisinde ne değişti?

<details><summary>İpucu (korkaklar için)</summary>

Bir dosyanın hangi disk bölümünde olduğunu ve inode numarasını aynı anda gösteren bir komut Gün 2/3'te işlendi.
</details>

**D5.** `/dev` altındaki aygıtları iki gruba ayırıp say: bir grubu sabit boyutlu bloklar halinde rastgele erişimle okunur (diskler), diğeri sıralı bir bayt akışı olarak okunur (terminaller vb.). Her gruptan kaç tane var?

<details><summary>İpucu (korkaklar için)</summary>

`ls -l /dev` çıktısının en soldaki karakteri bu iki grubu ayırt eder.
</details>

**D6.** İkinci diskin bölüm tablosu türünü (MBR mi GPT mi) iki farklı araçla doğrula, ikisi de aynı sonucu veriyor mu?

**D7.** `/bin/ls` programının çalışması için ihtiyaç duyduğu paylaşımlı kütüphanelerden birinin (`libc`) tam yolunu bul. Sonra bu arama yoluna geçici olarak var olmayan bir dizin ekleyip aynı komutu tekrar çalıştır — sonuç değişti mi, neden?

<details><summary>İpucu (korkaklar için)</summary>

Bir programın bağlı olduğu kütüphaneleri listeleyen bir komut var. Arama yoluna "önce buraya bak" diyen bir ortam değişkeni de var.
</details>

**D8.** `/proc/cpuinfo` dosyasının disk üzerindeki gerçek boyutunu öğrenmeye çalış. Ne görüyorsun, neden?

<details><summary>İpucu (korkaklar için)</summary>

Bir dosyanın meta verisini (boyut dahil) gösteren komutu `/proc` altındaki bir dosyaya da uygulayabilirsin.
</details>

---

## Bölüm E — Silinen/Açık Dosya, Sıkıştırma, ASCII/HEX, Paket Yönetimi (Gün 4)

**E1.** `~/gorev/bolum-e/canli/kayit.log` dosyasını arka planda **canlı takip eden** bir süreç başlat, sonra dosyayı **sil**, sonra o sürecin hâlâ açık tuttuğu dosya tanıtıcısı üzerinden içindeki `KOD-K`'yı kurtar.

<details><summary>İpucu (korkaklar için)</summary>

Bir dosyayı canlı takip eden komutu hatırla (`&` ile arka plana at). Sildikten sonra o sürecin PID'ini bul, `/proc/<PID>/fd/` altına bak — silinmiş ama hâlâ açık olan dosyanın linkini bulup `cat` ile okuyabilirsin.
</details>

**E2.** `~/gorev/bolum-e/arsiv/paket.tar.xz` dosyasını **açmadan önce** içindeki dosya listesini gör, sonra aç ve `gizli/rapor.txt` içindeki `KOD-L`'yi oku.

<details><summary>İpucu (korkaklar için)</summary>

`tar`'ın açmadan sadece içeriği listeleyen bir bayrağı var. `tar` sıkıştırma formatını dosyanın imzasından kendisi anlar, ayrıca bir bayrak vermene gerek yok.
</details>

**E3.** `~/gorev/bolum-e/hex/sifreli.hex` dosyasında bir metnin **onaltılık (hex)** biçimde yazılmış hâli var. Bunu gerçek metne çevirip içindeki `KOD-M`'yi oku.

<details><summary>İpucu (korkaklar için)</summary>

Hex'i metne çeviren, `-r` (reverse) ve `-p` (plain, offset/adres sütunu olmadan) bayraklarıyla çalışan bir araç var.
</details>

**E4.** `~/gorev/bolum-e/paket/gerekli-arac.txt` dosyasını oku — bir görev için sistemde kurulu olmayan bir araç gerekiyor. O aracı doğru paket yöneticisi komutuyla kur, sonra dosyada istenen işlemi yapıp çıkan **kendi ürettiğin değeri** (dosya/dizin sayısı) not al.

<details><summary>İpucu (korkaklar için)</summary>

Önce `which <araç>` ile kurulu olmadığını doğrula. Kurulumdan önce paket indekslerini güncellemen gerekebilir.
</details>

---

## Bölüm F — Kullanıcı/Grup, İzinler, ACL, sudo, Araçlar (Gün 5)

**F1.** Sistemde daha önce açılmış bir **servis hesabı** var. Bu hesabın kullanıcı adını ve içinde `KOD-N` geçen açıklama (GECOS) alanını, doğrudan kaynağından okuyarak bul — `id`/`getent` gibi araçlar kullanmadan, dosyanın kendisine bak.

<details><summary>İpucu (korkaklar için)</summary>

Kullanıcı bilgilerinin tutulduğu dosyayı Gün 5'te işlemiştin — 5. alan (GECOS) serbest metin içerir.
</details>

**F2.** `~/gorev/bolum-f/acl/hassas.txt` dosyasını okumayı dene. `ls -l` çıktısına göre bu senin için **imkânsız** görünüyor (owner sen değilsin, group/other izni de yok) — ama yine de okuyabiliyor musun, dene. Nasıl mümkün olduğunu bul, içindeki `KOD-O`'yu oku.

<details><summary>İpucu (korkaklar için)</summary>

`ls -l` çıktısının izin bitlerinin **sonunda** normalde görmediğin bir işaret var mı kontrol et. O işaret varsa, klasik 9 bitin ötesinde ek bir yetkilendirme katmanı olduğunu gösterir — o katmanı gösteren ayrı bir komut var.
</details>

**F3.** `~/gorev/bolum-f/sahiplik/veri.txt` dosyasının, **senin kullanıcın tarafından** sahiplenilmiş ve sadece senin okuyup yazabildiğin (başka kimsenin dokunamadığı) bir dosya olması gerekiyordu — ama şu an öyle değil. Durumu düzelt (hem sahiplik hem izin), sonra içindeki `KOD-P`'yi oku.

<details><summary>İpucu (korkaklar için)</summary>

Sahipliği değiştiren komut ile izni değiştiren komut ayrı ayrı iki komuttur. Sonuç izni üç haneli, sadece owner'a okuma+yazma veren bir değer olmalı.
</details>

**F4.** Sistemde `raportor` adında bir hesap var (parola: `raportor123`). O hesaba geç, `sudo` ile **nelere izinli olduğunu** keşfet, izinli olduğun komutu çalıştırıp `KOD-Q`'yu bul. Sonra `sudo whoami` ya da `sudo cat /etc/shadow` gibi tamamen farklı bir şey dene — ne oluyor, neden?

<details><summary>İpucu (korkaklar için)</summary>

Bir kullanıcıya tanımlı tüm sudo kurallarını listeleyen bir bayrak var (`sudo -l`). Kurallar `sudoers` dosyalarında komut bazlı tanımlanır — sadece izin verilen **tam komut** çalışır, başka hiçbir şey çalışmaz.
</details>

**F5.** `~/gorev/bolum-f/sshd/sshd_config.orig` ve `sshd_config` iki farklı sürüm. Aralarında ne değişmiş, bul — değişen satırdaki değer `KOD-R`'dir.

<details><summary>İpucu (korkaklar için)</summary>

İki dosya arasındaki farkı satır satır gösteren, Gün 4'te de kullandığın komutu hatırla.
</details>

**F6.** `~/gorev/bolum-f/derin/` altında, epey derin bir dizin yapısının içinde bir yapılandırma dosyası var, içinde `KOD-S` var. Dosyanın **tam yolunu bilmeden**, sadece adını bilerek bul. İlk denemende muhtemelen **hiçbir sonuç** almayacaksın — neden almadığını düşün, düzelt, tekrar dene.

<details><summary>İpucu (korkaklar için)</summary>

Kullanacağın araç canlı tarama yapmaz, önceden çıkarılmış bir **indeks**i sorgular. İndeks güncel değilse yeni dosyalar görünmez — indeksi elle güncelleyen bir komut var.
</details>

**F7.** Bu makinede `8080` portunda çalışan bir web servisi var. Önce `curl` ile `http://localhost:8080/gizli.txt` adresinin içeriğini **ekrana bastır**, içindeki `KOD-T`'yi oku. Sonra aynı dosyayı `wget` ile, **`indirilen.txt`** adıyla diske kaydet ve kaydettiğini doğrula.

<details><summary>İpucu (korkaklar için)</summary>

`curl` varsayılan olarak aldığı içeriği ekrana basar, dosyaya kaydetmez. `wget`'in çıktı dosyasının adını belirleyen bir bayrağı var.
</details>

---

## Bölüm G — Süreç ve Servis Yönetimi (Gün 6)

> Bu bölümden itibaren senaryo değişiyor: dosya avı değil, **çalışan bir sistemi teşhis edip düzeltmek**. Çoğu görevin "cevabı" bir durum: servis `active` oldu, süreç durdu, hata kayboldu.

**G1.** Makine yavaş. Bir süreç bir CPU çekirdeğini tam kapasite meşgul ediyor. Onu **bul**, önce önceliğini en düşük seviyeye çek (sistemi bırakması için), sonra onu başlatan şeyi **kalıcı olarak** durdur (yeniden başlamasın). Durdurduğunu doğrula.

<details><summary>İpucu (korkaklar için)</summary>

Canlı süreç izleyen araçta CPU'ya göre sırala. Süreç bir systemd servisi tarafından başlatılmış olabilir — `ps` çıktısındaki komut adı ve `systemctl status <PID>` bunu söyler. Öncelik = `renice`; kalıcı durdurma = servisi `stop` + `disable`.
</details>

**G2.** `ps` çıktısında `Z` (defunct/zombi) durumunda bir süreç var. Onu **kimin** bıraktığını (parent PID) bul. Zombiye `kill -9` göndermeyi dene — ne oldu, neden? Zombiyi gerçekten temizle.

<details><summary>İpucu (korkaklar için)</summary>

Zombi zaten ölüdür — ona sinyal göndermek işe yaramaz. `ps -eo pid,ppid,stat,comm` ile parent'ı bul; asıl hedef parent'tır. Parent bir servisse onu yeniden başlatmak çocuğu reap eder.
</details>

**G3.** `gorev-rapor.service` servisi başlamıyor. **Neden** başlamadığını servisin kendi günlüğünden öğren, sorunu gider, servisi başarıyla çalıştır. Başarılı olunca ürettiği dosyada `KOD-U` var.

<details><summary>İpucu (korkaklar için)</summary>

`systemctl status gorev-rapor` ve `journalctl -u gorev-rapor` son hatayı gösterir — "No such file or directory" bir **yol** eksikliğini işaret eder. Servisin `ExecStart`'ındaki betiği (`systemctl cat`) okuyup nereye yazmaya çalıştığına bak.
</details>

**G4.** Düzenli çalışması gereken `gorev-bakim.service` şu an hiç başlatılamıyor — `systemctl start` "masked" diyor. Bu durumu düzelt, servisi bir kez çalıştır, günlüğünden `KOD-V`'yi oku.

<details><summary>İpucu (korkaklar için)</summary>

"masked" = `/dev/null`'a symlink'lenmiş, kasıtlı olarak engellenmiş. Tersi bir `systemctl` alt komutu var. Sonra `start` + `journalctl -u ...`.
</details>

**G5.** Bu makinede dinleme yapan (LISTEN) tüm TCP portlarını, her birini hangi süreç/servisin tuttuğuyla birlikte listele. `8080` ve `8090` portlarını hangi servisler açmış, PID'leri kaç? (Sabit KOD yok — kendi bulduğun değerleri yaz.)

<details><summary>İpucu (korkaklar için)</summary>

Soket istatistiği veren araç, `-t` (tcp), `-l` (listen), `-n` (isim çözme yok), `-p` (süreç) bayraklarıyla tam bunu verir. Root gerekebilir.
</details>

---

## Bölüm H — Log, Zamanlanmış Görev, Log Rotasyonu (Gün 6)

**H1.** Bu boot'ta bir servis journald'e **kritik seviyede** (`err`) bir hata yazdı. Zaman/önem filtreleriyle o kaydı bul, içindeki `KOD-W`'yi oku.

<details><summary>İpucu (korkaklar için)</summary>

`journalctl` önem derecesine (`-p err`) ve boot'a (`-b`) göre filtrelenebilir. Kaydı yazan etiket `gorev-app`.
</details>

**H2.** `/etc/cron.d/gorev-rapor` her dakika bir rapor üretmeli ama `~/gorev/bolum-h/rapor-cikti.txt` boş kalıyor. Cron'un **neden** başaramadığını günlüğünden gör, cron kuralını düzelt, bir-iki dakika içinde dosyaya `KOD-X` satırının düştüğünü doğrula.

<details><summary>İpucu (korkaklar için)</summary>

`journalctl -u cron` cron'un her dakika CMD'yi **denediğini** gösterir ama çıktı yok. Kuralın sözdizimi doğru, komut **yolu** yanlış — `ls` ile yok olduğunu gör, `find / -name ...` ile gerçek yeri (`/opt/gorev/`) bul. `cron.d` satırında komuttan önce kullanıcı alanı (`ogrenci`) vardır.
</details>

**H3.** `/var/log/gorev-app.log` sınırsız büyüyor, hiç rotasyon kuralı yok. Bu log için bir `logrotate` kuralı yaz (günlük, 7 kopya, sıkıştırma). Önce **kuru çalıştırma** (`-d`) ile ne yapacağını gör, sonra **zorla** (`-f`) bir rotasyon yaptır. `.1` dosyasının oluştuğunu ve yeni logun boş başladığını doğrula.

<details><summary>İpucu (korkaklar için)</summary>

Kurallar `/etc/logrotate.d/` altına ayrı dosya olarak konur (paket deseni). `daily`, `rotate 7`, `compress`, `missingok`, `notifempty` yönergeleri. Test: `sudo logrotate -d /etc/logrotate.d/gorev-app` sonra `-f`.
</details>

**H4.** `last` ile bu makineye yapılan giriş kayıtlarına bak. `ogrenci` bu boot'ta kaç kez ve nereden (hangi IP) SSH ile giriş yaptı? (Kendi bulduğun değeri yaz — `wtmp` ikili bir dosyadır, editörle açılmaz.)

<details><summary>İpucu (korkaklar için)</summary>

`last`, `/var/log/wtmp` ikili dosyasını okunur hale getirir. `last -a` kaynak adresi/host'u sağ sütunda gösterir. Bu boot'la sınırlamak için `last -s today` ya da `journalctl -u ssh` içinde "Accepted".
</details>

---

## Bölüm I — Ağ Temelleri, Soket İstatistiği, Firewall (Gün 7)

Bu bölümde sabit KOD yoktur (I4 sonrası KOD-T tekrar erişilebilir olur) — arayüz adı, IP/prefix, gateway, network/broadcast adresi, kullanılabilir host aralığı, port durumları gibi **kendi ürettiğin** değerleri kaydet.

**I1.** Bu makinenin aktif ağ arayüzünün adını, IPv4 adresini + prefix uzunluğunu (CIDR), ve varsayılan ağ geçidini (gateway) bul.

<details><summary>İpucu (korkaklar için)</summary>

`ip -brief address` kısa bir özet verir; `ip route` içindeki `default via ...` satırı gateway'i söyler.
</details>

**I2.** I1'de bulduğun IP/prefix'ten yola çıkarak: bu ağın **network adresi**, **broadcast adresi**, **kullanılabilir host aralığı** (ilk–son) ve **toplam kullanılabilir host sayısı** nedir? Elle hesapla, sonra bir araçla doğrula.

<details><summary>İpucu (korkaklar için)</summary>

`ipcalc <ip>/<prefix>` hepsini birden verir. /24 için: network = son oktet `.0`, broadcast = `.255`, kullanılabilir = `.1`–`.254` (254 host).
</details>

**I3.** `8080` portundaki web servisine `curl http://localhost:8080/gizli.txt` ile ulaşmayı dene — takılıyor/başarısız. Bunun bir **firewall** sorunu olduğunu kanıtla (kuralları listele), engelleyen kuralı bul, **sadece o kuralı** kaldır (topyekûn flush yapma), `curl`'ün tekrar çalıştığını ve `KOD-T`'yi verdiğini doğrula.

<details><summary>İpucu (korkaklar için)</summary>

`sudo nft list ruleset` tüm nftables kurallarını gösterir — senaryo kuralı `inet gorev_fw` adlı ayrı bir tabloda, `tcp dport 8080 drop`. Onu uygulayan bir systemd servisi de var (`gorev-fw`); kalıcı çözüm için onu da durdur/disable et.
</details>

**I4.** `8080` (web), `22` (ssh) ve `9999` (kapalı) portlarının localhost'ta açık mı kapalı mı olduğunu bir port test aracıyla kontrol et. I3'ten **önce ve sonra** 8080 için sonucu karşılaştır.

<details><summary>İpucu (korkaklar için)</summary>

`nc -zv localhost <port>` bir portun bağlantı kabul edip etmediğini söyler (`-z` = veri gönderme, sadece tara; `-v` = sonucu yaz).
</details>

**I5.** Ağ geçidine `ping` at (3 paket). Sonra `traceroute` ile geçide giden yolu çıkar. `ping` çalışıyor ama internetteki bir adrese `ping` çalışmıyorsa bu ne anlama gelir — DNS mi, yönlendirme mi, firewall mı? Kısa bir cümleyle yaz.

<details><summary>İpucu (korkaklar için)</summary>

`ping` ICMP kullanır, isim yerine doğrudan IP verirsen DNS devre dışı kalır — böylece sorunu isim çözme mi bağlantı mı diye ayırabilirsin.
</details>

---

## Bölüm J — İsim Çözümleme: /etc/hosts, nsswitch, dig (Gün 8)

**J1.** `~/gorev/bolum-j/app/kontrol.sh` betiği, bir iç API'ye (`api.local.gorev`) bağlanıp durum almalı ama başarısız oluyor. Sorunun **isim çözümleme** kaynaklı olduğunu kanıtla (isim hangi IP'ye çözülüyor, bu doğru mu?), düzelt, betiğin `KOD-Y`'yi getirdiğini doğrula.

<details><summary>İpucu (korkaklar için)</summary>

`getent hosts api.local.gorev` ismin hangi IP'ye gittiğini söyler; `dig api.local.gorev` ise DNS'te hiç olmadığını (yani kaydın sadece bir dosyada olduğunu) gösterir. O dosya `/etc/hosts`. API aslında `127.0.0.1:8090`'da.
</details>

**J2.** `/etc/nsswitch.conf` içindeki `hosts:` satırına bak. `api.local.gorev` DNS'te yokken bile neden çözülebiliyordu (J1'den önce yanlış da olsa bir cevap dönüyordu)? Satırdaki sıralama ne anlatıyor?

<details><summary>İpucu (korkaklar için)</summary>

`hosts: files dns` → önce `/etc/hosts` (`files`), sonra DNS (`dns`). `files` bir cevap verirse DNS'e hiç gidilmez.
</details>

**J3.** `dig` aracının mekaniğini pekiştir (VM'de internet varsa): bir alan adının A kaydını sorgula (`dig +short`), MX kayıtlarını al, bir IP için ters (PTR) sorgu yap (`dig -x`), belirli bir DNS sunucusuna sor (`dig @1.1.1.1`). ANSWER bölümündeki kayıt sayısını ve TTL'i not al. (İnternet yoksa `dig api.local.gorev` ile "DNS'te yok" cevabını gözlemle — J1/J2'nin kanıtı.)

<details><summary>İpucu (korkaklar için)</summary>

`dig google.com A +short`, `dig google.com MX`, `dig -x 1.1.1.1`, `dig @9.9.9.9 debian.org`. Çıktının `;; ANSWER SECTION` kısmına ve satır başındaki TTL sütununa bak.
</details>

**J4.** `host` ve `whois` araçlarını dene (internet varsa): bir IP'nin ters kaydını `host` ile bul; bir alan adının kayıt firmasını (registrar) / oluşturulma tarihini `whois` ile öğren. (Bunlar mekanik alıştırma — sabit değer beklenmez.)

---

## Bölüm K — SSH: Anahtar, Sertleştirme, Tünel, Aktarım (Gün 9)

Bu bölümde `sshtest` / `sshtest123` hesabına (aynı makinede, `localhost` üzerinden) bağlanacaksın.

**K1.** Kendine bir SSH anahtar çifti üret (ed25519), **açık** anahtarını `sshtest` hesabına kur, sonra `sshtest@localhost`'a **parola girmeden** bağlanıp `~/kod.txt` içindeki `KOD-Z`'yi oku.

<details><summary>İpucu (korkaklar için)</summary>

`ssh-keygen -t ed25519 -f ~/.ssh/gorev_key -N ''` → `ssh-copy-id -i ~/.ssh/gorev_key.pub sshtest@localhost` (bir kez `sshtest123` sorar) → `ssh -i ~/.ssh/gorev_key sshtest@localhost 'cat kod.txt'`.
</details>

**K2.** `/etc/ssh/sshd_config.d/60-gorev.conf` içinde güvensiz bir ayar var: `PermitRootLogin yes`. Bunu güvenli bir değere çek, yapılandırmayı **yazmadan önce** doğrula (`sshd -t`), servisi yeniden yükle, etkin değeri kontrol et. (Kendi ürettiğin değer: `sshd -T | grep permitrootlogin` çıktısı.) `2224` üzerinden kendi bağlantın etkilenmez.

<details><summary>İpucu (korkaklar için)</summary>

Güvenli değerler: `no` ya da `prohibit-password`. `sudo sshd -t` sözdizimi kontrolü; `sudo systemctl reload ssh`; `sudo sshd -T | grep -i permitrootlogin` etkin (birleştirilmiş) değeri verir.
</details>

**K3.** Bu makinede yalnızca **`127.0.0.1:8090`**'a bağlı bir iç servis var (dışarıdan erişilemez — Bölüm J'deki API). `sshtest@localhost` üzerinden **yerel port yönlendirme** (`-L`) kurarak bu servise `9090` portundan ulaş ve `http://localhost:9090/tunel.txt` içindeki `KOD-AA`'yı oku. Sonra tüneli kapat. (Bu, `ssh -L`'in klasik kullanımıdır: yalnızca uzak uçta loopback'e bağlı bir servise erişmek.)

<details><summary>İpucu (korkaklar için)</summary>

`ssh -i ~/.ssh/gorev_key -L 9090:127.0.0.1:8090 -N -f sshtest@localhost` — `-L yerel:hedef_host:hedef_port`, `-N` komut çalıştırma yok, `-f` arka plan. Kapatmak için `pgrep -af 'ssh .*9090'` → `kill`.
</details>

**K4.** `~/gorev/bolum-k/veri/` klasörünü `rsync` ile `sshtest@localhost:/tmp/gorev-veri/` altına aktar. Sonra iki taraftaki dosyaların **sha256** özetlerini karşılaştırarak aktarımın bozulmadığını doğrula. `rsync`'i bir kez daha çalıştır — bu sefer neden "hiçbir şey aktarılmadı"?

<details><summary>İpucu (korkaklar için)</summary>

`rsync -av -e 'ssh -i ~/.ssh/gorev_key' ~/gorev/bolum-k/veri/ sshtest@localhost:/tmp/gorev-veri/`. Doğrulama: `sha256sum ~/gorev/bolum-k/veri/*` vs `ssh sshtest@localhost 'sha256sum /tmp/gorev-veri/*'`. `rsync` sadece **değişen** dosyaları gönderir.
</details>

**K5.** `ssh-agent` başlat, anahtarını `ssh-add` ile ekle, `ssh-add -l` ile parmak izini (fingerprint) gör. Artık `-i` vermeden `ssh sshtest@localhost` çalışıyor mu? (Kendi ürettiğin değer: anahtarın `SHA256:...` parmak izi.)

<details><summary>İpucu (korkaklar için)</summary>

`eval "$(ssh-agent -s)"` → `ssh-add ~/.ssh/gorev_key` → `ssh-add -l`. Agent çalışırken ssh anahtarı otomatik kullanır.
</details>

---

## Bölüm L — dd, Otomatik Başlatma, Paket Deposu, tmux (Gün 9)

**L1.** `dd` ile `/dev/sda`'nın **ilk sektörünü** (512 bayt) oku ve son iki baytına bak. Bu "boot signature" değeri nedir? (Kendi bulduğun değeri yaz — hex olarak.)

<details><summary>İpucu (korkaklar için)</summary>

`sudo dd if=/dev/sda bs=512 count=1 2>/dev/null | xxd | tail -2` — son satırın sonundaki iki bayt. Klasik MBR/protective-MBR imzası `55 aa`.
</details>

**L2.** `gorev-web.service` her açılışta otomatik başlıyor mu? `systemctl is-enabled` ile kontrol et, `enable` işleminin `/etc/systemd/system/` altında **hangi symlink'i** oluşturduğunu bul. Debian'da `apt install` ile kurulan bir servis genelde otomatik enable+start olur; RHEL/Rocky'de `dnf install` sonrası servis **disabled** gelir — bu farkın sebebi ne? (Kısa bir cümle.)

<details><summary>İpucu (korkaklar için)</summary>

`systemctl is-enabled gorev-web` ve `ls -l /etc/systemd/system/multi-user.target.wants/ | grep gorev`. Debian'ın politikası (`policy-rc.d` / `deb-systemd-helper`) paket kurulumunda servisi etkinleştirir; RHEL etmez.
</details>

**L3.** `sudo apt update` bir hata veriyor. Hatayı oku, **hangi depo dosyasının** sorun çıkardığını bul, o dosyayı kaldır, `apt update`'in temiz çalıştığını doğrula.

<details><summary>İpucu (korkaklar için)</summary>

Hata mesajı çözümlenemeyen bir host adı içerir (`apt.olmayan.gorev`). Depolar `/etc/apt/sources.list.d/` altında ayrı dosyalardadır — hangisinin bu URL'yi içerdiğini `grep -r` ile bul.
</details>

**L4.** Uzun sürecek bir işi (`sleep 600` ya da `top`) bir `tmux` oturumunda başlat, oturumdan **ayrıl** (detach), SSH bağlantını **tamamen kapat**, yeniden bağlan ve oturuma **geri dön** (attach) — iş hâlâ çalışıyor mu? Bu neden `nohup` / `&` ile arka plana atmaktan farklı/daha iyi?

<details><summary>İpucu (korkaklar için)</summary>

`tmux new -s gorev` → işi başlat → `Ctrl-b` sonra `d` (detach). Yeniden: `tmux ls` → `tmux attach -t gorev`. tmux tam bir terminal oturumu tutar — geri dönüp etkileşime devam edebilirsin.
</details>

**L5.** Sık kullandığın bir komuta kalıcı bir `alias` tanımla (örn. `gd='systemctl status gorev-web --no-pager'`), yeni bir kabuk açıp çalıştığını doğrula. `type gd` ne diyor? (`~/.bashrc`'ye ekle, `source` et.)

<details><summary>İpucu (korkaklar için)</summary>

`alias gd='...'` satırını `~/.bashrc` sonuna ekle → `source ~/.bashrc` (ya da yeni SSH oturumu). `type gd` bir şeyin alias mı, dosya mı, builtin mi olduğunu söyler.
</details>

---

## Bitirince

Topladığın kodları (`KOD-A`'dan `KOD-AA`'ya) ve Bölüm C–L'de kendi ürettiğin değerleri (UUID, inode numaraları, PID'ler, subnet broadcast/host aralığı, port durumları, `sshd -T` çıktısı, boot signature, anahtar parmak izi...) bir kenara yaz. Kontrol için: [Cevaplar](Cevaplar.md).

Her bölümü bitirdikçe ilgili gün notlarındaki "Hedefler" / "Sorular / Takip Edilecekler" kısımlarını gözden geçir:
- Bölüm A–F → [Gün 1](../Kamp%20Eğitim/Gün%201.md) [Gün 2](../Kamp%20Eğitim/Gün%202.md) [Gün 3](../Kamp%20Eğitim/Gün%203.md) [Gün 4](../Kamp%20Eğitim/Gün%204.md) [Gün 5](../Kamp%20Eğitim/Gün%205.md)
- Bölüm G–H → [Gün 6](../Kamp%20Eğitim/Gün%206.md) · Bölüm I → [Gün 7](../Kamp%20Eğitim/Gün%207.md) · Bölüm J → [Gün 8](../Kamp%20Eğitim/Gün%208.md) · Bölüm K–L → [Gün 9](../Kamp%20Eğitim/Gün%209.md)

Hâlâ soru işareti kalan bir yer varsa söyle, birlikte netleştirelim.
