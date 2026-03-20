<?php
header('Content-Type: application/json');
include 'db_connect.php'; // Pastikan file koneksi database Anda ada

$response = array('success' => false, 'message' => 'An unknown error occurred.');

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $input = json_decode(file_get_contents('php://input'), true);

    $card_detail_id = $input['card_detail_id'] ?? null; // Mengambil card_detail_id

    if (is_null($card_detail_id)) {
        $response['message'] = 'Missing required parameter: card_detail_id.';
        echo json_encode($response);
        $conn->close();
        exit();
    }

    $conn->begin_transaction();

    try {
        // Hapus kartu dari tracking_card_details berdasarkan ID unik
        $stmt = $conn->prepare("DELETE FROM tracking_card_details WHERE id = ?");
        if (!$stmt) {
            throw new Exception("Prepare statement failed: " . $conn->error);
        }
        $stmt->bind_param("i", $card_detail_id); // Bind sebagai integer
        $stmt->execute();

        if ($stmt->affected_rows > 0) {
            $conn->commit();
            $response['success'] = true;
            $response['message'] = 'Kartu berhasil dihapus.';
        } else {
            $conn->rollback();
            $response['message'] = 'Kartu tidak ditemukan atau tidak ada perubahan.';
        }
        $stmt->close();

    } catch (Exception $e) {
        $conn->rollback();
        $response['message'] = 'Error deleting card: ' . $e->getMessage();
    }
} else {
    $response['message'] = 'Invalid request method. Only POST is allowed.';
}

$conn->close();
echo json_encode($response);
?>
