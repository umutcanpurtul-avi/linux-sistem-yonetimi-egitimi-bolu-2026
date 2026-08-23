---
tags: [linux, egitim, boot, grub, systemd]
modul: 14
durum: tamamlandi
---

# 14 — Sistem Açılışı ve GRUB Önyükleyici

> **Ön koşul:** [08-surec-yonetimi](08-surec-yonetimi.md), [09-disk-yonetimi](09-disk-yonetimi.md)
> **Süre:** ~3 saat
> ⚠️ Bu modülde sistemi açılamaz hale getirmek mümkündür. **Önce snapshot al.**

## Hedefler

- [ ] Açılış zincirini baştan sona anlatabiliyorum
- [ ] BIOS/MBR ile UEFI/GPT farkını biliyorum
- [ ] GRUB2 yapılandırmasını doğru dosyadan değiştirebiliyorum
- [ ] systemd target'larını yönetebiliyorum (runlevel karşılığı)
- [ ] Root parolasını sıfırlayabiliyorum
- [ ] Açılmayan bir sistemi teşhis edebiliyorum

---

## 1. Açılış zinciri

```
1. Güç → Firmware (BIOS veya UEFI)
        │  POST, donanım başlatma, önyükleme aygıtı seçimi
        ▼
2. Önyükleyici (GRUB2)
        │  kernel + initramfs'i RAM'e yükler, parametreleri geçirir
        ▼
3. Kernel
        │  donanımı başlatır, initramfs'i geçici kök olarak bağlar
        ▼
4. initramfs
        │  disk/RAID/LVM/LUKS sürücülerini yükler, GERÇEK kökü bulur
        │  switch_root ile gerçek köke geçer
        ▼
5. PID 1 = systemd
        │  target'lara göre unit'leri paralel başlatır
        ▼
6. multi-user.target / graphical.target  → giriş ekranı
```

### GRUB'ın rolü tam olarak nedir?

GRUB (**GR**and **U**nified **B**ootloader), firmware (BIOS/UEFI) ile Linux kernel'i arasında
duran bir "yönlendirici"dir. Firmware sadece "diskten/ESP'den bir kod parçası bul ve çalıştır"
diyecek kadar basit bir iştir; GRUB ise şunları yapar:

- Diskte hangi kernel'lerin kurulu olduğunu bilir ve sana **seçmen için bir menü** sunar
  (birden fazla kernel sürümü kuruluysa, ya da başka bir işletim sistemi de varsa).
- Seçilen kernel dosyasını ve ona eşlik eden **initramfs** dosyasını diskten okuyup **RAM'e**
  yükler (bu noktada henüz hiçbir dosya sistemi "normal" şekilde bağlı değildir — GRUB kendi
  başına disk okuma yeteneğine sahiptir).
- Kernel'e açılış parametrelerini (`kernel command line` — `ro`, `quiet`, `rd.break` gibi)
  geçirir ve kontrolü kernel'e devreder.

GRUB'ın kendisi bir işletim sistemi değildir, sadece **"kernel'i doğru parametrelerle RAM'e
koyup çalıştıran bir başlatıcı"**dır — bu yüzden `single`, `init=/bin/bash` gibi parametreleri
GRUB menüsünde anlık olarak değiştirebilmen, aşağıdaki parola kurtarma senaryolarının temelini
oluşturur.

### initramfs neden gerekli? — "tavuk mu yumurtadan çıkar, yumurta mı tavuktan" problemi

Bu, en çok kafa karıştıran konulardan biridir; adım adım kuralım:

1. Kernel çalışmaya başladığında, gerçek kök dosya sistemine (`/`) erişmesi gerekir —
   çünkü kullanıcı programları, kütüphaneler, yapılandırma dosyaları hep oradadır.
2. Ama gerçek kök dosya sistemi genelde bir diskte durur, ve o diske erişebilmek için
   kernel'in **doğru disk sürücüsüne** (SATA denetleyici, NVMe, RAID kartı, hatta bazen
   LVM ya da şifreleme katmanı gibi yazılımsal katmanlara) ihtiyacı vardır.
3. İşte tam burada tavuk-yumurta problemi ortaya çıkar: **o disk sürücüsü genelde kök dosya
   sisteminin İÇİNDE bulunur** (`/lib/modules/...` altında). Yani kök dosya sistemine
   erişmek için sürücüye ihtiyacın var, ama sürücüye erişmek için önce kök dosya sistemine
   erişmen gerekiyor. Bu döngüyü kırmadan sistem hiç açılamaz.

**Çözüm — initramfs:** GRUB, gerçek kök dosya sistemini hiç bağlamadan önce, RAM içine
**küçük, geçici bir dosya sistemi** (initramfs — "initial RAM filesystem") yükler. Bu geçici
dosya sistemi, sadece gerçek kökü açmak için gereken minimum şeyi içerir: disk sürücüleri,
RAID/LVM/LUKS araçları ve küçük bir başlatma betiği. Kernel önce bu **geçici** kökle çalışır,
gerekli sürücüleri yükler, artık gerçek diski görebilir hale gelir, gerçek kökü bulup bağlar
ve `switch_root` ile **kalıcı olarak** geçici RAM kökünden gerçek diske "atlar". Bu noktadan
sonra systemd (PID 1) devreye girer ve normal açılış sürer.

> **Somut sonuç — initramfs'i ne zaman yeniden oluşturman gerekir:** Disk denetleyicisi
> değiştirdiğinde (donanım değişikliği), LVM/RAID/LUKS yapılandırmasını değiştirdiğinde, ya da
> kernel'i güncellediğinde initramfs de güncel olmalıdır — çünkü içindeki sürücü listesi eski
> donanıma göre kalmışsa, kernel gerçek kökü bulamaz ve **"unable to mount root fs"** hatasıyla
> panic olur (aşağıdaki "Yaygın senaryolar" bölümünde C maddesi tam bunu anlatıyor).
> Bu yüzden `dracut -f` (RHEL) veya `update-initramfs -u` (Debian) komutları, disk/depolama
> ile ilgili her değişiklikten sonra çalıştırman gereken komutlardır.

### BIOS/MBR vs UEFI/GPT

**Bunlar ne, neden var, aralarındaki fark nedir?**

Bilgisayarı açtığında, işletim sistemi henüz belleğe yüklenmeden önce **birinin** diski
bulup "buradan başla" demesi gerekir. Bu ilk adımı atan şey işletim sistemi değil,
anakartın üzerindeki **firmware**'dir (donanıma gömülü, en temel yazılım). Bu firmware
iki türden biridir:

- **BIOS** (eski, 1980'lerden kalma standart): Diskin en başındaki 512 baytlık küçük bir
  alana (**MBR — Master Boot Record**) bakar, orada bulduğu küçük kod parçasını çalıştırır.
  Bu alan o kadar küçüktür ki (512 bayt!) GRUB'ın tamamı oraya sığmaz — sadece "GRUB'ın geri
  kalanını diskin başka bir yerinden yükle" diyen minik bir başlatıcı sığar. MBR ile bölümlenmiş
  bir diskte en fazla 4 birincil bölüm olabilir ve disk en fazla 2 TB olabilir (adresleme
  sınırı yüzünden) — bugünün standartlarında ciddi bir kısıtlama.
- **UEFI** (modern standart): BIOS'un yerini almak üzere tasarlanmış, çok daha yetenekli bir
  firmware'dir. Kendi başına bir dosya sistemini (FAT32) okuyabilir ve GRUB'ı doğrudan normal
  bir dosya (`grubx64.efi`) olarak, **ESP** (EFI System Partition, genelde `/boot/efi` altına
  bağlanır) adı verilen özel bir bölümden çalıştırır. 2 TB sınırı yoktur, 128 bölüme kadar
  destekler (GPT bölüm tablosuyla), ayrıca **Secure Boot** gibi imzasız/kötü amaçlı önyükleyicileri
  engelleyen bir güvenlik katmanı sunar.

**Neden bu fark seni ilgilendiriyor — gerçek bir olay üzerinden:**
Bir sanal makineye (VirtualBox) minimal bir Rocky Linux ISO'su ile otomatik kurulum başlatıldığında,
VM'in firmware ayarı **BIOS** olarak bırakılmıştı. Kurulum aracı ISO'yu incelediğinde bu ISO'nun
sadece **UEFI için** hazırlanmış önyükleme dosyaları içerdiğini (`/EFI/BOOT/grub.cfg`) tespit
etti — yani ISO'da BIOS/MBR ile uyumlu bir önyükleme kodu yoktu. Sonuç: VM, BIOS modunda
CD-ROM'dan önyüklemeye çalıştı, ekrana **hiçbir şey basamadan** (tamamen siyah ekran, yanıp
sönen bir imleçten başka hiçbir şey yok) sonsuza dek bekledi — CPU biraz kullanılıyordu ama
hiçbir ilerleme yoktu, çünkü firmware'in anladığı yöntemle bir önyükleyici bulamıyordu.
**Çözüm:** VM kapatılıp firmware ayarı BIOS'tan **EFI**'ye çevrildi, aynı ISO ile tekrar
başlatıldığında kurulum sorunsuz ilerledi. Ders: **"kurulum ekranı hiç açılmıyor / siyah ekranda
takılı kalıyor" şikâyetinin çok yaygın bir sebebi, ISO'nun beklediği önyükleme türü (BIOS/UEFI)
ile VM'in/makinenin firmware ayarının uyuşmamasıdır.** Fiziksel bir makinede de aynı sorunla
karşılaşabilirsin: BIOS ayarlarından "Boot Mode: UEFI / Legacy" seçeneğini kontrol etmen gerekir.

| | BIOS + MBR | UEFI + GPT |
|---|---|---|
| Önyükleyici konumu | MBR (ilk 512 bayt) + boot bölümü | **ESP** — `/boot/efi`, FAT32 |
| Disk sınırı | 2 TB | Pratikte sınırsız |
| Secure Boot | ❌ | ✅ |
| GRUB kurulumu | `grub2-install /dev/sda` | `grub2-install` genelde gerekmez |
| Kontrol | | `ls /sys/firmware/efi` varsa UEFI |

```bash
[ -d /sys/firmware/efi ] && echo "UEFI" || echo "BIOS"
sudo efibootmgr -v                # UEFI önyükleme girdileri
lsblk -f | grep -i efi
```

> **VirtualBox'ta pratik kural:** Yeni bir VM oluştururken Ayarlar → Sistem → Anakart
> sekmesinde "EFI'yi Etkinleştir (özel işletim sistemleri)" kutusunu işaretlersen VM UEFI ile,
> işaretlemezsen BIOS ile açılır. Modern bir dağıtım (Rocky 9/10, Ubuntu 22.04+, Fedora) kuracaksan
> bu kutuyu **kurulumdan önce** işaretlemek, yukarıdaki gibi bir "siyah ekranda takılı kalma"
> sorununu baştan önler.

---

## 2. SysV-init, Upstart, systemd

> Kurs **SysV-init** anlatıyor (CentOS 6). RHEL 7+, Debian 8+, Ubuntu 15.04+
> hepsi **systemd** kullanır. İkisini de tanı, ama systemd'yi öğren.

| | SysV-init (CentOS 6) | systemd (bugün) |
|---|---|---|
| PID 1 | `/sbin/init` | `/usr/lib/systemd/systemd` |
| Başlatma | Betikler, **sırayla** | Unit'ler, **paralel** ⭐ |
| Betik konumu | `/etc/init.d/` | `/usr/lib/systemd/system/`, `/etc/systemd/system/` |
| Seviye kavramı | runlevel (0-6) | target |
| Servis başlat | `service X start` | `systemctl start X` |
| Açılışta başlat | `chkconfig X on` | `systemctl enable X` |
| Log | metin dosyaları | journald |
| Bağımlılık | numaralı sıra (S10, S20…) | `After=`, `Requires=`, `Wants=` |

### Runlevel → target karşılıkları

| Runlevel | systemd target | Anlamı |
|---|---|---|
| 0 | `poweroff.target` | Kapat |
| 1 / S | `rescue.target` | Tek kullanıcı, kurtarma |
| 2, 3, 4 | `multi-user.target` | ⭐ Çok kullanıcı, ağ, GUI yok |
| 5 | `graphical.target` | GUI ile |
| 6 | `reboot.target` | Yeniden başlat |
| — | `emergency.target` | En minimal — sadece kök FS (salt okunur) |

```bash
systemctl get-default                          # varsayılan target
sudo systemctl set-default multi-user.target   # GUI'yi kapat ⭐ sunucuda yap
sudo systemctl isolate multi-user.target       # ŞİMDİ geç (runlevel komutu gibi)
systemctl list-units --type=target
systemctl list-dependencies graphical.target
runlevel                                       # eski komut, hâlâ çalışır
```

---

## 3. GRUB2 yapılandırması

> 🔥 **En kritik kural: `/boot/grub2/grub.cfg` dosyasını ELLE DÜZENLEME.**
> O dosya üretilir; her kernel güncellemesinde yeniden yazılır, değişikliklerin gider.
> Doğru yer `/etc/default/grub` ve `/etc/grub.d/`'dir.

### `/etc/default/grub`

```bash
sudo cp /etc/default/grub /etc/default/grub.bak
sudo vi /etc/default/grub
```
```ini
GRUB_TIMEOUT=5                       # menü bekleme süresi (saniye)
GRUB_TIMEOUT_STYLE=menu              # menu | hidden | countdown
GRUB_DEFAULT=saved                   # son seçileni hatırla (veya 0, 1, 2...)
GRUB_DISABLE_SUBMENU=true            # eski kernel'leri alt menüye koyma
GRUB_TERMINAL_OUTPUT="console"
GRUB_CMDLINE_LINUX="rhgb quiet"      # ⭐ kernel parametreleri
GRUB_DISABLE_RECOVERY="false"        # kurtarma girdisi göster
```

`rhgb quiet` kaldırılırsa açılış mesajları görünür — **sorun teşhisinde faydalıdır**.

### Yapılandırmayı yeniden üret

> **Dağıtım farkı — komut ve dosya yolu farklı:**

```bash
# RHEL / Rocky / Alma
sudo grub2-mkconfig -o /boot/grub2/grub.cfg              # BIOS
sudo grub2-mkconfig -o /boot/efi/EFI/rocky/grub.cfg      # UEFI (dizin adı dağıtıma göre)
# RHEL 9'da tek komut yeterli:
sudo grub2-mkconfig -o /etc/grub2.cfg                    # symlink doğru yeri gösterir

# Debian / Ubuntu
sudo update-grub                                          # ⭐ kısayol
sudo grub-mkconfig -o /boot/grub/grub.cfg                # aynısı
```

| | RHEL ailesi | Debian ailesi |
|---|---|---|
| Komut | `grub2-mkconfig` | `grub-mkconfig` / `update-grub` |
| Config | `/boot/grub2/grub.cfg` | `/boot/grub/grub.cfg` |
| Kurulum | `grub2-install` | `grub-install` |
| Kernel parametre aracı | `grubby` ⭐ | — |

### `grubby` — RHEL'in kolay yolu

```bash
sudo grubby --info=ALL                                     # tüm girdiler
sudo grubby --default-kernel                               # varsayılan kernel
sudo grubby --update-kernel=ALL --args="audit=0"           # parametre ekle
sudo grubby --update-kernel=ALL --remove-args="quiet rhgb" # parametre çıkar
sudo grubby --set-default /boot/vmlinuz-5.14.0-...
```
`grub2-mkconfig` çalıştırmana gerek kalmaz.

### Kernel yönetimi

```bash
uname -r                              # çalışan kernel
rpm -qa kernel                        # kurulu kernel'ler (RHEL)
dpkg -l | grep linux-image            # (Debian)

sudo dnf remove kernel-5.14.0-100.el9.x86_64     # eski kernel sil
sudo apt autoremove --purge

# Kaç kernel saklansın
# RHEL:   /etc/dnf/dnf.conf → installonly_limit=3
# Debian: /etc/apt/apt.conf.d/01autoremove-kernels
```
> `/boot` bölümü küçük (genelde 1 GB) ve kernel'ler birikir. "No space left on
> /boot" hatası aldığında eski kernel'leri temizle. Güncelleme başarısızlıklarının
> yaygın sebeplerinden biridir.

### GRUB'a parola koyma

```bash
grub2-setpassword                     # RHEL — kolay yol
```
Debian'da `/etc/grub.d/40_custom` içine `grub-mkpasswd-pbkdf2` çıktısıyla eklenir.
Fiziksel erişimi olan birinin `init=/bin/bash` ile parolasız root olmasını engeller.

---

## 4. Kernel parametreleri (açılışta geçici)

GRUB menüsünde bir girdinin üzerindeyken **`e`** tuşuna bas, `linux` satırının sonuna
parametre ekle, **`Ctrl+X`** ile başlat. Bu **kalıcı değildir** — bir sonraki açılışta
eski haline döner. Teşhis için ideal.

| Parametre | Etki |
|---|---|
| `single` / `1` / `rescue.target` | Tek kullanıcı modu |
| `systemd.unit=emergency.target` | Minimal kurtarma |
| `rd.break` | initramfs aşamasında dur (RHEL parola sıfırlama) ⭐ |
| `init=/bin/bash` | systemd yerine doğrudan kabuk ⭐ |
| `nomodeset` | Ekran kartı sürücüsünü devre dışı bırak (siyah ekran çözümü) |
| `selinux=0` | SELinux'u kapat |
| `ro` / `rw` | Kökü salt okunur / yazılabilir bağla |
| `net.ifnames=0` | Eski arayüz isimleri (`eth0`) |
| `mem=2G` | Bellek sınırla (test) |

```bash
cat /proc/cmdline        # ⭐ mevcut açılışın parametreleri
```

---

## 5. Root parolası sıfırlama

> Sadece **fiziksel/konsol erişimin** olduğunda mümkündür. Bu, aynı zamanda neden
> sunucu odalarının kilitli olduğunun ve GRUB parolasının neden konduğunun cevabıdır.

### RHEL 8/9 / Rocky / Alma (SELinux'lu — `rd.break` yöntemi)

**Neden bu yöntem işe yarıyor — mantığını anla:** Root parolasını unuttuğunda normal yoldan
(login ekranından) sisteme giremezsin, ama fiziksel/konsol erişimin varsa GRUB üzerinden
kernel'e "normal açılışı tamamlama, initramfs aşamasında dur" diyebilirsin. O an henüz
systemd, kullanıcı girişi, parola kontrolü gibi hiçbir şey **çalışmamış** olur — çünkü
`rd.break` ile initramfs, gerçek kökü bağlamadan hemen önce seni bir kabuğa düşürür. O anda
diskteki gerçek dosya sistemine (henüz "gerçek" anlamda bağlı olmasa da) `chroot` ile girip
`passwd` komutuyla parolayı doğrudan değiştirebilirsin — hiçbir kimlik doğrulaması istemez,
çünkü zaten sistemin "içindesindir", parola kontrolü mekanizması henüz devrede değildir.
Bu da neden fiziksel erişimin bu kadar kritik bir güvenlik sınırı olduğunu gösterir: konsola
elini sürebilen biri, parola bilmeden root olabilir (bu yüzden GRUB'a parola koymak — bu
modülün ilerleyen kısmında anlatılıyor — bu riski azaltır).

1. Yeniden başlat, GRUB menüsünde **`e`** (düzenleme moduna gir — bu, o açılışa özel geçici
   bir değişikliktir, kalıcı bir dosyayı değiştirmezsin)
2. `linux` satırının sonuna: `rd.break enforcing=0`
   - `rd.break` → initramfs aşamasının sonunda, gerçek kökü bağlamadan **hemen önce** dur.
   - `enforcing=0` → SELinux'u bu açılış için pasif moda al (aksi halde birazdan yapacağın
     `passwd` işlemi SELinux tarafından engellenebilir).
3. **`Ctrl+X`** (bu parametrelerle önyüklemeyi başlat)
4. `switch_root:/#` isteminde — burada olman, initramfs'in geçici kabuğunda olduğun anlamına
   gelir, henüz gerçek disk **sadece salt-okunur** olarak `/sysroot` altında bağlıdır:

```bash
mount -o remount,rw /sysroot   # gerçek diski yazılabilir yap — passwd yazacağı için şart
chroot /sysroot                 # "sanki gerçek sistemdeymişsin gibi" o dosya sistemine geç
passwd root                     # artık normal passwd komutu, gerçek /etc/shadow'u değiştirir
touch /.autorelabel          # ⭐ SELinux etiketlerini yenile
exit                             # chroot'tan çık
exit                             # initramfs kabuğundan çık → normal açılışa devam eder
```
> `/.autorelabel` unutulursa sistem SELinux etiket uyuşmazlığı yüzünden açılmaz
> veya giriş kabul etmez. Bu dosya sayesinde ilk açılışta tüm FS yeniden etiketlenir
> (uzun sürer, sabırlı ol).
> Alternatif: `enforcing=0` ile açıp `restorecon -v /etc/shadow` çalıştırmak.

### Debian / Ubuntu (`init=/bin/bash` yöntemi)

**Mantığı:** Bu sefer initramfs aşamasında değil, gerçek kök zaten bağlandıktan **hemen sonra,
ama systemd (PID 1) başlamadan önce** araya giriyorsun. Normalde kernel açılışın sonunda
`/sbin/init`'i (yani systemd'yi) çalıştırır ve o da login ekranını, parola kontrolünü vs.
başlatır. `init=/bin/bash` diyerek kernel'e "systemd'yi değil, doğrudan bir kabuk çalıştır"
dersin — hiçbir servis, hiçbir giriş kontrolü devreye girmeden, doğrudan root yetkili bir
kabukla karşılaşırsın.

1. GRUB menüsünde **`e`**
2. `linux` satırında `ro` → `rw` yap (kök salt-okunur bağlanıyor normalde; `passwd` yazacağı
   için yazılabilir olması şart), sonuna `init=/bin/bash` ekle (systemd yerine çıplak bir kabuk
   başlat)
3. **`Ctrl+X`**
4. Kabukta:

```bash
mount -o remount,rw /   # (2. adımda ro→rw yapılmadıysa burada da yapılabilir, çift güvence)
passwd root              # /etc/shadow'u doğrudan değiştirir, kimlik doğrulaması istemez
mount -o remount,ro /    # işin bitince köke saygılı davran, salt-okunura geri al
exec /sbin/init          # şimdi systemd'yi normal şekilde başlat, açılış kaldığı yerden sürsün
                          # (veya: reboot -f ile temiz bir yeniden başlatma tercih edebilirsin)
```

> **İki yöntem neden farklı?** RHEL ailesi initramfs aşamasında (`rd.break`) durmayı tercih
> eder çünkü SELinux etiketleme gibi ekstra adımlar initramfs'te daha güvenli yönetilir.
> Debian ailesinde SELinux öntanımlı olmadığı için doğrudan gerçek kökte, systemd'den önce
> durmak yeterlidir. İkisi de aynı temel fikri kullanır: **parola kontrolü devreye girmeden
> önce bir kabuğa düş, dosyayı elle değiştir.**

### CentOS 6 (kursun anlattığı — SysV)

GRUB menüsünde `a` → satırın sonuna `single` → Enter → `passwd root`

---

## 6. Açılış sorunları teşhisi

### Teşhis araçları

```bash
systemd-analyze                       # toplam açılış süresi
systemd-analyze blame                 # ⭐ hangi servis ne kadar sürdü
systemd-analyze critical-chain        # kritik yol
systemd-analyze plot > acilis.svg     # görsel zaman çizelgesi

journalctl -b                         # bu açılış
journalctl -b -1 -p err               # ⭐ ÖNCEKİ açılışın hataları (çökme analizi)
journalctl -b -p err                  # bu açılışın hataları
systemctl --failed                    # ⭐ arızalı servisler
systemctl list-jobs                   # takılı işler
dmesg -T | less                       # kernel mesajları
```

### Yaygın senaryolar

**A) Emergency mode'a düşüyor — "Failed to mount"**

Sebep neredeyse her zaman **bozuk `/etc/fstab`**.
```bash
journalctl -xb | grep -i mount
mount -o remount,rw /
vi /etc/fstab                # hatalı satırı yorum satırı yap veya nofail ekle
mount -a                     # test et
systemctl reboot
```
> **Önleme:** Her fstab değişikliğinden sonra reboot etmeden `mount -a` çalıştır
> ve `nofail` seçeneğini kullan (Modül 09).

**B) GRUB menüsü gelmiyor / "no such partition"**

Kurtarma ISO'su ile başlat, `chroot` yap, GRUB'u yeniden kur:
```bash
# Kurtarma ortamında
mount /dev/vgsystem/lv_root /mnt
mount /dev/sda1 /mnt/boot
mount /dev/sda2 /mnt/boot/efi        # UEFI ise
for d in dev proc sys run; do mount --bind /$d /mnt/$d; done
chroot /mnt

grub2-install /dev/sda               # BIOS (RHEL)
grub2-mkconfig -o /boot/grub2/grub.cfg
# veya Debian:
grub-install /dev/sda && update-grub

exit
reboot
```

**C) Kernel panic — "unable to mount root fs"**

initramfs bozuk veya kök aygıt bulunamıyor. Eski kernel ile açıl (GRUB menüsünden),
sonra:
```bash
sudo dracut -f --regenerate-all       # RHEL
sudo update-initramfs -u -k all       # Debian
sudo grub2-mkconfig -o /boot/grub2/grub.cfg
```

**D) Bir servis açılışı bloke ediyor**

```bash
systemd-analyze blame | head
systemctl --failed
journalctl -u sorunlu.service -b
sudo systemctl disable sorunlu.service
```

**E) Disk dolu — açılamıyor**

`emergency.target`'a düşer. `df -h`, `journalctl --vacuum-size=100M`, eski kernel temizliği.

### Kurtarma sırası — hangi hedefe düşeceksin

```
graphical.target   ← normal
multi-user.target  ← GUI'siz normal
rescue.target      ← tek kullanıcı, kök bağlı, servisler yok  (systemd.unit=rescue.target)
emergency.target   ← en minimal, kök salt okunur              (systemd.unit=emergency.target)
init=/bin/bash     ← systemd bile yok, çıplak kabuk
```
Yukarıdan aşağıya doğru dene. En üstte açılabiliyorsa aşağıya inme.

---

## 🧪 Lab

> **Her adımdan önce VM snapshot'ı al.** Bu modülde sistemi kırmak amaçlanıyor.

1. `[ -d /sys/firmware/efi ]` ile sisteminin UEFI mi BIOS mu olduğunu belirle.
   UEFI ise `efibootmgr -v` çıktısını incele.
2. `cat /proc/cmdline` ile mevcut kernel parametrelerini oku, her birinin ne yaptığını araştır.
3. `systemd-analyze blame | head -10` ile açılışın en yavaş servislerini bul.
   `systemd-analyze plot > /tmp/acilis.svg` üret.
4. `/etc/default/grub` içinde `GRUB_TIMEOUT=10` yap ve `quiet rhgb` parametrelerini kaldır.
   Uygun komutla yeniden üret, reboot et, açılış mesajlarının aktığını gör.
5. `systemctl get-default` ile varsayılan target'ı gör. `multi-user.target` yap
   (zaten öyleyse `graphical` yapıp geri al). `systemctl isolate` ile anında geçiş dene.
6. GRUB menüsünde `e` ile `systemd.unit=rescue.target` ekleyip aç. Ortamı incele
   (`systemctl list-units`, `df -h`), reboot et.
7. **Root parolası sıfırlama:** Rocky'de `rd.break` yöntemiyle, Debian'da `init=/bin/bash`
   yöntemiyle root parolasını değiştir. Rocky'de `touch /.autorelabel` adımını **kasten
   atla**, ne olduğunu gör, sonra düzelt.
8. **fstab kırma:** `/etc/fstab`'a var olmayan bir UUID satırı ekle (`nofail` **olmadan**),
   reboot et, emergency mode'a düştüğünü gör. `mount -o remount,rw /` → düzelt → reboot.
   Sonra aynı satırı `nofail` ile ekle, sistemin sorunsuz açıldığını gör.
9. `journalctl -b -1 -p err` ile bir önceki açılışın hatalarını oku.
10. Eski bir kernel'i GRUB menüsünden seçerek aç, `uname -r` ile doğrula.
11. `systemctl --failed` çalıştır, varsa bir servisin neden başarısız olduğunu
    `journalctl -xeu` ile bul.
12. (İleri) `grub2-setpassword` ile GRUB'a parola koy, menüde düzenleme yapmayı dene.

---

## ❓ Kendini test et

**S1.** `/boot/grub2/grub.cfg` dosyasını neden elle düzenlememelisin?

<details><summary>Cevap</summary>
O dosya `grub2-mkconfig`/`update-grub` tarafından **üretilir**. Her kernel güncellemesinde
yeniden yazılır ve elle yaptığın değişiklikler kaybolur.
Doğru yer: `/etc/default/grub` (+ `/etc/grub.d/`), sonra config'i yeniden üret.
</details>

**S2.** RHEL 9'da root parolası sıfırladıktan sonra `touch /.autorelabel` neden şart?

<details><summary>Cevap</summary>
`/etc/shadow` dosyası yeniden yazıldığında SELinux güvenlik bağlamı bozulur.
`/.autorelabel` bir sonraki açılışta tüm dosya sisteminin yeniden etiketlenmesini sağlar.
Yapılmazsa sistem açılmayabilir veya girişe izin vermez.
Alternatif: `restorecon -v /etc/shadow`.
</details>

**S3.** initramfs neden gerekli?

<details><summary>Cevap</summary>
Kernel'in gerçek kök dosya sistemini bağlayabilmesi için disk denetleyici, RAID, LVM
veya şifreleme sürücülerine ihtiyacı var — ama bu sürücüler kök FS'in içinde.
initramfs, RAM'e yüklenen geçici bir kök sağlayarak bu tavuk-yumurta problemini çözer.
</details>

**S4.** Sistem "Failed to mount /veri" diyerek emergency mode'a düştü. İlk hamlen?

<details><summary>Cevap</summary>
`mount -o remount,rw /` ile kökü yazılabilir yap, `/etc/fstab`'taki hatalı satırı
düzelt veya yorum satırı yap, `mount -a` ile test et, reboot.
Önleme: fstab girdilerine `nofail` eklemek ve değişiklik sonrası `mount -a` çalıştırmak.
</details>

**S5.** SysV-init ile systemd arasındaki en temel mimari fark?

<details><summary>Cevap</summary>
SysV betikleri **sırayla** (numaralandırılmış) çalıştırır — biri yavaşsa hepsi bekler.
systemd bağımlılık grafiği kurar ve birbirine bağlı olmayan unit'leri **paralel**
başlatır; ayrıca socket/D-Bus tetiklemeli gecikmeli başlatma yapabilir.
Sonuç: çok daha hızlı ve öngörülebilir açılış.
</details>

---

## 📋 Hızlı referans

```bash
[ -d /sys/firmware/efi ] && echo UEFI || echo BIOS
cat /proc/cmdline                    # mevcut kernel parametreleri

# GRUB
vi /etc/default/grub                 # ⭐ DOĞRU DOSYA
grub2-mkconfig -o /boot/grub2/grub.cfg    # RHEL
update-grub                               # Debian/Ubuntu
grubby --update-kernel=ALL --args="X"     # RHEL kolay yol
grub2-setpassword                         # GRUB parolası

# Target (runlevel)
systemctl get-default
systemctl set-default multi-user.target
systemctl isolate rescue.target

# Teşhis
systemd-analyze blame | head
systemctl --failed
journalctl -b -1 -p err              # ⭐ önceki açılışın hataları
dmesg -T | less

# Kurtarma (GRUB'da 'e', sonra Ctrl+X)
rd.break enforcing=0                 # RHEL parola sıfırlama
init=/bin/bash                       # Debian parola sıfırlama (ro→rw)
systemd.unit=rescue.target | emergency.target
nomodeset                            # siyah ekran

# initramfs
dracut -f --regenerate-all           # RHEL
update-initramfs -u -k all           # Debian
```
