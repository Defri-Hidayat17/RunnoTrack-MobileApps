<?php
header('Content-Type: application/json');
include 'db_connect.php'; // Pastikan path ini benar ke file koneksi database Anda

$input = json_decode(file_get_contents('php://input'), true);

$entry_date = $input['entry_date'] ?? '';
$group_code = $input['group_code'] ?? '';
$checker_username = $input['checker_username'] ?? '';
$model = $input['model'] ?? '';
$runno_awal = $input['runno_awal'] ?? '';
$runno_akhir = $input['runno_akhir'] ?? '';

if (empty($entry_date) || empty($group_code) || empty($checker_username) || empty($model) || empty($runno_awal) || empty($runno_akhir)) {
    echo json_encode(['success' => false, 'message' => 'Missing required parameters.']);
    exit();
}

// 1. Dapatkan ID dari tracking_entries
$stmt = $conn->prepare("SELECT id FROM tracking_entries WHERE entry_date = ? AND group_code = ? AND checker_username = ?");
if (!$stmt) {
    echo json_encode(['success' => false, 'message' => 'Prepare statement for tracking_entries failed: ' . $conn->error]);
    exit();
}
$stmt->bind_param("sss", $entry_date, $group_code, $checker_username);
$stmt->execute();
$result = $stmt->get_result();
$entry = $result->fetch_assoc();
$stmt->close();

if (!$entry) {
    echo json_encode(['success' => false, 'message' => 'Tracking entry not found for deletion.']);
    exit();
}

$tracking_entry_id = $entry['id']; // Mengambil 'id' dari tracking_entries

// 2. Hapus kartu spesifik dari tracking_card_details
$stmt = $conn->prepare("DELETE FROM tracking_card_details WHERE tracking_entry_id = ? AND model = ? AND runno_awal = ? AND runno_akhir = ?");
if (!$stmt) {
    echo json_encode(['success' => false, 'message' => 'Prepare statement for tracking_card_details delete failed: ' . $conn->error]);
    exit();
}
$stmt->bind_param("isss", $tracking_entry_id, $model, $runno_awal, $runno_akhir);

if ($stmt->execute()) {
    if ($stmt->affected_rows > 0) {
        // HANYA HAPUS KARTU. TIDAK PERLU UPDATE total_actual DI tracking_entries DARI SINI
        // Karena Flutter akan menghitung ulang total_actual setelah fetch data baru.
        echo json_encode(['success' => true, 'message' => 'Card deleted successfully.']);
    } else {
        echo json_encode(['success' => false, 'message' => 'Card not found or already deleted.']);
    }
} else {
    echo json_encode(['success' => false, 'message' => 'Failed to delete card: ' . $stmt->error]);
}

$conn->close();
?>
