<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

$conn = new mysqli("localhost", "root", "", "dao_culture");

if ($conn->connect_error) {
    die(json_encode(["status" => "error", "message" => "Lỗi kết nối CSDL"]));
}

$user_id = $_POST['user_id'] ?? '';
$user_name = $conn->real_escape_string($_POST['user_name'] ?? 'Khách');
$content = $conn->real_escape_string($_POST['content'] ?? '');

if (!empty($content)) {
    // Lệnh cất dữ liệu vào bảng feedbacks
    $sql = "INSERT INTO feedbacks (user_id, user_name, content, created_at) 
            VALUES ('$user_id', '$user_name', '$content', NOW())";

    if ($conn->query($sql) === TRUE) {
        echo json_encode(["status" => "success"]);
    } else {
        echo json_encode(["status" => "error", "message" => $conn->error]);
    }
} else {
    echo json_encode(["status" => "error", "message" => "Nội dung rỗng"]);
}
$conn->close();
?>