<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

ob_start();

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With');

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}

include 'db_connect.php';

$response = array();

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $name = $_POST['name'] ?? '';
    $username = $_POST['username'] ?? '';
    $password = $_POST['password'] ?? '';
    $role = $_POST['role'] ?? '';
    $account_type = $_POST['account_type'] ?? 'User';

    if (empty($name) || empty($username) || empty($password) || empty($role)) {
        $response['success'] = false;
        $response['message'] = 'Nama, username, password, dan jabatan tidak boleh kosong.';
        ob_clean();
        echo json_encode($response);
        exit();
    }

    $hashed_password = password_hash($password, PASSWORD_DEFAULT);

    $photo_url = null;
    $upload_dir = 'uploads/profile_photos/';
    if (!is_dir($upload_dir)) {
        mkdir($upload_dir, 0777, true);
    }

    if (isset($_FILES['profile_photo']) && $_FILES['profile_photo']['error'] == UPLOAD_ERR_OK) {
        $file_tmp_name = $_FILES['profile_photo']['tmp_name'];
        $file_name = uniqid() . '_' . basename($_FILES['profile_photo']['name']);
        $destination = $upload_dir . $file_name;

        if (move_uploaded_file($file_tmp_name, $destination)) {
            $photo_url = 'http://' . $_SERVER['SERVER_ADDR'] . '/runnotrack_api/' . $destination;
        } else {
            $response['success'] = false;
            $response['message'] = 'Gagal mengunggah foto profil.';
            ob_clean();
            echo json_encode($response);
            exit();
        }
    }

    $stmt = $conn->prepare("INSERT INTO users (name, username, password, role, account_type, photo_url) VALUES (?, ?, ?, ?, ?, ?)");
    if ($stmt === false) {
        $response['success'] = false;
        $response['message'] = 'Failed to prepare statement: ' . $conn->error;
        ob_clean();
        echo json_encode($response);
        exit();
    }

    $stmt->bind_param("ssssss", $name, $username, $hashed_password, $role, $account_type, $photo_url);

    if ($stmt->execute()) {
        $response['success'] = true;
        $response['message'] = 'Member baru berhasil ditambahkan.';
    } else {
        if ($conn->errno == 1062) {
            $response['success'] = false;
            $response['message'] = 'Username sudah ada. Harap gunakan username lain.';
        } else {
            $response['success'] = false;
            $response['message'] = 'Gagal menambahkan member: ' . $stmt->error;
        }
    }

    $stmt->close();
    $conn->close();

} else {
    http_response_code(405);
    $response['success'] = false;
    $response['message'] = 'Metode request tidak diizinkan.';
}

ob_clean();
echo json_encode($response);
exit();
?>
