---
tarih: 2026-08-20
durum: "Debian doğrulandı ✅ | Ubuntu vazgeçildi (4 deneme, VirtualBox Guest Additions kısıtı) ❌"
tags: [linux-egitimi, virtualbox, ubuntu, debian, sanallastirma]
---

# VirtualBox ve Sanal Makine Kurulumu

Eğitim ön-şartı: *"VirtualBox sanallaştırma ortamının kurulması"* ve *"Rocky Linux, Debian, Ubuntu, Pardus dağıtımlarının en az birinin minimum paketlerle (grafik arayüz olmadan) sanal makine olarak kurulması"* maddeleri kapsamında yapılan çalışmanın notları.

## Ortam

- Host: CachyOS Linux (Arch tabanlı), çekirdek `7.1.8-1-cachyos`
- VirtualBox: **7.2.16** (pacman `extra` deposu)
- Host CPU: AMD, SVM (AMD-V) aktif, `/dev/kvm` mevcut
- 14 GB RAM, ~308 GB boş disk

## Kurulan paketler

```
pacman -S virtualbox virtualbox-host-dkms virtualbox-guest-iso sshpass
```

- `virtualbox-host-dkms`: vboxdrv çekirdek modülünü DKMS ile derler (çalışan çekirdeğe göre **reboot gerektirir**)
- `virtualbox-guest-iso`: Guest Additions ISO'su (`--install-additions` unattended kurulum seçeneği için gerekli)
- Kurulum kullanıcı `vboxusers` grubuna eklendi (`usermod -aG vboxusers`); ayrıca VirtualBox'ın `VBoxHeadless`/`VirtualBoxVM` binary'leri setuid-root olduğundan grup üyeliği aktifleşmeden de VM başlatılabildi.

⚠️ Not: `pacman -Syu` sırasında sistemin geri kalanı da güncellendi ve bu `snapper` aracını (libboost sürüm uyuşmazlığı) kırdı — VirtualBox kurulumuyla ilgisiz, ayrı bir bakım gerektirir.

## VM'ler

| VM Adı                   | Dağıtım                           | RAM     | CPU | Disk        | Ağ  | SSH (host→guest)                |
| ------------------------ | --------------------------------- | ------- | --- | ----------- | --- | ------------------------------- |
| **Ubuntu-Server-Egitim** | Ubuntu Server 24.04.3 LTS (Noble) | 2048 MB | 2   | 20 GB (VDI) | NAT | `ssh -p 2222 egitmen@127.0.0.1` |
| **Debian-Egitim**        | Debian 13.6.0 (Trixie) netinst    | 2048 MB | 4   | 20 GB (VDI) | NAT | `ssh -p 2223 egitmen@127.0.0.1` |

- Kullanıcı: `egitmen` / Şifre: `<GÜÇLÜ_BİR_ŞİFRE>` (sudo yetkili)
- **Debian tamamen doğrulandı**: SSH çalışıyor, GUI paketi (gnome-shell, xserver-xorg-core, plasma, xfce) **yok**, `temiz-kurulum` snapshot'ı alındı.
- **Ubuntu**: 4 otomatik kurulum denemesinden sonra vazgeçildi (bkz. aşağıdaki "Ubuntu neden yarım kaldı" bölümü). VM kayıtlı ama **kapalı** bırakıldı; kurs şartı zaten Debian ile karşılandığından zorunlu değil.
- Dosyalar: `~/VMs/` (ISO'lar `~/VMs/isos/`, diskler `~/VMs/disks/`, VM tanımları `~/VMs/<VM adı>/`)
- Her iki ISO'nun SHA256 checksum'ı resmi kaynaklarla doğrulandı.
- Ayrıntılı rapor: `~/VMs/KURULUM_RAPORU.md`

## Kurulum yöntemi: VBoxManage unattended install

Manuel/interaktif kurulum yerine `VBoxManage unattended install` (autoinstall/preseed) kullanıldı — headless, tamamen otomatik:

```
VBoxManage unattended install "<VM adı>" --iso=<iso yolu> \
  --user=egitmen --user-password=<GÜÇLÜ_BİR_ŞİFRE> --full-user-name="Egitmen" \
  --hostname=<hostname> --locale=tr_TR --time-zone=Europe/Istanbul \
  --package-selection-adjustment=minimal --install-additions \
  --script-template=<özel şablon> --start-vm=headless
```

### Karşılaşılan sorunlar ve çözümleri

1. **Debian'a yanlışlıkla GNOME masaüstü kuruldu.** VirtualBox'ın varsayılan Debian preseed şablonunda `--package-selection-adjustment=minimal` seçeneği `tasksel`'i hiç etkilemiyor; Debian installer varsayılan olarak "Debian desktop environment" görevini seçiyor. **Çözüm:** özel preseed şablonuna `tasksel tasksel/first multiselect standard` satırı eklendi (bkz. `~/VMs/templates/debian_preseed.tpl`), VM sıfırdan yeniden kuruldu → GNOME'suz, minimal, doğrulandı.

2. **Ubuntu'da SSH şifre kimlik doğrulaması sürekli reddedildi ("Permission denied").** Kök neden: Ubuntu'nun autoinstall/cloud-init mekanizmasında `egitmen` kullanıcısı **kurulum sırasında değil, VM'in gerçek ilk açılışında** cloud-init tarafından oluşturuluyor. İlk düzeltme denemesi bu şifre komutunu `late-commands` içine (kurulum sırasında, kullanıcı henüz yokken) koyduğu için kurulumu çökertti ("curtin in-target ... chpasswd" exit 1 → installer hata ekranında kilitlendi). **Çözüm:** düzeltme cloud-init'in `runcmd:` bölümüne taşındı (gerçek ilk açılışta, kullanıcı oluşturulduktan SONRA çalışır) — bkz. `~/VMs/templates/ubuntu_user_data.tpl`. Ayrıca `ssh: {install-server: true, allow-pw: true}` ve `chpasswd: {expire: false}` eklendi.

   Teşhis için VirtualBox ekran görüntüsü (`VBoxManage controlvm ... screenshotpng`) ve klavye enjeksiyonu (`keyboardputstring`/`keyboardputscancode`) kullanılarak kurulumcunun acil kurtarma kabuğuna girilip `/target/etc/passwd` doğrudan incelendi — bu, SSH/guestcontrol hiçbiri çalışmadığında en güvenilir teşhis yöntemi oldu.

3. **Reboot sonrası `vboxdrv` yüklenmedi.** `pacman -Syu` çekirdeği yükseltti ama sistem eski çekirdekte çalışmaya devam ediyordu; DKMS modülü yeni çekirdek için derlenmişti. Kullanıcının kendisi reboot attıktan sonra sorun kalktı.

4. Yeniden kurulan her VM için önce `VBoxManage controlvm <vm> poweroff` + `VBoxManage unregistervm <vm> --delete` ile eski VM/disk tamamen temizlendi, sonra `createvm`/`createmedium`/`storagectl`/`storageattach` ile sıfırdan oluşturuldu.

5. **4. denemede Ubuntu'dan tamamen vazgeçildi.** `runcmd` düzeltmesi doğru çalıştı ama bu sefer **VirtualBox'ın kendi Guest Additions kurulum betiği** (`vboxpostinstall.sh`, `--install-additions` seçeneğiyle tetikleniyor) kurulum-anı `chroot` ortamında çöktü: script `/proc/modules`'a erişmeye çalışıyor ama kurulum chroot'unda `/proc` düzgün bağlı değil (`kmod_module_new_from_loaded: could not open /proc/modules`, exit code 1) — bu VirtualBox 7.2.16'nın kendi Ubuntu autoinstall şablonunun bir kısıtı, eklenen özel kodla ilgisi yok. Teşhis, `chroot /target /bin/bash /root/vboxpostinstall.sh --direct` komutu ekran görüntüsü + klavye enjeksiyonuyla manuel çalıştırılarak yapıldı. Kullanıcı isteği üzerine 5. bir deneme yapılmadı, VM kapalı bırakıldı.

## Özel şablonlar

Varsayılan VirtualBox şablonlarının kopyaları, düzeltmelerle:
- `~/VMs/templates/ubuntu_user_data.tpl`
- `~/VMs/templates/debian_preseed.tpl`

## Snapshot'lar

Doğrulanan her VM için `temiz-kurulum` adında bir snapshot alınıyor — ileride bir şey bozulursa oradan geri dönülebilir:
```
VBoxManage snapshot "<VM adı>" restore "temiz-kurulum"
```

## Neden minimal/GUI'siz kurulum?

Kursun içeriği (kabuk, paket yönetimi, süreç/servis yönetimi, LAMP/LEMP'i sıfırdan kurmak, SSH ile uzaktan erişim) zaten GUI'siz sunucu yönetimi pratiğini hedefliyor. Masaüstü ortamının olmaması hiçbir ders konusunu engellemiyor; gerçek sunucu ortamlarının standart hali de zaten böyle.
