---
tags: [linux, egitim, kurulum]
modul: 01
durum: tamamlandi
---

# 01 — Sunucu Kurulumu

> **Ön koşul:** Yok
> **Süre:** ~2 saat (kurulum beklemeleri dahil)

## Hedefler

- [ ] Sanallaştırma tiplerini ayırt edebiliyorum (Tip-1 / Tip-2)
- [ ] Sıfırdan bir Linux sunucu kurabiliyorum
- [ ] Disk bölümleme şemasını bilinçli seçebiliyorum
- [ ] Kurulum sonrası ilk ağ ayarını hem GUI'siz hem dosya üzerinden yapabiliyorum
- [ ] `hostname`, saat dilimi, SSH erişimini yapılandırabiliyorum

---

## 1. Sanallaştırma: hangi araç, neden?

**Önce temel soru: sanallaştırma nedir, neden var?**

Fiziksel bir bilgisayarın donanımı (CPU, RAM, disk, ağ kartı) normalde tek bir işletim sistemi tarafından baştan sona kullanılır. Sanallaştırma, bu donanımı **yazılımla bölüp**, her dilime kendi işletim sistemini kurabileceğin sahte (ama işlevsel) bir bilgisayar gibi sunar. Bu sahte bilgisayara **VM (Virtual Machine — sanal makine)** denir. Amaç: tek bir fiziksel makinede onlarca bağımsız sunucu çalıştırmak, hatasını bozunca gerçek donanımı riske atmadan "anlık görüntüden" (snapshot) geri dönebilmek, ve laboratuvar ortamında gerçek bir sunucu almadan pratik yapabilmek.

Bunu yapan yazılıma **hipervizör (hypervisor)** denir — donanımla VM'ler arasındaki trafik polisi. İki türü var:

**Tip-1 (bare-metal — "çıplak metal"):** Hipervizör, donanımın **doğrudan üstünde** çalışır; altında başka bir işletim sistemi yoktur. Kendisi zaten bir işletim sistemi gibi davranır. Benzetme: Bir apartmanı sıfırdan sen inşa edip dairelere bölmen gibi — bina (donanım) doğrudan senin (hipervizörün) kontrolünde.
- Proxmox VE, VMware ESXi, KVM/QEMU (libvirt), Hyper-V Server
- Üretim sunucularında (gerçek şirketlerde) kullanılan budur — performans kaybı en azdır çünkü araya bir "ana işletim sistemi" girmez.

**Tip-2 (hosted — "barındırılan"):** Hipervizör, zaten çalışan bir işletim sisteminin (senin masaüstü Windows/Linux/macOS'unun) **üzerinde sıradan bir uygulama gibi** çalışır. Benzetme: Zaten oturduğun bir evde, bir odayı bölme duvarlarıyla ayırıp alt kiracıya vermen gibi — ev (host OS) hâlâ var ve kendi işlerini de yapıyor, VM sadece onun içinde bir "oda".
- VMware Workstation/Player, VirtualBox, UTM (macOS)
- Laboratuvar/öğrenme için idealdir — kendi dizüstü bilgisayarında, ayrı donanım almadan çalışır.

Kurs VMware Player kullanıyor. Lab için üçü de olur, ama:

| Araç | Artı | Eksi |
|---|---|---|
| VirtualBox | Ücretsiz, her platformda | Ağ performansı zayıf |
| VMware Workstation Pro | Artık kişisel kullanımda ücretsiz, snapshot güçlü | Linux kernel güncellemelerinde modül derleme derdi |
| KVM + virt-manager | Linux'ta en performanslı, üretimle aynı teknoloji | Sadece Linux host |
| Proxmox VE | Gerçek sunucu deneyimi, web arayüz, LXC + KVM | Ayrı bir makine/ayrı disk ister |

> **Öneri:** Elinde ayrı bir makine varsa Proxmox kur. Yoksa ana makinende KVM
> (Linux) veya VMware Workstation (Windows).

### VM kaynak planı (lab için)

Bir VM oluştururken sana "ne kadar CPU/RAM/disk versem" diye sorar. Bu değerler fiziksel donanımdan **rezerve edilir** (Tip-2'de host'un kaynağından pay alır); gereğinden fazla vermek host'u yavaşlatır, gereğinden az vermek VM içindeki işlemleri (paket kurulum, derleme) sürüncemede bırakır.

| Kaynak | Değer | Neden |
|---|---|---|
| CPU | 2 vCPU | Derleme/paket işlemleri hızlansın |
| RAM | 2 GB (GUI'siz), 4 GB (GUI'li) | Sunucu kurulumda GUI kurma |
| Disk 1 | 20 GB | Sistem |
| Disk 2 | 8-16 GB (boş) | Disk + LVM modülleri için, **şimdi ekle** |
| Ağ | Bridged veya NAT | Bridged: LAN'dan erişilir. NAT: internet var, dışarıdan erişilmez |

> **İkinci diski neden şimdiden eklemelisin?** Modül 09 ve 10'da bölümleme, dosya sistemi
> oluşturma ve LVM konularını **gerçek bir diskte** deneyeceksin. Bunu ana (sistem) diskinde
> yaparsan bir hata işletim sistemini bozabilir. Boş bir ikinci disk, "bozarsan önemi yok"
> güvenli bir oyun alanıdır. Sonradan eklemek de mümkündür ama şimdi eklemek pratik zamanı
> kısaltır — VM'i durdurup disk eklemek, çalışırken eklemekten daha az sürpriz çıkarır.

**Bridged vs NAT vs Host-only — bunlar VM'in ağa nasıl bağlanacağını belirler:**

Bir VM'in "sanal ağ kartı" var ama bu kart fiziksel dünyaya nasıl çıkacak, üç modelden biriyle karar verilir:

- `Bridged` (köprülenmiş) — VM'in sanal ağ kartı, host'un fiziksel ağ kartına doğrudan "köprülenir". VM, ev/ofis ağındaki diğer cihazlarla birebir aynı ağdan kendi IP'sini alır (ör. router'dan DHCP ile). Benzetme: VM'e ayrı bir ethernet kablosu çekip aynı switch'e takmışsın gibi — ağdaki her cihaz onu görebilir, o da onları. Bu yüzden başka bir bilgisayardan (host dışında) SSH ile rahatça bağlanabilirsin.
- `NAT` (Network Address Translation) — VM, host'un **arkasına gizlenir**. Host, VM'in trafiğini kendi IP'si üzerinden dışarı taşır (tıpkı evindeki router'ın senin bilgisayarını internete çıkarması gibi). VM internete çıkabilir ama dışarıdan (host dışındaki bir makineden) VM'e doğrudan erişilemez — erişmek istersen host üzerinde "port yönlendirme (port forwarding)" tanımlaman gerekir (bunu Ubuntu-egitim VM'inde SSH için zaten yaptık: host `2222` → VM `22`).
- `Host-only` — VM sadece host ile konuşabilen izole bir ağdadır, internete hiç çıkamaz. Tamamen kapalı, dışarıdan tamamen izole test senaryoları için kullanılır.

Lab için **Bridged** en rahatı — çünkü ayrıca port yönlendirmesi uğraşısı olmadan doğrudan `ssh kullanici@vm-ip` yazabilirsin.

---

## 2. Kurulum: ne seçmeli?

Kurs CentOS 6 kuruyor. Bugün CentOS 6 ve 7 **EOL** (End Of Life — destek ömrü bitti) —
depoları kapalı, güvenlik yaması yok. EOL bir dağıtım kurmak, kilidi kırılmış bir kapıyı
"çalışıyor" diye kullanmaya devam etmek gibidir; bilinen güvenlik açıkları asla
kapatılmaz çünkü üretici artık yama yayınlamıyor.

| Kurs (2016) | Bugünkü karşılığı |
|---|---|
| CentOS 6 / 7 | **Rocky Linux 9** veya **AlmaLinux 9** (RHEL 9 klonu) |
| Ubuntu 14/16 | **Ubuntu Server 24.04 LTS** |
| Debian 7/8 | **Debian 12 (bookworm)** |

### Kurulum sırasında dikkat edilecekler

**1. Software selection / paket seti**

Kurulum sırasında sana "hangi paket grubunu kurayım" diye sorulur (Server with GUI,
Workstation, Minimal Install gibi). Bu seçim, kurulumun sonunda diskte kaç GB yer
kaplayacağını ve kaç servisin arka planda çalışacağını belirler.

- `Minimal Install` seç. GUI kurma. Sunucuda GUI yok, alışkanlığı şimdiden edin.
  **Neden önemli?** Gerçek üretim sunucularının ezici çoğunluğu hiç ekran/masaüstü
  ortamı olmadan, sadece SSH ile yönetilir — GUI hem gereksiz kaynak tüketir hem de
  saldırı yüzeyini (exploit edilebilecek ek yazılım) büyütür. Şimdiden komut satırıyla
  rahat olmazsan, gerçek bir sunucuyla karşılaştığında elin ayağın dolaşır.
- Rocky/Alma: "Minimal Install"
- Debian: tasksel ekranında sadece `SSH server` + `standard system utilities`
- Ubuntu Server: zaten minimal, "Install OpenSSH server" kutusunu işaretle

**2. Disk bölümleme**

Otomatik ("Automatic"/"Guided") de seçebilirsin ama öğrenmek için **manuel** yap —
otomatik seçenek senin yerine karar verir, sen neyin nereye gittiğini görmezsin.
Manuel yaparsan "neden bu boyut, neden bu dosya sistemi" sorularını kendi elinle
cevaplamış olursun.

Basit, öğrenmeye uygun şema (20 GB disk):

| Bölüm | Boyut | Dosya sistemi | Not |
|---|---|---|---|
| `/boot` | 1 GB | xfs / ext4 | UEFI'de ayrıca `/boot/efi` 600 MB, FAT32 |
| `swap` | 2 GB | swap | RAM kadar veya yarısı |
| `/` | Kalan | xfs (RHEL) / ext4 (Debian) | LVM üstünde olsun |

**Bu bölümler neden ayrı ayrı var, tek bir `/` yapsan olmaz mıydı?**
- `/boot` ayrı olur çünkü açılış (boot) aşamasında kernel ve GRUB, henüz karmaşık bir
  dosya sistemi katmanına (LVM gibi) erişemeyebilir; basit, garantili erişilebilir küçük
  bir bölümde tutulur.
- `swap`, RAM dolduğunda kullanılan disk alanıdır (ayrıntısı Modül 09'da) — ayrı bir bölüm
  (veya dosya) olarak var olması gerekir, dosya sisteminin bir parçası değildir.
- `/` (kök), sistemin geri kalan her şeyini barındırır.

Üretimde ayrıca ayrılan dizinler: `/var`, `/var/log`, `/home`, `/tmp`.
**Neden?** Örneğin bir uygulama çıldırıp `/var/log` içine sonsuz log yazmaya başlarsa,
`/var/log` ayrı bir bölümse sadece o bölüm dolar — kök dosya sistemi (`/`) hâlâ boş kalır,
sistem çökmez, SSH ile bağlanıp temizleyebilirsin. Hepsi tek `/` altında olsaydı, disk
tamamen dolar ve sistem açılış dahil hiçbir işlem yapamaz hale gelirdi (bir dosya sistemi
%100 dolduğunda log yazma, geçici dosya oluşturma gibi temel işlemler bile başarısız olur).

> **Dağıtım farkı — varsayılan dosya sistemi**
> - RHEL/Rocky/Alma: **XFS** (küçültülemez! sadece büyütülür)
> - Debian/Ubuntu: **ext4** (hem büyütülür hem küçültülür)
> - Bu fark LVM modülünde canını yakabilir, aklında olsun. Neden önemli: bir LVM biriminde
>   (bölüm gibi düşün) yer fazlalığını geri almak istersen, XFS'te bu **mümkün değildir**
>   — veriyi yedekleyip birimi silip yeniden oluşturmak zorunda kalırsın. ext4'te
>   `resize2fs` ile küçültme mümkündür. Bu yüzden RHEL ailesinde birim boyutunu **baştan**
>   dikkatli seçmek, sonradan büyütmekten çok daha kritiktir.

**3. Hostname ve ağ**

Kurulum ekranında ağ kartını **"Connect automatically"** yap. Bu kutu, kurulumcuya
"bu ağ kartını açılışta otomatik etkinleştir" der. RHEL tabanlılarda bu kutu
işaretlenmezse makine açılır ama ağ kartı **pasif kalır** — VM ayaktadır, `ping` bile
atamazsın, SSH ile hiç bağlanamazsın; klasik acemi tuzağı budur ve "sunucum bozuldu"
sanılan durumların çoğu aslında sadece bu kutunun işaretlenmemiş olmasıdır.

**4. Root parolası + normal kullanıcı**

Root, sistemde her şeyi yapabilen (dosya izinlerini hiçe sayan) tek kullanıcıdır —
"tanrı modu" gibi düşün. Doğrudan root olarak günlük iş yapmak tehlikelidir: bir yazım
hatası (`rm -rf` gibi) tüm sistemi geri dönüşsüz siler. Bu yüzden kurulumda root
parolası koyduktan **sonra** kendine ayrı, sıradan bir kullanıcı hesabı açıp onu
"administrator" (wheel/sudo grubu) yaparsın — günlük işini bu kullanıcıyla yapar,
sadece gerektiğinde `sudo` ile (tek komutluk) root yetkisi ödünç alırsın.
Modül 05'te bunun ne demek olduğunu detaylı işleyeceğiz.

---

## 3. Kurulum sonrası ilk 10 dakika

Kurulum bitti, makineye ilk girdin. Sırasıyla ne yapman gerektiğini ve **neden** o
sırayla yapman gerektiğini açıklayalım.

```bash
# 1. Kim ve nerede olduğunu doğrula
whoami
hostname
cat /etc/os-release          # Dağıtım ve sürüm - her dağıtımda çalışır
uname -r                     # Kernel sürümü
```
Bu dört komut bir "kimlik kontrolü"dür: hangi kullanıcı olarak, hangi makinede,
hangi dağıtım/sürümde, hangi kernel ile çalıştığını doğrular. Uzaktan bir sürü VM
yönettiğinde yanlış makinede komut çalıştırmamak için bu refleks hayat kurtarır.
`/etc/os-release` **her** Linux dağıtımında aynı biçimde bulunur (standarttır) —
bu yüzden "bu hangi dağıtım" sorusunun evrensel cevabı budur, `cat /etc/redhat-release`
gibi dağıtıma özel dosyalara güvenme.

```bash
# 2. Sistemi güncelle
sudo dnf update -y           # RHEL/Rocky/Alma/Fedora
sudo apt update && sudo apt upgrade -y   # Debian/Ubuntu
```
**Neden ilk iş güncelleme?** Kurulum ISO'su, hazırlandığı tarihteki paket sürümlerini
içerir; ISO indirdiğin an ile şu an arasında güvenlik yamaları çıkmış olabilir. Yeni
bir makineyi güncellemeden internete/ağa açmak, bilinen açıkları taşıyan bir kapıyı
açık bırakmaktır. `apt` ailesinde `update` sadece paket **listesini** (depodaki hangi
sürümler var bilgisini) tazeler, gerçek yükseltmeyi yapmaz — bu yüzden `upgrade` ile
birlikte yazılır. `dnf` bu ikisini `update` komutunda birleştirir.

```bash
# 3. Temel araçları kur
sudo dnf install -y vim tar wget curl bash-completion   # RHEL ailesi
sudo apt install -y vim tar wget curl bash-completion   # Debian ailesi
```
Minimal kurulum gerçekten minimaldir — bazen `vim` bile yoktur, sadece kısıtlı `vi`
vardır. Bu paketler günlük işin temel dişlisidir: `vim` düzenleme (Modül 03), `tar`
arşivleme, `wget`/`curl` dosya indirme, `bash-completion` Tab tuşuyla otomatik
tamamlama (yazım hatalarını azaltır, hızlandırır).

```bash
# 4. Saat dilimi
timedatectl                            # Mevcut durum
sudo timedatectl set-timezone Europe/Istanbul
timedatectl list-timezones | grep Ist  # Doğru adı bulmak için
```
**Neden saat dilimi önemli?** Loglardaki zaman damgaları (Modül 13), zamanlanmış
görevlerin (Modül 12) ne zaman çalışacağı, SSL sertifikalarının geçerlilik kontrolü —
hepsi doğru saate bağlıdır. Varsayılan genelde UTC'dir; kendi saatinle log
zamanlarını karşılaştırmak zorlaşır. `timedatectl` tek başına çalıştırıldığında mevcut
saat dilimini, sistem saatini ve senkronizasyon durumunu gösterir — değiştirmeden
önce ne olduğunu görmen için.

```bash
# 5. Hostname
sudo hostnamectl set-hostname rocky1.lab.local
hostnamectl                            # Doğrula
```
Hostname, makinenin ağdaki "adı"dır. Birden fazla sunucuyla çalıştığında (ki
sistem yöneticiliğinde hep öyle olur) terminaldeki prompt'un hangi makinede
olduğunu gösterir (`kullanici@rocky1:~$` gibi) — yanlış sunucuda komut çalıştırma
riskini azaltır. Ayrıca loglarda, monitoring sistemlerinde makineyi ayırt etmenin
tek yoludur.

> `hostnamectl` ve `timedatectl` systemd araçlarıdır. CentOS 6'da **yoktur** —
> orada `/etc/sysconfig/network` düzenlenip yeniden başlatılırdı. Bugün her modern
> dağıtımda bu komutlar var.

---

## 4. İlk ağ ayarı

Detayı Modül 11'de. Burada sadece "makineye SSH ile bağlanabileyim" seviyesi.

### Mevcut durumu gör

```bash
ip a                    # IP adresleri (eski: ifconfig)
ip r                    # Yönlendirme tablosu (eski: route -n)
cat /etc/resolv.conf    # DNS sunucuları
ping -c3 8.8.8.8        # IP seviyesinde internet var mı
ping -c3 google.com     # DNS çalışıyor mu
```

Ağ bağlantısı üç ayrı katmanda çalışır ve her katman ayrı ayrı bozulabilir:
1. **Kendi IP adresin var mı?** (`ip a` ile bak — arayüzün altında `inet 192.168.x.x`
   satırı yoksa henüz IP alamamışsındır.)
2. **Ağ geçidine (gateway/router) giden yolu biliyor musun?** (`ip r` çıktısında
   `default via X` satırı yoksa, IP paketlerini nereye göndereceğini bilmiyorsundur —
   sadece kendi yerel ağınla konuşabilirsin, dışarı çıkamazsın.)
3. **İsim çözümleme (DNS) çalışıyor mu?** (`google.com` gibi bir ismi IP'ye çeviren
   sunucu `/etc/resolv.conf`'ta tanımlı mı, ona erişilebiliyor mu?)

`ping 8.8.8.8` çalışıp `ping google.com` çalışmıyorsa: **sorun DNS'te** — IP seviyesinde
(1. ve 2. katman) her şey yolunda, sadece isim-IP çevirisi bozuk. İkisi de çalışmıyorsa:
sorun IP/gateway'de (1. veya 2. katman). Bu ayrım, sahada ilk refleks olmalı — çünkü
çözümü tamamen farklıdır: biri `/etc/resolv.conf`'a bakmayı gerektirir, diğeri IP/route
ayarına.

### Statik IP verme

> **Dağıtım farkı — burası ailelerin en çok ayrıştığı yer**

Sunucularda IP adresinin genelde **statik** (sabit, hiç değişmeyen) olması istenir —
DHCP ile otomatik alınan IP zaman zaman değişebilir, ve sunucuya SSH ile bağlanan
istemciler, DNS kayıtları, güvenlik duvarı kuralları hep o sabit IP'ye göre
yapılandırılmıştır. IP değişirse hepsi bozulur. Bu yüzden sunucu kurulumunun standart
bir adımı, DHCP ile gelen geçici IP'yi statik bir IP'ye çevirmektir.

**RHEL 9 / Rocky 9 / Alma 9 — NetworkManager (nmcli)**

```bash
nmcli con show                       # Bağlantıları listele
nmcli con mod "ens192" \
  ipv4.addresses 192.168.1.50/24 \
  ipv4.gateway 192.168.1.1 \
  ipv4.dns "192.168.1.1 8.8.8.8" \
  ipv4.method manual
nmcli con up "ens192"                # Uygula
```
`nmcli con mod` komutu **hemen** bir şey değiştirmez — sadece "bağlantı profilini"
günceller (diskteki yapılandırma dosyasını değiştirir). Değişikliğin etkili olması
için son satırdaki `nmcli con up` (veya makineyi yeniden başlatmak) gerekir. Bu iki
aşamalılık aslında bir güvenlik özelliğidir: yanlış yazdığını `up` demeden önce
`nmcli con show "ens192"` ile kontrol edip düzeltme şansın olur.

RHEL 9'da yapılandırma dosyaları `/etc/NetworkManager/system-connections/*.nmconnection`
altındadır. RHEL 8 ve öncesindeki `/etc/sysconfig/network-scripts/ifcfg-*` biçimi
RHEL 9'da **kaldırıldı**.

**Geri almak istersen (DHCP'ye dönmek):**
```bash
nmcli con mod "ens192" ipv4.method auto
nmcli con up "ens192"
```

**CentOS 6/7 — ifcfg dosyası (kursun anlattığı yöntem)**

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

**Ubuntu 18.04+ — netplan**

Netplan, alttaki NetworkManager veya systemd-networkd'yi konfigüre eden **basit bir
YAML katmanı**dır — sen karmaşık ayrıntılarla uğraşmazsın, netplan senin YAML'ini alıp
alttaki sisteme çevirir.

```bash
sudo vi /etc/netplan/01-netcfg.yaml
```
```yaml
network:
  version: 2
  ethernets:
    ens18:
      addresses: [192.168.1.50/24]
      routes:
        - to: default
          via: 192.168.1.1
      nameservers:
        addresses: [192.168.1.1, 8.8.8.8]
```
```bash
sudo netplan try     # 120 sn sonra geri alır — uzaktayken bunu kullan!
sudo netplan apply
```
**`netplan try` neden var?** Uzak bir sunucuda ağ ayarını değiştirirken, yanlış bir IP
veya gateway yazarsan SSH bağlantın anında kopar — ve genelde fiziksel erişimin yoksa
sunucuya bir daha asla giremezsin ("kendi ayağına sıkmak" tabir edilen bu durum sahada
sık yaşanır). `netplan try` yeni ayarı **uygular ama 120 saniye içinde onaylamazsan
(Enter'a basmazsan) otomatik olarak eski haline geri döner.** Bağlantın koptuysa zaten
onay veremezsin, 120 saniye sonra ayar kendiliğinden düzelir ve tekrar bağlanabilirsin.
`netplan apply` ise böyle bir güvenlik ağı sunmaz, kalıcı ve anında uygular.

> YAML **girinti hassastır**, tab kullanma, boşluk kullan.

**Debian 12 — /etc/network/interfaces**

```bash
sudo vi /etc/network/interfaces
```
```ini
auto ens18
iface ens18 inet static
    address 192.168.1.50/24
    gateway 192.168.1.1
```
```bash
sudo systemctl restart networking
```

### Arayüz isimleri neden `eth0` değil?

Modern dağıtımlarda systemd "predictable network interface names" (öngörülebilir ağ
arayüzü adları) kullanır: `ens192`, `enp0s3`, `eno1`. **Sebep:** eski `eth0`/`eth1`
adlandırması, kernel'in ağ kartlarını **algılama sırasına** göre veriliyordu — bu sıra
her açılışta garanti değildi, özellikle birden fazla ağ kartı olan sunucularda bir gün
`eth0` olan kart ertesi gün `eth1` olabiliyordu. Statik IP verdiğin kart değişirse,
yanlış karta IP atanmış olur, sunucu ağdan düşer. Yeni isimlendirme donanımın **fiziksel
konumundan** (hangi PCI yuvasında, hangi anakart üzerinde) türetilir — bu konum
değişmediği sürece isim de değişmez, garantilidir.

- `en` = ethernet, `wl` = wlan
- `p0s3` = PCI bus 0, slot 3
- `o1` = onboard 1

Eski isme dönmek istersen (genelde gerekmez) GRUB'a `net.ifnames=0 biosdevname=0` eklenir.

---

## 5. SSH ile bağlan

**SSH nedir, neden var?** SSH (Secure Shell), bir makineye **ağ üzerinden**, şifrelenmiş
bir kanaldan, uzaktan komut satırı erişimi sağlayan protokoldür. Sunucuların büyük
çoğunluğu fiziksel olarak elinin altında değildir (veri merkezinde, bulutta); SSH,
o makineye sanki önündeymişsin gibi komut çalıştırma imkanı verir. Şifrelenmemiş
eski protokoller (telnet gibi) parolanı açık metin olarak ağdan geçirirdi — biri
trafiği dinlerse parolanı çalardı. SSH tüm trafiği şifreler.

```bash
# Sunucuda servis çalışıyor mu
sudo systemctl status sshd     # RHEL ailesi
sudo systemctl status ssh      # Debian ailesi  ← servis adı farklı!

sudo systemctl enable --now sshd

# İstemciden
ssh kullanici@192.168.1.50
```
`systemctl enable --now sshd` iki şeyi birden yapar: `enable` servisi **her açılışta
otomatik başlat** olarak işaretler (kalıcı), `--now` ise **şu an hemen başlat** der
(anlık). Sadece `start` yazsaydın servis şimdi çalışırdı ama reboot'ta tekrar kapalı
gelirdi; sadece `enable` yazsaydın açılışta otomatik gelirdi ama şimdi çalışmazdı.

Bağlanamıyorsan sırayla kontrol:
1. `ping 192.168.1.50` — ağ var mı? (Yoksa katman 1 sorunu, yukarıdaki ağ bölümüne dön.)
2. `ss -tlnp | grep :22` — sunucuda 22 dinleniyor mu? (SSH servisi 22 numaralı porttan
   bağlantı bekler; bu port "dinliyor (LISTEN)" görünmüyorsa servis çalışmıyordur ya da
   farklı bir portta yapılandırılmıştır.)
3. Güvenlik duvarı:
   ```bash
   sudo firewall-cmd --list-all              # RHEL ailesi
   sudo firewall-cmd --permanent --add-service=ssh && sudo firewall-cmd --reload
   sudo ufw status && sudo ufw allow ssh     # Ubuntu
   ```
   **Güvenlik duvarı neden ayrı bir kontrol maddesi?** SSH servisi çalışıyor ve 22
   portu dinliyor olsa bile, işletim sisteminin güvenlik duvarı o porta gelen trafiği
   **daha ağ katmanında** reddedebilir — servise hiç ulaşmadan paket düşürülür. Bu
   yüzden "servis çalışıyor" ile "servise dışarıdan erişilebiliyor" iki ayrı şeydir.

> **Dağıtım farkı — güvenlik duvarı**
> - RHEL ailesi: `firewalld` (varsayılan aktif, çoğu port kapalı)
> - Ubuntu: `ufw` (varsayılan **kapalı/inactive** — açık gelir)
> - Debian: hiçbiri kurulu değil, çıplak `nftables`
> - Hepsinin altında **nftables** (eski sistemlerde iptables) var. `firewalld` ve `ufw`,
>   nftables kurallarını senin yerine, daha kolay komutlarla yöneten "ön yüzlerdir" —
>   ikisi de aslında aynı çekirdek mekanizmasını (netfilter) kontrol eder.

### SSH anahtarı ile giriş (parolasız)

Parola ile giriş iki zayıflık taşır: biri parolayı tahmin edebilir (brute-force) veya
sunucudan sızdırılabilir (bir parola tüm sunucularda aynıysa, biri sızarsa hepsi risk
altında). SSH anahtarı, bunun yerine **matematiksel bir anahtar çifti** kullanır:
gizli tutulan bir **özel anahtar (private key)** senin bilgisayarında kalır, eşleşen
**genel anahtar (public key)** ise bağlanacağın sunucuya kopyalanır. Sunucu, sana bir
"bunu özel anahtarınla imzala" bulmacası sorar; sadece gerçek özel anahtara sahip olan
bunu doğru cevaplayabilir — parola hiç ağdan geçmez, hiç tahmin edilebilir olmaz.

```bash
# İstemcide (bir kere)
ssh-keygen -t ed25519 -C "notum"
ssh-copy-id kullanici@192.168.1.50
ssh kullanici@192.168.1.50    # artık parola sormaz
```
`ssh-keygen` özel/genel anahtar çiftini üretir (özel anahtar `~/.ssh/id_ed25519`, genel
anahtar `~/.ssh/id_ed25519.pub` olarak diske yazılır — özel anahtarı **asla** kimseyle
paylaşma). `ssh-copy-id` genel anahtarını otomatik olarak sunucudaki
`~/.ssh/authorized_keys` dosyasına ekler — bu dosya, sunucunun "bu genel anahtarlara
sahip olanları tanıyorum, sorgusuz içeri al" listesidir.

**Geri almak istersen (anahtarı iptal etmek):** Sunucudaki `~/.ssh/authorized_keys`
dosyasını aç, ilgili satırı sil. O anahtarla giriş artık kabul edilmez, parola girişi
(hâlâ açıksa) yerine geçer.

---

## 🧪 Lab

1. Rocky Linux 9 ve Debian 12'yi ayrı VM'lere **minimal** kur. İkisine de 2. disk ekle.
2. Her ikisinde de:
   - hostname'i `rocky1` / `deb1` yap
   - saat dilimini `Europe/Istanbul` yap
   - statik IP ver (ailesine uygun yöntemle)
   - SSH ile ana makinenden bağlan
3. Rocky'de `ip a` çıktısındaki arayüz adını not al, Debian'dakiyle karşılaştır.
4. Rocky'de firewalld'yi kapatmadan SSH'ı aç. Ubuntu/Debian'da ufw'yi aktif et ve SSH'a izin ver.
5. Her iki VM'in de **snapshot**'ını al, adını `temiz-kurulum` koy.

---

## ❓ Kendini test et

**S1.** `ping 8.8.8.8` çalışıyor ama `ping google.com` "Name or service not known" veriyor. Nerede sorun var?

<details><summary>Cevap</summary>
DNS'te. IP katmanı (route + gateway) sağlam, isim çözümleme bozuk.
`/etc/resolv.conf` içeriğini ve DNS sunucusuna erişimi (`dig @8.8.8.8 google.com`) kontrol et.
</details>

**S2.** RHEL 9'da `/etc/sysconfig/network-scripts/` dizini boş. Neden?

<details><summary>Cevap</summary>
RHEL 9 ifcfg biçimini kaldırdı. Yapılandırma artık
`/etc/NetworkManager/system-connections/*.nmconnection` altında, `nmcli` ile yönetiliyor.
</details>

**S3.** Uzak bir sunucuda ağ ayarını değiştireceksin, hata yaparsan bağlantın kopacak. Ubuntu'da hangi komut seni kurtarır?

<details><summary>Cevap</summary>
`sudo netplan try` — yapılandırmayı uygular, 120 saniye içinde onaylamazsan eski haline döner.
Onaylayamazsan (bağlantın zaten koptuğu için) 120 saniye sonra otomatik eski hâle döner ve
tekrar bağlanabilirsin.
</details>

**S4.** XFS ve ext4 arasındaki, ileride canını yakacak temel fark nedir?

<details><summary>Cevap</summary>
XFS **küçültülemez**, sadece büyütülebilir. ext4 hem büyütülür hem küçültülür.
LVM'de yanlış boyut verdiysen XFS'te geri dönüş yok, yedekten yeniden kurmak gerekir.
</details>

**S5.** SSH servisi çalışıyor, `ss -tlnp` 22 portunun dinlendiğini gösteriyor, ama yine de dışarıdan bağlanamıyorsun. Sırada ne kontrol edersin?

<details><summary>Cevap</summary>
Güvenlik duvarı (firewalld/ufw/nftables). Servis çalışıp portu dinlese bile, işletim
sistemi seviyesindeki güvenlik duvarı o porta gelen trafiği paket seviyesinde
reddedebilir — servise hiç ulaşmadan bağlantı düşer.
</details>

---

## 📋 Hızlı referans

```bash
cat /etc/os-release            # Dağıtım tespiti (evrensel)
uname -r                       # Kernel sürümü
hostnamectl set-hostname X     # Hostname
timedatectl set-timezone X     # Saat dilimi
ip a / ip r                    # Adres ve rota
nmcli con show                 # RHEL ağ bağlantıları
netplan try / netplan apply    # Ubuntu ağ ayarı (try = güvenli, geri alınabilir)
systemctl status sshd|ssh      # SSH servisi (ad dağıtıma göre değişir)
ssh-keygen -t ed25519 ; ssh-copy-id kullanici@ip   # Parolasız SSH girişi
```
