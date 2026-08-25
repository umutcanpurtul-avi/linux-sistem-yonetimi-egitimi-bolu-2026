---
tags:
  - egitim/linux-sistem-yonetimi
tarih: 2026-08-24
konular:
  - Gün 1 + Gün 2 + Gün 3 pratik tekrarı
---

# Gün 1-3 Pratik Challenge

Bağlantı: [Linux Sistem Yönetimi Eğitimi](../README.md) · [Gün 1](../Kamp%20Eğitim/Gün%201.md) · [Gün 2](../Kamp%20Eğitim/Gün%202.md) · [Gün 3](../Kamp%20Eğitim/Gün%203.md) · Cevaplar: [Cevaplar](Cevaplar.md)

> [!WARNING]
> **Bu challenge, sadece Gün 1, Gün 2 ve Gün 3'te **işlenen konularla sınırlıdır.** Her görevde bir **İpucu** kutusu var (küçük bir yönlendirme — hangi komut ailesine bakman gerektiğini söyler ama tam komutu vermez). Tam çözümler ayrı bir dosyada: [Cevaplar](Cevaplar.md) — önce kendin dene, sadece gerçekten takıldığında oraya bak.**

## Senaryo

Bu makinede senden önce çalışmış bir sistem yöneticisinin **dağınık ev dizini** var. Dosya adları gerçekçi ama neyin ne işe yaradığı adından belli değil. Görev metinleri de bilerek **hangi komutu kullanacağını söylemiyor** — bunu senin çözmen gerekiyor. Her görevde ya bir değer (`KOD-X`) bulacaksın ya da bir ayar/işlem yapıp ortaya çıkan gerçek bir değeri (inode numarası, UUID, izin biti, dosya boyutu...) kaydedeceksin.

## Ortam

- **VM:** `Debian-Challenge` — ders makinesinden (`Debian-Egitim`) **tamamen ayrı**, sadece bu challenge için kurulmuş, tek amaçlı bir sanal makine. Debian 13 (Trixie), minimal (GUI'siz) kurulum.
- **Erişim:** `ssh -p 2224 ogrenci@127.0.0.1` — şifre `ogrenci123`.

  > [!tip] Bu, herkese açık/paylaşılabilir bir **pratik makinesi parolasıdır** — gerçek/kişisel hiçbir bilgi içermez.
- Giriş yaptığında ev dizininde hazır bir **`~/gorev/`** klasörü bulacaksın. Hiçbir şey senin oluşturman gerekmiyor.
- Ayrıca VM'e **ikinci bir disk zaten takılı** (~1.2 GB, boş, Bölüm C/D için). Disk/mount bölümündeki hiçbir adımı ana diskte (`/dev/sda`) **denemeyin** — sadece ikinci diskte çalışın.

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

## Bitirince

Topladığın kodları (`KOD-A`'dan `KOD-J`'ye) ve Bölüm C/D'de kendi ürettiğin değerleri (UUID, inode numaraları, aygıt sayıları...) bir kenara yaz. Kontrol için: [Cevaplar](Cevaplar.md). Her bölümü bitirdikçe [Gün 1](../Kamp%20Eğitim/Gün%201.md), [Gün 2](../Kamp%20Eğitim/Gün%202.md) ve [Gün 3](../Kamp%20Eğitim/Gün%203.md) notlarındaki "Hedefler"/"Sorular" kısımlarını gözden geçir, hâlâ soru işareti kalan bir yer varsa söyle, birlikte netleştirelim.
