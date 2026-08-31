---
tags:
  - egitim/linux-sistem-yonetimi
tarih: 2026-08-30
konular:
  - SSH — istemci/sunucu, ssh ve sshd farkı, kurulum ve bağımlılıklar
  - SSH bağlantı anı — ssh -v, sunucu anahtar doğrulama, TOFU
  - SSH dizin ve dosyaları — ~/.ssh, /etc/ssh, known_hosts
  - ssh_config ve sshd_config
  - PKI ve SSH anahtarları — ssh-keygen, ssh-copy-id, ssh-agent
  - SSH taklaları — port yönlendirme (-L/-R/-D), agent forwarding, X11
  - Dosya aktarımı — scp, sftp, rsync, sshfs
  - dd
  - Servislerin otomatik başlaması — Debian ve RHEL farkı
  - Paket deposu yönetimi ve apt update
  - Kısa komutlar — rm, touch, mkdir, logout, set, tmux, alias
---

# Gün 9

Bağlantı: [Linux Sistem Yönetimi Eğitimi](../README.md) · [00 - Eğitim Planı](../00%20-%20Eğitim%20Planı.md) · [Gün 8](Gün%208.md)

## İşlenen Konular

Günün ağırlığı **SSH** üzerineydi; yanında servis/paket yönetimi mantığı ve bir dizi
kısa komut işlendi.

**SSH:**

- SSH nedir? `ssh` istemcisi ile `ssh` sunucusu arasında ne fark var?
- Kurulum: `apt install openssh-server`. SSH'ın bağımlılıkları nelerdir?
- `ssh` (istemci komutu) ile `sshd` (sunucu servisi) arasındaki fark.
- `ssh -v` (verbose) çıktısı.
- İlk bağlantıda çıkan uyarı:
  > The authenticity of host '192.168.56.101 (192.168.56.101)' can't be established.
  > ED25519 key fingerprint is SHA256:kR3G7mP9vXqL2wYtN8bJ4hF6dC1sA0eZuI5oQpM3rTk.
  > This key is not known by any other names
  > Are you sure you want to continue connecting (yes/no/[fingerprint])?

  — bu nedir?
- SSH hangi dizinleri kullanır?
- "SSH taklaları": Agent Forwarding, SSH ters tünel, SSH tünelleme, SSH SOCKS proxy, SSH X11 (X.org).
- `~/.ssh/known_hosts` nedir? İçindeki bilgiyi değiştirirsem aldığım hata ne anlama gelir, nelere dikkat etmeliyim?
- `/etc/ssh/ssh_config` nedir, içeriği ne anlama gelir?
- PKI nedir? Neden kullanılır? Nasıl çalışır? Nerede kullanılır?
- SSH anahtarı üretimi, `ssh-copy-id`.
- `scp` nedir, nasıl kullanılır?
- `rsync` nedir, nasıl kullanılır?
- `sftp` nedir, nasıl kullanılır?
- `sshfs` nedir, nasıl kullanılır?
- `dd` nedir, nasıl kullanılır?

**Servis ve paket yönetimi:**

- Servislerin çalışması: Debian'da bir paket/servis kurulunca otomatik olarak çalışır ve açılışa eklenir; Red Hat ailesinde ise kurulum servisi kurar ama başlatmayı ve açılışa eklemeyi sana bırakır.
- Bir paket kurulumundan önce neden `apt update` yapılmalı?
- Paket deposu (repository) yönetimi.

**Kısa komutlar:**

- `rm` komutu ve parametreleri; yanlış kullanılan `rm` parametreleri ve `-rf` alışkanlığının bırakılması.
- `touch` nedir, ne işe yarar?
- `mkdir` nedir, ne işe yarar?
- `logout` komutu.
- `set` nedir, ne işe yarar?
- `tmux` nedir, ne işe yarar?
- `alias` nedir, ne işe yarar?

## Genişletilmiş Anlatım (Öğrenme İçin Ek Açıklamalar)

> [!WARNING]
> **Yukarıda bulunan kısa notların AI ile genişletilmiş halidir. Bilgiler sadece o gün işlenen konular ile sınırlandırılmış olup referans olması için eklenmiştir. Lütfen bu genişletilmiş metni kendi araştırmalarınıza bir ön bilgi olarak kullanın ve testlerinizi sadece burayı kullanarak değil, farklı kaynaklardan da yararlanarak yapın.**

> [!NOTE]
> **Ham nottaki bazı yazımlar düzeltilerek kullanıldı: "SSH Scok Proxy" → **SOCKS proxy**, "SSH X.org" → **X11 forwarding**, "know_host" → **`known_hosts`**, "`/home/.ssh/`" → **`~/.ssh/`** (kullanıcının ev dizini altında), "`/etc/ssh/ssh-config`" → **`/etc/ssh/ssh_config`** (istemci) ve onun sunucu karşılığı **`/etc/ssh/sshd_config`**, "ssh-copy-ıd" → **`ssh-copy-id`**, "tmax" → **`tmux`**, "allias" → **`alias`**.**

### 1. SSH nedir; `ssh` (istemci) ↔ `sshd` (sunucu); protokol mimarisi; kurulum

**Katman ve mekanizma.** SSH (Secure Shell), bir ağ üzerinden **güvenli** (şifreli, bütünlüğü korunan, karşı tarafın kimliği doğrulanmış) bir kanal açan, uygulama katmanında çalışan bir protokoldür; standart TCP portu **22**'dir. SSH-2 protokolü (bugün kullanılan sürüm) üç ayrı katmandan oluşur (RFC 4251 mimari, 4252/4253/4254 alt protokoller):

1. **Taşıma katmanı (RFC 4253):** İlk anahtar değişimi (key exchange), **sunucunun kimlik doğrulaması** (host key ile — 2. başlık), şifreleme, sıkıştırma ve bütünlük (MAC) burada kurulur. İleri gizlilik (perfect forward secrecy) sağlar; yaklaşık 1 GB veri veya 1 saat sonra anahtarları yeniler.
2. **Kullanıcı kimlik doğrulama katmanı (RFC 4252):** **İstemciyi sunucuya** doğrular — parola, açık anahtar (public key), klavye-etkileşimli, GSSAPI gibi yöntemlerle.
3. **Bağlantı katmanı (RFC 4254):** Kurulan tek şifreli tüneli **çok sayıda mantıksal kanala** böler: bir kabuk oturumu, port yönlendirmeleri, agent forwarding, X11 — hepsi aynı TCP bağlantısı içinde ayrı kanallardır (6. başlık bunun üstüne kurulu).

**`ssh` ↔ `sshd`.** İkisi aynı yazılım ailesinden (OpenSSH) ama zıt roller:

| | `ssh` | `sshd` |
| --- | --- | --- |
| Ne | **İstemci** komutu — sen çalıştırırsın, gidersin | **Sunucu daemon**'ı — arka planda dinler, gelen bağlantıyı kabul eder |
| Ne zaman | Sen `ssh kullanici@host` yazınca, tek seferlik | Boot'ta başlar, sürekli 22'yi dinler (systemd: `ssh.service`) |
| Kim | Herhangi bir kullanıcı | root (dinleme portu <1024; her bağlantı için ayrıcalık düşüren alt süreç açar) |
| Ayar | `~/.ssh/config`, `/etc/ssh/ssh_config` | `/etc/ssh/sshd_config` |
| Paket (Debian) | `openssh-client` | `openssh-server` |

**Kurulum ve bağımlılıklar.** `apt install openssh-server` (Debian 13'te sürüm `1:10.0p1-...`). `openssh-server` paketi `openssh-client` ve `openssh-sftp-server` paketlerine **bağımlıdır** (yani sunucuyu kurunca istemci ve SFTP alt sistemi de gelir). Diğer bağımlılıklar kriptografi ve sistem entegrasyonu içindir: **`libssl3` / libcrypto** (şifreleme algoritmaları), **`libpam`** (parola doğrulama — PAM üzerinden), `libgssapi-krb5` (Kerberos SSO), `libselinux1`, `libaudit1` (denetim günlüğü), `zlib1g` (sıkıştırma), `libc6`. Kavramsal olarak SSH'ın "olmazsa olmaz" bağımlılığı **bir kripto kütüphanesidir** (OpenSSL/libcrypto); geri kalanı isteğe bağlı özellikleri besler.

**Neden SSH var.** SSH, 1995'te telnet + rlogin + rsh + rcp'nin yerine geçmek için yazıldı — o araçlar **her şeyi düz metin** taşıyordu (Gün 7'de `telnet` için anlatıldı: `bkz.` [Gün 7#11. Ağ teşhis araçları: `ss`, `traceroute`, `telnet`](Gün%207.md#11-ağ-teşhis-araçları-ss-traceroute-telnet)). SSH aynı işi (uzak kabuk + dosya kopyalama + port yönlendirme) yapar ama trafiği şifreler ve **sunucunun gerçekten o sunucu olduğunu** doğrular.

### 2. Bağlantı anı: `ssh -v`, sunucu anahtar doğrulama ve TOFU

**Mekanizma — "authenticity of host … can't be established" ne demek.** SSH taşıma katmanı, bağlantının başında sunucudan **host key**'ini (sunucunun açık anahtarı — genelde Ed25519) ister ve bir imza doğrulamasıyla karşı tarafın o anahtarın özel yarısına sahip olduğunu teyit eder. Ama "bu anahtar gerçekten bu sunucuya mı ait?" sorusunun kriptografik cevabı yoktur — istemci bu anahtarı daha önce görmediyse **sen karar verirsin**. Bu modele **TOFU (Trust On First Use)** denir: ilk bağlantıda anahtarı kabul edersin, istemci onu `~/.ssh/known_hosts`'a **sabitler (pin)**, sonraki her bağlantıda sunucunun sunduğu anahtar bu kayıtla **birebir** eşleşmek zorundadır.

Uyarıdaki satırlar:

- `ED25519 key fingerprint is SHA256:kR3G7mP9…` → host key'in **parmak izi** (anahtarın SHA-256 özeti, base64). Anahtarın tamamını okumak yerine bu kısa özeti, sunucuya fiziksel/güvenli bir kanaldan eriştiğinde (konsol, kurulum çıktısı, yöneticiye sorarak) elde ettiğin değerle **karşılaştırırsın**. Eşleşiyorsa `yes` dersin.
- `This key is not known by any other names` → bu anahtarı başka bir hostname/IP altında da görmemişsin.
- `yes/no/[fingerprint]` → `yes` kabul et; `no` iptal; parmak izini yapıştırırsan istemci onu doğrulayıp otomatik kaydeder.

**Ne zaman / kim / neden.** Bu uyarı yalnızca **ilk kez** (veya `known_hosts`'tan kayıt silinmişse) çıkar. "Sadece `yes` bas geç" alışkanlığı SSH'ın MITM (ortadaki adam) korumasını fiilen kapatır — çünkü aynı ağdaki bir saldırgan araya girip **kendi** host key'ini sunabilir; parmak izini gerçekten doğrulamadan `yes` dersen onun anahtarını sabitlemiş olursun.

**`ssh -v` (ve `-vv`, `-vvv`).** İstemciye el sıkışmanın her adımını bastırır: hangi `ssh_config` dosyaları okundu, hangi anahtar değişim/şifreleme algoritması seçildi, host key doğrulaması, hangi kimlik doğrulama yöntemleri denendi (`publickey` → hangi anahtar dosyası → `password`), hangisi kabul edildi. Bir bağlantı "neden reddedildi / neden parola soruyor / neden anahtarım kabul edilmiyor" sorusunun ilk teşhis aracıdır.

### 3. SSH'ın kullandığı dizinler/dosyalar; `known_hosts` değiştirilirse

**Mekanizma.** SSH iki yerde dosya tutar:

**`~/.ssh/` (kullanıcıya özel, izinleri katı — `700`):**

| Dosya | Rolü | Tipik izin |
| --- | --- | --- |
| `known_hosts` | Daha önce bağlanılan sunucuların host key'leri (TOFU sabitleme) | `644` |
| `id_ed25519`, `id_rsa` … | **Özel** anahtar(lar) — asla paylaşılmaz | `600` |
| `id_ed25519.pub` … | **Açık** anahtar — sunuculara dağıtılır | `644` |
| `authorized_keys` | *Bu makineye* hangi açık anahtarlarla girilebileceği (sunucu tarafı) | `600` |
| `config` | İstemci kısayolları/ayarları (`Host web` blokları) | `600` |

`sshd`, `authorized_keys` ve `~/.ssh` izinleri fazla açıksa (başkası yazabiliyorsa) anahtar girişini **reddeder** — buna `StrictModes` denir; "anahtarım var ama parola soruyor" vakalarının klasik sebebidir.

**`/etc/ssh/` (sistem geneli):** `sshd_config` (sunucu ayarı), `ssh_config` + `ssh_config.d/` (istemci varsayılanları), `ssh_host_ed25519_key` / `ssh_host_rsa_key` (+`.pub`) — **sunucunun kendi host key'leri**, kurulumda üretilir; `sshd_config.d/` (parça ayar dosyaları).

**`known_hosts`'taki kaydı değiştirir/silersen ne olur:**

- **Bir satır silersen:** o sunucuya bir sonraki bağlantıda yeniden "authenticity of host…" uyarısı (TOFU sıfırlanır).
- **Bir kaydı kurcalar/bozarsan** ya da sunucu gerçekten farklı bir anahtar sunarsa (yeniden kurulmuş, IP başka makineye verilmiş, VM snapshot'tan dönmüş — **veya MITM**):
  ```
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @    WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!     @
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  ```
  SSH bağlantıyı **tamamen reddeder** (parola bile sormaz). Bu bilinçli bir tasarım: değişen host key, bir MITM saldırısının tam olarak göründüğü şeydir. **Dikkat edilecek:** körü körüne `ssh-keygen -R <host>` ile kaydı silip yeniden kabul etme — önce sunucunun host key'inin **neden** değiştiğini doğrula (yönetici, konsol çıktısı). Meşru sebep varsa (yeniden kurulum) sil ve yeni parmak izini teyit ederek kabul et.

### 4. `ssh_config` ↔ `sshd_config`: istemci mi sunucu mu; öncelik

**Mekanizma.** İki dosya **karıştırılır ama zıt taraftadır**:

- **`/etc/ssh/ssh_config`** → **istemci** (`ssh`, `scp`, `sftp`) için sistem geneli **varsayılanlar**: hangi kullanıcı adı, port, kimlik dosyası, `ForwardAgent`, `ForwardX11`, `ProxyJump` vb. Kullanıcı bunu `~/.ssh/config` ile geçersiz kılar.
- **`/etc/ssh/sshd_config`** → **sunucu** (`sshd`) davranışı: `Port`, `PermitRootLogin`, `PasswordAuthentication`, `PubkeyAuthentication`, `AllowUsers`, `X11Forwarding`, `AllowTcpForwarding`. Değişiklik için `sshd`'yi yeniden yükle (`systemctl reload ssh`).

**İstemci tarafı öncelik sırası** (ilk bulunan değer kazanır):

1. Komut satırı seçenekleri (`ssh -p 2222 -i ~/.ssh/özel ...`)
2. `~/.ssh/config` (kullanıcının kendi dosyası)
3. `/etc/ssh/ssh_config` (sistem geneli)

`~/.ssh/config` örneği (neden kullanılır: uzun komutları kısaltmak, host başına farklı anahtar/kullanıcı/atlama sunucusu tanımlamak):

```
Host web
    HostName 192.168.56.101
    User ucp
    Port 22
    IdentityFile ~/.ssh/id_ed25519
```

Artık `ssh web` yeter.

### 5. PKI ve SSH anahtarları

**PKI nedir / nasıl çalışır.** PKI (Public Key Infrastructure), **asimetrik şifreleme** üzerine kurulu bir güven altyapısıdır. Asimetrik şifrelemede matematiksel olarak bağlı bir **anahtar çifti** vardır: **özel anahtar** (private — gizli tutulur) ve **açık anahtar** (public — herkese verilebilir). Biriyle şifrelenen/imzalanan, yalnızca diğeriyle çözülür/doğrulanır. Bundan iki şey elde edilir: (a) açık anahtarla şifrele → sadece özel anahtar sahibi okur (gizlilik); (b) özel anahtarla imzala → herkes açık anahtarla doğrular ki imza gerçekten o kişiden (kimlik/bütünlük).

**Tam PKI**'de bir **Sertifika Otoritesi (CA)**, "bu açık anahtar şu kişiye/sunucuya aittir" diyen imzalı sertifikalar üretir; güven zinciri CA'ya dayanır (HTTPS böyle çalışır). **SSH ise varsayılan olarak tam PKI kullanmaz** — CA yerine **TOFU** ve `authorized_keys` / `known_hosts` dosyalarıyla açık anahtarları elle sabitler (2. başlık). Büyük ortamlarda **SSH sertifika otoriteleri** de vardır (bir SSH CA tüm host ve kullanıcı anahtarlarını imzalar, `known_hosts`/`authorized_keys` yönetimi ortadan kalkar) ama temel kurulumda anahtarlar "çıplak"tır.

**SSH açık anahtar kimlik doğrulaması nasıl işler:** İstemcinin açık anahtarı sunucudaki `~/.ssh/authorized_keys`'e eklenir. Bağlanırken sunucu bir rastgele veri (challenge) yollar, istemci onu **özel anahtarıyla imzalar**, sunucu `authorized_keys`'teki açık anahtarla imzayı **doğrular**. Özel anahtar hiçbir zaman ağa çıkmaz; parola gibi araya düşürülüp çalınamaz. Bu yüzden parola kimlik doğrulamasından güvenlidir.

**`ssh-keygen` — anahtar üretimi.** `ssh-keygen -t ed25519 -C "yorum"`:

- `-t ed25519` → anahtar türü. **Neden Ed25519:** RSA ile aynı güvenliği çok daha küçük anahtarla verir, üretimi/doğrulaması hızlıdır, yanlış kullanıma dirençlidir. OpenSSH **9.5'ten (2023) beri varsayılan** türdür; daha eski `ssh-keygen`'de varsayılan hâlâ RSA olduğundan `-t ed25519`'u açıkça yazmak iyi alışkanlıktır.
- **Passphrase:** özel anahtar dosyası bu parolayla şifrelenir. Dosya çalınsa bile passphrase olmadan kullanılamaz. Her bağlantıda sormaması için `ssh-agent` devreye girer.
- Çıktı: `~/.ssh/id_ed25519` (özel, `600`) + `~/.ssh/id_ed25519.pub` (açık).

**`ssh-copy-id`.** Açık anahtarı hedef sunucudaki `~/.ssh/authorized_keys`'e **doğru izinlerle** ekleyen küçük betik: `ssh-copy-id ucp@192.168.56.101`. İlk sefer parolayla girer, sonraki tüm bağlantılar anahtarla parolasız olur. Elle yapılırsa `~/.ssh` `700`, `authorized_keys` `600` olmalı yoksa `sshd` (`StrictModes`) reddeder.

**`ssh-agent`.** Özel anahtar(lar)ı bir kez passphrase girerek belleğe alan, sonraki imzalama isteklerini istemci adına yapan arka plan süreci. `ssh-add` ile anahtar eklenir. Böylece passphrase korumasından ödün vermeden her bağlantıda parola sorulmaz. (Agent forwarding — 6. başlık — bu süreci uzak makineye "uzatır", riskleri vardır.)

### 6. SSH taklaları: port yönlendirme, agent forwarding, X11

SSH'ın bağlantı katmanı (1. başlık) tek şifreli tünelde birden çok kanal taşıdığı için, kabuk oturumunun yanında **başka trafikleri de** aynı tünelden geçirebilirsin.

**Yerel port yönlendirme `-L` (SSH tünelleme).** `ssh -L 8080:127.0.0.1:80 ucp@web` → *senin* makinende `localhost:8080`'i dinler; oraya gelen bağlantıyı şifreli tünelden `web` sunucusuna taşır, `web` de onu kendi `127.0.0.1:80`'ine iletir. Kullanım: uzaktaki, dışa kapalı bir servise (yalnız `localhost`'a bağlı veritabanı, yönetim paneli) kendi tarayıcından erişmek. "İçeriye doğru" tünel.

**Uzak/ters port yönlendirme `-R` (SSH ters tünel).** `ssh -R 9000:127.0.0.1:3000 ucp@public` → *uzak* sunucuda (`public`) `9000` portunu açar; oraya gelen bağlantıyı tünelden **senin** makinene, senin `localhost:3000`'ine taşır. Kullanım: NAT/firewall arkasındaki (dışarıdan erişilemeyen) yerel bir servisi geçici olarak dışarıya açmak. "Dışarıya doğru" tünel.

**Dinamik yönlendirme `-D` (SOCKS proxy).** `ssh -D 1080 ucp@web` → yerelde `1080`'de bir **SOCKS proxy** açar; hedef port belirtmezsin. SOCKS'u kullanacak şekilde ayarlanmış uygulamalar (tarayıcı) her isteği tünelden `web` sunucusuna gönderir, çıkışı `web` yapar. Kullanım: tüm trafiği tek bir sunucu üzerinden çıkarmak (coğrafi kısıt, güvenli çıkış noktası).

**Agent forwarding (`-A` / `ForwardAgent yes`).** `ssh-agent` soketini uzak makineye "uzatır"; böylece `web`'e bağlıyken oradan `web2`'ye anahtarını `web`'e kopyalamadan atlayabilirsin. **Risk:** `web`'de root olan (veya soketine erişebilen) biri, sen bağlıyken **senin agent'ını kullanıp senin adına** başka makinelere kimlik doğrulayabilir. Bu yüzden varsayılan kapalıdır; gerekmedikçe açma, açacaksan **`ProxyJump` (`-J`)** tercih et — anahtar ara sunucuya hiç uğramaz.

**X11 forwarding (`-X` / `-Y`).** Uzak makinedeki bir grafiksel uygulamanın penceresini **senin** ekranında (X sunucunda) açar; X protokolü SSH kanalından tünellenir. `-X` **güvensiz mod** (uzak uygulamanın yerel X sunucusuna erişimi kısıtlı — pano okuma, tuş yakalama engellenir), `-Y` **güvenilir mod** (tam erişim — yalnızca gerçekten güvendiğin sunucuya). Sunucuda `sshd_config`'te `X11Forwarding yes` gerekir. Kimlik `xauth` çerezleriyle yapılır. Modern masaüstünde Wayland yaygınlaştıkça X11 forwarding'in yeri daralıyor.

### 7. Dosya aktarımı: `scp`, `sftp`, `rsync`, `sshfs`

Dördü de SSH kanalını kullanır; fark **iş modelinde**.

**`scp`.** "Uzak kopyala" — `scp dosya ucp@host:/hedef/` / `scp ucp@host:/uzak/dosya .`. Tarihsel olarak eski, güvensiz "rcp protokolü"nü kullanırdı; **OpenSSH 9.0'dan (2022) beri arka planda SFTP protokolünü** kullanır (`-O` ile eski protokole zorlanır). Basit, tek seferlik kopyalar için uygundur; **ilerleme takibi, devam ettirme, senkronizasyon zekası yoktur** — dosya varsa baştan kopyalar.

**`sftp`.** SSH'ın bir **alt sistemi** (`openssh-sftp-server`); FTP'ye benzer etkileşimli bir dosya oturumu verir (`get`, `put`, `ls`, `cd`, `rm`). FTP'nin aksine ayrı port/şifresiz kanal yok — her şey 22'den, şifreli. Elle gezinerek dosya alıp vermek için.

**`rsync`.** Sadece kopyalamaz, **senkronize eder** ve **delta-transfer algoritması** ile çalışır: kaynak ve hedefteki dosyaları bloklara böler, **yuvarlanan sağlama toplamı (rolling checksum)** ile hedefte zaten var olan blokları tespit eder ve **yalnızca değişen blokları** ağdan gönderir. 1 GB'lık dosyanın 5 MB'ı değiştiyse ~5 MB trafik olur. Varsayılan uzak taşıma SSH'tır (`rsync -avz kaynak/ ucp@host:/hedef/`). `-a` (arşiv: izin/sahip/zaman koru), `-v`, `-z` (sıkıştır), `--delete` (hedefte fazlalıkları sil), `--dry-run` (deneme). Yedekleme ve büyük ağaç eşitleme için standart araç.

**`sshfs`.** Uzak dizini **yerel bir klasör gibi mount eder**; **FUSE** (Filesystem in Userspace) sayesinde çekirdeği/modül yüklemeyi gerektirmez, ayrıcalıksız kullanıcı çalıştırabilir. Her dosya işlemi (`open`, `read`, `readdir`) arka planda bir SFTP isteğine dönüşür. Sunucuda **sadece SSH+SFTP** yeter, ek yazılım yok. `sshfs ucp@host:/uzak/dizin ~/mnt`. Her bayt şifrelenip çözüldüğü için NFS'ten yavaştır; sık, küçük dosya erişiminde gecikme hissedilir. Ara sıra uzak dizinde çalışmak için pratik.

**Özet — hangisi ne zaman:** tek dosya at → `scp`; elle gezinerek al-ver → `sftp`; dizin eşitle / yedek / tekrar tekrar → `rsync`; uzak dizinde yerelmiş gibi çalış → `sshfs`.

### 8. `dd` — blok düzeyinde kopyalama

**Mekanizma.** `dd`, bir girdiyi bloklar hâlinde okuyup bir çıktıya bloklar hâlinde yazan çok alt seviye bir kopyalama aracıdır. Dosya sistemini, dosya adlarını, "boş alanı" **umursamaz** — ham baytları (sektörleri) olduğu gibi taşır. Bu yüzden bir diskin/bölümün **birebir (bit-bit) kopyasını** çıkarabilir: bölüm tablosu, önyükleyici, silinmiş ama üzerine yazılmamış veriler dâhil.

**Parametreler ve çözdükleri sorun:**

| Parametre | İşi |
| --- | --- |
| `if=` | input file — kaynak (`/dev/sda`, bir `.iso`, `/dev/zero`, `/dev/urandom`) |
| `of=` | output file — hedef (`/dev/sdb`, `disk.img`) |
| `bs=` | block size — bir seferde okunup yazılan öbek (`bs=4M` genelde en hızlısı) |
| `count=` | kaç blok kopyalanacak (`bs=512 count=1` → sadece MBR) |
| `status=progress` | ilerlemeyi canlı göster (yoksa `dd` bitene kadar sessiz durur) |
| `conv=fsync` | bitmeden diske gerçekten yazıldığından emin ol |

Kullanım: USB'ye kurulum imajı yazma (`if=debian.iso of=/dev/sdb bs=4M status=progress`), disk/bölüm imajı alma, MBR yedeği, bir alanı sıfırlama (`if=/dev/zero`), adli kopya.

> [!WARNING]
> **`dd`'nin lakabı "**disk destroyer**": hiçbir onay sormaz, `of=` neyi gösteriyorsa **anında ve geri dönüşsüz** üzerine yazar. `if=` ve `of=`'i ters yazmak (`of=/dev/sda` demek isterken kaynak diski hedef yapmak) tüm diski siler. Her çalıştırmadan önce `lsblk` ile hedef aygıtı **iki kez** doğrula; mümkünse önce bir `.img` dosyasına al.**

### 9. Servislerin otomatik başlaması: Debian ↔ RHEL politika farkı

**Ham nottaki gözlem doğru** ve bunun altında somut bir mekanizma var. Bir paketin servisi kurulunca ne olacağını **systemd preset politikası** (`systemctl preset`, `/usr/lib/systemd/system-preset/*.preset`) belirler; paketlerin kurulum-sonrası betikleri (`postinst` / `%post`) bu politikayı uygular.

| | **Debian / Ubuntu** | **RHEL / Rocky / Fedora** |
| --- | --- | --- |
| Politika | Preset varsayılanı `enable *` → kurulan **her servis hemen enable edilir ve başlatılır** | Preset varsayılanı çoğunlukla `disable *` → kurulum servisi **sadece kurar**; enable/start sana kalır |
| Kurulumdan sonra | Servis zaten çalışıyor ve açılışa ekli | `systemctl enable --now servis` çalıştırman gerekir |
| Ek mekanizma | `policy-rc.d` (ör. chroot/konteyner içinde başlatmayı engellemek için) | — |

**Neden bu fark.** İki dağıtım felsefesi: Debian "kurduysan kullanmak istiyorsundur, çalışır hâlde bırakayım" der (kolaylık). RHEL "hiçbir servis sen açıkça istemeden ağ portu açmasın / kaynak tüketmesin" der (varsayılan güvenlik / az sürpriz). Pratik sonuç: bir RHEL sunucusuna `httpd` kurup "neden `curl localhost` çalışmıyor" dersen cevap, servisin kurulu ama **enable/start edilmemiş** olmasıdır.

### 10. Paket deposu yönetimi ve neden önce `apt update`

**Mekanizma — `apt update` ne yapar.** APT'nin bildiği paketler, sürümleri ve bağımlılıkları, depoların yayınladığı **indeks dosyalarındadır** (`Release` — imzalı özet; `Packages` — paket listesi + sürüm + bağımlılık + dosya adı). `apt update` bu indeksleri `/etc/apt/sources.list` ve `/etc/apt/sources.list.d/*` içinde tanımlı depolardan **yeniden indirir** ve `/var/lib/apt/lists/` altına yazar. **Paketleri indirmez** — sadece "neyin, hangi sürümünün mevcut olduğu" bilgisini tazeler.

**Neden `apt install`'dan önce.** `apt install X` bu **yerel indekse** bakar. İndeks eskiyse:

- Paket depoya yeni eklendiyse → "**Unable to locate package X**".
- Depodaki dosya adı/sürüm değiştiyse (özellikle sık güncellenen depolarda) → indeksteki eski dosya adı artık sunucuda yok → indirme **404**.
- Güvenlik güncellemesi çıkmışsa → eski sürümü kurarsın.

Bu yüzden kalıp: `sudo apt update && sudo apt install ...`.

**Depo yönetimi.** Depolar `deb <URL> <sürüm> <bileşenler>` satırlarıyla tanımlanır (`main`, `contrib`, `non-free`, `non-free-firmware`). **Debian 13 (trixie) artık `deb822` biçimini** varsayılan kullanıyor: tek satırlık `sources.list` yerine `/etc/apt/sources.list.d/debian.sources` içinde anahtar-değer blokları (`Types:`, `URIs:`, `Suites:`, `Components:`, `Signed-By:`). Eski tek satır biçimi en az 2029'a kadar destekleniyor; `apt modernize-sources` ile dönüştürülür. Üçüncü parti depolar `/etc/apt/sources.list.d/` altına **ayrı dosya** + ayrı GPG imza anahtarı (`Signed-By:` / `/etc/apt/keyrings/`) olarak eklenir — imza doğrulaması, deponun gerçekten o proje tarafından yayınlandığını garanti eder.

> [!NOTE]
> **`apt` ↔ `apt-get`: `apt-get` (ve `apt-cache`) betikler için kararlı, ayrıntılı arayüzdür. `apt` insan kullanımı için daha derli toplu çıktı + ilerleme çubuğu verir. Günlük elle kullanımda `apt`, otomasyon/script'te `apt-get` tercih edilir.**

### 11. Kısa komutlar: `rm`, `touch`, `mkdir`, `logout`, `set`, `tmux`, `alias`

**`rm` — ve neden `-rf` alışkanlığı bırakılmalı.** `rm` bir dosyayı "silmez", **`unlink()`** syscall'ı ile dizindeki bağını (link) kaldırır; son bağ ve dosyayı açık tutan süreç kalmayınca çekirdek alanı boşa çıkarır (inode mantığı: `bkz.` [Gün 3](Gün%203.md)). **Geri dönüşüm kutusu yoktur** — grafiksel dosya yöneticisinin "çöp kutusu" bir masaüstü özelliğidir, `rm`'de yok. Parametreler: `-r` (recursive — dizin ve içi), `-f` (force — onay sorma, olmayan dosyaya hata verme), `-i` (her dosya için sor). `rm -rf` bu ikisini birleştirir: **hızlı ama affetmez**. Riskler: değişken boşsa `rm -rf "$DIR"/` → `rm -rf /`; yanlış yol; joker (`*`) beklenmedik eşleşme. GNU `rm` **`--preserve-root`'u varsayılan** uygular (coreutils 6.4'ten beri) — `rm -rf /` reddedilir, ama `rm -rf /home/*` reddedilmez. Alışkanlık önerisi: önce `ls` ile aynı yolu/joker'i gör, `-f`'i ancak gerçekten gerekince ekle, kritik yollarda `--one-file-system` (mount sınırını geçme) kullan, mümkünse `-i` veya `trash-cli`.

**`touch`.** İki iş yapar: (a) dosya yoksa **boş dosya oluşturur** (`open(O_CREAT)`), (b) dosya varsa **erişim/değiştirme zaman damgalarını** `utimensat()` ile günceller (varsayılan: şimdi; `-d`, `-t`, `-r` ile başka zaman). Kullanım: hızlıca boş dosya, bir dosyayı "yeniymiş gibi" göstermek (Make gibi zaman-damgası bakan araçlar için), `touch /forcefsck` gibi tetikleyiciler.

**`mkdir`.** Dizin oluşturur (`mkdir()` syscall). `-p` → ara dizinleri de oluştur ve zaten varsa hata verme (`mkdir -p a/b/c`). `-m` → oluştururken izin ver (`mkdir -m 700 gizli`). `-p` betiklerde "varsa dokunma, yoksa yarat" için idealdir.

**`logout`.** Yalnızca bir **login shell**'i sonlandıran kabuk builtin'idir (giriş yaptığın ilk kabuk — TTY veya SSH oturumu). Login olmayan bir kabukta `logout` "not login shell" hatası verir; orada `exit` kullanılır. Pratikte çoğu zaman `exit` ile aynı sonuç.

**`set`.** Kabuk builtin'i, iki işi var: (a) **kabuk seçeneklerini** açıp kapatmak — `set -e` (bir komut hata verirse betiği durdur), `set -u` (tanımsız değişken kullanımı hata), `set -x` (çalıştırılan her komutu yaz — betik hata ayıklama), `set -o pipefail` (pipe'ta herhangi bir aşama hata verirse tüm pipe hatalı sayılsın). Sağlam betiklerin başında `set -euo pipefail` sık görülür. (b) Argümansız `set` → o anki **tüm kabuk değişkenlerini ve fonksiyonlarını** listeler; ayrıca konumsal parametreleri (`$1`, `$2`…) ayarlar.

**`tmux` (terminal multiplexer).** Bir **sunucu-istemci** mimarisiyle çalışır: `tmux` ilk çalıştığında bir arka plan **sunucusu** başlatır (`/tmp` altında bir soket), pencereni ona bir **istemci** olarak bağlar. Oturumlar, pencereler ve panolar (bölünmüş görünümler) sunucuda yaşar; **istemci koparsa (SSH düşerse, `Ctrl-b d` ile ayrılırsan) sunucu çalışmaya devam eder** — içindeki kabuklar, süreçler, açık dosyalar durmaz. Sonra `tmux attach` ile geri bağlanıp kaldığın yerden devam edersin. Neden: uzun süren bir işi (derleme, yedek, göç) SSH bağlantısının ömrüne bağlı olmaktan kurtarmak; tek terminalde çok bölme. Eski muadili `screen`; `tmux` daha modern ve yapılandırılabilir.

**`alias`.** Bir kelimeyi başka bir komut dizisiyle değiştiren kabuk kısayolu: `alias ll='ls -alF'`, `alias ..='cd ..'`. Yalnızca **etkileşimli kabuğun o oturumunda** geçerlidir; kalıcı olması için `~/.bashrc`'ye yazılır. `unalias ll` kaldırır; başında `\` ile (`\ls`) alias'ı atlayıp gerçek komutu çalıştırırsın; `alias` (argümansız) tanımlı tüm alias'ları listeler. Not: alias basit metin değiştirmedir, argüman alamaz — bunun için kabuk **fonksiyonu** gerekir.

### Kaynaklar

Kaynaklar konu başlıklarına göre gruplandı. SSH protokol katmanları ve temel komut sözdizimi uzun süredir sabit RFC/man page bilgisidir; dağıtım varsayılanları (Debian 13 socket activation, deb822, preset politikaları, `ssh-keygen` varsayılan anahtarı) 2026-08'de ayrıca doğrulandı.

- **SSH protokol mimarisi / `ssh` ↔ `sshd` / kurulum:**
  - [RFC 4251 — SSH Protocol Architecture](https://www.rfc-editor.org/rfc/rfc4251) + [RFC 4253 — Transport Layer](https://datatracker.ietf.org/doc/html/rfc4253) — üç katman, 1 GB / 1 saat anahtar yenileme
  - [OpenSSH/SSH Protocols — Wikibooks](https://en.wikibooks.org/wiki/OpenSSH/SSH_Protocols) (ikincil — katman özeti)
  - [Debian trixie — openssh-server paket sayfası](https://packages.debian.org/trixie/openssh-server) — sürüm `1:10.0p1`, `openssh-client` + `openssh-sftp-server` + `libssl3` + `libpam` bağımlılıkları
- **Bağlantı anı / host key / TOFU / `ssh -v`:**
  - [Understanding known_hosts and Host Key Verification: TOFU — dev.to](https://dev.to/mahafuz/understanding-knownhosts-and-host-key-verification-what-it-protects-against-and-how-tofu-works-pid) (ikincil) + [Dealing with SSH Host Key Changes — PSU CAT](https://cat.pdx.edu/platforms/linux/remote-access/dealing-with-ssh-host-key-changes/) — "REMOTE HOST IDENTIFICATION HAS CHANGED", MITM ile ilişki
  - birincil: `man ssh` / `man sshd` (StrictHostKeyChecking, known_hosts biçimi)
- **SSH dizin/dosyaları:**
  - `man sshd` "FILES" ve "AUTHORIZED_KEYS FILE FORMAT" bölümleri; `man ssh_config` — `~/.ssh/` ve `/etc/ssh/` içerikleri, `StrictModes`
- **`ssh_config` ↔ `sshd_config`:**
  - [ssh_config(5) — man7.org](https://man7.org/linux/man-pages/man5/ssh_config.5.html) ve [sshd_config(5) — man7.org](https://man7.org/linux/man-pages/man5/sshd_config.5.html) — istemci öncelik sırası (komut satırı > `~/.ssh/config` > `/etc/ssh/ssh_config`)
- **PKI / anahtarlar / `ssh-keygen` / `ssh-copy-id`:**
  - [ssh-keygen(1) — man7.org](https://man7.org/linux/man-pages/man1/ssh-keygen.1.html)
  - [Using Ed25519 for OpenSSH keys — Linux Audit](https://linux-audit.com/ssh/using-ed25519-openssh-keys-instead-of-dsa-rsa-ecdsa/) (ikincil) — OpenSSH 9.5'ten beri Ed25519 varsayılan; öncesinde RSA
  - [SSH Agent Explained — smallstep](https://smallstep.com/blog/ssh-agent-explained/) (ikincil) — agent, challenge-response akışı
- **Port yönlendirme / agent forwarding / X11:**
  - [SSH Tunnel: Local, Remote, and Dynamic Port Forwarding — Linuxize](https://linuxize.com/post/how-to-setup-ssh-tunneling/) (ikincil) + birincil `man ssh` (`-L`, `-R`, `-D`)
  - [The Hidden Risks of SSH Agent Forwarding — Medium](https://medium.com/@bornaly/the-hidden-risks-of-ssh-agent-forwarding-and-how-i-avoid-them-d7abff54f567) ve [SSH Agent Explained — smallstep](https://smallstep.com/blog/ssh-agent-explained/) — soket ele geçirme, `ProxyJump` önerisi
  - [What You Need to Know About X11 Forwarding — Teleport](https://goteleport.com/blog/x11-forwarding/) (ikincil) — `-X` güvensiz / `-Y` güvenilir, `xauth`
- **scp / sftp / rsync / sshfs:**
  - [OpenSSH 9.0 sürüm notları](https://www.openssh.com/txt/release-9.0) — `scp` artık varsayılan SFTP protokolü, `-O` ile eski protokol
  - [OpenSSH SCP deprecation in RHEL 9 — Red Hat Blog](https://www.redhat.com/en/blog/openssh-scp-deprecation-rhel-9-what-you-need-know) (ikincil)
  - [Understanding rsync, Rolling Checksums — cfischer.io](https://blog.cfischer.io/understanding-rsync-rolling-checksums-and-efficient-data-transfer/) (ikincil) + birincil `man rsync` — delta-transfer, rolling checksum
  - [SSHFS: Mounting a remote file system over SSH — Red Hat Blog](https://www.redhat.com/en/blog/sshfs) + [libfuse/sshfs — GitHub](https://github.com/libfuse/sshfs) — FUSE, her işlem = SFTP isteği, sunucuda ek yazılım yok
- **`dd`:**
  - `man dd` (`if`, `of`, `bs`, `count`, `status=progress`, `conv=fsync`)
  - [dd — Forensics Wiki](https://forensics.wiki/dd/) (ikincil) — bit-bit kopya, `if`/`of` ters yazma riski
- **Servis otomatik başlaması (Debian ↔ RHEL):**
  - [systemd Presets — systemd.io](https://systemd.io/PRESET/) — "Debian'da tüm servisler varsayılan enable; Fedora'da varsayılan disable"
  - [systemd.preset(5) — Debian trixie manpages](https://manpages.debian.org/trixie/systemd/systemd.preset.5.en.html) — `enable`/`disable`/`ignore` direktifleri, `systemctl preset` postinst'te
- **`apt update` / depo yönetimi / deb822:**
  - [apt-get(8) — Ubuntu manpage](https://manpages.ubuntu.com/manpages/focal/man8/apt-get.8.html) ve [Ubuntu Server — package management](https://ubuntu.com/server/docs/how-to/software/package-management/) — `update` indeksleri tazeler, install'dan önce şart
  - [SourcesList — Debian Wiki](https://wiki.debian.org/SourcesList) + [How To Migrate To deb822 Format In Debian 13 — OSTechNix](https://ostechnix.com/migrate-to-deb822-format-debian-13-trixie/) (ikincil) — Debian 13 varsayılan `.sources`, `apt modernize-sources`, eski biçim ~2029'a kadar
- **Kısa komutlar:**
  - [GNU Coreutils — rm invocation](https://www.gnu.org/software/coreutils/manual/html_node/rm-invocation.html) + [rm (Unix) — Wikipedia](https://en.wikipedia.org/wiki/Rm_-rf_*) (ikincil) — `unlink()`, `--preserve-root` varsayılan (coreutils 6.4+), `--one-file-system`
  - `man touch`, `man mkdir`, `help set` / `man bash` (SHELL BUILTIN COMMANDS, `set -euo pipefail`), `help logout`, `help alias`
  - [tmux(1) — man7.org](https://man7.org/linux/man-pages/man1/tmux.1.html) + [tmux.app](https://tmux.app/) (ikincil) — sunucu-istemci, `/tmp` soketi, detach/attach kalıcılığı

Tekil bayrak/sözdizimi bilgileri (`ssh -L a:b:c`, `rsync -avz`, `rm -r`, `mkdir -p`, `dd if= of=`) ilgili `man` sayfalarıyla doğrulanabilir; bunlar için ayrıca kaynak verilmedi.

## Notlar

- **SSH tek bir şifreli tünel, üstünde birçok kanal.** Kabuk oturumu, port yönlendirmeleri (`-L`/`-R`/`-D`), agent forwarding ve X11 — hepsi aynı TCP:22 bağlantısının içinde ayrı mantıksal kanallardır (RFC 4254). "SSH taklaları" dediğimiz şey aslında bu bağlantı katmanının doğal sonucu.
- **SSH'ın güven modeli PKI değil, TOFU.** Sunucu kimliği `known_hosts`'a ilk bağlantıda sabitlenir; sonraki uyuşmazlık **bağlantıyı komple reddettirir** çünkü bu bir MITM'in göründüğü şeydir. "authenticity of host…" uyarısında parmak izini gerçekten doğrulamadan `yes` demek, korumayı kapatmaktır.
- **Anahtar > parola.** Açık anahtar kimlik doğrulamada özel anahtar ağa hiç çıkmaz; passphrase + `ssh-agent` ile hem güvenli hem pratik olur. `ssh-copy-id` ile kurulur, ama `~/.ssh` (`700`) / `authorized_keys` (`600`) izinleri yanlışsa `sshd` sessizce reddeder (`StrictModes`).
- **Dağıtım felsefesi farkı yine karşımızda:** Debian "kurduysan çalışsın" (servisi otomatik enable+start), RHEL "sen açıkça istemeden hiçbir port açılmasın" (kurar ama başlatmaz). Aynı ayrım Gün 6–8'de systemd-resolved, rsyslog, journald kalıcılığında da görülmüştü.
- **`apt update` paket indirmez, indeks tazeler.** `apt install`'dan önce yapılmazsa "Unable to locate package" veya eski dosya adına 404 alınır. Debian 13 depo tanımını artık `deb822` (`.sources`) biçiminde tutuyor.
- **Geri alınamayan iki komut:** `rm -rf` (çöp kutusu yok) ve `dd` (onay yok, `if`/`of` ters yazımı diski siler). İkisinde de çalıştırmadan önce yolu/hedefi ayrı bir komutla (`ls`, `lsblk`) doğrulama alışkanlığı.

## Komutlar / Örnekler

```bash
# --- SSH kurulum / servis ---
sudo apt update && sudo apt install openssh-server
systemctl status ssh                 # sunucu (sshd) çalışıyor mu
sudo systemctl reload ssh            # sshd_config değişikliğinden sonra

# --- Bağlanma / teşhis ---
ssh ucp@192.168.56.101               # ilk sefer: host key doğrulama (parmak izini teyit et)
ssh -v ucp@192.168.56.101            # el sıkışma / kimlik doğrulama adımlarını göster
ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub   # sunucunun parmak izini önceden öğren
ssh-keygen -R 192.168.56.101         # known_hosts'tan kaydı sil (SADECE değişim sebebini doğruladıktan sonra)

# --- Anahtar tabanlı giriş ---
ssh-keygen -t ed25519 -C "ucp@laptop"
ssh-copy-id ucp@192.168.56.101       # açık anahtarı authorized_keys'e ekle
ssh-add ~/.ssh/id_ed25519            # anahtarı ssh-agent'a yükle

# --- SSH taklaları ---
ssh -L 8080:127.0.0.1:80  ucp@web     # yerel 8080 -> web'in localhost:80'i (tünelleme)
ssh -R 9000:127.0.0.1:3000 ucp@public # public'in 9000'i -> benim localhost:3000 (ters tünel)
ssh -D 1080 ucp@web                   # yerelde SOCKS proxy
ssh -J bastion ucp@ic-sunucu          # ProxyJump — agent forwarding'e tercih et
ssh -X ucp@web xclock                 # X11 forwarding (güvensiz mod)

# --- Dosya aktarımı ---
scp dosya.txt ucp@web:/tmp/                     # tek seferlik kopya
sftp ucp@web                                    # etkileşimli oturum (get/put)
rsync -avz --delete ./site/ ucp@web:/var/www/   # delta ile eşitle
sshfs ucp@web:/var/www ~/mnt                    # uzak dizini yerel gibi mount et
fusermount -u ~/mnt                             # sshfs mount'unu çöz

# --- dd (DİKKAT: lsblk ile hedefi iki kez doğrula) ---
lsblk
sudo dd if=debian-13.iso of=/dev/sdX bs=4M status=progress conv=fsync
sudo dd if=/dev/sda of=~/mbr.img bs=512 count=1     # sadece MBR yedeği

# --- Servis (Debian otomatik başlatır; RHEL'de elle) ---
sudo systemctl enable --now <servis>    # RHEL ailesinde kurulumdan sonra gerekir

# --- Paket deposu ---
sudo apt update                         # install'dan ÖNCE
cat /etc/apt/sources.list.d/debian.sources   # Debian 13 deb822 biçimi
sudo apt modernize-sources              # eski sources.list -> deb822

# --- Kısa komutlar ---
rm -r dizin/            ;  ls dizin/     # -f'siz; önce ls ile doğrula
touch yeni.txt ; mkdir -p a/b/c
tmux new -s is    →  Ctrl-b d  →  tmux attach -t is
alias ll='ls -alF'      # kalıcı için ~/.bashrc'ye ekle
set -euo pipefail       # betik başında: hata/tanımsız değişken/pipe hatasında dur
```

## Sorular / Takip Edilecekler

- [ ] İki VM arasında `ssh-keygen` + `ssh-copy-id` ile parolasız giriş kur; sonra sunucuda `~/.ssh` iznini `777` yapıp tekrar bağlan — `sshd`'nin `StrictModes` nedeniyle anahtarı reddedip parolaya düştüğünü `ssh -v` çıktısında gözlemle.
- [ ] `known_hosts`'tan bir sunucunun satırını elle boz, bağlanmayı dene, "REMOTE HOST IDENTIFICATION HAS CHANGED" çıktısını gör; sonra `ssh-keygen -R` ile temizleyip yeniden kabul et.
- [ ] `ssh -L 8080:127.0.0.1:3306 ucp@192.168.56.102` ile Gün 8'deki MariaDB'ye kendi makinenden `mysql -h 127.0.0.1 -P 8080` ile bağlan — veritabanı yalnız `192.168.56.102`'yi dinlerken tünel üzerinden erişebildiğini doğrula (`bkz.` [Gün 8#Uygulamalı Örnek — İki sunuculu WordPress (Apache + PHP ⟷ uzak MariaDB)](Gün%208.md#uygulamalı-örnek-iki-sunuculu-wordpress-apache-php-uzak-mariadb)).
- [ ] Aynı dosyayı bir kez `scp`, bir kez `rsync` ile kopyala; sonra dosyanın küçük bir kısmını değiştirip ikisini tekrar çalıştır — `rsync`'in çok daha az veri gönderdiğini `--stats` / `-v` ile karşılaştır.
- [ ] Bir Rocky/RHEL VM'de bir servis paketi kur (`dnf install httpd`), `systemctl status httpd` ile kurulu ama **inactive/disabled** olduğunu gör; `systemctl enable --now httpd` sonrası farkı gözlemle. Aynısını Debian'da `apt install apache2` ile yapıp Debian'ın otomatik başlattığını doğrula.
- [ ] `apt update` yapmadan bilerek eski bir indeksle yeni bir paket kurmayı dene; "Unable to locate package" veya 404'ü gör, sonra `apt update` ile düzelt.
