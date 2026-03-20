<?php
// login.php

error_reporting(E_ALL);
ini_set('display_errors', 1);

ob_start();

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With');

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    ob_clean();
    http_response_code(200);
    exit();
}

include 'db_connect.php';

if ($conn === null) {
    http_response_code(500);
    $response['success'] = false;
    $response['message'] = 'Database connection failed.';
    ob_clean();
    echo json_encode($response);
    exit();
}

$response = array();

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $username = $_POST['username'] ?? '';
    $password = $_POST['password'] ?? '';
    $account_type = $_POST['account_type'] ?? '';

    if (empty($username) || empty($password) || empty($account_type)) {
        http_response_code(400);
        $response['status'] = 'error';
        $response['message'] = 'Username, password, and account type are required.';
        ob_clean();
        echo json_encode($response);
        exit();
    }

    $stmt = $conn->prepare("SELECT id, username, password, name, role, account_type, photo_url FROM users WHERE username = ? AND account_type = ?");
    if (!$stmt) {
        http_response_code(500);
        $response['status'] = 'error';
        $response['message'] = 'Failed to prepare statement: ' . $conn->error;
        ob_clean();
        echo json_encode($response);
        exit();
    }

    $stmt->bind_param("ss", $username, $account_type);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result->num_rows > 0) {
        $user = $result->fetch_assoc();

        if (password_verify($password, $user['password'])) {
            $base_image_url = "http://192.168.1.10/runnotrack_api/images/";
            // ✅ PERBAIKAN: Tambahkan fallback 'default_avatar.png' jika $user['photo_url'] NULL
            $photo_full_url = $base_image_url . ($user['photo_url'] ?? 'default_avatar.png');

            $response['status'] = 'success';
            $response['message'] = 'Login successful!';
            $response['user_data'] = [
                'user_id' => $user['id'],
                'username' => $user['username'],
                // ✅ PERBAIKAN: Tambahkan fallback 'Pengguna' jika $user['name'] NULL
                'name' => $user['name'] ?? 'Pengguna',
                'role' => $user['role'],
                'account_type' => $user['account_type'],
                'photo_url' => $photo_full_url // ✅ SELALU KIRIM URL LENGKAP DENGAN FALLBACK
            ];
            http_response_code(200);
        } else {
            $response['status'] = 'error';
            $response['message'] = 'ID atau kata sandi salah.';
            http_response_code(401);
        }
    } else {
        $response['status'] = 'error';
        $response['message'] = 'ID atau kata sandi salah.';
        http_response_code(401);
    }

    $stmt->close();
} else {
    $response['status'] = 'error';
    $response['message'] = 'Invalid request method. Only POST is allowed.';
    http_response_code(405);
}

$conn->close();
ob_clean();
echo json_encode($response);
// HILANGKAN TAG PENUTUP PHP INI UNTUK MENCEGAH OUTPUT YANG TIDAK DIINGINKAN
