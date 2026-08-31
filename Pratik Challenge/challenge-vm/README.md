# Challenge VM Kurulumu

Bu klasördeki betikler, [Sorular.md](../Sorular.md) içindeki görevlerin (Bölüm A–L, Gün 1–9) çözüleceği, tek amaçlı, izole bir Debian 13 sanal makinesini **sıfırdan, çözülmemiş** haliyle senin bilgisayarında kurar. Hazır bir disk imajı indirmiyorsun — makine kendi bilgisayarında, senin önünde inşa ediliyor.

## Gereksinimler

- VirtualBox 7.x
- `sshpass` (kurulumu doğrulamak ve görev senaryosunu makineye kopyalamak için)
- ~800MB internet (Debian netinst paketleri + ek paketler: `acl`, `xxd`, `plocate`, `curl`, `cron`, `logrotate`, `nftables`, `ipcalc`, `netcat`, `bind9-dnsutils`, `whois`, `rsync`, `tmux`)
- ~8-12 dakika (çoğunlukla bekleme)

## Kurulum

```bash
bash provision.sh
```

Script sırasıyla:
1. Debian 13 netinst ISO'sunu indirir (yoksa)
2. `Debian-Challenge` adında yeni bir VM oluşturur (2048MB RAM, 4 CPU, 20GB birincil disk)
3. `debian_preseed.tpl` ile tamamen otomatik (unattended), headless bir kurulum yapar
4. Kurulum bitince VM'i kapatıp ~1.2GB **boş, biçimlendirilmemiş** bir ikinci disk ekler (Bölüm C/D'nin disk/mount görevleri için)
5. `setup_gorev.sh`'yi makineye kopyalayıp çalıştırarak `~/gorev/` altındaki çözülmemiş görev senaryosunu kurar. Bu adım:
   - **Bölüm A–F (Gün 1–5):** dağınık ev dizini, gerekli paketler (`acl`, `xxd`, `plocate`, `curl`), bir servis hesabı (`yedekleme`), kısıtlı-sudo'lu `raportor`/`raportor123`, `8080` portunda `gorev-web.service`
   - **Bölüm G–L (Gün 6–9):** bilerek bozuk operasyonel durum —
     - `gorev-hog.service` (CPU yiyen kaçak süreç), `gorev-zombi.service` (zombi bırakan parent), `gorev-rapor.service` (dizin eksikliğinden `failed`), `gorev-bakim.service` (`masked`), `gorev-hatali.service` (boot'ta journald'e `err` yazar)
     - `/etc/cron.d/gorev-rapor` (yanlış betik yolu), `/var/log/gorev-app.log` (rotasyonsuz, ~2MB)
     - `gorev-fw.service` — `inet gorev_fw` nftables tablosuyla **sadece `tcp/8080`'i** DROP eder (SSH'a dokunmaz)
     - `gorev-api.service` (`127.0.0.1:8090`) + `/etc/hosts`'ta `api.local.gorev` için **yanlış** IP
     - `sshtest`/`sshtest123` hesabı + `/etc/ssh/sshd_config.d/60-gorev.conf` (`PermitRootLogin yes`)
     - `/etc/apt/sources.list.d/gorev-ekstra.list` (çözülemeyen depo URL'si)

## Bağlantı

```bash
ssh -p 2224 ogrenci@127.0.0.1
# şifre: ogrenci123
```

> [!NOTE]
> **`ogrenci` / `ogrenci123`, bu challenge için üretilmiş genel bir pratik parolasıdır** — gerçek/kişisel hiçbir bilgi içermez, VM'i kendi bilgisayarında kurduğunda bu kimlik bilgileri sende de aynı olacak. Aynı şekilde `raportor` / `raportor123` (Bölüm F) ve `sshtest` / `sshtest123` (Bölüm K) hesapları da sadece bu görev için üretilmiştir. Üretim ortamında asla böyle parolalar kullanma.

> [!WARNING]
> Bölüm I ve K'daki firewall/`sshd` görevleri **`2224` üzerinden SSH erişimini kesmez** — nftables kuralı yalnızca `tcp/8080`'i, `sshd` drop-in'i yalnızca `PermitRootLogin`'i hedefler. Kendini kilitlememek için `nft flush ruleset` gibi topyekûn komutlardan kaçın; sadece `inet gorev_fw` tablosunu hedefle. Bir şey ters giderse VM'i VirtualBox'tan kapatıp açmak `gorev-fw` kuralı dışında çoğu şeyi sıfırlar, `bash setup_gorev.sh` ise senaryoyu baştan kurar.

## Sıfırdan tekrar denemek istersen

```bash
VBoxManage unregistervm "Debian-Challenge" --delete
bash provision.sh
```

Sadece `~/gorev/` senaryosunu (diskler/bölümlemeler dahil değil) baştan kurmak için, VM içinde:
```bash
bash setup_gorev.sh
```

`setup_gorev.sh` idempotenttir — tekrar tekrar çalıştırılabilir. `~/gorev/` her seferinde sıfırdan kurulur; kullanıcı hesapları/paketler zaten varsa dokunulmadan geçilir; Bölüm G–L servisleri, cron/log/hosts/sshd/apt değişiklikleri her çalıştırmada bilerek-bozuk başlangıç durumuna geri alınır (çözdüğün bir bölümü tekrar denemek istersen script'i yeniden çalıştır).
