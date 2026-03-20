<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);
header('Content-Type: application/json');
include 'db_connect.php'; // Pastikan file koneksi database Anda ada

$response = array('success' => false, 'message' => 'An unknown error occurred.', 'data' => []);

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    $tracking_entry_id = $_GET['tracking_entry_id'] ?? null;

    if (is_null($tracking_entry_id)) {
        $response['message'] = 'Missing required parameter: tracking_entry_id.';
        echo json_encode($response);
        $conn->close();
        exit();
    }

    try {
        // 1. Ambil status is_confirmed dari tracking_entries
        $stmt_entry_status = $conn->prepare("SELECT is_confirmed FROM tracking_entries WHERE id = ?");
        if (!$stmt_entry_status) {
            throw new Exception("Prepare statement for entry status failed: " . $conn->error);
        }
        $stmt_entry_status->bind_param("i", $tracking_entry_id);
        $stmt_entry_status->execute();
        $result_entry_status = $stmt_entry_status->get_result();
        $entry_status_row = $result_entry_status->fetch_assoc();
        $stmt_entry_status->close();

        $is_confirmed = 0; // Default
        if ($entry_status_row) {
            $is_confirmed = (int)$entry_status_row['is_confirmed'];
        } else {
            // Jika tracking_entry_id tidak ditemukan, anggap tidak sukses
            $response['message'] = 'Tracking entry not found.';
            echo json_encode($response);
            $conn->close();
            exit();
        }

        // 2. Ambil semua detail kartu untuk tracking_entry_id yang diberikan
        $stmt_cards = $conn->prepare("SELECT id, model, runno_awal, runno_akhir, qty FROM tracking_card_details WHERE tracking_entry_id = ? ORDER BY id ASC");
        if (!$stmt_cards) {
            throw new Exception("Prepare statement for card details failed: " . $conn->error);
        }
        $stmt_cards->bind_param("i", $tracking_entry_id);
        $stmt_cards->execute();
        $result_cards = $stmt_cards->get_result();

        $card_details = [];
        while ($row = $result_cards->fetch_assoc()) {
            $card_details[] = $row;
        }

        $stmt_cards->close();

        $response['success'] = true;
        $response['message'] = 'Card details fetched successfully.';
        $response['is_confirmed'] = $is_confirmed; // Tambahkan status konfirmasi di sini
        $response['data'] = $card_details;

    } catch (Exception $e) {
        $response['message'] = 'Error fetching card details: ' . $e->getMessage();
    }
} else {
    $response['message'] = 'Invalid request method. Only GET is allowed.';
}

$conn->close();
echo json_encode($response);
?>
