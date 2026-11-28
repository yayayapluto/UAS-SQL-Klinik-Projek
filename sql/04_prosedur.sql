-- =====================================================================
-- 04_prosedur.sql
-- Pemilik : Agit
-- Fase    : F2 objek-sql
-- Butuh   : 01_struktur.sql dan 02_data.sql
-- Sumber  : PRD bagian 6 dan 8, panduan Kenzie
-- Tautan  : ../../docs/PRD.md dan ../../docs/panduan-anggota-4-view-trigger-prosedur.md
-- =====================================================================
-- Dua prosedur simpan untuk Sistem Informasi Klinik Pratama. Keduanya
-- bukti sifat atomicity: seluruh langkah berjalan dalam satu transaksi,
-- dan kegagalan di tengah jalan tidak meninggalkan baris setengah jadi.
-- Keduanya memakai EXIT HANDLER FOR SQLEXCEPTION yang menjalankan
-- ROLLBACK lalu RESIGNAL.
--
-- Daftar TODO Agit. Ganti [ ] menjadi [x] setelah prosedur diuji.
-- [x] sp_daftar_kunjungan
-- [x] sp_bayar_kunjungan
-- [x] kedua prosedur memakai transaksi, handler rollback, dan dapat diulang

USE klinik_pratama;

-- ---------------------------------------------------------------------
-- 1. Prosedur sp_daftar_kunjungan
--    Masuk: p_id_pasien, p_id_jadwal. Hasil dikembalikan lewat SELECT
--    (id_kunjungan_baru, no_antrean) supaya pemanggilan cukup dua
--    argumen, seperti yang dipakai verify.sh bagian G dan Uji 7.
--    Kuota TIDAK diperiksa di sini, diserahkan ke
--    trg_cek_kuota_jadwal (aturan bisnis 1).
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_daftar_kunjungan;
DELIMITER //
CREATE PROCEDURE sp_daftar_kunjungan(
    IN p_id_pasien INT,
    IN p_id_jadwal INT
)
BEGIN
    DECLARE v_tanggal DATE;
    DECLARE v_antrean INT;
    DECLARE v_id_kunjungan INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    START TRANSACTION;
    SELECT tanggal INTO v_tanggal FROM jadwal_praktik WHERE id_jadwal = p_id_jadwal;
    IF v_tanggal IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Jadwal tidak ditemukan';
    END IF;
    IF v_tanggal < CURDATE() THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Jadwal sudah lewat, tidak bisa didaftari';
    END IF;
    SELECT COALESCE(MAX(no_antrean), 0) + 1 INTO v_antrean
        FROM kunjungan WHERE id_jadwal = p_id_jadwal;
    INSERT INTO kunjungan (id_pasien, id_jadwal, tanggal_kunjungan, no_antrean, status_kunjungan)
        VALUES (p_id_pasien, p_id_jadwal, v_tanggal, v_antrean, 'Menunggu');
    SET v_id_kunjungan = LAST_INSERT_ID();
    COMMIT;
    SELECT v_id_kunjungan AS id_kunjungan_baru, v_antrean AS no_antrean;
END //
DELIMITER ;

-- ---------------------------------------------------------------------
-- 2. Prosedur sp_bayar_kunjungan
--    Masuk: p_id_kunjungan, p_metode. Hasil dikembalikan lewat SELECT
--    (total_dibayar) supaya pemanggilan cukup dua argumen, seperti yang
--    dipakai verify.sh bagian G dan Uji 7.
--    Total dihitung sendiri dari tindakan + obat (aturan bisnis 6),
--    bukan disalin dari masukan pemanggil.
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_bayar_kunjungan;
DELIMITER //
CREATE PROCEDURE sp_bayar_kunjungan(
    IN p_id_kunjungan INT,
    IN p_metode VARCHAR(20)
)
BEGIN
    DECLARE v_sudah INT;
    DECLARE v_total DECIMAL(12,2);
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    START TRANSACTION;
    SELECT COUNT(*) INTO v_sudah FROM pembayaran WHERE id_kunjungan = p_id_kunjungan;
    IF v_sudah > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Kunjungan sudah dibayar';
    END IF;
    SELECT
        COALESCE((SELECT SUM(dt.jumlah * t.tarif)
                    FROM detail_tindakan dt
                    JOIN tindakan t ON t.id_tindakan = dt.id_tindakan
                   WHERE dt.id_kunjungan = p_id_kunjungan), 0)
        +
        COALESCE((SELECT SUM(dr.jumlah * o.harga)
                    FROM detail_resep dr
                    JOIN rekam_medis rm ON rm.id_rekam = dr.id_rekam
                    JOIN obat o ON o.id_obat = dr.id_obat
                   WHERE rm.id_kunjungan = p_id_kunjungan), 0)
        INTO v_total;
    INSERT INTO pembayaran (id_kunjungan, tanggal_bayar, metode, total_tagihan, status_bayar)
        VALUES (p_id_kunjungan, CURDATE(), p_metode, v_total, 'Lunas');
    COMMIT;
    SELECT v_total AS total_dibayar;
END //
DELIMITER ;

-- ---------------------------------------------------------------------
-- Pemeriksaan
-- ---------------------------------------------------------------------
--   bash tools/reset-db.sh
--     Harapan: seluruh berkas 01 sampai 06 selesai tanpa galat, dan
--     kedua prosedur muncul pada daftar rutin database klinik_pratama.
--   bash tools/verify.sh
--     Harapan: 34 pemeriksaan lulus. Bagian G: total tagihan sama
--     dengan hitungan manual (0 baris selisih), membayar dua kali
--     ditolak dengan pesan Kunjungan sudah dibayar, dan insert yang
--     gagal tidak menyisakan baris (0 baris bertotal nol).
--   Uji 7 pada 07_pengujian.sql
--     Harapan: pendaftaran pada jadwal baru menghasilkan no_antrean 1.
--     Pembayaran menghasilkan total_tagihan 155000, yaitu 150000 biaya
--     pembersihan karang gigi ditambah 5000 harga sepuluh tablet
--     Paracetamol, dengan status Lunas.
--   Uji 8 pada 07_pengujian.sql
--     Harapan: pemanggilan kedua ditolak dengan pesan
--     Kunjungan sudah dibayar, dan jumlah baris pembayaran untuk
--     kunjungan itu tetap satu.
-- =====================================================================
