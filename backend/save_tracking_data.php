<?php
header('Content-Type: application/json');
include 'db_connect.php'; // Pastikan file koneksi database Anda ada

$response = array('success' => false, 'message' => 'An unknown error occurred.');

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $input = json_decode(file_get_contents('php://input'), true);

    // --- PERBAIKAN DI SINI: Sesuaikan nama key dengan yang dikirim dari Flutter ---
    $entry_date = $input['entry_date'] ?? null;
    $group_code = $input['group_code'] ?? null; // Diperbaiki dari 'selected_group'
    $checker_username = $input['checker_username'] ?? null; // Diperbaiki dari 'selected_checker'
    $total_target = $input['total_target'] ?? null;
    $cards = $input['cards'] ?? []; // Expecting an array of cards

    // Basic validation
    if (is_null($entry_date) || empty($entry_date) || // Tambahkan empty check untuk string
        is_null($group_code) || empty($group_code) ||
        is_null($checker_username) || empty($checker_username) ||
        is_null($total_target) || // total_target bisa 0, jadi jangan pakai empty()
        empty($cards)) { // Pastikan array cards tidak kosong
        $response['message'] = 'Missing required parameters or no cards provided. Debug info: ' .
                               'entry_date=' . ($entry_date ?? 'null') .
                               ', group_code=' . ($group_code ?? 'null') .
                               ', checker_username=' . ($checker_username ?? 'null') .
                               ', total_target=' . ($total_target ?? 'null') .
                               ', cards_empty=' . (empty($cards) ? 'true' : 'false');
        echo json_encode($response);
        $conn->close();
        exit();
    }

    // Pastikan total_target adalah integer
    $total_target = (int) $total_target;

    $conn->begin_transaction();

    try {
        // 1. Check if tracking_entry already exists for this date, group, and checker
        $stmt_check_entry = $conn->prepare("SELECT id FROM tracking_entries WHERE entry_date = ? AND group_code = ? AND checker_username = ?");
        if (!$stmt_check_entry) {
            throw new Exception("Prepare statement failed: " . $conn->error);
        }
        $stmt_check_entry->bind_param("sss", $entry_date, $group_code, $checker_username);
        $stmt_check_entry->execute();
        $result_check_entry = $stmt_check_entry->get_result();
        $tracking_entry_id = null;

        if ($result_check_entry->num_rows > 0) {
            // If exists, get its ID and update total_target
            $row = $result_check_entry->fetch_assoc();
            $tracking_entry_id = $row['id'];

            $stmt_update_target = $conn->prepare("UPDATE tracking_entries SET total_target = ? WHERE id = ?");
            if (!$stmt_update_target) {
                throw new Exception("Prepare update statement failed: " . $conn->error);
            }
            $stmt_update_target->bind_param("ii", $total_target, $tracking_entry_id);
            $stmt_update_target->execute();
            $stmt_update_target->close();

        } else {
            // If not exists, create a new entry
            $stmt_insert_entry = $conn->prepare("INSERT INTO tracking_entries (entry_date, group_code, checker_username, total_target) VALUES (?, ?, ?, ?)");
            if (!$stmt_insert_entry) {
                throw new Exception("Prepare insert statement failed: " . $conn->error);
            }
            $stmt_insert_entry->bind_param("sssi", $entry_date, $group_code, $checker_username, $total_target);
            $stmt_insert_entry->execute();
            $tracking_entry_id = $conn->insert_id; // Get the newly created ID
            $stmt_insert_entry->close();
        }
        $stmt_check_entry->close();

        if ($tracking_entry_id) {
            // 2. Insert card details into tracking_card_details
            // Assuming only one card is sent at a time from the current Flutter logic
            foreach ($cards as $card) {
                $model = $card['model'] ?? null;
                // --- PERBAIKAN DI SINI: Sesuaikan nama key dengan yang dikirim dari Flutter ---
                $runno_awal = $card['runno_awal'] ?? null; // Diperbaiki dari 'runnoAwal'
                $runno_akhir = $card['runno_akhir'] ?? null; // Diperbaiki dari 'runnoAkhir'
                $qty = $card['qty'] ?? null;

                if (is_null($model) || empty($model) ||
                    is_null($runno_awal) || empty($runno_awal) ||
                    is_null($runno_akhir) || empty($runno_akhir) ||
                    is_null($qty)) { // qty bisa 0 jika diizinkan, tapi biasanya > 0
                    throw new Exception("Missing or empty card details in one of the cards. Model: " . ($model ?? 'null') . ", Runno Awal: " . ($runno_awal ?? 'null') . ", Runno Akhir: " . ($runno_akhir ?? 'null') . ", Qty: " . ($qty ?? 'null'));
                }

                // Pastikan qty adalah integer
                $qty = (int) $qty;

                $stmt_insert_card = $conn->prepare("INSERT INTO tracking_card_details (tracking_entry_id, model, runno_awal, runno_akhir, qty) VALUES (?, ?, ?, ?, ?)");
                if (!$stmt_insert_card) {
                    throw new Exception("Prepare insert card statement failed: " . $conn->error);
                }
                $stmt_insert_card->bind_param("isssi", $tracking_entry_id, $model, $runno_awal, $runno_akhir, $qty);
                $stmt_insert_card->execute();
                $stmt_insert_card->close();
            }

            $conn->commit();
            $response['success'] = true;
            $response['message'] = 'Data tracking dan kartu berhasil disimpan.';
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
