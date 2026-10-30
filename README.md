# Hán-Việt Duo — Flutter MVP

### Lưu ý chạy dự án

- ZIP mã nguồn không đóng gói font TTF. Font Nom Na Tong là tùy chọn; nếu chưa có, app dùng fallback CJK của hệ điều hành/trình duyệt.
- Trên Windows, chạy `setup_and_run.bat` để tạo scaffold Android/Web/Windows nếu thiếu, cấu hình font đang có, chạy kiểm tra asset, lấy dependencies và khởi động Flutter.
- Nếu muốn chạy trực tiếp bằng lệnh Flutter, trước đó cần tạo platform scaffold (`flutter create . --platforms=web,android,windows`) và chạy `python scripts/configure_optional_fonts.py`.

## Bản cập nhật v2.6.3+20

- Đủ ít nhất một Pinyin và một On’yomi cho cả 250 chữ giáo trình; dữ liệu đa âm phổ biến được mở rộng.
- Phần 3 giảm lặp câu nhận diện cố định, vẫn yêu cầu gõ âm Hán-Việt cho mỗi chữ. Với câu Hán văn, người học gõ âm Hán-Việt; sau khi nộp mới hiện nghĩa tiếng Việt tham khảo.
- Ôn sau bài: tối đa 4 câu gõ âm Hán-Việt của câu; Tổng Ôn tập: tối đa 9; Học vượt: tối đa 16. Sau khi nộp, app mới hiện nghĩa tiếng Việt tham khảo và nếu sai sẽ hiện âm Hán-Việt chính xác.
- Lần mở app đầu tiên có popup chọn ngôn ngữ đọc bổ sung với cờ 🇻🇳 🇨🇳 🇯🇵; có thể bỏ qua và đổi lại trong Hồ sơ. Hán-Hàn 🇰🇷 và Quảng Đông 🇭🇰 hiện chỉ được hiển thị là dự kiến.
- Xem `CHANGELOG.md` và `assets/data/READINGS_DATA_NOTES.md` để biết chi tiết và giới hạn dữ liệu âm đọc.


Phiên bản mã nguồn **2.6.3+20**. Ứng dụng học Hán tự theo âm Hán-Việt, lưu tiến độ trên thiết bị bằng `shared_preferences` và không cần máy chủ.

## Câu dịch Hán-Việt hai chiều (2.6.0)

- **Dịch thuận:** hiển thị cụm chữ Hán, người học xếp các âm Hán-Việt đúng thứ tự. `朋友` dùng `bằng hữu`, không ghép nghĩa riêng của từng chữ thành “bạn bè bạn”.
- **Dịch ngược:** hiển thị văn bản âm Hán-Việt, người học chọn/kéo các ô chữ Hán để khôi phục văn bản gốc. Ví dụ `Bằng hữu` -> `朋 友`.
- Cụm dài như `南國山河`, `日出東方`, `父母愛子`, `大江東去`, `四海一家`, `五湖四海`, `江河湖海`, `山河大地`, `一日千秋`, `白日青天`, `青山綠水`, `花前月下` được ưu tiên khi đủ ký tự trong phạm vi đã học. Câu ví dụ giải nghĩa ở phản hồi sai là nghĩa cả cụm, không thay thế cách đọc Hán-Việt.
- Nếu không có câu/cụm được duyệt phù hợp, câu dịch bị bỏ qua. Đây là lựa chọn có chủ ý để tránh hiển thị chuỗi chữ gượng ép hoặc ký tự người học chưa biết.

## Lộ trình theo chủ đề (2.6.0)

- Node 1: số đếm 一–十; các Node tiếp theo gom đủ 250 chữ Hán hiện hữu theo các chủ đề như số lượng/kích thước, phương hướng, vị trí, gia đình/xã hội, cơ thể, di chuyển, giao tiếp, trời/đất, thời tiết, cây cối, động vật, thời gian, cảm xúc, màu sắc, ăn uống, vật dụng và tư duy.
- Mỗi Node Hán gồm 10 chữ mới. Phần 1 giới thiệu/luyện 5 chữ đầu; Phần 2 giới thiệu/luyện 5 chữ sau; Phần 3 ôn 10 chữ và có câu gõ âm Hán-Việt.
- Bài dịch không còn ghép nghĩa từng chữ để tạo bản dịch máy móc. Chỉ sinh bài dịch với cụm/câu Hán-Việt có trong `curatedHanVietPhrases`; ví dụ `朋友` -> `bằng hữu`, `南國山河` -> `nam quốc sơn hà`, `父母愛子` -> `phụ mẫu ái tử`. Nếu chưa có cụm phù hợp hoặc có chữ chưa được học, bỏ bài dịch đó.
- Có hai chiều dùng cùng một phrase: chữ Hán -> xếp âm Hán-Việt và âm Hán-Việt -> xếp các ô chữ Hán tương ứng. Các ô có thể chạm hoặc kéo thả.
- Cả 250 chữ Hán được phân vào đúng một Node duy nhất. Dữ liệu âm Hán-Việt/nghĩa vẫn lấy từ bản ghi seed/từ điển hiện có; không tạo thêm mục từ mới.
- Khi nâng cấp từ cấu trúc 50 Node cũ, tiến độ Hán/Tổng Ôn tập được quy đổi xấp xỉ theo số chữ đã học; Node đang học được mở lại từ Phần 1 do nội dung đã đổi. Tiến độ học và dữ liệu chữ Nôm cũ được tạm xóa trong lúc chờ chuẩn hóa.

## Tổng Ôn tập, Học vượt và dữ liệu Nôm (2.6.0)

- **Tổng Ôn tập** thay nhãn bài thi Boss cũ. Sau mỗi 5 Node Hán, chọn ngẫu nhiên 20 chữ duy nhất trong 50 chữ của đúng 5 Node vừa học. Bộ sinh câu hỏi dùng định dạng Phần 3 của bài học, bao gồm nhận diện, gõ âm Hán-Việt, nối cặp và xếp nghĩa.
- **Học vượt** chọn 10 chữ ngẫu nhiên từ toàn bộ các Node đứng trước Node mục tiêu. Nếu mục tiêu là Node 1 thì không có bài học vượt vì chưa có chữ ở các Node trước đó. Bộ câu hỏi dùng định dạng Phần 3.
- **Tạm gỡ dữ liệu Nôm:** seed hoạt động chỉ chứa 250 chữ Hán; ba Node Nôm được giữ dưới dạng khung rỗng để giữ mã giao diện và luồng bài học. Native SQLite xóa bản ghi Nôm đã lưu từ phiên bản trước; Flutter Web không nạp lại các mục đó.
- `lib/data/legacy_nom_codepoints.dart` chỉ chứa mã Unicode cũ dùng cho tác vụ dọn dữ liệu, không chứa âm đọc/nghĩa và không tham gia tìm kiếm hay sinh câu hỏi. Code màn Nôm, bộ lọc từ điển, model `HanCharacter`, widget bài học và công cụ nhập/chuẩn hóa từ điển vẫn được giữ nguyên.
- Khi nâng cấp, tiến độ Nôm và mastery của mã Nôm cũ được bỏ; tiến độ Hán, XP, tim, đá quý, chuỗi ngày và mastery của các ký tự khác được giữ nguyên.

## Font chữ Hán–Nôm Nom Na Tong v5.18 (tùy chọn)

Font Nom Na Tong là fallback tùy chọn, không bắt buộc để chạy app. Nếu chưa có file TTF, giao diện dùng font CJK có sẵn của hệ điều hành/trình duyệt. ZIP không đóng gói font nhị phân.

Khi chạy `setup_and_run.bat`, script sẽ thử tải font từ [bản phát hành chính thức v5.18](https://github.com/nomfoundation/font/releases/tag/v5.18), kiểm tra SHA-256 rồi đăng ký font nếu file có mặt. Nếu mạng không tải được, script vẫn tiếp tục với font hệ thống. Có thể tải thủ công từ [NomNaTong-Regular.ttf](https://github.com/nomfoundation/font/releases/download/v5.18/NomNaTong-Regular.ttf), đặt vào `assets/fonts/NomNaTong-Regular.ttf`, rồi chạy `python scripts/configure_optional_fonts.py`, `flutter clean` và `flutter pub get`. Giấy phép MIT được lưu tại `assets/fonts/LICENSE-NomNaTong.txt`.
