# DESIGN.md: Spesifikasi & Pedoman Desain ViDric

Dokumen ini memuat spesifikasi desain visual, tata letak antarmuka (*UI/UX Layout*), dan panduan komponen aplikasi **ViDric (Virtual Driving Controller)** yang disusun berdasarkan wireframe dan mockup resmi dari pengguna.

---

## 1. Identitas Produk & Karakter Visual

* **Nama Produk:** ViDric (Virtual Driving Controller)
* **Kategori:** Antarmuka Pengontrol & Telemetri Game Simulasi Mengemudi PC (Multi-Mode)
* **Karakter Visual:** Modern Cockpit, Utilitarian, Presisi Tinggi, dan Ergonomis.
* **Prinsip Tampilan:** Terasa seperti dasbor instrumen kendaraan nyata dengan tekstur logam, karet anti-selip, iluminasi neon, dan tombol fisik taktil, bukan tampilan aplikasi web SaaS generik.
* **Tiga Dial Antislop:**
  * **ENERGY: 2 (Balanced):** Hidup dan berwibaba dengan warna status fungsional tanpa efek gradien ungu-biru mengambang.
  * **RHYTHM: 2 (Structured):** Tata letak instrumen kokpit teratur rapi berdasarkan jangkauan jempol tangan kiri dan kanan.
  * **MOTION: 1 (Data-Driven):** Animasi hanya didorong oleh data sentuhan pengguna (rotasi setir, injakan pedal, pegas pembalik, dan pergeseran tuas).

---

## 2. Palet Warna & Token Visual

Seluruh warna dipilih berdasarkan fungsi teknis kokpit otomotif:

| Elemen | Kode Warna (Hex) | Peruntukan / Fungsi |
| :--- | :--- | :--- |
| **Cockpit Background** | `#16202A` s/d `#1C2834` | Panel dasar kokpit gelap bernuansa Deep Slate Navy untuk kenyamanan mata. |
| **Card / Module Container** | `#22303E` | Wadah modul tombol, navigasi, dan instrumen. |
| **Interactive Button Base** | `#293B4D` | Latar tombol saat idle (Menu, Map, Camera, D-Pad). |
| **Border & Divider** | `#344A5F` | Garis pembatas fisik antar modul instrumen. |
| **Text Primary** | `#FFFFFF` | Teks utama, label tombol, dan angka derajat kemiringan. |
| **Text Secondary / Muted** | `#8FA0B2` | Teks keterangan pendukung dan deskripsi opsi. |
| **Accent Cyan / Ice Blue** | `#00E5FF` / `#40C4FF` | Iluminasi gerbang gigi shifter (1 s/d 6), mode aktif, dan indikator sudut tengah. |
| **Accent Emerald Green** | `#00E676` | Indikator `GYRO CAM : ACTIVE`, input pedal gas, dan status koneksi normal. |
| **Accent Crimson Red** | `#FF1744` | Indikator pedal rem, tuas handbrake saat aktif, dan batas kemudi ekstrem. |

---

## 3. Tata Letak Layar Kokpit Utama (Controller Cockpit)

Aplikasi memiliki dua mode kemudi utama yang dapat dipilih pemain dengan tata letak visual spesifik:

```
+---------------------------------------------------------------------------------------+
| [MENU] [MAP]                                                 [GYRO CAM: ACTIVE] (O) ⚙ |
| [CAMERA]                                                                              |
|                                                     [ H-PATTERN ]      \              |
|       ( STEERING )                                  [  SHIFTER  ]       \ HANDBRAKE   |
|         ( WHEEL )                                                                     |
|                                                      [REM]      [ GAS ]               |
|                               [ ◀ ] [ENTER] [ ▶ ]    [PEDAL]    [PEDAL]               |
|                               [ 1 ] [  2  ] [ 3 ]                                     |
+---------------------------------------------------------------------------------------+
(STEERING MODE LAYOUT)
```

```
+---------------------------------------------------------------------------------------+
| [MENU] [MAP]                                                 [GYRO CAM: ACTIVE] (O) ⚙ |
| [CAMERA] [RECENTER]                                                                   |
|                                 __________________                                    |
|                                       0.0°                                            |
|                                                                        \ HANDBRAKE    |
|   [REM]                       [ ◀ ] [ENTER] [ ▶ ]                      [ GAS ]        |
|   [PEDAL]                     [ 1 ] [  2  ] [ 3 ]                      [PEDAL]        |
+---------------------------------------------------------------------------------------+
(TILT MODE LAYOUT)
```

### 3.1 Layar `STEERING MODE` (Mode Roda Kemudi)
1. **Pojok Kiri Atas (Navigasi & Kamera):**
   * Grid tombol 2x2 dengan sudut membulat:
     * Baris 1: `[ MENU ]`, `[ MAP ]`
     * Baris 2: `[ CAMERA ]`
2. **Sisi Kiri (Roda Kemudi Fotorealistik):**
   * Menggunakan aset gambar kemudi berkualitas tinggi (`assets/images/setir1.png` / `setir2.png` / `steering_wheel_cropped.png`).
   * Rotasi akselerasi GPU via `Transform.rotate` dengan kalkulasi trigonometri `atan2(dy, dx)`.
   * Dilengkapi animasi pegas pembalik otomatis (*damped spring return*) yang membal kembali ke 0.0 lurus saat sentuhan dilepas.
   * Bagian emblem tengah setir mendukung gestur sentuh untuk klakson instan (*tap-to-honk*, vJoy Button 7).
3. **Bagian Tengah Bawah (D-Pad & Cluster Seleksi):**
   * Baris 1: Tombol panah navigasi game `[ ◀ ]`, `[ ENTER ]`, `[ ▶ ]`.
   * Baris 2: Tombol aksi angka `[ 1 ]`, `[ 2 ]`, `[ 3 ]` untuk fungsi cepat (misalnya radio, cruise control, ignition).
4. **Kanan Tengah (H-Pattern Shifter & Handbrake):**
   * **Modul Persneling Manual Pola H:** Menggunakan aset gerbang shifter (`persneling.png` / `tuas_persneling.png`) dengan angka gigi beriluminasi cyan neon (1-3-5 di atas, 2-4-6 di bawah, dan R). Knob dapat disentuh/digeser ke tiap celah slot gigi dengan getaran haptik *notch-lock*.
   * **Tuas Rem Tangan (Handbrake):** Menggunakan aset tuas (`handbrake.png`) dengan orientasi diagonal yang dapat ditarik untuk rem parkir atau drift.
5. **Kanan Bawah (Pedal Gas & Rem):**
   * **Pedal Rem (`pedal_rem.png`):** Pelat horizontal logam bergaris karet anti-selip hitam dengan respon analog kontinu.
   * **Pedal Gas (`pedal_gas.png`):** Pelat vertikal panjang dengan bantalan anti-selip dan animasi level cairan neon responsif.
6. **Pojok Kanan Atas (Indikator Status & Aksi Cepat):**
   * Badge status: `[ GYRO CAM : ACTIVE ]`
   * Tombol aksi lingkaran (Quick Action / Reset View)
   * Tombol gerigi pengaturan `[ ⚙ ]` (Membuka dialog modal Settings)

---

### 3.2 Layar `TILT MODE` (Mode Kemiringan Fisik Smartphone)
1. **Pojok Kiri Atas (Navigasi & Kalibrasi Nol):**
   * Grid tombol 2x2:
     * Baris 1: `[ MENU ]`, `[ MAP ]`
     * Baris 2: `[ CAMERA ]`, `[ RECENTER ]`
   * Tombol **`[ RECENTER ]`** berfungsi mengunci sudut kemiringan ponsel saat ini sebagai titik nol netral (0.0°) agar pemain dapat memegang ponsel dalam posisi santai.
2. **Tengah Layar (Cockpit Artificial Horizon Gauge):**
   * Garis horizon horizontal putih bersih (`________`) yang merefleksikan sumbu datar kendaraan.
   * Teks numerik sudut roll presisi tepat di bawah garis horizon (misalnya: `0.0°`, `-14.5°`, `+25.2°`).
3. **Pojok Kiri Bawah (Ergonomi Pengereman Dua Jempol):**
   * Pedal Rem (`pedal_rem.png`) dipindahkan ke pojok kiri bawah layar agar seimbang dengan pedal gas di kanan saat bodi ponsel dimiringkan dengan kedua tangan.
4. **Bagian Tengah Bawah (D-Pad Cluster):**
   * Tetap menyediakan baris `[ ◀ ] [ ENTER ] [ ▶ ]` dan `[ 1 ] [ 2 ] [ 3 ]`.
5. **Sisi Kanan:**
   * Tuas rem tangan (`handbrake.png`) di bagian tengah-kanan.
   * Pedal gas (`pedal_gas.png`) di bagian kanan bawah.
6. **Pojok Kanan Atas:**
   * Badge `[ GYRO CAM : ACTIVE ]`, tombol lingkaran aksi cepat, dan ikon Settings `[ ⚙ ]`.

---

## 4. Tata Letak Layar Pengaturan (Settings Screen - Split Master-Detail)

Layar Settings dirancang dengan format modal lanskap berbilah ganda (*Master-Detail Split View*):

```
+---------------------------------------------------------------------------------------+
|  SETTINGS              |  SETTINGS                                                    |
|                        |                                                              |
|  SELECT MODE           |       +-------------------+    +-------------------+         |
|  CUSTOMIZATION         |       |        [O]        |    |        (O)        |         |
|  STEERING              |       |     TILT MODE     |    |    STEER MODE     |         |
|  PEDALS                |       +-------------------+    +-------------------+         |
|  SOUND AND HAPTICS     |                                                              |
|  ABOUT                 |                                                              |
+---------------------------------------------------------------------------------------+
(SETTINGS SCREEN - DETAIL SELECT MODE)
```

```
+---------------------------------------------------------------------------------------+
|  SETTINGS              |  SETTINGS                                                    |
|                        |                                                              |
|  SELECT MODE           |  TILT SETTINGS                                               |
|  CUSTOMIZATION         |    (o) GYRO TILT                                             |
|  STEERING              |    ( ) ACCELEROMETER TILT                                    |
|  PEDALS                |                                                              |
|  SOUND AND HAPTICS     |                                                              |
|  ABOUT                 |                                                              |
+---------------------------------------------------------------------------------------+
(SETTINGS SCREEN - DETAIL STEERING)
```

### 4.1 Panel Master (Sidebar Kiri)
* Lebar: ~25% s/d 30% lebar layar.
* Header: `SETTINGS` (Ukuran teks 18pt, Bold, Putih).
* Daftar Menu Vertikal:
  1. `SELECT MODE`: Pemilihan mode operasional kemudi.
  2. `CUSTOMIZATION`: Kustomisasi tombol bebas dan penataan layout drag-and-drop.
  3. `STEERING`: Pemilihan sensor kemiringan, batas derajat setir, dan deadzone.
  4. `PEDALS`: Pengaturan kurva linearitas pengereman, transmisi, dan auto-spring.
  5. `SOUND AND HAPTICS`: Slider intensitas getaran dan suara klik sakelar mekanis.
  6. `ABOUT`: Nomor versi aplikasi, tim pengembang UKK RPL, dan dokumentasi port UDP 5005.

### 4.2 Panel Detail (Konten Kanan)
* **`SETTING_SELECT`:**
  * Dua kartu seleksi interaktif besar berdampingan:
    * **Kartu 1 (`TILT MODE`):** Wadah abu-abu gelap dengan ikon rotasi smartphone miring dan label `TILT MODE`.
    * **Kartu 2 (`STEER MODE`):** Wadah abu-abu gelap dengan ikon kemudi melingkar dan label `STEER MODE`.
    * Kartu yang aktif memiliki garis tepi (*border*) iluminasi menyala terang.
* **`SETTING_STEERING`:**
  * Sub-judul: `TILT SETTINGS`.
  * Radio Group pilihan perangkat keras sensor:
    * `GYRO TILT` (Sensor Giroskop untuk respon rotasi sudut murni).
    * `ACCELEROMETER TILT` (Sensor Akselerometer gravitasi linier).
  * Slider batas derajat putaran setir: `180°`, `360°`, `540°`, `900°`, `1080°`.
  * Slider redaman pegas pembalik (*Spring Damping*) dan deadzone tengah.
* **`SETTING_CUSTOMIZATION`:**
  * Tombol **"Buka Editor Layar Penuh (Edit Mode)"** untuk menggeser (*drag & drop*) posisi seluruh elemen secara langsung.
  * Tombol **"Tambah Tombol Baru (+)"** untuk memunculkan tombol aksesoris baru (Lampu, Sen, Hazard, Wiper, Horn, atau vJoy 1-32 bebas).
  * Pengatur transparansi tombol (*Button Opacity*) dan skala ukuran (*Scale Slider*).
  * **Tabel Pemetaan vJoy:** Lembar contekan pemetaan tombol ke ID vJoy Button 1-32 untuk kemudahan konfigurasi di dalam game PC.
  * **Alat Uji Sensor Live:** Grafik visual real-time untuk memeriksa responsivitas sensor smartphone.
* **`SETTING_PEDALS`:**
  * Pilihan mode transmisi: **Sequential Shifter** (< >) vs **Manual H-Pattern (1-6 + R)**.
  * Opsi mengaktifkan pedal kopling analog ketiga (*Clutch Pedal*).
  * Kurva pengereman non-linear progresif (*trail braking*) dan mode handbrake (Parkir Toggle vs Drift Momentary).
* **`SETTING_SOUND`:**
  * Slider intensitas getaran haptik (Mati, Rendah, Sedang, Kuat).
  * Efek audio klik mekanis sakelar dan sentakan batas kemudi (*lock bump*).
* **`SETTING_ABOUT`:**
  * Status koneksi target (IP & Port 5005), panduan vJoy, lisensi, dan informasi tim pengembang.

---

## 5. Pemetaan Aset Gambar (Asset Mapping)

| Komponen Antarmuka | Berkas Aset Gambar (`assets/images/`) | Spesifikasi Penggunaan |
| :--- | :--- | :--- |
| **Setir Kemudi (High-Res)** | `steering_wheel_cropped.png` / `setir1.png` | Roda setir bertekstur kulit diputar via GPU `Transform.rotate`. |
| **Setir Kemudi (Compact)** | `steering_wheel_cropped2.png` / `setir2.png` | Varian alternatif roda setir untuk perangkat layar ringkas. |
| **Shifter Pola H** | `persneling.png` | Gerbang persneling 6-percepatan dengan angka iluminasi cyan. |
| **Knob / Tuas Shifter** | `gear_lever.png` / `tuas_persneling1.png` | Kepala tuas persneling yang digeser ke tiap celah gigi. |
| **Tuas Rem Tangan (Tarik)** | `handbrake.png` | Tuas rem tangan saat ditarik aktif (warna merah/status ON). |
| **Tuas Rem Tangan (Lepas)** | `handbrake_down.png` | Tuas rem tangan saat berada di posisi bawah netral. |
| **Pedal Rem Analog** | `pedal_rem.png` | Pelat logam rem horizontal bergaris karet hitam. |
| **Pedal Gas Analog** | `pedal_gas.png` | Pelat logam gas vertikal panjang dengan bantalan anti-selip. |

---

## 6. Aturan Kualitas & Larangan Anti-Slop

* **Bebas Gradien Ungu/Pink Klise:** Seluruh palet warna menggunakan tema gelap kokpit otomotif autentik (`Deep Slate Navy` & `Carbon Charcoal`).
* **Bebas Em Dash:** Dilarang keras menggunakan tanda hubung em dash pada seluruh berkas kode, UI copy, label tombol, maupun dokumentasi.
* **Presisi Monospace:** Semua angka telemetri yang berubah dinamis (derajat sudut kemudi, persentase gas/rem, dan frekuensi Hz) wajib menggunakan font monospace atau fitur angka bertabulator agar posisi teks tidak bergetar saat nilai berubah cepat.
