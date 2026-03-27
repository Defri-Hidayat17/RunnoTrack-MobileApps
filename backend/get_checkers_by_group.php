<?php
header('Content-Type: application/json');
include 'db_connect.php'; // Sertakan file koneksi database

$response = array();
$checkers = array();

// Memastikan parameter group_code DAN account_type diterima
if (isset($_GET['group_code']) && isset($_GET['account_type'])) {
    $group_code = $_GET['group_code'];
    $account_type = $_GET['account_type']; // Parameter baru dari Flutter

    // Query untuk mengambil checker_name DAN phone_number berdasarkan group_code DAN associated_account_type
    $stmt = $conn->prepare("SELECT checker_name, phone_number FROM checkers WHERE group_code = ? AND associated_account_type = ? ORDER BY checker_name ASC");
    $stmt->bind_param("ss", $group_code, $account_type); // "ss" karena dua string
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result->num_rows > 0) {
        while($row = $result->fetch_assoc()) {
            // 🔥 Mengembalikan objek dengan 'name' dan 'phone'
            $checkers[] = [
                "name" => $row['checker_name'],
                "phone" => $row['phone_number']
            ];
        }
        $response['success'] = true;
        $response['data'] = $checkers;
    } else {
        $response['success'] = false;
        $response['message'] = 'Tidak ada checker ditemukan untuk grup ini dengan tipe akun tersebut.';
        $response['data'] = [];
    }
    $stmt->close();
} else {
    $response['success'] = false;
    $response['message'] = 'Parameter group_code atau account_type tidak ditemukan.';
    $response['data'] = [];
}

echo json_encode($response);
$conn->close();
?>
