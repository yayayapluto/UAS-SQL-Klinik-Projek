-- =====================================================================
-- 06_indeks.sql
-- Pemilik : Kenzie
-- Fase    : F2 objek-sql
-- Butuh   : 01_struktur.sql dan 02_data.sql
-- Sumber  : PRD bagian 8 dan 9, panduan Kafka
-- Tautan  : ../../docs/PRD.md dan ../../docs/panduan-anggota-5-keamanan-indeks.md
-- =====================================================================
-- Dua indeks beserta bukti rencana eksekusi sebelum dan sesudah indeks
-- terpasang. MySQL 8.0.16 tidak punya DROP INDEX IF EXISTS, jadi
-- pembuatan indeks didahului pemeriksaan keberadaan nama indeks pada
-- information_schema.statistics; tanpa itu reset-db.sh kedua kali gagal
-- dengan galat 1061 Duplicate key name.
--
-- Daftar TODO Kenzie. Ganti [ ] menjadi [x] setelah indeks dibuktikan.
-- [x] idx_pasien_nama pada pasien(nama_pasien)
-- [x] idx_kunjungan_tanggal pada kunjungan(tanggal_kunjungan, id_jadwal)
-- [x] EXPLAIN sebelum dan sesudah untuk kedua query
-- [x] SHOW INDEX dan bukti ke verify.sh bagian D

USE klinik_pratama;

-- ---------------------------------------------------------------------
-- 1. idx_pasien_nama
--    Melayani pencarian awalan nama: nama_pasien LIKE 'A%'.
--    Sebelum: type ALL, key NULL, rows 10. Sesudah: type range,
--    key idx_pasien_nama, rows 1.
-- ---------------------------------------------------------------------
SELECT '--- EXPLAIN sebelum idx_pasien_nama ---' AS bukti;
EXPLAIN SELECT * FROM pasien WHERE nama_pasien LIKE 'A%';

SET @idx := (SELECT COUNT(*) FROM information_schema.statistics
    WHERE table_schema = 'klinik_pratama' AND table_name = 'pasien'
      AND index_name = 'idx_pasien_nama');
SET @sql := IF(@idx > 0, 'DROP INDEX idx_pasien_nama ON pasien', 'SELECT 1');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

CREATE INDEX idx_pasien_nama ON pasien (nama_pasien);

SELECT '--- EXPLAIN sesudah idx_pasien_nama ---' AS bukti;
EXPLAIN SELECT * FROM pasien WHERE nama_pasien LIKE 'A%';

-- ---------------------------------------------------------------------
-- 2. idx_kunjungan_tanggal
--    Melayani penyaringan tanggal: tanggal_kunjungan = '2026-09-10'.
--    Kolom tanggal diletakkan lebih dulu karena dipakai sendirian pada
--    penyaringan; kolom kedua melayani laporan tanggal sekaligus jadwal.
--    Sebelum: type ALL, key NULL, rows 14. Sesudah: type ref,
--    key idx_kunjungan_tanggal, rows 1.
-- ---------------------------------------------------------------------
SELECT '--- EXPLAIN sebelum idx_kunjungan_tanggal ---' AS bukti;
EXPLAIN SELECT * FROM kunjungan WHERE tanggal_kunjungan = '2026-09-10';

SET @idx := (SELECT COUNT(*) FROM information_schema.statistics
    WHERE table_schema = 'klinik_pratama' AND table_name = 'kunjungan'
      AND index_name = 'idx_kunjungan_tanggal');
SET @sql := IF(@idx > 0, 'DROP INDEX idx_kunjungan_tanggal ON kunjungan', 'SELECT 1');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

CREATE INDEX idx_kunjungan_tanggal ON kunjungan (tanggal_kunjungan, id_jadwal);

SELECT '--- EXPLAIN sesudah idx_kunjungan_tanggal ---' AS bukti;
EXPLAIN SELECT * FROM kunjungan WHERE tanggal_kunjungan = '2026-09-10';

-- ---------------------------------------------------------------------
-- 3. Bukti struktur indeks
-- ---------------------------------------------------------------------
SHOW INDEX FROM pasien;
SHOW INDEX FROM kunjungan;

-- ---------------------------------------------------------------------
-- Pemeriksaan
-- ---------------------------------------------------------------------
--   bash tools/reset-db.sh
--     Harapan: seluruh berkas 01 sampai 06 selesai tanpa galat,
--     database klinik_pratama berisi 2 indeks.
--   bash tools/reset-db.sh sekali lagi
--     Harapan: tetap tanpa galat dan tanpa pesan 1061 Duplicate key
--     name. Ini membuktikan bagian pembuangan indeks bekerja.
--   bash tools/verify.sh
--     Harapan: 34 pemeriksaan lulus, termasuk bagian D dua pemeriksaan
--     yang membaca kolom key dari EXPLAIN untuk kedua indeks.
-- =====================================================================
