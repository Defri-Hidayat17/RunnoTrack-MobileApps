<?php
header('Content-Type: application/json');
include 'db_connect.php'; // Pastikan path ini benar

$response = array();

// Terima data JSON dari request body
$data = json_decode(file_get_contents("php://input"), true);

if (isset($data['tracking_entry_id'])) {
    $tracking_entry_id = $data['tracking_entry_id'];

    // Siapkan statement SQL untuk update
    $stmt = $conn->prepare("UPDATE tracking_entries SET is_confirmed = 0 WHERE id = ?");
    $stmt->bind_param("i", $tracking_entry_id);

    if ($stmt->execute()) {
        if ($stmt->affected_rows > 0) {
            $response['success'] = true;
            $response['message'] = "Entry berhasil dibatalkan konfirmasi.";
        } else {
            $response['success'] = false;
            $response['message'] = "Tidak ada entri yang ditemukan dengan ID tersebut atau sudah tidak dikonfirmasi.";
        }
    } else {
        $response['success'] = false;
        $response['message'] = "Gagal mengeksekusi query: " . $stmt->error;
    }
    $stmt->close();
} else {
    $response['success'] = false;
    $response['message'] = "Parameter 'tracking_entry_id' tidak ditemukan.";
}

$conn->close();
echo json_encode($response);
?>
