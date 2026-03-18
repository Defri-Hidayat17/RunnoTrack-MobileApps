<?php
header('Content-Type: application/json');
include 'db_connect.php'; // Pastikan file koneksi database Anda ada

$response = array('success' => false, 'message' => 'An unknown error occurred.');

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    // Ambil semua parameter yang diharapkan dari Flutter
    $entry_date_param = $_GET['entry_date'] ?? null;
    $group_code_param = $_GET['group_code'] ?? null;
    $checker_username_param = $_GET['checker_username'] ?? null;

    if (is_null($entry_date_param) || is_null($group_code_param) || is_null($checker_username_param)) {
        $response['message'] = 'Missing required parameters: entry_date, group_code, or checker_username.';
        echo json_encode($response);
        $conn->close();
        exit();
    }

    $entry_date = $entry_date_param;
    $group_code = $group_code_param;
    $checker_username = $checker_username_param;

    try {
        // Ambil tracking_entry untuk tanggal, grup, dan checker yang diberikan
        $stmt_entry = $conn->prepare("SELECT id, group_code, checker_username, total_target, is_confirmed FROM tracking_entries WHERE entry_date = ? AND group_code = ? AND checker_username = ?");
        $stmt_entry->bind_param("sss", $entry_date, $group_code, $checker_username);
        $stmt_entry->execute();
        $result_entry = $stmt_entry->get_result();

        if ($result_entry->num_rows > 0) {
            $entry_data = $result_entry->fetch_assoc();
            $tracking_entry_id = $entry_data['id'];

            // Ambil detail kartu terkait
            // Menghapus 'id' dari SELECT jika tidak diperlukan di Flutter
            $stmt_cards = $conn->prepare("SELECT model, runno_awal, runno_akhir, qty FROM tracking_card_details WHERE tracking_entry_id = ?");
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

            // Strukturkan respons agar sesuai dengan ekspektasi Flutter
            $response['success'] = true;
            $response['message'] = 'Tracking data found.';
            $response['data'] = [ // Flutter mengharapkan array 'data'
                [ // Dan di dalamnya ada satu objek
                    'total_target' => $entry_data['total_target'],
                    'is_confirmed' => $entry_data['is_confirmed'],
                    'cards' => $card_details // Array kartu di dalam objek ini
                ]
            ];
        } else {
            // Jika tidak ada data tracking_entry yang ditemukan untuk kriteria ini
            $response['success'] = true; // Tetap success, hanya tidak ada data yang ditemukan
            $response['message'] = 'No tracking data found for this criteria.';
            $response['data'] = []; // Kirim array 'data' kosong
        }
        $stmt_entry->close();

    } catch (Exception $e) {
        $response['message'] = 'Error fetching data: ' . $e->getMessage();
    }
} else {
    $response['message'] = 'Invalid request method. Only GET is allowed.';
}

$conn->close();
echo json_encode($response);
?>
