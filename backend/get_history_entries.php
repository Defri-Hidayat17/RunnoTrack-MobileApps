<?php
header('Content-Type: application/json');
include 'db_connect.php'; // Pastikan file koneksi database Anda ada

$response = array('success' => false, 'message' => 'An unknown error occurred.', 'data' => []);

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    $user_id = $_GET['user_id'] ?? null;
    $search_query = $_GET['query'] ?? '';

    if (is_null($user_id)) {
        $response['message'] = 'User ID is required.';
        echo json_encode($response);
        $conn->close();
        exit();
    }

    $user_id_int = (int)$user_id;

    try {
        $sql = "SELECT
                    te.id,
                    te.entry_date,
                    te.group_code,
                    te.checker_username,
                    te.total_target,
                    te.total_actual_qty,
                    te.difference,
                    te.efficiency_percentage,
                    te.is_confirmed,
                    te.created_at,
                    u.account_type AS user_account_type,
                    u.name AS user_name,
                    u.photo_url AS user_photo_url,
                    te.production_type,
                    c.phone_number AS checker_phone_number  -- 🔥 Tambahkan phone_number dari tabel checkers
                FROM
                    tracking_entries te
                JOIN
                    users u ON te.user_id = u.id
                LEFT JOIN
                    checkers c ON te.checker_username = c.checker_name AND te.group_code = c.group_code -- 🔥 JOIN dengan checkers
                WHERE te.user_id = ?";

        $params = [$user_id_int];
        $types = "i";

        if (!empty($search_query)) {
            $sql .= " AND (te.entry_date LIKE ? OR te.group_code LIKE ? OR te.checker_username LIKE ?)";
            $searchTerm = "%" . $search_query . "%";
            $params[] = $searchTerm;
            $params[] = $searchTerm;
            $params[] = $searchTerm;
            $types .= "sss";
        }

        $sql .= " ORDER BY te.entry_date DESC, te.id DESC";

        $stmt = $conn->prepare($sql);
        if (!$stmt) {
            throw new Exception("Prepare statement for main query failed: " . $conn->error);
        }

        if (!empty($params)) {
            $bind_names = [$types];
            for ($i = 0; $i < count($params); $i++) {
                $bind_name = 'bind' . $i;
                $$bind_name = $params[$i];
                $bind_names[] = &$$bind_name;
            }
            call_user_func_array([$stmt, 'bind_param'], $bind_names);
        }

        $stmt->execute();
        $result = $stmt->get_result();

        $history_entries = [];
        while ($entry_row = $result->fetch_assoc()) {
            $entry_row['total_target'] = (int)$entry_row['total_target'];
            $entry_row['total_actual_qty'] = (int)$entry_row['total_actual_qty'];
            $entry_row['difference'] = (int)$entry_row['difference'];
            $entry_row['efficiency_percentage'] = (float)$entry_row['efficiency_percentage'];
            
            // --- PERBAIKAN PENTING: Konversi is_confirmed ke boolean PHP ---
            $entry_row['is_confirmed'] = (bool)$entry_row['is_confirmed'];
            // --- AKHIR PERBAIKAN ---

            $entry_row['user_name'] = $entry_row['user_name'] ?? 'N/A';
            $entry_row['user_photo_url'] = $entry_row['user_photo_url'] ?? '';
            $entry_row['production_type'] = $entry_row['production_type'] ?? 'N/A';
            $entry_row['user_account_type'] = $entry_row['user_account_type'] ?? 'N/A';
            $entry_row['checker_phone_number'] = $entry_row['checker_phone_number'] ?? ''; // 🔥 Pastikan ada, default kosong jika null

            $history_entries[] = $entry_row;
        }

        $stmt->close();

        $response['success'] = true;
        $response['message'] = 'History entries fetched successfully.';
        $response['data'] = $history_entries;

    } catch (Exception $e) {
        $response['message'] = 'Error fetching history entries: ' . $e->getMessage();
    }
} else {
    $response['message'] = 'Invalid request method. Only GET is allowed.';
}

$conn->close();
echo json_encode($response);
?>
