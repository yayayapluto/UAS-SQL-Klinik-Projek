-- =====================================================================
-- bukti/kueri-panduan.sql
-- Pemilik : Kafka (Q1 sampai Q10)
-- Sumber  : PRD bagian 7. Teks query ini ditulis dari spesifikasi PRD;
--           repo panduan tidak memuat teks SQL Q1-Q10, hanya tujuan,
--           teknik, dan acuan hasil tiap query.
-- Jalankan sebagai root setelah bash tools/reset-db.sh:
--   mysql -uroot -pkbd klinik_pratama < bukti/kueri-panduan.sql > bukti/10-kueri.txt
-- =====================================================================

USE klinik_pratama;

-- Q1. Pasien lahir sebelum 2005, diurutkan dari yang paling tua.
--     Acuan: 10 baris, tertua Gilang Ramadhan 1980-02-18.
SELECT id_pasien, nama_pasien, tanggal_lahir
FROM pasien
WHERE tanggal_lahir < '2005-01-01'
ORDER BY tanggal_lahir ASC;

-- Q2. Dokter, poli tempat bertugas, dan lantai poli tersebut.
--     Acuan: 6 dokter.
SELECT d.id_dokter, d.nama_dokter, p.nama_poli, p.lantai
FROM dokter d
JOIN poli p ON p.id_poli = d.id_poli
ORDER BY d.id_dokter;

-- Q3. Riwayat kunjungan lengkap: pasien, dokter, poli, status.
--     Acuan: 14 baris.
SELECT k.id_kunjungan, ps.nama_pasien, d.nama_dokter, p.nama_poli, k.status_kunjungan
FROM kunjungan k
JOIN pasien ps ON ps.id_pasien = k.id_pasien
JOIN jadwal_praktik j ON j.id_jadwal = k.id_jadwal
JOIN dokter d ON d.id_dokter = j.id_dokter
JOIN poli p ON p.id_poli = d.id_poli
ORDER BY k.id_kunjungan;

-- Q4. Sisa kuota setiap jadwal praktik saat ini.
--     Kunjungan Batal tidak dihitung sebagai pemakaian kuota (sama
--     seperti trg_cek_kuota_jadwal). Acuan: jadwal 7 sisa 0.
SELECT j.id_jadwal, j.tanggal, j.kuota,
    j.kuota - COUNT(k.id_kunjungan) AS sisa_kuota
FROM jadwal_praktik j
LEFT JOIN kunjungan k ON k.id_jadwal = j.id_jadwal
    AND k.status_kunjungan <> 'Batal'
GROUP BY j.id_jadwal, j.tanggal, j.kuota
ORDER BY j.id_jadwal;

-- Q5. Kunjungan yang tagihannya belum lunas.
--     Acuan: 3 baris.
SELECT b.id_pembayaran, ps.nama_pasien, k.id_kunjungan, b.total_tagihan, b.status_bayar
FROM pembayaran b
JOIN kunjungan k ON k.id_kunjungan = b.id_kunjungan
JOIN pasien ps ON ps.id_pasien = k.id_pasien
WHERE b.status_bayar = 'Belum Lunas'
ORDER BY b.id_pembayaran;

-- Q6. Pasien yang pernah dirujuk ke Poli Anak, dan pasien tertua.
--     Acuan: 2 pasien ke Poli Anak; pasien tertua Gilang Ramadhan.
SELECT id_pasien, nama_pasien
FROM pasien
WHERE id_pasien IN (
    SELECT k.id_pasien
    FROM kunjungan k
    JOIN jadwal_praktik j ON j.id_jadwal = k.id_jadwal
    JOIN dokter d ON d.id_dokter = j.id_dokter
    JOIN poli p ON p.id_poli = d.id_poli
    WHERE p.nama_poli = 'Poli Anak'
)
ORDER BY id_pasien;

SELECT id_pasien, nama_pasien, tanggal_lahir
FROM pasien
WHERE tanggal_lahir = (SELECT MIN(tanggal_lahir) FROM pasien);

-- Q7. Poli dengan pendapatan di atas rata-rata.
--     Pendapatan = total tagihan Lunas per poli (sejalan dengan
--     v_pendapatan_poli). Rata-rata = rata-rata pendapatan per poli
--     = 200000. Acuan: Poli Umum 274000, Poli Gigi 213000,
--     Poli Penyakit Dalam 202000.
SELECT p.nama_poli, SUM(b.total_tagihan) AS pendapatan
FROM pembayaran b
JOIN kunjungan k ON k.id_kunjungan = b.id_kunjungan
JOIN jadwal_praktik j ON j.id_jadwal = k.id_jadwal
JOIN dokter d ON d.id_dokter = j.id_dokter
JOIN poli p ON p.id_poli = d.id_poli
WHERE b.status_bayar = 'Lunas'
GROUP BY p.nama_poli
HAVING SUM(b.total_tagihan) > (
    SELECT AVG(pendapatan_poli) FROM (
        SELECT SUM(b2.total_tagihan) AS pendapatan_poli
        FROM pembayaran b2
        JOIN kunjungan k2 ON k2.id_kunjungan = b2.id_kunjungan
        JOIN jadwal_praktik j2 ON j2.id_jadwal = k2.id_jadwal
        JOIN dokter d2 ON d2.id_dokter = j2.id_dokter
        JOIN poli p2 ON p2.id_poli = d2.id_poli
        WHERE b2.status_bayar = 'Lunas'
        GROUP BY p2.nama_poli
    ) AS per_poli
)
ORDER BY pendapatan DESC;

-- Q8. Obat paling banyak keluar.
--     Acuan: Amlodipine 5mg, 60 tablet dari 2 resep.
SELECT o.nama_obat, SUM(dr.jumlah) AS total_keluar,
    COUNT(dr.id_detail_resep) AS jumlah_resep
FROM detail_resep dr
JOIN obat o ON o.id_obat = dr.id_obat
GROUP BY o.id_obat, o.nama_obat
ORDER BY total_keluar DESC
LIMIT 1;

-- Q9. Kategori biaya kunjungan.
--     Ambang kategori TIDAK ditetapkan di panduan mana pun; ambang di
--     bawah ini diturunkan dari data biaya per kunjungan agar
--     menghasilkan sebaran acuan: 5 Ringan, 3 Sedang, 2 Berat.
--     Ringan: total < 100000. Sedang: 100000 sampai 199999.
--     Berat: total >= 200000.
SELECT k.id_kunjungan, b.total_tagihan,
    CASE
        WHEN b.total_tagihan < 100000 THEN 'Ringan'
        WHEN b.total_tagihan < 200000 THEN 'Sedang'
        ELSE 'Berat'
    END AS kategori_biaya
FROM pembayaran b
JOIN kunjungan k ON k.id_kunjungan = b.id_kunjungan
ORDER BY b.total_tagihan ASC;

-- Q10. Peringkat dokter berdasarkan jumlah kunjungan yang ditangani.
--      Acuan: dr. Andi Pratama peringkat 1 (6 kunjungan).
SELECT d.nama_dokter, COUNT(k.id_kunjungan) AS jumlah_kunjungan,
    RANK() OVER (ORDER BY COUNT(k.id_kunjungan) DESC) AS peringkat
FROM dokter d
LEFT JOIN jadwal_praktik j ON j.id_dokter = d.id_dokter
LEFT JOIN kunjungan k ON k.id_jadwal = j.id_jadwal
GROUP BY d.id_dokter, d.nama_dokter
ORDER BY peringkat ASC, d.nama_dokter ASC;
