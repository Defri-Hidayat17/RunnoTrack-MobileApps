<?php
header('Content-Type: application/json');
include 'db_connect.php'; // Pastikan file koneksi database Anda ada

$response = array('success' => false, 'message' => 'An unknown error occurred.');

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $input = json_decode(file_get_contents('php://input'), true);

    $entry_date = $input['entry_date'] ?? null;
    $group_code = $input['group_code'] ?? null;
    $checker_username = $input['checker_username'] ?? null;

    if (is_null($entry_date) || is_null($group_code) || is_null($checker_username)) {
        $response['message'] = 'Missing required parameters: entry_date, group_code, or checker_username.';
        echo json_encode($response);
        $conn->close();
        exit();
    }

    try {
        // Update kolom is_confirmed menjadi 1 (true) untuk entri yang cocok
        $stmt = $conn->prepare("UPDATE tracking_entries SET is_confirmed = 1 WHERE entry_date = ? AND group_code = ? AND checker_username = ?");
        $stmt->bind_param("sss", $entry_date, $group_code, $checker_username);
        $stmt->execute();

        if ($stmt->affected_rows > 0) {
            $response['success'] = true;
            $response['message'] = 'Data confirmed successfully.';
        } else {
            // Jika tidak ada baris yang terpengaruh, mungkin tidak ada entri yang cocok atau sudah dikonfirmasi
            $response['message'] = 'No matching entry found or data already confirmed.';
        }
        $stmt->close();

    } catch (Exception $e) {
        $response['message'] = 'Error confirming data: ' . $e->getMessage();
    }
} else {
    $response['message'] = 'Invalid request method. Only POST is allowed.';
}

$conn->close();
echo json_encode($response);
?>
