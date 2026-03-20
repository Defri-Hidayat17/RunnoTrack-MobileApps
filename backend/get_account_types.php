<?php
// get_account_types.php

// Aktifkan pelaporan error untuk debugging (HAPUS ATAU NONAKTIFKAN DI PRODUKSI)
// error_reporting(E_ALL); // Hapus atau set ke 0 di produksi
// ini_set('display_errors', 1); // Hapus atau set ke 0 di produksi

// Mulai output buffering di awal skrip
ob_start();

// 1. Mengatur header HTTP untuk respons JSON dan CORS
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *'); // Izinkan semua origin (untuk development). Di produksi, ganti dengan domain Flutter Anda.
header('Access-Control-Allow-Methods: GET, OPTIONS'); // Izinkan metode GET
header('Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With');

// Jika ini adalah preflight request OPTIONS, langsung kirim respons OK
if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    ob_end_clean(); // Bersihkan buffer sebelum exit
    http_response_code(200);
    exit();
}

// Sertakan file koneksi database
// Pastikan file ini mendefinisikan variabel $conn untuk koneksi MySQLi
include 'db_connect.php';

$response = array(); // Inisialisasi array respons

// Pastikan koneksi database berhasil
if ($conn->connect_error) {
    http_response_code(500); // Internal Server Error
    $response['status'] = 'error';
    $response['message'] = 'Database connection failed: ' . $conn->connect_error; // Di produksi, ganti dengan pesan umum
    ob_end_clean(); // Bersihkan buffer sebelum mengirim respons
    echo json_encode($response);
    exit();
}

$account_types = array();

// Menggunakan prepared statement meskipun tidak ada input user langsung,
// ini adalah praktik yang baik untuk konsistensi dan keamanan.
$sql = "SELECT DISTINCT account_type FROM users ORDER BY account_type ASC";
$stmt = $conn->prepare($sql);

if ($stmt === false) {
    http_response_code(500); // Internal Server Error
    $response['status'] = 'error';
    $response['message'] = 'Failed to prepare statement: ' . $conn->error; // Di produksi, ganti dengan pesan umum
    ob_end_clean(); // Bersihkan buffer sebelum mengirim respons
    echo json_encode($response);
    exit();
}

$stmt->execute();
$result = $stmt->get_result();

if ($result) {
    if ($result->num_rows > 0) {
        while ($row = $result->fetch_assoc()) {
            $account_types[] = $row['account_type'];
        }
        http_response_code(200); // OK
        $response['status'] = 'success';
        $response['message'] = 'Account types fetched successfully.';
        $response['data'] = $account_types;
    } else {
        http_response_code(404); // Not Found
        $response['status'] = 'error';
        $response['message'] = 'No account types found.';
    }
} else {
    // Ini seharusnya sudah ditangani oleh pengecekan $stmt === false,
    // tetapi sebagai fallback jika ada masalah eksekusi yang tidak tertangkap prepare.
    http_response_code(500); // Internal Server Error
    $response['status'] = 'error';
    $response['message'] = 'Database query failed.'; // Pesan umum untuk produksi
    // error_log('Database query failed: ' . $conn->error); // Log error untuk debugging
}

$stmt->close();
$conn->close(); // Tutup koneksi database

ob_end_clean(); // Bersihkan buffer sebelum mengirim respons akhir
echo json_encode($response);
exit();

// HILANGKAN TAG PENUTUP PHP INI UNTUK MENCEGAH OUTPUT YANG TIDAK DIINGINKAN
// ?>
