<?php
header('Content-Type: application/json');
include 'db_connect.php'; // Pastikan ini mengarah ke file koneksi database Anda

// Tambahkan ini untuk mengaktifkan logging error PHP ke file
ini_set('display_errors', 'Off'); // Nonaktifkan tampilan error di output
ini_set('log_errors', 'On');     // Aktifkan logging error
ini_set('error_log', __DIR__ . '/php_error.log'); // Tentukan lokasi file log error
error_log("admin_dashboard.php: Script started."); // Log awal

$response = array();
$response['success'] = false;
$response['message'] = "Terjadi kesalahan yang tidak diketahui.";

// Function to hash password (tetap dibutuhkan untuk akun admin)
function hash_password($password) {
    return password_hash($password, PASSWORD_DEFAULT);
}

// Function to handle file upload
function upload_photo($file, $target_dir = "images/") {
    error_log("upload_photo: Attempting to upload file.");
    if (!isset($file) || $file['error'] != UPLOAD_ERR_OK) {
        error_log("upload_photo: No file uploaded or upload error. File error code: " . ($file['error'] ?? 'N/A'));
        return null; // No file uploaded or error
    }

    // Pastikan direktori target ada
    if (!is_dir($target_dir)) {
        error_log("upload_photo: Target directory '$target_dir' does not exist. Attempting to create.");
        if (!mkdir($target_dir, 0777, true)) { // Izin 0777 untuk debugging, ubah nanti
            error_log("upload_photo: Failed to create directory '$target_dir'. Check permissions.");
            return null;
        }
        error_log("upload_photo: Directory '$target_dir' created successfully.");
    }

    $file_name = uniqid() . "_" . basename($file["name"]);
    $target_file = $target_dir . $file_name;
    $imageFileType = strtolower(pathinfo($target_file, PATHINFO_EXTENSION));

    // Check if image file is a actual image or fake image
    $check = getimagesize($file["tmp_name"]);
    if ($check === false) {
        error_log("upload_photo: Uploaded file is not a valid image. Mime type check failed.");
        return null;
    }

    // Allow certain file formats
    if (!in_array($imageFileType, ["jpg", "png", "jpeg", "gif"])) {
        error_log("upload_photo: Invalid file type: '$imageFileType'. Allowed: jpg, png, jpeg, gif.");
        return null;
    }

    // Check file size (e.g., max 5MB)
    if ($file["size"] > 5000000) {
        error_log("upload_photo: File size too large: " . $file["size"] . " bytes. Max 5MB allowed.");
        return null;
    }

    if (move_uploaded_file($file["tmp_name"], $target_file)) {
        error_log("upload_photo: File uploaded successfully: '$file_name' to '$target_file'.");
        return $file_name; // Return just the filename
    } else {
        error_log("upload_photo: Failed to move uploaded file to '$target_file'. PHP error: " . (error_get_last()['message'] ?? 'Unknown error'));
        return null;
    }
}

// Function to delete old photo file
function delete_old_photo($filename, $target_dir = "images/") {
    error_log("delete_old_photo: Attempting to delete file: '$filename' from directory '$target_dir'.");
    if (!empty($filename) && file_exists($target_dir . $filename)) {
        if (unlink($target_dir . $filename)) {
            error_log("delete_old_photo: Successfully deleted file: '$filename'.");
            return true;
        } else {
            error_log("delete_old_photo: Failed to delete file: '$filename'. Check file permissions. PHP error: " . (error_get_last()['message'] ?? 'Unknown error'));
            return false;
        }
    } else {
        error_log("delete_old_photo: File not found or filename empty. Filename: '$filename'. Path checked: '$target_dir$filename'.");
        return false;
    }
}

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $form_type = $_POST['form_type'] ?? '';
    error_log("admin_dashboard.php: Received POST request with form_type: '$form_type'.");

    // Start transaction
    $conn->begin_transaction();

    try {
        switch ($form_type) {
            case 'add_pimpinan':
            case 'add_checker':
                error_log("admin_dashboard.php: Handling add_pimpinan/add_checker.");
                $name = $_POST['name'] ?? '';
                $phoneNumber = $_POST['phone_number'] ?? '';

                if (empty($name)) {
                    throw new Exception("Nama tidak boleh kosong.");
                }

                // Handle photo upload
                $photo_filename = upload_photo($_FILES['photo'] ?? null);
                error_log("admin_dashboard.php: Upload photo result: " . ($photo_filename ?? 'NULL'));

                if ($form_type == 'add_pimpinan') {
                    $department = $_POST['department'] ?? ''; // Untuk jabatan Pimpinan
                    $stmt_detail = $conn->prepare("INSERT INTO pimpinan_details (pimpinan_name, department, phone_number, photo_url) VALUES (?, ?, ?, ?)");
                    if (!$stmt_detail) {
                        throw new Exception("Prepare statement failed for pimpinan_details: " . $conn->error);
                    }
                    $stmt_detail->bind_param("ssss", $name, $department, $phoneNumber, $photo_filename);
                } else { // add_checker
                    $groupCode = $_POST['group_code'] ?? '';
                    $associatedAccountType = 'Operator'; // Pastikan ini 'Operator' sesuai dengan tabel users
                    $stmt_detail = $conn->prepare("INSERT INTO checkers (checker_name, group_code, associated_account_type, phone_number, photo_url) VALUES (?, ?, ?, ?, ?)");
                    if (!$stmt_detail) {
                        throw new Exception("Prepare statement failed for checkers: " . $conn->error);
                    }
                    $stmt_detail->bind_param("sssss", $name, $groupCode, $associatedAccountType, $phoneNumber, $photo_filename);
                }

                if (!$stmt_detail->execute()) {
                    throw new Exception("Gagal menambahkan detail member: " . $stmt_detail->error);
                }
                $stmt_detail->close();
                error_log("admin_dashboard.php: Member added successfully to database.");

                $response['success'] = true;
                $response['message'] = "Member berhasil ditambahkan.";
                break;

            case 'edit_pimpinan':
            case 'edit_checker':
                error_log("admin_dashboard.php: Handling edit_pimpinan/edit_checker.");
                $id = $_POST['id'] ?? '';
                $name = $_POST['name'] ?? '';
                $phoneNumber = $_POST['phone_number'] ?? '';
                $removePhoto = $_POST['remove_photo'] ?? '0';
                $currentPhotoFilename = $_POST['current_photo_filename'] ?? ''; // Ini seharusnya hanya nama file, bukan URL lengkap

                error_log("admin_dashboard.php: Edit request for ID: '$id', Name: '$name', Current Photo Filename: '$currentPhotoFilename', Remove Photo Flag: '$removePhoto'.");

                if (empty($id) || empty($name)) {
                    throw new Exception("ID dan Nama tidak boleh kosong.");
                }

                $new_photo_filename_for_db = $currentPhotoFilename; // Default: pertahankan nama file yang ada
                $photo_url_updated = false;

                if (isset($_FILES['photo']) && $_FILES['photo']['error'] == UPLOAD_ERR_OK) {
                    error_log("admin_dashboard.php: New photo file detected for upload.");
                    // Ada file foto baru diupload
                    delete_old_photo($currentPhotoFilename); // Hapus foto lama jika ada
                    $new_photo_filename_for_db = upload_photo($_FILES['photo']); // Upload foto baru
                    $photo_url_updated = true;
                    error_log("admin_dashboard.php: New photo uploaded. Filename for DB: " . ($new_photo_filename_for_db ?? 'NULL'));
                } elseif ($removePhoto == '1') {
                    error_log("admin_dashboard.php: Explicit request to remove photo.");
                    // Permintaan eksplisit untuk menghapus foto
                    delete_old_photo($currentPhotoFilename); // Hapus foto lama
                    $new_photo_filename_for_db = null; // Set photo_url ke NULL di DB
                    $photo_url_updated = true;
                    error_log("admin_dashboard.php: Photo removed. Filename for DB: NULL.");
                } else {
                    error_log("admin_dashboard.php: No new photo or remove request. Keeping existing photo filename.");
                }

                // Update pimpinan_details or checkers table
                $updateDetailSql = "";
                $detailParams = array();
                $detailParamTypes = "";

                if ($form_type == 'edit_pimpinan') {
                    $department = $_POST['department'] ?? '';
                    $updateDetailSql = "UPDATE pimpinan_details SET pimpinan_name = ?, department = ?, phone_number = ?";
                    $detailParamTypes = "sss";
                    $detailParams[] = $name;
                    $detailParams[] = $department;
                    $detailParams[] = $phoneNumber;
                } else { // edit_checker
                    $groupCode = $_POST['group_code'] ?? '';
                    $updateDetailSql = "UPDATE checkers SET checker_name = ?, group_code = ?, phone_number = ?";
                    $detailParamTypes = "sss";
                    $detailParams[] = $name;
                    $detailParams[] = $groupCode;
                    $detailParams[] = $phoneNumber;
                }

                // Tambahkan photo_url ke update jika ada perubahan terkait foto
                if ($photo_url_updated) {
                    $updateDetailSql .= ", photo_url = ?";
                    $detailParamTypes .= "s";
                    $detailParams[] = $new_photo_filename_for_db;
                    error_log("admin_dashboard.php: Photo URL will be updated in DB to: " . ($new_photo_filename_for_db ?? 'NULL'));
                }

                $updateDetailSql .= " WHERE id = ?";
                $detailParamTypes .= "i";
                $detailParams[] = $id;

                $stmt_detail = $conn->prepare($updateDetailSql);
                if (!$stmt_detail) {
                    throw new Exception("Prepare statement failed for detail update: " . $conn->error);
                }
                // Menggunakan refValues untuk bind_param
                call_user_func_array(array($stmt_detail, 'bind_param'), refValues(array_merge(array($detailParamTypes), $detailParams)));
                if (!$stmt_detail->execute()) {
                    throw new Exception("Gagal mengupdate detail member: " . $stmt_detail->error);
                }
                $stmt_detail->close();
                error_log("admin_dashboard.php: Member details updated successfully in database.");

                $response['success'] = true;
                $response['message'] = "Member berhasil diupdate.";
                break;

            case 'delete_pimpinan':
            case 'delete_checker':
                error_log("admin_dashboard.php: Handling delete_pimpinan/delete_checker.");
                $id = $_POST['id'] ?? '';

                if (empty($id)) {
                    throw new Exception("ID tidak boleh kosong untuk penghapusan.");
                }

                // Get photo_url before deleting from detail table
                $old_photo_filename = null;
                if ($form_type == 'delete_pimpinan') {
                    $stmt_get_photo = $conn->prepare("SELECT photo_url FROM pimpinan_details WHERE id = ?");
                } else {
                    $stmt_get_photo = $conn->prepare("SELECT photo_url FROM checkers WHERE id = ?");
                }
                if (!$stmt_get_photo) {
                    throw new Exception("Prepare statement failed to get photo_url: " . $conn->error);
                }
                $stmt_get_photo->bind_param("i", $id);
                $stmt_get_photo->execute();
                $stmt_get_photo->bind_result($old_photo_filename);
                $stmt_get_photo->fetch();
                $stmt_get_photo->close();
                error_log("admin_dashboard.php: Retrieved old photo filename for deletion: " . ($old_photo_filename ?? 'NULL'));


                // Delete from pimpinan_details or checkers table
                if ($form_type == 'delete_pimpinan') {
                    $stmt_detail = $conn->prepare("DELETE FROM pimpinan_details WHERE id = ?");
                } else { // delete_checker
                    $stmt_detail = $conn->prepare("DELETE FROM checkers WHERE id = ?");
                }
                if (!$stmt_detail) {
                    throw new Exception("Prepare statement failed for detail deletion: " . $conn->error);
                }
                $stmt_detail->bind_param("i", $id);
                if (!$stmt_detail->execute()) {
                    throw new Exception("Gagal menghapus detail member: " . $stmt_detail->error);
                }
                $stmt_detail->close();
                error_log("admin_dashboard.php: Member deleted from database.");

                // Delete photo file
                delete_old_photo($old_photo_filename);

                $response['success'] = true;
                $response['message'] = "Member berhasil dihapus.";
                break;

            case 'change_password': // Admin mengubah passwordnya sendiri
                error_log("admin_dashboard.php: Handling change_password (admin self-change).");
                $user_id = $_POST['user_id'] ?? '';
                $old_password = $_POST['old_password'] ?? '';
                $new_password = $_POST['new_password'] ?? '';

                if (empty($user_id) || empty($old_password) || empty($new_password)) {
                    throw new Exception('User ID, password lama, dan password baru tidak boleh kosong.');
                }

                $stmt = $conn->prepare("SELECT password FROM users WHERE id = ?");
                if (!$stmt) {
                    throw new Exception("Prepare statement failed for password verification: " . $conn->error);
                }
                $stmt->bind_param("i", $user_id);
                $stmt->execute();
                $result = $stmt->get_result();
                $user = $result->fetch_assoc();
                $stmt->close();

                if (!$user || !password_verify($old_password, $user['password'])) {
                    throw new Exception('Password lama salah.');
                }

                $hashed_new_password = hash_password($new_password);

                $stmt = $conn->prepare("UPDATE users SET password = ? WHERE id = ?");
                if (!$stmt) {
                    throw new Exception("Prepare statement failed for password update: " . $conn->error);
                }
                $stmt->bind_param("si", $hashed_new_password, $user_id);

                if (!$stmt->execute()) {
                    throw new Exception('Gagal mengubah password: ' . $stmt->error);
                }
                $stmt->close();
                error_log("admin_dashboard.php: Admin password changed successfully for user ID: '$user_id'.");

                $response['success'] = true;
                $response['message'] = 'Password berhasil diubah.';
                break;

            case 'admin_reset_password': // Admin mengganti password user lain (Pimpinan/Operator)
                error_log("admin_dashboard.php: Handling admin_reset_password.");
                $user_id_to_reset = $_POST['user_id'] ?? '';
                $new_password_for_reset = $_POST['new_password'] ?? '';

                if (empty($user_id_to_reset) || empty($new_password_for_reset)) {
                    throw new Exception('ID user dan password baru tidak boleh kosong.');
                }

                // Hash password baru
                $hashed_new_password_for_reset = hash_password($new_password_for_reset);

                // Update password di database
                $stmt = $conn->prepare("UPDATE users SET password = ? WHERE id = ?");
                if (!$stmt) {
                    throw new Exception("Prepare statement failed for admin password reset: " . $conn->error);
                }
                $stmt->bind_param("si", $hashed_new_password_for_reset, $user_id_to_reset);

                if (!$stmt->execute()) {
                    throw new Exception('Gagal mereset password: ' . $stmt->error);
                }
                $stmt->close();
                error_log("admin_dashboard.php: Password reset successfully for user ID: '$user_id_to_reset'.");

                $response['success'] = true;
                $response['message'] = 'Password user berhasil direset.';
                break;

            default:
                throw new Exception("Tipe form tidak valid.");
        }
        $conn->commit(); // Commit transaction
        error_log("admin_dashboard.php: Transaction committed successfully.");
    } catch (Exception $e) {
        $conn->rollback(); // Rollback transaction on error
        $response['message'] = $e->getMessage();
        error_log("admin_dashboard.php: PHP Exception caught: " . $e->getMessage() . " on line " . $e->getLine() . " in file " . $e->getFile());
    }
} else {
    $response['message'] = "Metode request tidak diizinkan.";
    error_log("admin_dashboard.php: Invalid request method.");
}

$conn->close();
echo json_encode($response);
error_log("admin_dashboard.php: Script finished.");

// Helper function for bind_param with call_user_func_array
function refValues($arr){
    if (strnatcmp(phpversion(),'5.3') >= 0) //Reference is required for PHP 5.3+
    {
        $refs = array();
        foreach($arr as $key => $value)
            $refs[$key] = &$arr[$key];
        return $refs;
    }
    return $arr;
}
?>
