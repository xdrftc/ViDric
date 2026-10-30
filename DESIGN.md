# DESIGN.md: Spesifikasi & Arahan Desain Antarmuka ViDric

Dokumen ini menjadi acuan tunggal (*single source of truth*) seluruh desain antarmuka, tata letak visual (*cockpit layout*), pemetaan aset grafis, dan sistem navigasi aplikasi **ViDric (Virtual Driving Controller)**.

---

## 1. Identitas Produk & Karakter Visual (Mood & Personality)

* **Nama Produk:** ViDric (Virtual Driving Controller)
* **Kategori:** Simulator Driving Controller & Telemetry Dashboard (Mobile Android Lanskap)
* **Filosofi Tampilan:** 
  * Terasa seperti kokpit kendaraan simulator premium (*industrial, high-precision, utilitarian*).
  * Bersih, gelap, kontras tinggi, dan bebas dari ornamen dekoratif generik (*anti-slop*).
  * Seluruh komponen interaktif meniru wujud fisik instrumen mobil nyata (setir kemudi bertekstur, pelat pedal logam anti-selip, tuas rem tangan, dan gerbang persneling pola H).

---

## 2. Nilai Tiga Tombol Kendali (Three Dials)

* **ENERGY: 2 (Balanced Cockpit)**
  * Nuansa gelap dengan aksen pencahayaan fungsional (Cyan neon untuk posisi gigi dan sudut kemudi, Hijau untuk status gyro, Merah untuk rem/handbrake).
  * Tidak menggunakan efek gradien pelangi atau efek neon berlebih yang mengaburkan pandangan.
* **RHYTHM: 3 (Strict Asymmetric Ergonomics)**
  * Dirancang spesifik untuk orientasi lanskap dengan jangkauan jempol kiri dan kanan (*dual-thumb ergonomics*).
  * Pemisahan zona fungsional yang tegas: Area Kemudi (Kiri), Area Navigasi/Transmisi (Tengah), Area Pedal & Tuas (Kanan).
* **MOTION: 1 (Calm, Real-Time Hardware-Driven)**
  * Animasi murni mencerminkan respon fisik instrumen: putaran setir sesuai gestur tangan, pergerakan knob persneling ke gerbang gigi, dan kompresi visual pedal saat ditekan.
  * Dilengkapi fisika pegas pembalik (*damped spring return*) yang kembali ke titik netral saat sentuhan jari dilepas.

---

## 3. Palet Warna & Fungsi Spesifik

| Token Warna | Nilai Hex | Peruntukan / Fungsi Komponen |
| :--- | :--- | :--- |
| **Cockpit Background** | `#141D26` | Latar belakang kanvas utama kokpit lanskap (slate dark slate blue). |
| **Card / Panel Surface** | `#18232E` | Latar modul instrumen, bilah header, dan kontainer navigasi. |
| **Panel Border** | `#263647` | Garis tepi penegas modul dan pemisah antar panel instrumen. |
| **Button Surface** | `#2B3B4C` | Latar tombol aksi (`MENU`, `MAP`, `CAMERA`, `ENTER`, `1`, `2`, `3`). |
| **Button Border / Highlight** | `#3C5066` | Garis tepi tombol interaktif dengan efek bevel mikro. |
| **Cyan Accent (Gears & HUD)**| `#00E5FF` | Indikator nomor gigi aktif pada H-Pattern shifter, angka telemetri, dan outline aktif. |
| **Green Accent (System/Gyro)**| `#00E676` | Status sensor kamera aktif (`GYRO CAM : ACTIVE`) dan respon pedal gas. |
| **Red Accent (Brake & Park)** | `#FF1744` | Indikator rem tangan aktif (`PARK`), garis batas setir, dan respon pedal rem. |
| **White Pure** | `#FFFFFF` | Ikon gerigi pengaturan, garis horizon kemiringan (*horizon gauge*), dan teks judul. |
| **Text Secondary** | `#8FA3B8` | Label instrumen, satuan derajat (`0.0°`), dan teks pembantu. |

---

## 4. Pemetaan Aset Grafis Resmi (`assets/images/`)

Aplikasi menggunakan aset fotorealistik resmi yang telah disediakan di dalam proyek:

| Nama Berkas Aset | Resolusi Asli | Peruntukan di Antarmuka |
| :--- | :--- | :--- |
| **`setir1.png`** / **`setir2.png`** | 2400x1340 / 1024x572 | Roda kemudi fotorealistik dengan pegangan kulit dan logo tengah (tap-to-honk klakson). |
| **`steering_wheel_cropped.png`** | 1300x1300 (1:1) | Roda kemudi hasil crop presisi untuk rotasi matriks GPU (`Transform.rotate`) tanpa distorsi. |
| **`pedal_gas.png`** | 1024x572 | Pelat logam vertikal bergaris anti-selip untuk pedal gas (*throttle*). |
| **`pedal_rem.png`** | 1024x572 | Pelat logam horizontal bergaris anti-selip untuk pedal rem (*brake*). |
| **`handbrake.png`** | 1024x572 | Tuas rem tangan mekanis dalam posisi ditarik (aktif / *engaged*). |
| **`handbrake_down.png`** | 1024x572 | Tuas rem tangan mekanis dalam posisi turun (lepas / *released*). |
| **`persneling.png`** | 1024x572 | Rumah gerbang persneling manual H-Pattern dengan cetakan angka gigi cyan (`1 3 5` / `2 4 6`). |
| **`gear_lever.png`** | 1024x572 | Batang dan knob tuas transmisi manual yang dapat digeser ke masing-masing celah gigi. |
| **`tuas_persneling1.png`** | 1024x572 | Alternatif varian knob persneling metalik dengan tekstur bergaris. |
| **`tuas_persneling2.png`** | 1024x572 | Alternatif varian gerbang persneling kontras tinggi. |

---

## 5. Tata Letak Layar Kokpit (Cockpit Screens)

### 5.1 Layar 1: `STEERING MODE` (Mode Roda Kemudi)

Layar ini ditujukan untuk pemain yang mengemudi menggunakan sentuhan roda setir virtual di layar:

```text
+-----------------------------------------------------------------------------------------+
| [MENU]  [MAP]                                                    [GYRO CAM: ACTIVE] (O) [*]|
| [CAMERA]                                                                                |
|                                                                                         |
|       /=======\                                             +-------------+   /======\  |
|      |    |    |                                            |  1   3   5  |  (  __--/   |
|      | ---O--- |                                            |  |   |   |  |   ||Handbrake
|      |    |    |                                            |  2   4   6  |             |
|       \=======/                      [<]  [ENTER]  [>]      +-------------+   [===]     |
|     (Steering Wheel)                 [1]    [2]    [3]        (H-Pattern)     |GAS|     |
|                                     (Nav Cluster)             [=======]       |   |     |
|                                                                | BRAKE |      [===]     |
+-----------------------------------------------------------------------------------------+
```

* **Pojok Kiri Atas:**
  * Tombol `MENU`: Membuka menu jeda game PC atau menu game.
  * Tombol `MAP`: Tombol toggle peta navigasi/GPS di game (vJoy Button).
  * Tombol `CAMERA`: Siklus pergantian kamera pandangan (Kabin, Bemper, Kamera Luar).
* **Pojok Kanan Atas:**
  * Pill Status: `GYRO CAM : ACTIVE` (Indikator pelacakan gerakan kepala/kamera).
  * Tombol Bundar `(O)`: Tombol reset orientasi sudut kamera (*Camera Recenter*).
  * Tombol Ikon Gerigi `[*]`: Membuka jendela pengaturan modal `SETTINGS`.
* **Area Kiri:**
  * Komponen roda kemudi fotorealistik (`steering_wheel_cropped.png`).
  * Mendukung gestur sentuhan melingkar, indikator derajat belok, dan klakson tengah (*tap-to-honk*).
* **Area Tengah Bawah:**
  * Tombol navigasi arah: `<` (Kiri / Downshift), `ENTER` (Pilih / Klakson 2), `>` (Kanan / Upshift).
  * Tombol cepat sub-gigi / aksi: `[1]`, `[2]`, `[3]`.
* **Area Kanan Tengah:**
  * Modul H-Pattern Shifter interaktif (`persneling.png` + `gear_lever.png`).
  * Tuas rem tangan (`handbrake.png` / `handbrake_down.png`).
* **Area Kanan Bawah:**
  * Pedal Rem analog (`pedal_rem.png`) di sebelah kiri pedal gas.
  * Pedal Gas analog (`pedal_gas.png`) di sebelah kanan dengan orientasi vertikal.

---

### 5.2 Layar 2: `TILT MODE` (Mode Kemiringan Fisik Ponsel)

Layar ini ditujukan untuk pemain yang memutar seluruh badan smartphone secara fisik untuk berbelok:

```text
+-----------------------------------------------------------------------------------------+
| [MENU]  [MAP]                                                    [GYRO CAM: ACTIVE] (O) [*]|
| [CAMERA] [RECENTER]                                                                     |
|                                                                                         |
|                                     -----------------                                   |
|                                           0.0°                                          |
|                                  (Artificial Horizon Gauge)                             |
|                                                                               /======\  |
|                                                                              (  __--/   |
|                                      [<]  [ENTER]  [>]              /======\  ||Handbrake
|     [=======]                        [1]    [2]    [3]             (  __--/             |
|     | BRAKE |                       (Nav Cluster)                               [===]   |
|    (Left Thumb)                                                                 |GAS|   |
|                                                                                 |   |   |
|                                                                                 [===]   |
+-----------------------------------------------------------------------------------------+
```

* **Pojok Kiri Atas:**
  * Tombol `MENU`, `MAP`, `CAMERA`, serta penambahan tombol **`RECENTER`** (kalibrasi sudut kemiringan saat ini menjadi titik nol 0.0°).
* **Area Kiri Bawah (Ergonomi Tangan Kiri):**
  * Roda setir dihilangkan karena ponsel diputar secara fisik.
  * **Pedal Rem (`pedal_rem.png`) dipindahkan ke pojok kiri bawah** agar dapat diinjak dengan nyaman oleh jempol tangan kiri saat mengerem mendadak (*left-foot braking*).
* **Area Tengah Atas:**
  * Garis instrumen busur cakrawala (*Artificial Horizon Line*) dengan pembacaan derajat kemiringan live: `0.0°` (misalnya: `-15.4°` saat miring ke kiri, `+22.8°` saat miring ke kanan).
* **Area Tengah Bawah:**
  * Modul kluster navigasi tetap konsisten: `< [ENTER] >` dan tombol `[1] [2] [3]`.
* **Area Kanan:**
  * Tuas rem tangan mekanis (`handbrake.png`).
  * Pedal gas analog vertikal (`pedal_gas.png`) untuk jempol kanan.

---

## 6. Arsitektur Layar Pengaturan (`SETTINGS` Master-Detail)

Menu pengaturan mengadopsi tata letak split lanskap (*Master-Detail Split View*):
* **Sisi Kiri (Bilah Master Navigasi):**
  1. `SELECT MODE`
  2. `CUSTOMIZATION`
  3. `STEERING`
  4. `PEDALS`
  5. `SOUND AND HAPTICS`
  6. `ABOUT`
* **Sisi Kanan (Panel Konten Detail):**

### 6.1 `SETTING_SELECT`
* Dua kartu pilihan mode besar dengan ikon dan ilustrasi visual:
  * **Kartu 1 (`TILT MODE`):** Ikon ponsel berputar dengan panah melingkar.
  * **Kartu 2 (`STEER MODE`):** Ikon roda kemudi setir bundar.

### 6.2 `SETTING_STEERING`
* Bagian `TILT SETTINGS`:
  * Radio button / Switch: `GYRO TILT` (Sensor giroskop sudut presisi).
  * Radio button / Switch: `ACCELEROMETER TILT` (Sensor gravitasi akselerometer standar).
* Bagian `STEERING WHEEL SETTINGS`:
  * Derajat putaran kemudi (*Rotation Lock*): 180°, 360°, 540°, 900°, 1080°.
  * Slider redaman pegas pembalik (*Spring Return Damping*).
  * Slider deadzone tengah (*Center Deadzone*).

### 6.3 `SETTING_CUSTOMIZATION`
* **Layout Editor Canvas:**
  * Tombol **"Edit Layout On-Screen"** untuk menggeser (*drag & drop*) posisi setir, pedal gas, pedal rem, dan tombol di atas kanvas kokpit.
  * Tombol **"Tambah Tombol Kustom (+)"** untuk memunculkan tombol aksesoris baru (Lampu, Sen, Hazard, Wiper, Horn, atau vJoy Button 1-32).
  * Slider transparansi tombol (*Opacity*) dan slider skala ukuran (*Scale*).
* **Tabel Pemetaan vJoy (*In-Game Binding Guide*):**
  * Lembar panduan cepat nomor tombol vJoy agar pemain mudah mencocokkan konfigurasi kontrol di menu Options game PC.
* **Alat Uji Sensor Langsung (*Live Hardware Sensor Tester*):**
  * Grafik visual live pembacaan data sensor X, Y, Z untuk memastikan kalibrasi ponsel bekerja sempurna.

### 6.4 `SETTING_PEDALS`
* **Kurva Pengereman Progresif (*Non-Linear Brake Resistance*):** Simulasi pedal rem empuk di awal dan memadat di ujung.
* **Mode Handbrake:** Toggle (Parkir) vs Momentary (Drift/Rally).
* **Mode Transmisi:** Sequential Shifter vs Manual H-Pattern Shifter dengan opsi Pedal Kopling ketiga.
* **Pembalikan Sumbu (*Invert Axis*):** Sakelar pembalik arah pedal jika diperlukan.

### 6.5 `SETTING_SOUND AND HAPTICS`
* Slider intensitas getaran (*Haptic Intensity*: Mati, Rendah, Sedang, Kuat).
* Efek suara sakelar mekanis (*Mechanical Audio Clicks* untuk perpindahan gigi, relay lampu sen, dan klakson).
* Getaran sentakan batas putaran setir (*Lock-to-Lock Bump*).

### 6.6 `SETTING_ABOUT`
* Informasi nomor versi rilis aplikasi ViDric.
* Identitas pengembang dan kompetensi UKK Rekayasa Perangkat Lunak.
* Dokumentasi protokol jaringan UDP port 5005 dan lisensi open-source.

---

## 7. Ketentuan Bebas Slop (Anti-Slop Hard Rules)

1. **Dilarang Menggunakan Karakter Em Dash:** Seluruh teks pada dokumen desain, kode program, komentar, maupun string antarmuka dilarang menggunakan karakter em dash. Gunakan tanda titik dua, tanda koma, tanda kurung, atau tanda hubung ganda `--`.
2. **Tanpa Gradien Ungu/Biru SaaS Generic:** Seluruh warna UI wajib menggunakan warna fungsional instrumen dasbor otomotif (Slate `#141D26`, Cyan `#00E5FF`, Green `#00E676`, Red `#FF1744`).
3. **Fisika Nyata untuk Seluruh Kontrol:** Setir dan pedal wajib memiliki sifat mekanis yang dapat diprediksi (kembali ke titik nol saat dilepas, getaran haptik saat berpindah gigi atau mencapai batas kemudi).
