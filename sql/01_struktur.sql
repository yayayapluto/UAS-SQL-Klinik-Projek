-- =====================================================================
-- 01_struktur.sql
-- Pemilik : Farras
-- Fase    : F1 skema-v1
-- Butuh   : tidak ada
-- Sumber  : PRD bagian 5 dan 10, panduan Farras
-- Tautan  : ../../docs/PRD.md dan ../../docs/panduan-anggota-3-struktur-transformasi.md
-- =====================================================================
-- DRAF untuk direview sebelum PR (belum di-commit, belum di-push).
-- Membuat database klinik_pratama (utf8mb4, utf8mb4_unicode_ci) dan
-- tepat 11 tabel, mesin InnoDB, sesuai PRD bagian 5.2. Semua kunci tamu
-- memakai ON DELETE RESTRICT ON UPDATE CASCADE (PRD bagian 2 dan 5.3).
-- DROP TABLE IF EXISTS diurutkan dari anak ke induk supaya skrip bisa
-- dijalankan ulang (PRD bagian 10); CREATE diurutkan dari induk ke anak.
-- Pemeriksaan kunci tamu tidak dimatikan untuk melewati urutan ini.
--
-- Daftar TODO Farras. Ganti [ ] menjadi [x] setelah objek selesai.
-- [x] database klinik_pratama, utf8mb4, utf8mb4_unicode_ci
-- [x] urutan DROP TABLE dari anak ke induk
-- [x] tabel poli
-- [x] tabel dokter
-- [x] tabel jadwal_praktik
-- [x] tabel pasien
-- [x] tabel kunjungan
-- [x] tabel rekam_medis
-- [x] tabel tindakan
-- [x] tabel detail_tindakan
-- [x] tabel obat
-- [x] tabel detail_resep
-- [x] tabel pembayaran
-- [x] seluruh kunci primer, unique, check, dan kunci tamu
-- [x] mesin InnoDB pada semua tabel

-- ---------------------------------------------------------------------
-- 1. Database
-- ---------------------------------------------------------------------
-- Buat database klinik_pratama dengan karakter utf8mb4 dan kolasi
-- utf8mb4_unicode_ci, lalu aktifkan database tersebut sebelum tabel dibuat.

CREATE DATABASE IF NOT EXISTS klinik_pratama
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;
USE klinik_pratama;

-- ---------------------------------------------------------------------
-- 2. Urutan eksekusi
-- ---------------------------------------------------------------------
-- Pengulangan skrip dimulai dengan menghapus tabel memakai DROP TABLE IF
-- EXISTS dari anak ke induk:
--   pembayaran, detail_resep, obat, detail_tindakan, tindakan,
--   rekam_medis, kunjungan, pasien, jadwal_praktik, dokter, poli
-- Setelah bersih, tabel dibuat dari induk ke anak:
--   poli, dokter, jadwal_praktik, pasien, kunjungan, rekam_medis,
--   tindakan, detail_tindakan, obat, detail_resep, pembayaran

DROP TABLE IF EXISTS pembayaran;
DROP TABLE IF EXISTS detail_resep;
DROP TABLE IF EXISTS obat;
DROP TABLE IF EXISTS detail_tindakan;
DROP TABLE IF EXISTS tindakan;
DROP TABLE IF EXISTS rekam_medis;
DROP TABLE IF EXISTS kunjungan;
DROP TABLE IF EXISTS pasien;
DROP TABLE IF EXISTS jadwal_praktik;
DROP TABLE IF EXISTS dokter;
DROP TABLE IF EXISTS poli;

-- ---------------------------------------------------------------------
-- 3. Tabel poli
-- ---------------------------------------------------------------------
-- Kolom:
--   id_poli, nama_poli, lantai
-- Kunci primer:
--   id_poli, AUTO_INCREMENT.
-- Unik:
--   uq_poli_nama pada (nama_poli).
-- Kunci tamu:
--   tidak ada, poli adalah tabel induk paling atas.

CREATE TABLE poli (
    id_poli   INT         NOT NULL AUTO_INCREMENT,
    nama_poli VARCHAR(50) NOT NULL,
    lantai    VARCHAR(10) NOT NULL,
    PRIMARY KEY (id_poli),
    CONSTRAINT uq_poli_nama UNIQUE (nama_poli)
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- 4. Tabel dokter
-- ---------------------------------------------------------------------
-- Kolom:
--   id_dokter, id_poli, nama_dokter, no_sip, email, no_telp, tipe_dokter
-- Kunci primer:
--   id_dokter, AUTO_INCREMENT.
-- Unik:
--   uq_dokter_sip pada (no_sip).
--   uq_dokter_email pada (email).
-- Kunci tamu:
--   fk_dokter_poli: id_poli merujuk poli(id_poli),
--   ON DELETE RESTRICT ON UPDATE CASCADE.
-- Catatan:
--   tipe_dokter memakai ENUM('Umum', 'Spesialis'), DEFAULT 'Umum'.

CREATE TABLE dokter (
    id_dokter   INT          NOT NULL AUTO_INCREMENT,
    id_poli     INT          NOT NULL,
    nama_dokter VARCHAR(100) NOT NULL,
    no_sip      VARCHAR(30)  NOT NULL,
    email       VARCHAR(100) NOT NULL,
    no_telp     VARCHAR(20)  NULL,
    tipe_dokter ENUM('Umum', 'Spesialis') NOT NULL DEFAULT 'Umum',
    PRIMARY KEY (id_dokter),
    CONSTRAINT uq_dokter_sip   UNIQUE (no_sip),
    CONSTRAINT uq_dokter_email UNIQUE (email),
    CONSTRAINT fk_dokter_poli FOREIGN KEY (id_poli)
        REFERENCES poli (id_poli)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- 5. Tabel jadwal_praktik
-- ---------------------------------------------------------------------
-- Kolom:
--   id_jadwal, id_dokter, tanggal, jam_mulai, jam_selesai, ruangan, kuota
-- Kunci primer:
--   id_jadwal, AUTO_INCREMENT.
-- Unik:
--   uq_jadwal_sesi pada (id_dokter, tanggal, jam_mulai), mencegah satu
--   dokter punya dua sesi dengan awal yang sama pada tanggal yang sama.
-- CHECK:
--   ck_jadwal_jam: jam_selesai > jam_mulai.
--   ck_jadwal_kuota: kuota > 0.
-- Kunci tamu:
--   fk_jadwal_dokter: id_dokter merujuk dokter(id_dokter),
--   ON DELETE RESTRICT ON UPDATE CASCADE.
-- Catatan:
--   kolom hari tidak disimpan; diturunkan dari tanggal dengan DAYNAME().

CREATE TABLE jadwal_praktik (
    id_jadwal   INT         NOT NULL AUTO_INCREMENT,
    id_dokter   INT         NOT NULL,
    tanggal     DATE        NOT NULL,
    jam_mulai   TIME        NOT NULL,
    jam_selesai TIME        NOT NULL,
    ruangan     VARCHAR(30) NOT NULL,
    kuota       INT         NOT NULL,
    PRIMARY KEY (id_jadwal),
    CONSTRAINT uq_jadwal_sesi UNIQUE (id_dokter, tanggal, jam_mulai),
    CONSTRAINT ck_jadwal_jam   CHECK (jam_selesai > jam_mulai),
    CONSTRAINT ck_jadwal_kuota CHECK (kuota > 0),
    CONSTRAINT fk_jadwal_dokter FOREIGN KEY (id_dokter)
        REFERENCES dokter (id_dokter)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- 6. Tabel pasien
-- ---------------------------------------------------------------------
-- Kolom:
--   id_pasien, nama_pasien, nik, email, no_telp, tanggal_lahir, alamat
-- Kunci primer:
--   id_pasien, AUTO_INCREMENT.
-- Unik:
--   uq_pasien_nik pada (nik).
--   uq_pasien_email pada (email).
-- Kunci tamu:
--   tidak ada, pasien adalah tabel induk untuk kunjungan.

CREATE TABLE pasien (
    id_pasien     INT          NOT NULL AUTO_INCREMENT,
    nama_pasien   VARCHAR(100) NOT NULL,
    nik           CHAR(16)     NOT NULL,
    email         VARCHAR(100) NULL,
    no_telp       VARCHAR(20)  NULL,
    tanggal_lahir DATE         NOT NULL,
    alamat        VARCHAR(200) NULL,
    PRIMARY KEY (id_pasien),
    CONSTRAINT uq_pasien_nik   UNIQUE (nik),
    CONSTRAINT uq_pasien_email UNIQUE (email)
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- 7. Tabel kunjungan
-- ---------------------------------------------------------------------
-- Kolom:
--   id_kunjungan, id_pasien, id_jadwal, tanggal_kunjungan, no_antrean,
--   status_kunjungan
-- Kunci primer:
--   id_kunjungan, AUTO_INCREMENT.
-- Unik:
--   uq_kunjungan_antrean pada (id_jadwal, no_antrean), satu nomor antrean
--   hanya dipakai sekali pada satu sesi jadwal.
--   uq_kunjungan_pasien pada (id_pasien, id_jadwal), satu pasien hanya
--   terdaftar sekali pada sesi yang sama.
-- Kunci tamu:
--   fk_kunjungan_pasien: id_pasien merujuk pasien(id_pasien),
--   ON DELETE RESTRICT ON UPDATE CASCADE.
--   fk_kunjungan_jadwal: id_jadwal merujuk jadwal_praktik(id_jadwal),
--   ON DELETE RESTRICT ON UPDATE CASCADE.
-- Catatan:
--   status_kunjungan memakai ENUM('Menunggu', 'Diperiksa', 'Selesai',
--   'Batal'), DEFAULT 'Menunggu'.

CREATE TABLE kunjungan (
    id_kunjungan      INT  NOT NULL AUTO_INCREMENT,
    id_pasien         INT  NOT NULL,
    id_jadwal         INT  NOT NULL,
    tanggal_kunjungan DATE NOT NULL,
    no_antrean        INT  NOT NULL,
    status_kunjungan  ENUM('Menunggu', 'Diperiksa', 'Selesai', 'Batal')
                      NOT NULL DEFAULT 'Menunggu',
    PRIMARY KEY (id_kunjungan),
    CONSTRAINT uq_kunjungan_antrean UNIQUE (id_jadwal, no_antrean),
    CONSTRAINT uq_kunjungan_pasien  UNIQUE (id_pasien, id_jadwal),
    CONSTRAINT fk_kunjungan_pasien FOREIGN KEY (id_pasien)
        REFERENCES pasien (id_pasien)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_kunjungan_jadwal FOREIGN KEY (id_jadwal)
        REFERENCES jadwal_praktik (id_jadwal)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- 8. Tabel rekam_medis
-- ---------------------------------------------------------------------
-- Kolom:
--   id_rekam, id_kunjungan, keluhan, diagnosis, tekanan_darah, suhu,
--   berat_badan, tinggi_badan, imt, tanggal_periksa
-- Kunci primer:
--   id_rekam, AUTO_INCREMENT.
-- Unik:
--   uq_rekam_kunjungan pada (id_kunjungan), menjaga relasi 1:0..1 dengan
--   kunjungan.
-- CHECK:
--   ck_rekam_suhu: suhu antara 30.0 dan 45.0.
--   ck_rekam_berat: berat_badan antara 1.0 dan 300.0.
--   ck_rekam_tinggi: tinggi_badan antara 30.0 dan 250.0.
-- Kolom turunan:
--   imt adalah generated column STORED, dihitung database dari
--   berat_badan dan tinggi_badan memakai rumus PRD bagian 5.2:
--   ROUND(berat_badan / ((tinggi_badan/100) * (tinggi_badan/100)), 1).
--   Kolom ini tidak diisi saat INSERT.
-- Kunci tamu:
--   fk_rekam_kunjungan: id_kunjungan merujuk kunjungan(id_kunjungan),
--   ON DELETE RESTRICT ON UPDATE CASCADE.

CREATE TABLE rekam_medis (
    id_rekam      INT           NOT NULL AUTO_INCREMENT,
    id_kunjungan  INT           NOT NULL,
    keluhan       VARCHAR(200)  NOT NULL,
    diagnosis     VARCHAR(200)  NOT NULL,
    tekanan_darah VARCHAR(15)   NULL,
    suhu          DECIMAL(4,1)  NULL,
    berat_badan   DECIMAL(5,1)  NULL,
    tinggi_badan  DECIMAL(4,1)  NULL,
    imt           DECIMAL(4,1)  GENERATED ALWAYS AS
                      (ROUND(berat_badan / ((tinggi_badan / 100) * (tinggi_badan / 100)), 1)) STORED,
    tanggal_periksa DATE        NOT NULL,
    PRIMARY KEY (id_rekam),
    CONSTRAINT uq_rekam_kunjungan UNIQUE (id_kunjungan),
    CONSTRAINT ck_rekam_suhu   CHECK (suhu BETWEEN 30.0 AND 45.0),
    CONSTRAINT ck_rekam_berat  CHECK (berat_badan BETWEEN 1.0 AND 300.0),
    CONSTRAINT ck_rekam_tinggi CHECK (tinggi_badan BETWEEN 30.0 AND 250.0),
    CONSTRAINT fk_rekam_kunjungan FOREIGN KEY (id_kunjungan)
        REFERENCES kunjungan (id_kunjungan)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- 9. Tabel tindakan
-- ---------------------------------------------------------------------
-- Kolom:
--   id_tindakan, nama_tindakan, tarif
-- Kunci primer:
--   id_tindakan, AUTO_INCREMENT.
-- Unik:
--   uq_tindakan_nama pada (nama_tindakan).
-- CHECK:
--   ck_tindakan_tarif: tarif >= 0.
-- Kunci tamu:
--   tidak ada, tindakan dirujuk oleh detail_tindakan.

CREATE TABLE tindakan (
    id_tindakan   INT           NOT NULL AUTO_INCREMENT,
    nama_tindakan VARCHAR(80)   NOT NULL,
    tarif         DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (id_tindakan),
    CONSTRAINT uq_tindakan_nama  UNIQUE (nama_tindakan),
    CONSTRAINT ck_tindakan_tarif CHECK (tarif >= 0)
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- 10. Tabel detail_tindakan
-- ---------------------------------------------------------------------
-- Kolom:
--   id_detail_tindakan, id_kunjungan, id_tindakan, jumlah
-- Kunci primer:
--   id_detail_tindakan, AUTO_INCREMENT.
-- Unik:
--   uq_detail_tindakan pada (id_kunjungan, id_tindakan), mencegah baris
--   ganda untuk tindakan yang sama pada satu kunjungan.
-- CHECK:
--   ck_detail_tindakan_jumlah: jumlah > 0.
-- Kunci tamu:
--   fk_detail_tindakan_kunjungan: id_kunjungan merujuk
--   kunjungan(id_kunjungan), ON DELETE RESTRICT ON UPDATE CASCADE.
--   fk_detail_tindakan_tindakan: id_tindakan merujuk
--   tindakan(id_tindakan), ON DELETE RESTRICT ON UPDATE CASCADE.
-- Catatan:
--   jumlah DEFAULT 1.

CREATE TABLE detail_tindakan (
    id_detail_tindakan INT NOT NULL AUTO_INCREMENT,
    id_kunjungan       INT NOT NULL,
    id_tindakan        INT NOT NULL,
    jumlah             INT NOT NULL DEFAULT 1,
    PRIMARY KEY (id_detail_tindakan),
    CONSTRAINT uq_detail_tindakan UNIQUE (id_kunjungan, id_tindakan),
    CONSTRAINT ck_detail_tindakan_jumlah CHECK (jumlah > 0),
    CONSTRAINT fk_detail_tindakan_kunjungan FOREIGN KEY (id_kunjungan)
        REFERENCES kunjungan (id_kunjungan)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_detail_tindakan_tindakan FOREIGN KEY (id_tindakan)
        REFERENCES tindakan (id_tindakan)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- 11. Tabel obat
-- ---------------------------------------------------------------------
-- Kolom:
--   id_obat, nama_obat, satuan, harga, stok
-- Kunci primer:
--   id_obat, AUTO_INCREMENT.
-- Unik:
--   uq_obat_nama pada (nama_obat).
-- CHECK:
--   ck_obat_harga: harga >= 0.
--   ck_obat_stok: stok >= 0.
-- Kunci tamu:
--   tidak ada, obat dirujuk oleh detail_resep.
-- Catatan:
--   stok DEFAULT 0, diubah oleh trigger trg_kurangi_stok pada fase
--   berikutnya.

CREATE TABLE obat (
    id_obat   INT           NOT NULL AUTO_INCREMENT,
    nama_obat VARCHAR(80)   NOT NULL,
    satuan    VARCHAR(20)   NOT NULL,
    harga     DECIMAL(10,2) NOT NULL,
    stok      INT           NOT NULL DEFAULT 0,
    PRIMARY KEY (id_obat),
    CONSTRAINT uq_obat_nama  UNIQUE (nama_obat),
    CONSTRAINT ck_obat_harga CHECK (harga >= 0),
    CONSTRAINT ck_obat_stok  CHECK (stok >= 0)
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- 12. Tabel detail_resep
-- ---------------------------------------------------------------------
-- Kolom:
--   id_detail_resep, id_rekam, id_obat, jumlah, aturan_pakai
-- Kunci primer:
--   id_detail_resep, AUTO_INCREMENT.
-- Unik:
--   uq_detail_resep pada (id_rekam, id_obat), mencegah obat yang sama
--   ditulis dua kali pada satu rekam medis.
-- CHECK:
--   ck_detail_resep_jumlah: jumlah > 0.
-- Kunci tamu:
--   fk_detail_resep_rekam: id_rekam merujuk rekam_medis(id_rekam),
--   ON DELETE RESTRICT ON UPDATE CASCADE.
--   fk_detail_resep_obat: id_obat merujuk obat(id_obat),
--   ON DELETE RESTRICT ON UPDATE CASCADE.

CREATE TABLE detail_resep (
    id_detail_resep INT          NOT NULL AUTO_INCREMENT,
    id_rekam        INT          NOT NULL,
    id_obat         INT          NOT NULL,
    jumlah          INT          NOT NULL,
    aturan_pakai    VARCHAR(100) NULL,
    PRIMARY KEY (id_detail_resep),
    CONSTRAINT uq_detail_resep UNIQUE (id_rekam, id_obat),
    CONSTRAINT ck_detail_resep_jumlah CHECK (jumlah > 0),
    CONSTRAINT fk_detail_resep_rekam FOREIGN KEY (id_rekam)
        REFERENCES rekam_medis (id_rekam)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_detail_resep_obat FOREIGN KEY (id_obat)
        REFERENCES obat (id_obat)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- 13. Tabel pembayaran
-- ---------------------------------------------------------------------
-- Kolom:
--   id_pembayaran, id_kunjungan, tanggal_bayar, metode, total_tagihan,
--   status_bayar
-- Kunci primer:
--   id_pembayaran, AUTO_INCREMENT.
-- Unik:
--   uq_pembayaran_kunjungan pada (id_kunjungan), satu kunjungan paling
--   banyak punya satu baris pembayaran.
-- CHECK:
--   ck_pembayaran_total: total_tagihan >= 0.
-- Kunci tamu:
--   fk_pembayaran_kunjungan: id_kunjungan merujuk
--   kunjungan(id_kunjungan), ON DELETE RESTRICT ON UPDATE CASCADE.
-- Catatan:
--   metode memakai ENUM('Tunai', 'Transfer', 'BPJS'); status_bayar
--   memakai ENUM('Lunas', 'Belum Lunas'), DEFAULT 'Belum Lunas'.

CREATE TABLE pembayaran (
    id_pembayaran INT            NOT NULL AUTO_INCREMENT,
    id_kunjungan  INT            NOT NULL,
    tanggal_bayar DATE           NULL,
    metode        ENUM('Tunai', 'Transfer', 'BPJS') NOT NULL,
    total_tagihan DECIMAL(12,2) NOT NULL,
    status_bayar  ENUM('Lunas', 'Belum Lunas') NOT NULL DEFAULT 'Belum Lunas',
    PRIMARY KEY (id_pembayaran),
    CONSTRAINT uq_pembayaran_kunjungan UNIQUE (id_kunjungan),
    CONSTRAINT ck_pembayaran_total CHECK (total_tagihan >= 0),
    CONSTRAINT fk_pembayaran_kunjungan FOREIGN KEY (id_kunjungan)
        REFERENCES kunjungan (id_kunjungan)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- 14. Rekap kunci tamu
-- ---------------------------------------------------------------------
-- Sepuluh kunci tamu, semuanya ON DELETE RESTRICT ON UPDATE CASCADE:
-- 1. dokter.id_poli ke poli(id_poli).
-- 2. jadwal_praktik.id_dokter ke dokter(id_dokter).
-- 3. kunjungan.id_pasien ke pasien(id_pasien).
-- 4. kunjungan.id_jadwal ke jadwal_praktik(id_jadwal).
-- 5. rekam_medis.id_kunjungan ke kunjungan(id_kunjungan).
-- 6. detail_tindakan.id_kunjungan ke kunjungan(id_kunjungan).
-- 7. detail_tindakan.id_tindakan ke tindakan(id_tindakan).
-- 8. detail_resep.id_rekam ke rekam_medis(id_rekam).
-- 9. detail_resep.id_obat ke obat(id_obat).
-- 10. pembayaran.id_kunjungan ke kunjungan(id_kunjungan).

-- ---------------------------------------------------------------------
-- Pemeriksaan
-- ---------------------------------------------------------------------
-- Jalankan dari akar repo kerja:
--
--   bash tools/reset-db.sh
--   Keluaran diharapkan: database klinik_pratama dibuat tanpa error dan
--   skrip melaporkan "tabel terdaftar: 11".
--
--   bash tools/verify.sh
--   Keluaran diharapkan: bagian A lulus 13 dari 13 (jumlah tabel, kolom,
--   kunci primer, constraint) dan bagian B lulus 1 dari 1 (tidak ada
--   kunci tamu yatim).
--
-- Kesalahan yang paling sering muncul:
-- 1. Tabel anak dibuat sebelum induk.
-- 2. Kunci tamu memakai tipe berbeda dari kolom yang dirujuk.
-- 3. Nama kolom pada klausa REFERENCES salah ketik.
-- 4. Nilai CHECK di luar rentang yang tertulis di PRD bagian 5.2.
-- =====================================================================
