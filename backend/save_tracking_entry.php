<?php
error_reporting(E_ALL); // Hapus atau set ke 0 di produksi
ini_set('display_errors', 1); // Hapus atau set ke 0 di produksi
header('Content-Type: application/json');
include 'db_connect.php';

$response = array('success' => false, 'message' => 'An unknown error occurred.');

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $input = json_decode(file_get_contents('php://input'), true);

    $entry_date = $input['entry_date'] ?? null;
    $group_code = $input['group_code'] ?? null;
    $checker_username = $input['checker_username'] ?? null;
    $total_target = $input['total_target'] ?? null;
    // 🔥 PENTING: Tambahkan user_id dari input POST
    $user_id = $input['user_id'] ?? null;

    // Basic validation
    if (is_null($entry_date) || empty($entry_date) ||
        is_null($group_code) || empty($group_code) ||
        is_null($checker_username) || empty($checker_username) ||
        is_null($total_target) || // total_target bisa 0, jadi tidak perlu empty()
        is_null($user_id) || empty($user_id)) { // 🔥 user_id juga wajib
        $response['message'] = 'Missing required parameters for tracking entry. Debug info: ' .
                               'entry_date=' . ($entry_date ?? 'null') .
                               ', group_code=' . ($group_code ?? 'null') .
                               ', checker_username=' . ($checker_username ?? 'null') .
                               ', total_target=' . ($total_target ?? 'null') .
                               ', user_id=' . ($user_id ?? 'null'); // 🔥 Tambahkan user_id ke debug info
        echo json_encode($response);
        $conn->close();
        exit();
    }

    $total_target = (int) $total_target;

    $conn->begin_transaction();

    try {
        // Check if tracking_entry already exists for this date, group, checker, AND user_id
        $stmt_check_entry = $conn->prepare("SELECT id FROM tracking_entries WHERE entry_date = ? AND group_code = ? AND checker_username = ? AND user_id = ?"); // 🔥 Tambahkan user_id
        if (!$stmt_check_entry) {
            throw new Exception("Prepare statement failed: " . $conn->error);
        }
        $stmt_check_entry->bind_param("ssss", $entry_date, $group_code, $checker_username, $user_id); // 🔥 "ssss" untuk 4 string
        $stmt_check_entry->execute();
        $result_check_entry = $stmt_check_entry->get_result();
        $tracking_entry_id = null;

        if ($result_check_entry->num_rows > 0) {
            // If exists, get its ID and update total_target
            $row = $result_check_entry->fetch_assoc();
            $tracking_entry_id = $row['id'];

            // Update total_target, pastikan hanya untuk entry milik user_id ini
            $stmt_update_target = $conn->prepare("UPDATE tracking_entries SET total_target = ? WHERE id = ? AND user_id = ?"); // 🔥 Tambahkan user_id ke WHERE
            if (!$stmt_update_target) {
                throw new Exception("Prepare update statement failed: " . $conn->error);
            }
            $stmt_update_target->bind_param("iis", $total_target, $tracking_entry_id, $user_id); // 🔥 "iis" untuk int, int, string
            $stmt_update_target->execute();
            $stmt_update_target->close();

            $response['message'] = 'Tracking entry updated successfully.';

        } else {
            // If not exists, create a new entry, including user_id
            $stmt_insert_entry = $conn->prepare("INSERT INTO tracking_entries (entry_date, group_code, checker_username, total_target, user_id) VALUES (?, ?, ?, ?, ?)"); // 🔥 Tambahkan user_id
            if (!$stmt_insert_entry) {
                throw new Exception("Prepare insert statement failed: " . $conn->error);
            }
            $stmt_insert_entry->bind_param("sssis", $entry_date, $group_code, $checker_username, $total_target, $user_id); // 🔥 "sssis" untuk 3 string, 1 int, 1 string
            $stmt_insert_entry->execute();
            $tracking_entry_id = $conn->insert_id;
            $stmt_insert_entry->close();

            $response['message'] = 'Tracking entry created successfully.';
        }
        $stmt_check_entry->close();

        if ($tracking_entry_id) {
            $conn->commit();
            $response['success'] = true;
            $response['tracking_entry_id'] = $tracking_entry_id;
        } else {
            throw new Exception("Failed to get or create tracking_entry_id.");
        }

    } catch (Exception $e) {
        $conn->rollback();
        $response['message'] = 'Error saving tracking entry: ' . $e->getMessage();
    }
} else {
    $response['message'] = 'Invalid request method. Only POST is allowed.';
}

$conn->close();
echo json_encode($response);
?>
