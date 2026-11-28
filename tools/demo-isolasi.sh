#!/usr/bin/env bash
# =====================================================================
# tools/demo-isolasi.sh
# Membuktikan perilaku tingkat isolasi transaksi dan deteksi deadlock.
#
#   Bagian 1: READ COMMITTED    -> sesi A melihat nilai baru setelah B commit
#   Bagian 2: REPEATABLE READ   -> sesi A tetap melihat nilai lama
#   Bagian 3: deadlock          -> salah satu sesi dihentikan dengan galat 1213
#
# Pakai: bash tools/demo-isolasi.sh
# Syarat: database sudah di-reset lewat tools/reset-db.sh, dan container
#         kbd-mysql atau MySQL host (XAMPP/Laragon) menyala.
# =====================================================================
set -uo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DIR/tools/db.sh"
OPSI=(-D klinik_pratama -N -B)

SESSION_A=$(mktemp)
SESSION_B=$(mktemp)
KELUARAN_A=$(mktemp)
KELUARAN_B=$(mktemp)
trap 'rm -f "$SESSION_A" "$SESSION_B" "$KELUARAN_A" "$KELUARAN_B"' EXIT

sesi() {
  db "${OPSI[@]}" 2>&1 | grep -v "Using a password"
}

ambil_stok() {
  local id="${1:-1}"
  db -D klinik_pratama -N -B -e "SELECT stok FROM obat WHERE id_obat=$id;" 2>/dev/null
}

# Stok awal dicatat supaya demo mengembalikannya ke nilai semula,
# berapa pun isi data contoh (dulu hardcode 200 dan 150).
STOK1_AWAL=$(ambil_stok 1)
STOK2_AWAL=$(ambil_stok 2)

lapor() {
  printf '\n%s\n' "-------------------------------------------------------------"
  printf '%s\n' "$1"
  printf '%s\n' "-------------------------------------------------------------"
}

# ---------------------------------------------------------------------
# Bagian 1: READ COMMITTED
# ---------------------------------------------------------------------
lapor "BAGIAN 1. Tingkat isolasi READ COMMITTED"
echo "Stok awal obat 1: $(ambil_stok)"

cat > "$SESSION_A" <<'SQL'
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
START TRANSACTION;
SELECT CONCAT('A membaca pertama kali  : ', stok) AS jejak FROM obat WHERE id_obat = 1;
SELECT SLEEP(4) AS tunggu;
SELECT CONCAT('A membaca setelah B commit: ', stok) AS jejak FROM obat WHERE id_obat = 1;
COMMIT;
SQL

cat > "$SESSION_B" <<'SQL'
SELECT SLEEP(1) AS tunggu;
START TRANSACTION;
UPDATE obat SET stok = stok - 5 WHERE id_obat = 1;
SELECT CONCAT('B mengubah stok menjadi  : ', stok) AS jejak FROM obat WHERE id_obat = 1;
SELECT SLEEP(2) AS tunggu;
COMMIT;
SELECT 'B commit selesai' AS jejak;
SQL

sesi < "$SESSION_A" > "$KELUARAN_A" &
PID_A=$!
sesi < "$SESSION_B" > "$KELUARAN_B"
wait "$PID_A"

echo "--- jejak sesi A ---"
grep -E "A membaca|tunggu" "$KELUARAN_A" | grep -v "^0$"
echo "--- jejak sesi B ---"
grep -E "B mengubah|B commit" "$KELUARAN_B"

# ---------------------------------------------------------------------
# Bagian 2: REPEATABLE READ
# ---------------------------------------------------------------------
lapor "BAGIAN 2. Tingkat isolasi REPEATABLE READ"
echo "Stok obat 1 sebelum percobaan: $(ambil_stok)"

cat > "$SESSION_A" <<'SQL'
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
START TRANSACTION;
SELECT CONCAT('A membaca pertama kali  : ', stok) AS jejak FROM obat WHERE id_obat = 1;
SELECT SLEEP(4) AS tunggu;
SELECT CONCAT('A membaca setelah B commit: ', stok) AS jejak FROM obat WHERE id_obat = 1;
COMMIT;
SQL

cat > "$SESSION_B" <<'SQL'
SELECT SLEEP(1) AS tunggu;
START TRANSACTION;
UPDATE obat SET stok = stok - 5 WHERE id_obat = 1;
SELECT CONCAT('B mengubah stok menjadi  : ', stok) AS jejak FROM obat WHERE id_obat = 1;
SELECT SLEEP(2) AS tunggu;
COMMIT;
SELECT 'B commit selesai' AS jejak;
SQL

sesi < "$SESSION_A" > "$KELUARAN_A" &
PID_A=$!
sesi < "$SESSION_B" > "$KELUARAN_B"
wait "$PID_A"

echo "--- jejak sesi A ---"
grep -E "A membaca" "$KELUARAN_A"
echo "--- jejak sesi B ---"
grep -E "B mengubah|B commit" "$KELUARAN_B"

# ---------------------------------------------------------------------
# Bagian 3: deadlock
# Dua sesi mengunci dua baris yang sama dengan urutan berlawanan.
# ---------------------------------------------------------------------
lapor "BAGIAN 3. Deadlock dua transaksi"

cat > "$SESSION_A" <<'SQL'
START TRANSACTION;
UPDATE obat SET stok = stok - 1 WHERE id_obat = 1;
SELECT 'A mengunci obat 1' AS jejak;
SELECT SLEEP(2) AS tunggu;
UPDATE obat SET stok = stok - 1 WHERE id_obat = 2;
SELECT 'A mengunci obat 2' AS jejak;
COMMIT;
SQL

cat > "$SESSION_B" <<'SQL'
SELECT SLEEP(1) AS tunggu;
START TRANSACTION;
UPDATE obat SET stok = stok - 1 WHERE id_obat = 2;
SELECT 'B mengunci obat 2' AS jejak;
SELECT SLEEP(2) AS tunggu;
UPDATE obat SET stok = stok - 1 WHERE id_obat = 1;
SELECT 'B mengunci obat 1' AS jejak;
COMMIT;
SQL

sesi < "$SESSION_A" > "$KELUARAN_A" 2>&1 &
PID_A=$!
sesi < "$SESSION_B" > "$KELUARAN_B" 2>&1
wait "$PID_A"

echo "--- jejak sesi A ---"
grep -vE "^0$|Using a password" "$KELUARAN_A"
echo "--- jejak sesi B ---"
grep -vE "^0$|Using a password" "$KELUARAN_B"

if grep -q "ERROR 1213" "$KELUARAN_A" "$KELUARAN_B"; then
  echo "KESIMPULAN: deadlock terdeteksi, satu transaksi dihentikan dengan galat 1213."
else
  echo "CATATAN: tidak ada galat 1213 pada percobaan ini."
fi

# Kembalikan stok ke angka semula supaya percobaan bisa diulang.
db -D klinik_pratama \
  -e "UPDATE obat SET stok = $STOK1_AWAL WHERE id_obat = 1; UPDATE obat SET stok = $STOK2_AWAL WHERE id_obat = 2;" 2>/dev/null
echo "Stok obat 1 dan 2 dikembalikan ke nilai semula ($STOK1_AWAL dan $STOK2_AWAL)."
