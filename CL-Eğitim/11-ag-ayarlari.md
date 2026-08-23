---
tags: [linux, egitim, ag, network]
modul: 11
durum: tamamlandi
---

# 11 — Ağ Ayarları

> **Ön koşul:** [01-sunucu-kurulumu](01-sunucu-kurulumu.md)
> **Süre:** ~4 saat

## Hedefler

- [ ] IP, alt ağ maskesi, gateway kavramlarını uygulayabiliyorum
- [ ] Her iki ailede statik/DHCP yapılandırması yapabiliyorum
- [ ] `ip` komut ailesini `ifconfig` yerine kullanıyorum
- [ ] Ağ sorununu katman katman teşhis edebiliyorum
- [ ] DNS, hostname çözümleme ve güvenlik duvarı yönetebiliyorum

---

## 1. Temel kavramlar — IP, maske ve gateway'i gerçekten anlamak

### IP adresi — bir "sokak + kapı numarası" gibi düşün

Bir IP adresi (`192.168.1.50` gibi) tek başına anlamlı değildir; her zaman bir
**alt ağ maskesiyle (subnet mask)** birlikte gelir, çünkü IP'nin hangi kısmının
"ağ" (mahalle), hangi kısmının "host" (o mahalledeki senin evinin numarası)
olduğunu maskesi belirler.

> **Benzetme — apartman ve daire numarası:**
> `192.168.1.0/24` bir apartman sitesi (**ağ**) gibi düşün. `/24`, ilk 24 bitin
> (yani `192.168.1` kısmının) **sabit site adresi** olduğunu, geri kalan 8 bitin
> (son sayı, `.0`–`.255`) ise o sitedeki **daire numarası** olduğunu söyler.
> `192.168.1.50` demek, "192.168.1 sitesindeki 50 numaralı daire" demektir.
> Aynı siteden (aynı `/24` ağından) biri diğerine mektup gönderirken kapıcıya
> (yönlendiriciye/gateway'e) ihtiyaç duymaz — direkt komşuya gider. Ama site
> dışına (başka bir ağa, örneğin internete) mektup gönderecekse, mektup önce
> **sitenin çıkış kapısına** (gateway'e) gitmek zorundadır.

Bu yüzden üç kavram her zaman birlikte anlam kazanır:

| Kavram | Ne işe yarar | Benzetmedeki karşılığı |
|---|---|---|
| **IP adresi** | Cihazın o ağdaki tekil kimliği | Daire numaran |
| **Alt ağ maskesi (subnet mask / CIDR)** | Adresin hangi kısmının "aynı mahalle" (ağ), hangisinin "senin numaran" (host) olduğunu belirler | Site sınırı — kimler "komşun" |
| **Gateway (ağ geçidi)** | Kendi ağının **dışına** giden trafiğin teslim edildiği yönlendirici | Sitenin çıkış kapısı, dış dünyaya açılan yol |

**Maske matematiği — neden `/24` = 254 host?**
`/24`, IP'nin 32 bitlik toplam uzunluğunun ilk 24 bitinin sabit (ağ), kalan
32-24 = **8 bitinin** değişken (host) olduğu anlamına gelir. 8 bit ile
2⁸ = 256 farklı değer üretilebilir (0'dan 255'e). Ama bu 256'nın ikisi özel
ayrılmıştır: en küçüğü (`.0`) **ağ adresi**dir (sitenin kendisini tanımlar, bir
cihaza atanamaz), en büyüğü (`.255`) **broadcast adresi**dir (o ağdaki herkese
aynı anda mesaj göndermek için ayrılmıştır, o da bir cihaza atanamaz). Geriye
256 − 2 = **254 kullanılabilir adres** kalır.

| CIDR | Maske (insan-okunur) | Host bitleri | Kullanılabilir host |
|---|---|---|---|
| /24 | 255.255.255.0 | 8 | 254 |
| /25 | 255.255.255.128 | 7 | 126 |
| /26 | 255.255.255.192 | 6 | 62 |
| /16 | 255.255.0.0 | 16 | 65534 |
| /30 | 255.255.255.252 | 2 | 2 (nokta-nokta bağlantılar için — sadece 2 cihaz sığar) |

Genel formül: kullanılabilir host = 2^(host bit sayısı) − 2. `/30`'un neden
sadece 2 cihaz için kullanıldığını da bu formül açıklar — iki router'ı doğrudan
birbirine bağlarken daha büyük bir ağ israf etmemek için en küçük pratik ağ
budur.

**Özel (private) IP aralıkları:** `10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`
Bunlar internette **doğrudan yönlendirilmez** — yani dünyanın her yerinde binlerce
farklı ev/şirket ağı aynı `192.168.1.x` aralığını kullanabilir, çünkü bu adresler
sadece kendi yerel ağınızın içinde anlamlıdır (internete çıkarken NAT ile gerçek/
public bir IP'ye çevrilirler).

### Katmanlı düşünme — ağ sorunlarını nereden aramaya başlarsın?

Ağ, birbirinin üzerine inşa edilmiş katmanlardan oluşur; alt katman çalışmazsa
üstteki hiçbir şey çalışmaz. Bu yüzden bir sorun ararken **her zaman en alt
katmandan başlayıp yukarı çıkarsın** — üst katmanda debelenmek, kablo çıkmışken
DNS ayarlarıyla uğraşmak gibi zaman kaybettirir.

```
L1 Fiziksel  → kablo/link var mı        ip link
L2 Veri bağı → MAC, ARP, VLAN           ip neigh, arp
L3 Ağ        → IP, rota                 ip a, ip r, ping
L4 Taşıma    → port, TCP/UDP            ss, telnet, nc
L7 Uygulama  → DNS, HTTP                dig, curl
```

Bu sırayı ezberlemek yerine mantığını kavra: "kablo takılı mı" sorusunun cevabı
yoksa (L1), "IP alıyor mu" sorusunu sormanın anlamı yoktur (L3); "IP'si var mı"
sorusunun cevabı yoksa "web sitesi açılıyor mu" sorusu (L7) anlamsızdır. Aşağıdaki
5. bölümdeki teşhis akış şeması bu mantığı adım adım komutlarla gösteriyor.

---

## 2. `ip` komut ailesi (modern standart)

> `ifconfig`, `route`, `netstat`, `arp` gibi eski araçlar (`net-tools` paketi)
> **kullanımdan kalktı (deprecated)**. RHEL 8+ ve Debian 12 minimal kurulumlarında
> bu paket **yüklü bile gelmiyor**. Yerini `iproute2` paketindeki `ip` ve `ss`
> komutları aldı. Eski komutları hâlâ internette/eski dokümanlarda görürsün,
> bu yüzden karşılıklarını bilmek gerekir — ama **yeni yazdığın her komut/betikte
> `ip` ailesini kullan.**

| Eski (net-tools) | Yeni (iproute2) |
|---|---|
| `ifconfig` | `ip addr` / `ip a` |
| `ifconfig eth0 up` | `ip link set eth0 up` |
| `ifconfig eth0 192.168.1.5/24` | `ip addr add 192.168.1.5/24 dev eth0` |
| `route -n` | `ip route` / `ip r` |
| `route add default gw X` | `ip route add default via X` |
| `arp -n` | `ip neigh` |
| `netstat -tulnp` | `ss -tulnp` |
| `netstat -i` | `ip -s link` |

```bash
ip a                                  # tüm arayüzlerin tüm adresleri
ip -br a                              # ⭐ kısa, okunaklı özet (br = brief)
ip -4 a                               # sadece IPv4
ip a show ens18                       # tek arayüz

ip link                               # arayüzler ve fiziksel durumları (UP/DOWN)
ip link set ens18 up|down
ip -s link show ens18                 # paket/hata istatistikleri (-s = statistics)

# Geçici adres ekleme (reboot'ta kaybolur — sadece test amaçlı!)
sudo ip addr add 192.168.1.60/24 dev ens18
sudo ip addr del 192.168.1.60/24 dev ens18
```

**Neden "geçici" diyoruz, kalıcı yapmak için neden yetmez?**
`ip addr add` komutu, çekirdeğin o anki çalışan ağ yapılandırmasını doğrudan
değiştirir — hiçbir dosyaya yazmaz. Sistem yeniden başladığında çekirdek ağ
arayüzlerini sıfırdan kurar ve sadece **kalıcı yapılandırma dosyalarında**
(aşağıdaki 3. bölüm — NetworkManager/netplan/interfaces) ne yazıyorsa onu okur.
Bu, `mount` komutunu hatırlarsan tıpatıp aynı mantıktır: `mount` da anlık bağlar,
kalıcılık için `/etc/fstab`'a yazman gerekirdi. Burada da aynı ayrım var: **anlık
komut vs. kalıcı yapılandırma dosyası.**

```bash
ip r                                  # yönlendirme (routing) tablosu
sudo ip route add default via 192.168.1.1
sudo ip route add 10.0.0.0/8 via 192.168.1.254
ip route get 8.8.8.8                  # ⭐ "8.8.8.8'e gitmek için hangi rota/arayüz kullanılacak?"

ip neigh                              # ARP tablosu — "bu IP'nin fiziksel (MAC) adresi ne?"
```

**`ip route get` neden özellikle faydalı?** Elle rota tablosuna (`ip r`) bakıp
hangi satırın hangi hedefe uygulanacağını hesaplamak yerine, doğrudan çekirdeğe
"bu hedefe gidersem hangi kararı verirsin" diye sorarsın — çekirdek, gerçekte
kullanacağı arayüz ve sonraki durağı (next hop) doğrudan söyler. Sorun giderirken
"doğru rota mı kullanılıyor" şüphesini anında ortadan kaldırır.

---

## 3. Kalıcı yapılandırma — dağıtım farkları

> **Bu bölüm, ailelerin en çok ayrıştığı yerdir.** Neden bu kadar farklı araçlar
> var diye sorarsan: her aile kendi tarihsel gelişimi içinde farklı bir ağ
> yönetim felsefesi benimsedi. RHEL ailesi masaüstü kökenli **NetworkManager**'ı
> sunucularda da standartlaştırdı; Debian, geleneksel `ifupdown` sistemine sadık
> kaldı; Ubuntu ise kendi `netplan` katmanını ekleyip altta hem `NetworkManager`'ı
> hem `systemd-networkd`'yi kullanabilen esnek bir köprü kurdu. Sonuç olarak
> "IP nasıl atarım" sorusunun cevabı, hangi dağıtımda olduğuna göre değişir —
> ama hepsinin çözdüğü problem aynıdır: **bir yapılandırmayı dosyaya yazıp, kalıcı
> olmasını, açılışta otomatik uygulanmasını sağlamak.**

### RHEL 9 / Rocky 9 / Alma 9 — NetworkManager (`nmcli`)

```bash
nmcli con show                     # tanımlı bağlantı profilleri
nmcli con show "ens18"             # bir profilin tüm detayı
nmcli dev status                   # fiziksel/mantıksal cihazların durumu

# Statik IP ata
sudo nmcli con mod "ens18" \
  ipv4.method manual \
  ipv4.addresses 192.168.1.50/24 \
  ipv4.gateway 192.168.1.1 \
  ipv4.dns "192.168.1.1 8.8.8.8" \
  ipv4.dns-search "lab.local" \
  connection.autoconnect yes

sudo nmcli con up "ens18"          # ⭐ değişikliği FİİLEN uygula — mod tek başına uygulamaz

# DHCP'ye geri dön
sudo nmcli con mod "ens18" ipv4.method auto
sudo nmcli con up "ens18"

# Sıfırdan yeni bir bağlantı profili oluştur
sudo nmcli con add type ethernet con-name lan1 ifname ens19 \
  ip4 10.0.0.5/24 gw4 10.0.0.1

sudo nmtui                         # interaktif, menü tabanlı metin arayüzü — komut ezberlemene gerek kalmaz
```

**`con mod` ile `con up` arasındaki fark neden önemli?** `nmcli con mod`, sadece
profilin **kayıtlı ayarlarını** değiştirir (diskteki dosyayı günceller) — o anki
çalışan bağlantıya hemen yansımaz. `nmcli con up`, o profili **yeniden etkinleştirir**
ve güncel ayarları fiilen uygular. Bu iki adımı `mount -a` mantığıyla
karşılaştırabilirsin: önce ayarı yazarsın (`vi /etc/fstab` gibi), sonra onu
uygulaman gerekir (`mount -a` gibi) — sadece dosyayı değiştirmek otomatik
uygulanmaz.

Yapılandırma dosyaları: `/etc/NetworkManager/system-connections/*.nmconnection`

> RHEL 9'da eski `/etc/sysconfig/network-scripts/ifcfg-*` biçimi **tamamen
> kaldırıldı**. RHEL 8'de hâlâ okunur ama artık önerilmez — yeni sistemlerde
> hep `nmcli`/`nmconnection` kullan.

### Ubuntu 18.04+ — netplan

```bash
ls /etc/netplan/
sudo vi /etc/netplan/01-netcfg.yaml
```
```yaml
network:
  version: 2
  renderer: networkd          # sunucularda genelde bu; masaüstünde NetworkManager de olabilir
  ethernets:
    ens18:
      dhcp4: false
      addresses:
        - 192.168.1.50/24
      routes:
        - to: default
          via: 192.168.1.1
      nameservers:
        addresses: [192.168.1.1, 8.8.8.8]
        search: [lab.local]
```
```bash
sudo chmod 600 /etc/netplan/*.yaml   # Ubuntu 24.04 bu dosyanın izinleri gevşekse uyarı verir
sudo netplan get                     # o an etkin olan (birleştirilmiş) yapılandırmayı gör
sudo netplan try                     # ⭐ 120 saniye içinde onaylamazsan otomatik GERİ ALIR
sudo netplan apply                   # kalıcı olarak uygula
```

**Netplan aslında ne yapıyor?** Netplan doğrudan bir ağ yöneticisi değildir —
YAML dosyanı okuyup arkadaki gerçek motora (genelde sunucularda `systemd-networkd`,
masaüstünde `NetworkManager`) çevirip aktaran bir **çeviri/orkestrasyon katmanıdır**.
Yani senin yazdığın basit YAML, altta daha karmaşık bir yapılandırmaya dönüştürülüp
gerçek motora teslim edilir.

> [!WARNING]
> **`netplan try` neden uzaktan çalışırken hayat kurtarır?**
> Uzak bir sunucuda SSH ile bağlıyken yanlış bir IP/gateway girip `netplan apply`
> dersen ve kendini ağdan koparırsan, o sunucuya bir daha SSH ile **giremezsin** —
> fiziksel/konsol erişimin yoksa sunucu senin için kaybolur. `netplan try`, yeni
> ayarları **geçici olarak** uygular; 120 saniye içinde bir tuşa basıp onaylamazsan
> (ki bağlantın koptuysa onaylayamazsın), eski ayarlara **otomatik geri döner**.
> Bu güvenlik ağı olmadan uzak sunucuda ağ ayarı değiştirmek, üzerinde çalıştığın
> dalı testere ile kesmeye benzer.
>
> YAML dosyaları **girintiye (indentation) karşı çok hassastır** — sekme (tab)
> karakteri kullanma, sadece boşluk kullan. `netplan apply` hata verirse, hangi
> satırda sorun olduğunu söyler; o satırın girintisini kontrol et.
> Ayrıca eski `gateway4:` anahtarı artık kullanımdan kalktı, yerini yukarıdaki
> gibi `routes:` bloğu aldı.

### Debian 12 — `/etc/network/interfaces` (ifupdown)

```bash
sudo vi /etc/network/interfaces
```
```ini
auto lo
iface lo inet loopback

auto ens18
iface ens18 inet static
    address 192.168.1.50/24
    gateway 192.168.1.1
    dns-nameservers 192.168.1.1 8.8.8.8

# DHCP için:
# iface ens18 inet dhcp
```
```bash
sudo systemctl restart networking
# veya sadece tek bir arayüzü yeniden başlat:
sudo ifdown ens18 && sudo ifup ens18
```

Bu, üçü arasında en "klasik" olanıdır — düz metin dosyası, `auto` ile "açılışta
otomatik başlat" denen arayüzler, `iface ... inet static/dhcp` ile o arayüzün
tipi belirlenir. Karmaşık bir soyutlama katmanı yoktur, dosyayı okuyup anlamak
nmcli/netplan'a göre daha doğrudandır — bu yüzden hâlâ minimal/gömülü Debian
kurulumlarında tercih edilir.

### CentOS 6/7 — ifcfg dosyası (referans için — orijinal kursun anlattığı)

```bash
sudo vi /etc/sysconfig/network-scripts/ifcfg-eth0
```
```ini
DEVICE=eth0
BOOTPROTO=static
ONBOOT=yes
IPADDR=192.168.1.50
NETMASK=255.255.255.0
GATEWAY=192.168.1.1
DNS1=8.8.8.8
```
```bash
sudo service network restart      # CentOS 6
sudo systemctl restart network    # CentOS 7
```
Bunu artık kurmayacaksın (CentOS 6/7 destek dışı), ama sahada eski RHEL 7/8
sistemlere denk gelirsen bu formatı tanıman gerekebilir.

### Özet tablo

| Dağıtım | Yönetici | Dosya | Uygulama |
|---|---|---|---|
| RHEL 9 / Rocky 9 | NetworkManager | `/etc/NetworkManager/system-connections/` | `nmcli con up` |
| RHEL 7/8 | NetworkManager | `/etc/sysconfig/network-scripts/ifcfg-*` | `nmcli` / `systemctl restart network` |
| CentOS 6 | network servisi | `/etc/sysconfig/network-scripts/ifcfg-*` | `service network restart` |
| Ubuntu 18.04+ | netplan → networkd/NM | `/etc/netplan/*.yaml` | `netplan apply` |
| Debian 12 | ifupdown | `/etc/network/interfaces` | `systemctl restart networking` |

---

## 4. Hostname ve isim çözümleme

```bash
hostnamectl                                  # tam durum (statik/geçici/pretty hostname, işletim sistemi, kernel)
sudo hostnamectl set-hostname web1.lab.local
hostname                                     # kısa ad
hostname -f                                  # FQDN (Fully Qualified Domain Name — tam nitelikli alan adı)
```

### `/etc/hosts` — sistemin kendi, en basit "telefon rehberi"

```
127.0.0.1     localhost
::1           localhost
192.168.1.50  web1.lab.local  web1
192.168.1.51  db1.lab.local   db1
```

Bu dosya, hiçbir DNS sunucusuna sormadan, doğrudan makinenin kendi belleğinden
isim → IP eşlemesi yapmanı sağlar. **DNS'ten önce bakılır** — yani `/etc/hosts`'ta
bir isim varsa, sistem DNS sunucusuna hiç sormaz, direkt buradaki cevabı kullanır.
Lab ortamında, henüz gerçek bir DNS sunucusu kurmadan makineler arası isimle
çalışmanın en hızlı yoludur — her makinenin `/etc/hosts`'una diğerlerinin IP'sini
elle eklersin.

### `/etc/resolv.conf` — "isim çözerken hangi DNS sunucusuna sorayım?"

```
nameserver 192.168.1.1
nameserver 8.8.8.8
search lab.local
options timeout:2 attempts:2
```

> [!WARNING]
> **Bu dosyayı genelde elle düzenlemek işe yaramaz**
> Çoğu modern sistemde bu dosya **otomatik üretilir**, elle yazdığın değişiklikler
> bir sonraki ağ olayında (arayüz yeniden başlatma, reboot) sessizce ezilir. Doğru
> yer, seni yöneten ağ aracının kendisidir:
> - RHEL/Rocky: NetworkManager üretir → `nmcli con mod ... ipv4.dns "..."` kullan.
> - Ubuntu: `systemd-resolved` devrede → `/etc/resolv.conf` aslında bir
>   **sembolik bağlantıdır** (`/run/systemd/resolve/stub-resolv.conf`'a işaret
>   eder), içinde gerçek DNS sunucuları değil `127.0.0.53` (yerel stub çözümleyici)
>   yazar. Gerçek kullanılan DNS sunucularını görmek için `resolvectl status`
>   çalıştırman gerekir.
> - Netplan kullanıyorsan, DNS ayarı YAML'daki `nameservers:` bloğundan yönetilir,
>   oradan değiştir.

```bash
resolvectl status                # Ubuntu/systemd-resolved — gerçek DNS sunucularını gösterir
resolvectl query google.com
resolvectl flush-caches
```

### `/etc/nsswitch.conf` — "isim çözerken hangi sırayla bakayım?"

```
hosts: files dns myhostname
```

Bu satır, sistemin bir isim (`db1.lab.local` gibi) çözerken hangi kaynaklara,
hangi **sırayla** başvuracağını belirler: önce `files` (yani `/etc/hosts`),
bulamazsa `dns`, o da bulamazsa `myhostname` (makinenin kendi adı). AD/LDAP'a
bağlı kurumsal sistemlerde `passwd`, `group` satırlarına `sss` (SSSD) eklenerek
kullanıcı/grup bilgisi de merkezi dizinden çekilebilir hale getirilir.

### DNS sorgulama araçları — hangisini ne zaman kullanmalısın?

```bash
dig google.com                  # ⭐ en detaylı, ham DNS cevabı (bind-utils / dnsutils paketiyle gelir)
dig +short google.com           # sadece cevabı göster, gürültüyü at
dig @8.8.8.8 google.com         # belirli bir DNS sunucusuna DOĞRUDAN sor ⭐ DNS'i izole test etmek için
dig MX ornek.com                # belirli bir kayıt türünü sorgula (mail sunucusu kaydı)
dig -x 8.8.8.8                  # ters (reverse) sorgu — IP'den isme
host google.com                 # dig'in daha kısa/basit hali
nslookup google.com             # eski ama hâlâ yaygın kullanılan araç
getent hosts google.com         # ⭐ SİSTEMİN GERÇEKTE kullandığı tam çözümleme zincirini izler (nsswitch dahil)
```

> [!WARNING]
> **`dig` ile `getent` neden farklı cevap verebilir?**
> `dig`, doğrudan bir DNS sunucusuna sorar — `/etc/hosts`'u, `nsswitch.conf`'u
> **hiç görmez**, sadece saf DNS protokolü konuşur. `getent hosts` ise gerçek
> bir uygulamanın (tarayıcı, `ping`, `curl`...) izleyeceği **tam yolu** izler:
> önce `/etc/hosts`'a bakar, sonra DNS'e sorar (nsswitch sırasına göre). Bu yüzden
> "`dig` çalışıyor ama uygulamam o adresi bulamıyor" gibi tuhaf durumlarda,
> gerçek sorunu `getent` ile teşhis edersin — çünkü uygulamanın gördüğü gerçeklik
> `dig`'in değil, `getent`'in gösterdiğidir.

---

## 5. Ağ teşhisi — katman katman, en alttan başlayarak

```bash
# L1/L2 — fiziksel bağlantı var mı, komşuyu görüyor muyum?
ip link show ens18                  # state UP / DOWN, NO-CARRIER (kablo yok demek)
ethtool ens18                       # bağlantı hızı, duplex modu, link durumu
ip neigh                            # ARP tablosu — aynı ağdaki komşuları görüyor muyum

# L3 — IP atanmış mı, rota doğru mu?
ip -br a
ip r
ping -c4 192.168.1.1                # kendi gateway'ime ulaşabiliyor muyum
ping -c4 8.8.8.8                    # internete IP ile ulaşabiliyor muyum (DNS'i devre dışı bırakarak test)
ping -c4 google.com                 # internete isimle ulaşabiliyor muyum (DNS de dahil)
traceroute 8.8.8.8                  # paket hangi yönlendiricilerden geçiyor
mtr 8.8.8.8                         # ⭐ traceroute + ping birleşimi, canlı ve sürekli günceller
ping -c4 -M do -s 1472 8.8.8.8      # MTU testi — 1472+28(IP+ICMP başlığı)=1500, standart Ethernet MTU'sunu test eder

# L4 — hedef port açık mı, kim dinliyor?
ss -tulnp                           # ⭐ bu makinede dinlenen (LISTEN) tüm portlar
ss -tan state established           # şu an kurulu (aktif) bağlantılar
ss -tulnp | grep :443
nc -zv sunucu 443                   # belirli bir port açık mı (netcat ile hızlı test)
nc -zv sunucu 20-25                 # bir port aralığını tarama
timeout 3 bash -c "</dev/tcp/sunucu/443" && echo açık    # hiçbir ekstra araç yoksa saf bash ile port testi

# L7 — uygulama seviyesinde cevap alıyor muyum?
curl -I https://ornek.com           # sadece HTTP başlıklarını al (hızlı, gövdeyi indirmez)
curl -v https://ornek.com           # TLS el sıkışması dahil tüm detayı göster
dig ornek.com

# Paket yakalama — "gerçekte ne gidip geliyor" seviyesinde kanıt
sudo tcpdump -i ens18 -n port 80
sudo tcpdump -i any -n host 192.168.1.50
sudo tcpdump -i ens18 -nn -w yakalama.pcap    # Wireshark'ta sonradan incelemek için dosyaya kaydet
```

### Teşhis akış şeması — "önce şunu sor, cevaba göre bir sonrakine geç"

```
ping gateway
 ├─ ✗ → L1/L2 sorunu: kablo, VLAN, switch portu, ip link durumu, ARP
 └─ ✓ → ping 8.8.8.8
          ├─ ✗ → yönlendirme/NAT/firewall sorunu: ip r, gateway yapılandırması
          └─ ✓ → ping google.com
                   ├─ ✗ → DNS sorunu: resolv.conf, dig @8.8.8.8, resolvectl
                   └─ ✓ → nc -zv hedef PORT
                            ├─ ✗ → firewall veya servis çalışmıyor
                            └─ ✓ → uygulama katmanı: curl -v, loglar
```

Bu şema, 1. bölümdeki katman mantığının pratikte nasıl bir karar ağacına
dönüştüğünü gösterir: her adımda "bir önceki katman sağlamsa, sorun bir üst
katmandadır" mantığıyla ilerlersin, rastgele denemeler yapmazsın.

---

## 6. Güvenlik duvarı

> **Dağıtım farkı — üç farklı ön yüz (arayüz), hepsinin altında aslında aynı
> çekirdek teknoloji (nftables) çalışır.** Yani `firewall-cmd`, `ufw`, `nft`
> birbirinden farklı komutlar öğretir ama üçü de arka planda çekirdeğin paket
> filtreleme motoruna kural yazar — sadece o kurallara "kolay isim" veren
> katman farklıdır.

### firewalld (RHEL / Rocky / Alma — varsayılan olarak **aktif** gelir)

```bash
sudo firewall-cmd --state
sudo firewall-cmd --list-all
sudo firewall-cmd --get-active-zones

sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-port=8080/tcp
sudo firewall-cmd --permanent --add-source=192.168.1.0/24 --zone=trusted
sudo firewall-cmd --permanent --remove-service=cockpit
sudo firewall-cmd --reload          # ⭐ --permanent ile eklediklerini FİİLEN uygula

# Kalıcı olmadan hızlı test et (reboot'ta/reload'da kaybolur — güvenli deneme alanı)
sudo firewall-cmd --add-port=8080/tcp
```

> [!WARNING]
> **`--permanent` ve `--reload` arasındaki ilişkiyi kavra**
> `firewalld`'de iki ayrı "gerçeklik" vardır: **runtime** (o an çalışan, hafızadaki
> kurallar) ve **permanent** (diske yazılmış, kalıcı kurallar). `--permanent`
> eklediğin bir kural sadece diske yazılır, **hemen etkili olmaz** — bunu
> `--reload` ile runtime'a da yansıtman gerekir. `--permanent` yazmadan eklediğin
> bir kural ise anında etkilidir ama bir sonraki `reload`/reboot'ta **kaybolur**.
> Kalıcı ve anlık aynı anda istiyorsan ikisini birlikte ekle, ya da `--permanent`
> ekleyip hemen `--reload` çalıştır — bu ikilinin standart kullanım şeklidir.

### ufw (Ubuntu — varsayılan olarak **kapalı (inactive)** gelir)

```bash
sudo ufw status verbose
sudo ufw allow ssh                     # veya: allow 22/tcp
sudo ufw allow from 192.168.1.0/24 to any port 3306
sudo ufw delete allow 8080/tcp
sudo ufw default deny incoming
sudo ufw enable                        # ⚠️ SSH kuralını ÖNCE ekle!
```

`ufw` (uncomplicated firewall — "karmaşık olmayan güvenlik duvarı"), `firewalld`'e
göre çok daha az kavram (zone, service gibi kavramlar yok) sunar; komutlar
neredeyse İngilizce cümle gibi okunur (`allow ssh`, `deny incoming`). Bu
basitlik, Ubuntu'nun "hızlı kur, çalıştır" felsefesiyle örtüşür.

### nftables (Debian — çıplak, doğrudan)

```bash
sudo nft list ruleset
sudo nft add rule inet filter input tcp dport 22 accept
sudo systemctl enable --now nftables
# Kalıcı kurallar /etc/nftables.conf içine yazılır
```

Debian'da hazır bir "kolaylaştırıcı" katman (firewalld/ufw gibi) varsayılan
olarak gelmez — doğrudan çekirdeğin paket filtreleme diliyle (`nft`) çalışırsın.
Daha ham ama daha az soyutlama katmanı demektir.

> [!WARNING]
> **Uzak sunucuda güvenlik duvarı açarken en tehlikeli hata**
> Önce SSH kuralını (22/tcp) ekle, **sonra** güvenlik duvarını etkinleştir.
> Sırayı ters çevirip önce `enable`/`ufw enable` yaparsan ve içinde SSH kuralı
> yoksa, kendi bağlantını kendin keserler — tıpkı bir odada oturup kapıyı
> dışarıdan kilitlemek gibi, konsol erişimin yoksa geri dönemezsin. Güvenlik
> ağı olarak şu numara işe yarar:
> `sudo bash -c 'sleep 300 && systemctl stop firewalld' &`
> Bu, 300 saniye sonra güvenlik duvarını otomatik kapatan bir arka plan görevi
> kurar — 5 dakika içinde tekrar bağlanamazsan duvar kendiliğinden iner ve
> tekrar erişim kazanırsın.

### SELinux (RHEL ailesi) — unutulan, ama sık karşılaşılan katman

```bash
getenforce                     # Enforcing / Permissive / Disabled
sudo setenforce 0              # GEÇİCİ olarak permissive'e al (sorunu izole etmek için)
sudo ausearch -m avc -ts recent      # SELinux'un engellediği erişim denemeleri
sudo semanage port -a -t http_port_t -p tcp 8080   # standart olmayan bir porta izin ver
sudo restorecon -Rv /var/www   # dosyaların SELinux etiketlerini varsayılana döndür
```

**SELinux ile firewall birbirine karıştırılan iki farklı katmandır.** Firewall,
"hangi ağ trafiği bu makineye/porta girebilir" sorusuna cevap verir. SELinux ise
tamamen farklı bir soruya cevap verir: "bu **süreç** (örneğin nginx), bu
**dosyaya/porta** erişmeye **izinli mi**" — trafik firewall'u geçse bile, süreç
kendi SELinux politikasının izin vermediği bir işlem yapmaya çalışırsa engellenir.
Bu yüzden "firewall açık, servis çalışıyor, port dinleniyor ama yine de dışarıdan
bağlanamıyorum" durumunda, RHEL ailesinde ilk şüphelenilecek şey SELinux'tur.
Ubuntu/Debian'ın kavramsal karşılığı **AppArmor**'dur (`aa-status` ile kontrol
edilir) — mantığı benzerdir ama politika biçimi farklıdır.

---

## 7. Ek ağ konuları

```bash
# IP yönlendirme (bu makineyi bir router gibi davranmaya zorlamak)
sudo sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" | sudo tee /etc/sysctl.d/99-forward.conf
sudo sysctl -p

# Bant genişliği izleme — "şu an ağımı kim/ne dolduruyor"
iftop -i ens18            # bağlantı bazlı canlı trafik
nload ens18               # toplam giriş/çıkış hız göstergesi
vnstat -l                 # uzun dönem (günlük/aylık) istatistik
sudo tcpdump -i ens18 -n

# VLAN — tek fiziksel arayüz üzerinde mantıksal ayrı ağlar
sudo nmcli con add type vlan con-name vlan100 ifname ens18.100 dev ens18 id 100

# Bonding / teaming — birden fazla ağ kartını yedekli/toplu kullanma
sudo nmcli con add type bond con-name bond0 ifname bond0 mode active-backup

# Sunucu saat senkronizasyonu (NTP)
timedatectl                        # saat senkronizasyonu durumu
sudo timedatectl set-ntp true
chronyc sources -v                 # RHEL: chrony servisi kullanılır
timedatectl show-timesync          # Ubuntu: systemd-timesyncd kullanılır
```

---

## 🧪 Lab

1. `ip -br a`, `ip r`, `ip neigh` çıktılarını al, her sütunu kendi cümlenle açıkla.
2. Rocky'de `nmcli` ile statik IP ver. `/etc/NetworkManager/system-connections/` altındaki
   dosyayı incele.
3. Debian/Ubuntu'da aynı IP'yi netplan veya `interfaces` ile ver. İki yapılandırmayı
   yan yana koyup karşılaştır.
4. Ubuntu'da `netplan try` kullan, 120 saniye bekleyip geri aldığını gözlemle.
5. `ip addr add` ile geçici ikinci bir IP ekle. Reboot sonrası kaybolduğunu doğrula.
6. `/etc/hosts`'a `192.168.1.51 db1.lab.local db1` ekle, `ping db1` ile test et.
   `dig db1.lab.local` ile `getent hosts db1.lab.local` çıktılarını karşılaştır — **farkı açıkla.**
7. Rocky'de nginx kur, başlat. `ss -tulnp | grep :80` ile dinlediğini doğrula.
   Başka makineden erişmeyi dene — firewalld engelini gör, `--permanent --add-service=http`
   + `--reload` ile aç.
8. Aynı senaryoyu Ubuntu'da `ufw` ile yap.
9. Rocky'de nginx'i 8080 portuna al. Firewall'u açmana rağmen erişemediğini gör —
   `getenforce` ve `ausearch -m avc -ts recent` ile SELinux'u teşhis et,
   `semanage port -a` ile çöz.
10. `tcpdump -i any -n port 80` çalıştırırken başka terminalden `curl` at, paketleri izle.
11. `mtr 8.8.8.8` çalıştır, hangi atlamada gecikme olduğunu oku.
12. `dig @8.8.8.8 google.com` ile `dig google.com` çıktılarını karşılaştır — sunucu farkı.
13. **Teşhis egzersizi:** Bir arkadaşından/kendinden ağı kasten boz (yanlış gateway,
    yanlış DNS, kapalı arayüz), yukarıdaki akış şemasıyla adım adım bul.

---

## ❓ Kendini test et

**S1.** `ping 8.8.8.8` çalışıyor, `ping google.com` çalışmıyor. Sorun nerede?

<details><summary>Cevap</summary>
DNS'te. L3 (rota/gateway) sağlam. `/etc/resolv.conf`, `resolvectl status`,
`dig @8.8.8.8 google.com` ile DNS sunucusuna erişimi kontrol et.
</details>

**S2.** RHEL 9'da `/etc/sysconfig/network-scripts/` boş. Ayarlar nerede?

<details><summary>Cevap</summary>
RHEL 9 ifcfg biçimini kaldırdı. Yapılandırma
`/etc/NetworkManager/system-connections/*.nmconnection` içinde, `nmcli`/`nmtui` ile yönetilir.
</details>

**S3.** `firewall-cmd --add-port=8080/tcp` yaptın, reboot sonrası kural kayboldu. Neden?

<details><summary>Cevap</summary>
`--permanent` kullanmadın; kural sadece çalışma zamanı (runtime) için eklendi.
Doğrusu: `firewall-cmd --permanent --add-port=8080/tcp && firewall-cmd --reload`.
</details>

**S4.** Servis çalışıyor, `ss` portu dinlediğini gösteriyor, firewall açık, ama RHEL'de
dışarıdan bağlanılamıyor. Sırada ne var?

<details><summary>Cevap</summary>
SELinux. `getenforce` ile durumu, `ausearch -m avc -ts recent` ile engellenen erişimi gör.
Standart olmayan port için `semanage port -a -t <tip>_port_t -p tcp <port>` gerekir.
Ubuntu'daki muadili AppArmor'dur.
</details>

**S5.** `dig db1.lab.local` cevap vermiyor ama `ping db1.lab.local` çalışıyor. Nasıl olur?

<details><summary>Cevap</summary>
İsim `/etc/hosts`'ta tanımlı. `dig` doğrudan DNS sunucusuna sorar, `/etc/hosts`'u
atlar. `ping` ise NSS zincirini (`/etc/nsswitch.conf`: `files dns`) kullanır.
Sistemin gerçek davranışını test etmek için `getent hosts db1.lab.local` kullanılır.
</details>

---

## 📋 Hızlı referans

```bash
ip -br a ; ip r ; ip neigh ; ip route get 8.8.8.8
ss -tulnp                              # dinlenen portlar
ping -c4 GATEWAY → 8.8.8.8 → google.com   # katman katman
nc -zv HOST PORT ; mtr HEDEF ; tcpdump -i any -n port 80
dig +short X ; dig @8.8.8.8 X ; getent hosts X ; resolvectl status

# RHEL 9
nmcli con mod "ens18" ipv4.method manual ipv4.addresses X/24 \
      ipv4.gateway Y ipv4.dns "Z"
nmcli con up "ens18" ; nmtui
firewall-cmd --permanent --add-service=http && firewall-cmd --reload
getenforce ; ausearch -m avc -ts recent

# Ubuntu
vi /etc/netplan/01-netcfg.yaml ; netplan try ; netplan apply
ufw allow ssh ; ufw enable ; ufw status verbose

# Debian
vi /etc/network/interfaces ; systemctl restart networking
```
