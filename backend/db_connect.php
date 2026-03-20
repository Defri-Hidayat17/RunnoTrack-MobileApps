<?php
// db_connect.php

$host = "localhost";
$user = "root";
$pass = "";
$db   = "runnotrack_db";

$conn = new mysqli($host,$user,$pass,$db);

// Jangan gunakan die() di sini. Biarkan skrip pemanggil yang menangani error.
// Jika koneksi gagal, $conn akan memiliki properti connect_error yang bisa diperiksa.
// Atau, kita bisa set $conn = null; untuk indikasi yang jelas.
if ($conn->connect_error) {
    // Untuk API, lebih baik log error ini daripada mencetaknya ke output
    error_log("Database Connection Failed: " . $conn->connect_error);
    $conn = null; // Set $conn menjadi null jika koneksi gagal
} else {
    $conn->set_charset("utf8mb4");
}

// Hapus tag penutup ?>
