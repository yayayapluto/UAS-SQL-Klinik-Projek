-- =====================================================================
-- 02_data.sql
-- Pemilik : Dapa (A2)
-- Fase    : F2 data-v1
-- Butuh   : 01_struktur.sql
-- Sumber  : PRD bagian 7 dan 10, panduan A2
-- =====================================================================
-- Daftar TODO Dapa. Ganti [ ] menjadi [x] setelah tabel terisi.
-- [x] poli 5 baris
-- [x] dokter 6 baris
-- [x] jadwal_praktik 8 baris
-- [x] pasien 10 baris
-- [x] kunjungan 14 baris
-- [x] rekam_medis 10 baris
-- [x] tindakan 6 baris
-- [x] detail_tindakan 16 baris
-- [x] obat 8 baris
-- [x] detail_resep 12 baris
-- [x] pembayaran 10 baris
-- [x] keadaan khusus: jadwal 7 penuh, obat 8 stok 5, 2 Batal, 3 belum lunas
-- [x] nilai query Q1 sampai Q10 cocok dengan bukti
-- =====================================================================

USE klinik_pratama;

-- ---------------------------------------------------------------------
-- 1. poli (5 baris)
-- ---------------------------------------------------------------------
INSERT INTO poli (id_poli, nama_poli, lantai) VALUES
(1, 'Poli Umum', 1),
(2, 'Poli Gigi', 2),
(3, 'Poli Anak', 3),
(4, 'Poli Penyakit Dalam', 4),
(5, 'Poli KIA', 5);

-- ---------------------------------------------------------------------
-- 2. dokter (6 baris)
-- ---------------------------------------------------------------------
INSERT INTO dokter (id_dokter, id_poli, nama_dokter, no_sip, email, no_telp, tipe_dokter) VALUES
(1, 1, 'dr. Andi Pratama',         'SIP-001/2024', 'andi.pratama@klinikpratama.id',   '081210000001', 'Umum'),
(2, 1, 'dr. Budi Santoso',         'SIP-002/2024', 'budi.santoso@klinikpratama.id',   '081210000002', 'Umum'),
(3, 2, 'drg. Citra Lestari',       'SIP-003/2024', 'citra.lestari@klinikpratama.id',  '081210000003', 'Spesialis'),
(4, 3, 'dr. Dewi Anggraini, Sp.A', 'SIP-004/2024', 'dewi.anggraini@klinikpratama.id', '081210000004', 'Spesialis'),
(5, 4, 'dr. Eko Prasetyo, Sp.PD',  'SIP-005/2024', 'eko.prasetyo@klinikpratama.id',   '081210000005', 'Spesialis'),
(6, 5, 'dr. Fajar Nugroho',        'SIP-006/2024', 'fajar.nugroho@klinikpratama.id',  '081210000006', 'Umum');

-- ---------------------------------------------------------------------
-- 3. jadwal_praktik (8 baris)
-- Rentang tanggal: Agustus - Oktober 2026
-- Jadwal 1: dokter 1, 2026-08-05 08:00-12:00 (bahan uji bentrok Uji 5)
-- Jadwal 2: dokter 3, 2026-08-06 (bahan uji antrean ganda Uji 1)
-- Jadwal 7: dokter 1, 2026-10-07, kuota 4 penuh (bahan uji kuota Uji 4)
-- ---------------------------------------------------------------------
INSERT INTO jadwal_praktik (id_jadwal, id_dokter, tanggal, jam_mulai, jam_selesai, ruangan, kuota) VALUES
(1, 1, '2026-08-05', '08:00:00', '12:00:00', 'R-01', 6),
(2, 3, '2026-08-06', '09:00:00', '12:00:00', 'R-02', 5),
(3, 4, '2026-08-12', '08:00:00', '11:00:00', 'R-03', 5),
(4, 5, '2026-09-02', '13:00:00', '16:00:00', 'R-04', 5),
(5, 2, '2026-09-10', '08:00:00', '12:00:00', 'R-01', 6),
(6, 6, '2026-09-18', '09:00:00', '12:00:00', 'R-05', 5),
(7, 1, '2026-10-07', '08:00:00', '12:00:00', 'R-01', 4),
(8, 3, '2026-10-14', '13:00:00', '16:00:00', 'R-02', 5);

-- ---------------------------------------------------------------------
-- 4. pasien (10 baris)
-- Semua lahir sebelum 2005; tertua Gilang Ramadhan (1980-02-18).
-- Hanya 1 pasien berawalan 'A' untuk uji indeks idx_pasien_nama.
-- ---------------------------------------------------------------------
INSERT INTO pasien (id_pasien, nama_pasien, nik, email, no_telp, tanggal_lahir, alamat) VALUES
(1,  'Ahmad Fauzi',     '3201011405920001', 'ahmad.fauzi@mail.test',     '081320000001', '1992-05-14', 'Jl. Merdeka No. 10, Bandung'),
(2,  'Budi Hartono',    '3201010311880002', 'budi.hartono@mail.test',    '081320000002', '1988-11-03', 'Jl. Asia Afrika No. 22, Bandung'),
(3,  'Citra Dewi',      '3201012107950003', 'citra.dewi@mail.test',      '081320000003', '1995-07-21', 'Jl. Braga No. 5, Bandung'),
(4,  'Dian Kusuma',     '3201011903900004', 'dian.kusuma@mail.test',     '081320000004', '1990-03-19', 'Jl. Dago No. 41, Bandung'),
(5,  'Eka Putra',       '3201010809970005', 'eka.putra@mail.test',       '081320000005', '1997-09-08', 'Jl. Cihampelas No. 18, Bandung'),
(6,  'Fitri Handayani', '3201012512930006', 'fitri.handayani@mail.test', '081320000006', '1993-12-25', 'Jl. Setiabudi No. 77, Bandung'),
(7,  'Gilang Ramadhan', '3201011802800007', 'gilang.ramadhan@mail.test', '081320000007', '1980-02-18', 'Jl. Diponegoro No. 12, Bandung'),
(8,  'Hana Pertiwi',    '3201011104990008', 'hana.pertiwi@mail.test',    '081320000008', '1999-04-11', 'Jl. Riau No. 33, Bandung'),
(9,  'Indra Wijaya',    '3201013008850009', 'indra.wijaya@mail.test',    '081320000009', '1985-08-30', 'Jl. Pasteur No. 64, Bandung'),
(10, 'Joko Susilo',     '3201011701010010', 'joko.susilo@mail.test',     '081320000010', '2001-01-17', 'Jl. Soekarno Hatta No. 89, Bandung');

-- ---------------------------------------------------------------------
-- 5. kunjungan (14 baris)
-- Status: 10 Selesai, 2 Menunggu, 2 Batal.
-- dr. Andi Pratama (id_dokter 1) menangani 6 kunjungan (jadwal 1 & 7).
-- Jadwal 7 berkuota 4 dan terisi 4 kunjungan non-Batal (sisa kuota 0).
-- ---------------------------------------------------------------------
INSERT INTO kunjungan (id_kunjungan, id_pasien, id_jadwal, tanggal_kunjungan, no_antrean, status_kunjungan) VALUES
(1,  1,  1, '2026-08-05', 1, 'Selesai'),
(2,  2,  1, '2026-08-05', 2, 'Selesai'),
(3,  3,  2, '2026-08-06', 1, 'Selesai'),
(4,  4,  2, '2026-08-06', 2, 'Selesai'),
(5,  5,  3, '2026-08-12', 1, 'Selesai'),
(6,  6,  3, '2026-08-12', 2, 'Selesai'),
(7,  7,  4, '2026-09-02', 1, 'Selesai'),
(8,  8,  4, '2026-09-02', 2, 'Selesai'),
(9,  9,  5, '2026-09-10', 1, 'Batal'),
(10, 10, 6, '2026-09-18', 1, 'Batal'),
(11, 3,  7, '2026-10-07', 1, 'Selesai'),
(12, 4,  7, '2026-10-07', 2, 'Selesai'),
(13, 7,  7, '2026-10-07', 3, 'Menunggu'),
(14, 8,  7, '2026-10-07', 4, 'Menunggu');

-- ---------------------------------------------------------------------
-- 6. rekam_medis (10 baris, hanya kunjungan Selesai)
-- Kolom imt tidak diisi karena dihitung otomatis (generated column).
-- id_rekam 1: berat 72.0 kg, tinggi 170.0 cm -> imt = 24.9.
-- ---------------------------------------------------------------------
INSERT INTO rekam_medis (id_rekam, id_kunjungan, keluhan, diagnosis, tekanan_darah, suhu, berat_badan, tinggi_badan, tanggal_periksa) VALUES
(1,  1,  'Batuk berdahak 3 hari',        'ISPA ringan',              '120/80', 37.2, 72.0, 170.0, '2026-08-05'),
(2,  2,  'Sesak napas dan batuk malam',  'Bronkitis akut',           '125/82', 37.6, 68.0, 168.0, '2026-08-05'),
(3,  3,  'Karang gigi dan gusi bengkak', 'Gingivitis kronis',        '115/75', 36.6, 55.0, 160.0, '2026-08-06'),
(4,  4,  'Gigi geraham nyeri saat makan','Karies dentin',            '118/78', 36.7, 60.0, 165.0, '2026-08-06'),
(5,  5,  'Demam ringan sejak kemarin',   'Febris viral',             '110/70', 38.1, 52.0, 162.0, '2026-08-12'),
(6,  6,  'Lemas dan nafsu makan turun',  'Defisiensi vitamin ringan','112/72', 36.5, 54.0, 158.0, '2026-08-12'),
(7,  7,  'Pusing dan tengkuk terasa kaku','Hipertensi esensial',     '150/95', 36.8, 78.0, 172.0, '2026-09-02'),
(8,  8,  'Kontrol tekanan darah tinggi', 'Hipertensi terkontrol',    '140/90', 36.7, 62.0, 163.0, '2026-09-02'),
(9,  11, 'Sakit kepala dan pegal badan', 'Myalgia akut',             '118/76', 37.0, 56.0, 160.0, '2026-10-07'),
(10, 12, 'Cek kesehatan rutin',          'Kondisi stabil',           '120/80', 36.6, 61.0, 165.0, '2026-10-07');

-- ---------------------------------------------------------------------
-- 7. tindakan (6 baris)
-- id_tindakan 3: Pembersihan Karang Gigi, tarif 150000.00 (Uji 7).
-- ---------------------------------------------------------------------
INSERT INTO tindakan (id_tindakan, nama_tindakan, tarif) VALUES
(1, 'Konsultasi Dokter Umum',          50000.00),
(2, 'Konsultasi Dokter Spesialis',    100000.00),
(3, 'Pembersihan Karang Gigi',        150000.00),
(4, 'Tambal Gigi',                    120000.00),
(5, 'Cek Tekanan Darah & Gula Darah',  35000.00),
(6, 'Nebulisasi',                      75000.00);

-- ---------------------------------------------------------------------
-- 8. detail_tindakan (16 baris)
-- ---------------------------------------------------------------------
INSERT INTO detail_tindakan (id_detail_tindakan, id_kunjungan, id_tindakan, jumlah) VALUES
(1,  1,  1, 1),
(2,  2,  1, 1),
(3,  2,  6, 1),
(4,  3,  3, 1),
(5,  3,  1, 1),
(6,  4,  4, 1),
(7,  4,  5, 1),
(8,  5,  1, 1),
(9,  6,  1, 1),
(10, 7,  2, 1),
(11, 7,  5, 2),
(12, 8,  2, 1),
(13, 8,  5, 1),
(14, 11, 1, 1),
(15, 12, 1, 1),
(16, 12, 5, 1);

-- ---------------------------------------------------------------------
-- 9. obat (8 baris)
-- id_obat 1: Paracetamol 500mg, harga 500.00 (Uji 7: 10 tablet = 5000).
-- id_obat 2: Amlodipine 5mg (Q8: keluar 60 tablet dari 2 resep).
-- id_obat 8: Obat Batuk Sirup, stok 5 (Uji 6: uji stok minimum).
-- Stok di bawah adalah sisa setelah seluruh detail_resep keluar.
-- ---------------------------------------------------------------------
INSERT INTO obat (id_obat, nama_obat, satuan, harga, stok) VALUES
(1, 'Paracetamol 500mg', 'Tablet',   500.00, 100),
(2, 'Amlodipine 5mg',    'Tablet',  1000.00,  40),
(3, 'Amoxicillin 500mg', 'Kapsul',  1500.00,  80),
(4, 'Ibuprofen 400mg',   'Tablet',   800.00,  60),
(5, 'Cetirizine 10mg',   'Tablet',  1000.00,  70),
(6, 'Omeprazole 20mg',   'Kapsul',  2000.00,  50),
(7, 'Vitamin C 500mg',   'Tablet',   600.00,  90),
(8, 'Obat Batuk Sirup',  'Botol',  18000.00,   5);

-- ---------------------------------------------------------------------
-- 10. detail_resep (12 baris)
-- Amlodipine 5mg (id_obat 2) keluar 30 + 30 = 60 tablet dari 2 resep.
-- ---------------------------------------------------------------------
INSERT INTO detail_resep (id_detail_resep, id_rekam, id_obat, jumlah, aturan_pakai) VALUES
(1,  1, 8,  1, '3x1 sendok teh sesudah makan'),
(2,  2, 3, 10, '3x1 kapsul sampai habis'),
(3,  2, 7,  5, '1x1 tablet pagi'),
(4,  3, 4, 10, '3x1 tablet bila nyeri'),
(5,  3, 1, 10, '3x1 tablet bila demam'),
(6,  5, 1, 10, '3x1 tablet sesudah makan'),
(7,  6, 7, 10, '1x1 tablet sesudah makan'),
(8,  7, 2, 30, '1x1 tablet pagi hari'),
(9,  7, 6,  1, '1x1 kapsul sebelum makan'),
(10, 8, 2, 30, '1x1 tablet pagi hari'),
(11, 9, 1, 10, '3x1 tablet sesudah makan'),
(12, 9, 4, 10, '2x1 tablet sesudah makan');

-- ---------------------------------------------------------------------
-- 11. pembayaran (10 baris)
-- 7 Lunas, 3 Belum Lunas (tanggal_bayar NULL).
-- Pendapatan Lunas: Poli Umum 274000, Poli Gigi 213000,
--                   Poli Penyakit Dalam 202000, Poli Anak 111000.
-- Sebaran Q9: 5 Ringan (<100000), 3 Sedang (100000-199999), 2 Berat (>=200000).
-- ---------------------------------------------------------------------
INSERT INTO pembayaran (id_pembayaran, id_kunjungan, tanggal_bayar, metode, total_tagihan, status_bayar) VALUES
(1,  1,  '2026-08-05', 'Tunai',    68000.00, 'Lunas'),
(2,  2,  '2026-08-05', 'Transfer', 143000.00, 'Lunas'),
(3,  3,  '2026-08-06', 'QRIS',    213000.00, 'Lunas'),
(4,  4,  NULL,         'Tunai',   155000.00, 'Belum Lunas'),
(5,  5,  '2026-08-12', 'Tunai',    55000.00, 'Lunas'),
(6,  6,  '2026-08-12', 'QRIS',     56000.00, 'Lunas'),
(7,  7,  '2026-09-02', 'Transfer', 202000.00, 'Lunas'),
(8,  8,  NULL,         'Transfer', 165000.00, 'Belum Lunas'),
(9,  11, '2026-10-07', 'Tunai',    63000.00, 'Lunas'),
(10, 12, NULL,         'QRIS',     85000.00, 'Belum Lunas');
