<?php
header('Content-Type: application/json');
include 'db_connect.php'; // Pastikan file ini ada dan berisi koneksi database

$response = array('success' => false, 'message' => 'Terjadi kesalahan.', 'data' => []);

try {
    // Query untuk mengambil semua data checker
    // Menghapus 'user_id' sesuai permintaan
    $stmt = $conn->prepare("SELECT id, checker_name, group_code, associated_account_type, phone_number, photo_url FROM checkers ORDER BY checker_name ASC");
    $stmt->execute();
    $result = $stmt->get_result();

    $checkers = array();
    while ($row = $result->fetch_assoc()) {
        // Logika untuk menentukan 'role' (Pimpinan/Operator)
        // Anda bisa menyesuaikan logika ini sesuai dengan kriteria spesifik Anda
        $role = 'Operator'; // Default
        // Contoh sederhana: jika associated_account_type mengandung 'Pimpinan' atau nama mengandung 'Supervisor', 'Foreman', 'Leader'
        if (strpos($row['associated_account_type'], 'Pimpinan') !== false ||
            strpos($row['checker_name'], 'Supervisor') !== false ||
            strpos($row['checker_name'], 'Foreman') !== false ||
            strpos($row['checker_name'], 'Leader') !== false) {
             $role = 'Pimpinan';
        }

        // Pastikan URL foto lengkap jika ada, atau null jika tidak ada
        $full_photo_url = null;
        if (!empty($row['photo_url'])) {
            // Asumsi folder gambar adalah 'images/' di root API
            $full_photo_url = 'http://' . $_SERVER['HTTP_HOST'] . '/runnotrack_api/images/' . $row['photo_url'];
        }

        $checkers[] = array(
            'id' => $row['id'],
            'checker_name' => $row['checker_name'],
            'group_code' => $row['group_code'],
            'associated_account_type' => $row['associated_account_type'],
            'phone_number' => $row['phone_number'],
            'photo_url' => $full_photo_url,
            'role' => $role // Role yang ditentukan
        );
    }

    $response['success'] = true;
    $response['message'] = 'Data checker berhasil diambil.';
    $response['data'] = $checkers;

} catch (Exception $e) {
    $response['message'] = 'Error: ' . $e->getMessage();
}

echo json_encode($response);
$conn->close();
?>
