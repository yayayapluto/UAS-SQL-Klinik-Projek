-- =====================================================================
-- 03_view_trigger.sql
-- Pemilik : Kenzie
-- Fase    : F2 objek-sql
-- Butuh   : 01_struktur.sql dan 02_data.sql
-- Sumber  : PRD bagian 6 dan 8, panduan Kenzie
-- Tautan  : ../../docs/PRD.md dan ../../docs/panduan-anggota-4-view-trigger-prosedur.md
-- =====================================================================
-- Dua view dan empat trigger untuk Sistem Informasi Klinik Pratama.
-- Pesan penolakan memakai SIGNAL SQLSTATE 45000 dengan teks yang sama
-- persis seperti yang dicari verify.sh bagian E dan 07_pengujian.sql.
--
-- Daftar TODO Kenzie. Ganti [ ] menjadi [x] setelah objek diuji.
-- [x] view v_kunjungan_lengkap
-- [x] view v_pendapatan_poli
-- [x] trigger trg_cek_kuota_jadwal
-- [x] trigger trg_cek_bentrok_jadwal
-- [x] trigger trg_cek_stok_obat
-- [x] trigger trg_kurangi_stok
-- [x] semua objek memakai DROP IF EXISTS dan aman diulang

USE klinik_pratama;

-- ---------------------------------------------------------------------
-- 1. View v_kunjungan_lengkap
--    Satu baris = satu kunjungan (14 baris pada data contoh).
--    LEFT JOIN pembayaran agar kunjungan tanpa tagihan tetap muncul,
--    status_bayar-nya tampil 'Belum Ada Tagihan' lewat COALESCE.
-- ---------------------------------------------------------------------
DROP VIEW IF EXISTS v_kunjungan_lengkap;
CREATE VIEW v_kunjungan_lengkap AS
SELECT
    k.id_kunjungan,
    k.tanggal_kunjungan,
    k.no_antrean,
    k.status_kunjungan,
    k.id_pasien,
    ps.nama_pasien,
    j.id_dokter,
    d.nama_dokter,
    d.tipe_dokter,
    p.nama_poli,
    j.ruangan,
    j.jam_mulai,
    j.jam_selesai,
    COALESCE(b.status_bayar, 'Belum Ada Tagihan') AS status_bayar,
    b.total_tagihan
FROM kunjungan k
JOIN pasien ps ON ps.id_pasien = k.id_pasien
JOIN jadwal_praktik j ON j.id_jadwal = k.id_jadwal
JOIN dokter d ON d.id_dokter = j.id_dokter
JOIN poli p ON p.id_poli = d.id_poli
LEFT JOIN pembayaran b ON b.id_kunjungan = k.id_kunjungan;

-- ---------------------------------------------------------------------
-- 2. View v_pendapatan_poli
--    Ringkasan pendapatan per poli per bulan. Hanya pembayaran Lunas
--    yang dihitung, supaya piutang tidak menambah angka pendapatan.
-- ---------------------------------------------------------------------
DROP VIEW IF EXISTS v_pendapatan_poli;
CREATE VIEW v_pendapatan_poli AS
SELECT
    p.nama_poli,
    DATE_FORMAT(k.tanggal_kunjungan, '%Y-%m') AS bulan,
    COUNT(b.id_pembayaran) AS jumlah_kunjungan,
    SUM(b.total_tagihan) AS total_pendapatan
FROM pembayaran b
JOIN kunjungan k ON k.id_kunjungan = b.id_kunjungan
JOIN jadwal_praktik j ON j.id_jadwal = k.id_jadwal
JOIN dokter d ON d.id_dokter = j.id_dokter
JOIN poli p ON p.id_poli = d.id_poli
WHERE b.status_bayar = 'Lunas'
GROUP BY p.nama_poli, DATE_FORMAT(k.tanggal_kunjungan, '%Y-%m');

-- ---------------------------------------------------------------------
-- 3. Trigger trg_cek_kuota_jadwal
--    BEFORE INSERT pada kunjungan. Menolak pendaftaran yang melampaui
--    kuota sesi. Kunjungan Batal tidak dihitung sebagai pemakaian kuota.
--    Aturan bisnis 1. Bukti: Uji 4.
-- ---------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_cek_kuota_jadwal;
DELIMITER //
CREATE TRIGGER trg_cek_kuota_jadwal
BEFORE INSERT ON kunjungan
FOR EACH ROW
BEGIN
    DECLARE v_kuota INT;
    DECLARE v_terpakai INT;
    IF NEW.status_kunjungan <> 'Batal' THEN
        SELECT kuota INTO v_kuota FROM jadwal_praktik WHERE id_jadwal = NEW.id_jadwal;
        SELECT COUNT(*) INTO v_terpakai FROM kunjungan
            WHERE id_jadwal = NEW.id_jadwal AND status_kunjungan <> 'Batal';
        IF v_terpakai >= v_kuota THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Kuota jadwal sudah penuh';
        END IF;
    END IF;
END //
DELIMITER ;

-- ---------------------------------------------------------------------
-- 4. Trigger trg_cek_bentrok_jadwal
--    BEFORE INSERT pada jadwal_praktik. Satu dokter tidak memegang dua
--    sesi beririsan pada tanggal yang sama. Aturan bisnis 2. Bukti: Uji 5.
-- ---------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_cek_bentrok_jadwal;
DELIMITER //
CREATE TRIGGER trg_cek_bentrok_jadwal
BEFORE INSERT ON jadwal_praktik
FOR EACH ROW
BEGIN
    DECLARE v_bentrok INT;
    SELECT COUNT(*) INTO v_bentrok FROM jadwal_praktik
        WHERE id_dokter = NEW.id_dokter
          AND tanggal = NEW.tanggal
          AND jam_mulai < NEW.jam_selesai
          AND jam_selesai > NEW.jam_mulai;
    IF v_bentrok > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Jadwal dokter bentrok';
    END IF;
END //
DELIMITER ;

-- ---------------------------------------------------------------------
-- 5. Trigger trg_cek_stok_obat
--    BEFORE INSERT pada detail_resep. Resep tidak boleh melebihi stok.
--    Aturan bisnis 7. Bukti: Uji 6.
-- ---------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_cek_stok_obat;
DELIMITER //
CREATE TRIGGER trg_cek_stok_obat
BEFORE INSERT ON detail_resep
FOR EACH ROW
BEGIN
    DECLARE v_stok INT;
    SELECT stok INTO v_stok FROM obat WHERE id_obat = NEW.id_obat;
    IF v_stok < NEW.jumlah THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Stok obat tidak cukup';
    END IF;
END //
DELIMITER ;

-- ---------------------------------------------------------------------
-- 6. Trigger trg_kurangi_stok
--    AFTER INSERT pada detail_resep. Stok berkurang otomatis sebesar
--    jumlah yang diresepkan. Urutan penting: pemeriksaan (BEFORE)
--    lebih dulu, pengurangan (AFTER) kemudian. Aturan bisnis 7.
-- ---------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_kurangi_stok;
DELIMITER //
CREATE TRIGGER trg_kurangi_stok
AFTER INSERT ON detail_resep
FOR EACH ROW
BEGIN
    UPDATE obat SET stok = stok - NEW.jumlah WHERE id_obat = NEW.id_obat;
END //
DELIMITER ;

-- ---------------------------------------------------------------------
-- Pemeriksaan
-- ---------------------------------------------------------------------
--   bash tools/reset-db.sh
--     Harapan: seluruh berkas 01 sampai 06 selesai tanpa galat, jumlah
--     view di database menjadi 2.
--   bash tools/verify.sh
--     Harapan: 34 pemeriksaan lulus. Yang berkaitan dengan berkas ini:
--     - Bagian C: baris view v_kunjungan_lengkap bernilai 14.
--     - Bagian C: sisa kuota jadwal 7 bernilai 0.
--     - Bagian E: pendaftaran melewati kuota ditolak dengan pesan
--       Kuota jadwal sudah penuh; jadwal dokter bentrok ditolak dengan
--       pesan Jadwal dokter bentrok; resep melebihi stok ditolak dengan
--       pesan Stok obat tidak cukup.
--   SELECT dari v_kunjungan_lengkap
--     Harapan: 14 baris. Kunjungan tanpa pembayaran menampilkan
--     Belum Ada Tagihan pada status_bayar.
--   SELECT dari v_pendapatan_poli
--     Harapan: baris per poli per bulan, hanya dari pembayaran Lunas.
-- =====================================================================
