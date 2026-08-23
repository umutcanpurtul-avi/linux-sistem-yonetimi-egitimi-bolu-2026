---
tags: [linux, egitim, index]
durum: tamamlandi
---

# Linux Sistem Yöneticiliği — Çalışma Seti

Bu set, "Sıfırdan Linux Ağ ve Sistem Yöneticiliği" müfredatının modül modül işlenmiş,
**uygulanabilir** halidir. Orijinal kurs CentOS 6 tabanlı; bu notlar hem o mimariyi
hem de bugün sahada karşılaşacağın modern karşılıklarını (RHEL 9 / Rocky / Alma,
Debian 12 / Ubuntu 24.04, systemd) birlikte veriyor.

## Nasıl kullanılır

1. Modülleri sırayla oku. Her modülün sonunda **Lab** bölümü var — oku geç yapma, yaz.
2. Her modülün başındaki `- [ ]` hedeflerini lab'ı bitirdikçe işaretle.
3. **Kendini test et** bölümündeki soruları önce cevapla, sonra aç.
4. `Dağıtım farkı` kutularını atlama — mülakatta ve sahada asıl ayrım orada.

## Lab ortamı (bir kere kur, hep kullan)

En az 2 sanal makine öner:

| VM | Dağıtım | Amaç |
|---|---|---|
| `rocky1` | Rocky Linux 9 (veya AlmaLinux 9) | RHEL ailesi — dnf, firewalld, SELinux |
| `deb1` | Debian 12 veya Ubuntu Server 24.04 | Debian ailesi — apt, ufw, AppArmor |

Her ikisine de kurulum sırasında **ikinci bir boş disk** (8-16 GB) ekle — disk ve LVM
modüllerinde lazım olacak. Snapshot alma alışkanlığı edin: her modül öncesi snapshot,
modül sonrası sil.

> Kurstaki CentOS 6 + VMware Player kombinasyonunu birebir takip etmeni önermem.
> CentOS 6'nın deposu kapalı, `yum install` çalışmaz. Proxmox / VirtualBox / KVM üzerinde
> Rocky 9 kur, komut farklarını modüllerdeki tablolardan takip et.

## Modüller

| # | Modül | Ana konu |
|---|---|---|
| 01 | [01-sunucu-kurulumu](01-sunucu-kurulumu.md) | Sanallaştırma, kurulum, ilk ağ ayarı |
| 02 | [02-temel-komutlar](02-temel-komutlar.md) | man, dosya komutları, metin araçları |
| 03 | [03-vim-editoru](03-vim-editoru.md) | Vim modları, düzenleme, arama-değiştirme |
| 04 | [04-dosya-sistemi](04-dosya-sistemi.md) | FHS, dosya tipleri, link, izinler, tar |
| 05 | [05-kullanici-grup-yonetimi](05-kullanici-grup-yonetimi.md) | useradd, grup, su/sudo, parola politikası |
| 06 | [06-kabuk-shell](06-kabuk-shell.md) | Değişken, yönlendirme, pipe, grep/sed/awk, bash script |
| 07 | [07-paket-yonetimi](07-paket-yonetimi.md) | rpm/dnf, dpkg/apt, depo yönetimi |
| 08 | [08-surec-yonetimi](08-surec-yonetimi.md) | ps, kill, nice, nohup, systemd servisleri |
| 09 | [09-disk-yonetimi](09-disk-yonetimi.md) | Bölümleme, mkfs, mount, swap, kota, dd, rsync, fsck |
| 10 | [10-lvm](10-lvm.md) | PV/VG/LV, büyütme, snapshot |
| 11 | [11-ag-ayarlari](11-ag-ayarlari.md) | IP yapılandırma, nmcli, netplan, ss, dig, tcpdump |
| 12 | [12-zamanlanmis-gorevler](12-zamanlanmis-gorevler.md) | crontab, at, systemd timer |
| 13 | [13-loglama-rsyslog](13-loglama-rsyslog.md) | rsyslog, journald, merkezi log, logrotate |
| 14 | [14-sistem-acilisi-grub](14-sistem-acilisi-grub.md) | BIOS/UEFI, GRUB2, initramfs, target, parola kurtarma |
| 15 | [15-sistem-izleme-araclari](15-sistem-izleme-araclari.md) | top/htop, donanım bilgisi, çekirdek modülleri |

## Önerilen sıra ve tempo

- **Hafta 1:** 01 → 04 (temel hakimiyet)
- **Hafta 2:** 05 → 08 (kullanıcı, kabuk, paket, süreç)
- **Hafta 3:** 09 → 12 (depolama ve otomasyon)
- **Hafta 4:** 13 → 15 (log, boot, izleme) + genel tekrar labı

## Genel kural

Her komutu **kendi makinende çalıştırmadan** bir sonrakine geçme. Linux öğrenmenin
tek yolu, bozup geri getirmektir. Snapshot al, boz, düzelt.
