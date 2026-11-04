# Giải pháp app mobile đọc mã khắc/phun trên phôi sắt (quét nhiều phôi cùng lúc)

> Dự án: QCM – VPN | Ngày: 2026-11-04
> Ảnh mẫu: 2 bó phôi, mỗi bó 3 phôi – mã `26B7587` (mác SWRH82B) và `26E7110` (mác 30MnSi).

---

## 1. Quan sát từ ảnh mẫu (quyết định thiết kế)

| Quan sát | Hệ quả thiết kế |
|---|---|
| Mỗi mặt đầu phôi có **1 mã 7 ký tự** dạng `2 số + 1 chữ + 4 số` (`26B7587`, `26E7110`) | Dùng **regex + ràng buộc theo vị trí ký tự** → sửa lỗi OCR rất hiệu quả |
| Mã bị **xoay đủ hướng**: ngang, dọc đọc xuống, dọc đọc lên, **ngược 180°** (phôi trên giữa) | Cần bước chuẩn hoá hướng, không thể chỉ chạy OCR thẳng |
| Cùng mặt phôi còn có **mác thép** (SWRH82B, 30MnSi) và **số viết tay** vàng (32, 33, 34) | Phải phân biệt "mã cần đọc" với chữ nhiễu → dùng detector có lớp riêng |
| Chữ sơn trắng trên nền đen, bề mặt nhám, bụi, trầy, phản quang | Cần fine-tune trên dữ liệu thật; bật đèn flash/torch; kiểm tra độ nét |
| Các phôi trong 1 bó thường **cùng số mẻ** (3/3 phôi mỗi bó trùng mã) | Dùng làm **tiên nghiệm mềm** (voting trong 1 ảnh) – không ép buộc |
| Ảnh 3024×4032, mã chỉ chiếm ~5% khung hình | Cần chụp độ phân giải cao / xử lý theo vùng, không resize cả ảnh xuống 640px rồi OCR |

---

## 2. Pipeline đề xuất

```
 Camera (ảnh 12MP / video)
        │
        ▼
 [1] Detector: tìm VÙNG MÃ trên từng mặt phôi (YOLO / oriented box)
        │   lớp: ma_me | mac_thep | so_viet_tay (lớp 2,3 chỉ để loại nhiễu hoặc đọc phụ)
        ▼
 [2] Chuẩn hoá hướng: cắt crop → xoay về nằm ngang
        │   (tỉ lệ hộp ~1:5 → biết ngang/dọc; chỉ còn mơ hồ 0°/180° → thử cả 2)
        ▼
 [3] Nhận dạng (OCR crop): PaddleOCR rec đã fine-tune  (hoặc char-detector)
        │
        ▼
 [4] Hậu xử lý: regex, sửa nhầm ký tự theo vị trí, đối chiếu danh sách mã hợp lệ (SAP)
        │   → điểm tin cậy: XANH (tự nhận) / VÀNG (cần xem) / ĐỎ (sai định dạng)
        ▼
 [5] App: overlay trên ảnh, gom nhóm "26B7587 × 3 phôi", xác nhận/sửa tay, lưu + đồng bộ
```

### Xử lý hướng chữ (điểm khó nhất trong ảnh này)
- Cách 1 (đơn giản): detector hộp thẳng → cắt crop → nhìn tỉ lệ cạnh: dài ngang ⇒ 0°/180°, dài dọc ⇒ 90°/270°. Xoay về ngang, chạy OCR **cả 2 chiều (x và x+180°)**, chọn kết quả **khớp regex + confidence cao hơn**.
- Cách 2 (gọn hơn): **YOLO-OBB** (oriented bounding box) cho ra luôn góc → xoay thẳng; vẫn giữ bước thử 180°.
- Bổ sung: một classifier nhỏ 4 hướng (0/90/180/270) nếu muốn bỏ bước thử 2 chiều.

---

## 3. Lựa chọn công nghệ nhận dạng

| Phương án | Ưu | Nhược | Dùng khi |
|---|---|---|---|
| **A. ML Kit (Android) / Apple Vision (iOS)** on-device | Miễn phí, offline, dựng POC 1–2 ngày | Không tinh chỉnh được, dễ sai với chữ sơn/khắc nhám, chữ xoay 90°/180° cần kiểm chứng | **Đo baseline** |
| **B. YOLO (detect vùng mã) + PaddleOCR rec fine-tune** | Chính xác cao khi có dữ liệu thật; mã định dạng cố định nên dễ học | Cần gán nhãn + quy trình huấn luyện | ✅ **Khuyến nghị production** |
| **C. YOLO nhận diện từng ký tự (36 lớp 0–9, A–Z)** | Rất bền với font/nhiễu, dễ ràng buộc theo vị trí | Nhãn từng ký tự tốn công hơn | Nếu B chưa đủ chính xác |
| **D. Vision LLM (Claude/Gemini API)** | Không cần train, tự hiểu nhiều hướng chữ, dựng trong vài ngày | Chậm 2–6 s/ảnh, tính phí theo ảnh, **có thể "bịa" chữ số**, cần mạng | **POC / dự phòng** cho ca confidence thấp (luôn qua regex + đối chiếu) |

**Lộ trình chọn:** POC bằng A + D để đo baseline → làm B trên server → nếu cần offline/real-time thì đóng gói model sang mobile (C nếu cần).

> Lưu ý bản quyền: Ultralytics YOLO dùng giấy phép **AGPL-3.0** (cần license thương mại nếu đóng gói sản phẩm đóng). Phương án thay thế giấy phép Apache-2.0: YOLOX, PaddleDetection, RT-DETR; PaddleOCR là Apache-2.0.

---

## 4. Kiến trúc hệ thống

```
┌────────────── Mobile App (Flutter / React Native / native) ──────────────┐
│ Camera + torch + khung hướng dẫn │ kiểm tra nét/loá │ overlay kết quả     │
│ Danh sách kết quả, sửa tay, offline queue                                │
└───────────────┬──────────────────────────────────────────────────────────┘
                │ HTTPS (ảnh gốc + metadata: user, thời gian, vị trí kho)
┌───────────────▼───────────────┐      ┌───────────────────────────────┐
│ API suy luận (FastAPI, Python)│─────▶│ SAP (OData/REST qua BTP/CPI   │
│ Detector + OCR + hậu xử lý    │      │ hoặc ABAP service): danh sách │
│ Lưu ảnh bằng chứng + log      │◀─────│ mã mẻ/batch hợp lệ, ghi nhận │
└───────────────────────────────┘      └───────────────────────────────┘
```

- **MVP: "chụp 1 ảnh → xử lý → duyệt kết quả"** (dùng ảnh 12MP, chính xác nhất, đơn giản nhất).
- **v2: quét live** (detector nhỏ trên máy để vẽ khung real-time + tracker; crop gửi OCR; vote nhiều khung hình).
- **Offline** (kho không có wifi): đóng gói model ONNX/TFLite/CoreML chạy trên máy; ảnh + kết quả vào hàng đợi, có mạng thì đồng bộ.

### Quét live nhiều phôi (v2)
1. Detector nano chạy ~10–15 FPS để vẽ khung.
2. Tracker IoU/ByteTrack-lite gán ID cho từng mặt phôi.
3. Mỗi ID giữ top-k lần đọc; **vote theo từng ký tự**; khoá khi ≥3 lần đọc nhất quán → hiển thị xanh.
4. Tự động chụp ảnh nét cao khi khung ổn định.

---

## 5. Hậu xử lý – yếu tố quyết định độ chính xác

1. **Regex**: `^\d{2}[A-Z]\d{4}$` (xác nhận lại format thực tế với nhà máy).
2. **Sửa nhầm theo vị trí**:
   - Vị trí cần SỐ: `O→0`, `D→0`, `B→8`, `I/l→1`, `S→5`, `Z→2`, `G→6`.
   - Vị trí cần CHỮ (vị trí 3): `8→B`, `0→D/O`, `5→S`, `3→E` … **giới hạn tập chữ hợp lệ** (B, E, … theo dữ liệu thực).
3. **Đối chiếu danh sách hợp lệ từ SAP** (mã mẻ/batch của lệnh sản xuất/lô nhập hôm nay): nếu đọc không khớp nhưng cách 1 ký tự và **duy nhất 1 ứng viên** → đề xuất sửa (màu vàng, người dùng xác nhận).
4. **Đối chiếu mác thép** (nếu đọc thêm SWRH82B/30MnSi): kiểm tra mã – mác có khớp bản ghi SAP không.
5. **Voting trong 1 ảnh/bó**: nếu 3 phôi cùng bó đọc `26B7587`, `26B7587`, `2687587` → cảnh báo phôi thứ 3 sai/hoặc khác mẻ thật.
6. **Ngưỡng tin cậy**: xanh (≥ ngưỡng & khớp regex & khớp danh sách) → tự nhận; vàng → hỏi người dùng; đỏ → chụp lại/nhập tay.

---

## 6. Dữ liệu & huấn luyện

- **Thu thập**: POC 300–500 ảnh; production 1.500–3.000 ảnh (mỗi ảnh 3–10 phôi ⇒ >10k crop). Phủ: ca ngày/đêm, bụi/ướt, nhiều khoảng cách và góc, đủ 4 hướng chữ, mọi mác thép & mọi chữ cái mẻ.
- **Gán nhãn**: Label Studio hoặc CVAT; ảnh mẫu đã có khung đỏ quanh mã ⇒ dùng được ngay làm nhãn detector. Với OCR rec: crop + chuỗi text đúng.
- **Tăng cường dữ liệu**: xoay 4 hướng, blur, thay đổi sáng/tương phản, nhiễu, perspective, che một phần.
- **Dữ liệu tổng hợp** (rẻ vì format cố định): sinh ảnh chữ sơn/stencil trên nền thép nhám với chuỗi `\d{2}[A-Z]\d{4}` ngẫu nhiên để bổ sung.
- **Đánh giá**: đo **exact-match toàn mã** (không đo từng ký tự), tách theo điều kiện sáng/hướng/khoảng cách; giữ tập test riêng chụp ở ca/ngày khác.
- **Vòng học liên tục**: các ca người dùng sửa tay = dữ liệu huấn luyện mới (human-in-the-loop).

---

## 7. UX hiện trường (ảnh hưởng nhiều tới độ chính xác)

- Khung hướng dẫn + nhắc: *"Chụp vuông góc mặt phôi, cách ~1–1,5 m, đủ sáng"*.
- Tự bật **torch/flash**; cảnh báo **mờ (Laplacian variance)**, **loá**, **nghiêng quá**.
- Hiển thị overlay màu từng phôi + mã đọc được; chạm vào để sửa; nút "Chụp lại".
- Màn kết quả gom nhóm: `26B7587 × 3 phôi`, `26E7110 × 3 phôi`; tổng số phôi; cảnh báo mã lạ.
- Số viết tay (32/33/34): bỏ qua hoặc đọc như trường "STT" tuỳ nhu cầu (xác nhận với nhà máy).
- Lưu ảnh gốc làm bằng chứng kiểm tra/tranh chấp.

---

## 8. Tích hợp SAP (tuỳ nhu cầu)

- Mã đọc được ↔ **Batch (CHARG)/số mẻ nấu** của vật tư phôi; kiểm tra tồn tại + trạng thái.
- Nghiệp vụ gợi ý: kiểm kê/nhập kho/xuất kho/đối chiếu giao nhận phôi theo mẻ.
- Kênh: OData/REST do ABAP service (hoặc BTP/CPI) cung cấp; app chỉ gọi API, không truy cập SAP trực tiếp.
- Ghi vào SAP **sau khi người dùng xác nhận**, kèm ID ảnh bằng chứng.

---

## 9. Lộ trình & ước lượng (tham khảo, cần chỉnh theo nguồn lực)

| Giai đoạn | Nội dung | Thời gian |
|---|---|---|
| 0. POC | Thu 300 ảnh; chạy A và D; đo exact-match; app chụp + upload tối thiểu | 1–2 tuần |
| 1. Pilot | Gán nhãn; train detector + OCR (B); API server; app MVP có overlay + sửa tay | 4–6 tuần |
| 2. Tích hợp | Kết nối SAP, đối chiếu danh sách hợp lệ, phân quyền, log, offline queue | 3–4 tuần |
| 3. Tối ưu | Quét live + tracker, model chạy trên máy, vòng học liên tục | 4–8 tuần |

**Điểm dừng/đánh giá:** sau POC nếu baseline đã ≥ ~95% exact-match sau hậu xử lý thì có thể rút gọn lộ trình; nếu < 80% thì ưu tiên thu dữ liệu + fine-tune (B/C). *(Các ngưỡng là mục tiêu đề xuất, cần đo thực tế.)*

---

## 10. Rủi ro & dự phòng

| Rủi ro | Giảm thiểu |
|---|---|
| Chữ mờ/bám bụi/trầy, loá sáng | Torch + cảnh báo chất lượng ảnh; chụp lại; fine-tune với dữ liệu xấu |
| Nhầm `B/8`, `0/D`, `1/7`, `5/S` | Ràng buộc theo vị trí + đối chiếu danh sách SAP + xác nhận tay ca vàng |
| Nhiều phôi xếp chồng, che khuất | Hướng dẫn góc chụp; chụp nhiều ảnh; cho phép bổ sung phôi bị sót |
| Mất mạng ở kho | Chạy model on-device hoặc hàng đợi offline |
| Giấy phép phần mềm (AGPL) | Chọn detector Apache-2.0 hoặc mua license |
| Mã sai nhưng "hợp lệ" (đọc nhầm sang mã khác có thật) | Voting cùng bó + cảnh báo khi mác thép/lệnh không khớp |

**Giải pháp dài hạn (nếu nhà máy cho phép):** đổi sang khắc/in **QR hoặc Data Matrix** (laser/phun mực) – đọc ổn định >99,9%, có checksum, đọc được nhiều mã/khung hình bằng ML Kit/ZXing mà không cần train.

---

## 11. Câu hỏi cần chốt với nhà máy

1. Format mã đầy đủ? `26` = năm? `B/E` = lò/dây chuyền/mác? 4 số cuối = số mẻ? Có danh sách mã hợp lệ lấy từ SAP không?
2. Cần đọc thêm **mác thép** và **số viết tay** hay chỉ mã mẻ?
3. Số phôi tối đa trong 1 lần quét? Khoảng cách/góc chụp thực tế? Chồng chéo nhiều lớp không?
4. Khu vực kho có wifi/4G ổn định không (quyết định online hay offline)?
5. Thiết bị: iOS hay Android, máy cá nhân hay máy chuyên dụng (Zebra…)?
6. Mức độ chính xác chấp nhận và quy trình xác nhận khi app không chắc?
7. Kết quả đọc dùng cho nghiệp vụ nào trong SAP (nhập kho, kiểm kê, xuất, đối soát)?
