# 🚀 Lumora App (Flutter + Supabase)

Lumora adalah aplikasi Flutter berbasis AI learning tools yang memungkinkan pengguna untuk:

* Login & register dengan verifikasi email
* Upload dan membaca dokumen PDF
* Menggunakan AI tools seperti Summarizer, Flashcard Generator, Quiz Generator & Explain Mode

Backend authentication dan database menggunakan **Supabase**.

---

## ✨ Fitur Utama

* 🔐 Authentication (Register, Login, Email Verification)
* 👤 Profile user (username disimpan di tabel `profiles`)
* 📄 Upload & ekstraksi teks PDF
* 🤖 AI Tools:

  * Summarizer
  * Flashcard Generator
  * Quiz Generator
  * (Coming soon: Explain Mode)
* 🎨 UI modern (gradient + glassmorphism)

---

## 🧱 Tech Stack

* **Flutter** (Frontend)
* **Supabase** (Auth & Database)
* **Syncfusion PDF** (PDF reader)
* **File Picker**

---

## 📂 Struktur Database (Supabase)

### Table: `profiles`

| Kolom    | Tipe | Keterangan          |
| -------- | ---- | ------------------- |
| id       | uuid | FK ke auth.users.id |
| username | text | Nama user           |
| email    | text | Email user          |
| userId   | int4 | Id User             |
| created_at | timestamp | Tgl User daftar |

> 🔒 RLS aktif dengan policy: user hanya bisa akses datanya sendiri

---

## ⚙️ Setup Project

### 1️⃣ Clone Repository

```bash
git clone https://github.com/Gansputra/lumora-app.git
cd lumora-app
```

---

### 2️⃣ Install Dependencies

```bash
flutter pub get
```

---

### 3️⃣ Setup Environment Variables (.env)

Salin file environment contoh:

```bash
cp .env.example .env
```

Lalu isi file `.env` dengan konfigurasi milikmu:

```env
GEMINI_API_KEY="Api Gemini Anda!"
SUPABASE_ANON="Supabase Anon Anda"
SUPABASE_URL="Url Supabase Anda"
```

### 4️⃣ Jalankan Aplikasi

```bash
flutter run
```

Pastikan emulator atau device sudah aktif.

---

## 🧪 Alur Penggunaan Aplikasi

### 📝 Register

1. Masuk ke halaman **Daftar**
2. Isi username, email, dan password
3. Cek email → klik link verifikasi

---

### 🔐 Login

1. Masukkan email & password
2. Sistem cek:

   * Email terverifikasi
   * Data profile di tabel `profiles`
3. Berhasil → masuk ke Home Page

---

### 🏠 Home Page

* Username ditampilkan dari database
* Upload PDF
* Pilih AI tools

---

## 🛠 Troubleshooting

**❌ Login gagal / error 500**

* Pastikan RLS policy di `profiles` benar
* Pastikan email sudah diverifikasi

**❌ Username tidak tampil**

* Cek kolom `username` di tabel `profiles`
* Pastikan `id` sama dengan `auth.users.id`

## 🧠 Catatan Developer

Project ini dibuat untuk eksplorasi:

* Flutter UI modern
* Supabase Auth & RLS
* Integrasi AI tools

Feel free untuk fork & develop 🔥

---

## 📄 License

MIT License

---

💡 *Built with Flutter & Supabase — Lumora App*
