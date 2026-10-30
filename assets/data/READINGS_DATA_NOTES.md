# Ghi chú dữ liệu cách đọc CJKV

- Bộ dữ liệu hiện tại đảm bảo **250/250 chữ trong giáo trình** có tối thiểu một Pinyin Quan thoại và một cách đọc On’yomi Hán-Nhật.
- Một số chữ đa âm đã được lưu nhiều cách đọc phổ biến. Danh sách này chưa nhằm mô tả mọi cách đọc, mọi biến âm theo từ ghép, tên riêng hay ngữ cảnh.
- Các giá trị trong `cjk_readings_overrides.json` được biên tập thủ công theo các cách đọc phổ biến, không phải bản nhập tự động hoàn chỉnh từ một cơ sở dữ liệu duy nhất. Cần đối chiếu lại trước khi phát hành rộng rãi.
- Unicode Unihan là tài liệu tham khảo hữu ích cho dữ liệu Han, bao gồm các trường đọc Quan thoại và Hán-Nhật: https://unicode.org/reports/tr38/ .
- KANJIDIC2 cung cấp thông tin chữ Kanji và phân biệt các kiểu đọc Nhật; EDRDG ghi nhận dữ liệu được cung cấp theo giấy phép Creative Commons BY-SA 4.0: https://www.edrdg.org/kanjidic/kanjidic2_ov_legacy.html .
- Nếu bổ sung dữ liệu từ các nguồn bên ngoài vào bản phát hành, cần tuân thủ giấy phép và ghi attribution của đúng nguồn dữ liệu đã nhập.
