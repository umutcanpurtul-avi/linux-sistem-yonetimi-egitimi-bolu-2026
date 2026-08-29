---
tags:
  - egitim/linux-sistem-yonetimi
tarih: 2026-08-29
konular:
  - DNS nedir, DNS servisi nedir, nasıl çalışır
  - "/etc/hosts"
  - "/etc/nsswitch.conf"
  - nslookup (eski) ve dig (yeni)
  - dig ile isimden IP çözme
  - host ile IP'den isim çözme (reverse / PTR)
  - whois komutu
  - Uygulamalı örnek — iki sunuculu WordPress (Apache + PHP ⟷ uzak MariaDB)
---

# Gün 8

Bağlantı: [Linux Sistem Yönetimi Eğitimi](../README.md) · [00 - Eğitim Planı](../00%20-%20Eğitim%20Planı.md) · [Gün 7](Gün%207.md)

## İşlenen Konular

Günün ilk yarısı **DNS ve isim çözümleme araçları**, ikinci yarısı iki makine üzerinde
**WordPress + uzak veritabanı** uygulamasıydı.

- **DNS nedir?**
- **DNS servisi nedir?**
- **DNS servisi nasıl çalışır?**
- DNS ile ilgili dosyalar: `/etc/hosts`, `/etc/nsswitch.conf`
- `nslookup` eski, `dig` yeni — **`dig` nedir, nasıl kullanılır?**
- İsimden IP çözme → `dig`
- IP'den isim çözme → `host`
- `whois` komutu

Uygulama — WordPress kurulumu:

1. **192.168.56.101** — Debian sunucu (kullanıcı `ucp`), üzerine **WordPress + Apache2** kurulacak.
2. **192.168.56.102** — Ubuntu makine (kullanıcı `ucp`), üzerine **veritabanı sunucusu (MariaDB)** kurulacak.

101 sunucusuna WordPress ve Apache2, 102 içine SQL veritabanı sunucusu kurulup iki uygulama
birbirine bağlanacak. `/home/umutcanpurtul/` altındaki `101terminal.txt` ve `102terminal.txt`
dosyalarında derste kullanılan komutlar var (aşağıda "Uygulamalı Örnek" başlığında satır satır
çözümlendi).

## Genişletilmiş Anlatım (Öğrenme İçin Ek Açıklamalar)

> [!WARNING]
> **Yukarıda bulunan kısa notların AI ile genişletilmiş halidir. Bilgiler sadece o gün işlenen konular ile sınırlandırılmış olup referans olması için eklenmiştir. Lütfen bu genişletilmiş metni kendi araştırmalarınıza bir ön bilgi olarak kullanın ve testlerinizi sadece burayı kullanarak değil, farklı kaynaklardan da yararlanarak yapın.**

> [!NOTE]
> **DNS kavramının temeli **Gün 7'de** işlenmişti (`bkz.` [Gün 7#8. DHCP ve DNS](Gün%207.md#8-dhcp-ve-dns)): dağıtık veritabanı, UDP/TCP port 53, kök → TLD → yetkili sunucu hiyerarşisi, özyinelemeli (recursive) vs. yinelemeli (iterative) sorgu, TTL/önbellek. Bu gün **aynı konuyu sıfırdan tekrar etmiyoruz**; bunun yerine (a) "DNS **servisi**" derken kastedilen yazılımın ne olduğu, (b) Linux istemcisinin bir ismi çözerken izlediği yol (`/etc/hosts` → `/etc/nsswitch.conf` → resolver → DNS) ve (c) teşhis araçları (`dig`, `host`, `whois`) ele alınıyor.**

### 1. DNS servisi nedir, "çözümleme" istemci tarafında nasıl başlar

**Katman ve mekanizma.** DNS, OSI'nin uygulama katmanında çalışan bir isim–kayıt veritabanıdır; taşıma olarak neredeyse her sorgu **UDP port 53** ile gider, cevap 512 bayttan büyükse veya zone transfer (AXFR) yapılıyorsa **TCP port 53** kullanılır. "DNS" tek bir program değil, bir **protokol + veri modeli**dir; bu protokolü konuşan üç ayrı rol vardır ve "DNS servisi" derken bunlardan hangisinin kastedildiği önemlidir:

| Rol | Görevi | Linux'ta tipik yazılım |
| --- | --- | --- |
| **Stub resolver** (istemci kütüphanesi) | Uygulamanın `getaddrinfo()` çağrısını alıp bir özyinelemeli sunucuya soru soran, cevabı uygulamaya döndüren kod. Kendi başına hiyerarşiyi gezmez. | glibc'nin içindeki resolver + `systemd-resolved` (varsa) |
| **Recursive (caching) resolver** | İstemci adına kök/TLD/yetkili sunucuları sırayla gezip nihai cevabı bulan, sonucu TTL boyunca önbelleğe alan sunucu. | `unbound`, `bind9` (named), `dnsmasq`, `systemd-resolved`, ya da ISS'nin / `8.8.8.8` gibi genel bir çözücünün sunucusu |
| **Authoritative (yetkili) server** | Bir alan adının (`example.com`) kayıtlarının **asıl kaynağı**; o zone için "kesin cevap" verir, başkasına sormaz. | `bind9` (named), `nsd`, `knot`, `PowerDNS` |

**Ne / nasıl / ne zaman / neden / kim.** Bir uygulama (`ping`, tarayıcı, `curl`) bir isme bağlanacağı zaman kendi başına DNS paketi üretmez; glibc'nin `getaddrinfo()` fonksiyonunu çağırır (**kim**: uygulama süreci, kendi kullanıcı bağlamında). glibc de "bu ismi nereye sorayım" kararını **`/etc/nsswitch.conf`** dosyasına bakarak verir (**nasıl** — 3. başlık). Sıra `dns`'e geldiğinde stub resolver, **`/etc/resolv.conf`** dosyasındaki `nameserver` satırındaki adrese bir özyinelemeli sorgu yollar (**ne zaman**: isim ilk kez veya önbellekteki TTL dolduğunda). O özyinelemeli sunucu hiyerarşiyi gezer (Gün 7'de anlatıldı), cevabı bulur, kaydı **TTL** süresince önbellekte tutar (**neden önbellek**: her sorgu için kök sunuculara gitmek hem yavaş hem de kök altyapısını boğardı — önbellek olmadan internet ölçeklenmez).

**Kayıt (record) türleri** — bir DNS cevabının içinde ne döner:

- **A** → isim → IPv4 adresi. **AAAA** → isim → IPv6 adresi.
- **CNAME** → isim → başka bir isim (takma ad; "asıl adı şudur, onu çöz").
- **NS** → bir zone'un yetkili sunucularının isimleri (delegasyon bu kayıtla yapılır).
- **MX** → o alan adının e-postasını hangi sunucu(lar) kabul eder (+ öncelik değeri).
- **PTR** → IP adresi → isim (ters çözüm; 6. başlık).
- **SOA** → zone'un "başlangıç" kaydı: birincil yetkili sunucu, yenileme/expire süreleri, seri numarası.
- **TXT** → serbest metin; pratikte SPF/DKIM/alan doğrulama için kullanılır.

**Tasarım gerekçesi.** İsimleri tek bir merkezî dosyada tutmanın neden bırakıldığı 2. başlıkta (HOSTS.TXT hikâyesi); DNS'in getirdiği şey **hiyerarşik yetki devri** (her kurum kendi zone'unu yönetir) + **önbellekleme** + **çoğaltma (replikasyon)**dır. "DNS servisi kur" denince pratikte ya bir **caching resolver** (ağdaki makineler hızlı çözsün, dışarıya tek noktadan çıkılsın) ya da bir **authoritative server** (kendi alan adının kayıtlarını sen yayınla) kurulur — bu eğitimde ikisi de ileride ayrı ele alınacak; bugün sadece **istemci tarafı** ve teşhis araçları var.

### 2. `/etc/hosts` — DNS'ten ön(veya sonra) bakılan yerel isim tablosu

**Mekanizma ve katman.** `/etc/hosts` düz metin bir dosyadır; her satır `IP  isim [takma-adlar...]` biçimindedir. Bu dosyayı **DNS altyapısı değil**, glibc'nin NSS `files` eklentisi (`libnss_files.so`) okur — yani `getaddrinfo()` çağrısı sırasında, `/etc/nsswitch.conf`'taki `hosts:` satırında `files` nerede yazıyorsa o sırada devreye girer. Ağ, port, sunucu yoktur; sadece bir dosya okuması. `systemd-resolved` kuruluysa bu dosyayı **kendi içinde** ayrıca işler ve sonucu önbelleğe alır.

**Ne zaman / neden / kim.** Tarihsel olarak bu dosya **DNS'ten önce** vardı: 1970'ler–80'lerde ARPANET'teki her makinenin adı, SRI'nin Network Information Center'ında merkezî olarak tutulan tek bir **`HOSTS.TXT`** dosyasındaydı; her host bu dosyayı FTP ile indirip kendi `/etc/hosts`'unu ondan üretirdi. Makine sayısı büyüyünce (dosyanın dağıtımı yavaşladı, tek düzenleme noktası darboğaz oldu) 1983–84'te DNS bu işi otomatikleştirdi. `/etc/hosts` bugün hâlâ duruyor çünkü:

- **Önyükleme / DNS yokken**: DNS sunucusuna ulaşmadan çözülmesi gereken isimler (kendi hostname'in `127.0.1.1` satırı Debian/Ubuntu'da bu yüzden vardır).
- **Yerel geçersiz kılma (override)**: bir alan adını test için kendi sunucuna yönlendirmek (`93.184.216.34 example.com` yerine `10.0.0.5 example.com`).
- **Küçük/izole ağlar**: DNS sunucusu kurmaya değmeyen lab ağında birkaç makineyi isimle çağırmak — **bu günkü uygulamada** 101 makinesine `192.168.56.102 db.egitim.local` satırı eklenip WordPress'in veritabanına isimle bağlanması tam bu senaryodur.
- **Basit reklam/parazit engelleme**: istenmeyen alan adlarını `0.0.0.0`'a düşürmek.

**Kim / hangi ayrıcalık.** Dosyayı sadece root düzenler (`-rw-r--r--`), ama **herkes okur** — çözümleme sırasında her kullanıcının süreçleri bu dosyaya bakar.

Örnek:

```
127.0.0.1       localhost
127.0.1.1       debian-egitim
192.168.56.102  db.egitim.local   db
```

> [!TIP]
> **`/etc/hosts` mi önce DNS mi önce? Bu **sabit değildir**, `/etc/nsswitch.conf`'taki sıraya bağlıdır (3. başlık). Klasik Debian'da `files dns` → önce dosya. `systemd-resolved`'lı bir Ubuntu'da satır `resolve [!UNAVAIL=return]` içerebilir ve `resolved` `/etc/hosts`'u kendi içinde işlediği için sonuç yine "önce yerel dosya" olur ama yol farklıdır.**

### 3. `/etc/nsswitch.conf` — hangi bilgiyi hangi kaynaktan, hangi sırayla

**Mekanizma ve köken.** NSS (Name Service Switch), **glibc**'nin bir özelliğidir. Fikir Sun Microsystems'in Solaris 2'sinden gelir: eskiden `passwd`, `group`, `hosts` gibi bilgilerin tek kaynağı sabit dosyalardı (`/etc/passwd` vb.); NIS ve DNS gibi ağ kaynakları çıkınca "aynı bilgi birden çok yerden, belirli bir öncelik sırasıyla gelebilsin" ihtiyacı doğdu. Çözüm: her **veritabanı** (satır başındaki `passwd:`, `group:`, `shadow:`, `hosts:`, `services:`, `networks:` …) için, glibc'nin sırayla deneyeceği **kaynak listesi**. Kaynaklar `libnss_<isim>.so` paylaşımlı kütüphaneleridir — `files` → `libnss_files.so`, `dns` → `libnss_dns.so`, `resolve` → `libnss_resolve.so` (systemd), `myhostname`, `mymachines`, `mdns` …

**`hosts:` satırı ve eylem (action) kuralları.** Kaynaklar soldan sağa denenir; bir kaynağın sonucuna göre `[DURUM=eylem]` köşeli parantezleriyle davranış değiştirilir:

- Durumlar: `success`, `notfound`, `unavail` (kaynak yok/çalışmıyor), `tryagain` (geçici hata).
- Eylemler: `return` (dur, cevabı ver), `continue` (sıradaki kaynağa geç), `merge`.
- `[NOTFOUND=return]` → "bu kaynak 'böyle bir isim yok' dediyse, DNS'e sorma, olumsuz cevabı kabul et."
- `[!UNAVAIL=return]` → "kaynak **erişilebilir** olduğu sürece onun sonucuyla devam et (`!` = 'değil'); sadece kaynağın kendisi yoksa sıradakine geç." `systemd-resolved` satırında bu yüzden bu kalıp kullanılır: resolved ayaktaysa cevabı ondan al, ölüyse `dns`'e düş.

**Dağıtım farkı (2026-08 doğrulaması) — bu satır dağıtıma göre değişir:**

| Dağıtım | Tipik `hosts:` satırı | Neden |
| --- | --- | --- |
| **Debian 13 (trixie)** | `files dns` (kurulum profiline göre `myhostname` de eklenir) | Debian 13, **`systemd-resolved`'ı varsayılan kurmaz** — hatta 12→13 yükseltmesinde paket otomatik gelmez, elle `apt install systemd-resolved` gerekir. Kurulu değilse `/etc/resolv.conf` düz bir dosyadır ve `nameserver` satırları doğrudan DHCP/elle yazılır. |
| **Ubuntu Server 24.04 LTS** | İçinde `resolve [!UNAVAIL=return]` geçen, `dns`'ten önce | Ubuntu, 18.04'ten beri `systemd-resolved`'ı **varsayılan etkin** tutar; `/etc/resolv.conf` → `/run/systemd/resolve/stub-resolv.conf` sembolik bağıdır ve tek `nameserver` olarak **`127.0.0.53`** (yerel stub) görünür. Gerçek yukarı-akım DNS sunucuları `resolvectl status` ile görülür. |
| **Rocky / RHEL 9–10** | `files dns myhostname` | `systemd-resolved` genelde etkin değil; `/etc/resolv.conf`'u **NetworkManager** yönetir. DNS araçları `bind-utils` paketindedir (Debian/Ubuntu'da `bind9-dnsutils`). |

**Ne zaman / kim.** Bu dosyayı sistem yöneticisi; LDAP/AD ile merkezî kullanıcı (`passwd: files sss`), mDNS ile `.local` çözümü, veya `/etc/hosts`'un DNS'ten önce/sonra gelme sırasını ayarlarken düzenler. Değişiklik **anında** etkilidir (servis yeniden başlatma gerekmez), çünkü her yeni `getaddrinfo()` çağrısı dosyayı yeniden okur — ama uzun süre çalışan servisler resolver sonuçlarını kendi içinde önbelleğe almış olabilir.

### 4. `nslookup` (eski) → `dig` (yeni): neden araç değişti

**Tarihsel gerekçe.** `nslookup` da `dig` de ISC'nin **BIND** (Berkeley Internet Name Domain) paketinden gelir. `nslookup` daha eskidir ve iki sorunu vardır: (1) **kendi resolver rutinlerini** kullanır, sistemin `getaddrinfo()`/NSS yolunu **kullanmaz** — yani `nslookup`'ın verdiği cevap ile uygulamaların gerçekte aldığı cevap farklı olabilir (`/etc/hosts` ve `nsswitch.conf` `nslookup`'ı ilgilendirmez). (2) Etkileşimli, "kendine has" bir arayüzü ve sürüm/platforma göre değişen tutarsız davranışları vardır. ISC bu yüzden BIND kılavuzunda açıkça *"arcane user interface and frequently inconsistent behavior"* diyerek **`nslookup` kullanımını önermez**; modern teşhis aracı `dig`'dir.

**`dig` ne verir.** `dig` (**D**omain **I**nformation **G**roper) tek seferlik, betiklenebilir ve **DNS cevabının tamamını** ham hâlde gösteren bir sorgu aracıdır. Çıktısı gerçek DNS mesajının bölümlerini birebir yansıtır: `HEADER` (durum kodu — `NOERROR`, `NXDOMAIN`, `SERVFAIL`; bayraklar — `aa` yetkili cevap, `rd` recursion desired, `ra` recursion available), `QUESTION`, `ANSWER`, `AUTHORITY`, `ADDITIONAL`, ve alt bilgide **hangi sunucudan (`SERVER:`)**, **ne kadar sürede (`Query time:`)** cevap geldiği. Bu yüzden yönetici için `nslookup`'tan üstündür: `SERVFAIL` mi `NXDOMAIN` mi, cevap yetkili mi önbellekten mi, TTL kaç saniye — hepsi görünür.

**Paket / nereden okur.** Debian/Ubuntu: `apt install bind9-dnsutils` (eski adı `dnsutils`). Rocky/RHEL: `dnf install bind-utils`. `dig` de `host` da hangi sunucuya soracağını `/etc/resolv.conf`'tan alır (`@sunucu` ile geçersiz kılınır).

### 5. `dig` ile isimden IP çözme (forward lookup)

**Sözdizimi:** `dig [@sunucu] <isim> [tür] [+seçenekler]`. Tür yazılmazsa varsayılan **A** kaydıdır.

**Mekanizma.** `dig google.com` çalıştırdığında `dig`, `/etc/resolv.conf`'taki ilk `nameserver`'a **recursion desired (rd=1)** bayraklı bir A sorgusu yollar; o özyinelemeli sunucu işi yapıp cevabı döndürür, `dig` de tüm mesajı basar. `+trace` verildiğinde `dig` **özyinelemeli sunucuyu atlar** ve işi kendisi yapar: önce bir kök sunucuya sorar (".com'a kim bakıyor"), dönen NS kayıtlarını izleyip `.com` TLD sunucusuna sorar, oradan `google.com`'un yetkili sunucusuna iner — yani iteratif çözümü adım adım gözle görürsün.

**Sık kullanılan seçenekler ve hangi sorunu çözdükleri:**

| Komut | Ne işe yarar |
| --- | --- |
| `dig example.com` | Tam A sorgusu; tüm bölümlerle |
| `dig example.com +short` | Sadece cevabın kendisi (IP), betiklerde kullanmak için |
| `dig example.com +noall +answer` | Sadece ANSWER bölümü, tam kayıt satırlarıyla (TTL + tür görünür) |
| `dig example.com MX` / `NS` / `TXT` / `AAAA` | Belirli kayıt türü |
| `dig @1.1.1.1 example.com` | Sistemin resolver'ı yerine belirli bir sunucuya sor (resolver arızasını izole etmek) |
| `dig example.com +trace` | Kökten yetkiliye delegasyon zincirini adım adım göster |
| `dig -x 8.8.8.8` | Ters sorgu (aşağıda; `host` ile aynı iş) |
| `dig -f isimler.txt` | Dosyadan toplu sorgu (batch mode) |

**Ne zaman / kim.** "`ping 8.8.8.8` çalışıyor ama `ping alanadi.com` çalışmıyor" durumunda (Gün 7'deki teşhis merdiveni) sorunun DNS'te olduğu belliyse, `dig` ile **hangi katmanda** koptuğu bulunur: `dig @sistem-resolver` `SERVFAIL` veriyor ama `dig @1.1.1.1` çalışıyorsa sorun yerel resolver'da; ikisi de `NXDOMAIN` veriyorsa kayıt gerçekten yok; `+trace` bir TLD/yetkili sunucuda takılıyorsa delegasyon bozuk.

### 6. `host` ile IP'den isim çözme (reverse lookup / PTR)

**Mekanizma.** İleri çözüm "isim → A kaydı"dır; ters çözüm "IP → **PTR** kaydı"dır ve DNS'te ayrı bir ağaçta tutulur: IPv4 için **`in-addr.arpa`**, IPv6 için **`ip6.arpa`** — bu iki alan adı standartta ters sorgular için ayrılmıştır. `host 8.8.8.8` yazdığında `host`, adresi **ters çevirip** `8.8.8.8.in-addr.arpa` ismini oluşturur ve onun **PTR** kaydını sorar (`-x` verildiğinde `dig` de aynısını yapar). `host` varsayılan olarak A/AAAA/MX sorar; bir IP verilirse otomatik olarak PTR moduna geçer.

**Neden ileri ≠ geri.** İleri zone'u alan adının sahibi yönetir; **ters zone'u ise IP bloğunun sahibi** (ISS veya bölgesel kayıt kuruluşu RIR) yönetir ve blok kiralayana devreder. Bu yüzden:

- Bir alan adının A kaydı `1.2.3.4`'e bakıyor olabilir ama `1.2.3.4`'ün PTR'si o alan adına dönmeyebilir (ikisi ayrı yetki alanı).
- **Özel ağ adreslerinin (`192.168.x`, `10.x`) genelde PTR kaydı yoktur** — bu günkü lab ağında `host 192.168.56.102` büyük olasılıkla `NXDOMAIN` döner; isimle bağlanmak istiyorsan `/etc/hosts` kullanırsın (2. başlık).
- E-posta sunucularında **ileri ve geri kaydın tutarlı olması (FCrDNS)** spam filtrelerinin ilk kontrolüdür; PTR'si olmayan IP'den gelen posta çoğu zaman reddedilir.

**`host` vs `dig`.** `host` kısa, insan-okunur çıktı verir ("hızlı bak"); `dig` ham ve ayrıntılıdır ("teşhis et"). İkisi de `bind9-dnsutils` / `bind-utils` paketindedir.

```bash
host example.com          # ileri: A, AAAA, MX
host 8.8.8.8              # geri: PTR -> dns.google
dig -x 8.8.8.8 +short    # aynı geri sorgu, dig ile
```

### 7. `whois` — alan adı / IP tahsis kayıtlarını sorgulama

**Mekanizma ve katman.** `whois` DNS **değildir**; ayrı, çok basit bir protokoldür (RFC 3912, eski RFC 954'ün yerine geçer): istemci **TCP port 43**'e bağlanır, tek satır metin sorgu (`\r\n` ile biter) gönderir, sunucu metin cevabı döndürür ve **bağlantıyı kapatır** — cevabın bittiğinin işareti bağlantının kapanmasıdır. Şifreleme, kimlik doğrulama, erişim denetimi yoktur.

**Nasıl "doğru" sunucuyu bulur.** Her TLD'nin (`.com`, `.org`, `.com.tr`) ve her RIR'ın (RIPE, ARIN, APNIC…) kendi whois sunucusu vardır. `whois` istemcisi (Debian'da Marco d'Itri'nin `whois` paketi) **gömülü bir sunucu listesiyle** gelir: sorgu bir alan adıysa TLD'ye, bir IP/ASN ise ilgili RIR'a yönlendirir; ilk cevap "asıl kayıt şu sunucuda" (referral) diyorsa oraya tekrar sorar.

**Ne döner / neden kullanılır / kim.** Alan adı için: tescil eden firma (registrar), oluşturma/bitiş tarihleri, ad sunucuları, (çoğu zaman GDPR nedeniyle gizlenmiş) tescil sahibi bilgisi. IP için: adresi hangi kuruluşa tahsis edilmiş, hangi ülke, **abuse (kötüye kullanım) iletişim adresi**. Sistem/güvenlik yöneticisi bunu keşif (recon), sahiplik doğrulama, saldırı kaynağı bildirimi ve alan adı bitiş tarihi takibi için kullanır. Kişisel verilerin gizlenmesi eğilimi nedeniyle whois'in yerini yapılandırılmış **RDAP** protokolü almaya başladı, ama port 43 whois hâlâ yaygın.

```bash
whois example.com          # alan adı kaydı
whois 8.8.8.8              # IP tahsis kaydı + abuse contact
whois -h whois.nic.tr example.com.tr   # sunucuyu elle seç
```

### Uygulamalı Örnek — İki sunuculu WordPress (Apache + PHP ⟷ uzak MariaDB)

**Mimari ve neden.** Uygulama iki katmana ayrıldı: **101 (Debian)** = web/uygulama katmanı (Apache2 + PHP + WordPress kodu), **102 (Ubuntu 24.04)** = veri katmanı (MariaDB). İkisi `192.168.56.0/24` host-only ağında. Web ve veritabanını ayrı makinelere koymanın nedeni: (a) güvenlik — veritabanı doğrudan internete bakmaz, sadece web sunucusundan erişilir; (b) ölçekleme — ileride birden çok web sunucusu tek veritabanına bağlanabilir; (c) kaynak/yedekleme ayrımı. Bu, klasik "two-tier" mimarisidir.

Not: `101terminal.txt` yalnızca `/var/www/html/wp-content/themes` altında bir premium tema arşiviyle (`gustablo`) uğraşılan bölümü yakalamış; **Apache/PHP/WordPress çekirdek kurulumu ve `wp-config.php` düzenlemesi transkriptte yok**. Aşağıda 102 tarafı satır satır, 101 tarafı ise "olması gereken" olarak çözümlendi.

#### 102 (MariaDB) — `102terminal.txt` çözümlemesi

1. **`mysql_secure_installation` diyaloğu** (satır 1–52). Seçimler: root parolası değiştirildi; **"Remove anonymous users? → n"**, **"Disallow root login remotely? → n"** — yani anonim kullanıcı ve uzaktan root girişi **açık bırakıldı**. Lab için sorun değil ama **üretimde ikisi de kapatılmalı** (aşağıda takip maddesi). `test` veritabanı silindi, privilege tabloları yeniden yüklendi.
2. **`ls -l /etc/mysql/mariadb.conf.d/`** (satır 53–64) → MariaDB ayarları burada parça parça (`50-server.cnf` ana dosya). Sürüm: `10.11.14-MariaDB-0ubuntu0.24.04.1` — Ubuntu 24.04'ün depo sürümü.
3. **`nano /etc/mysql/mariadb.conf.d/50-server.cnf`** (satır 65) → burada **`bind-address`** değiştirildi. Varsayılan `127.0.0.1`'dir; bu hâliyle MariaDB sadece kendi makinesinden bağlantı kabul eder, 101'den gelen TCP bağlantısı hiç dinlenmez. Uzak erişim için `bind-address` ya `0.0.0.0` (tüm arayüzler) ya da tek bir arayüze (`192.168.56.102`) ayarlanır.
4. **Sonuç doğrulaması** — `ss -tlnp | grep 3306` (satır 125–126):
   ```
   LISTEN 0 80 192.168.56.102:3306 0.0.0.0:* users:(("mariadbd",pid=5667,fd=22))
   ```
   MariaDB **yalnızca `192.168.56.102:3306`**'da dinliyor — `0.0.0.0` değil. Yani `bind-address = 192.168.56.102` yazılmış; bu iyi bir tercih: host-only ağdan erişilebilir ama makinenin NAT/internet arayüzünden (`10.0.2.15`) erişilemez. Transkript satır 76'daki eğitmen notu tam bunu istiyordu. (`ss` Gün 7'de işlendi: `-t` TCP, `-l` listen, `-n` sayısal, `-p` süreç/PID — `bkz.` [Gün 7#11. Ağ teşhis araçları: `ss`, `traceroute`, `telnet`](Gün%207.md#11-ağ-teşhis-araçları-ss-traceroute-telnet).)
5. **`sql` yazım hatası** (satır 88–91):
   ```
   MariaDB [(none)]> sql
       -> CREATE DATABASE wordpress CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
   ERROR 1064 (42000): ... near 'sql\nCREATE DATABASE ...'
   ```
   MariaDB istemcisi bir **kabuk değildir**; her şeyi SQL olarak ayrıştırır. `sql` diye bir ifade yok, `;`'e kadar her şey tek deyim sayıldı ve sözdizimi hatası verdi. Doğrusu doğrudan `CREATE DATABASE ...` yazmaktır. `utf8mb4` / `utf8mb4_unicode_ci` seçimi: gerçek 4 baytlık Unicode (emoji dâhil) desteği — WordPress'in de varsayılanı budur.
6. **Uzak kullanıcı ve yetki** (satır 92–99):
   ```sql
   CREATE USER 'wpuser'@'192.168.56.101' IDENTIFIED BY '<parola>';
   GRANT ALL PRIVILEGES ON wordpress.* TO 'wpuser'@'192.168.56.101';
   FLUSH PRIVILEGES;
   ```
   MariaDB'de bir hesap **kullanıcı + host** çiftidir. `'wpuser'@'192.168.56.101'` yalnızca **101'in IP'sinden gelen** bağlantıların bu kullanıcıyla kimlik doğrulamasına izin verir; başka bir IP'den `wpuser` ile bağlanılamaz. Bu, güvenlik duvarından **bağımsız ikinci bir erişim denetimi katmanıdır** (uygulama katmanı ACL). `GRANT ALL ... ON wordpress.*` yetkiyi **sadece o veritabanına** kısıtlar (`*.*` değil — WordPress'in başka veritabanına erişmesi gerekmez). `FLUSH PRIVILEGES` burada **gerekli değildir** — `CREATE USER`/`GRANT` yetki tablolarını zaten anında yeniler; `FLUSH` sadece `mysql.user` gibi tablolara **doğrudan `INSERT`/`UPDATE`** yapıldığında gerekir. Zararsız ama gereksiz.
7. **Parola yeniden atama** (satır 185): `ALTER USER 'wpuser'@'192.168.56.101' IDENTIFIED BY '<parola>';` — muhtemelen 5. adımdaki hatadan sonra `CREATE DATABASE` ve kullanıcı sırası karıştığı için parolayı garantiye almak amacıyla. `FLUS PRIVILEGES` (satır 188) yine yazım hatası → 1064.
8. **Güvenlik duvarı — `ufw`** (satır 104–124, 158–173):
   ```
   ufw allow from 192.168.56.101 any port 3306      → ERROR: Wrong number of arguments
   ufw allow from 192.168.56.101 to any port 3306   → Rule added   (doğrusu: 'to any' şart)
   ufw enable                                        → SSH bağlantısını kesebilir uyarısı
   ufw status verbose                                → Default: deny (incoming); 3306 ALLOW IN 192.168.56.101
   ```
   İlk komut `to` anahtar kelimesi eksik olduğu için reddedildi — `ufw`'nin `from ... to ... port ...` kalıbı katıdır. Sonuçta iki bağımsız katman kuruldu: **paket düzeyinde** `ufw` (sadece 101'den 3306'ya izin, gerisi `deny`) + **kimlik düzeyinde** MariaDB `wpuser@192.168.56.101`. (`ufw` Gün 7'de işlendi: `bkz.` [Gün 7#9. Firewall](Gün%207.md#9-firewall).)
9. **Doğrulama** (satır 137–152): `SELECT User, Host FROM mysql.user WHERE User='wpuser';` ve `SHOW GRANTS FOR 'wpuser'@'192.168.56.101';` → hesabın ve `wordpress.*` yetkisinin oluştuğu teyit edildi.

#### 101 (Apache + PHP + WordPress) — olması gereken

Transkriptte yakalanmayan kurulum adımları (Debian 13 için):

```bash
apt install apache2 php libapache2-mod-php php-mysql php-gd php-curl php-xml php-mbstring php-zip mariadb-client
# wordpress.org'dan çekirdek indirilip /var/www/html altına açılır
chown -R www-data:www-data /var/www/html      # WordPress'in dosyaları yönetebilmesi için
```

**Kritik nokta — `wp-config.php`:** WordPress'in veritabanı ayarları:

```php
define( 'DB_NAME', 'wordpress' );
define( 'DB_USER', 'wpuser' );
define( 'DB_PASSWORD', '<parola>' );
define( 'DB_HOST', '192.168.56.102' );   // localhost DEĞİL — uzak DB sunucusunun IP'si
```

`DB_HOST` varsayılanı `localhost`'tur; iki sunuculu kurulumun **tek gerçek farkı** buranın uzak IP (veya `/etc/hosts`'a yazılmış bir isim) olmasıdır. Bugünkü DNS konusuna bağlanan yer: 101'in `/etc/hosts`'una

```
192.168.56.102  db.egitim.local
```

eklenip `DB_HOST` `'db.egitim.local'` yapılırsa, IP değişse bile tek satır güncellenir — lab ağında DNS sunucusu olmadığı için `/etc/hosts` tam olarak bu işi görür (2. başlık).

**Transkriptteki tema bölümü (`101terminal.txt`).** `/var/www/html/wp-content/themes` altında `gustablo` premium temasının pazaryeri arşivi (`...utc.zip`) açılmaya çalışılmış; içinden asıl kurulacak dosya **dış paket değil**, içindeki `gustablo-theme.zip`'tir (yanında `gustablo-child.zip` alt tema, `psd/`, `documentation/`, `plugins/` klasörleri pazaryeri ekleridir). Gözlem: `unzip` ile açılan dosyalar `root:root` sahipliğinde kaldı (`ls -la` satır 98–99, 118–119) — WordPress (`www-data`) bunları güncelleyemez; `chown -R www-data:www-data` gerekir. Ayrıca `zip -r arsiv.zip gustav/` ile **boş bir klasörü var olan arşive eklemeye** çalışmak arşivi bozdu; sonraki `unzip` denemeleri bu yüzden tuhaf davrandı.

### Kaynaklar

Kaynaklar konu başlıklarına göre gruplandı. DNS kayıt türleri ve protokol temelleri uzun süredir sabit RFC'lerdir; dağıtım varsayılanları (systemd-resolved, nsswitch satırı, paket adları) 2026-08'de ayrıca doğrulandı.

- **DNS servisi / çözümleme zinciri / kayıt türleri:**
  - [RFC 1034 — Domain Names: Concepts and Facilities](https://www.rfc-editor.org/rfc/rfc1034) ve [RFC 1035 — Implementation and Specification](https://www.rfc-editor.org/rfc/rfc1035) — kayıt türleri, zone, SOA/NS/A/CNAME/MX/PTR
  - [DNS records — Cloudflare Learning Center](https://www.cloudflare.com/learning/dns/dns-records/) (ikincil — kayıt türü özeti ve recursive resolver'ın kök→TLD→yetkili yürüyüşü)
  - `bkz.` [Gün 7#8. DHCP ve DNS](Gün%207.md#8-dhcp-ve-dns) — recursive vs iterative sorgu, UDP/TCP 53, TTL
- **`/etc/hosts` / tarihçe:**
  - [nsswitch.conf(5) — Debian trixie manpages](https://manpages.debian.org/trixie/manpages/nsswitch.conf.5.en.html) — `files` kaynağının `/etc/hosts`'u okuması
  - [The history of DNS: from HOSTS.TXT to DNS-over-HTTPS](https://blog.crawlex.net/blog/history-of-dns/) (ikincil) ve [O'Reilly — The History of the Domain Name System](https://www.oreilly.com/library/view/dns-on-windows/0596005628/ch01s02s01.html) — SRI-NIC, HOSTS.TXT'nin FTP ile dağıtımı, DNS'e geçiş (1983–84)
- **`/etc/nsswitch.conf` / NSS:**
  - [nsswitch.conf(5) — Debian trixie manpages](https://manpages.debian.org/trixie/manpages/nsswitch.conf.5.en.html) — Solaris 2 kökeni, `libnss_*.so`, durum/eylem kuralları (`[NOTFOUND=return]` vb.)
  - [nss-resolve(8) — freedesktop.org / systemd](https://www.freedesktop.org/software/systemd/man/latest/nss-resolve.html) — `resolve [!UNAVAIL=return]` kalıbı, `io.systemd.Resolve` soketi, `/etc/hosts`'un resolved içinde önbellekli işlenmesi
  - [Debian trixie — systemd-resolved paketi](https://packages.debian.org/trixie/systemd-resolved) + [firezone#11258 — Debian 13 systemd-resolved'ı varsayılan kurmuyor](https://github.com/firezone/firezone/issues/11258) — Debian 13 farkı
  - [nss-resolve — Ubuntu manpage](https://manpages.ubuntu.com/manpages/bionic/man8/nss-resolve.8.html) ve Ubuntu'da `/etc/resolv.conf` → `stub-resolv.conf` (127.0.0.53) davranışı
- **`nslookup` → `dig`:**
  - [dig(1) — bind9-dnsutils, Debian trixie](https://manpages.debian.org/trixie/bind9-dnsutils/dig.1.en.html) — "Most DNS administrators use dig…", `-x`, `-f`, `+short`, `+trace`, `/etc/resolv.conf`
  - [NSlookup vs Dig — networkstraining.com](https://www.networkstraining.com/nslookup-vs-dig-dns-tools/) (ikincil) — BIND kılavuzunun "arcane user interface / not recommended" ifadesi; nslookup'ın sistem resolver'ını kullanmaması (Cricket Liu)
- **`host` / ters çözüm:**
  - [dig / host manpages — BIND 9 documentation](https://bind9.readthedocs.io/en/stable/manpages.html) — `host` varsayılan A, `-x` ile PTR
  - [APNIC — Guide to reverse zones](https://www.apnic.net/about-apnic/corporate-documents/documents/resource-guidelines/reverse-zones/) ve [Oracle Linux — Resource Records for Reverse-Name Resolution](https://docs.oracle.com/en/operating-systems/oracle-linux/10/bind/bind-ResourceRecordsforReverseNameResolution.html) — `in-addr.arpa` / `ip6.arpa`, ters zone yetkisinin IP bloğu sahibinde olması
- **`whois`:**
  - [RFC 3912 — WHOIS Protocol Specification](https://www.rfc-editor.org/rfc/rfc3912.html) — TCP 43, düz metin sorgu/cevap, bağlantı kapanışı = cevap sonu, şifreleme/yetki yok, RFC 954'ü geçersiz kılar
  - [WHOIS — Wikipedia](https://en.wikipedia.org/wiki/WHOIS) (ikincil) — istemcinin TLD/RIR whois sunucusu seçimi, referral, RDAP'a geçiş
- **Uygulamalı örnek (MariaDB uzak erişim + WordPress):**
  - [Configuring MariaDB for Remote Client Access — MariaDB Documentation](https://mariadb.com/docs/server/mariadb-quickstart-guides/mariadb-remote-connection-guide) — `bind-address` `127.0.0.1` → `0.0.0.0`/arayüz IP, `GRANT ... TO user@host`, `ss`/`netstat` ile 3306 doğrulaması
  - [How to Install WordPress with Apache on Debian 13 — LinuxCapable](https://linuxcapable.com/how-to-install-wordpress-with-apache-on-debian-linux/) (ikincil) — `apache2` + `libapache2-mod-php` + `php-mysql` + eklenti paketleri, Debian 13'te PHP 8.4
  - [Install and configure WordPress — Ubuntu tutorial](https://ubuntu.com/tutorials/install-and-configure-wordpress) (ikincil) — `wp-config.php` `DB_HOST` ayarı, `chown -R www-data:www-data`
- **Güncel dağıtım sürümleri (2026-08 doğrulaması):**
  - [Debian 13 "trixie" release information](https://www.debian.org/releases/trixie/) — güncel stable
  - Ubuntu Server 24.04 LTS "Noble Numbat" — MariaDB 10.11 depo sürümü (transkriptte `10.11.14-MariaDB-0ubuntu0.24.04.1`)
  - [Rocky Linux version guide](https://wiki.rockylinux.org/rocky/version/) — DNS araçları `bind-utils` paketinde

Tekil bayrak/sözdizimi bilgileri (`dig +short`, `host -x`, `ufw ... to any port`, temel SQL `CREATE USER`/`GRANT`) `man dig`, `man host`, `man ufw`, MariaDB kılavuzu ile doğrulanabilir; bunlar için ayrıca kaynak verilmedi.

## Notlar

- **Bir isim çözülürken izlenen yol sabittir:** uygulama → `getaddrinfo()` → `/etc/nsswitch.conf` sırası → (`files` ise) `/etc/hosts`, (`dns`/`resolve` ise) `/etc/resolv.conf`'taki sunucu → özyinelemeli resolver → kök/TLD/yetkili. Bir DNS sorununu teşhis etmek, bu zincirin **hangi halkasında** koptuğunu bulmaktır; `dig @farklı-sunucu` ve `dig +trace` tam bunun için var.
- **"DNS servisi" belirsiz bir terim:** stub resolver, caching resolver ve authoritative server üç ayrı şeydir. Lab/kurumsal ortamda "DNS kur" genelde caching resolver (`unbound`/`dnsmasq`) demektir; kendi alan adını yayınlamak authoritative server (`bind9`/`nsd`) ister.
- **Dağıtım farkı bu gün de karşımıza çıktı:** Debian 13 `systemd-resolved`'ı varsayılan kurmaz (`/etc/resolv.conf` düz dosya, `nsswitch` `files dns`), Ubuntu 24.04 kurar (`127.0.0.53` stub, `nsswitch`'te `resolve [!UNAVAIL=return]`), Rocky `NetworkManager` + `bind-utils` kullanır. Gün 6–7'deki "eski araç → modern yerine geçen" deseninin (`nslookup` → `dig`) bir örneği daha.
- **Uygulamada iki bağımsız erişim denetimi katmanı var:** `ufw` (paket: sadece 101'den 3306'ya) + MariaDB `user@host` (kimlik: sadece `192.168.56.101`'den `wpuser`). Biri diğerinin yerini tutmaz; ikisi birlikte "derinlemesine savunma".
- İki sunuculu WordPress'in tek yapılandırma farkı **`wp-config.php`'deki `DB_HOST`**'un `localhost` yerine uzak sunucunun adresi olmasıdır; gerisi (bind-address, GRANT host'u, firewall) bu bağlantıyı mümkün kılan altyapıdır.

## Komutlar / Örnekler

```bash
# --- İsim çözümleme dosyaları ---
cat /etc/hosts                     # yerel isim tablosu (IP  isim  takma-ad)
cat /etc/nsswitch.conf             # 'hosts:' satırı = kaynak sırası (files/dns/resolve...)
cat /etc/resolv.conf               # kullanılan nameserver(lar); Ubuntu'da 127.0.0.53 stub
resolvectl status                  # systemd-resolved'ın gerçek yukarı-akım DNS sunucuları

# --- dig: isimden IP (forward) ---
dig example.com                    # tam A sorgusu (HEADER/QUESTION/ANSWER/...)
dig example.com +short             # sadece IP
dig example.com +noall +answer     # sadece ANSWER, TTL + tür görünür
dig example.com MX                 # posta sunucuları
dig @1.1.1.1 example.com           # sistem resolver'ını atla, belirli sunucuya sor
dig example.com +trace             # kök -> TLD -> yetkili delegasyon zinciri
dig -f isimler.txt                 # dosyadan toplu sorgu

# --- host: IP'den isim (reverse / PTR) ---
host example.com                   # ileri: A, AAAA, MX
host 8.8.8.8                       # geri: PTR
dig -x 8.8.8.8 +short              # aynı geri sorgu dig ile

# --- whois ---
whois example.com                  # alan adı tescil kaydı
whois 8.8.8.8                      # IP tahsisi + abuse contact
whois -h whois.nic.tr ornek.com.tr # whois sunucusunu elle seç

# --- Uygulama: 102 (MariaDB, Ubuntu) ---
sudo nano /etc/mysql/mariadb.conf.d/50-server.cnf   # bind-address = 192.168.56.102
sudo systemctl restart mariadb
ss -tlnp | grep 3306                                # 192.168.56.102:3306 dinliyor mu
sudo mysql -u root -p
#   CREATE DATABASE wordpress CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
#   CREATE USER 'wpuser'@'192.168.56.101' IDENTIFIED BY '****';
#   GRANT ALL PRIVILEGES ON wordpress.* TO 'wpuser'@'192.168.56.101';
#   FLUSH PRIVILEGES;
#   SHOW GRANTS FOR 'wpuser'@'192.168.56.101';
sudo ufw allow from 192.168.56.101 to any port 3306   # 'to any' şart
sudo ufw enable && sudo ufw status verbose

# --- Uygulama: 101 (Apache + PHP + WordPress, Debian) ---
sudo apt install apache2 php libapache2-mod-php php-mysql php-gd php-curl php-xml php-mbstring php-zip mariadb-client
sudo chown -R www-data:www-data /var/www/html
mariadb -h 192.168.56.102 -u wpuser -p wordpress       # bağlantıyı önce elle test et
# wp-config.php:  define('DB_HOST', '192.168.56.102');  // localhost değil
echo "192.168.56.102  db.egitim.local" | sudo tee -a /etc/hosts   # isteğe bağlı: isimle bağlan
```

## Sorular / Takip Edilecekler

- [ ] Kendi VM'de `dig ornek.com` ile bir alan adını **iki kez** sorgula; ikinci sorguda ANSWER'daki `TTL` değerinin düştüğünü (cevabın resolver önbelleğinden geldiğini) gözlemle. → [Gün 7](Gün%207.md)'deki aynı maddeyle örtüşüyor; orada kapatılabilir.
- [ ] `dig example.com +trace` çalıştır; çıktıda kök (`.`) → `.com` → yetkili sunucu geçişlerini ve her adımda hangi NS'e sorulduğunu takip et.
- [ ] `host 192.168.56.102` ve `host 192.168.56.101` çalıştır — özel ağ adreslerinin PTR kaydı olmadığı için `NXDOMAIN`/`not found` döndüğünü doğrula; sonra `/etc/hosts`'a satır ekleyip `getent hosts 192.168.56.102` ile `files` kaynağının çözdüğünü gör (`getent`, `dig`'in aksine tam NSS zincirini kullanır).
- [ ] 101'den `mariadb -h 192.168.56.102 -u wpuser -p wordpress` ile bağlan; sonra 102'de `ufw delete allow from 192.168.56.101 to any port 3306` yapıp tekrar dene — bağlantının **firewall katmanında** (timeout) mı yoksa **MariaDB katmanında** (access denied) mı kesildiğini ayırt et.
- [ ] Üretim güvenliği: 102'de `mysql_secure_installation`'da "n" denen iki adımı (anonim kullanıcı, uzaktan root) elle kapat — `DROP USER ''@'localhost';` ve root'un host kayıtlarını `localhost`/`127.0.0.1` ile sınırla; `SELECT User,Host FROM mysql.user;` ile doğrula.
- [ ] `wp-config.php`'de `DB_HOST`'u önce `192.168.56.102` sonra `db.egitim.local` (hosts kaydıyla) yaparak ikisinin de çalıştığını, WordPress kurulum ekranının açıldığını gözlemle.
