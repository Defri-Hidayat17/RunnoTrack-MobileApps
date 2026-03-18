<?php
header('Content-Type: application/json');
include 'db_connect.php';

$response = array();
$data = array();

$result = $conn->query("SELECT group_code FROM groups ORDER BY group_code ASC");

if ($result->num_rows > 0) {
    while ($row = $result->fetch_assoc()) {
        $data[] = $row; // Mengembalikan array of objects
    }

    $response['success'] = true;
    $response['data'] = $data;
} else {
    $response['success'] = false;
    $response['message'] = "No groups found";
}

echo json_encode($response);

$conn->close();
?>
