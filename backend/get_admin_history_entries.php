<?php
// get_admin_history_entries.php

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
    $response['success'] = false;
    $response['message'] = 'Database connection failed.';
    ob_clean();
    echo json_encode($response);
    exit();
}

$response = array();

$query_param = $_GET['query'] ?? '';
$production_type_filter_from_flutter = $_GET['production_type'] ?? null;

if (empty($production_type_filter_from_flutter)) {
    http_response_code(400);
    $response['success'] = false;
    $response['message'] = 'Production type filter is required.';
    ob_clean();
    echo json_encode($response);
    exit();
}

$check_column_sql = "SHOW COLUMNS FROM tracking_entries LIKE 'production_type'";
$column_result = $conn->query($check_column_sql);

if ($column_result->num_rows == 0) {
    http_response_code(500);
    $response['success'] = false;
    $response['message'] = 'Database error: Column `production_type` not found in `tracking_entries` table. Please add it.';
    ob_clean();
    echo json_encode($response);
    exit();
}

// Base URL untuk gambar - PASTIKAN IP INI BENAR
$base_image_url = "http://192.168.1.10/runnotrack_api/images/";

$sql = "SELECT
            te.id AS tracking_entry_id,
            te.entry_date,
            te.group_code,
            te.checker_username,
            te.total_target,
            te.is_confirmed,
            te.production_type,
            u.account_type,
            u.name AS user_name_from_db,  -- ✅ Ganti nama alias untuk menghindari konflik
            u.photo_url AS user_photo_filename_from_db, -- ✅ Ganti nama alias
            td.id AS tracking_detail_id,
            td.model,
            td.runno_awal,
            td.runno_akhir,
            td.qty
        FROM
            tracking_entries te
        JOIN
            users u ON te.user_id = u.id
        LEFT JOIN
            tracking_card_details td ON te.id = td.tracking_entry_id

        WHERE 1=1";

$params = [];
$types = "";

$production_type_for_db_query = $production_type_filter_from_flutter;

if ($production_type_filter_from_flutter == 'KaishiPicking') {
    $production_type_for_db_query = 'Kaishi Picking';
} elseif ($production_type_filter_from_flutter == 'Crossline') {
    $production_type_for_db_query = 'CrossLine';
}

$sql .= " AND te.production_type = ?";
$params[] = $production_type_for_db_query;
$types .= "s";

if (!empty($query_param)) {
    $sql .= " AND (u.name LIKE ? OR te.checker_username LIKE ? OR te.group_code LIKE ? OR te.entry_date LIKE ?)";
    $search_term = "%" . $query_param . "%";
    $params[] = $search_term;
    $params[] = $search_term;
    $params[] = $search_term;
    $params[] = $search_term;
    $types .= "ssss";
}

$sql .= " ORDER BY te.entry_date DESC, te.id DESC, td.id ASC";

$stmt = $conn->prepare($sql);

if ($stmt === false) {
    http_response_code(500);
    $response['success'] = false;
    $response['message'] = 'Failed to prepare statement: ' . $conn->error;
    ob_clean();
    echo json_encode($response);
    exit();
}

if (!empty($params)) {
    if (strlen($types) != count($params)) {
        http_response_code(500);
        $response['success'] = false;
        $response['message'] = 'Internal server error: Parameter type mismatch in bind_param. Debug info: Expected ' . strlen($types) . ' got ' . count($params) . ' for types ' . $types . ' with params ' . json_encode($params);
        ob_clean();
        echo json_encode($response);
        exit();
    }
    call_user_func_array(array($stmt, 'bind_param'), array_merge(array($types), refValues($params)));
}

function refValues($arr){
    if (strnatcmp(phpversion(),'5.3') >= 0) //PHP 5.3+
    {
        $refs = array();
        foreach($arr as $key => $value)
            $refs[$key] = &$arr[$key];
        return $refs;
    }
    return $arr;
}

$stmt->execute();
$result = $stmt->get_result();

$history_entries = [];
$current_entry_id = null;
$current_entry = null;

while ($row = $result->fetch_assoc()) {
    if ($row['tracking_entry_id'] !== $current_entry_id) {
        if ($current_entry !== null) {
            $current_entry['total_actual_qty'] = array_sum(array_column($current_entry['details'], 'qty'));
            $current_entry['difference'] = $current_entry['total_actual_qty'] - $current_entry['total_target'];
            $current_entry['efficiency_percentage'] = ($current_entry['total_target'] > 0)
                ? ($current_entry['total_actual_qty'] / $current_entry['total_target']) * 100
                : 0.0;
            $history_entries[] = $current_entry;
        }
        $current_entry_id = $row['tracking_entry_id'];

        // ✅ PERBAIKAN: Bangun URL lengkap untuk user_photo_url dengan fallback
        $full_user_photo_url = $base_image_url . ($row['user_photo_filename_from_db'] ?? 'default_avatar.png');
        // ✅ PERBAIKAN: Tambahkan fallback untuk user_name jika NULL
        $user_name_display = $row['user_name_from_db'] ?? 'Tidak Diketahui';


        $current_entry = [
            'id' => $row['tracking_entry_id'],
            'entry_date' => date('Y-m-d', strtotime($row['entry_date'])),
            'group_code' => $row['group_code'],
            'checker_username' => $row['checker_username'],
            'total_target' => (int)$row['total_target'],
            'is_confirmed' => (bool)$row['is_confirmed'],
            'production_type' => $row['production_type'],
            'user_account_type' => $row['account_type'],
            'user_name' => $user_name_display, // ✅ Gunakan nama dengan fallback
            'user_photo_url' => $full_user_photo_url, // ✅ Kirim URL LENGKAP
            'details' => []
        ];
    }

    if ($row['tracking_detail_id'] !== null) {
        $current_entry['details'][] = [
            'id' => $row['tracking_detail_id'],
            'model' => $row['model'],
            'runno_awal' => $row['runno_awal'],
            'runno_akhir' => $row['runno_akhir'],
            'qty' => (int)$row['qty']
        ];
    }
}

if ($current_entry !== null) {
    $current_entry['total_actual_qty'] = array_sum(array_column($current_entry['details'], 'qty'));
    $current_entry['difference'] = $current_entry['total_actual_qty'] - $current_entry['total_target'];
    $current_entry['efficiency_percentage'] = ($current_entry['total_target'] > 0)
                ? ($current_entry['total_actual_qty'] / $current_entry['total_target']) * 100
                : 0.0;
    $history_entries[] = $current_entry;
}

$response['success'] = true;
$response['message'] = 'History entries fetched successfully.';
$response['data'] = $history_entries;

$stmt->close();
$conn->close();

ob_clean();
echo json_encode($response);
// HILANGKAN TAG PENUTUP PHP INI UNTUK MENCEGAH OUTPUT YANG TIDAK DIINGINKAN
