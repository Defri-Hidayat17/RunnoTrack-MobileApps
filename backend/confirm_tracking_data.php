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
    $user_id = $input['user_id'] ?? null; // NEW: user_id is now required

    // Basic validation
    if (is_null($tracking_entry_id_param) && (is_null($entry_date) || empty($entry_date) ||
        is_null($group_code) || empty($group_code) ||
        is_null($checker_username) || empty($checker_username) ||
        is_null($user_id) || empty($user_id))) {
        $response['message'] = 'Missing required parameters for confirmation. Either tracking_entry_id OR entry_date, group_code, checker_username, and user_id are required.';
        echo json_encode($response);
        $conn->close();
        exit();
    }

    $conn->begin_transaction();

    try {
        $tracking_entry_id = null;
        $total_target = 0;
        $is_confirmed_db = 0;

        if ($tracking_entry_id_param !== null) {
            // If tracking_entry_id is provided, use it directly
            $stmt_get_entry = $conn->prepare("SELECT id, total_target, is_confirmed FROM tracking_entries WHERE id = ?");
            if (!$stmt_get_entry) {
                throw new Exception("Prepare statement failed: " . $conn->error);
            }
            $stmt_get_entry->bind_param("i", $tracking_entry_id_param);
        } else {
            // Otherwise, find by date, group, checker, and user_id
            $stmt_get_entry = $conn->prepare("SELECT id, total_target, is_confirmed FROM tracking_entries WHERE entry_date = ? AND group_code = ? AND checker_username = ? AND user_id = ?");
            if (!$stmt_get_entry) {
                throw new Exception("Prepare statement failed: " . $conn->error);
            }
            $stmt_get_entry->bind_param("ssss", $entry_date, $group_code, $checker_username, $user_id);
        }

        $stmt_get_entry->execute();
        $result_get_entry = $stmt_get_entry->get_result();
        $entry_data = $result_get_entry->fetch_assoc();
        $stmt_get_entry->close();

        if (!$entry_data) {
            throw new Exception("Tracking entry not found for confirmation.");
        }

        $tracking_entry_id = $entry_data['id'];
        $total_target = $entry_data['total_target'];
        $is_confirmed_db = $entry_data['is_confirmed'];

        // Pastikan entri belum dikonfirmasi sebelumnya (jika bukan re-konfirmasi dari unconfirm)
        // Jika status di DB sudah 1, dan kita tidak datang dari unconfirm (yang akan membuat is_confirmed_db jadi 0),
        // maka ini adalah upaya mengkonfirmasi ulang yang sudah dikonfirmasi.
        // Untuk saat ini, kita akan mengizinkan re-konfirmasi jika statusnya 0.
        // Jika Anda ingin mencegah re-konfirmasi total, Anda bisa menambahkan:
        // if ($is_confirmed_db == 1) { throw new Exception("Data sudah dikonfirmasi sebelumnya."); }


        // 2. Hitung total_actual_qty dari tracking_card_details yang terkait
        $stmt_calc_actual = $conn->prepare("SELECT SUM(qty) AS total_actual_sum FROM tracking_card_details WHERE tracking_entry_id = ?");
        if (!$stmt_calc_actual) {
            throw new Exception("Prepare statement for calculating actual qty failed: " . $conn->error);
        }
        $stmt_calc_actual->bind_param("i", $tracking_entry_id);
        $stmt_calc_actual->execute();
        $result_calc_actual = $stmt_calc_actual->get_result();
        $actual_data = $result_calc_actual->fetch_assoc();
        $stmt_calc_actual->close();

        $total_actual_qty = (int) ($actual_data['total_actual_sum'] ?? 0);

        // 3. Hitung difference dan efficiency_percentage
        $difference = $total_actual_qty - $total_target;
        $efficiency_percentage = ($total_target > 0) ? ($total_actual_qty / $total_target) * 100 : 0.00;

        // 4. Perbarui entri di tabel tracking_entries
        $stmt_update_entry = $conn->prepare("UPDATE tracking_entries SET
            is_confirmed = 1,
            total_actual_qty = ?,
            difference = ?,
            efficiency_percentage = ?
            WHERE id = ?");
        if (!$stmt_update_entry) {
            throw new Exception("Prepare statement for updating entry failed: " . $conn->error);
        }
        // Tipe parameter: i (total_actual_qty), i (difference), d (efficiency_percentage), i (id)
        $stmt_update_entry->bind_param("iidi", $total_actual_qty, $difference, $efficiency_percentage, $tracking_entry_id);
        $stmt_update_entry->execute();
        $stmt_update_entry->close();

        $conn->commit();
        $response['success'] = true;
        $response['message'] = 'Data berhasil dikonfirmasi dan ringkasan diperbarui.';

    } catch (Exception $e) {
        $conn->rollback();
        $response['message'] = 'Gagal konfirmasi data: ' . $e->getMessage();
    }
} else {
    $response['message'] = 'Invalid request method. Only POST is allowed.';
}

$conn->close();
echo json_encode($response);
?>
