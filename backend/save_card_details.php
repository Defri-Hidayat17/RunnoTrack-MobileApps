<?php
// save_card_details.php

error_reporting(E_ALL);
ini_set('display_errors', 1);
header('Content-Type: application/json');
include 'db_connect.php';

$response = array('success' => false, 'message' => 'An unknown error occurred.');

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $input = json_decode(file_get_contents('php://input'), true);

    $tracking_entry_id = $input['tracking_entry_id'] ?? null; // ID dari tracking_entries
    $card_detail_id = $input['card_detail_id'] ?? null; // Opsional, untuk update
    $model = $input['model'] ?? null;
    $runno_awal = $input['runno_awal'] ?? null;
    $runno_akhir = $input['runno_akhir'] ?? null;
    $qty = $input['qty'] ?? null;

    // Basic validation
    if (is_null($tracking_entry_id) || empty($tracking_entry_id) ||
        is_null($model) || empty($model) ||
        is_null($runno_awal) || empty($runno_awal) ||
        is_null($runno_akhir) || empty($runno_akhir) ||
        is_null($qty)) {
        $response['message'] = 'Missing required parameters for card details. Debug info: ' .
                               'tracking_entry_id=' . ($tracking_entry_id ?? 'null') .
                               ', model=' . ($model ?? 'null') .
                               ', runno_awal=' . ($runno_awal ?? 'null') .
                               ', runno_akhir=' . ($runno_akhir ?? 'null') .
                               ', qty=' . ($qty ?? 'null');
        echo json_encode($response);
        $conn->close();
        exit();
    }

    $tracking_entry_id = (int) $tracking_entry_id;
    $qty = (int) $qty;

    $conn->begin_transaction();

    try {
        if ($card_detail_id !== null) { // Jika card_detail_id ada, lakukan UPDATE
            $card_detail_id = (int) $card_detail_id;
            $stmt_update_card = $conn->prepare("UPDATE tracking_card_details SET model = ?, runno_awal = ?, runno_akhir = ?, qty = ? WHERE id = ? AND tracking_entry_id = ?");
            if (!$stmt_update_card) {
                throw new Exception("Prepare update card statement failed: " . $conn->error);
            }
            $stmt_update_card->bind_param("sssiii", $model, $runno_awal, $runno_akhir, $qty, $card_detail_id, $tracking_entry_id);
            $stmt_update_card->execute();
            $stmt_update_card->close();
            $response['message'] = 'Card detail updated successfully.';
        } else { // Jika card_detail_id tidak ada, lakukan INSERT
            $stmt_insert_card = $conn->prepare("INSERT INTO tracking_card_details (tracking_entry_id, model, runno_awal, runno_akhir, qty) VALUES (?, ?, ?, ?, ?)");
            if (!$stmt_insert_card) {
                throw new Exception("Prepare insert card statement failed: " . $conn->error);
            }
            $stmt_insert_card->bind_param("isssi", $tracking_entry_id, $model, $runno_awal, $runno_akhir, $qty);
            $stmt_insert_card->execute();
            $card_detail_id = $conn->insert_id; // Ambil ID kartu yang baru dibuat
            $stmt_insert_card->close();
            $response['message'] = 'Card detail created successfully.';
        }

        $conn->commit();
        $response['success'] = true;
        $response['card_detail_id'] = $card_detail_id; // Kembalikan ID detail kartu
    } catch (Exception $e) {
        $conn->rollback();
        $response['message'] = 'Error saving card details: ' . $e->getMessage();
    }
} else {
    $response['message'] = 'Invalid request method. Only POST is allowed.';
}

$conn->close();
echo json_encode($response);
?>
