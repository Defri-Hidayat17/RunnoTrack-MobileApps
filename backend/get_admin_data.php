<?php
header('Content-Type: application/json');
include 'db_connect.php';

$response = array();
$response['success'] = false;
$response['message'] = "Terjadi kesalahan yang tidak diketahui.";

$image_base_url = "http://192.168.1.10/runnotrack_api/images/";

// 🔥 Ambil account_type dari Flutter
$account_type = isset($_GET['account_type']) ? $_GET['account_type'] : '';

try {

    // ======================
    // ✅ PIMPINAN (SELALU TAMPIL SEMUA)
    // ======================
    $stmt_pimpinan = $conn->prepare("
        SELECT 
            pd.id, 
            pd.pimpinan_name, 
            pd.department, 
            pd.phone_number, 
            pd.photo_url,
            u.id AS user_id 
        FROM pimpinan_details pd
        LEFT JOIN users u 
            ON pd.pimpinan_name = u.name 
            AND u.account_type = 'Pimpinan'
        ORDER BY pd.pimpinan_name ASC
    ");

    if (!$stmt_pimpinan) {
        throw new Exception("Prepare statement failed for pimpinan: " . $conn->error);
    }

    $stmt_pimpinan->execute();
    $result_pimpinan = $stmt_pimpinan->get_result();
    $pimpinan_data = [];

    while ($row = $result_pimpinan->fetch_assoc()) {
        if (!empty($row['photo_url'])) {
            $row['photo_url'] = $image_base_url . $row['photo_url'];
        }
        $pimpinan_data[] = $row;
    }

    $stmt_pimpinan->close();


    // ======================
    // ✅ CHECKER (FILTER SESUAI LOGIN)
    // ======================
    if (!empty($account_type)) {

        $stmt_checkers = $conn->prepare("
            SELECT 
                c.id, 
                c.checker_name, 
                c.group_code, 
                c.associated_account_type, 
                c.phone_number, 
                c.photo_url,
                u.id AS user_id
            FROM checkers c
            LEFT JOIN users u 
                ON c.checker_name = u.name 
                AND u.account_type = 'Operator'
            WHERE c.associated_account_type = ?
            ORDER BY c.checker_name ASC
        ");

        $stmt_checkers->bind_param("s", $account_type);

    } else {
        // fallback (kalau tidak dikirim dari Flutter)
        $stmt_checkers = $conn->prepare("
            SELECT 
                c.id, 
                c.checker_name, 
                c.group_code, 
                c.associated_account_type, 
                c.phone_number, 
                c.photo_url,
                u.id AS user_id
            FROM checkers c
            LEFT JOIN users u 
                ON c.checker_name = u.name 
                AND u.account_type = 'Operator'
            ORDER BY c.checker_name ASC
        ");
    }

    if (!$stmt_checkers) {
        throw new Exception("Prepare statement failed for checkers: " . $conn->error);
    }

    $stmt_checkers->execute();
    $result_checkers = $stmt_checkers->get_result();
    $checkers_data = [];

    while ($row = $result_checkers->fetch_assoc()) {
        if (!empty($row['photo_url'])) {
            $row['photo_url'] = $image_base_url . $row['photo_url'];
        }
        $checkers_data[] = $row;
    }

    $stmt_checkers->close();


    // ======================
    // RESPONSE
    // ======================
    $response['success'] = true;
    $response['message'] = "Data berhasil diambil.";
    $response['pimpinan'] = $pimpinan_data;
    $response['checkers'] = $checkers_data;

} catch (Exception $e) {
    $response['message'] = $e->getMessage();
}

$conn->close();
echo json_encode($response);
?>