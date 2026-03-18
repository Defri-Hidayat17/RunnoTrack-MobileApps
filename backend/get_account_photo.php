<?php
// get_account_photo.php

// Mengatur header HTTP untuk respons JSON dan CORS
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *'); // Izinkan semua origin (untuk development). Di produksi, ganti dengan domain Flutter Anda.
header('Access-Control-Allow-Methods: GET, OPTIONS'); // Izinkan metode GET
header('Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With');

// Jika ini adalah preflight request OPTIONS, langsung kirim respons OK
if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Sertakan file koneksi database
include 'db_connect.php';

$response = array();

// Pastikan parameter account_type diterima dari URL
if (isset($_GET['account_type'])) {
    $account_type = $_GET['account_type'];

    // Ambil photo_url untuk salah satu user dengan account_type yang diberikan
    // Menggunakan LIMIT 1 karena kita hanya butuh satu foto untuk representasi tipe akun
    $sql = "SELECT photo_url FROM users WHERE account_type = ? LIMIT 1";
    $stmt = $conn->prepare($sql);

    // Cek apakah statement berhasil dipersiapkan
    if ($stmt === false) {
        $response['status'] = 'error';
        $response['message'] = 'Failed to prepare statement: ' . $conn->error;
        echo json_encode($response);
        exit();
    }

    // Bind parameter dan eksekusi statement
    $stmt->bind_param("s", $account_type); // "s" karena account_type adalah string
    $stmt->execute();
    $result = $stmt->get_result();

    // Cek apakah ada hasil
    if ($result->num_rows > 0) {
        $user = $result->fetch_assoc();
        // Bangun URL lengkap untuk gambar
        // Pastikan IP ini sesuai dengan IP komputer Anda dan nama folder API
        $photo_full_url = "http://192.168.1.10/runnotrack_api/images/" . $user['photo_url'];

        $response['status'] = 'success';
        $response['message'] = 'Photo URL fetched successfully.';
        $response['photo_url'] = $photo_full_url;
    } else {
        $response['status'] = 'error';
        $response['message'] = 'No photo found for this account type.';
    }

    // Tutup statement
    $stmt->close();
} else {
    // Jika parameter account_type tidak ada
    $response['status'] = 'error';
    $response['message'] = 'Account type is required.';
}

// Tutup koneksi database
$conn->close();

// Kirim respons JSON
echo json_encode($response);
exit();

?>
