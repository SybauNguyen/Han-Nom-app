# Changelog

## Version 2.6.3+20 — đọc câu bằng âm Hán-Việt và chọn ngôn ngữ lần đầu

- Đổi bài gõ câu Hán văn: người học nhập âm Hán-Việt theo thứ tự chữ, thay vì phải đoán một bản dịch tiếng Việt duy nhất.
- Sau khi nộp câu trả lời, dù đúng hay sai, giao diện mới hiện nghĩa tiếng Việt tham khảo. Nếu sai, luôn hiện đáp án âm Hán-Việt chuẩn; nghĩa tiếng Việt không còn dùng làm điều kiện chấm bài.
- Thêm kiểm thử hồi quy cho `長江入海` → `trường giang nhập hải`, nghĩa tham khảo “Trường Giang đổ ra biển”.
- Thêm popup chọn ngôn ngữ đọc bổ sung ở lần mở app đầu tiên: 🇻🇳 Chỉ Hán-Việt, 🇨🇳 Quan thoại/giản thể, 🇯🇵 Hán-Nhật. Có nút bỏ qua; lựa chọn và trạng thái đã xem được lưu cục bộ.
- Thêm cờ nhận diện cạnh từng lựa chọn; Hán-Hàn 🇰🇷 và Quảng Đông 🇭🇰 hiển thị là tính năng dự kiến, chưa bật.
- Có thể đổi ngôn ngữ trong Hồ sơ như trước; thay đổi này cũng đánh dấu popup lần đầu đã hoàn tất. Không thay đổi XP, tim, mastery hay tiến độ bài học.

## Version 2.6.2+19 — hoàn thiện âm đọc và tăng độ khó ôn tập

- Bổ sung Pinyin Quan thoại và On’yomi Hán-Nhật cho đủ 250/250 chữ thuộc giáo trình; thêm các cách đọc phổ biến khác cho một nhóm chữ đa âm như 好、重、長、樂、分、給 và 覺.
- Dữ liệu chữ giản thể và tân tự thể tiếp tục được lưu tách biệt. Các trường đọc dùng danh sách để sau này có thể mở rộng thêm cách đọc theo từ/ngữ cảnh.
- Mở rộng ngân hàng câu/vế Hán văn và cụm thành ngữ được biên tập, có đáp án tiếng Việt cùng các biến thể chấp nhận; bài gõ nghĩa chỉ chọn những mục được đánh dấu phù hợp và mọi chữ phải nằm trong phạm vi người học đã mở.
- Bài Phần 3 giảm việc lặp cứng ba dạng câu cho từng chữ: vẫn có câu gõ âm Hán-Việt cho toàn bộ chữ, nhưng phân bổ nhận diện âm/nghĩa theo thứ tự ngẫu nhiên và chỉ thêm hai câu kiểm tra chéo.
- Ôn tập sau bài tăng lên tối đa 4 câu gõ nghĩa câu văn; Tổng Ôn tập tối đa 9 câu; Học vượt tối đa 16 câu gõ nghĩa câu văn và 3 phrase dịch hai chiều. Câu chữ được chọn không lặp trong cùng một lượt và xáo trộn để khó đoán thứ tự.
- Tổng Ôn tập, Học vượt, ôn hằng ngày, bài thường và bài mở lại dùng chung động cơ Phần 3/3; phần Học vượt ưu tiên gõ nghĩa câu văn nhiều nhất.
- Tinh chỉnh chọn chữ ôn hằng ngày: giữ ưu tiên chữ có mastery thấp và xáo trộn trong cùng nhóm mastery, không sắp xếp lại toàn bộ danh sách sau khi đã trộn.
- Thêm kiểm thử cho độ phủ Pinyin/On’yomi trên toàn bộ 250 chữ, cách đọc đa âm, mức độ câu dịch và việc mọi câu dùng chữ trong curriculum.

**Ghi chú dữ liệu:** mọi chữ giáo trình hiện có ít nhất một Pinyin và một On’yomi đã được nhập, nhưng đây chưa phải danh mục đầy đủ tất cả cách đọc. Các cách đọc chính và biến thể được biên tập thủ công, cần tiếp tục đối chiếu từ điển/nguồn chuẩn trước khi phát hành rộng rãi.

## Version 2.6.1+18 — nền dữ liệu đa ngôn ngữ CJKV

- Bổ sung model `CjkCharacter` với danh sách nhiều cách đọc và hình thể chữ truyền thống, giản thể Trung Quốc, tân tự thể Nhật.
- Quan thoại (Pinyin) và Hán-Nhật (On'yomi) được phát triển song song; giao diện cho phép chọn tối đa một hệ thống đọc bổ sung trong Hồ sơ.
- Âm đọc bổ sung xuất hiện trong thẻ chi tiết chữ và tooltip của chữ trong phần giới thiệu từ mới.
- Thêm `master_dictionary.json`, `cjk_readings_overrides.json` và script `scripts/build_master_dictionary.py` để ghép dữ liệu seed hiện có với các âm đọc đã nhập.
- SQLite native nâng lên schema v5 theo kiểu cộng thêm bảng `cjk_characters`; không xóa bảng học tập hiện có, không reset mastery/XP/tim/tiến độ. Web/Edge dùng cùng API với catalogue trong bộ nhớ.
- **Giới hạn dữ liệu:** bộ hiện tại có 269 bản ghi CJKV; 117 bản ghi có dữ liệu Pinyin và On'yomi khởi đầu. Các mục chưa có âm đọc vẫn để trống, không tự đoán. Dữ liệu mở đầu cần được đối chiếu nguồn từ điển chuẩn trước khi phát hành rộng rãi.

## 2.6.0+17 — Câu dịch Hán-Việt có kiểm duyệt và dịch ngược sang chữ Hán

- Loại bỏ cơ chế fallback ghép nghĩa riêng lẻ của hai chữ thành câu, vốn có thể tạo đáp án gượng như “bạn bè bạn”.
- Thêm ngân hàng cụm/câu Hán-Việt được duyệt thủ công; ví dụ `朋友` sinh đáp án `bằng hữu`, `南國山河` sinh `nam quốc sơn hà`, `父母愛子` sinh `phụ mẫu ái tử` khi toàn bộ chữ đã được học.
- Ưu tiên câu dài có cấu trúc hoàn chỉnh; nếu chưa đủ ký tự đã học thì chọn cụm Hán-Việt thông dụng phù hợp. Nếu không có cụm nào hợp lệ thì không sinh bài dịch, thay vì ghép chữ ngẫu nhiên.
- Mọi câu dịch phải có tất cả ký tự nằm trong kho kiến thức đã mở; Học vượt và Tổng Ôn tập chỉ dùng câu phù hợp với phạm vi chữ trước đó.
- Thêm dạng ngược **âm Hán-Việt -> ghép chữ Hán** bằng các ô chữ có thể chạm/kéo, sử dụng cùng một phrase với dạng dịch thuận để đảm bảo đáp án nhất quán.
- Mở rộng ngân hàng cụm/câu nhiều chữ như `大江東去`, `四海一家`, `五湖四海`, `江河湖海`, `山河大地`, `一日千秋`, `白日青天`; mỗi mục được kiểm tra toàn bộ ký tự trong seed 250 chữ hiện có.
- Ưu tiên câu hoàn chỉnh trước, rồi xếp theo độ dài; chọn ngẫu nhiên trong nhóm tốt nhất để giảm lặp lại.
- Bổ sung kiểm thử cho `朋友 -> bằng hữu`, dạng dịch ngược `Bằng hữu -> 朋 友`, ưu tiên câu dài, đồng bộ số câu và loại bỏ trường hợp chưa đủ chữ.

## 2.5.0+16 — Đồng bộ Tổng Ôn tập/Học vượt và tạm gỡ dữ liệu Nôm

- Đổi nhãn mốc Boss thành **Tổng Ôn tập** trong cây Hán; mô tả rõ mỗi mốc lấy 20 chữ ngẫu nhiên trong 50 chữ của 5 Node vừa học.
- Tổng Ôn tập dùng bộ sinh câu hỏi Phần 3 như bài học: nhận diện chữ/âm/nghĩa, gõ âm Hán-Việt, nối cặp và xếp nghĩa, không dùng bộ câu hỏi Boss rút gọn cũ.
- Học vượt lấy 10 chữ ngẫu nhiên duy nhất từ các Node đứng trước Node mục tiêu và dùng cùng format Phần 3; Node 1 không có chữ trước đó để thi vượt.
- Gỡ 29 mục Nôm khỏi seed, lộ trình chủ động và danh sách ký tự curriculum; giữ khung 3 Node Nôm rỗng, màn hình, model, widget và logic từ điển để tích hợp dữ liệu chuẩn sau này.
- Khi khởi động trên nền tảng native, dọn bản ghi Nôm cũ khỏi SQLite bằng nhãn loại và các mã Unicode đã nghỉ dùng; bộ nạp từ điển web/native không nạp lại các mã cũ.
- Xóa tiến độ Nôm cũ và mastery của 29 mã Unicode đã gỡ nhưng giữ tiến độ Hán, XP, tim, đá quý, chuỗi ngày và các mastery khác.
- Cập nhật test cho 20 chữ Tổng Ôn tập, 10 chữ Học vượt, format Phần 3 và dữ liệu Nôm đã tạm ẩn.

## 2.4.0+15 — Lộ trình 10 chữ theo chủ đề

- Tái cấu trúc 250 chữ Hán hiện hữu thành 25 Node theo chủ đề, mỗi Node có đúng 10 chữ mới; Node đầu tiên là số đếm 一–十.
- Giữ nguyên mô hình 3 phần: 5 chữ đầu, 5 chữ tiếp theo, rồi ôn toàn bộ 10 chữ kèm gõ âm Hán-Việt.
- Đổi lộ trình Boss từ 10 mốc thành 5 mốc, vẫn xuất hiện sau mỗi 5 Node và bài Boss vẫn 24 câu.
- Gom 29 chữ Nôm thành 3 nhóm; bài Nôm cuối có 9 chữ duy nhất và một lượt ôn chữ số 5, không bổ sung mục từ giả.
- Cập nhật truy vấn SQLite để lấy đúng các ký tự theo Node chủ đề, đổi giới hạn truy vấn Boss/thi học vượt theo 10 chữ/Node.
- Thêm migration một lần từ lộ trình cũ 50×5 sang 25×10 để giữ tiến độ tương đối; Node đang học được mở lại từ Phần 1.
- Bổ sung test cấu trúc 25 Node, độ phủ 250 chữ Hán, số chữ mỗi phần và migration tiến độ.

## 2.3.0+14 — Node bài học 3 phần

- Thêm `currentLessonPart` vào trạng thái ứng dụng và lưu/khôi phục qua SharedPreferences; Node Hán chỉ được tính hoàn thành sau Phần 3.
- Chia bài thường thành Phần 1 giới thiệu + luyện nhóm chữ đầu, Phần 2 nhóm chữ sau và Phần 3 ôn toàn bộ chữ với câu hỏi gõ âm Hán-Việt.
- Thêm loại câu hỏi `introduceWord` và widget thẻ nghĩa 2×2 có tooltip âm Hán-Việt/nghĩa. Tái sử dụng nối cặp, xếp nghĩa và chấm đáp án hiện có.
- Bổ sung vòng tiến độ tròn, nhãn phần hiện tại trên Node; giữ nguyên 50 bài Hán, 10 Boss, 6 bài Nôm và cấu trúc bài thi 24 câu.
- Thêm kiểm thử cho chia phần, kiểu câu hỏi theo từng phần, lưu/khôi phục tiến độ và chỉ hoàn tất Node ở Phần 3.

## 2.2.0+13 — Câu hỏi tương tác

- Thêm loại câu hỏi nối cặp và xếp nghĩa dịch chuỗi chữ vào model Question và bộ sinh bài học.
- Tách widget điền khuyết; thêm giao diện word bank để xếp nghĩa bằng chạm/kéo, tooltip vẫn hiển thị âm Hán-Việt và nghĩa.
- Nối sai tối đa trừ một tim mỗi câu nối; hoàn thành nối cặp sẽ tự chuyển sang trạng thái đáp án đúng.
- Bổ sung kiểm thử sinh câu hỏi tương tác; giữ nguyên cấu trúc bài Boss/thi học vượt rút gọn.

## 2.1.0+12 — Tim tự hồi theo thời gian thực

- Thêm trường lưu `lastHeartRegenTime` bằng SharedPreferences.
- Hồi 1 tim mỗi 30 phút, tối đa 5 tim; giữ phần thời gian dư và bù thời gian đã trôi qua khi mở lại app.
- Bổ sung timer trong tiến trình app và tự cập nhật khi ứng dụng trở lại trạng thái resumed; không thêm background service.
- Hiển thị `MM:SS` cạnh số tim trên lộ trình và màn học, đồng thời cập nhật hộp thoại hết tim để cho phép tiếp tục sau khi tim tự hồi.
- Khi đầy tim, xóa mốc hồi; khi mua/nạp/nhận tim, mốc được chuẩn hóa không làm mất tiến độ khác.
- Bổ sung test cho hồi tim offline, giữ phần dư, đạt giới hạn 5 tim, và bắt đầu/dừng bộ đếm.


## 2.0.0+11
- Bumped native SQLite schema to v4 with additive migration; preserves mastery and never drops tables.
- Added SHA-256 tracking for `dictionary.json`; re-imports only when the bundled asset changes or imported count drifts.
- Added local asset verification and a dedicated clean Edge rebuild launcher.
- Normalizes case variants of Nom Na Tong font filename to `NomNaTong-Regular.ttf` after SHA-256 verification.
- Pubspec declares `assets/data/` and `assets/fonts/`; optional HanNomB remains declared only when its TTF exists.
- Dictionary shows a visible warning if the JSON asset failed to load.
- Documented Web hard-reload and warned that clearing site data can remove saved progress.
