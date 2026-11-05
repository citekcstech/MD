# MAISONMobile – Hướng dẫn build APK release (Windows)

Project: `C:\Users\sang.vu\Documents\GitHub\Citek_MAISONMobile` (React Native 0.61.2, Gradle 5.5, AGP 3.4.2)

## Kết quả build ngày 05/11/2026
- File: `android\app\build\outputs\apk\release\app-release.apk` (~25,6 MB)
- applicationId `com.citek.maison.scanner.prd`, versionCode 12, versionName 0.5.0
- Đã ký bằng `my-upload-key.keystore` (apksigner: v1 + v2 hợp lệ)
- Đã kiểm tra: `assets/index.android.bundle` trong APK là JS mới (đã bỏ đoạn `EAN_13` trong `formatBarcodeInput`, thay đổi chưa commit ở `src/global/appGlobal.js`)
- APK release cũ (11/05/2026) được sao lưu tại scratchpad `app-release.PREVIOUS-May11.apk` (thư mục tạm của session, có thể bị xóa)

## Cách build (PowerShell)
```powershell
$env:JAVA_HOME   = "C:\Users\sang.vu\.jdks\corretto-1.8.0_432"   # JDK 8 (Gradle 5.5 không chạy với JDK 17+)
$env:Path        = "$env:JAVA_HOME\bin;$env:Path"
$env:NODE_OPTIONS = "--openssl-legacy-provider"                   # Node 22 + Metro cũ
cd C:\Users\sang.vu\Documents\GitHub\Citek_MAISONMobile\android
.\gradlew.bat assembleRelease --console=plain
```
Thời gian: ~8–12 phút (bundle JS ~3 phút).

## 3 vấn đề gặp phải và cách xử lý
| # | Triệu chứng | Nguyên nhân | Xử lý |
|---|---|---|---|
| 1 | JDK mặc định 17 không build được | Gradle 5.5 chỉ hỗ trợ tới JDK 12 | Dùng JDK 8 (Corretto) hoặc JDK 11 qua `JAVA_HOME` |
| 2 | Task `bundleReleaseJsAndAssets` treo mãi, không có tiến trình node | Node 22 → `ERR_OSSL_EVP_UNSUPPORTED` (OpenSSL 3 bỏ md4) trong Metro | `NODE_OPTIONS=--openssl-legacy-provider` |
| 3 | `mergeReleaseResources FAILED: Duplicate resources` | 7 ảnh drawable đã commit trong `android/app/src/main/res/drawable-*` (`src_assets_images_logo.jpg`, `node_modules_reactnavigationstack_lib_module_views_assets_backicon*.png`) trùng với ảnh Gradle tự sinh từ bundle | Tạm di chuyển 7 file này ra ngoài trong lúc build, build xong trả lại (repo không đổi). Bản sao đã có sẵn ở `android/app/_leaked-bundle-assets-backup/` |

Lệnh liệt kê 7 file trùng:
```powershell
git ls-files android/app/src/main/res | Where-Object { $_ -match 'src_assets_images_logo|reactnavigationstack_lib_module_views_assets_backicon' }
```

## Lưu ý
- `android/app/src/main/assets/index.android.bundle` và `app.bundle` là bản bundle CŨ (Aug 2025) đã commit. Gradle vẫn ghi đè bằng bản mới khi build release (đã xác minh), nhưng **luôn kiểm tra** `assets/index.android.bundle` trong APK sau khi build.
- `MainApplication` dùng `CodePush.getJSBundleFile()` → mặc định nạp `assets://index.android.bundle`; `app.bundle` không được dùng.
- Cảnh báo `SAXParseException ... base-extension` trong log là vô hại (SDK XML mới hơn AGP 3.4.2).
- Khuyến nghị lâu dài: xóa 7 ảnh trùng khỏi `src/main/res` (và bundle cũ trong `src/main/assets`) để build không cần thủ thuật.
- Mật khẩu keystore đang nằm plain-text trong `android/gradle.properties` (đã commit) – nên chuyển sang `~/.gradle/gradle.properties`.
