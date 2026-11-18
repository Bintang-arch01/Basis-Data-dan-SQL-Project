# ============================================================
# SOAL 1: Koneksi ke MySQL + buat/gunakan database employees_db
#         + buat tabel employees (dan tabel pendukung)
# ============================================================
install.packages("RMySQL")
library(RMySQL)

conn <- dbConnect(MySQL(),
                  user = "root", # Masukkan username
                  password = "", # Masukkan password
                  host = "127.0.0.1",
                  port = 3306
) # Isi "localhost" jika MySQL ada di komputer

# Buat database jika belum ada
# IF NOT EXISTS mencegah error jika database sudah ada
dbExecute(conn, "CREATE DATABASE IF NOT EXISTS employees_db")

# Gunakan database
dbExecute(conn, "USE employees_db")

# Verifikasi
dbGetQuery(conn, "SHOW DATABASES")

# ------------------------------------------------------------
# Membuat tabel employees (Untuk Soal 2–6)
# id        : primary key (unik tiap karyawan)
# name      : nama karyawan
# position  : jabatan
# department: departemen
# salary    : gaji (IDR), DECIMAL agar presisi
# hire_date : tanggal masuk
# status    : status karyawan, default 'active'
# ------------------------------------------------------------
# Tabel karyawan
dbExecute(conn, "
CREATE TABLE IF NOT EXISTS employees (
  id          INT PRIMARY KEY,
  name        VARCHAR(100) NOT NULL,
  position    VARCHAR(50),
  department  VARCHAR(50),
  salary      DECIMAL(15,2),
  hire_date   DATE,
  status      VARCHAR(20) DEFAULT 'active'
)")

# ----------------
# Tabel pendukung 
# ----------------
# Tabel departments: data departemen & anggaran
dbExecute(conn, "
CREATE TABLE IF NOT EXISTS departments (
  dept_id   INT PRIMARY KEY,
  dept_name VARCHAR(50) NOT NULL,
  budget    DECIMAL(15,2)
)")

# Tabel absensi:absensi harian karyawan
# emp_id adalah foreign key ke employees.id
dbExecute(conn, "
CREATE TABLE IF NOT EXISTS attendance (
  att_id     INT AUTO_INCREMENT PRIMARY KEY,
  emp_id     INT,
  work_date  DATE,
  status     VARCHAR(20),
  hours      DECIMAL(4,1),
  FOREIGN KEY (emp_id) REFERENCES employees(id)
)")

# Tabel performa: skor kinerja per periode
dbExecute(conn, "
CREATE TABLE IF NOT EXISTS performance (
  perf_id    INT AUTO_INCREMENT PRIMARY KEY,
  emp_id     INT,
  period     VARCHAR(10),
  score      DECIMAL(4,2),
  FOREIGN KEY (emp_id) REFERENCES employees(id)
)")

# ---------
# Isi Data
# ---------
# Data awal karyawan (7 orang)
dbExecute(conn, "
INSERT IGNORE INTO employees (id,name,position,department,salary,hire_date,status) VALUES
(1,'Andi','Manager','Sales',15000,'2018-01-15','active'),
(2,'Budi','Sales Exec','Sales',8000,'2020-03-10','active'),
(3,'Citra','Engineer','IT',12000,'2019-07-01','active'),
(4,'Dewi','Analyst','Data Science',9000,'2021-02-20','active'),
(5,'Eka','HR Staff','HR',7000,'2022-05-05','active'),
(6,'Fajar','Sales Exec','Sales',7500,'2021-11-11','active'),
(7,'Gita','Engineer','IT',11000,'2020-09-09','active')")

# Data awal departemen
dbExecute(conn, "
INSERT IGNORE INTO departments VALUES
(1,'Sales',50000),(2,'IT',80000),(3,'Data Science',60000),(4,'HR',30000)")

# Data awal absensi (2 hari kerja per karyawan)
dbExecute(conn, "
INSERT IGNORE INTO attendance (emp_id,work_date,status,hours) VALUES
(1,'2025-01-02','Hadir',8),(1,'2025-01-03','Hadir',8),
(2,'2025-01-02','Hadir',8),(2,'2025-01-03','Izin',0),
(3,'2025-01-02','Hadir',8),(3,'2025-01-03','Hadir',9),
(4,'2025-01-02','Hadir',8),(4,'2025-01-03','Hadir',8),
(5,'2025-01-02','Sakit',0),(5,'2025-01-03','Hadir',8),
(6,'2025-01-02','Hadir',8),(6,'2025-01-03','Hadir',8),
(7,'2025-01-02','Hadir',8),(7,'2025-01-03','Hadir',8)")

# Data awal skor kinerja periode 2025-Q1
dbExecute(conn, "
INSERT IGNORE INTO performance (emp_id,period,score) VALUES
(1,'2025-Q1',88),(2,'2025-Q1',76),(3,'2025-Q1',92),
(4,'2025-Q1',85),(5,'2025-Q1',70),(6,'2025-Q1',79),(7,'2025-Q1',90)")

# ============================================================
# SOAL 2: Mengambil semua data dari tabel employees
# ============================================================

# dbGetQuery menjalankan SELECT dan mengembalikan hasil
# sebagai data frame R (df_employees)
df_employees <- dbGetQuery(conn, "SELECT * FROM employees")
print(df_employees)

# ============================================================
# SOAL 3: Mengambil karyawan yang bekerja di departemen Sales
# ============================================================
# WHERE department = 'Sales' memfilter baris sesuai departemen
df_sales <- dbGetQuery(conn,
                       "SELECT * FROM employees WHERE department = 'Sales'")
print(df_sales)

# ============================================================
# SOAL 4: Menambahkan data karyawan baru (id=101)
# ============================================================

# dbExecute dipakai untuk query yang tidak mengembalikan data (INSERT)
# salary bertipe numerik, jadi 7000 ditulis tanpa tanda kutip
dbExecute(conn,
          "INSERT IGNORE INTO employees (id, name, position, department, salary, status)
   VALUES (101, 'Son Heung Min', 'Data Analyst', 'Data Science', 7000, 'active')")

# ============================================================
# SOAL 5: Memperbarui gaji karyawan id=101 menjadi 8000
# ============================================================
# UPDATE ... SET salary = 8000 hanya mengubah baris dengan id = 101
dbExecute(conn,
          "UPDATE employees SET salary = 8000 WHERE id = 101")

# ============================================================
# SOAL 6: Menghapus data karyawan id=101 (resign)
# ============================================================

# DELETE FROM ... WHERE id = 101 menghapus satu baris dengan id = 101
dbExecute(conn, "DELETE FROM employees WHERE id = 101")

# Verifikasi: tampilkan seluruh data terurut berdasarkan id
dbGetQuery(conn, "SELECT * FROM employees ORDER BY id")

# Memuat dplyr untuk manipulasi data (group_by, summarise, dll.)
library(dplyr)
# Memuat tidyr untuk reshaping data
library(tidyr)

# Mengambil data dari ketiga tabel ke data frame R
emp <- dbGetQuery(conn, "SELECT * FROM employees")
att <- dbGetQuery(conn, "SELECT * FROM attendance")
perf<- dbGetQuery(conn, "SELECT * FROM performance")

# --- Statistik deskriptif gaji per departemen ---
# group_by(department) : kelompokkan data per departemen
# summarise(...)       : hitung statistik tiap kelompok
# arrange(desc(...))   : urutkan rata-rata gaji menurun
stat_gaji <- emp %>%
  group_by(department) %>%
  summarise(
    n          = n(),
    mean_gaji  = mean(salary),
    median_gaji= median(salary),
    sd_gaji    = sd(salary),
    min_gaji   = min(salary),
    max_gaji   = max(salary),
    total_gaji = sum(salary)
  ) %>% arrange(desc(mean_gaji))
print(stat_gaji)

# --- Rasio kehadiran per karyawan ---
# mean(status == "Hadir") menghasilkan proporsi (0-1) → x100 jadi persen
att_summary <- att %>%
  group_by(emp_id) %>%
  summarise(
    total_hari = n(),
    hadir      = sum(status == "Hadir"),
    rasio_hadir= round(mean(status == "Hadir")*100, 1),
    total_jam  = sum(hours)
  )
print(att_summary)

# --- Gabungan kinerja + gaji (efisiensi) ---
# left_join menggabungkan perf dengan emp (emp_id = id)
# gaji_per_poin = gaji / skor (semakin kecil semakin efisien)
perf_emp <- perf %>%
  left_join(emp, by = c("emp_id" = "id")) %>%
  mutate(gaji_per_poin = salary / score)
print(perf_emp %>% select(name, department, score, salary, gaji_per_poin))

# Memuat ggplot2 untuk membuat grafik
library(ggplot2)

# 1) Rata-rata gaji per departemen
# reorder(department, mean_gaji) mengurutkan batang berdasarkan nilai
# coord_flip() membuat batang horizontal agar label mudah dibaca
p1 <- ggplot(stat_gaji, aes(x = reorder(department, mean_gaji), y = mean_gaji, fill = department)) +
  geom_col() + coord_flip() +
  labs(title = "Rata-rata Gaji per Departemen", x = "Departemen", y = "Gaji (IDR)") +
  theme_minimal()
print(p1)

# 2) Distribusi skor kinerja
# binwidth = 5 mengatur lebar interval histogram
p2 <- ggplot(perf_emp, aes(x = score, fill = department)) +
  geom_histogram(binwidth = 5, color = "white") +
  labs(title = "Distribusi Skor Kinerja", x = "Skor", y = "Frekuensi") +
  theme_minimal()
print(p2)

# 3) Rasio kehadiran per karyawan
# join att_summary dengan emp untuk dapat nama & departemen
p3 <- att_summary %>%
  left_join(emp, by = c("emp_id" = "id")) %>%
  ggplot(aes(x = reorder(name, rasio_hadir), y = rasio_hadir, fill = department)) +
  geom_col() + coord_flip() +
  labs(title = "Rasio Kehadiran per Karyawan (%)", x = "Karyawan", y = "%") +
  theme_minimal()
print(p3)

# 4) Scatter plot gaji vs skor kinerja + garis regresi
# geom_smooth(method="lm") menambahkan garis tren linear
p4 <- ggplot(perf_emp, aes(x = score, y = salary, color = department)) +
  geom_point(size = 3) + geom_smooth(method = "lm", se = FALSE, linetype = "dashed") +
  labs(title = "Hubungan Skor Kinerja vs Gaji", x = "Skor", y = "Gaji") +
  theme_minimal()
print(p4)

# Simpan otomatis
ggsave("plot_gaji.png", p1, width = 7, height = 5)
ggsave("plot_kinerja.png", p2, width = 7, height = 5)
ggsave("plot_kehadiran.png", p3, width = 7, height = 5)
ggsave("plot_scatter.png", p4, width = 7, height = 5)

# --- Model 1: Regresi Linear — prediksi gaji dari skor kinerja ---
# lm(salary ~ score + department) memodelkan gaji
# sebagai fungsi skor & departemen
model_gaji <- lm(salary ~ score + department, data = perf_emp)
summary(model_gaji)

# Prediksi gaji karyawan baru (skor=85, department=IT)
new_emp <- data.frame(score = 85, department = "IT")
predict(model_gaji, new_emp)

# --- Model 2: Klasifikasi — prediksi status kehadiran ---
# Buat variabel target biner: "Ya" (Hadir) / "Tidak"
att_model <- att %>%
  mutate(hadir = factor(ifelse(status == "Hadir", "Ya", "Tidak")))

# Memuat randomForest untuk klasifikasi
library(randomForest)
set.seed(42)
# ntree = 100 pohon keputusan
rf <- randomForest(hadir ~ hours + emp_id, data = att_model, ntree = 100)
print(rf)
# OOB accuracy = 1 - error out-of-bag
cat("OOB Accuracy:", 1 - rf$err.rate[rf$ntree, "OOB"], "\n")

# --- Model 3: Clustering karyawan (K-Means, k=3) ---
set.seed(42)
# scale() menstandarkan salary & score agar skala sebanding
cluster_data <- perf_emp %>% select(salary, score) %>% scale()
# nstart = 25 mencoba 25 inisialisasi awal, ambil terbaik
km <- kmeans(cluster_data, centers = 3, nstart = 25)
perf_emp$cluster <- km$cluster
print(perf_emp %>% select(name, salary, score, cluster))

# Visualisasi cluster: sumbu X = skor, Y = gaji, warna = cluster
ggplot(perf_emp, aes(x = score, y = salary, color = factor(cluster), label = name)) +
  geom_point(size = 3) + geom_text(vjust = -0.8, size = 3) +
  labs(title = "Segmentasi Karyawan (K-Means, k=3)",
       x = "Skor Kinerja", y = "Gaji", color = "Cluster") +
  theme_minimal()

# Fungsi untuk mencetak laporan ringkasan perusahaan ke konsol
buat_laporan <- function() {
  cat("=========================================\n")
  cat("   LAPORAN OTOMATIS PERUSAHAAN\n")
  cat("   Tanggal:", format(Sys.Date()), "\n")
  cat("=========================================\n")
# Jumlah karyawan aktif
  cat("Total karyawan aktif :", sum(emp$status == "active"), "\n")
# Total payroll (format ribuan dengan koma)
  cat("Total payroll        :", format(sum(emp$salary), big.mark = ","), "IDR\n")
# Rata-rata gaji
  cat("Rata-rata gaji       :", round(mean(emp$salary)), "IDR\n")
# Departemen dengan karyawan terbanyak
  cat("Departemen terbesar  :", names(sort(table(emp$department), decreasing = TRUE))[1], "\n")
# Rata-rata skor kinerja  
  cat("Rata-rata kinerja    :", round(mean(perf$score), 2), "\n")
# Rata-rata rasio kehadiran
    cat("Rasio kehadiran rata2:", round(mean(att_summary$rasio_hadir), 1), "%\n")
  cat("-----------------------------------------\n")
# Top 3 kinerja tertinggi  
  cat("Top 3 kinerja tertinggi:\n")
  print(head(perf_emp[order(-perf_emp$score), c("name","department","score")], 3))
  cat("=========================================\n")
}
buat_laporan()

# Fungsi menu interaktif: memanggil modul-modul di atas
sistem_perusahaan <- function() {
  repeat {
    pilihan <- menu(c(
      "Lihat semua karyawan (Soal 2)",
      "Filter departemen Sales (Soal 3)",
      "Tambah karyawan baru (Soal 4)",
      "Update gaji karyawan (Soal 5)",
      "Hapus karyawan (Soal 6)",
      "Statistik gaji per departemen",
      "Rasio kehadiran",
      "Grafik gaji per departemen",
      "Prediksi gaji (skor=85, IT)",
      "Laporan ringkasan",
      "Keluar"
    ), title = "=== SISTEM PERUSAHAAN ===")
    
    if (pilihan == 0 || pilihan == 11) { cat("Keluar...\n"); break }
    
    if (pilihan == 1) print(dbGetQuery(conn, "SELECT * FROM employees"))
    if (pilihan == 2) print(dbGetQuery(conn, "SELECT * FROM employees WHERE department='Sales'"))
    if (pilihan == 3) {
      dbExecute(conn,
                "INSERT INTO employees (id,name,position,department,salary,status)
         VALUES (101,'Son Heung Min','Data Analyst','Data Science',7000,'active')")
      cat("Data ditambahkan.\n")
    }
    if (pilihan == 4) {
      dbExecute(conn, "UPDATE employees SET salary=8000 WHERE id=101")
      cat("Gaji id 101 diupdate.\n")
    }
    if (pilihan == 5) {
      dbExecute(conn, "DELETE FROM employees WHERE id=101")
      cat("Karyawan id 101 dihapus.\n")
    }
    if (pilihan == 6) print(stat_gaji)
    if (pilihan == 7) print(att_summary)
    if (pilihan == 8) print(p1)
    if (pilihan == 9) print(predict(model_gaji, data.frame(score=85, department="IT")))
    if (pilihan == 10) buat_laporan()
  }
}
# sistem_perusahaan()   # jalankan di konsol interaktif

# ============================================================
# SOAL 7: Menutup koneksi ke database
# ============================================================

# dbDisconnect menutup koneksi agar tidak menghabiskan sumber daya
dbDisconnect(conn)