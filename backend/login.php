<?php
// login.php

// 1. Mengatur header HTTP untuk respons JSON dan CORS
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *'); // Izinkan semua origin (untuk development). Di produksi, ganti dengan domain Flutter Anda.
header('Access-Control-Allow-Methods: POST, GET, OPTIONS'); // Izinkan metode POST
header('Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With');

// Jika ini adalah preflight request OPTIONS, langsung kirim respons OK
if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Sertakan file koneksi database
// Pastikan file ini mendefinisikan variabel $conn untuk koneksi MySQLi
include 'db_connect.php';

$response = array(); // Inisialisasi array respons

// Pastikan request adalah POST
if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    // 2. Ambil semua data yang diperlukan dari POST
    $username = $_POST['username'] ?? ''; // Gunakan ?? '' untuk menghindari error jika tidak ada
    $password = $_POST['password'] ?? '';
    $account_type = $_POST['account_type'] ?? ''; // Ambil account_type

    // --- BARIS DEBUGGING DIMULAI DI SINI ---
    error_log("DEBUG FLUTTER: Username received: '" . $username . "'");
    error_log("DEBUG FLUTTER: Account Type received: '" . $account_type . "'");
    // error_log("DEBUG FLUTTER: Password received: '" . $password . "'"); // Hati-hati logging password di produksi!
    // --- BARIS DEBUGGING BERAKHIR DI SINI ---

    // Validasi input dasar
    if (empty($username) || empty($password) || empty($account_type)) {
        http_response_code(400); // Bad Request
        $response['status'] = 'error';
        $response['message'] = 'Username, password, and account type are required.';
        echo json_encode($response);
        exit(); // Hentikan eksekusi setelah mengirim respons
    }

    // 3. Modifikasi query SQL untuk menyertakan account_type
    $sql = "SELECT id, username, password, account_type, photo_url FROM users WHERE username = ? AND account_type = ?";
    $stmt = $conn->prepare($sql);

    if ($stmt === false) {
        http_response_code(500); // Internal Server Error
        $response['status'] = 'error';
        $response['message'] = 'Failed to prepare statement: ' . $conn->error;
        echo json_encode($response);
        exit();
    }

    $stmt->bind_param("ss", $username, $account_type); // "ss" karena ada dua parameter string
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result->num_rows > 0) {
        $user = $result->fetch_assoc();

        // --- BARIS DEBUGGING DIMULAI DI SINI ---
        error_log("DEBUG DB: User found. DB username: '" . $user['username'] . "', DB account_type: '" . $user['account_type'] . "'");
        // error_log("DEBUG DB: DB hash: '" . $user['password'] . "'"); // Hati-hati logging hash di produksi!
        // --- BARIS DEBUGGING BERAKHIR DI SINI ---

        // Verifikasi password dengan hash yang tersimpan
        if (password_verify($password, $user['password'])) {
            // --- BARIS DEBUGGING DIMULAI DI SINI ---
            error_log("DEBUG VERIFY: Password verification SUCCESSFUL.");
            // --- BARIS DEBUGGING BERAKHIR DI SINI ---

            // Login berhasil
            http_response_code(200); // OK
            $photo_full_url = "http://192.168.1.10/runnotrack_api/images/" . $user['photo_url']; // IP komputermu

            $response = [
                "status" => "success",
                "message" => "Login successful!",
                "user_data" => [ // Bungkus data user dalam array 'user_data'
                    "username" => $user['username'],
                    "account_type" => $user['account_type'],
                    "photo_url" => $photo_full_url // Kirim URL lengkap
                ]
            ];
            echo json_encode($response);
            exit();
        } else {
            // --- BARIS DEBUGGING DIMULAI DI SINI ---
            error_log("DEBUG VERIFY: Password verification FAILED for user '" . $user['username'] . "'.");
            // --- BARIS DEBUGGING BERAKHIR DI SINI ---

            // Password salah - gunakan pesan umum untuk keamanan
            http_response_code(401); // Unauthorized
            $response['status'] = 'error';
            $response['message'] = 'ID atau kata sandi salah.'; // Pesan umum
            echo json_encode($response);
            exit();
        }
    } else {
        // --- BARIS DEBUGGING DIMULAI DI SINI ---
        error_log("DEBUG DB: User NOT found in DB for username '" . $username . "' and account_type '" . $account_type . "'.");
        // --- BARIS DEBUGGING BERAKHIR DI SINI ---

        // User tidak ditemukan atau account_type tidak cocok - gunakan pesan umum untuk keamanan
        http_response_code(401); // Unauthorized
        $response['status'] = 'error';
        $response['message'] = 'ID atau kata sandi salah.'; // Pesan umum
        echo json_encode($response);
        exit();
    }

    // 5. Tutup statement dan koneksi database
    // Baris ini mungkin tidak selalu tereksekusi karena adanya exit() di atas.
    // Namun, PHP akan otomatis menutup koneksi saat skrip berakhir.
    $stmt->close();
    $conn->close();

} else {
    // Jika metode request bukan POST
    http_response_code(405); // Method Not Allowed
    $response['status'] = 'error';
    $response['message'] = 'Invalid request method. Only POST requests are allowed.';
    echo json_encode($response);
    exit();
}
?>
