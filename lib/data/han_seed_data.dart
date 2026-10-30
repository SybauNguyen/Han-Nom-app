import 'dart:math';

import 'han_character.dart';
import 'question.dart';

/// Tắt dữ liệu Nôm hiện tại trong app cho đến khi bộ chữ được chuẩn hóa.
/// Khi có bộ dữ liệu chuẩn, bổ sung lại seed + unit ký tự rồi bật cờ này.
bool isNomDataEnabled = false;

const List<HanCharacter> seedCharacters = [
  HanCharacter(character: '一', hanVietReading: 'nhất', meaning: 'một', radical: '一', structure: 'Đơn thể', difficulty: 1, examples: ['Nhất định', 'Thống nhất']),
  HanCharacter(character: '二', hanVietReading: 'nhị', meaning: 'hai', radical: '二', structure: 'Đơn thể', difficulty: 1, examples: ['Nhị phân', 'Nhịp']),
  HanCharacter(character: '三', hanVietReading: 'tam', meaning: 'ba', radical: '一', structure: 'Đơn thể', difficulty: 1, examples: ['Tam giác', 'Tam quan']),
  HanCharacter(character: '人', hanVietReading: 'nhân', meaning: 'người', radical: '人', structure: 'Đơn thể', difficulty: 1, examples: ['Nhân loại', 'Nhân dân']),
  HanCharacter(character: '大', hanVietReading: 'đại', meaning: 'to lớn', radical: '大', structure: 'Đơn thể', difficulty: 1, examples: ['Đại học', 'Vĩ đại']),
  HanCharacter(character: '小', hanVietReading: 'tiểu', meaning: 'nhỏ bé', radical: '小', structure: 'Đơn thể', difficulty: 1, examples: ['Tiểu học', 'Tiểu đội']),
  HanCharacter(character: '中', hanVietReading: 'trung', meaning: 'ở giữa, bên trong', radical: '丨', structure: 'Đơn thể', difficulty: 1, examples: ['Trung tâm', 'Trung gian']),
  HanCharacter(character: '日', hanVietReading: 'nhật', meaning: 'mặt trời, ngày', radical: '日', structure: 'Đơn thể', difficulty: 1, examples: ['Nhật ký', 'Nhật nguyệt']),
  HanCharacter(character: '月', hanVietReading: 'nguyệt', meaning: 'mặt trăng, tháng', radical: '月', structure: 'Đơn thể', difficulty: 1, examples: ['Nguyệt thực', 'Nhật nguyệt']),
  HanCharacter(character: '山', hanVietReading: 'sơn', meaning: 'núi', radical: '山', structure: 'Đơn thể', difficulty: 2, examples: ['Sơn hà', 'Sơn thủy']),
  HanCharacter(character: '水', hanVietReading: 'thủy', meaning: 'nước', radical: '水', structure: 'Đơn thể', difficulty: 2, examples: ['Thủy điện', 'Thủy ngân']),
  HanCharacter(character: '木', hanVietReading: 'mộc', meaning: 'cây, gỗ', radical: '木', structure: 'Đơn thể', difficulty: 2, examples: ['Thảo mộc', 'Mộc bản']),
  HanCharacter(character: '火', hanVietReading: 'hỏa', meaning: 'lửa', radical: '火', structure: 'Đơn thể', difficulty: 2, examples: ['Hỏa lực', 'Hỏa hoạn']),
  HanCharacter(character: '心', hanVietReading: 'tâm', meaning: 'trái tim, tâm trí', radical: '心', structure: 'Đơn thể', difficulty: 2, examples: ['Tâm lý', 'Tâm hồn']),
  HanCharacter(character: '學', hanVietReading: 'học', meaning: 'học tập', radical: '子', structure: 'Trên dưới', difficulty: 3, examples: ['Học sinh 學生', 'Đại học 大學']),
  HanCharacter(character: '生', hanVietReading: 'sinh', meaning: 'sinh ra, sống', radical: '生', structure: 'Đơn thể', difficulty: 3, examples: ['Sinh viên', 'Sinh nhật']),
  HanCharacter(character: '忠', hanVietReading: 'trung', meaning: 'trung thành', radical: '心', structure: 'Trên dưới: 中 + 心', difficulty: 3, examples: ['Trung thành 忠誠', 'Trung thần 忠臣']),
  HanCharacter(character: '休', hanVietReading: 'hưu', meaning: 'nghỉ ngơi', radical: '亻', structure: 'Trái phải: 亻 + 木', difficulty: 3, examples: ['Hưu trí', 'Hưu chiến'], mnemonic: 'Gồm Nhân đứng 亻 và Mộc 木: hình dung một người tựa vào gốc cây để nghỉ ngơi.'),
  HanCharacter(character: '明', hanVietReading: 'minh', meaning: 'sáng, rõ', radical: '日', structure: 'Trái phải: 日 + 月', difficulty: 3, examples: ['Thông minh', 'Văn minh'], mnemonic: 'Nhật 日 là mặt trời, Nguyệt 月 là mặt trăng; ghép lại gợi hình ảnh sáng rõ.'),
  HanCharacter(character: '林', hanVietReading: 'lâm', meaning: 'rừng', radical: '木', structure: 'Trái phải: 木 + 木', difficulty: 3, examples: ['Lâm nghiệp', 'Sơn lâm'], mnemonic: 'Hai chữ Mộc 木 đứng cạnh nhau, gợi một khu rừng thưa.'),
  HanCharacter(character: '好', hanVietReading: 'hảo', meaning: 'tốt, đẹp', radical: '女', structure: 'Trái phải: 女 + 子', difficulty: 3, examples: ['Hảo hán', 'Hảo ý'], mnemonic: 'Gồm Nữ 女 và Tử 子; liên tưởng đến hình ảnh người mẹ ôm con, điều tốt đẹp.'),
  HanCharacter(character: '語', hanVietReading: 'ngữ', meaning: 'lời nói, ngôn ngữ', radical: '言', structure: 'Trái phải', difficulty: 3, examples: ['Ngôn ngữ', 'Thành ngữ']),
  HanCharacter(character: '國', hanVietReading: 'quốc', meaning: 'nước, quốc gia', radical: '囗', structure: 'Bao quanh', difficulty: 3, examples: ['Quốc gia', 'Tổ quốc'], mnemonic: 'Khung 囗 bao quanh phần bên trong, gợi một vùng lãnh thổ có ranh giới.'),
  HanCharacter(character: '愛', hanVietReading: 'ái', meaning: 'yêu thương', radical: '心', structure: 'Trên dưới', difficulty: 3, examples: ['Ái quốc', 'Bác ái']),
  HanCharacter(character: '家', hanVietReading: 'gia', meaning: 'nhà, gia đình', radical: '宀', structure: 'Trên dưới', difficulty: 3, examples: ['Gia đình', 'Quốc gia']),

  // --- BO SUNG: SO DEM ---
  HanCharacter(character: '四', hanVietReading: 'tứ', meaning: 'bốn', radical: '囗', structure: 'Chưa bổ sung', difficulty: 1),
  HanCharacter(character: '五', hanVietReading: 'ngũ', meaning: 'năm', radical: '二', structure: 'Chưa bổ sung', difficulty: 1),
  HanCharacter(character: '六', hanVietReading: 'lục', meaning: 'sáu', radical: '八', structure: 'Chưa bổ sung', difficulty: 1),
  HanCharacter(character: '七', hanVietReading: 'thất', meaning: 'bảy', radical: '一', structure: 'Chưa bổ sung', difficulty: 1),
  HanCharacter(character: '八', hanVietReading: 'bát', meaning: 'tám', radical: '八', structure: 'Chưa bổ sung', difficulty: 1),
  HanCharacter(character: '九', hanVietReading: 'cửu', meaning: 'chín', radical: '乙', structure: 'Chưa bổ sung', difficulty: 1),
  HanCharacter(character: '十', hanVietReading: 'thập', meaning: 'mười', radical: '十', structure: 'Chưa bổ sung', difficulty: 1),
  HanCharacter(character: '百', hanVietReading: 'bách', meaning: 'trăm', radical: '白', structure: 'Chưa bổ sung', difficulty: 2),
  HanCharacter(character: '千', hanVietReading: 'thiên', meaning: 'nghìn', radical: '十', structure: 'Chưa bổ sung', difficulty: 2),
  HanCharacter(character: '萬', hanVietReading: 'vạn', meaning: 'mười nghìn', radical: '艸', structure: 'Chưa bổ sung', difficulty: 3),

  // --- PHUONG HUONG VA VI TRI ---
  HanCharacter(character: '東', hanVietReading: 'đông', meaning: 'phía đông', radical: '木', structure: 'Chưa bổ sung', difficulty: 2),
  HanCharacter(character: '西', hanVietReading: 'tây', meaning: 'phía tây', radical: '襾', structure: 'Chưa bổ sung', difficulty: 2),
  HanCharacter(character: '南', hanVietReading: 'nam', meaning: 'phía nam', radical: '十', structure: 'Chưa bổ sung', difficulty: 2),
  HanCharacter(character: '北', hanVietReading: 'bắc', meaning: 'phía bắc', radical: '匕', structure: 'Chưa bổ sung', difficulty: 2),
  HanCharacter(character: '左', hanVietReading: 'tả', meaning: 'bên trái', radical: '工', structure: 'Chưa bổ sung', difficulty: 2),
  HanCharacter(character: '右', hanVietReading: 'hữu', meaning: 'bên phải', radical: '口', structure: 'Chưa bổ sung', difficulty: 2),
  HanCharacter(character: '前', hanVietReading: 'tiền', meaning: 'phía trước', radical: '刀', structure: 'Chưa bổ sung', difficulty: 2),
  HanCharacter(character: '後', hanVietReading: 'hậu', meaning: 'phía sau', radical: '彳', structure: 'Chưa bổ sung', difficulty: 3),
  HanCharacter(character: '上', hanVietReading: 'thượng', meaning: 'bên trên', radical: '一', structure: 'Chưa bổ sung', difficulty: 1),
  HanCharacter(character: '下', hanVietReading: 'hạ', meaning: 'bên dưới', radical: '一', structure: 'Chưa bổ sung', difficulty: 1),
  HanCharacter(character: '內', hanVietReading: 'nội', meaning: 'bên trong', radical: '入', structure: 'Chưa bổ sung', difficulty: 2),
  HanCharacter(character: '外', hanVietReading: 'ngoại', meaning: 'bên ngoài', radical: '夕', structure: 'Chưa bổ sung', difficulty: 2),

  // --- TU NHIEN ---
  HanCharacter(character: '天', hanVietReading: 'thiên', meaning: 'trời', radical: '大', structure: 'Chưa bổ sung', difficulty: 1),
  HanCharacter(character: '地', hanVietReading: 'địa', meaning: 'đất', radical: '土', structure: 'Chưa bổ sung', difficulty: 2),
  HanCharacter(character: '風', hanVietReading: 'phong', meaning: 'gió', radical: '風', structure: 'Chưa bổ sung', difficulty: 3),
  HanCharacter(character: '雨', hanVietReading: 'vũ', meaning: 'mưa', radical: '雨', structure: 'Chưa bổ sung', difficulty: 2),
  HanCharacter(character: '雲', hanVietReading: 'vân', meaning: 'mây', radical: '雨', structure: 'Chưa bổ sung', difficulty: 3),
  HanCharacter(character: '雪', hanVietReading: 'tuyết', meaning: 'tuyết', radical: '雨', structure: 'Chưa bổ sung', difficulty: 3),
  HanCharacter(character: '電', hanVietReading: 'điện', meaning: 'điện, sấm chớp', radical: '雨', structure: 'Chưa bổ sung', difficulty: 3),
  HanCharacter(character: '星', hanVietReading: 'tinh', meaning: 'ngôi sao', radical: '日', structure: 'Chưa bổ sung', difficulty: 2),
  HanCharacter(character: '草', hanVietReading: 'thảo', meaning: 'cỏ', radical: '艸', structure: 'Chưa bổ sung', difficulty: 2),
  HanCharacter(character: '花', hanVietReading: 'hoa', meaning: 'bông hoa', radical: '艸', structure: 'Chưa bổ sung', difficulty: 2),

  // --- GIA DINH VA CON NGUOI ---
  HanCharacter(character: '男', hanVietReading: 'nam', meaning: 'đàn ông, con trai', radical: '田', structure: 'Chưa bổ sung', difficulty: 2),
  HanCharacter(character: '女', hanVietReading: 'nữ', meaning: 'phụ nữ, con gái', radical: '女', structure: 'Chưa bổ sung', difficulty: 1),
  HanCharacter(character: '父', hanVietReading: 'phụ', meaning: 'cha, bố', radical: '父', structure: 'Chưa bổ sung', difficulty: 2),
  HanCharacter(character: '母', hanVietReading: 'mẫu', meaning: 'mẹ', radical: '毋', structure: 'Chưa bổ sung', difficulty: 2),
  HanCharacter(character: '子', hanVietReading: 'tử', meaning: 'con cái', radical: '子', structure: 'Chưa bổ sung', difficulty: 1),
  HanCharacter(character: '兄', hanVietReading: 'huynh', meaning: 'anh trai', radical: '儿', structure: 'Chưa bổ sung', difficulty: 2),
  HanCharacter(character: '弟', hanVietReading: 'đệ', meaning: 'em trai', radical: '弓', structure: 'Chưa bổ sung', difficulty: 2),

  // --- BO PHAN CO THE ---
  HanCharacter(character: '目', hanVietReading: 'mục', meaning: 'con mắt', radical: '目', structure: 'Chưa bổ sung', difficulty: 1),
  HanCharacter(character: '耳', hanVietReading: 'nhĩ', meaning: 'lỗ tai', radical: '耳', structure: 'Chưa bổ sung', difficulty: 2),
  HanCharacter(character: '口', hanVietReading: 'khẩu', meaning: 'cái miệng', radical: '口', structure: 'Chưa bổ sung', difficulty: 1),
  HanCharacter(character: '手', hanVietReading: 'thủ', meaning: 'bàn tay', radical: '手', structure: 'Chưa bổ sung', difficulty: 1),
  HanCharacter(character: '足', hanVietReading: 'túc', meaning: 'cái chân', radical: '足', structure: 'Chưa bổ sung', difficulty: 2),
  HanCharacter(character: '頭', hanVietReading: 'đầu', meaning: 'cái đầu', radical: '頁', structure: 'Chưa bổ sung', difficulty: 3),

  // --- DONG TU VA TINH TU ---
  HanCharacter(character: '來', hanVietReading: 'lai', meaning: 'đến, lại', radical: '人', structure: 'Chưa bổ sung', difficulty: 2),
  HanCharacter(character: '去', hanVietReading: 'khứ', meaning: 'đi', radical: '厶', structure: 'Chưa bổ sung', difficulty: 2),
  HanCharacter(character: '出', hanVietReading: 'xuất', meaning: 'đi ra', radical: '凵', structure: 'Chưa bổ sung', difficulty: 1),
  HanCharacter(character: '入', hanVietReading: 'nhập', meaning: 'đi vào', radical: '入', structure: 'Chưa bổ sung', difficulty: 1),
  HanCharacter(character: '多', hanVietReading: 'đa', meaning: 'nhiều', radical: '夕', structure: 'Chưa bổ sung', difficulty: 1),
  HanCharacter(character: '少', hanVietReading: 'thiểu', meaning: 'ít', radical: '小', structure: 'Chưa bổ sung', difficulty: 1),
  HanCharacter(character: '新', hanVietReading: 'tân', meaning: 'mới', radical: '斤', structure: 'Chưa bổ sung', difficulty: 3),
  HanCharacter(character: '古', hanVietReading: 'cổ', meaning: 'cũ, xưa', radical: '口', structure: 'Chưa bổ sung', difficulty: 2),
  HanCharacter(character: '白', hanVietReading: 'bạch', meaning: 'màu trắng', radical: '白', structure: 'Chưa bổ sung', difficulty: 1),
  HanCharacter(character: '黑', hanVietReading: 'hắc', meaning: 'màu đen', radical: '黑', structure: 'Chưa bổ sung', difficulty: 3),


  // --- DONG VAT ---
  HanCharacter(character: '犬', hanVietReading: 'khuyển', meaning: 'con chó', radical: '犬', structure: 'Đơn thể', difficulty: 2),
  HanCharacter(character: '貓', hanVietReading: 'miêu', meaning: 'con mèo', radical: '豸', structure: 'Trái phải', difficulty: 3),
  HanCharacter(character: '馬', hanVietReading: 'mã', meaning: 'con ngựa', radical: '馬', structure: 'Đơn thể', difficulty: 2),
  HanCharacter(character: '牛', hanVietReading: 'ngưu', meaning: 'con trâu, con bò', radical: '牛', structure: 'Đơn thể', difficulty: 2),
  HanCharacter(character: '羊', hanVietReading: 'dương', meaning: 'con dê, cừu', radical: '羊', structure: 'Đơn thể', difficulty: 2),
  HanCharacter(character: '鳥', hanVietReading: 'điểu', meaning: 'con chim', radical: '鳥', structure: 'Đơn thể', difficulty: 3),
  HanCharacter(character: '魚', hanVietReading: 'ngư', meaning: 'con cá', radical: '魚', structure: 'Đơn thể', difficulty: 3),
  HanCharacter(character: '蟲', hanVietReading: 'trùng', meaning: 'côn trùng', radical: '虫', structure: 'Đơn thể', difficulty: 3),
  HanCharacter(character: '龍', hanVietReading: 'long', meaning: 'con rồng', radical: '龍', structure: 'Đơn thể', difficulty: 3),

  // --- MAU SAC: 日/月 da co trong bo du lieu nen khong tao ban ghi trung ---
  HanCharacter(character: '青', hanVietReading: 'thanh', meaning: 'màu xanh', radical: '青', structure: 'Đơn thể', difficulty: 2),
  HanCharacter(character: '黃', hanVietReading: 'hoàng', meaning: 'màu vàng', radical: '黃', structure: 'Đơn thể', difficulty: 2),
  HanCharacter(character: '赤', hanVietReading: 'xích', meaning: 'màu đỏ', radical: '赤', structure: 'Đơn thể', difficulty: 2),
  HanCharacter(character: '綠', hanVietReading: 'lục', meaning: 'màu xanh lá', radical: '糸', structure: 'Trái phải', difficulty: 3),
  HanCharacter(character: '藍', hanVietReading: 'lam', meaning: 'màu xanh lam', radical: '艸', structure: 'Trên dưới', difficulty: 3),
  HanCharacter(character: '紫', hanVietReading: 'tử', meaning: 'màu tím', radical: '糸', structure: 'Trên dưới', difficulty: 3),

  // --- HANH DONG CO BAN ---
  HanCharacter(character: '走', hanVietReading: 'tẩu', meaning: 'chạy, đi bộ', radical: '走', structure: 'Đơn thể', difficulty: 2),
  HanCharacter(character: '飛', hanVietReading: 'phi', meaning: 'bay', radical: '飛', structure: 'Đơn thể', difficulty: 2),
  HanCharacter(character: '游', hanVietReading: 'du', meaning: 'bơi lội, đi chơi', radical: '水', structure: 'Trái phải', difficulty: 3),
  HanCharacter(character: '看', hanVietReading: 'khán', meaning: 'nhìn, xem', radical: '目', structure: 'Trên dưới: 手 + 目', difficulty: 2, mnemonic: 'Có thể nhớ như bàn tay 手 đặt trên mắt 目 để che nắng, nhìn cho rõ.'),
  HanCharacter(character: '聽', hanVietReading: 'thính', meaning: 'nghe', radical: '耳', structure: 'Trái phải', difficulty: 3),
  HanCharacter(character: '說', hanVietReading: 'thuyết', meaning: 'nói', radical: '言', structure: 'Trái phải', difficulty: 2),
  HanCharacter(character: '讀', hanVietReading: 'độc', meaning: 'đọc', radical: '言', structure: 'Trái phải', difficulty: 3),
  HanCharacter(character: '寫', hanVietReading: 'tả', meaning: 'viết', radical: '宀', structure: 'Trên dưới', difficulty: 3),
  HanCharacter(character: '食', hanVietReading: 'thực', meaning: 'ăn, thức ăn', radical: '食', structure: 'Đơn thể', difficulty: 2),
  HanCharacter(character: '飲', hanVietReading: 'ẩm', meaning: 'uống', radical: '食', structure: 'Trái phải', difficulty: 3),

  // --- CAM XUC VA TRANG THAI; 愛 da co san ---
  HanCharacter(character: '恨', hanVietReading: 'hận', meaning: 'ghét, hận', radical: '心', structure: 'Trái phải', difficulty: 3),
  HanCharacter(character: '喜', hanVietReading: 'hỷ', meaning: 'vui vẻ', radical: '口', structure: 'Trên dưới', difficulty: 3),
  HanCharacter(character: '怒', hanVietReading: 'nộ', meaning: 'tức giận', radical: '心', structure: 'Trên dưới', difficulty: 3),
  HanCharacter(character: '哀', hanVietReading: 'ai', meaning: 'đau buồn', radical: '口', structure: 'Trên dưới', difficulty: 3),
  HanCharacter(character: '樂', hanVietReading: 'lạc', meaning: 'vui thú, âm nhạc', radical: '木', structure: 'Trên dưới', difficulty: 3),
  HanCharacter(character: '苦', hanVietReading: 'khổ', meaning: 'đắng, khổ cực', radical: '艸', structure: 'Trên dưới', difficulty: 2),
  HanCharacter(character: '甜', hanVietReading: 'điềm', meaning: 'ngọt', radical: '甘', structure: 'Trái phải', difficulty: 3),

  // --- THOI GIAN; 日 va 月 da co san ---
  HanCharacter(character: '年', hanVietReading: 'niên', meaning: 'năm', radical: '干', structure: 'Đơn thể', difficulty: 1),
  HanCharacter(character: '時', hanVietReading: 'thời', meaning: 'thời gian, giờ', radical: '日', structure: 'Trái phải', difficulty: 2),
  HanCharacter(character: '分', hanVietReading: 'phân', meaning: 'phút, chia ra', radical: '刀', structure: 'Trên dưới', difficulty: 2),
  HanCharacter(character: '秒', hanVietReading: 'miểu', meaning: 'giây', radical: '禾', structure: 'Trái phải', difficulty: 3),
  HanCharacter(character: '今', hanVietReading: 'kim', meaning: 'hiện tại, nay', radical: '人', structure: 'Trên dưới', difficulty: 1),
  HanCharacter(character: '昔', hanVietReading: 'tích', meaning: 'ngày xưa', radical: '日', structure: 'Trên dưới', difficulty: 3),

  // --- DO VAT GAN GUI: them de mo rong nhom bo thu ---
  HanCharacter(character: '門', hanVietReading: 'môn', meaning: 'cửa', radical: '門', structure: 'Bao quanh', difficulty: 2),
  HanCharacter(character: '車', hanVietReading: 'xa', meaning: 'xe cộ', radical: '車', structure: 'Đơn thể', difficulty: 2),
  HanCharacter(character: '金', hanVietReading: 'kim', meaning: 'vàng, kim loại', radical: '金', structure: 'Đơn thể', difficulty: 2),
  HanCharacter(character: '石', hanVietReading: 'thạch', meaning: 'đá', radical: '石', structure: 'Trên dưới', difficulty: 1),
  HanCharacter(character: '田', hanVietReading: 'điền', meaning: 'ruộng', radical: '田', structure: 'Đơn thể', difficulty: 1),
  HanCharacter(character: '竹', hanVietReading: 'trúc', meaning: 'tre', radical: '竹', structure: 'Đơn thể', difficulty: 2),
  HanCharacter(character: '米', hanVietReading: 'mễ', meaning: 'gạo', radical: '米', structure: 'Đơn thể', difficulty: 2),


  // --- BO SUNG 125 HAN TU: MUA, THIEN NHIEN, CO THE, HANH DONG, XA HOI ---
  HanCharacter(character: '春', hanVietReading: 'xuân', meaning: 'mùa xuân', radical: '日', structure: 'Trên dưới', difficulty: 2),
  HanCharacter(character: '夏', hanVietReading: 'hạ', meaning: 'mùa hè', radical: '夂', structure: 'Trên dưới', difficulty: 2),
  HanCharacter(character: '秋', hanVietReading: 'thu', meaning: 'mùa thu', radical: '禾', structure: 'Trái phải', difficulty: 2),
  HanCharacter(character: '冬', hanVietReading: 'đông', meaning: 'mùa đông', radical: '冫', structure: 'Trên dưới', difficulty: 2),
  HanCharacter(character: '朝', hanVietReading: 'triêu', meaning: 'buổi sáng', radical: '月', structure: 'Trái phải', difficulty: 3),
  HanCharacter(character: '夕', hanVietReading: 'tịch', meaning: 'buổi chiều tối', radical: '夕', structure: 'Đơn thể', difficulty: 2),
  HanCharacter(character: '夜', hanVietReading: 'dạ', meaning: 'ban đêm', radical: '夕', structure: 'Trên dưới', difficulty: 2),
  HanCharacter(character: '江', hanVietReading: 'giang', meaning: 'sông lớn', radical: '水', structure: 'Trái phải', difficulty: 2, mnemonic: 'Bộ Thủy 氵 và chữ Công 工; liên tưởng dòng nước chảy không ngừng thành sông lớn.'),
  HanCharacter(character: '河', hanVietReading: 'hà', meaning: 'sông', radical: '水', structure: 'Trái phải', difficulty: 2),
  HanCharacter(character: '海', hanVietReading: 'hải', meaning: 'biển', radical: '水', structure: 'Trái phải', difficulty: 2),
  HanCharacter(character: '湖', hanVietReading: 'hồ', meaning: 'cái hồ', radical: '水', structure: 'Trái phải', difficulty: 2),
  HanCharacter(character: '土', hanVietReading: 'thổ', meaning: 'đất đai', radical: '土', structure: 'Đơn thể', difficulty: 1),
  HanCharacter(character: '氣', hanVietReading: 'khí', meaning: 'không khí, hơi thở', radical: '气', structure: 'Trên dưới', difficulty: 2),
  HanCharacter(character: '空', hanVietReading: 'không', meaning: 'bầu trời, trống rỗng', radical: '穴', structure: 'Trên dưới', difficulty: 2),
  HanCharacter(character: '光', hanVietReading: 'quang', meaning: 'ánh sáng', radical: '儿', structure: 'Trên dưới', difficulty: 2),
  HanCharacter(character: '暗', hanVietReading: 'ám', meaning: 'tối tăm', radical: '日', structure: 'Trái phải', difficulty: 3),
  HanCharacter(character: '銀', hanVietReading: 'ngân', meaning: 'bạc', radical: '金', structure: 'Trái phải', difficulty: 2),
  HanCharacter(character: '鐵', hanVietReading: 'thiết', meaning: 'sắt', radical: '金', structure: 'Trái phải', difficulty: 3),
  HanCharacter(character: '血', hanVietReading: 'huyết', meaning: 'máu', radical: '血', structure: 'Đơn thể', difficulty: 2),
  HanCharacter(character: '肉', hanVietReading: 'nhục', meaning: 'thịt', radical: '肉', structure: 'Đơn thể', difficulty: 2),
  HanCharacter(character: '骨', hanVietReading: 'cốt', meaning: 'xương', radical: '骨', structure: 'Trên dưới', difficulty: 2),
  HanCharacter(character: '皮', hanVietReading: 'bì', meaning: 'da', radical: '皮', structure: 'Đơn thể', difficulty: 2),
  HanCharacter(character: '毛', hanVietReading: 'mao', meaning: 'lông, tóc', radical: '毛', structure: 'Đơn thể', difficulty: 1),
  HanCharacter(character: '肝', hanVietReading: 'can', meaning: 'gan', radical: '肉', structure: 'Trái phải', difficulty: 2),
  HanCharacter(character: '肺', hanVietReading: 'phế', meaning: 'phổi', radical: '肉', structure: 'Trái phải', difficulty: 2),
  HanCharacter(character: '胃', hanVietReading: 'vị', meaning: 'dạ dày', radical: '肉', structure: 'Trên dưới', difficulty: 2),
  HanCharacter(character: '腸', hanVietReading: 'tràng', meaning: 'ruột', radical: '肉', structure: 'Trái phải', difficulty: 3),
  HanCharacter(character: '面', hanVietReading: 'diện', meaning: 'khuôn mặt, bề mặt', radical: '面', structure: 'Đơn thể', difficulty: 2),
  HanCharacter(character: '齒', hanVietReading: 'xỉ', meaning: 'răng', radical: '齒', structure: 'Đơn thể', difficulty: 3),
  HanCharacter(character: '立', hanVietReading: 'lập', meaning: 'đứng', radical: '立', structure: 'Đơn thể', difficulty: 1),
  HanCharacter(character: '坐', hanVietReading: 'tọa', meaning: 'ngồi', radical: '土', structure: 'Trên dưới', difficulty: 2, mnemonic: 'Hai người 人 ngồi trên mặt đất 土.'),
  HanCharacter(character: '步', hanVietReading: 'bộ', meaning: 'bước đi', radical: '止', structure: 'Trên dưới', difficulty: 2),
  HanCharacter(character: '居', hanVietReading: 'cư', meaning: 'cư trú, ở', radical: '尸', structure: 'Trên dưới', difficulty: 2),
  HanCharacter(character: '眠', hanVietReading: 'miên', meaning: 'ngủ', radical: '目', structure: 'Trái phải', difficulty: 2, mnemonic: 'Mắt 目 khép lại gợi hình ảnh đang ngủ.'),
  HanCharacter(character: '夢', hanVietReading: 'mộng', meaning: 'giấc mơ', radical: '夕', structure: 'Trên dưới', difficulty: 3),
  HanCharacter(character: '覺', hanVietReading: 'giác', meaning: 'tỉnh ngộ, cảm thấy', radical: '見', structure: 'Trên dưới', difficulty: 3),
  HanCharacter(character: '買', hanVietReading: 'mãi', meaning: 'mua', radical: '貝', structure: 'Trên dưới', difficulty: 2),
  HanCharacter(character: '賣', hanVietReading: 'mại', meaning: 'bán', radical: '貝', structure: 'Trên dưới', difficulty: 2),
  HanCharacter(character: '給', hanVietReading: 'cấp', meaning: 'cho, cung cấp', radical: '糸', structure: 'Trái phải', difficulty: 2),
  HanCharacter(character: '受', hanVietReading: 'thụ', meaning: 'nhận lấy', radical: '又', structure: 'Trên dưới', difficulty: 2),
  HanCharacter(character: '問', hanVietReading: 'vấn', meaning: 'hỏi', radical: '口', structure: 'Bao quanh', difficulty: 2, mnemonic: 'Miệng 口 ở trong cửa 門 để gọi hỏi.'),
  HanCharacter(character: '答', hanVietReading: 'đáp', meaning: 'trả lời', radical: '竹', structure: 'Trên dưới', difficulty: 2),
  HanCharacter(character: '長', hanVietReading: 'trường', meaning: 'dài', radical: '長', structure: 'Đơn thể', difficulty: 1),
  HanCharacter(character: '短', hanVietReading: 'đoản', meaning: 'ngắn', radical: '矢', structure: 'Trái phải', difficulty: 2),
  HanCharacter(character: '高', hanVietReading: 'cao', meaning: 'cao', radical: '高', structure: 'Trên dưới', difficulty: 1),
  HanCharacter(character: '低', hanVietReading: 'đê', meaning: 'thấp', radical: '人', structure: 'Trái phải', difficulty: 2),
  HanCharacter(character: '重', hanVietReading: 'trọng', meaning: 'nặng, quan trọng', radical: '里', structure: 'Đơn thể', difficulty: 2),
  HanCharacter(character: '輕', hanVietReading: 'khinh', meaning: 'nhẹ', radical: '車', structure: 'Trái phải', difficulty: 2),
  HanCharacter(character: '快', hanVietReading: 'khoái', meaning: 'nhanh, vui vẻ', radical: '心', structure: 'Trái phải', difficulty: 2),
  HanCharacter(character: '慢', hanVietReading: 'mạn', meaning: 'chậm chạp', radical: '心', structure: 'Trái phải', difficulty: 3),
  HanCharacter(character: '寒', hanVietReading: 'hàn', meaning: 'lạnh lẽo', radical: '宀', structure: 'Trên dưới', difficulty: 3),
  HanCharacter(character: '熱', hanVietReading: 'nhiệt', meaning: 'nóng bức', radical: '火', structure: 'Trên dưới', difficulty: 3),
  HanCharacter(character: '冷', hanVietReading: 'lãnh', meaning: 'lạnh, buốt', radical: '冫', structure: 'Trái phải', difficulty: 2),
  HanCharacter(character: '溫', hanVietReading: 'ôn', meaning: 'ấm áp', radical: '水', structure: 'Trái phải', difficulty: 2),
  HanCharacter(character: '厚', hanVietReading: 'hậu', meaning: 'dày', radical: '厂', structure: 'Trên dưới', difficulty: 2),
  HanCharacter(character: '薄', hanVietReading: 'bạc', meaning: 'mỏng', radical: '艸', structure: 'Trên dưới', difficulty: 3),
  HanCharacter(character: '君', hanVietReading: 'quân', meaning: 'vua, người quân tử', radical: '口', structure: 'Trên dưới', difficulty: 2),
  HanCharacter(character: '臣', hanVietReading: 'thần', meaning: 'bề tôi', radical: '臣', structure: 'Đơn thể', difficulty: 2),
  HanCharacter(character: '主', hanVietReading: 'chủ', meaning: 'chủ, người chủ', radical: '丶', structure: 'Trên dưới', difficulty: 1),
  HanCharacter(character: '客', hanVietReading: 'khách', meaning: 'người khách', radical: '宀', structure: 'Trên dưới', difficulty: 2),
  HanCharacter(character: '朋', hanVietReading: 'bằng', meaning: 'bạn bè', radical: '月', structure: 'Trái phải', difficulty: 2),
  HanCharacter(character: '友', hanVietReading: 'hữu', meaning: 'bạn', radical: '又', structure: 'Trên dưới', difficulty: 1),
  HanCharacter(character: '敵', hanVietReading: 'địch', meaning: 'kẻ thù', radical: '攴', structure: 'Trái phải', difficulty: 3),
  HanCharacter(character: '民', hanVietReading: 'dân', meaning: 'người dân', radical: '氏', structure: 'Đơn thể', difficulty: 1),
  HanCharacter(character: '兵', hanVietReading: 'binh', meaning: 'người lính', radical: '八', structure: 'Trên dưới', difficulty: 2),
  HanCharacter(character: '將', hanVietReading: 'tướng', meaning: 'vị tướng', radical: '寸', structure: 'Trái phải', difficulty: 2),
  HanCharacter(character: '理', hanVietReading: 'lý', meaning: 'lý lẽ, đạo lý', radical: '玉', structure: 'Trái phải', difficulty: 2),
  HanCharacter(character: '法', hanVietReading: 'pháp', meaning: 'pháp luật, cách thức', radical: '水', structure: 'Trái phải', difficulty: 2),
  HanCharacter(character: '道', hanVietReading: 'đạo', meaning: 'con đường, đạo đức', radical: '辵', structure: 'Nửa bao quanh', difficulty: 2),
  HanCharacter(character: '德', hanVietReading: 'đức', meaning: 'đạo đức, ân đức', radical: '彳', structure: 'Trái phải', difficulty: 3),
  HanCharacter(character: '智', hanVietReading: 'trí', meaning: 'trí tuệ', radical: '日', structure: 'Trên dưới', difficulty: 3),
  HanCharacter(character: '愚', hanVietReading: 'ngu', meaning: 'ngu ngốc', radical: '心', structure: 'Trên dưới', difficulty: 3),
  HanCharacter(character: '才', hanVietReading: 'tài', meaning: 'tài năng', radical: '手', structure: 'Đơn thể', difficulty: 1),
  HanCharacter(character: '能', hanVietReading: 'năng', meaning: 'khả năng', radical: '肉', structure: 'Đơn thể', difficulty: 2),
  HanCharacter(character: '思', hanVietReading: 'tư', meaning: 'suy nghĩ', radical: '心', structure: 'Trên dưới', difficulty: 2, mnemonic: 'Cánh đồng 田 ở trên trái tim 心; liên tưởng suy nghĩ như cày cấy trong tâm.'),
  HanCharacter(character: '想', hanVietReading: 'tưởng', meaning: 'tưởng tượng', radical: '心', structure: 'Trên dưới', difficulty: 2),
  HanCharacter(character: '意', hanVietReading: 'ý', meaning: 'ý nghĩa, ý nghĩ', radical: '心', structure: 'Trên dưới', difficulty: 2),
  HanCharacter(character: '也', hanVietReading: 'dã', meaning: 'cũng, vậy (trợ từ)', radical: '乙', structure: 'Đơn thể', difficulty: 2),
  HanCharacter(character: '之', hanVietReading: 'chi', meaning: 'của, đi đến', radical: '丿', structure: 'Đơn thể', difficulty: 2),
  HanCharacter(character: '乎', hanVietReading: 'hồ', meaning: 'trợ từ nghi vấn, cảm thán', radical: '丿', structure: 'Đơn thể', difficulty: 3),
  HanCharacter(character: '者', hanVietReading: 'giả', meaning: 'kẻ, người (hậu tố)', radical: '老', structure: 'Trên dưới', difficulty: 2),
  HanCharacter(character: '以', hanVietReading: 'dĩ', meaning: 'lấy, dùng để', radical: '人', structure: 'Đơn thể', difficulty: 2),
  HanCharacter(character: '可', hanVietReading: 'khả', meaning: 'có thể', radical: '口', structure: 'Trên dưới', difficulty: 1),
  HanCharacter(character: '必', hanVietReading: 'tất', meaning: 'chắc chắn', radical: '心', structure: 'Đơn thể', difficulty: 1),
  HanCharacter(character: '定', hanVietReading: 'định', meaning: 'quyết định, cố định', radical: '宀', structure: 'Trên dưới', difficulty: 2),
  HanCharacter(character: '真', hanVietReading: 'chân', meaning: 'sự thật, thật sự', radical: '目', structure: 'Trên dưới', difficulty: 2),
  HanCharacter(character: '假', hanVietReading: 'giả', meaning: 'giả dối, không thật', radical: '人', structure: 'Trái phải', difficulty: 2),
  HanCharacter(character: '茶', hanVietReading: 'trà', meaning: 'nước trà', radical: '艸', structure: 'Trên dưới', difficulty: 2),
  HanCharacter(character: '酒', hanVietReading: 'tửu', meaning: 'rượu', radical: '酉', structure: 'Trái phải', difficulty: 2),
  HanCharacter(character: '餅', hanVietReading: 'bính', meaning: 'bánh', radical: '食', structure: 'Trái phải', difficulty: 3),
  HanCharacter(character: '船', hanVietReading: 'thuyền', meaning: 'con thuyền', radical: '舟', structure: 'Trái phải', difficulty: 2),
  HanCharacter(character: '衣', hanVietReading: 'y', meaning: 'quần áo', radical: '衣', structure: 'Đơn thể', difficulty: 1),
  HanCharacter(character: '帽', hanVietReading: 'mạo', meaning: 'cái mũ', radical: '巾', structure: 'Trái phải', difficulty: 3),
  HanCharacter(character: '書', hanVietReading: 'thư', meaning: 'sách, viết', radical: '曰', structure: 'Trên dưới', difficulty: 2),
  HanCharacter(character: '筆', hanVietReading: 'bút', meaning: 'cây bút', radical: '竹', structure: 'Trên dưới', difficulty: 2),
  HanCharacter(character: '央', hanVietReading: 'ương', meaning: 'chính giữa', radical: '大', structure: 'Đơn thể', difficulty: 2),
  HanCharacter(character: '旁', hanVietReading: 'bàng', meaning: 'bên cạnh', radical: '方', structure: 'Trên dưới', difficulty: 3),
  HanCharacter(character: '側', hanVietReading: 'trắc', meaning: 'phía bên', radical: '人', structure: 'Trái phải', difficulty: 2),
  HanCharacter(character: '頂', hanVietReading: 'đỉnh', meaning: 'trên cùng', radical: '頁', structure: 'Trái phải', difficulty: 3),
  HanCharacter(character: '底', hanVietReading: 'để', meaning: 'đáy, dưới cùng', radical: '广', structure: 'Nửa bao quanh', difficulty: 2),
  HanCharacter(character: '森', hanVietReading: 'sâm', meaning: 'rừng rậm', radical: '木', structure: 'Trên dưới', difficulty: 2, mnemonic: 'Ba chữ Mộc 木 gộp lại gợi thành rừng rậm.'),
  HanCharacter(character: '淚', hanVietReading: 'lệ', meaning: 'nước mắt', radical: '水', structure: 'Trái phải', difficulty: 2, mnemonic: 'Bộ Thủy 氵 cạnh Mục 目: nước chảy ra từ mắt là nước mắt.'),
  HanCharacter(character: '仙', hanVietReading: 'tiên', meaning: 'tiên nhân', radical: '人', structure: 'Trái phải', difficulty: 3, mnemonic: 'Nhân 亻 đứng cạnh Sơn 山: người tu hành trên núi gợi hình ảnh tiên nhân.'),
  HanCharacter(character: '尖', hanVietReading: 'tiêm', meaning: 'mũi nhọn', radical: '小', structure: 'Trên dưới', difficulty: 3, mnemonic: 'Trên nhỏ 小, dưới to 大, tạo dáng mũi nhọn.'),
  HanCharacter(character: '信', hanVietReading: 'tín', meaning: 'niềm tin, thư từ', radical: '人', structure: 'Trái phải', difficulty: 2, mnemonic: 'Nhân 亻 và Ngôn 言: lời nói của người đáng tin tạo nên chữ tín.'),
  HanCharacter(character: '雞', hanVietReading: 'kê', meaning: 'con gà', radical: '鳥', structure: 'Trái phải', difficulty: 2),
  HanCharacter(character: '鴨', hanVietReading: 'áp', meaning: 'con vịt', radical: '鳥', structure: 'Trái phải', difficulty: 2),
  HanCharacter(character: '虎', hanVietReading: 'hổ', meaning: 'con hổ', radical: '虍', structure: 'Nửa bao quanh', difficulty: 2),
  HanCharacter(character: '兔', hanVietReading: 'thố', meaning: 'con thỏ', radical: '儿', structure: 'Đơn thể', difficulty: 2),
  HanCharacter(character: '蛇', hanVietReading: 'xà', meaning: 'con rắn', radical: '虫', structure: 'Trái phải', difficulty: 2),
  HanCharacter(character: '鼠', hanVietReading: 'thử', meaning: 'con chuột', radical: '鼠', structure: 'Đơn thể', difficulty: 3),
  HanCharacter(character: '龜', hanVietReading: 'quy', meaning: 'con rùa', radical: '龜', structure: 'Đơn thể', difficulty: 3),
  HanCharacter(character: '蛙', hanVietReading: 'oa', meaning: 'con ếch', radical: '虫', structure: 'Trái phải', difficulty: 2),
  HanCharacter(character: '豬', hanVietReading: 'trư', meaning: 'con lợn', radical: '豕', structure: 'Trái phải', difficulty: 2),
  HanCharacter(character: '象', hanVietReading: 'tượng', meaning: 'con voi', radical: '豕', structure: 'Đơn thể', difficulty: 2),
  HanCharacter(character: '開', hanVietReading: 'khai', meaning: 'mở', radical: '門', structure: 'Bao quanh', difficulty: 2),
  HanCharacter(character: '關', hanVietReading: 'quan', meaning: 'đóng, cửa ải', radical: '門', structure: 'Bao quanh', difficulty: 3),
  HanCharacter(character: '灰', hanVietReading: 'hôi', meaning: 'tro, màu xám', radical: '火', structure: 'Trên dưới', difficulty: 1),
  HanCharacter(character: '褐', hanVietReading: 'cát', meaning: 'màu nâu', radical: '衣', structure: 'Trái phải', difficulty: 3),
  HanCharacter(character: '圓', hanVietReading: 'viên', meaning: 'tròn', radical: '囗', structure: 'Bao quanh', difficulty: 2),
  HanCharacter(character: '方', hanVietReading: 'phương', meaning: 'phương hướng, vuông', radical: '方', structure: 'Đơn thể', difficulty: 1),
  HanCharacter(character: '正', hanVietReading: 'chính', meaning: 'đúng, ngay thẳng', radical: '止', structure: 'Trên dưới', difficulty: 1),
  HanCharacter(character: '美', hanVietReading: 'mỹ', meaning: 'đẹp', radical: '羊', structure: 'Trên dưới', difficulty: 2),
  HanCharacter(character: '安', hanVietReading: 'an', meaning: 'an toàn, bình an', radical: '宀', structure: 'Trên dưới', difficulty: 1),
  HanCharacter(character: '病', hanVietReading: 'bệnh', meaning: 'bệnh tật', radical: '疒', structure: 'Nửa bao quanh', difficulty: 2),

  // Dữ liệu seed hoạt động chỉ chứa 250 chữ Hán.
];

const int hanCoreLessonCount = 25;
const int nomCharacterCount = 0;
const int hanLessonsPerCycle = 5;
const int nomTrackLessonCount = 3;

/// Lộ trình Hán được tổ chức theo chủ đề, mỗi Node có 10 chữ mới.
/// Tất cả chữ đều lấy từ seed/từ điển hiện hữu; không thêm bản ghi từ vựng mới.
const List<LessonUnit> lessonUnits = [
  LessonUnit(title: 'Số đếm từ 1 đến 10', subtitle: 'Nhất, nhị, tam… đến thập', characters: ['一', '二', '三', '四', '五', '六', '七', '八', '九', '十'], icon: '🔢'),
  LessonUnit(title: 'Số lượng và kích thước', subtitle: 'Số lớn, nhiều–ít, lớn–nhỏ, dài–ngắn và cao', characters: ['百', '千', '萬', '多', '少', '大', '小', '長', '短', '高'], icon: '📏'),
  LessonUnit(title: 'Phương hướng', subtitle: 'Đông, tây, nam, bắc và các hướng tương đối', characters: ['東', '西', '南', '北', '左', '右', '前', '後', '上', '下'], icon: '🧭'),
  LessonUnit(title: 'Vị trí và hình dạng', subtitle: 'Trong–ngoài, giữa, bên cạnh, đỉnh, đáy và hình dạng', characters: ['中', '內', '外', '央', '旁', '側', '頂', '底', '方', '圓'], icon: '📍'),
  LessonUnit(title: 'Con người, gia đình và quốc gia', subtitle: 'Người thân, vai trò gia đình và quốc gia', characters: ['人', '男', '女', '家', '父', '母', '子', '兄', '弟', '國'], icon: '👨‍👩‍👧‍👦'),
  LessonUnit(title: 'Xã hội và vai trò', subtitle: 'Bạn bè, đối thủ, người dân, quân đội và vai trò xã hội', characters: ['朋', '友', '敵', '民', '兵', '君', '臣', '主', '客', '將'], icon: '🤝'),
  LessonUnit(title: 'Bộ phận cơ thể bên ngoài', subtitle: 'Mắt, tai, miệng, tay, chân, đầu, mặt, răng, da và lông', characters: ['目', '耳', '口', '手', '足', '頭', '面', '齒', '皮', '毛'], icon: '🧍'),
  LessonUnit(title: 'Cơ thể và sức khỏe', subtitle: 'Tim, nội tạng, máu, thịt, xương, bệnh và sự sống', characters: ['心', '肝', '肺', '胃', '腸', '血', '肉', '骨', '病', '生'], icon: '🫀'),
  LessonUnit(title: 'Di chuyển và tư thế', subtitle: 'Đến, đi, ra, vào, chạy, bay, bơi, đứng, ngồi và bước', characters: ['來', '去', '出', '入', '走', '飛', '游', '立', '坐', '步'], icon: '🚶'),
  LessonUnit(title: 'Học tập và giao tiếp', subtitle: 'Học, ngôn ngữ, nói, đọc, viết, sách, bút, hỏi, đáp và tín', characters: ['學', '語', '說', '讀', '寫', '書', '筆', '問', '答', '信'], icon: '📚'),
  LessonUnit(title: 'Bầu trời và ánh sáng', subtitle: 'Trời đất, nhật nguyệt, sao, sáng–tối, khí và lửa', characters: ['天', '地', '日', '月', '星', '光', '明', '暗', '氣', '火'], icon: '🌤️'),
  LessonUnit(title: 'Thời tiết và sông nước', subtitle: 'Nước, mưa, mây, tuyết, điện, gió, sông, biển và hồ', characters: ['水', '雨', '雲', '雪', '電', '風', '江', '河', '海', '湖'], icon: '🌧️'),
  LessonUnit(title: 'Cây cối và địa hình', subtitle: 'Núi, cây, rừng, cỏ, hoa, tre, ruộng, đất và đá', characters: ['山', '木', '林', '森', '草', '花', '竹', '田', '土', '石'], icon: '🌿'),
  LessonUnit(title: 'Động vật quen thuộc', subtitle: 'Chó, mèo, ngựa, trâu/bò, dê/cừu, gà, vịt, lợn, chim và cá', characters: ['犬', '貓', '馬', '牛', '羊', '雞', '鴨', '豬', '鳥', '魚'], icon: '🐾'),
  LessonUnit(title: 'Muông thú và linh vật', subtitle: 'Côn trùng, rồng, hổ, thỏ, rắn, chuột, rùa, ếch, voi và tiên', characters: ['蟲', '龍', '虎', '兔', '蛇', '鼠', '龜', '蛙', '象', '仙'], icon: '🐉'),
  LessonUnit(title: 'Mùa, buổi và đơn vị thời gian', subtitle: 'Xuân–hạ–thu–đông, sáng–tối, năm, phút và giây', characters: ['春', '夏', '秋', '冬', '朝', '夕', '夜', '年', '分', '秒'], icon: '🕰️'),
  LessonUnit(title: 'Cảm xúc và phẩm chất', subtitle: 'Tốt đẹp, yêu–ghét, vui–giận–buồn, nước mắt, trung và chính', characters: ['好', '愛', '恨', '喜', '怒', '哀', '樂', '淚', '忠', '正'], icon: '💭'),
  LessonUnit(title: 'Màu sắc', subtitle: 'Trắng, đen, xanh, vàng, đỏ, tím, xám và nâu', characters: ['白', '黑', '青', '黃', '赤', '綠', '藍', '紫', '灰', '褐'], icon: '🎨'),
  LessonUnit(title: 'Ăn uống và trao đổi', subtitle: 'Ăn, uống, trà, rượu, bánh, gạo, mua–bán, cho–nhận', characters: ['食', '飲', '茶', '酒', '餅', '米', '買', '賣', '給', '受'], icon: '🍵'),
  LessonUnit(title: 'Vật liệu, trang phục và phương tiện', subtitle: 'Kim loại, quần áo, thuyền, xe, cửa và đóng/mở', characters: ['金', '銀', '鐵', '衣', '帽', '船', '車', '門', '開', '關'], icon: '🧰'),
  LessonUnit(title: 'Trọng lượng, tốc độ và nhiệt độ', subtitle: 'Thấp, nặng–nhẹ, nhanh–chậm, nóng–lạnh, ấm và dày', characters: ['低', '重', '輕', '快', '慢', '寒', '熱', '冷', '溫', '厚'], icon: '🌡️'),
  LessonUnit(title: 'Tư duy, trí tuệ và quy tắc', subtitle: 'Tư tưởng, trí–ngu, tài năng, lý lẽ, pháp và đức', characters: ['思', '想', '意', '智', '愚', '才', '能', '理', '法', '德'], icon: '🧠'),
  LessonUnit(title: 'Hư từ và logic', subtitle: 'Trợ từ, liên từ, khả năng, tất yếu và thật–giả', characters: ['也', '之', '乎', '者', '以', '可', '必', '定', '真', '假'], icon: '🧩'),
  LessonUnit(title: 'Sinh hoạt, giác quan và thời gian', subtitle: 'Nghỉ, ở, ngủ, mơ, tỉnh, nhìn, nghe, giờ, nay và xưa', characters: ['休', '居', '眠', '夢', '覺', '看', '聽', '時', '今', '昔'], icon: '🌙'),
  LessonUnit(title: 'Đặc điểm và khái niệm', subtitle: 'Cũ–mới, nhọn, ngọt–đắng, đẹp, mỏng, đạo, an và không', characters: ['古', '尖', '新', '甜', '美', '苦', '薄', '道', '安', '空'], icon: '✨'),

  // Khung lộ trình Nôm được giữ nguyên để dùng lại sau khi chuẩn hóa.
  // Dữ liệu ký tự đã được gỡ khỏi seed và cần được bổ sung lại bằng bộ chuẩn mới.
  LessonUnit(title: 'Bài Nôm 1', subtitle: 'Tạm ẩn dữ liệu trong thời gian chuẩn hóa chữ và mã Unicode.', characters: [], icon: '🟠', type: 'Nôm'),
  LessonUnit(title: 'Bài Nôm 2', subtitle: 'Tạm ẩn dữ liệu trong thời gian chuẩn hóa chữ và mã Unicode.', characters: [], icon: '🟠', type: 'Nôm'),
  LessonUnit(title: 'Bài Nôm 3', subtitle: 'Tạm ẩn dữ liệu trong thời gian chuẩn hóa chữ và mã Unicode.', characters: [], icon: '🟠', type: 'Nôm'),
];

/// Separate skill-tree lists used by the Hán/Nôm tabs.
final List<LessonUnit> hanLessonUnits = List<LessonUnit>.unmodifiable(
  lessonUnits.take(hanCoreLessonCount),
);
final List<LessonUnit> nomLessonUnits = List<LessonUnit>.unmodifiable(
  lessonUnits.skip(hanCoreLessonCount),
);

HanCharacter? findCharacter(String value) {
  for (final character in seedCharacters) {
    if (character.character == value) return character;
  }
  return null;
}

List<HanCharacter> charactersForUnit(int unitIndex) {
  final safeIndex = unitIndex.clamp(0, lessonUnits.length - 1).toInt();
  final unit = lessonUnits[safeIndex];
  return unit.characters.map(findCharacter).whereType<HanCharacter>().toList();
}

List<HanCharacter> randomJumpAheadCharacters({
  int limit = 10,
  int? targetLessonNumber,
  Random? random,
}) {
  if (limit <= 0 || seedCharacters.isEmpty) return <HanCharacter>[];
  final rng = random ?? Random();

  final target = targetLessonNumber ?? 1;
  // Học vượt chỉ lấy ký tự thuộc các Node đứng trước Node mục tiêu.
  // Node 1 không có bài trước để lấy mẫu nên trả về danh sách rỗng.
  if (target <= 1 || target > hanCoreLessonCount) return <HanCharacter>[];
  final eligibleCharacters = seedCharacters.where((character) => character.isHan).toList();

  final priorCharacters = <String>{};
  if (target > 1) {
    final priorUnits = hanLessonUnits.take(target - 1);
    for (final unit in priorUnits) {
      priorCharacters.addAll(unit.characters);
    }
  }

  final priorPool = eligibleCharacters
      .where((character) => priorCharacters.contains(character.character))
      .toList()
    ..shuffle(rng);
  // Không lấy chữ từ bài hiện tại/tương lai để bù thiếu; chỉ kiểm tra kiến thức cũ.
  return priorPool.take(min(limit, priorPool.length)).toList();
}

List<HanCharacter> randomReviewCheckpointCharacters({
  required int checkpointNumber,
  int limit = 20,
  Random? random,
}) {
  if (checkpointNumber < 1 || limit <= 0) return <HanCharacter>[];
  final firstUnit = (checkpointNumber - 1) * hanLessonsPerCycle;
  final previousUnits = hanLessonUnits.skip(firstUnit).take(hanLessonsPerCycle);
  final previousSymbols = previousUnits.expand((unit) => unit.characters).toSet();
  final pool = seedCharacters
      .where((character) => character.isHan && previousSymbols.contains(character.character))
      .toList();
  final rng = random ?? Random();
  pool.shuffle(rng);
  return pool.take(min(limit, pool.length)).toList();
}

/// Một cụm/câu đã được duyệt cho bài dịch Hán <-> âm Hán-Việt.
/// Không ghép nghĩa từng chữ theo kiểu máy móc; chỉ dùng những chuỗi có
/// cách đọc/cách dùng ổn định trong Hán-Việt.
class CuratedHanVietPhrase {
  final String hanText;
  final String vietnameseGloss;
  final bool isFullSentence;
  /// Các bản dịch diễn đạt khác được lưu để tham khảo; không dùng để chấm
  /// câu gõ âm Hán-Việt vì nghĩa tiếng Việt không có một cách diễn đạt duy nhất.
  final List<String> acceptedVietnameseAnswers;

  const CuratedHanVietPhrase({
    required this.hanText,
    required this.vietnameseGloss,
    this.isFullSentence = false,
    this.acceptedVietnameseAnswers = const <String>[],
  });

  List<String> get symbols => hanText.runes.map(String.fromCharCode).toList();
}

/// Ngân hàng phrase được kiểm duyệt thủ công. Một phrase chỉ được sinh ra khi
/// TẤT CẢ ký tự đã thuộc phạm vi người học được học.
const List<CuratedHanVietPhrase> curatedHanVietPhrases = [
  CuratedHanVietPhrase(hanText: '朋友', vietnameseGloss: 'bạn bè'),
  CuratedHanVietPhrase(hanText: '君臣', vietnameseGloss: 'vua tôi'),
  CuratedHanVietPhrase(hanText: '民兵', vietnameseGloss: 'dân binh'),
  CuratedHanVietPhrase(hanText: '父母', vietnameseGloss: 'cha mẹ'),
  CuratedHanVietPhrase(hanText: '兄弟', vietnameseGloss: 'anh em'),
  CuratedHanVietPhrase(hanText: '國家', vietnameseGloss: 'đất nước'),
  CuratedHanVietPhrase(hanText: '學生', vietnameseGloss: 'học sinh'),
  CuratedHanVietPhrase(hanText: '學問', vietnameseGloss: 'học vấn'),
  CuratedHanVietPhrase(hanText: '日月', vietnameseGloss: 'mặt trời và mặt trăng'),
  CuratedHanVietPhrase(hanText: '左右', vietnameseGloss: 'trái phải'),
  CuratedHanVietPhrase(hanText: '前後', vietnameseGloss: 'trước sau'),
  CuratedHanVietPhrase(hanText: '上下', vietnameseGloss: 'trên dưới'),
  CuratedHanVietPhrase(hanText: '出入', vietnameseGloss: 'ra vào'),
  CuratedHanVietPhrase(hanText: '內外', vietnameseGloss: 'trong ngoài'),
  CuratedHanVietPhrase(hanText: '手足', vietnameseGloss: 'tay chân; anh em ruột'),
  CuratedHanVietPhrase(hanText: '山水', vietnameseGloss: 'núi sông, phong cảnh thiên nhiên'),
  CuratedHanVietPhrase(hanText: '金銀', vietnameseGloss: 'vàng bạc'),
  CuratedHanVietPhrase(hanText: '黑白', vietnameseGloss: 'đen trắng'),
  CuratedHanVietPhrase(hanText: '東西南北', vietnameseGloss: 'bốn phương đông tây nam bắc'),
  CuratedHanVietPhrase(hanText: '天地日月', vietnameseGloss: 'trời đất và mặt trời, mặt trăng'),
  CuratedHanVietPhrase(hanText: '春夏秋冬', vietnameseGloss: 'bốn mùa xuân hạ thu đông'),
  CuratedHanVietPhrase(hanText: '南國山河', vietnameseGloss: 'non sông nước Nam'),
  CuratedHanVietPhrase(hanText: '日出東方', vietnameseGloss: 'mặt trời mọc ở phương Đông', isFullSentence: true),
  CuratedHanVietPhrase(hanText: '父母愛子', vietnameseGloss: 'cha mẹ yêu con', isFullSentence: true),
  CuratedHanVietPhrase(hanText: '大江東去', vietnameseGloss: 'sông lớn chảy về phía đông', isFullSentence: true),
  CuratedHanVietPhrase(
    hanText: '人多地少',
    vietnameseGloss: 'người đông, đất ít',
    isFullSentence: true,
    acceptedVietnameseAnswers: ['người đông đất ít', 'dân đông, đất ít'],
  ),
  CuratedHanVietPhrase(
    hanText: '冬去春來',
    vietnameseGloss: 'đông qua, xuân đến',
    isFullSentence: true,
    acceptedVietnameseAnswers: ['mùa đông qua, mùa xuân đến', 'đông đi xuân tới'],
  ),
  CuratedHanVietPhrase(
    hanText: '魚游水中',
    vietnameseGloss: 'cá bơi trong nước',
    isFullSentence: true,
    acceptedVietnameseAnswers: ['con cá bơi trong nước'],
  ),
  CuratedHanVietPhrase(
    hanText: '飛鳥入林',
    vietnameseGloss: 'chim bay vào rừng',
    isFullSentence: true,
    acceptedVietnameseAnswers: ['con chim bay vào rừng'],
  ),
  CuratedHanVietPhrase(
    hanText: '鳥飛魚游',
    vietnameseGloss: 'chim bay, cá bơi',
    isFullSentence: true,
    acceptedVietnameseAnswers: ['chim thì bay, cá thì bơi', 'chim bay cá bơi'],
  ),
  CuratedHanVietPhrase(
    hanText: '江河入海',
    vietnameseGloss: 'sông ngòi đổ ra biển',
    isFullSentence: true,
    acceptedVietnameseAnswers: ['sông ngòi chảy ra biển', 'các dòng sông đổ ra biển'],
  ),
  CuratedHanVietPhrase(
    hanText: '人立山下',
    vietnameseGloss: 'người đứng dưới núi',
    isFullSentence: true,
    acceptedVietnameseAnswers: ['một người đứng dưới núi'],
  ),
  CuratedHanVietPhrase(
    hanText: '花開月圓',
    vietnameseGloss: 'hoa nở, trăng tròn',
    isFullSentence: true,
    acceptedVietnameseAnswers: ['hoa nở trăng tròn'],
  ),
  CuratedHanVietPhrase(
    hanText: '長江入海',
    vietnameseGloss: 'Trường Giang đổ ra biển',
    isFullSentence: true,
    acceptedVietnameseAnswers: ['sông Trường Giang đổ ra biển', 'Trường Giang chảy ra biển'],
  ),
  CuratedHanVietPhrase(
    hanText: '日月光明',
    vietnameseGloss: 'mặt trời và mặt trăng đều sáng',
    isFullSentence: true,
    acceptedVietnameseAnswers: ['mặt trời mặt trăng đều sáng', 'nhật nguyệt sáng tỏ'],
  ),
  CuratedHanVietPhrase(
    hanText: '魚游江海',
    vietnameseGloss: 'cá bơi giữa sông và biển',
    isFullSentence: true,
    acceptedVietnameseAnswers: ['cá bơi ở sông biển', 'cá bơi trong sông và biển'],
  ),
  CuratedHanVietPhrase(hanText: '四海一家', vietnameseGloss: 'bốn biển một nhà'),
  CuratedHanVietPhrase(hanText: '五湖四海', vietnameseGloss: 'năm hồ bốn bể; khắp mọi miền'),
  CuratedHanVietPhrase(hanText: '江河湖海', vietnameseGloss: 'sông ngòi, hồ và biển'),
  CuratedHanVietPhrase(hanText: '山河大地', vietnameseGloss: 'non sông đất trời'),
  CuratedHanVietPhrase(hanText: '一日千秋', vietnameseGloss: 'một ngày dài tựa nghìn thu'),
  CuratedHanVietPhrase(hanText: '白日青天', vietnameseGloss: 'ban ngày giữa trời xanh; rõ ràng, quang minh'),
  CuratedHanVietPhrase(hanText: '山高水長', vietnameseGloss: 'núi cao sông dài'),
  CuratedHanVietPhrase(hanText: '光明正大', vietnameseGloss: 'ngay thẳng, quang minh chính đại'),
  CuratedHanVietPhrase(hanText: '天高地厚', vietnameseGloss: 'trời cao đất dày'),
  CuratedHanVietPhrase(hanText: '人山人海', vietnameseGloss: 'đông người như biển người'),
  CuratedHanVietPhrase(hanText: '花好月圓', vietnameseGloss: 'sum vầy viên mãn'),
  CuratedHanVietPhrase(hanText: '青山綠水', vietnameseGloss: 'núi xanh nước biếc'),
  CuratedHanVietPhrase(hanText: '花前月下', vietnameseGloss: 'trước hoa dưới trăng; nơi hẹn hò'),
  CuratedHanVietPhrase(hanText: '一心一意', vietnameseGloss: 'một lòng một dạ'),
  CuratedHanVietPhrase(hanText: '三心二意', vietnameseGloss: 'không chuyên tâm, hay đổi ý'),
  CuratedHanVietPhrase(hanText: '千山萬水', vietnameseGloss: 'muôn núi ngàn sông; đường xa cách trở'),

  // Additional curated Hán văn sentences and phrases; only sentence-like clauses are used for typed sentence translation.
  CuratedHanVietPhrase(
    hanText: '春來花開',
    vietnameseGloss: 'xuân đến, hoa nở',
    isFullSentence: true,
    acceptedVietnameseAnswers: ['mùa xuân đến, hoa nở', 'xuân về hoa nở'],
  ),
  CuratedHanVietPhrase(
    hanText: '春去秋來',
    vietnameseGloss: 'xuân đi, thu đến',
    isFullSentence: true,
    acceptedVietnameseAnswers: ['mùa xuân qua, mùa thu đến', 'xuân qua thu tới'],
  ),
  CuratedHanVietPhrase(
    hanText: '馬入山林',
    vietnameseGloss: 'ngựa vào rừng núi',
    isFullSentence: true,
    acceptedVietnameseAnswers: ['con ngựa đi vào rừng núi'],
  ),
  CuratedHanVietPhrase(
    hanText: '牛羊上山',
    vietnameseGloss: 'trâu bò và dê lên núi',
    isFullSentence: true,
    acceptedVietnameseAnswers: ['trâu bò dê lên núi'],
  ),
  CuratedHanVietPhrase(
    hanText: '小魚游水',
    vietnameseGloss: 'cá nhỏ bơi trong nước',
    isFullSentence: true,
    acceptedVietnameseAnswers: ['những con cá nhỏ bơi trong nước'],
  ),
  CuratedHanVietPhrase(
    hanText: '雨下山中',
    vietnameseGloss: 'mưa rơi trong núi',
    acceptedVietnameseAnswers: ['mưa rơi giữa núi rừng'],
  ),
  CuratedHanVietPhrase(
    hanText: '雲入山中',
    vietnameseGloss: 'mây vào trong núi',
    isFullSentence: true,
    acceptedVietnameseAnswers: ['mây bay vào núi'],
  ),
  CuratedHanVietPhrase(
    hanText: '鳥入山林',
    vietnameseGloss: 'chim vào rừng núi',
    isFullSentence: true,
    acceptedVietnameseAnswers: ['chim bay vào rừng'],
  ),
  CuratedHanVietPhrase(
    hanText: '虎入山林',
    vietnameseGloss: 'hổ vào rừng núi',
    isFullSentence: true,
    acceptedVietnameseAnswers: ['con hổ đi vào rừng'],
  ),
  CuratedHanVietPhrase(
    hanText: '龜入水中',
    vietnameseGloss: 'rùa vào trong nước',
    isFullSentence: true,
    acceptedVietnameseAnswers: ['con rùa đi xuống nước'],
  ),
  CuratedHanVietPhrase(
    hanText: '魚入江河',
    vietnameseGloss: 'cá đi vào sông ngòi',
    acceptedVietnameseAnswers: ['cá bơi vào sông'],
  ),
  CuratedHanVietPhrase(
    hanText: '朋友來家',
    vietnameseGloss: 'bạn bè đến nhà',
    isFullSentence: true,
    acceptedVietnameseAnswers: ['bạn bè tới nhà'],
  ),
  CuratedHanVietPhrase(
    hanText: '子讀書',
    vietnameseGloss: 'con đọc sách',
    isFullSentence: true,
    acceptedVietnameseAnswers: ['đứa trẻ đọc sách'],
  ),
  CuratedHanVietPhrase(
    hanText: '多讀多問',
    vietnameseGloss: 'đọc nhiều, hỏi nhiều',
    isFullSentence: true,
    acceptedVietnameseAnswers: ['đọc nhiều hỏi nhiều'],
  ),
  CuratedHanVietPhrase(
    hanText: '讀書問答',
    vietnameseGloss: 'đọc sách, hỏi đáp',
    acceptedVietnameseAnswers: ['đọc sách và hỏi đáp'],
  ),
  CuratedHanVietPhrase(
    hanText: '多說少問',
    vietnameseGloss: 'nói nhiều, hỏi ít',
    acceptedVietnameseAnswers: ['nói nhiều hỏi ít'],
  ),
  CuratedHanVietPhrase(
    hanText: '好學多問',
    vietnameseGloss: 'ham học, hay hỏi',
    isFullSentence: true,
    acceptedVietnameseAnswers: ['ham học và hỏi nhiều'],
  ),
  CuratedHanVietPhrase(
    hanText: '車入山中',
    vietnameseGloss: 'xe vào trong núi',
    isFullSentence: true,
    acceptedVietnameseAnswers: ['chiếc xe đi vào núi'],
  ),
  CuratedHanVietPhrase(
    hanText: '愛恨分明',
    vietnameseGloss: 'yêu ghét rõ ràng',
    acceptedVietnameseAnswers: ['yêu ghét phân minh'],
  ),
  CuratedHanVietPhrase(
    hanText: '忠心愛國',
    vietnameseGloss: 'một lòng yêu nước',
    acceptedVietnameseAnswers: ['trung thành và yêu nước'],
  ),
  CuratedHanVietPhrase(
    hanText: '國內多山河',
    vietnameseGloss: 'trong nước có nhiều núi sông',
    acceptedVietnameseAnswers: ['trong nước nhiều núi sông'],
  ),
  CuratedHanVietPhrase(
    hanText: '北風入夜',
    vietnameseGloss: 'gió bắc tràn vào đêm',
    acceptedVietnameseAnswers: ['gió bắc thổi về đêm'],
  ),
  CuratedHanVietPhrase(
    hanText: '夜長夢多',
    vietnameseGloss: 'đêm dài, nhiều mộng',
    acceptedVietnameseAnswers: ['đêm dài lắm mộng'],
  ),
  CuratedHanVietPhrase(
    hanText: '月圓花好',
    vietnameseGloss: 'trăng tròn, hoa đẹp',
    acceptedVietnameseAnswers: ['trăng tròn hoa nở đẹp'],
  ),
  CuratedHanVietPhrase(
    hanText: '春日花開',
    vietnameseGloss: 'ngày xuân hoa nở',
    acceptedVietnameseAnswers: ['hoa nở vào ngày xuân'],
  ),
  // Additional varied sentence patterns for typed-meaning practice.
  CuratedHanVietPhrase(
    hanText: '日出海上',
    vietnameseGloss: 'mặt trời mọc trên biển',
    isFullSentence: true,
    acceptedVietnameseAnswers: ['mặt trời xuất hiện trên biển'],
  ),
  CuratedHanVietPhrase(
    hanText: '月出山中',
    vietnameseGloss: 'trăng lên giữa núi',
    isFullSentence: true,
    acceptedVietnameseAnswers: ['mặt trăng lên giữa núi'],
  ),
  CuratedHanVietPhrase(
    hanText: '秋日雲高',
    vietnameseGloss: 'ngày thu mây cao',
    isFullSentence: true,
    acceptedVietnameseAnswers: ['mây cao trong ngày thu'],
  ),
  CuratedHanVietPhrase(
    hanText: '冬日天冷',
    vietnameseGloss: 'ngày đông trời lạnh',
    isFullSentence: true,
    acceptedVietnameseAnswers: ['trời lạnh vào ngày đông'],
  ),
  CuratedHanVietPhrase(
    hanText: '夏日天長',
    vietnameseGloss: 'ngày hè dài',
    isFullSentence: true,
    acceptedVietnameseAnswers: ['ngày mùa hè dài'],
  ),
  CuratedHanVietPhrase(
    hanText: '春日草木生',
    vietnameseGloss: 'ngày xuân cỏ cây sinh trưởng',
    isFullSentence: true,
    acceptedVietnameseAnswers: ['cỏ cây sinh trưởng vào ngày xuân'],
  ),
  CuratedHanVietPhrase(
    hanText: '一人立山中',
    vietnameseGloss: 'một người đứng giữa núi',
    isFullSentence: true,
    acceptedVietnameseAnswers: ['một người đứng trong núi'],
  ),
  CuratedHanVietPhrase(
    hanText: '子問母答',
    vietnameseGloss: 'con hỏi, mẹ đáp',
    isFullSentence: true,
    acceptedVietnameseAnswers: ['đứa con hỏi, người mẹ trả lời'],
  ),
  CuratedHanVietPhrase(
    hanText: '兄問弟答',
    vietnameseGloss: 'anh hỏi, em đáp',
    isFullSentence: true,
    acceptedVietnameseAnswers: ['người anh hỏi, người em trả lời'],
  ),
  CuratedHanVietPhrase(
    hanText: '君主愛民',
    vietnameseGloss: 'vua yêu dân',
    isFullSentence: true,
    acceptedVietnameseAnswers: ['quân chủ yêu dân'],
  ),
  CuratedHanVietPhrase(
    hanText: '民愛國家',
    vietnameseGloss: 'người dân yêu đất nước',
    isFullSentence: true,
    acceptedVietnameseAnswers: ['dân yêu nước'],
  ),
  CuratedHanVietPhrase(
    hanText: '人多食少',
    vietnameseGloss: 'người đông, thức ăn ít',
    isFullSentence: true,
    acceptedVietnameseAnswers: ['nhiều người, ít thức ăn'],
  ),
  CuratedHanVietPhrase(
    hanText: '牛羊食草',
    vietnameseGloss: 'trâu bò và dê ăn cỏ',
    isFullSentence: true,
    acceptedVietnameseAnswers: ['trâu dê ăn cỏ'],
  ),
  CuratedHanVietPhrase(
    hanText: '小鳥入林',
    vietnameseGloss: 'chim nhỏ vào rừng',
    isFullSentence: true,
    acceptedVietnameseAnswers: ['con chim nhỏ bay vào rừng'],
  ),
  CuratedHanVietPhrase(
    hanText: '大魚入海',
    vietnameseGloss: 'cá lớn vào biển',
    isFullSentence: true,
    acceptedVietnameseAnswers: ['con cá lớn bơi ra biển'],
  ),
  CuratedHanVietPhrase(
    hanText: '龍游四海',
    vietnameseGloss: 'rồng bơi khắp bốn biển',
    isFullSentence: true,
    acceptedVietnameseAnswers: ['rồng tung hoành bốn biển'],
  ),
  CuratedHanVietPhrase(
    hanText: '海上多船',
    vietnameseGloss: 'ngoài biển có nhiều thuyền',
    isFullSentence: true,
    acceptedVietnameseAnswers: ['trên biển có nhiều thuyền'],
  ),
  CuratedHanVietPhrase(
    hanText: '雲多雨少',
    vietnameseGloss: 'mây nhiều, mưa ít',
    isFullSentence: true,
    acceptedVietnameseAnswers: ['nhiều mây ít mưa'],
  ),
  CuratedHanVietPhrase(
    hanText: '日夜讀書',
    vietnameseGloss: 'ngày đêm đọc sách',
    isFullSentence: true,
    acceptedVietnameseAnswers: ['đọc sách ngày đêm'],
  ),
  CuratedHanVietPhrase(
    hanText: '年少好學',
    vietnameseGloss: 'tuổi trẻ ham học',
    isFullSentence: true,
    acceptedVietnameseAnswers: ['khi còn trẻ đã ham học'],
  ),
  CuratedHanVietPhrase(
    hanText: '君明臣忠',
    vietnameseGloss: 'vua sáng, bề tôi trung thành',
    isFullSentence: true,
    acceptedVietnameseAnswers: ['vua sáng suốt, bề tôi trung thành'],
  ),
  CuratedHanVietPhrase(
    hanText: '母愛子女',
    vietnameseGloss: 'mẹ yêu con cái',
    isFullSentence: true,
    acceptedVietnameseAnswers: ['người mẹ yêu thương con cái'],
  ),
  CuratedHanVietPhrase(
    hanText: '兵多將少',
    vietnameseGloss: 'quân đông, tướng ít',
    isFullSentence: true,
    acceptedVietnameseAnswers: ['quân lính đông mà tướng ít'],
  ),
  CuratedHanVietPhrase(
    hanText: '秋冬多雪',
    vietnameseGloss: 'thu đông nhiều tuyết',
    isFullSentence: true,
    acceptedVietnameseAnswers: ['mùa thu và mùa đông có nhiều tuyết'],
  ),
  CuratedHanVietPhrase(
    hanText: '兵出國門',
    vietnameseGloss: 'binh lính ra khỏi cổng thành',
    isFullSentence: true,
    acceptedVietnameseAnswers: ['quân lính rời cổng thành'],
  ),
  CuratedHanVietPhrase(
    hanText: '青天白日',
    vietnameseGloss: 'trời xanh, ban ngày',
    acceptedVietnameseAnswers: ['trời xanh giữa ban ngày'],
  ),
  CuratedHanVietPhrase(
    hanText: '筆下生花',
    vietnameseGloss: 'dưới ngòi bút nở hoa',
    acceptedVietnameseAnswers: ['ngòi bút sinh hoa'],
  ),
  CuratedHanVietPhrase(
    hanText: '一問一答',
    vietnameseGloss: 'một hỏi, một đáp',
    acceptedVietnameseAnswers: ['hỏi một câu, đáp một câu'],
  ),
  CuratedHanVietPhrase(
    hanText: '上下一心',
    vietnameseGloss: 'trên dưới một lòng',
    acceptedVietnameseAnswers: ['từ trên xuống dưới đồng lòng'],
  ),
  CuratedHanVietPhrase(
    hanText: '前後左右',
    vietnameseGloss: 'trước sau trái phải',
    acceptedVietnameseAnswers: ['phía trước phía sau bên trái bên phải'],
  ),
  CuratedHanVietPhrase(
    hanText: '買米賣茶',
    vietnameseGloss: 'mua gạo, bán trà',
    acceptedVietnameseAnswers: ['mua gạo bán trà'],
  ),
  CuratedHanVietPhrase(
    hanText: '水入江河',
    vietnameseGloss: 'nước đổ vào sông ngòi',
    acceptedVietnameseAnswers: ['nước chảy vào sông'],
  ),
  CuratedHanVietPhrase(
    hanText: '小魚入海',
    vietnameseGloss: 'cá nhỏ vào biển',
    acceptedVietnameseAnswers: ['những con cá nhỏ bơi ra biển'],
  ),
  CuratedHanVietPhrase(
    hanText: '大鳥飛天',
    vietnameseGloss: 'chim lớn bay lên trời',
    acceptedVietnameseAnswers: ['con chim lớn bay lên trời'],
  ),
  CuratedHanVietPhrase(
    hanText: '鳥飛天上',
    vietnameseGloss: 'chim bay trên trời',
    acceptedVietnameseAnswers: ['chim bay giữa trời'],
  ),
  CuratedHanVietPhrase(
    hanText: '風入山中',
    vietnameseGloss: 'gió vào trong núi',
    acceptedVietnameseAnswers: ['gió thổi vào núi'],
  ),
  CuratedHanVietPhrase(
    hanText: '船入江海',
    vietnameseGloss: 'thuyền vào sông biển',
    acceptedVietnameseAnswers: ['thuyền đi ra sông biển'],
  ),
  CuratedHanVietPhrase(
    hanText: '船出江海',
    vietnameseGloss: 'thuyền rời sông biển',
    acceptedVietnameseAnswers: ['thuyền đi ra sông biển'],
  ),
  CuratedHanVietPhrase(
    hanText: '兔入山林',
    vietnameseGloss: 'thỏ vào rừng núi',
    acceptedVietnameseAnswers: ['con thỏ đi vào rừng'],
  ),
  CuratedHanVietPhrase(
    hanText: '龍入江海',
    vietnameseGloss: 'rồng vào sông biển',
    isFullSentence: true,
    acceptedVietnameseAnswers: ['rồng đi vào sông biển'],
  ),
  CuratedHanVietPhrase(
    hanText: '龍飛上天',
    vietnameseGloss: 'rồng bay lên trời',
    isFullSentence: true,
    acceptedVietnameseAnswers: ['con rồng bay lên trời'],
  ),
  CuratedHanVietPhrase(
    hanText: '門開人出',
    vietnameseGloss: 'cửa mở, người đi ra',
    isFullSentence: true,
    acceptedVietnameseAnswers: ['cửa mở rồi người đi ra'],
  ),
  CuratedHanVietPhrase(
    hanText: '人多車多',
    vietnameseGloss: 'người đông, xe nhiều',
    isFullSentence: true,
    acceptedVietnameseAnswers: ['người nhiều xe nhiều'],
  ),
  CuratedHanVietPhrase(
    hanText: '七上八下',
    vietnameseGloss: 'bồn chồn, không yên',
    acceptedVietnameseAnswers: ['thất thượng bát hạ; lòng dạ không yên'],
  ),
];

String _capitalizeReading(String value) => value.isEmpty
    ? value
    : '${value.substring(0, 1).toUpperCase()}${value.substring(1)}';

/// Sinh một cặp bài dịch thuận/ngược từ cùng một cụm đã duyệt.
/// Thuận: chữ Hán -> xếp âm Hán-Việt. Ngược: âm Hán-Việt -> xếp chữ Hán.
/// Không có fallback ghép nghĩa từng chữ nếu không tìm được phrase phù hợp.
List<Question> generateCuratedTranslationQuestions(
  List<HanCharacter> exerciseCharacters, {
  required Iterable<HanCharacter> knownCharacters,
  required String sectionTitle,
  Random? random,
  int maxPhrases = 1,
  Set<String> excludedHanTexts = const <String>{},
}) {
  if (exerciseCharacters.length < 2 || maxPhrases <= 0) return <Question>[];

  final rng = random ?? Random();
  final knownBySymbol = <String, HanCharacter>{
    for (final character in knownCharacters)
      if (character.isHan) character.character: character,
  };
  final exerciseSymbols = exerciseCharacters.map((c) => c.character).toSet();
  final excluded = excludedHanTexts.map((text) => text.replaceAll(' ', '')).toSet();
  final eligible = curatedHanVietPhrases.where((phrase) {
    final symbols = phrase.symbols;
    return symbols.length >= 2 &&
        !excluded.contains(phrase.hanText) &&
        symbols.every(knownBySymbol.containsKey) &&
        symbols.any(exerciseSymbols.contains);
  }).toList();
  if (eligible.isEmpty) return <Question>[];

  final completeSentences = eligible
      .where((phrase) => phrase.isFullSentence && phrase.symbols.length >= 4)
      .toList()
    ..sort((a, b) => b.symbols.length.compareTo(a.symbols.length));
  final longPhrases = eligible
      .where((phrase) => phrase.symbols.length >= 4)
      .toList()
    ..sort((a, b) => b.symbols.length.compareTo(a.symbols.length));

  List<CuratedHanVietPhrase> selected;
  if (maxPhrases == 1) {
    // Preserve the earlier behavior for ordinary lessons: sample from a small
    // group of the strongest candidates instead of always asking the same phrase.
    final preferred = completeSentences.isNotEmpty ? completeSentences : longPhrases.isNotEmpty ? longPhrases : eligible;
    final longestLength = preferred.first.symbols.length;
    final top = preferred.where((phrase) => phrase.symbols.length >= longestLength - 1).take(5).toList();
    top.shuffle(rng);
    selected = top.take(1).toList();
  } else {
    // Challenge mode uses distinct questions and favors complete/long phrases.
    final ordered = <CuratedHanVietPhrase>[
      ...completeSentences,
      ...longPhrases.where((phrase) => !completeSentences.any((sentence) => sentence.hanText == phrase.hanText)),
      ...eligible.where((phrase) => !longPhrases.any((longPhrase) => longPhrase.hanText == phrase.hanText)),
    ];
    // Introduce randomness within a nearby length band but retain sentence priority.
    final sentences = ordered.where((phrase) => phrase.isFullSentence).toList()..shuffle(rng);
    final nonSentences = ordered.where((phrase) => !phrase.isFullSentence).toList()..shuffle(rng);
    selected = <CuratedHanVietPhrase>[];
    selected.addAll(sentences.take(maxPhrases));
    if (selected.length < maxPhrases) {
      selected.addAll(nonSentences.take(maxPhrases - selected.length));
    }
    selected = selected.toSet().toList();
  }

  final questions = <Question>[];
  for (final phrase in selected) {
    final symbols = phrase.symbols;
    final phraseCharacters = symbols.map((symbol) => knownBySymbol[symbol]!).toList();
    final readings = phraseCharacters.map((character) => character.hanVietReading.trim()).toList();
    if (readings.any((reading) => reading.isEmpty)) continue;

    final sentenceTokens = phraseCharacters.map((character) => SentenceToken(
      text: character.character,
      hanVietReading: character.hanVietReading,
      meaning: character.meaning,
    )).toList();
    final displayReading = _capitalizeReading(readings.join(' '));
    final gloss = 'Nghĩa cả cụm: ${phrase.vietnameseGloss}.';
    final first = phraseCharacters.first;

    questions.add(Question(
      type: QuestionType.translateSentence,
      sectionTitle: sectionTitle,
      prompt: 'Xếp âm Hán-Việt của cụm chữ theo đúng thứ tự.',
      options: List<String>.from(readings),
      correctAnswer: readings.join(' '),
      associatedCharacter: first.character,
      sentenceTokens: sentenceTokens,
      mnemonic: gloss,
      characterType: 'Hán',
    ));
    questions.add(Question(
      type: QuestionType.translateHanVietToCharacter,
      sectionTitle: sectionTitle,
      prompt: 'Ghép các chữ Hán tương ứng với âm Hán-Việt đã cho.',
      options: List<String>.from(symbols),
      correctAnswer: symbols.join(' '),
      associatedCharacter: first.character,
      sentenceTokens: sentenceTokens,
      sourceText: displayReading,
      mnemonic: gloss,
      characterType: 'Hán',
    ));
  }
  return questions;
}

/// Sinh câu hỏi gõ âm Hán-Việt của câu Hán văn ngắn. Nghĩa tiếng Việt chỉ là
/// phần giải thích sau khi nộp bài, tránh chấm sai các bản dịch diễn đạt khác nhau.
List<Question> generateSentenceReadingTypingQuestions({
  required Iterable<HanCharacter> targetCharacters,
  required Iterable<HanCharacter> knownCharacters,
  required int limit,
  required String sectionTitle,
  Set<String> excludedHanTexts = const <String>{},
  Random? random,
}) {
  if (limit <= 0) return <Question>[];
  final rng = random ?? Random();
  final targets = targetCharacters.where((item) => item.isHan).toList();
  if (targets.isEmpty) return <Question>[];
  final targetSymbols = targets.map((item) => item.character).toSet();
  final knownBySymbol = <String, HanCharacter>{
    for (final character in knownCharacters)
      if (character.isHan) character.character: character,
  };
  final excluded = excludedHanTexts.map((text) => text.replaceAll(' ', '')).toSet();
  final candidates = curatedHanVietPhrases.where((phrase) {
    return phrase.isFullSentence &&
        phrase.symbols.length >= 4 &&
        !excluded.contains(phrase.hanText) &&
        phrase.symbols.every(knownBySymbol.containsKey) &&
        phrase.symbols.every((symbol) => knownBySymbol[symbol]!.hanVietReading.trim().isNotEmpty) &&
        phrase.symbols.any(targetSymbols.contains) &&
        phrase.vietnameseGloss.trim().isNotEmpty;
  }).toList()
    ..sort((a, b) => b.symbols.length.compareTo(a.symbols.length));
  if (candidates.isEmpty) return <Question>[];

  // A narrow length window gives challenging questions while shuffling the
  // order prevents every session from repeating the same translation sequence.
  final longest = candidates.first.symbols.length;
  final preferred = candidates.where((phrase) => phrase.symbols.length >= longest - 2).toList()..shuffle(rng);
  final fallback = candidates.where((phrase) => phrase.symbols.length < longest - 2).toList()..shuffle(rng);
  final unique = <CuratedHanVietPhrase>[];
  final seen = <String>{};
  for (final phrase in [...preferred, ...fallback]) {
    if (seen.add(phrase.hanText)) unique.add(phrase);
  }

  return unique.take(limit).map((phrase) {
    final chars = phrase.symbols.map((symbol) => knownBySymbol[symbol]!).toList();
    final readings = chars.map((character) => character.hanVietReading.trim()).toList();
    if (readings.any((reading) => reading.isEmpty)) {
      throw StateError('Thiếu âm Hán-Việt trong câu ${phrase.hanText}');
    }
    final hanVietAnswer = readings.join(' ');
    final tokens = chars.map((character) => SentenceToken(
      text: character.character,
      hanVietReading: character.hanVietReading,
      meaning: character.meaning,
    )).toList();
    return Question(
      type: QuestionType.typingSentenceReading,
      sectionTitle: sectionTitle,
      prompt: 'Gõ âm Hán-Việt của câu Hán văn sau.',
      options: const <String>[],
      correctAnswer: hanVietAnswer,
      acceptedAnswers: <String>[hanVietAnswer],
      associatedCharacter: chars.first.character,
      sentenceTokens: tokens,
      sourceText: phrase.hanText,
      meaningExplanation: phrase.vietnameseGloss,
      mnemonic: 'Đọc theo âm Hán-Việt của từng chữ; nghĩa tiếng Việt sẽ hiện sau khi kiểm tra.',
      characterType: 'Hán',
    );
  }).toList();
}

/// Xáo trộn câu hỏi nhưng cố gắng không để cùng một chữ hoặc cùng một dạng
/// câu hỏi xuất hiện liên tiếp, giảm khả năng đoán theo vị trí.
List<Question> _shuffleQuestionsWithSeparation(List<Question> input, Random random) {
  final remaining = List<Question>.from(input)..shuffle(random);
  final result = <Question>[];
  while (remaining.isNotEmpty) {
    final previous = result.isEmpty ? null : result.last;
    var choices = <int>[];
    for (var i = 0; i < remaining.length; i++) {
      final candidate = remaining[i];
      if (previous != null && candidate.associatedCharacter == previous.associatedCharacter) continue;
      if (previous != null && candidate.type == previous.type) continue;
      choices.add(i);
    }
    if (choices.isEmpty) {
      for (var i = 0; i < remaining.length; i++) {
        if (previous == null || remaining[i].associatedCharacter != previous.associatedCharacter) choices.add(i);
      }
    }
    if (choices.isEmpty) choices = List<int>.generate(remaining.length, (i) => i);
    final selectedIndex = choices[random.nextInt(choices.length)];
    result.add(remaining.removeAt(selectedIndex));
  }
  return result;
}

/// Sinh câu hỏi cho cấu trúc một Node gồm 3 phần.
/// Node Hán có 10 chữ: Phần 1 học 5 chữ đầu, Phần 2 học 5 chữ sau,
/// Phần 3 ôn toàn bộ 10 chữ và yêu cầu tự gõ âm Hán-Việt. Bộ sinh câu hỏi này
/// cũng được dùng cho Tổng Ôn tập và Học vượt để đồng bộ định dạng tương tác.
List<Question> generateLessonPartQuestions(
  List<HanCharacter> allLessonCharacters, {
  required int part,
  Iterable<HanCharacter>? knownCharacters,
  Random? random,
  int translationPhraseLimit = 1,
  int sentenceTypingLimit = 0,
}) {
  if (part < 1 || part > 3) {
    throw ArgumentError.value(part, 'part', 'Phải nằm trong khoảng 1–3.');
  }
  if (allLessonCharacters.isEmpty) return <Question>[];

  final rng = random ?? Random();
  final splitAt = (allLessonCharacters.length ~/ 2).clamp(1, allLessonCharacters.length).toInt();
  final targetCharacters = part == 1
      ? allLessonCharacters.take(splitAt).toList()
      : part == 2
          ? allLessonCharacters.skip(splitAt).toList()
          : allLessonCharacters.toList();
  final effectiveTargets = targetCharacters.isEmpty ? allLessonCharacters : targetCharacters;
  final questions = <Question>[];
  final partName = 'Phần $part/3';
  const fallback = <String>['một', 'hai', 'ba', 'người', 'trời', 'đất', 'nước', 'núi', 'cây', 'lửa'];

  List<String> optionsFor(String answer, Iterable<String> candidates) {
    final pool = candidates.map((value) => value.trim()).where((value) => value.isNotEmpty).toSet().toList();
    if (!pool.contains(answer)) pool.add(answer);
    for (final value in fallback) {
      if (pool.length >= 4) break;
      if (value != answer && !pool.contains(value)) pool.add(value);
    }
    final distractors = pool.where((value) => value != answer).toList()..shuffle(rng);
    final result = <String>[answer, ...distractors.take(3)]..shuffle(rng);
    return result;
  }

  List<HanCharacter> sameTypeFor(HanCharacter character) =>
      seedCharacters.where((candidate) => candidate.type == character.type).toList();

  Question makeReadingQuestion(HanCharacter character) {
    final candidates = sameTypeFor(character).map((item) => item.hanVietReading);
    return Question(
      type: QuestionType.reading,
      sectionTitle: '$partName · Âm Hán-Việt',
      prompt: character.isNom
          ? 'Cách đọc tiếng Việt của chữ Nôm ${character.character} là gì?'
          : 'Âm Hán-Việt của chữ ${character.character} là gì?',
      options: optionsFor(character.hanVietReading, candidates),
      correctAnswer: character.hanVietReading,
      associatedCharacter: character.character,
      mnemonic: character.mnemonic,
      characterType: character.type,
    );
  }

  Question makeCharacterQuestion(HanCharacter character) {
    final candidates = sameTypeFor(character).map((item) => item.character);
    return Question(
      type: QuestionType.character,
      sectionTitle: '$partName · Nhận diện chữ',
      prompt: 'Chữ nào có nghĩa “${character.meaning}”?',
      options: optionsFor(character.character, candidates),
      correctAnswer: character.character,
      associatedCharacter: character.character,
      mnemonic: character.mnemonic,
      characterType: character.type,
    );
  }

  if (part < 3) {
    // Giới thiệu từ mới: chữ lớn có tooltip và 4 thẻ nghĩa tiếng Việt.
    for (final character in effectiveTargets) {
      final meanings = sameTypeFor(character).map((item) => item.meaning);
      questions.add(Question(
        type: QuestionType.introduceWord,
        sectionTitle: '$partName · Từ mới',
        prompt: 'Chọn nghĩa đúng của chữ sau.',
        options: optionsFor(character.meaning, meanings),
        correctAnswer: character.meaning,
        associatedCharacter: character.character,
        sentenceTokens: [SentenceToken(
          text: character.character,
          hanVietReading: character.hanVietReading,
          meaning: character.meaning,
        )],
        mnemonic: character.mnemonic,
        characterType: character.type,
      ));
      questions.add(makeReadingQuestion(character));
      questions.add(makeCharacterQuestion(character));
    }
  } else {
    // Mỗi chữ vẫn có một câu gõ âm, nhưng không cố định cả ba dạng câu
    // liền nhau cho từng chữ. Thứ tự chữ và dạng nhận diện được xáo trộn;
    // chỉ hai chữ được chọn ngẫu nhiên có thêm câu nhận diện chiều ngược.
    final reviewOrder = List<HanCharacter>.from(effectiveTargets)..shuffle(rng);
    final extraChecks = <String>{};
    if (reviewOrder.length > 2) {
      final candidates = List<HanCharacter>.from(reviewOrder)..shuffle(rng);
      extraChecks.addAll(candidates.take(min(2, candidates.length).toInt()).map((item) => item.character));
    }
    for (var index = 0; index < reviewOrder.length; index++) {
      final character = reviewOrder[index];
      final useReading = index.isEven;
      questions.add(useReading ? makeReadingQuestion(character) : makeCharacterQuestion(character));
      questions.add(Question(
        type: QuestionType.typing,
        sectionTitle: '$partName · Ghi nhớ chủ động',
        prompt: 'Gõ âm Hán-Việt của chữ ${character.character}.',
        options: const <String>[],
        correctAnswer: character.hanVietReading,
        acceptedAnswers: <String>[character.hanVietReading.trim().toLowerCase()],
        associatedCharacter: character.character,
        mnemonic: character.mnemonic,
        characterType: character.type,
      ));
      if (extraChecks.contains(character.character)) {
        questions.add(useReading ? makeCharacterQuestion(character) : makeReadingQuestion(character));
      }
    }
  }

  // Nối cặp được thêm ở cuối phần, không đưa chữ ngoài nhóm đang học vào câu hỏi.
  if (effectiveTargets.length >= 2) {
    final pairs = <String, String>{};
    final usedLabels = <String>{};
    for (final character in effectiveTargets) {
      final shortMeaning = character.meaning.split(RegExp(r'[,;]')).first.trim();
      final label = '${character.hanVietReading} · $shortMeaning';
      if (label.trim().isEmpty || !usedLabels.add(label)) continue;
      pairs[character.character] = label;
      if (pairs.length >= min(4, effectiveTargets.length)) break;
    }
    if (pairs.length >= 2) {
      final first = effectiveTargets.firstWhere((item) => pairs.containsKey(item.character));
      questions.add(Question(
        type: QuestionType.matchingPairs,
        sectionTitle: '$partName · Nối cặp',
        prompt: 'Nối mỗi chữ với âm Hán-Việt và nghĩa tương ứng.',
        options: const <String>[],
        correctAnswer: '__all_matching_pairs_completed__',
        associatedCharacter: first.character,
        matchingPairs: pairs,
        mnemonic: first.mnemonic,
        characterType: first.type,
      ));
    }

    // Chỉ thêm câu dịch khi tìm được phrase đã duyệt và mọi chữ đã được học.
    questions.addAll(generateCuratedTranslationQuestions(
      effectiveTargets,
      knownCharacters: knownCharacters ?? effectiveTargets,
      sectionTitle: '$partName · Dịch hai chiều',
      random: rng,
      maxPhrases: translationPhraseLimit,
    ));
    if (part == 3 && sentenceTypingLimit > 0) {
      final usedPhrases = questions
          .where((question) => question.type == QuestionType.translateSentence ||
              question.type == QuestionType.translateHanVietToCharacter)
          .map((question) => question.sentenceTokens?.map((token) => token.text).join() ?? '')
          .where((text) => text.isNotEmpty)
          .toSet();
      questions.addAll(generateSentenceReadingTypingQuestions(
        targetCharacters: effectiveTargets,
        knownCharacters: knownCharacters ?? effectiveTargets,
        limit: sentenceTypingLimit,
        sectionTitle: '$partName · Gõ âm Hán-Việt câu văn',
        excludedHanTexts: usedPhrases,
        random: rng,
      ));
    }
  }

  if (part == 3) return _shuffleQuestionsWithSeparation(questions, rng);
  return questions;
}


enum ReviewChallengeMode { dailyReview, checkpoint, jumpAhead }

/// Câu hỏi khó hơn cho ôn tập, Tổng Ôn tập và Học vượt.
/// Mọi chế độ dùng chung động cơ Phần 3/3; chế độ Học vượt được ưu tiên câu gõ nghĩa.
List<Question> generateAdvancedReviewQuestions({
  required List<HanCharacter> characters,
  required Iterable<HanCharacter> knownCharacters,
  required ReviewChallengeMode mode,
  Random? random,
}) {
  if (characters.isEmpty) return <Question>[];
  final rng = random ?? Random();
  final uniqueCharacters = <String, HanCharacter>{
    for (final character in characters)
      if (character.isHan) character.character: character,
  }.values.toList();
  if (uniqueCharacters.isEmpty) return <Question>[];

  final int translationLimit;
  final int sentenceTypingLimit;
  final String prefix;
  switch (mode) {
    case ReviewChallengeMode.dailyReview:
      translationLimit = 2;
      sentenceTypingLimit = 4;
      prefix = 'Ôn tập';
      break;
    case ReviewChallengeMode.checkpoint:
      translationLimit = 3;
      sentenceTypingLimit = 9;
      prefix = 'Tổng Ôn tập';
      break;
    case ReviewChallengeMode.jumpAhead:
      translationLimit = 3;
      sentenceTypingLimit = 16;
      prefix = 'Học vượt';
      break;
  }

  final questions = generateLessonPartQuestions(
    uniqueCharacters,
    part: 3,
    knownCharacters: knownCharacters,
    random: rng,
    translationPhraseLimit: translationLimit,
    sentenceTypingLimit: 0,
  );
  final usedPhrases = questions
      .where((question) => question.type == QuestionType.translateSentence ||
          question.type == QuestionType.translateHanVietToCharacter)
      .map((question) => question.sentenceTokens?.map((token) => token.text).join() ?? '')
      .where((text) => text.isNotEmpty)
      .toSet();
  questions.addAll(generateSentenceReadingTypingQuestions(
    targetCharacters: uniqueCharacters,
    knownCharacters: knownCharacters,
    limit: sentenceTypingLimit,
    sectionTitle: '$prefix · Gõ âm Hán-Việt câu văn',
    excludedHanTexts: usedPhrases,
    random: rng,
  ));

  // Keep challenge interaction mixed rather than showing blocks of one type.
  return _shuffleQuestionsWithSeparation(questions, rng);
}

List<Question> generateQuestions(
  List<HanCharacter> lessonCharacters, {
  bool jumpAheadMode = false,
  bool reviewCheckpointMode = false,
  Iterable<HanCharacter>? knownCharacters,
  Random? random,
}) {
  // Backward-compatible flags now route into the same Part 3 engine used by
  // the lesson screen, preventing any call site from using the legacy quiz format.
  if (jumpAheadMode || reviewCheckpointMode) {
    return generateLessonPartQuestions(
      lessonCharacters,
      part: 3,
      knownCharacters: knownCharacters ?? lessonCharacters,
      random: random,
    );
  }

  final rng = random ?? Random();
  final part1Radicals = <Question>[];
  final part2Characters = <Question>[];
  final part3Typing = <Question>[];
  final part4Interactive = <Question>[];
  const fallbackRadicals = <String>['一', '人', '心', '水', '木', '火', '口', '日', '手', '目'];

  List<String> optionsFor(String answer, Iterable<String> candidates) {
    final pool = candidates.toSet().where((value) => value.trim().isNotEmpty).toList();
    if (!pool.contains(answer)) pool.add(answer);
    for (final fallback in fallbackRadicals) {
      if (pool.length >= 4) break;
      if (fallback != answer && !pool.contains(fallback)) pool.add(fallback);
    }
    final distractors = pool.where((value) => value != answer).toList()..shuffle(rng);
    final options = <String>[answer, ...distractors.take(3)]..shuffle(rng);
    return options;
  }

  for (final character in lessonCharacters) {
    // Trắc nghiệm dùng các phương án cùng loại để không vô tình đưa Nôm vào bài Hán.
    final sameTypeCharacters = seedCharacters.where((candidate) => candidate.type == character.type).toList();
    final readings = sameTypeCharacters.map((c) => c.hanVietReading).toSet();
    final symbols = sameTypeCharacters.map((c) => c.character).toSet();
    final radicals = sameTypeCharacters.map((c) => c.radical).toSet();
    final characterType = character.type;
    final isNom = character.isNom;

    // PHẦN 1: NHẬN DIỆN BỘ THỦ / THÀNH PHẦN GỢI NGHĨA.
    part1Radicals.add(Question(
      type: QuestionType.radical,
      sectionTitle: 'Phần 1: Nhận diện cấu tạo',
      prompt: isNom
          ? 'Thành phần Hán tự gợi nghĩa trong chữ Nôm ${character.character} là gì?'
          : 'Bộ thủ của chữ Hán ${character.character} (${character.hanVietReading}) là gì?',
      options: optionsFor(character.radical, [...radicals, ...fallbackRadicals]),
      correctAnswer: character.radical,
      associatedCharacter: character.character,
      mnemonic: character.mnemonic,
      characterType: characterType,
    ));

    // PHẦN 2: HÁN-VIỆT hoặc cách đọc tiếng Việt của chữ Nôm.
    final readingQuestion = Question(
      type: QuestionType.reading,
      sectionTitle: isNom ? 'Phần 2: Đọc chữ Nôm' : 'Phần 2: Học Âm & Nghĩa',
      prompt: isNom
          ? 'Cách đọc tiếng Việt của chữ Nôm ${character.character} là gì?'
          : 'Âm Hán-Việt của chữ ${character.character} là gì?',
      options: optionsFor(character.hanVietReading, readings),
      correctAnswer: character.hanVietReading,
      associatedCharacter: character.character,
      mnemonic: character.mnemonic,
      characterType: characterType,
    );

    final characterQuestion = Question(
      type: QuestionType.character,
      sectionTitle: isNom ? 'Phần 2: Nhận diện chữ Nôm' : 'Phần 2: Học Âm & Nghĩa',
      prompt: isNom
          ? 'Chữ Nôm nào có nghĩa “${character.meaning}”?'
          : 'Chữ nào có nghĩa “${character.meaning}”?',
      options: optionsFor(character.character, symbols),
      correctAnswer: character.character,
      associatedCharacter: character.character,
      mnemonic: character.mnemonic,
      characterType: characterType,
    );

    part2Characters.add(readingQuestion);
    part2Characters.add(characterQuestion);

    if (!isNom && character.character == '學') {
      part2Characters.add(Question(
        type: QuestionType.fillInTheBlank,
        sectionTitle: 'Phần 2: Học Âm & Nghĩa',
        prompt: 'Chọn chữ còn thiếu để tạo thành từ ghép “học sinh”.',
        options: optionsFor('生', const ['生', '日', '山', '水']),
        correctAnswer: '生',
        associatedCharacter: character.character,
        mnemonic: character.mnemonic,
        characterType: characterType,
        sentenceTokens: const [
          SentenceToken(text: '學', hanVietReading: 'học', meaning: 'học tập'),
          SentenceToken(text: '生', isBlank: true),
        ],
      ));
    }

    // PHẦN 3: TỰ GÕ ĐÁP ÁN.
    final answerCandidates = <String>{
      character.hanVietReading.trim().toLowerCase(),
      character.meaning.trim().toLowerCase(),
    }.where((value) => value.isNotEmpty).toList();
    part3Typing.add(Question(
      type: QuestionType.typing,
      sectionTitle: 'Phần 3: Kiểm tra trí nhớ',
      prompt: isNom
          ? 'Gõ cách đọc tiếng Việt hoặc nghĩa của chữ Nôm ${character.character}:'
          : 'Gõ âm Hán-Việt hoặc nghĩa của chữ ${character.character}:',
      options: const [],
      correctAnswer: isNom ? character.hanVietReading : character.hanVietReading,
      acceptedAnswers: answerCandidates,
      associatedCharacter: character.character,
      mnemonic: character.mnemonic,
      characterType: characterType,
    ));
  }

  // PHẦN 4: CÁC DẠNG TƯƠNG TÁC. Những chế độ Tổng Ôn tập/Học vượt đã được
  // chuyển sang Part 3 ở đầu hàm, nên bộ sinh mặc định dành cho bài học thường.
  if (lessonCharacters.length >= 2) {
    final trackCharacters = lessonCharacters.toList();

    // Nối 2–4 chữ với âm Hán-Việt và nghĩa. Kết hợp âm + nghĩa để tránh
    // trường hợp hai chữ đồng âm/đồng nghĩa khiến cặp nối bị mơ hồ.
    final matchingPairs = <String, String>{};
    final usedLabels = <String>{};
    for (final item in trackCharacters) {
      final shortMeaning = item.meaning.split(RegExp(r'[,;]')).first.trim();
      final label = '${item.hanVietReading} · $shortMeaning';
      if (label.trim().isEmpty || !usedLabels.add(label)) continue;
      matchingPairs[item.character] = label;
      if (matchingPairs.length >= min(4, trackCharacters.length)) break;
    }

    if (matchingPairs.length >= 2) {
      final first = trackCharacters.firstWhere((item) => matchingPairs.containsKey(item.character));
      part4Interactive.add(Question(
        type: QuestionType.matchingPairs,
        sectionTitle: 'Phần 4: Luyện tập tương tác',
        prompt: 'Nối mỗi chữ với âm Hán-Việt và nghĩa tương ứng.',
        options: const <String>[],
        correctAnswer: '__all_matching_pairs_completed__',
        associatedCharacter: first.character,
        characterType: first.type,
        matchingPairs: matchingPairs,
        mnemonic: first.mnemonic,
      ));
    }

    // Chỉ sinh bài dịch từ ngân hàng cụm/câu đã kiểm duyệt. Các ký tự của
    // phrase phải nằm trong phạm vi người học đã tiếp cận.
    part4Interactive.addAll(generateCuratedTranslationQuestions(
      lessonCharacters,
      knownCharacters: knownCharacters ?? lessonCharacters,
      sectionTitle: 'Phần 4: Dịch hai chiều',
      random: rng,
    ));
  }

  part1Radicals.shuffle(rng);
  part2Characters.shuffle(rng);
  part3Typing.shuffle(rng);
  // Các câu tương tác đặt cuối bài học thường để người học làm quen thao tác
  // trắc nghiệm/gõ trước, rồi chuyển sang nối cặp và dịch bằng word bank.
  return [...part1Radicals, ...part2Characters, ...part3Typing, ...part4Interactive];
}

