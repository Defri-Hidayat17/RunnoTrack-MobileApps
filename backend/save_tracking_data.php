<?php

error_reporting(E_ALL);
ini_set('display_errors', 1);
header('Content-Type: application/json');
include 'db_connect.php'; // Pastikan file koneksi database Anda ada

$response = array('success' => false, 'message' => 'An unknown error occurred.');

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $input = json_decode(file_get_contents('php://input'), true);

    $tracking_entry_id_param = $input['tracking_entry_id'] ?? null; // NEW: Optional tracking_entry_id
    $entry_date = $input['entry_date'] ?? null;
    $group_code = $input['group_code'] ?? null;
    $checker_username = $input['checker_username'] ?? null;
    $total_target = $input['total_target'] ?? null;
    $user_id = $input['user_id'] ?? null; // NEW: user_id
    $cards = $input['cards'] ?? []; // Expecting an array of cards

    // Basic validation
    if (is_null($entry_date) || empty($entry_date) ||
        is_null($group_code) || empty($group_code) ||
        is_null($checker_username) || empty($checker_username) ||
        is_null($total_target) ||
        is_null($user_id) || empty($user_id) || // user_id is now required
        !is_array($cards)) {
        $response['message'] = 'Missing required parameters or invalid cards data.';
        echo json_encode($response);
        $conn->close();
        exit();
    }

    $total_target = (int) $total_target;

    $conn->begin_transaction();

    try {
        $tracking_entry_id = null;
        $is_confirmed = 0;

        // 1. Check if tracking_entry already exists
        // Prioritize tracking_entry_id if provided
        if ($tracking_entry_id_param !== null) {
            $stmt_check_entry = $conn->prepare("SELECT id, is_confirmed FROM tracking_entries WHERE id = ? AND user_id = ?");
            if (!$stmt_check_entry) {
                throw new Exception("Prepare statement failed: " . $conn->error);
            }
            $stmt_check_entry->bind_param("ii", $tracking_entry_id_param, $user_id);
        } else {
            // Otherwise, find by date, group, checker, and user_id
            // NOTE: If entry_date, group_code, checker_username are changed,
            // this search might not find the old entry.
            // The Flutter app should always pass tracking_entry_id if it's an existing entry.
            $stmt_check_entry = $conn->prepare("SELECT id, is_confirmed FROM tracking_entries WHERE entry_date = ? AND group_code = ? AND checker_username = ? AND user_id = ?");
            if (!$stmt_check_entry) {
                throw new Exception("Prepare statement failed: " . $conn->error);
            }
            $stmt_check_entry->bind_param("ssss", $entry_date, $group_code, $checker_username, $user_id);
        }

        $stmt_check_entry->execute();
        $result_check_entry = $stmt_check_entry->get_result();

        if ($result_check_entry->num_rows > 0) {
            $row = $result_check_entry->fetch_assoc();
            $tracking_entry_id = $row['id'];
            $is_confirmed = $row['is_confirmed'];

            // --- PERBAIKAN: Update semua kolom header yang bisa diubah ---
            $stmt_update_entry = $conn->prepare("UPDATE tracking_entries SET entry_date = ?, group_code = ?, checker_username = ?, total_target = ? WHERE id = ? AND user_id = ?");
            if (!$stmt_update_entry) {
                throw new Exception("Prepare update entry statement failed: " . $conn->error);
            }
            $stmt_update_entry->bind_param("sssiis", $entry_date, $group_code, $checker_username, $total_target, $tracking_entry_id, $user_id);
            $stmt_update_entry->execute();
            $stmt_update_entry->close();
            // --- AKHIR PERBAIKAN ---

        } else {
            // If not exists, create a new entry
            $stmt_insert_entry = $conn->prepare("INSERT INTO tracking_entries (entry_date, group_code, checker_username, total_target, user_id, is_confirmed) VALUES (?, ?, ?, ?, ?, 0)");
            if (!$stmt_insert_entry) {
                throw new Exception("Prepare insert statement failed: " . $conn->error);
            }
            $stmt_insert_entry->bind_param("sssis", $entry_date, $group_code, $checker_username, $total_target, $user_id);
            $stmt_insert_entry->execute();
            $tracking_entry_id = $conn->insert_id;
            $stmt_insert_entry->close();
        }
        $stmt_check_entry->close();

        if ($tracking_entry_id) {
            // If entry is confirmed, no modifications to cards are allowed
            if ($is_confirmed == 1) {
                $conn->rollback();
                $response['message'] = 'Error: Data sudah dikonfirmasi dan tidak dapat diubah.';
                echo json_encode($response);
                $conn->close();
                exit();
            }

            // --- LOGIKA UNTUK MENGHAPUS KARTU YANG DIHILANGKAN ---
            $existing_card_ids_db = [];
            $stmt_get_existing_cards = $conn->prepare("SELECT id FROM tracking_card_details WHERE tracking_entry_id = ?");
            if (!$stmt_get_existing_cards) {
                throw new Exception("Prepare statement for getting existing cards failed: " . $conn->error);
            }
            $stmt_get_existing_cards->bind_param("i", $tracking_entry_id);
            $stmt_get_existing_cards->execute();
            $result_existing_cards = $stmt_get_existing_cards->get_result();
            while ($row = $result_existing_cards->fetch_assoc()) {
                $existing_card_ids_db[] = $row['id'];
            }
            $stmt_get_existing_cards->close();

            $incoming_card_ids = [];
            foreach ($cards as $card) {
                if (isset($card['id']) && $card['id'] !== null) { // Use 'id' from Flutter's toJson, which maps to cardDetailId
                    $incoming_card_ids[] = $card['id'];
                }
            }

            $card_ids_to_delete = array_diff($existing_card_ids_db, $incoming_card_ids);

            if (!empty($card_ids_to_delete)) {
                $placeholders = implode(',', array_fill(0, count($card_ids_to_delete), '?'));
                $stmt_delete_cards = $conn->prepare("DELETE FROM tracking_card_details WHERE id IN ($placeholders) AND tracking_entry_id = ?");
                if (!$stmt_delete_cards) {
                    throw new Exception("Prepare delete cards statement failed: " . $conn->error);
                }
                $types = str_repeat('i', count($card_ids_to_delete)) . 'i';
                $bind_values = array_merge($card_ids_to_delete, [$tracking_entry_id]);
                $stmt_delete_cards->bind_param($types, ...$bind_values);
                $stmt_delete_cards->execute();
                $stmt_delete_cards->close();
            }
            // --- AKHIR LOGIKA PENGHAPUSAN KARTU ---


            // 2. Proses detail kartu (INSERT atau UPDATE)
            foreach ($cards as $card) {
                $card_detail_id = $card['id'] ?? null; // Use 'id' from Flutter's toJson
                $model = $card['model'] ?? null;
                $runno_awal = $card['runno_awal'] ?? null;
                $runno_akhir = $card['runno_akhir'] ?? null;
                $qty = $card['qty'] ?? null;

                if (is_null($model) || empty($model) ||
                    is_null($runno_awal) || empty($runno_awal) ||
                    is_null($runno_akhir) || empty($runno_akhir) ||
                    is_null($qty)) {
                    throw new Exception("Missing or empty card details in one of the cards. Model: " . ($model ?? 'null') . ", Runno Awal: " . ($runno_awal ?? 'null') . ", Runno Akhir: " . ($runno_akhir ?? 'null') . ", Qty: " . ($qty ?? 'null'));
                }

                $qty = (int) $qty;

                // If card_detail_id is present AND it exists in the DB (was not deleted), UPDATE
                if ($card_detail_id !== null && in_array($card_detail_id, $existing_card_ids_db)) {
                    $stmt_update_card = $conn->prepare("UPDATE tracking_card_details SET model = ?, runno_awal = ?, runno_akhir = ?, qty = ? WHERE id = ? AND tracking_entry_id = ?");
                    if (!$stmt_update_card) {
                        throw new Exception("Prepare update card statement failed: " . $conn->error);
                    }
                    $stmt_update_card->bind_param("sssiii", $model, $runno_awal, $runno_akhir, $qty, $card_detail_id, $tracking_entry_id);
                    $stmt_update_card->execute();
                    $stmt_update_card->close();
                } else { // If card_detail_id is null or not found in DB, INSERT (this is a new card)
                    $stmt_insert_card = $conn->prepare("INSERT INTO tracking_card_details (tracking_entry_id, model, runno_awal, runno_akhir, qty) VALUES (?, ?, ?, ?, ?)");
                    if (!$stmt_insert_card) {
                        throw new Exception("Prepare insert card statement failed: " . $conn->error);
                    }
                    $stmt_insert_card->bind_param("isssi", $tracking_entry_id, $model, $runno_awal, $runno_akhir, $qty);
                    $stmt_insert_card->execute();
                    $stmt_insert_card->close();
                }
            }

            $conn->commit();
            $response['success'] = true;
            $response['message'] = 'Data tracking dan kartu berhasil disimpan/diperbarui.';
            $response['tracking_entry_id'] = $tracking_entry_id; // Tambahkan ID ke respons
        } else {
            throw new Exception("Failed to get or create tracking_entry_id.");
        }

    } catch (Exception $e) {
        $conn->rollback();
        $response['message'] = 'Error saving data: ' . $e->getMessage();
    }
} else {
    $response['message'] = 'Invalid request method. Only POST is allowed.';
}

$conn->close();
echo json_encode($response);
?>
