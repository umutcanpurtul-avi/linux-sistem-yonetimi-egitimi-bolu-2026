---
tags:
  - egitim/linux-sistem-yonetimi
---

# Eğitim Planı — GNU/Linux Sistem Yönetimi 1. Düzey

> Kaynak: `yerel eğitim materyali (repo dışı)`. İşlenen konuları aşağıda işaretleyip ilgili [Günlük Notlar](Kamp%20Eğitim/README.md) sayfasına bağlantı verebilirsin.

## Özgür Yazılım Felsefesi ve Temel Kavramlar

- [x] Yazılımın özgürlüğü kavramı ✅ 2026-08-22
- [x] Yazılım lisansları ✅ 2026-08-22
- [x] Özgür yazılım vs açık kaynak ✅ 2026-08-22
- [x] Özgür programlama dilleri ✅ 2026-08-22
- [x] İşletim sistemi kavramı ve yapısı ✅ 2026-08-22
- [x] Çekirdek tanımı ✅ 2026-08-22
- [x] Özgür yazılımların tarihçesi ve felsefesi ✅ 2026-08-22
- [x] Özgür yazılımların sağladığı kazanımlar ✅ 2026-08-22
- [x] Özgür yazılımların kullanım alanları ✅ 2026-08-22
- [x] Dağıtımlar ve Dağıtım Seçimi ✅ 2026-08-22
	- [x] GNU/Linux, FreeBSD, OpenBSD ve özel mülkiyet UNIX işletim sistemleri ✅ 2026-08-22
	- [x] Debian Ailesi ✅ 2026-08-22
	- [x] RedHat Ailesi ✅ 2026-08-22
	- [x] Özelleşmiş Dağıtımlar (pfSense, FreeNAS, Kali vs) ✅ 2026-08-22
	- [x] Diğer Dağıtımlar (SuSE, Arch, Gentoo, vs) ✅ 2026-08-22

## GNU/Linux İşletim Sisteminin Yapısı

- [ ] Açılış Sistemi
- [x] Dosya Sistemlerinin Tanıtılması ✅ 2026-08-23
- [x] Dosya ve Dizin Hiyerarşisi ✅ 2026-08-23

## Komut Satırı (Kabuk) ve Temel Komutlar

- [x] Kabuk Kavramı ✅ 2026-08-23
- [x] Bourne-Again SHell (Bash) ✅ 2026-08-23
- [x] Uçbirimde yön bulma ✅ 2026-08-23
	- [ ] Sık Kullanılan Kısa Yollar
	- [ ] Geçmiş
- [x] Yardım Almak (man, info, help, Google :P) ✅ 2026-08-23
- [x] Mutlak Yol, Bağıl Yol Kavramları ✅ 2026-08-23
- [x] Dosya Türleri (Dizin, Soket, vs) ✅ 2026-08-23
- [ ] Temel Komutlar
	- [x] pwd, ls, touch, cat, echo, cp, mv, rmdir, rm, file, mkdir, tail, head ✅ 2026-08-23
	- [ ] grep, wc, sort, which, du, df, wget, curl
	- [ ] Dosyaların İncelenmesi ve Düzenlenmesi
		- [ ] vi, nano, less, more
	- [x] Dosya, dizin arama işlemleri ✅ 2026-08-23
		- [ ] find
	- [x] Dosya içerik arama işlemleri ✅ 2026-08-23
		- [ ] grep
	- [ ] Arşivleme (GNU Tar)
	- [ ] Sıkıştırma Yöntemleri ve Farkları (gzip, xz, bzip2, zip, rar)
	- [ ] Donanım Bilgisi Toplama (dmidecode, lscpu, lspci, lsusb)
- [x] Sembolik bağ ✅ 2026-08-23

## Kabuk ve Özellikleri

- [ ] Çevresel Değişkenler (Giriş Seviyesi)
- [x] Standart Girdi/Çıktı (IO) ✅ 2026-08-22
- [ ] Mantıksal Operatorler
- [ ] Takma Ad (Alias)
- [x] Girdi/Çıktının Yönlendirilmesi ✅ 2026-08-22
- [ ] Özel karakterler

## Kullanıcı ve Grup Yönetimi

- [ ] Kullanıcı Kavramı
	- [ ] Kullanıcı Kontrol Dosyalarının Yapıları (`/etc/passwd`, `/etc/shadow`, `/etc/group`)
- [ ] "root" Kullanıcısı, Özel Tanımlı Kullanıcılar ve "sudo"
- [ ] Kullanıcı İşlemleri (oluşturma, silme, kabuk atama, kimlik değişimi)
	- [ ] Kullanıcı Bilgi Değişikliği (passwd, chsh, chfn)
	- [ ] Kullanıcı Bilgilerinin Gözlemi (w, who, whoami, id, users, last)
- [ ] Grup Kavramı
	- [ ] Grup Dosyalarının Yapıları (`/etc/group`, `/etc/gshadow`, vs.)
- [ ] Grup İşlemleri (gruba ekleme-çıkarma, grup ekleme-silme, vs.)
- [ ] Dosya Yetkilendirmeleri (rwx, suid/guid, sticky bit, immutable, acl)
- [ ] Bilinmeyen bir root parolasının değiştirilmesi

## Paket Yönetim Sistemi

- [ ] Temel Kavramlar (Paket, Depo, Paket Yöneticisi)
- [ ] Dağıtımların Paket Yöneticileri ve Araçları (apt/deb, yum/rpm, pacman, zypper/rpm, vs.)
- [ ] Temel İşlemler (kurma, kaldırma, güncelleme, arama, detaylı paket inceleme, vs.)
- [ ] Yükseltme, Eski Sürüme İndirme (downgrade) ve Otomatik Güncelleme
- [ ] Benzer Sistemler (maven, composer, rvm, pip, nuget, vs.)
- [ ] Önbellek (cache, yerel indeks) Yönetimi
- [ ] DEB/APT - YUM/RPM farklılıkları
- [ ] Yeni Paket Depolarının Eklenmesi
- [ ] Bir Depodaki Belli Paketlerin Kullanılma(ma)sı ve Güncellenmemesi (exclude)
- [ ] Paket Yöneticileri ve Ayar Dosyaları
- [ ] Paket Yönetimi Geçmişi Yönetimi ve İşlem Geri Alma
- [ ] Paket Yöneticisi Kullanılarak Bir Programın Kaynak Kodunun İndirilmesi
- [ ] Delta kavramı

## Süreçler ve Servisler

- [ ] Süreç Kavramı
- [ ] Süreç Durumlarının Açıklaması
- [ ] Süreçlerin Yönetimi (öldürme, durdurma, jobs, fg-bg, vs.)
	- [ ] ps, top, htop Çıktılarının İncelenmesi
	- [ ] Sinyaller
- [ ] Servis Kavramı
- [ ] Systemd ve SysV Sistemleri
- [ ] Bilgisayar Açılış (Boot-up) Süreci
- [ ] Userspace ve Kernelspace Kavramları
- [ ] Systemd ile Servis Yönetimi
	- [ ] Systemd unit dosyalarının yapısı
	- [ ] Target Kavramı
	- [ ] Sistem açılırken servislerin çalışma sırası
	- [ ] Her sistem açılışında çalışacak bir komut eklenmesi
	- [ ] systemd'nin servis yönetimi dışında işlevleri

## Sistem Kayıtları

- [ ] Log Kavramı
	- [ ] syslog, rsyslog
- [ ] /var/log İncelemesi
- [ ] logger Aracının Kullanımı, İncelenmesi
- [ ] systemd-journald Kullanımı, Farkları

## Depolama Aygıtlarının Yönetimi

- [ ] GNU/Linux Sistemlerde Disk Yönetimi
	- [ ] Disk bölümleme (fdisk, parted vb.)
	- [ ] Bir Dosya Sistemi Kullanılarak Diskin Formatlanması (mkfs)
	- [ ] Dosya sisteminin kontrolü ve düzeltilmesi (fsck)
- [ ] Mount (Bindirme) İşlemleri
	- [ ] Mount Parametreleri
	- [ ] /etc/fstab Açıklaması
- [ ] Hard link ve inode (ln, stat)
- [ ] Bir sürecin kullandığı bir dosyanın silinmesi ya da değiştirilmesi

## Zamanlanmış Görevler

- [ ] cron
- [ ] at
- [ ] systemd-timer

## Temel TCP/IP Bilgisi ve Ağ Yönetimi

- [ ] Ağ Nedir?
- [ ] Temel Ağ Bilgisi
	- [ ] OSI Katmanları
- [ ] Ağ Protokolleri
	- [ ] TCP, UDP, ICMP
- [ ] TCP/IP Protokolü
	- [ ] IP adresi, Ağ, Ağ Maskesi, Ağ Geçidi, Broadcast
	- [ ] Alt Ağ Adresi Bulma İşlemleri / Subnetting
- [ ] GNU/Linux Sistemlerde Ağ Yönetimi
	- [ ] ip, ifconfig, route, traceroute, ping, whois, telnet, ss, netstat, netcat (uygulamasız), tcpdump (uygulamasız)
	- [ ] Ağ Ayarlarının Yönetimi
		- [ ] /etc/network/interfaces, /etc/sysconfig/network-scripts
		- [ ] NetworkManager
		- [ ] DHCP

## DNS Teknolojisine Giriş

- [ ] DNS sisteminin çalışması
	- [ ] Ağaç yapısı (tr -> org -> linux -> kamp)
	- [ ] Alan adı çözümleme (nsswitch, /etc/hosts, /etc/resolv.conf)
- [ ] dig, nslookup, host
- [ ] DNS kayıtlarının incelenmesi (A, MX, CNAME, NS, AAAA)
- [ ] Birincil (master) ve ikincil (slave) DNS kavramı
	- [ ] Yetkili (authorative)
	- [ ] Özyinelemeli (recursive) sorgu
- [ ] SOA kaydı (TTL, Refresh, Retry, Expire, Minimum)

## Güvenli Uzaktan Erişim

- [ ] SSH'a Giriş
	- [ ] Doğrulama yöntemleri (parola, anahtar, vs.)
	- [ ] Şifreleme yöntemleri (simetrik - asimetrik)
- [ ] sshd servisi ve ayarları
- [ ] Parolasız güvenli erişim
- [ ] ssh uzaktan komut çalıştırma
- [ ] scp ile dosyaların güvenli bir şekilde kopyalanması
- [ ] sftp ile güvenli FTP benzeri dosya aktarma erişimi
- [ ] ssh ile SOCKS vekil (proxy) sunucu
- [ ] ssh ile tünelleme ve ters tünelleme
- [ ] ssh-agent ile anahtar taşıma
- [ ] ssh ile X11 tünelleme
- [ ] ssh istemcisinin ~/.config dosyasının yapılandırılması

## Yedekleme, Arşivleme ve Sıkıştırma

- [ ] rsync (ssh üzerinden) ile dizin eşitlenmesi
- [ ] Yedekleme yazılımlarının tanıtılması (Bacula, rdiff-backup, vs)

## Apache/PHP/MySQL Kurulumu ve Örnek Bir Uygulamanın Koşturulması

- [ ] Apache/PHP/MySQL'in paket yöneticisinden kurulumu
- [ ] phpMyAdmin web arayüzünün kurulumu
- [ ] Wordpress'in meşhur 5 dakikada kurulumu
	- [ ] MySQL'de kullanıcı oluşturulması
	- [ ] Apache'de gerekli ayarların düzenlenmesi (AllowOverride, vs)
- [ ] Kendi sunucunuza kurabileceğiniz yaygın uygulamalar (https://github.com/Kickball/awesome-selfhosted)
