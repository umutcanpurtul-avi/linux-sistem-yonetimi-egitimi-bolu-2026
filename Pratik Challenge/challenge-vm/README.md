# Challenge VM Kurulumu

Bu klasördeki betikler, [Sorular.md](../Sorular.md) içindeki görevlerin çözüleceği, tek amaçlı, izole bir Debian 13 sanal makinesini **sıfırdan, çözülmemiş** haliyle senin bilgisayarında kurar. Hazır bir disk imajı indirmiyorsun — makine kendi bilgisayarında, senin önünde inşa ediliyor.

## Gereksinimler

- VirtualBox 7.x
- `sshpass` (kurulumu doğrulamak ve görev senaryosunu makineye kopyalamak için)
- ~500MB internet (Debian netinst paketleri için)
- ~5-10 dakika (çoğunlukla bekleme)

## Kurulum

```bash
bash provision.sh
```

Script sırasıyla:
1. Debian 13 netinst ISO'sunu indirir (yoksa)
2. `Debian-Challenge` adında yeni bir VM oluşturur (2048MB RAM, 4 CPU, 20GB birincil disk)
3. `debian_preseed.tpl` ile tamamen otomatik (unattended), headless bir kurulum yapar
4. Kurulum bitince VM'i kapatıp ~1.2GB **boş, biçimlendirilmemiş** bir ikinci disk ekler (Bölüm C/D'nin disk/mount görevleri için)
5. `setup_gorev.sh`'yi makineye kopyalayıp çalıştırarak `~/gorev/` altındaki çözülmemiş görev senaryosunu kurar

## Bağlantı

```bash
ssh -p 2224 ogrenci@127.0.0.1
# şifre: ogrenci123
```

> [!NOTE]
> **`ogrenci` / `ogrenci123`, bu challenge için üretilmiş genel bir pratik parolasıdır** — gerçek/kişisel hiçbir bilgi içermez, VM'i kendi bilgisayarında kurduğunda bu kimlik bilgileri sende de aynı olacak. Üretim ortamında asla böyle bir parola kullanma.

## Sıfırdan tekrar denemek istersen

```bash
VBoxManage unregistervm "Debian-Challenge" --delete
bash provision.sh
```

Sadece `~/gorev/` senaryosunu (diskler/bölümlemeler dahil değil) baştan kurmak için, VM içinde:
```bash
bash setup_gorev.sh
```
