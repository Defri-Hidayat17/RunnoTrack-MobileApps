<?php
error_reporting(E_ALL); // Hapus atau set ke 0 di produksi
ini_set('display_errors', 1); // Hapus atau set ke 0 di produksi
header('Content-Type: application/json');
include 'db_connect.php'; // Pastikan file koneksi database Anda ada

$response = array('success' => false, 'message' => 'An unknown error occurred.');

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    $entry_date_param = $_GET['entry_date'] ?? null;
    $group_code_param = $_GET['group_code'] ?? null;
    $checker_username_param = $_GET['checker_username'] ?? null;
    // 🔥 PENTING: Tambahkan user_id sebagai parameter yang WAJIB
    $user_id_param = $_GET['user_id'] ?? null;

    if (is_null($entry_date_param) || is_null($group_code_param) || is_null($checker_username_param) || is_null($user_id_param)) {
        $response['message'] = 'Missing required parameters: entry_date, group_code, checker_username, or user_id.';
        echo json_encode($response);
        $conn->close();
        exit();
    }

    $entry_date = $entry_date_param;
    $group_code = $group_code_param;
    $checker_username = $checker_username_param;
    $user_id = $user_id_param;

    try {
        // 🔥 Tambahkan user_id ke klausa WHERE
        $stmt_entry = $conn->prepare("SELECT id, group_code, checker_username, total_target, is_confirmed FROM tracking_entries WHERE entry_date = ? AND group_code = ? AND checker_username = ? AND user_id = ?");
        if (!$stmt_entry) {
            throw new Exception("Prepare statement failed: " . $conn->error);
        }
        $stmt_entry->bind_param("ssss", $entry_date, $group_code, $checker_username, $user_id); // "ssss" untuk 4 string
        $stmt_entry->execute();
        $result_entry = $stmt_entry->get_result();

        if ($result_entry->num_rows > 0) {
            $entry_data = $result_entry->fetch_assoc();
            $tracking_entry_id = $entry_data['id'];

            $stmt_cards = $conn->prepare("SELECT id, model, runno_awal, runno_akhir, qty FROM tracking_card_details WHERE tracking_entry_id = ?");
            if (!$stmt_cards) {
                throw new Exception("Prepare statement for cards failed: " . $conn->error);
            }
            $stmt_cards->bind_param("i", $tracking_entry_id);
            $stmt_cards->execute();
            $result_cards = $stmt_cards->get_result();

            $card_details = [];
            if ($result_cards->num_rows > 0) {
                while($row_card = $result_cards->fetch_assoc()) {
                    $card_details[] = $row_card;
                }
            }
            $stmt_cards->close();

            $response['success'] = true;
            $response['message'] = 'Tracking data found.';
            $response['data'] = [
                [
                    'tracking_entry_id' => $tracking_entry_id,
                    'total_target' => $entry_data['total_target'],
                    'is_confirmed' => $entry_data['is_confirmed'],
                    'cards' => $card_details
                ]
            ];
        } else {
            $response['success'] = true;
            $response['message'] = 'No tracking data found for this criteria.';
            $response['data'] = [];
        }
        $stmt_entry->close();

    } catch (Exception $e) {
        $response['message'] = 'Error fetching data: ' . $e->getMessage();
        $response['success'] = false;
    }
} else {
    $response['message'] = 'Invalid request method. Only GET is allowed.';
    $response['success'] = false;
}

$conn->close();
echo json_encode($response);
?>
