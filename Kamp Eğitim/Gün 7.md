---
tags:
  - egitim/linux-sistem-yonetimi
tarih: 2026-08-28
konular:
  - TCP/IP temelleri ve OSI modeli
  - Ethernet, frame, MAC adresi, PDU
  - Switch, hub, router, bridge, gateway
  - Ağ arayüzü (network interface), VLAN, broadcast
  - IP adresleme — IPv4, IPv6, subnet, prefix, CIDR
  - Protokol kavramı, paket, buffer, soket, port
  - DHCP, DNS
  - TCP, UDP
  - Firewall
  - ping ve ICMP
  - ss, traceroute, telnet
---

# Gün 7

Bağlantı: [Linux Sistem Yönetimi Eğitimi](../README.md) · [00 - Eğitim Planı](../00%20-%20Eğitim%20Planı.md) · [Gün 6](Gün%206.md)

## İşlenen Konular

Günün tek başlığı **TCP/IP**'ydi; altında ağ temelleri bir terim listesi hâlinde işlendi:

- **Ethernet** nedir?
- **Protokol** nedir?
- **DHCP** nedir?
- **MAC adresi** nedir?
- **DNS** nedir?
- **Gateway** nedir?
- **Port** nedir?
- **Soket** nedir?
- **Prefix** nedir?
- **Subnet** nedir?
- **VLAN** nedir?
- **Paket** nedir?
- **TCP** nedir?
- **UDP** nedir?
- **Firewall** nedir?
- **Broadcast** nedir?
- **IP adresi** nedir? — **IPv4** nedir? **IPv6** nedir?
- **Switch** nedir?
- **Hub** nedir?
- **Router** nedir?
- **Buffer** nedir?
- **Ağ arayüzü (network interface)** nedir?
- **PDU** nedir?
- **OSI Modeli** nedir?
- **Bridge** nedir?
- **Frame** nedir?
- **CIDR** nedir?
- **ping** komutu nedir? Nasıl çalışır? Neden çalışır?
- **ICMP** nedir? Nasıl çalışır? Neden çalışır?
- **`ss -nltp`** nedir, ne işe yarar? Parametre anlamları nelerdir? Ne zaman kullanılır?
- **`traceroute`** nedir, nasıl çalışır, hangi amaçla ve ne zaman kullanılır?
- **`telnet`** nedir, nasıl çalışır, hangi amaçla ve ne zaman kullanılır, neden kullanılır?

## Genişletilmiş Anlatım (Öğrenme İçin Ek Açıklamalar)

> [!WARNING]
> **Yukarıda bulunan kısa notların AI ile genişletilmiş halidir. Bilgiler sadece o gün işlenen konular ile sınırlandırılmış olup referans olması için eklenmiştir. Lütfen bu genişletilmiş metni kendi araştırmalarınıza bir ön bilgi olarak kullanın ve testlerinizi sadece burayı kullanarak değil, farklı kaynaklardan da yararlanarak yapın.**

> [!NOTE]
> **Bu gün 27 küçük terim + 3 komut içeriyor. Tek tek başlık açmak yerine terimler **11 tematik başlıkta** gruplandı; her başlık, ilişkili terimleri birbirine bağlayarak anlatıyor (örn. "hub / switch / bridge / router / gateway" tek başlıkta, çünkü hepsi aynı sorunun farklı katmanlardaki cevabı). Her başlık şu sırayı izliyor: önce mekanizma (bu şey ağ yığınında hangi katmanda, altında ne çalışıyor), sonra ne/nasıl/ne zaman/neden/kim, sonra tarihsel gerekçe, en son komut.**

### 1. Katmanlı model: protokol, OSI, TCP/IP ve PDU

Bir bilgisayar ağı, farklı üreticilerin farklı donanım ve yazılımlarının birlikte çalışması gereken bir sistemdir; bunu mümkün kılan şey, işi **katmanlara** bölüp her katman için ayrı bir sözleşme (protokol) tanımlamaktır. **Protokol**, iki tarafın bir mesajı nasıl biçimlendireceği, hangi sırayla ne göndereceği ve hataya nasıl tepki vereceği üzerine önceden anlaşılmış kurallar bütünüdür — insanların telefonda "alo" deyip sırayla konuşması gibi. Bir protokol her zaman belirli bir katmanda çalışır ve sadece bir alt/üst katmanla konuşur; bu sayede bir katman değişse (bakır kablo yerine fiber) üstteki katmanlar hiç etkilenmez.

**OSI modeli** (resmî adı ISO/IEC 7498-1), bu katmanlamayı yedi seviyeye böler: fiziksel (1), veri bağı (2), ağ (3), taşıma (4), oturum (5), sunum (6), uygulama (7). Bu bir **referans modelidir** — gerçek internet OSI'yi birebir uygulamaz; pratikte kullanılan **TCP/IP modeli** dört katmandır (bağlantı, internet, taşıma, uygulama) ve resmî tanımı RFC 1122'dir. OSI hâlâ öğretiliyor çünkü "bu sorun 2. katmanda mı 3. katmanda mı" gibi konuşmak için ortak bir sözlük veriyor: bir switch "2. katman cihazı", bir router "3. katman cihazı" denince herkes aynı şeyi anlıyor.

**PDU (Protocol Data Unit)**, bir katmanın o an işlediği veri biriminin genel adıdır ve her katmanda farklı isim alır: uygulama katmanında **veri**, taşıma katmanında **segment** (TCP) veya **datagram** (UDP), ağ katmanında **paket**, veri bağı katmanında **frame**, fiziksel katmanda **bit**. Bir mesaj yığından aşağı inerken her katman kendi başlığını (header) ekler — buna **kapsülleme (encapsulation)** denir; karşı tarafta her katman kendi başlığını soyup yukarı verir (**decapsulation**). Yani ağdan geçen bir Ethernet frame'inin içinde bir IP paketi, onun içinde bir TCP segmenti, onun içinde de HTTP verisi vardır — soğan gibi.

**Ne zaman / kim:** Bu model günlük komut kullanımında görünmez ama bir sorunu teşhis ederken zihinsel harita olarak kullanılır — "ping gidiyor ama web açılmıyor" dediğinde 3. katman (IP) çalışıyor, sorun 4-7 arasında demektir. Modeli tasarlayan ISO/OSI çalışması 1970'lerin sonunda, TCP/IP ise ARPANET üzerinde 1970'ler-80'ler boyunca gelişti; TCP/IP kazandı çünkü daha basit ve çalışan koda dayanıyordu, OSI ise komite tarafından yukarıdan tasarlanıp ağırlaştı.

### 2. Ethernet, frame ve MAC adresi

**Ethernet**, yerel ağlarda (LAN) aynı fiziksel ortama bağlı cihazların veri alışverişini tanımlayan kablolu ağ standardıdır (IEEE 802.3) ve OSI'nin 1. (fiziksel) ile 2. (veri bağı) katmanına karşılık gelir. Ethernet üzerinde veri, **frame** adı verilen paketçikler hâlinde taşınır: bir frame'in başında hedef MAC adresi, kaynak MAC adresi ve tür alanı (EtherType — içindeki yükün IPv4 mi IPv6 mı olduğunu söyler), sonunda ise **FCS (Frame Check Sequence)** denen bir sağlama toplamı bulunur; alıcı bu toplamı yeniden hesaplayıp bozuk frame'i sessizce atar.

**MAC adresi (Media Access Control)**, her ağ kartına (NIC) üretim sırasında yazılan 48 bitlik (6 bayt, `a4:c3:f0:11:22:33` gibi) donanım kimliğidir; ilk 3 bayt üreticiyi (OUI — IEEE tarafından tahsis edilir), son 3 bayt kartı belirtir. Ethernet'in çalışma mantığı şudur: bir cihaz frame'i gönderirken hedef MAC'i yazar; **switch**, hangi MAC adresinin hangi portunda olduğunu öğrenip (aşağıdaki başlık) frame'i sadece o porta iletir. MAC adresi **yereldir** — sadece aynı ağ segmentinde anlam taşır, bir router'ı geçtiği an frame yeniden yazılır ve MAC'ler değişir; IP adresi ise uçtan uca sabit kalır (ayrım 5. başlıkta).

**Ne zaman / kim:** MAC adresi sistem yöneticisini DHCP rezervasyonu (bir cihaza hep aynı IP'yi vermek), MAC filtreleme ve `arp`/`ip neigh` tablosunu okurken ilgilendirir. Linux'ta `ip link` çıktısındaki `link/ether` satırı kartın MAC'idir. Ethernet 1973'te Xerox PARC'ta Robert Metcalfe tarafından icat edildi; ilk hâli tek bir paylaşılan kabloydu ve cihazlar sırayla konuşmak için **CSMA/CD** (dinle, boşsa gönder, çakışma olursa bekle) kullanırdı. Modern switch'li tam çift yönlü (full-duplex) ağlarda her port ayrı bir hat olduğu için çakışma diye bir şey kalmadı — CSMA/CD artık fiilen ölü, ama standartta hâlâ duruyor.

### 3. Ağ cihazları: hub, switch, bridge, router, gateway

Bu beş cihaz aynı temel soruna — "bir frame/paket nereye gitmeli" — farklı katmanlarda cevap verir; hangisinin ne olduğunu anlamanın anahtarı **hangi OSI katmanında çalıştığıdır**.

**Hub**, 1. katman cihazıdır: bir porttan gelen elektrik sinyalini hiç yorumlamadan **diğer tüm portlara** tekrar eder. MAC adresi, frame kavramı yoktur; sadece "tekrarlayıcı"dır. Sonuç: tüm cihazlar tek bir **çakışma alanı (collision domain)** paylaşır, aynı anda sadece biri konuşabilir, ağ büyüdükçe çöker. Bugün üretilmiyor.

**Switch** (ve onun eski/basit hâli **bridge**), 2. katman cihazıdır. Bir porttan frame geldiğinde **kaynak MAC adresine** bakıp "şu MAC bu portta" bilgisini bir tabloya (**MAC/CAM tablosu**) yazar; sonra **hedef MAC'e** bakıp frame'i sadece o porta gönderir (tabloda yoksa tüm portlara taşırır — buna *flooding* denir, sadece ilk sefer olur). Her port ayrı çakışma alanıdır, hepsi full-duplex çalışır. Bridge ile switch arasındaki fark tarihseldir: bridge birkaç portlu, yazılımla çalışan eski bir cihazdı; switch onun donanım hızlandırmalı, çok portlu modern hâlidir — Linux'ta `ip link add br0 type bridge` ile oluşturduğun sanal aygıt tam olarak bir yazılım switch'idir.

**Router**, 3. katman cihazıdır: **IP paketine** bakar, hedef IP'yi kendi **yönlendirme tablosuyla** (routing table) eşleştirip paketi bir sonraki ağa iletir ve bu sırada Ethernet frame'ini **yeniden yazar** (yeni kaynak/hedef MAC). Farklı IP ağlarını birbirine bağlayan şey router'dır; switch aynı ağ içinde çalışır, router ağların arasında.

**Gateway**, ayrı bir cihaz türü değil, bir **roldür**: "kendi ağının dışına çıkmak istediğinde paketi teslim edeceğin cihaz" — pratikte yerel ağının router'ıdır. Linux'ta `ip route` çıktısındaki `default via 192.168.1.1` satırındaki adres, varsayılan gateway'dir; bir hedef için tabloda daha spesifik bir kayıt yoksa paket oraya gider.

**Ne zaman / kim:** Sistem yöneticisi bir bağlantı sorununda "aynı ağdaki cihaza erişiyorum ama internete çıkamıyorum" derse sorun switch'te değil gateway/router veya DNS'tedir; "hiçbir yere erişemiyorum" derse önce kendi arayüzü ve switch bağlantısıdır. Ayrım katman katman daralttırılır.

### 4. Broadcast, VLAN ve ağ arayüzü (network interface)

**Broadcast**, bir frame'in/paketin **o segmentteki herkese** gönderilmesidir. Ethernet'te hedef MAC `ff:ff:ff:ff:ff:ff` olduğunda switch onu tüm portlara taşır; IPv4'te bir alt ağın en yüksek adresi (örn. `192.168.1.0/24` için `192.168.1.255`) broadcast adresidir. ARP (bir IP'nin MAC'ini sorma) ve DHCP Discover broadcast ile çalışır — çünkü gönderen henüz karşı tarafın kim olduğunu bilmiyor. Bir broadcast'in ulaştığı cihazların tamamına **broadcast alanı (broadcast domain)** denir. Router'lar broadcast'i geçirmez; yani bir broadcast alanı = bir IP alt ağı, sınırı router'dır.

**VLAN (Virtual LAN)**, tek bir fiziksel switch'i mantıksal olarak birden çok ayrı switch'e bölme yöntemidir; her VLAN ayrı bir broadcast alanıdır. Nasıl çalışır: switch, frame'e **IEEE 802.1Q** etiketi ekler — kaynak MAC ile EtherType arasına giren 4 baytlık bir alan; içinde 12 bitlik **VLAN ID** (1–4094) ve 3 bitlik öncelik (PCP) vardır. Aynı VLAN ID'li portlar birbirini görür, farklı VLAN'lar ancak bir router (veya "L3 switch") üzerinden konuşur. **Neden:** kablo çekmeden bölümleri ayırmak (muhasebe ağı ile misafir Wi-Fi'yi fiziksel olarak ayrı switch almadan izole etmek), broadcast trafiğini küçük tutmak, güvenlik.

**Ağ arayüzü (network interface)**, işletim sisteminin bir ağ bağlantı noktasına verdiği addır — fiziksel bir NIC (`enp3s0`), sanal bir aygıt (`br0`, `wg0`, `docker0`) ya da `lo` (loopback, `127.0.0.1`) olabilir. Linux'ta arayüzler `ip link` ile listelenir. İsimlendirme: eski çekirdek `eth0`, `eth1` verirdi ama bu isimler açılıştan açılışa değişebiliyordu (kartların algılanma sırası sabit değil). systemd/udev v197'den beri **öngörülebilir arayüz isimleri** kullanır: `enp3s0` = **e**thernet, **p**ci bus 3, **s**lot 0 — isim kartın fiziksel konumundan türetildiği için kart değişmedikçe hep aynı kalır. `eno1` (anakart üstü), `ens1` (PCIe hotplug slot), `enx<MAC>` (MAC'ten) diğer şemalardır.

**Ne zaman / kim:** Sistem yöneticisi statik IP, VLAN alt-arayüzü (`ip link add link enp3s0 name enp3s0.10 type vlan id 10`) veya köprü tanımlarken bu kavramları kullanır; `/etc/network/interfaces` (Debian), Netplan (Ubuntu) veya NetworkManager (Rocky) bunları yapılandırır.

### 5. IP adresleme: IPv4, IPv6, subnet, prefix, CIDR

**IP adresi**, bir cihazın ağ (3.) katmanındaki, **uçtan uca** geçerli kimliğidir — MAC'in aksine router'ları geçerken değişmez. Bir IP adresi iki parçadan oluşur: **ağ kısmı** (aynı ağdaki herkes için ortak) ve **host kısmı** (o ağ içinde cihazı belirler). Bu ikisini ayıran şey **subnet mask** / **prefix**'tir.

**IPv4** 32 bitlik adres kullanır (`192.168.1.10` — dört sekizli, her biri 0–255), toplam ~4,3 milyar adres. Bu tükendiği için **IPv6** geldi: 128 bit (`2001:db8::1` gibi, sekiz gruplu onaltılık), pratikte sınırsız adres + otomatik yapılandırma (SLAAC) + basitleştirilmiş başlık. IPv4 hâlâ baskın; IPv6 yıllardır "geliyor". IPv4 RFC 791, IPv6'nın güncel tanımı RFC 8200'dür (eski RFC 2460'ı geçersiz kılar).

**Subnet (alt ağ)**, bir IP bloğunu daha küçük parçalara bölmektir. **Prefix**, adresin kaç bitinin ağ kısmı olduğunu söyleyen sayıdır. **CIDR (Classless Inter-Domain Routing)** notasyonu bunu `/` ile yazar: `192.168.1.0/24` → ilk 24 bit ağ, kalan 8 bit host → 256 adres (2 tanesi ağ ve broadcast için ayrılır, 254 kullanılabilir). `/25` → 128 adres, `/26` → 64, `/30` → 4 (nokta-nokta link için). CIDR'den önce adresler sabit "sınıflara" (A `/8`, B `/16`, C `/24`) bölünürdü; bu çok israfçıydı (bir kuruma B sınıfı verince 65 bin adres boşa yatıyordu), CIDR (RFC 4632) bu sınıfları kaldırıp herhangi bir prefix uzunluğuna izin verdi ve internet yönlendirme tablosunun şişmesini yavaşlattı.

Bir cihaz bir IP'ye paket göndereceği zaman önce prefix'e bakar: hedef **kendi alt ağında mı**? Evet ise ARP ile MAC'ini bulup doğrudan gönderir. Hayır ise paketi **gateway**'e yollar. Yani subnet maskesi yanlışsa cihaz "yakındaki" bir adrese ulaşamaz veya gereksiz yere gateway'e trafik basar.

**ARP (Address Resolution Protocol)**, "şu IP kimde?" sorusunun cevabıdır: kaynak, `192.168.1.1 kimde?` diye broadcast bir ARP isteği yollar, o IP'nin sahibi kendi MAC'iyle cevap verir, sonuç kısa süre `ip neigh` tablosunda tutulur. IPv4'ün Ethernet üzerinde çalışabilmesi bu köprüye bağlıdır; RFC 826.

### 6. Paket, buffer, soket ve port

**Paket**, ağ (3.) katmanının PDU'sudur: bir IP başlığı (kaynak IP, hedef IP, TTL, protokol numarası) + yük. "Paket" kelimesi günlük dilde her türlü ağ verisi için gevşek kullanılır ama teknik olarak IP katmanına aittir (Ethernet'te frame, TCP'de segment).

**Buffer**, ağda birçok yerde karşına çıkan "verinin işlenene kadar beklediği geçici bellek" kavramıdır. NIC'in donanım **ring buffer**'ı çekirdek onu okuyana kadar gelen frame'leri tutar; her soketin bir **gönderme** ve bir **alma buffer**'ı vardır (`net.core.rmem_max` gibi çekirdek parametreleriyle ayarlanır) — uygulama okumakta yavaşsa alma buffer'ı dolar ve TCP karşı tarafa "yavaşla" der (akış kontrolü). Buffer'ların amacı, üretim ve tüketim hızları eşit olmadığında veri kaybını önlemektir; ama aşırı büyük buffer'lar gecikmeyi artırır ("bufferbloat").

**Soket (socket)**, bir uygulamanın ağ ile konuşmak için kullandığı **programlama arayüzüdür** — 1983'te 4.2BSD Unix ile gelen "Berkeley sockets" API'si. Bir soket, işletim sistemi tarafında bir dosya tanımlayıcısı (fd) gibi davranır; uygulama `socket()`, `bind()`, `connect()`, `send()`, `recv()` çağırır. Bir TCP bağlantısı tam olarak dört şeyle tanımlanır: **kaynak IP + kaynak port + hedef IP + hedef port** (dört-lü / 4-tuple). Linux'ta `/proc/net/tcp` ve `ss` çıktısı bu soketleri listeler; Unix domain soketleri (`/run/*.sock`) ise aynı API'yi ağ yerine yerel süreçler-arası iletişim için kullanır.

**Port**, tek bir IP adresine gelen trafiğin **hangi uygulamaya** ait olduğunu ayıran 16 bitlik sayıdır (0–65535). Bir sunucuda hem web (80/443) hem SSH (22) çalışabilmesinin sebebi budur — IP aynı, port farklı. IANA port aralıklarını üçe böler (RFC 6335): **0–1023 sistem/ayrıcalıklı portlar** (bu portları dinlemek root veya `CAP_NET_BIND_SERVICE` ister — böylece rastgele bir kullanıcı 80'de sahte bir sunucu açamaz), **1024–49151 kayıtlı portlar**, **49152–65535 dinamik/geçici portlar** (giden bağlantılarda çekirdeğin kaynak port olarak seçtiği aralık). `/etc/services` dosyası isim↔numara eşlemesini tutar.

### 7. TCP ve UDP

İkisi de taşıma (4.) katmanı protokolüdür ve ikisi de port kullanır; fark, **güvenilirlik** konusundaki tercihte.

**TCP (Transmission Control Protocol)** bağlantı-yönelimlidir: veri göndermeden önce iki taraf **üçlü el sıkışma (three-way handshake)** yapar — istemci `SYN`, sunucu `SYN-ACK`, istemci `ACK`. Bundan sonra TCP her baytı numaralar, alıcı aldığını `ACK`'ler, kaybolan parça yeniden gönderilir, parçalar sırayla teslim edilir, ve **akış kontrolü** (alıcıyı boğmama) ile **tıkanıklık kontrolü** (ağı boğmama) uygulanır. Üçlü el sıkışmanın amacı sadece "merhaba" demek değil: her iki tarafın başlangıç sıra numarasında anlaşmasını ve **eski, gecikmiş bir bağlantı isteğinin** yeni bir bağlantı sanılmasını önlemeyi sağlar (RFC 9293 — 2022'de RFC 793'ün yerine geçen güncel TCP standardı, 41 yıllık düzeltmeyi tek metinde toplar).

**UDP (User Datagram Protocol)** bağlantısızdır (RFC 768): el sıkışma yok, sıra numarası yok, yeniden gönderim yok, onay yok. Her datagram bağımsız gönderilir; kaybolursa kaybolur, sırası bozulursa bozuk gelir. Karşılığında **çok düşük gecikme ve ek yük** sunar; kaybı/sırayı önemseyen uygulama bunu kendisi halleder.

**Ne zaman hangisi:** Bütünlüğün şart, gecikmenin ikincil olduğu her şey TCP — web (HTTP), e-posta, SSH, dosya aktarımı. Anlık olmanın kaybı tolere etmekten önemli olduğu şeyler UDP — DNS sorguları (küçük, tek pakette biter, kaybolursa tekrar sorulur), VoIP ve video (geç gelen ses paketi zaten işe yaramaz), DHCP, oyunlar, QUIC/HTTP-3 (TCP'nin baş-tıkanıklığını aşmak için UDP üstüne kendi güvenilirliğini kuruyor).

### 8. DHCP ve DNS

**DHCP (Dynamic Host Configuration Protocol)**, bir cihaza ağa girdiğinde IP adresi, subnet mask, gateway ve DNS sunucusunu **otomatik** veren protokoldür (RFC 2131); UDP üzerinde çalışır, sunucu port 67, istemci port 68. Süreç dört adımdır, kısaltması **DORA**: istemci `DISCOVER` broadcast eder (henüz IP'si yok), sunucu(lar) `OFFER` ile bir adres önerir, istemci `REQUEST` ile birini seçtiğini broadcast eder (diğer sunucular önerilerini geri çeker), sunucu `ACK` ile kiralamayı (lease — belirli süreli) onaylar. **Neden broadcast:** istemci başta ne kendi IP'sini ne sunucunun IP'sini bilir, tek ulaşabileceği yol "buradaki herkes" demektir. Bir alt ağda DHCP sunucusu yoksa router üzerinde **DHCP relay** ile istekler başka bir alt ağdaki sunucuya iletilir.

**DNS (Domain Name System)**, insan-okunur isimleri (`example.com`) IP adreslerine çeviren dağıtık veritabanıdır (RFC 1034 kavramlar, RFC 1035 uygulama); genelde UDP port 53 (büyük cevaplar ve zone transfer için TCP 53). Nasıl çalışır: bir **resolver** (cihazındaki `systemd-resolved` / `/etc/resolv.conf`'taki sunucu) ismi çözmek için hiyerarşiyi tırmanır — kök sunucular → `.com` TLD sunucuları → `example.com`'un yetkili (authoritative) sunucusu. İki sorgu tipi vardır: **özyinelemeli (recursive)** — "sen benim için tüm işi yap, bana nihai cevabı getir" (istemcinin resolver'a sorduğu şey); **yinelemeli (iterative)** — "bildiğini söyle, bilmiyorsan beni bir sonraki sunucuya yönlendir" (resolver'ın kök/TLD sunucularına sorduğu şey). Cevaplar **TTL** süresince önbelleğe alınır, bu yüzden bir DNS değişikliği anında yayılmaz.

**Ne zaman / kim:** Sistem yöneticisi "ping 8.8.8.8 çalışıyor ama ping google.com çalışmıyor" gördüğünde sorunun ağda değil **isim çözümlemede** (yanlış/erişilemez DNS sunucusu) olduğunu anlar. `dig`, `nslookup`, `resolvectl` teşhis araçlarıdır.

### 9. Firewall

**Firewall**, hangi ağ trafiğine izin verilip hangisinin engelleneceğine kaynak/hedef IP, port ve protokol gibi kriterlere göre karar veren süzgeçtir. Linux'ta firewall **çekirdeğin içindedir**: **netfilter** çerçevesi, ağ yığınının belirli noktalarına (**hook**) yerleştirilmiş kancalardır — bir paket ağ kartından girdiğinde `prerouting`, yerel bir sürece gidiyorsa `input`, başka bir ağa yönlendiriliyorsa `forward`, yerel bir süreçten çıkıyorsa `output`, karttan çıkmadan hemen önce `postrouting` kancasından geçer. Her kancada çekirdek, kayıtlı kuralları sırayla değerlendirir ve paketi kabul/ret/değiştir.

Kuralları yazan modern kullanıcı-alanı aracı **nftables**'tır (`nft` komutu); Debian 10+, Ubuntu 20.10+, RHEL/Rocky 8+ sistemlerinde çekirdek arka planı artık nftables'tır (eski `iptables` çoğu sistemde nftables'a çeviren bir uyumluluk katmanıdır). Çoğu yönetici doğrudan `nft` yazmaz, bir **ön yüz** kullanır: **Debian ve Ubuntu'da `ufw`** (Uncomplicated Firewall — `ufw allow 22/tcp` gibi basit komutlar), **Rocky/RHEL'de `firewalld`** (`firewall-cmd`, "zone" kavramıyla). İkisi de altta nftables'a kural üretir. **Neden çekirdekte:** paket süzme her pakette, hatta saniyede milyonlarca kez olur; bunu kullanıcı-alanında yapmak çok yavaş olurdu — netfilter kararı paket zaten çekirdekteyken, kopyalama olmadan verir.

**Ne zaman / kim:** Sunucu kurulumunda "sadece 22, 80, 443 açık olsun, gerisi kapalı" politikası; bir servis erişilemiyorsa "firewall mı engelliyor" kontrolü (`ufw status`, `firewall-cmd --list-all`, `nft list ruleset`). Bu işlemler root ister.

### 10. ping ve ICMP

**ICMP (Internet Control Message Protocol)**, IP'nin "durum ve hata bildirimi" yardımcısıdır (RFC 792). IP'nin kendisi veri taşımaz-durumu bildirmez; bir paket TTL'i bittiği için atıldığında, hedef port kapalı olduğunda veya bir ağ erişilemez olduğunda bunu kaynağa haber veren mekanizma ICMP'dir. ICMP mesajları IP paketinin **içinde** taşınır (protokol numarası 1) ama mimari olarak IP'nin ayrılmaz parçası sayılır — yani ayrı bir taşıma protokolü değildir, port kullanmaz.

**ping**, ICMP'nin **Echo Request (tip 8)** mesajını hedefe gönderip **Echo Reply (tip 0)** bekleyen küçük bir araçtır. Nasıl çalışır: ping bir Echo Request yollar, içine bir kimlik + sıra numarası + zaman damgası koyar; hedef, RFC 792 gereği aldığı veriyi **aynen** Echo Reply'a kopyalayıp geri gönderir; ping dönen paketin zaman damgasından gidiş-dönüş süresini (RTT) hesaplar, sıra numarasından kayıp paketi tespit eder. "Neden çalışır" sorusunun cevabı: Echo Reply, ICMP standardının **zorunlu** kıldığı bir davranıştır — bir IP yığını uyguluyorsan Echo Request'e cevap vermek zorundasın (ancak firewall'lar bunu bilerek engelleyebilir, o yüzden "ping atmıyor" her zaman "cihaz kapalı" demek değildir).

Linux'ta `ping` eskiden ham soket (raw socket) açtığı için **setuid root** bir binary'ydi; modern sistemlerde `CAP_NET_RAW` yeteneği ya da `net.ipv4.ping_group_range` çekirdek ayarıyla ayrıcalıksız çalışabiliyor. `ping` aracı 1983'te Mike Muuss tarafından, denizaltı sonarının "ping" sesine öykünerek yazıldı.

**Ne zaman / kim:** Bir teşhisin ilk adımı — "cihaz ayakta ve ağ katmanı (L3) çalışıyor mu?". `ping <gateway>` → yerel ağ tamam mı; `ping 8.8.8.8` → internet yönlendirmesi tamam mı; `ping google.com` → DNS tamam mı. Üçünü sırayla denemek sorunu katman katman daraltır.

### 11. Ağ teşhis araçları: `ss`, `traceroute`, `telnet`

**`ss` (socket statistics)**, çekirdeğin açık ağ soketlerini listeler ve eski `netstat`'ın yerini alan **iproute2** paketinin aracıdır. Mekanizma farkı önemlidir: `netstat`, `/proc/net/tcp` gibi metin dosyalarını açıp ayrıştırır (yavaş, binlerce bağlantıda gözle görülür gecikme); `ss`, çekirdekle **netlink** üzerinden `sock_diag` protokolüyle konuşur — ikili, çekirdek tarafında filtreleyebilen, `/proc` metninde hiç görünmeyen TCP durum bilgisini de verebilen bir arayüz. 2009'dan beri Debian `net-tools`'u (netstat/ifconfig) kullanımdan kaldırılmış ilan etti; modern dağıtımlarda `net-tools` çoğu zaman kurulu bile gelmez.

`ss -nltp` en sık kombinasyondur; parametreler tek tek hangi sorunu çözer: **`-n`** adres ve portları **sayısal** gösterir — DNS ters çözümlemesi yapmaz, yani çıktı hem hızlı gelir hem de DNS'i çökük bir sunucuda takılmaz. **`-l`** sadece **LISTEN** durumundaki soketleri gösterir — yani "hangi servis bağlantı bekliyor"; bu olmadan kurulu tüm bağlantılar da listelenir ve gürültü olur. **`-t`** TCP soketleri (`-u` ise UDP; ikisi de yazılmazsa `ss` ham/paket soketleri de karıştırır). **`-p`** soketi açan **süreç ve PID**'yi ekler — "80'i kim dinliyor" sorusunun cevabı; bu bilgiyi çekirdek sadece soketin sahibine veya root'a verir, yani `-p` çıktısının dolu gelmesi için `sudo` gerekir. Ne zaman kullanılır: bir servis kurduktan sonra gerçekten dinliyor mu (`ss -nltp | grep :80`), "address already in use" hatasında portu tutan süreci bulmak, güvenlik denetiminde beklenmedik açık port aramak.

**`traceroute`**, bir paketin hedefe giderken geçtiği router'ları (hop'ları) sırayla listeler. Nasıl çalışır — IP başlığındaki **TTL (Time To Live)** alanını sömürür: her router bir paketi ilettiğinde TTL'i 1 azaltır, TTL 0'a düşerse paketi atar ve kaynağa bir **ICMP Time Exceeded (tip 11)** gönderir. traceroute önce TTL=1 ile bir sonda yollar → ilk router atar ve kendini ele verir; sonra TTL=2 → ikinci router; böyle artırarak hedefe ulaşana kadar devam eder. Klasik Unix `traceroute` UDP sondaları kullanır (yüksek, kullanılmayan portlara), Windows `tracert` ICMP Echo kullanır, `traceroute -I` de öyle; hedefe varıldığı, UDP'de "ICMP Port Unreachable", ICMP'de "Echo Reply" dönmesinden anlaşılır. Ne zaman kullanılır: "bağlantı yavaş / kopuyor, nerede tıkanıyor" — hangi hop'ta gecikmenin fırladığını ya da yanıtın kesildiğini (`* * *`) görmek için. Yıldızlar her zaman "arıza" demek değil; birçok router ICMP'yi hız-sınırlar veya sessizce yutar.

**`telnet`**, uzak bir makinede oturum açmak için tasarlanmış en eski internet protokollerinden biridir (RFC 854, 1983; kökeni 1969 ARPANET). Bir **NVT (Network Virtual Terminal)** soyutlaması tanımlar: iki uç, birbirinin terminal özelliklerini bilmek zorunda kalmasın diye ortak, hayalî bir terminal üzerinden konuşur. **Neden artık kullanılmıyor:** telnet **her şeyi düz metin** taşır — kullanıcı adı, parola, tüm komutlar şifresiz gider; aynı ağı dinleyen biri hepsini okur. Bu yüzden uzak oturum işini tamamen **SSH** devraldı. Bugün `telnet` sadece bir **teşhis aracı** olarak yaşıyor: `telnet <host> <port>` ile "şu port açık mı ve arkasındaki servis ne cevap veriyor" bakılır (örn. `telnet mailhost 25` ile SMTP banner'ı görmek, `telnet web 80` ile elle HTTP isteği yazmak). Bu iş için `nc` (netcat) ve `curl` daha yaygın modern alternatiflerdir. Ne zaman / kim: sistem yöneticisi bir TCP portunun ulaşılabilir olduğunu ve el sıkışmanın kurulduğunu hızlıca doğrulamak istediğinde; oturum açmak için asla.

### Kaynaklar

Aşağıdaki kaynaklar konu başlıklarına göre gruplandı. Ağ temellerinin çoğu 20–40 yıldır sabit RFC/IEEE standartlarıdır; yine de her başlık için birincil kaynak (RFC Editor, IETF Datatracker, freedesktop.org, nftables wiki) verildi. Güncel dağıtım sürümleri ayrıca doğrulandı.

- **Katmanlı model / OSI / TCP/IP / PDU:**
  - [RFC 1122 — Requirements for Internet Hosts (Communication Layers)](https://www.rfc-editor.org/rfc/rfc1122.html) — TCP/IP dört katmanının resmî tanımı
  - [ISO/IEC 7498-1 — OSI Basic Reference Model](https://www.iso.org/standard/20269.html) — OSI yedi katman ve PDU/kapsülleme (özet: [Global Knowledge OSI white paper](https://www.globalknowledge.com/ca-en/resources/resource-library/white-paper/foundational-focus-osi-model-breaking-down-the-7-layers/), ikincil — kavram doğrulama)
- **Ethernet / frame / MAC / ARP:**
  - [RFC 826 — An Ethernet Address Resolution Protocol](https://www.rfc-editor.org/rfc/rfc826) — IP↔MAC eşlemesi
  - [How switches learn MAC addresses / CAM table — Cisco Press](https://www.ciscopress.com/articles/article.asp?p=3089352&seqNum=6) — ikincil, switch öğrenme mekanizması
- **Ağ cihazları (hub/switch/bridge/router/gateway):**
  - [RFC 1122](https://www.rfc-editor.org/rfc/rfc1122.html) (katman tanımları) + Cisco Press (yukarıda) — hub L1 / switch L2 / router L3 ayrımı ve çakışma alanı
- **Broadcast / VLAN / ağ arayüzü:**
  - [IEEE 802.1Q — VLAN tag frame format](https://en.wikipedia.org/wiki/IEEE_802.1Q) (ikincil özet; birincil: IEEE 802.1Q-2022 standardı) — 4 baytlık etiket, 12 bit VID
  - [Predictable Network Interface Names — freedesktop.org / systemd](https://www.freedesktop.org/wiki/Software/systemd/PredictableNetworkInterfaceNames/) — `enp3s0` şeması, v197'den beri
- **IP adresleme / IPv4 / IPv6 / CIDR:**
  - [RFC 791 — Internet Protocol (IPv4)](https://www.rfc-editor.org/rfc/rfc791)
  - [RFC 8200 — Internet Protocol, Version 6 (IPv6) Specification](https://www.rfc-editor.org/rfc/rfc8200.html) — 128 bit, RFC 2460'ı geçersiz kılar
  - [RFC 4632 — Classless Inter-domain Routing (CIDR)](https://www.rfc-editor.org/rfc/rfc4632.html) — sınıfların kaldırılması, prefix notasyonu
- **Paket / buffer / soket / port:**
  - [RFC 6335 — IANA Procedures for the Service Name and Transport Protocol Port Number Registry](https://www.rfc-editor.org/rfc/rfc6335.html) — 0–1023 / 1024–49151 / 49152–65535 aralıkları
  - [Berkeley sockets — 4.2BSD (1983) tarihçesi](https://en.wikipedia.org/wiki/Berkeley_sockets) (ikincil); birincil arayüz: [`man 7 socket` — man7.org](https://man7.org/linux/man-pages/man7/socket.7.html)
- **TCP / UDP:**
  - [RFC 9293 — Transmission Control Protocol (TCP)](https://www.rfc-editor.org/rfc/rfc9293.html) — 2022, RFC 793'ün yerine; üçlü el sıkışmanın gerekçesi
  - [RFC 768 — User Datagram Protocol](https://www.rfc-editor.org/rfc/rfc768.txt)
- **DHCP / DNS:**
  - [RFC 2131 — Dynamic Host Configuration Protocol](https://www.rfc-editor.org/rfc/rfc2131) — DORA, UDP 67/68
  - [RFC 1034 — Domain Names: Concepts and Facilities](https://www.rfc-editor.org/rfc/rfc1034) ve [RFC 1035 — Implementation and Specification](https://www.rfc-editor.org/rfc/rfc1035) — recursive vs iterative sorgu
- **Firewall:**
  - [Netfilter hooks — nftables wiki](https://wiki.nftables.org/wiki-nftables/index.php/Netfilter_hooks) — prerouting/input/forward/output/postrouting kancaları
  - [Inside Linux Packet Filtering: Netfilter and nftables — Oracle Linux Blog](https://blogs.oracle.com/linux/inside-linux-packet-filtering-netfilter-and-nftables) — ikincil, nftables'ın Debian 10+/Ubuntu 20.10+/RHEL 8+ varsayılan arka plan olması
  - [Uncomplicated Firewall (ufw) — Wikipedia](https://en.wikipedia.org/wiki/Uncomplicated_Firewall) (ikincil) — Debian/Ubuntu ufw, Rocky/RHEL firewalld
- **ICMP / ping:**
  - [RFC 792 — Internet Control Message Protocol](https://www.rfc-editor.org/rfc/rfc792) — Echo Request (8) / Echo Reply (0), Time Exceeded (11)
  - [RFC 1122 §3.2.2.6 — Echo Request/Reply zorunluluğu](https://www.rfc-editor.org/rfc/rfc1122.html)
- **ss / traceroute / telnet:**
  - [ss(8) — sock_diag/netlink — iproute2](https://man7.org/linux/man-pages/man8/ss.8.html)
  - [traceroute(8) — man7.org](https://man7.org/linux/man-pages/man8/traceroute.8.html) — TTL / ICMP Time Exceeded mekanizması
  - [RFC 854 — Telnet Protocol Specification](https://www.rfc-editor.org/rfc/rfc854) — NVT; düz metin (şifresiz) taşıma
- **Güncel dağıtım sürümleri (2026-08 doğrulaması):**
  - [Debian 13 "trixie" release information](https://www.debian.org/releases/trixie/) — güncel stable, 13.6 (2026-07)
  - [Ubuntu 24.04.4 LTS released](https://lists.ubuntu.com/archives/ubuntu-announce/2026-February/000321.html) — güncel LTS "Noble Numbat"
  - [Rocky Linux Release and Version Guide](https://wiki.rockylinux.org/rocky/version/) — güncel: 10.2; ayrıca 9.8 ve 8.10 destekte

## Notlar

- Günün tek büyük fikri: **her ağ kavramı bir katmana aittir** ve bir sorunu teşhis etmek, sorunun hangi katmanda olduğunu bulmaktır. `ping <gateway>` → 2-3. katman; `ping 8.8.8.8` → 3. katman yönlendirme; `ping alanadi.com` → DNS (uygulama katmanı); `ss -nltp` + `telnet host port` → 4. katman/servis. Araçlar da bu sırayla kullanılır.
- İki adres, iki kapsam: **MAC adresi yereldir** (her router'da yeniden yazılır, sadece segment içi anlam taşır), **IP adresi uçtan uçadır** (yol boyunca sabit). ARP bu ikisi arasındaki köprüdür — IPv4'ün Ethernet üstünde çalışabilmesi ona bağlı.
- **TCP vs UDP** tercihi tek soruya iner: "kayıp/sıra bozulması bu uygulama için mi felaket, yoksa gecikme mi?" Bütünlük kritikse TCP (web, ssh, e-posta), anlıklık kritikse UDP (DNS, VoIP, video, DHCP).
- Tarihsel desen: **eski araç → güvenlik/ölçek sorunu → modern yerine geçen.** telnet → SSH (şifreleme), netstat/ifconfig → ss/ip (netlink hızı), sınıflı adresleme → CIDR (adres israfı), iptables → nftables (tek çerçeve). Bu eğitimde tekrar tekrar görülüyor (Gün 6'da `procps`, SysVinit → systemd).
- Linux'ta firewall **çekirdeğin içinde** (netfilter); `ufw`/`firewalld` sadece ona kural yazan ön yüzler — ikisi de bugün altta nftables kullanıyor.

## Komutlar / Örnekler

```bash
# arayüz ve adres
ip link                      # ağ arayüzleri (enp3s0, lo, br0...) ve MAC adresleri
ip address                   # arayüzlere atanmış IP adresleri + prefix (/24 gibi)
ip -brief address            # kısa/okunur özet

# yönlendirme ve komşuluk
ip route                     # yönlendirme tablosu; "default via X" = gateway
ip neigh                     # ARP tablosu (IP -> MAC eşlemeleri, kısa ömürlü)

# bağlantı testi — katman katman
ping -c4 192.168.1.1         # yerel ağ / gateway ulaşılabilir mi (L2-L3)
ping -c4 8.8.8.8             # internet yönlendirmesi çalışıyor mu (L3)
ping -c4 google.com          # DNS çözümlemesi çalışıyor mu (uygulama)

# yol izleme
traceroute 8.8.8.8           # UDP sondaları (klasik)
traceroute -I 8.8.8.8        # ICMP Echo ile (tracert gibi)

# soketler / dinleyen servisler
ss -nltp                     # sayısal, dinleyen, TCP, süreç/PID (PID için sudo)
ss -nlup                     # aynısı UDP için
ss -ntp state established     # kurulu TCP bağlantıları
ss -s                        # özet istatistik

# port / servis testi
telnet mail.example.com 25   # portun açık olduğunu ve servis banner'ını gör
nc -vz example.com 443       # modern alternatif (bağlan, kapat, sonucu söyle)

# DNS teşhisi
dig google.com               # tam sorgu + cevap + TTL
resolvectl status            # sistemin kullandığı DNS sunucuları (systemd-resolved)

# firewall durumu
sudo ufw status verbose      # Debian / Ubuntu
sudo firewall-cmd --list-all # Rocky / RHEL
sudo nft list ruleset        # her ikisinin altındaki gerçek kural seti
```

## Sorular / Takip Edilecekler

- [ ] Kendi VM'de `ip route` çıktısındaki `default via` adresini bul, sonra `traceroute` ile o adresin ilk hop olduğunu doğrula.
- [ ] `ss -nltp` çıktısını `sudo` ile ve `sudo`'suz çalıştırıp karşılaştır — `-p` (süreç/PID) sütununun neden sadece `sudo` ile dolduğunu gözlemle.
- [ ] `telnet google.com 80` ile bağlanıp elle `GET / HTTP/1.0` + iki Enter yazarak bir HTTP cevabı al; sonra aynısını `telnet google.com 443` ile dene ve neden okunabilir bir cevap gelmediğini (TLS şifreli el sıkışma) not et.
- [ ] `dig` ile bir alan adını iki kez sorgula ve ikinci sorguda cevabın `TTL` değerinin düştüğünü / cevabın önbellekten geldiğini gözlemle.
- [ ] VM'de `nft list ruleset` çalıştır — Debian 13'te `ufw` etkinleştirilmeden kural seti nasıl görünüyor, `ufw enable` sonrası ne değişiyor?
