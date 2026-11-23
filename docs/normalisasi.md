# Analisis Normalisasi Basis Data Klinik Pratama

Dokumen ini menyusun analisis normalisasi skema `klinik_pratama` dari bentuk tidak normal (UNF) melalui 1NF, 2NF, 3NF, hingga BCNF untuk seluruh 11 tabel final, disertai bukti query di `bukti/query-dasar-normalisasi.txt`.

## Bentuk Awal (UNF)

Pada rancangan awal sebelum normalisasi, seluruh pencatatan layanan klinik digabung ke satu tabel besar `layanan_klinik`:

| id_kunjungan | pasien | dokter & poli | jadwal | rekam_medis | daftar_tindakan (berulang) | daftar_obat (berulang) | pembayaran |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | Ahmad Fauzi, 3201... | dr. Andi, Poli Umum (Lt 1) | 2026-08-05 08:00-12:00 | ISPA ringan, 72 kg, 170 cm | Konsultasi Umum (1, 50000) | Obat Batuk Sirup (1, 18000) | 68000, Tunai, Lunas |
| 2 | Budi Hartono, 3201... | dr. Andi, Poli Umum (Lt 1) | 2026-08-05 08:00-12:00 | Bronkitis akut, 68 kg, 168 cm | Konsultasi Umum (1, 50000); Nebulisasi (1, 75000) | Amoxicillin (10, 1500); Vitamin C (5, 600) | 143000, Transfer, Lunas |

Masalah rancangan awal:
1. Pengulangan nilai dalam satu sel pada `daftar_tindakan` dan `daftar_obat` (repeating group).
2. Ketergantungan sebagian (parsial) atribut master pada kunci gabungan setelah pemecahan item.
3. Ketergantungan transitif data poli melalui dokter, serta data pasien/dokter melalui kunjungan.
4. Anomali penyisipan, pembaruan, dan penghapusan ketika mengubah master poli, dokter, tindakan, atau obat.

## 1NF: kolom atomik

Syarat 1NF: setiap atribut bernilai atomik (tunggal) dan tidak ada kelompok kolom berulang.

**Sebelum 1NF** (`layanan_klinik` menyimpan daftar dalam satu sel):

| id_kunjungan | id_rekam | daftar_tindakan | daftar_obat |
| --- | --- | --- | --- |
| 2 | 2 | Konsultasi Umum (1); Nebulisasi (1) | Amoxicillin 500mg (10); Vitamin C 500mg (5) |

**Sesudah 1NF** (dipecah menjadi baris atomik pada `detail_tindakan` dan `detail_resep`):

Tabel `detail_tindakan_1nf`:

| id_kunjungan | id_tindakan | nama_tindakan | tarif | jumlah |
| --- | --- | --- | --- | --- |
| 2 | 1 | Konsultasi Dokter Umum | 50000 | 1 |
| 2 | 6 | Nebulisasi | 75000 | 1 |

Tabel `detail_resep_1nf`:

| id_rekam | id_obat | nama_obat | satuan | harga | stok | jumlah | aturan_pakai |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 2 | 3 | Amoxicillin 500mg | Kapsul | 1500 | 80 | 10 | 3x1 kapsul sampai habis |
| 2 | 7 | Vitamin C 500mg | Tablet | 600 | 90 | 5 | 1x1 tablet pagi |

Hasil 1NF: tidak ada lagi kolom berisi daftar pada seluruh skema final.

## 2NF: dependensi penuh

Syarat 2NF: sudah memenuhi 1NF dan setiap atribut bukan kunci bergantung penuh (fully functionally dependent) pada seluruh kunci primer, bukan sebagian kunci (tidak ada dependensi parsial).

**Sebelum 2NF** (atribut master bergantung parsial pada sebagian kunci gabungan):

| Tabel 1NF | Kunci Gabungan | Atribut Dependensi Parsial | Bergantung Hanya Pada |
| --- | --- | --- | --- |
| `detail_tindakan_1nf` | `(id_kunjungan, id_tindakan)` | `nama_tindakan`, `tarif` | `id_tindakan` |
| `detail_resep_1nf` | `(id_rekam, id_obat)` | `nama_obat`, `satuan`, `harga`, `stok` | `id_obat` |

**Sesudah 2NF** (atribut master dipisah ke `tindakan` dan `obat`):

| Tabel Hasil 2NF | Kunci Primer | Kolom Non-Kunci (Bergantung Penuh) |
| --- | --- | --- |
| `tindakan` | `id_tindakan` | `nama_tindakan`, `tarif` |
| `detail_tindakan` | `id_detail_tindakan` (UNIQUE `id_kunjungan, id_tindakan`) | `jumlah` |
| `obat` | `id_obat` | `nama_obat`, `satuan`, `harga`, `stok` |
| `detail_resep` | `id_detail_resep` (UNIQUE `id_rekam, id_obat`) | `jumlah`, `aturan_pakai` |

Hasil 2NF: tidak ada dependensi parsial pada seluruh tabel.

## 3NF: tidak ada dependensi transitif

Syarat 3NF: sudah memenuhi 2NF dan tidak ada atribut bukan kunci yang bergantung secara transitif pada kunci primer melalui atribut bukan kunci lain.

**Sebelum 3NF** (dependensi transitif pada tabel transaksi dan master):

| Tabel 2NF | Jalur Dependensi Transitif | Atribut Bermasalah |
| --- | --- | --- |
| `dokter_2nf` | `id_dokter` lewat `id_poli` | `nama_poli`, `lantai` |
| `jadwal_2nf` | `id_jadwal` lewat `id_dokter` | `nama_dokter`, `no_sip`, `email`, `no_telp`, `tipe_dokter` |
| `kunjungan_2nf` | `id_kunjungan` lewat `id_pasien` | `nama_pasien`, `nik`, `email`, `no_telp`, `tanggal_lahir`, `alamat` |
| `kunjungan_2nf` | `id_kunjungan` lewat `id_jadwal` | `tanggal`, `jam_mulai`, `jam_selesai`, `ruangan`, `kuota` |
| `kunjungan_2nf` | atribut opsional 1:0..1 pada kunjungan | kolom pemeriksaan (`keluhan`, `diagnosis`, ...) dan penagihan (`metode`, `total_tagihan`, ...) |

**Sesudah 3NF** (setiap entitas mandiri dipisah ke tabelnya sendiri):

| Tabel Hasil 3NF | Kunci Primer | Kunci Tamu | Atribut Langsung |
| --- | --- | --- | --- |
| `poli` | `id_poli` | — | `nama_poli`, `lantai` |
| `dokter` | `id_dokter` | `id_poli` | `nama_dokter`, `no_sip`, `email`, `no_telp`, `tipe_dokter` |
| `jadwal_praktik` | `id_jadwal` | `id_dokter` | `tanggal`, `jam_mulai`, `jam_selesai`, `ruangan`, `kuota` |
| `pasien` | `id_pasien` | — | `nama_pasien`, `nik`, `email`, `no_telp`, `tanggal_lahir`, `alamat` |
| `kunjungan` | `id_kunjungan` | `id_pasien`, `id_jadwal` | `tanggal_kunjungan`, `no_antrean`, `status_kunjungan` |
| `rekam_medis` | `id_rekam` | `id_kunjungan` (UNIQUE) | `keluhan`, `diagnosis`, `tekanan_darah`, `suhu`, `berat_badan`, `tinggi_badan`, `imt` (STORED), `tanggal_periksa` |
| `pembayaran` | `id_pembayaran` | `id_kunjungan` (UNIQUE) | `tanggal_bayar`, `metode`, `total_tagihan`, `status_bayar` |

Catatan: kolom turunan `imt` pada `rekam_medis` didefinisikan sebagai `GENERATED ALWAYS AS (...) STORED`, sehingga dihitung otomatis dari `berat_badan` dan `tinggi_badan` tanpa anomali pembaruan.

Hasil 3NF: seluruh atribut non-kunci pada 11 tabel hanya bergantung langsung pada kunci primer tabelnya.

## BCNF: setiap determinan adalah kandidat kunci

Syarat BCNF: untuk setiap dependensi fungsional non-trivial, determinan di sisi kiri harus merupakan superkey (kandidat kunci).

**Sebelum dan Sesudah BCNF** (verifikasi determinan pada seluruh 11 tabel final):

| No | Tabel | Kunci Primer | Kandidat Kunci Lain (UNIQUE) | Status BCNF & Alasan |
| --- | --- | --- | --- | --- |
| 1 | `poli` | `id_poli` | `nama_poli` (`uq_poli_nama`) | BCNF: determinan hanya `id_poli` dan `nama_poli` (keduanya kandidat kunci). |
| 2 | `dokter` | `id_dokter` | `no_sip` (`uq_dokter_sip`), `email` (`uq_dokter_email`) | BCNF: `no_sip` dan `email` dijaga UNIQUE sebagai kandidat kunci. |
| 3 | `jadwal_praktik` | `id_jadwal` | `(id_dokter, tanggal, jam_mulai)` (`uq_jadwal_sesi`) | BCNF: satu dokter hanya 1 sesi per tanggal & jam mulai; determinan = kandidat kunci. |
| 4 | `pasien` | `id_pasien` | `nik` (`uq_pasien_nik`), `email` (`uq_pasien_email`) | BCNF: `nik` dan `email` unik sehingga setiap determinan adalah kandidat kunci. |
| 5 | `kunjungan` | `id_kunjungan` | `(id_jadwal, no_antrean)`, `(id_pasien, id_jadwal)` | BCNF: antrean per jadwal dan pasien per jadwal keduanya kandidat kunci UNIQUE. |
| 6 | `rekam_medis` | `id_rekam` | `id_kunjungan` (`uq_rekam_kunjungan`) | BCNF: relasi 1:0..1 dijaga UNIQUE `id_kunjungan`; `imt` generated column. |
| 7 | `tindakan` | `id_tindakan` | `nama_tindakan` (`uq_tindakan_nama`) | BCNF: determinan hanya `id_tindakan` dan `nama_tindakan`. |
| 8 | `detail_tindakan` | `id_detail_tindakan` | `(id_kunjungan, id_tindakan)` (`uq_detail_tindakan`) | BCNF: tidak ada determinan non-kunci; `tarif` sudah dipisah ke `tindakan`. |
| 9 | `obat` | `id_obat` | `nama_obat` (`uq_obat_nama`) | BCNF: determinan hanya `id_obat` dan `nama_obat`. |
| 10 | `detail_resep` | `id_detail_resep` | `(id_rekam, id_obat)` (`uq_detail_resep`) | BCNF: tidak ada determinan non-kunci; master obat sudah dipisah ke `obat`. |
| 11 | `pembayaran` | `id_pembayaran` | `id_kunjungan` (`uq_pembayaran_kunjungan`) | BCNF: satu tagihan per kunjungan dijaga UNIQUE `id_kunjungan`. |

Tidak ada determinan di luar kandidat kunci yang tersisa pada satu pun dari 11 tabel.

## Daftar Dependensi Fungsional

Notasi determinan ke atribut untuk seluruh dependensi fungsional skema `klinik_pratama` (tanda `[dipecah]` menandai dependensi yang dipisahkan saat proses normalisasi):

1. `id_poli -> nama_poli, lantai` [dipecah ke `poli` pada 3NF]
2. `nama_poli -> id_poli, lantai`
3. `id_dokter -> id_poli, nama_dokter, no_sip, email, no_telp, tipe_dokter` [dipecah ke `dokter` pada 3NF]
4. `no_sip -> id_dokter, nama_dokter, id_poli`
5. `email (dokter) -> id_dokter, nama_dokter, no_sip`
6. `id_jadwal -> id_dokter, tanggal, jam_mulai, jam_selesai, ruangan, kuota` [dipecah ke `jadwal_praktik` pada 3NF]
7. `(id_dokter, tanggal, jam_mulai) -> id_jadwal, jam_selesai, ruangan, kuota`
8. `id_pasien -> nama_pasien, nik, email, no_telp, tanggal_lahir, alamat` [dipecah ke `pasien` pada 3NF]
9. `nik -> id_pasien, nama_pasien, email, no_telp, tanggal_lahir, alamat`
10. `id_kunjungan -> id_pasien, id_jadwal, tanggal_kunjungan, no_antrean, status_kunjungan`
11. `(id_jadwal, no_antrean) -> id_kunjungan, id_pasien, status_kunjungan`
12. `(id_pasien, id_jadwal) -> id_kunjungan, no_antrean, status_kunjungan`
13. `id_rekam -> id_kunjungan, keluhan, diagnosis, tekanan_darah, suhu, berat_badan, tinggi_badan, tanggal_periksa` [dipecah ke `rekam_medis` pada 3NF]
14. `id_tindakan -> nama_tindakan, tarif` [dipecah ke `tindakan` pada 2NF]
15. `(id_kunjungan, id_tindakan) -> id_detail_tindakan, jumlah` [dipecah ke `detail_tindakan` pada 1NF/2NF]
16. `id_obat -> nama_obat, satuan, harga, stok` [dipecah ke `obat` pada 2NF]
17. `(id_rekam, id_obat) -> id_detail_resep, jumlah, aturan_pakai` [dipecah ke `detail_resep` pada 1NF/2NF]
18. `id_pembayaran -> id_kunjungan, tanggal_bayar, metode, total_tagihan, status_bayar` [dipecah ke `pembayaran` pada 3NF]

## Bukti Query Dependensi dan Query Dasar

Keluaran query pembuktian (SELECT sederhana, JOIN multi-tabel, agregasi bulanan, dan uji pelanggaran dependensi fungsional bernilai 0 baris) disimpan pada `bukti/query-dasar-normalisasi.txt`.

## Ringkasan untuk Bab II Laporan (diserahkan ke Agit / A1)

```latex
\section{Normalisasi 1NF sampai BCNF}
Perancangan basis data \texttt{klinik\_pratama} dinormalisasi dari bentuk tidak normal
(UNF) hingga Boyce-Codd Normal Form (BCNF) menghasilkan 11 tabel final:
\begin{enumerate}
  \item \textbf{1NF (Kolom Atomik)}: Menghapus kelompok berulang daftar tindakan dan
        daftar obat menjadi tabel \texttt{detail\_tindakan} dan \texttt{detail\_resep}.
  \item \textbf{2NF (Dependensi Penuh)}: Memisahkan atribut master yang bergantung
        parsial pada kunci gabungan ke tabel \texttt{tindakan} dan \texttt{obat}.
  \item \textbf{3NF (Tanpa Dependensi Transitif)}: Memisahkan \texttt{poli},
        \texttt{dokter}, \texttt{jadwal\_praktik}, \texttt{pasien},
        \texttt{rekam\_medis}, dan \texttt{pembayaran} agar setiap kolom non-kunci
        bergantung langsung pada kunci primer tabelnya.
  \item \textbf{BCNF}: Seluruh 18 dependensi fungsional pada 11 tabel memiliki
        determinan berupa kandidat kunci (kunci primer atau constraint \texttt{UNIQUE}).
\end{enumerate}
```
