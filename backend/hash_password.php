<?php
// hash_password.php - Ini hanya untuk mendapatkan hash password saat setup.
// JANGAN biarkan ini di server produksi atau diakses publik.
echo 'Hash for kp123: ' . password_hash('kp123', PASSWORD_DEFAULT) . '<br>';
echo 'Hash for xline123: ' . password_hash('xline123', PASSWORD_DEFAULT) . '<br>';
?>
