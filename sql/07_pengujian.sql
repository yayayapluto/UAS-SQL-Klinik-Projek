-- =====================================================================
-- 07_pengujian.sql
-- Pemilik : Rassya
-- Fase    : F3 uji-hijau
-- Butuh   : 01_struktur.sql sampai 06_indeks.sql, dimuat lewat
--           bash tools/reset-db.sh sebelum berkas ini dijalankan.
-- Sumber  : PRD bagian 10 dan 11, panduan Rassya
-- Tautan  : ../../docs/PRD.md dan ../../docs/panduan-anggota-6-pengujian-rilis.md
-- =====================================================================
-- Sepuluh skenario pengujian. Uji 1 sampai 6 dan Uji 10 sengaja dibuat
-- gagal (galat yang diharapkan), Uji 7 dan 9 berhasil, Uji 8 berhasil
-- membuktikan penolakan pembayaran kedua.
--
-- Cara menjalankan (wajib opsi --force karena sebagian uji sengaja gagal):
--   mysql -uroot -pkbd --force klinik_pratama < sql/07_pengujian.sql
-- Keluaran disimpan ke bukti/07_pengujian.txt.
--
-- Aturan penting:
-- 1. Jangan mengubah data contoh dari 02_data.sql. Angka uji seperti
--    jadwal 7 penuh dan obat 8 berstok 5 adalah kontrak.
-- 2. Blok pembersihan di akhir wajib ada supaya pengujian kedua tidak
--    mengubah jumlah baris laporan. Urutan hapus dari anak ke induk.
--
-- Daftar TODO Rassya. Ganti [ ] menjadi [x] setelah uji dijalankan.
-- [x] Uji 1 antrean ganda
-- [x] Uji 2 pasien tidak terdaftar
-- [x] Uji 3 suhu di luar rentang
-- [x] Uji 4 kuota jadwal penuh
-- [x] Uji 5 jadwal dokter bentrok
-- [x] Uji 6 resep melebihi stok
-- [x] Uji 7 alur normal daftar, periksa, bayar
-- [x] Uji 8 pembayaran kedua ditolak
-- [x] Uji 9 view gabungan
-- [x] Uji 10 hak akses petugas
-- [x] blok pembersihan data uji

USE klinik_pratama;

-- ---------------------------------------------------------------------
-- UJI 1. Nomor antrean ganda pada satu jadwal
-- Harapan: galat 1062 Duplicate entry, menyebut uq_kunjungan_antrean.
-- ---------------------------------------------------------------------
SELECT '--- Uji 1: antrean ganda ---' AS uji;
INSERT INTO kunjungan (id_pasien, id_jadwal, tanggal_kunjungan, no_antrean, status_kunjungan)
VALUES (5, 2, '2026-08-06', 1, 'Menunggu');

-- ---------------------------------------------------------------------
-- UJI 2. Kunjungan dengan pasien tidak terdaftar
-- Harapan: galat 1452, foreign key fk_kunjungan_pasien gagal.
-- ---------------------------------------------------------------------
SELECT '--- Uji 2: pasien tidak terdaftar ---' AS uji;
INSERT INTO kunjungan (id_pasien, id_jadwal, tanggal_kunjungan, no_antrean, status_kunjungan)
VALUES (999, 1, '2026-08-05', 9, 'Menunggu');

-- ---------------------------------------------------------------------
-- UJI 3. Suhu tubuh di luar rentang wajar
-- Harapan: galat 3819, Check constraint ck_rekam_suhu is violated.
-- ---------------------------------------------------------------------
SELECT '--- Uji 3: suhu 50 derajat ---' AS uji;
UPDATE rekam_medis SET suhu = 50.0 WHERE id_rekam = 1;

-- ---------------------------------------------------------------------
-- UJI 4. Pendaftaran melewati kuota jadwal
-- Harapan: SIGNAL SQLSTATE 45000, pesan Kuota jadwal sudah penuh.
-- ---------------------------------------------------------------------
SELECT '--- Uji 4: kuota jadwal penuh ---' AS uji;
INSERT INTO kunjungan (id_pasien, id_jadwal, tanggal_kunjungan, no_antrean, status_kunjungan)
VALUES (5, 7, '2026-10-07', 5, 'Menunggu');

-- ---------------------------------------------------------------------
-- UJI 5. Jadwal dokter bentrok
-- Harapan: SIGNAL SQLSTATE 45000, pesan Jadwal dokter bentrok.
-- ---------------------------------------------------------------------
SELECT '--- Uji 5: jadwal dokter bentrok ---' AS uji;
INSERT INTO jadwal_praktik (id_dokter, tanggal, jam_mulai, jam_selesai, ruangan, kuota)
VALUES (1, '2026-08-05', '10:00:00', '11:00:00', 'R-02', 5);

-- ---------------------------------------------------------------------
-- UJI 6. Resep melebihi stok obat
-- Harapan: SIGNAL SQLSTATE 45000, pesan Stok obat tidak cukup.
-- ---------------------------------------------------------------------
SELECT '--- Uji 6: resep melebihi stok ---' AS uji;
INSERT INTO detail_resep (id_rekam, id_obat, jumlah, aturan_pakai)
VALUES (1, 8, 99, '3x1 sendok teh');

-- ---------------------------------------------------------------------
-- UJI 7. Alur normal daftar, periksa, bayar
-- Harapan: no_antrean 1; total_tagihan 155000.00 (150000 pembersihan
-- karang gigi + 5000 sepuluh tablet Paracetamol); status Lunas.
-- ---------------------------------------------------------------------
SELECT '--- Uji 7: alur normal daftar, periksa, bayar ---' AS uji;
INSERT INTO jadwal_praktik (id_dokter, tanggal, jam_mulai, jam_selesai, ruangan, kuota)
VALUES (3, '2026-12-20', '09:00:00', '12:00:00', 'R-03', 5);
SET @id_jadwal_uji = (SELECT MAX(id_jadwal) FROM jadwal_praktik);
CALL sp_daftar_kunjungan(10, @id_jadwal_uji);
SET @id_kunjungan_uji = (SELECT MAX(id_kunjungan) FROM kunjungan);
INSERT INTO rekam_medis (id_kunjungan, keluhan, diagnosis, tekanan_darah, suhu, berat_badan, tinggi_badan, tanggal_periksa)
VALUES (@id_kunjungan_uji, 'Gigi berlubang', 'Karies dentin', '120/80', 36.7, 62.0, 165.0, '2026-12-20');
SET @id_rekam_uji = (SELECT MAX(id_rekam) FROM rekam_medis);
INSERT INTO detail_tindakan (id_kunjungan, id_tindakan, jumlah)
VALUES (@id_kunjungan_uji, 3, 1);
INSERT INTO detail_resep (id_rekam, id_obat, jumlah, aturan_pakai)
VALUES (@id_rekam_uji, 1, 10, '3x1 tablet');
CALL sp_bayar_kunjungan(@id_kunjungan_uji, 'Tunai');
SELECT b.id_pembayaran, b.id_kunjungan, b.total_tagihan, b.status_bayar
FROM pembayaran b WHERE b.id_kunjungan = @id_kunjungan_uji;
SELECT 'Hitungan manual (tindakan + obat) kunjungan uji:' AS periksa,
    COALESCE((SELECT SUM(dt.jumlah * t.tarif) FROM detail_tindakan dt
        JOIN tindakan t ON t.id_tindakan = dt.id_tindakan
        WHERE dt.id_kunjungan = @id_kunjungan_uji), 0)
    +
    COALESCE((SELECT SUM(dr.jumlah * o.harga) FROM detail_resep dr
        JOIN rekam_medis rm ON rm.id_rekam = dr.id_rekam
        JOIN obat o ON o.id_obat = dr.id_obat
        WHERE rm.id_kunjungan = @id_kunjungan_uji), 0) AS total_manual;

-- ---------------------------------------------------------------------
-- UJI 8. Membayar kunjungan yang sudah lunas
-- Harapan: SIGNAL SQLSTATE 45000, pesan Kunjungan sudah dibayar, dan
-- jumlah baris pembayaran kunjungan uji tetap satu.
-- ---------------------------------------------------------------------
SELECT '--- Uji 8: pembayaran kedua ditolak ---' AS uji;
CALL sp_bayar_kunjungan(@id_kunjungan_uji, 'Tunai');
SELECT COUNT(*) AS jumlah_pembayaran_kunjungan_uji
FROM pembayaran WHERE id_kunjungan = @id_kunjungan_uji;

-- ---------------------------------------------------------------------
-- UJI 9. View gabungan v_kunjungan_lengkap
-- Harapan: view menampilkan riwayat kunjungan lengkap. Pada titik ini
-- view berisi 15 baris, yaitu 14 baris data contoh ditambah 1 kunjungan
-- uji dari Uji 7 (catatan: draf panduan menulis 14 di sini, padahal
-- kunjungan uji ikut tampil di view; angka 14 kembali setelah blok
-- pembersihan di bawah).
-- ---------------------------------------------------------------------
SELECT '--- Uji 9: view v_kunjungan_lengkap ---' AS uji;
SELECT COUNT(*) AS jumlah_baris_view FROM v_kunjungan_lengkap;
SELECT id_kunjungan, nama_pasien, nama_dokter, nama_poli, status_bayar
FROM v_kunjungan_lengkap ORDER BY id_kunjungan;

-- ---------------------------------------------------------------------
-- UJI 10. Hak akses petugas
-- Harapan: SHOW GRANTS menampilkan hak SELECT dan INSERT petugas pada
-- tabel yang diizinkan. Percobaan INSERT ke obat TIDAK ditulis di sini
-- karena skrip dijalankan sebagai root; jalankan terpisah sebagai
-- petugas_klinik (lihat bukti/05_keamanan.txt): ditolak ERROR 1142.
-- ---------------------------------------------------------------------
SELECT '--- Uji 10: hak akses petugas ---' AS uji;
SHOW GRANTS FOR 'petugas_klinik'@'%';

-- ---------------------------------------------------------------------
-- PEMBERSIHAN
-- Mengembalikan isi tabel persis seperti setelah 02_data.sql supaya
-- pengujian bisa dijalankan berulang dan jumlah baris laporan tetap
-- stabil. Urutan hapus dari anak ke induk. Stok obat 1 dikembalikan
-- (+10) karena trg_kurangi_stok sudah menguranginya pada Uji 7.
-- ---------------------------------------------------------------------
SELECT '--- Pembersihan data uji ---' AS uji;
DELETE FROM pembayaran WHERE id_kunjungan = @id_kunjungan_uji;
DELETE FROM detail_resep WHERE id_rekam = @id_rekam_uji;
DELETE FROM detail_tindakan WHERE id_kunjungan = @id_kunjungan_uji;
DELETE FROM rekam_medis WHERE id_rekam = @id_rekam_uji;
DELETE FROM kunjungan WHERE id_kunjungan = @id_kunjungan_uji;
DELETE FROM jadwal_praktik WHERE id_jadwal = @id_jadwal_uji;
UPDATE obat SET stok = stok + 10 WHERE id_obat = 1;
SELECT COUNT(*) AS jumlah_kunjungan FROM kunjungan;
SELECT COUNT(*) AS jumlah_pembayaran FROM pembayaran;
SELECT COUNT(*) AS jumlah_jadwal FROM jadwal_praktik;
SELECT COUNT(*) AS jumlah_rekam_medis FROM rekam_medis;
SELECT id_obat, nama_obat, stok FROM obat WHERE id_obat = 1;

-- =====================================================================
-- Pemeriksaan
--   bash tools/reset-db.sh, lalu jalankan berkas ini dengan --force.
--   Keluaran diharapkan: Uji 1 galat 1062, Uji 2 galat 1452, Uji 3
--   galat 3819, Uji 4 pesan Kuota jadwal sudah penuh, Uji 5 pesan
--   Jadwal dokter bentrok, Uji 6 pesan Stok obat tidak cukup, Uji 7
--   antrean 1 dan total 155000.00, Uji 8 pesan Kunjungan sudah
--   dibayar, Uji 9 view 15 baris sebelum pembersihan (14 sesudahnya),
--   Uji 10 SHOW GRANTS tampil. Pembersihan berakhir dengan jumlah
--   baris yang sama seperti setelah 02_data.sql.
-- =====================================================================
