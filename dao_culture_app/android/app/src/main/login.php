<?php
// Gọi chìa khóa mở Database
include 'db_config.php';

// Nhận tài khoản/mật khẩu từ App gửi lên
$username = $_POST['username'];
$password = $_POST['password'];

// Tìm xem có ai trong bảng users trùng khớp cả username và password không
$sql = "SELECT * FROM users WHERE username = '$username' AND password = '$password'";
$result = $conn->query($sql);

if ($result->num_rows > 0) {
    // Nếu tìm thấy: Lấy luôn thông tin người đó (tên, điểm XP, chức vụ...) gửi về cho App
    $user_data = $result->fetch_assoc();

    echo json_encode([
        "status" => "success",
        "message" => "Đăng nhập thành công!",
        "data" => $user_data
    ]);
} else {
    // Nếu không thấy: Báo sai mật khẩu hoặc tài khoản
    echo json_encode([
        "status" => "error",
        "message" => "Sai tên đăng nhập hoặc mật khẩu!"
    ]);
}

$conn->close();
?>