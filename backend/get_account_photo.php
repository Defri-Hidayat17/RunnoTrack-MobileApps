<?php
// get_account_photo.php

error_reporting(E_ALL);
ini_set('display_errors', 1);

ob_start();

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With');

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    ob_clean();
    http_response_code(200);
    exit();
}

include 'db_connect.php';

if ($conn === null) {
    http_response_code(500);
    $response['status'] = 'error';
    $response['message'] = 'Database connection failed.';
    ob_clean();
    echo json_encode($response);
    exit();
}

$response = array();

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    $account_type = $_GET['account_type'] ?? '';

    if (empty($account_type)) {
        http_response_code(400);
        $response['status'] = 'error';
        $response['message'] = 'Account type is required.';
        ob_clean();
        echo json_encode($response);
        exit();
    }

    $stmt = $conn->prepare("SELECT photo_url FROM users WHERE account_type = ? LIMIT 1");
    if (!$stmt) {
        http_response_code(500);
        $response['status'] = 'error';
        $response['message'] = 'Failed to prepare statement: ' . $conn->error;
        ob_clean();
        echo json_encode($response);
        exit();
    }

    $stmt->bind_param("s", $account_type);
    $stmt->execute();
    $result = $stmt->get_result();

    $base_image_url = "http://192.168.1.10/runnotrack_api/images/";

    if ($result->num_rows > 0) {
        $row = $result->fetch_assoc();
        // ✅ PERBAIKAN: Tambahkan fallback 'default_avatar.png' jika $row['photo_url'] NULL
        $photo_full_url = $base_image_url . ($row['photo_url'] ?? 'default_avatar.png');

        $response['status'] = 'success';
        $response['message'] = 'Photo fetched successfully';
        $response['photo_url'] = $photo_full_url; // ✅ SELALU KIRIM URL LENGKAP DENGAN FALLBACK
        http_response_code(200);
    } else {
        // ✅ PERBAIKAN: Jika tidak ada user/foto, tetap kirimkan URL fallback
        $response['status'] = 'error';
        $response['message'] = 'No photo found for this account type. Using default.';
        $response['photo_url'] = $base_image_url . 'default_avatar.png'; // ✅ FALLBACK KE DEFAULT
        http_response_code(404);
    }

    $stmt->close();
} else {
    $response['status'] = 'error';
    $response['message'] = 'Invalid request method. Only GET is allowed.';
    http_response_code(405);
}

$conn->close();
ob_clean();
echo json_encode($response);
// HILANGKAN TAG PENUTUP PHP INI UNTUK MENCEGAH OUTPUT YANG TIDAK DIINGINKAN
