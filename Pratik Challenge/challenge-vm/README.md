# Pratik Challenge — Uygulama VM'i

Bu klasör sana, [Sorular.md](../Sorular.md)'daki görevleri çözeceğin **tek kullanımlık
bir Debian 13 sanal makinesi** kurar: önceki sistem yöneticisinden kalma dağınık bir
ev dizini + bilerek bozuk bırakılmış çalışan bir sunucu. Hazır imaj indirmiyorsun;
VM senin önünde sıfırdan kuruluyor, hiçbir görev çözülmemiş hâlde.

Takılırsan [Cevaplar.md](../Cevaplar.md)'a bak.

---

## Kurulum — iki yoldan birini seç

### Yol 1 — VirtualBox (tek komut, en kolay)

Bilgisayarında **VirtualBox 7.x** ve **`sshpass`** varsa, bu klasörde:

```bash
bash provision.sh
```

~10 dakikada `Debian-Challenge` adlı bir VM kurar ve görev senaryosunu içine yerleştirir.
Bitince bağlan:

```bash
ssh -p 2224 ogrenci@127.0.0.1        # parola: ogrenci123
```

### Yol 2 — Proxmox / KVM / VMware / kendi Debian makinen

Elinde başka bir sanallaştırma platformu (Proxmox vb.) veya boş bir Debian makinesi varsa:

1. **Bir Debian 13 (trixie) VM kur:**
   - 2 GB RAM, 2 vCPU
   - **Disk 1:** ~20 GB — mümkünse **SATA/SCSI** bara (Bölüm L1 metni `/dev/sda` varsayar)
   - **Disk 2:** ~1–2 GB, **boş** — bölümleme/format **yapma** (Bölüm C ve D4 bunu kullanır)
   - Ağ: internete çıkabilen köprü
   - Kurulum sırasında yazılım seçiminde **"standard system utilities" + "SSH server"** işaretli olsun
2. **Bu `challenge-vm/` klasörünü VM'in içine al** (repoyu klonla ya da klasörü kopyala).
3. **VM'in içinde, root olarak çalıştır:**

   ```bash
   sudo bash prepare_vm.sh
   ```

   Bu script `ogrenci` kullanıcısını (parola `ogrenci123`) açar, gerekli paketleri kurar,
   ikinci diski kontrol eder, sonra görev senaryosunu `ogrenci` olarak kurar. Sonunda
   bağlantı satırını yazar:

   ```bash
   ssh ogrenci@<VM-IP>                 # parola: ogrenci123
   ```

> İkinci diski henüz eklemediysen `prepare_vm.sh` seni uyarır ama durmaz — diski sonra
> ekleyip script'i tekrar çalıştırabilirsin. Bölüm C/D dışındaki her şey ikinci disk
> olmadan da çalışır.

---

## Bağlandıktan sonra

- Görevler: **[../Sorular.md](../Sorular.md)** — Bölüm A'dan başla, sırayla ilerle.
- Kontrol: **[../Cevaplar.md](../Cevaplar.md)**
- Senaryo `~/gorev/` altında. Bölüm A–F: dosya/bilgi avı. Bölüm G–L: "bozuğu bul, düzelt, doğrula".

## Sıfırlamak / bir bölümü tekrar denemek

VM'in içinde, `ogrenci` olarak:

```bash
bash ~/setup_gorev.sh
```

Idempotenttir: `~/gorev/` her seferinde sıfırdan kurulur; Bölüm G–L'nin servis / cron /
firewall / `hosts` / `sshd` ayarları her çalıştırmada baştaki (bozuk) hâline döner.
Diskler/bölümlemeler buna dahil değil — onları `umount` edip bölümü silerek geri alırsın.

---

## Kimlik bilgileri

`ogrenci`/`ogrenci123`, `raportor`/`raportor123` (Bölüm F), `sshtest`/`sshtest123`
(Bölüm K) — hepsi **yalnızca bu alıştırma için** üretilmiş genel parolalardır, gerçek
hiçbir bilgi içermez. Üretimde asla böyle parola kullanma.

## Kendini kilitleme

Bölüm I ve K'daki firewall/SSH görevleri erişimini **kesmez** — nftables kuralı yalnız
`tcp/8080`'i, `sshd` ayarı yalnız `PermitRootLogin`'i hedefler. Yine de `nft flush ruleset`
gibi topyekûn komutlardan kaçın; sadece `inet gorev_fw` tablosuyla uğraş. Bir şey ters
giderse VM'i kapatıp açmak çoğu şeyi, `bash ~/setup_gorev.sh` senaryonun tamamını sıfırlar.

---

<sub><b>Bakımcı notu.</b> Üç script var: <code>provision.sh</code> yalnız VirtualBox
içindir (<code>VBoxManage unattended</code> ile sıfırdan VM kurar). <code>prepare_vm.sh</code>
platformdan bağımsızdır; hâlihazırda kurulu bir Debian'a <code>ogrenci</code> kullanıcısı +
paketler ekleyip senaryoyu kurar. <code>setup_gorev.sh</code> ikisinin de çağırdığı,
asıl <code>~/gorev/</code> senaryosunu kuran ortak script'tir — Debian + systemd + python3 +
<code>ogrenci</code> kullanıcısı dışında bir şey varsaymaz, o yüzden herhangi bir Debian
kutusunda elle de çalıştırılabilir.</sub>
