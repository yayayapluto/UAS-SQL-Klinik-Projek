-- =====================================================================
-- 05_keamanan.sql
-- Pemilik : Kafka
-- Fase    : F2 objek-sql
-- Butuh   : 01_struktur.sql
-- Sumber  : PRD bagian 8, panduan Kafka
-- Tautan  : ../../docs/PRD.md dan ../../docs/panduan-anggota-5-keamanan-indeks.md
-- =====================================================================
-- Tiga pengguna database beserta hak aksesnya pada klinik_pratama.
-- Jalankan sebagai root. Skrip memakai DROP USER IF EXISTS agar aman
-- diulang, lalu membuat pengguna baru dengan host %, lalu memberi hak,
-- lalu FLUSH PRIVILEGES, lalu menampilkan SHOW GRANTS sebagai bukti.
-- Kata sandi latihan: Klinik#2026.
--
-- Daftar TODO Kafka. Ganti [ ] menjadi [x] setelah hak diuji.
-- [x] pengguna petugas_klinik dan haknya
-- [x] pengguna dokter_klinik dan haknya
-- [x] pengguna admin_klinik dan haknya
-- [x] SHOW GRANTS dan bukti penolakan 1142

USE klinik_pratama;

-- ---------------------------------------------------------------------
-- 1. Akun petugas_klinik (meja depan)
--    SELECT pada poli, dokter, jadwal_praktik; SELECT dan INSERT pada
--    pasien serta kunjungan. Tanpa hak pada obat, rekam_medis, dan
--    pembayaran.
-- ---------------------------------------------------------------------
DROP USER IF EXISTS 'petugas_klinik'@'%';
CREATE USER 'petugas_klinik'@'%' IDENTIFIED BY 'Klinik#2026';
GRANT SELECT ON klinik_pratama.poli TO 'petugas_klinik'@'%';
GRANT SELECT ON klinik_pratama.dokter TO 'petugas_klinik'@'%';
GRANT SELECT ON klinik_pratama.jadwal_praktik TO 'petugas_klinik'@'%';
GRANT SELECT, INSERT ON klinik_pratama.pasien TO 'petugas_klinik'@'%';
GRANT SELECT, INSERT ON klinik_pratama.kunjungan TO 'petugas_klinik'@'%';

-- ---------------------------------------------------------------------
-- 2. Akun dokter_klinik (tenaga medis)
--    SELECT pada seluruh tabel; INSERT dan UPDATE pada rekam_medis dan
--    detail_resep. Tidak ada DELETE, karena riwayat medis tidak dihapus.
-- ---------------------------------------------------------------------
DROP USER IF EXISTS 'dokter_klinik'@'%';
CREATE USER 'dokter_klinik'@'%' IDENTIFIED BY 'Klinik#2026';
GRANT SELECT ON klinik_pratama.* TO 'dokter_klinik'@'%';
GRANT INSERT, UPDATE ON klinik_pratama.rekam_medis TO 'dokter_klinik'@'%';
GRANT INSERT, UPDATE ON klinik_pratama.detail_resep TO 'dokter_klinik'@'%';

-- ---------------------------------------------------------------------
-- 3. Akun admin_klinik (pengelola sistem)
--    ALL PRIVILEGES pada klinik_pratama.* (satu database, bukan server).
-- ---------------------------------------------------------------------
DROP USER IF EXISTS 'admin_klinik'@'%';
CREATE USER 'admin_klinik'@'%' IDENTIFIED BY 'Klinik#2026';
GRANT ALL PRIVILEGES ON klinik_pratama.* TO 'admin_klinik'@'%';

FLUSH PRIVILEGES;
SHOW GRANTS FOR 'petugas_klinik'@'%';
SHOW GRANTS FOR 'dokter_klinik'@'%';
SHOW GRANTS FOR 'admin_klinik'@'%';

-- ---------------------------------------------------------------------
-- Pemeriksaan
-- ---------------------------------------------------------------------
--   bash tools/reset-db.sh
--     Keluaran diharapkan: 05_keamanan.sql dieksekusi tanpa error dan
--     database klinik_pratama berisi tiga pengguna.
--   bash tools/verify.sh
--     Bagian F harus lulus tiga pemeriksaan: GRANT petugas_klinik,
--     GRANT dokter_klinik, dan penolakan INSERT ke obat dengan galat
--     1142. Total keseluruhan tetap 34 pemeriksaan lulus.
--   Percobaan INSERT ke obat oleh petugas_klinik, dijalankan terpisah
--   sebagai akun tersebut (bukan root):
--     mysql -upetugas_klinik -p'Klinik#2026' klinik_pratama -e
--       "INSERT INTO obat (nama_obat, satuan, harga, stok)
--        VALUES ('Uji Ilegal', 'Tablet', 1000.00, 1);"
--     Keluaran diharapkan: ERROR 1142 (42000), command denied untuk
--     pengguna petugas_klinik pada tabel obat.
-- =====================================================================
