# Bảng ký tự tiếng Việt — Unicode / JavaScript-C# escape

- Dạng chuẩn dùng trong code: **NFC** (ký tự dựng sẵn, 1 code point). Tất cả đều nằm trong BMP (≤ U+FFFF) nên escape `\uXXXX` 4 hex là đủ cho cả JavaScript và C#.
- Tổng cộng **134 ký tự non-ASCII** cần escape (xem tổng kết ở mục 5).
- Cột **UTF-8** là byte khi lưu file/gửi HTTP; cột **HTML** là entity số thập phân.

## 1. Nguyên âm — chữ thường (12 nguyên âm × 6 dạng = 72)

Thứ tự mỗi nhóm: không dấu, sắc, huyền, hỏi, ngã, nặng.

### 1.1 Chữ thường

| Ký tự | Unicode | JS/C# escape | UTF-8 | HTML |
|:-:|:-:|:-:|:-:|:-:|
| **Nhóm a** | | | | |
| a | U+0061 | `\u0061` | 61 | `&#97;` |
| á | U+00E1 | `\u00E1` | C3 A1 | `&#225;` |
| à | U+00E0 | `\u00E0` | C3 A0 | `&#224;` |
| ả | U+1EA3 | `\u1EA3` | E1 BA A3 | `&#7843;` |
| ã | U+00E3 | `\u00E3` | C3 A3 | `&#227;` |
| ạ | U+1EA1 | `\u1EA1` | E1 BA A1 | `&#7841;` |
| **Nhóm ă** | | | | |
| ă | U+0103 | `\u0103` | C4 83 | `&#259;` |
| ắ | U+1EAF | `\u1EAF` | E1 BA AF | `&#7855;` |
| ằ | U+1EB1 | `\u1EB1` | E1 BA B1 | `&#7857;` |
| ẳ | U+1EB3 | `\u1EB3` | E1 BA B3 | `&#7859;` |
| ẵ | U+1EB5 | `\u1EB5` | E1 BA B5 | `&#7861;` |
| ặ | U+1EB7 | `\u1EB7` | E1 BA B7 | `&#7863;` |
| **Nhóm â** | | | | |
| â | U+00E2 | `\u00E2` | C3 A2 | `&#226;` |
| ấ | U+1EA5 | `\u1EA5` | E1 BA A5 | `&#7845;` |
| ầ | U+1EA7 | `\u1EA7` | E1 BA A7 | `&#7847;` |
| ẩ | U+1EA9 | `\u1EA9` | E1 BA A9 | `&#7849;` |
| ẫ | U+1EAB | `\u1EAB` | E1 BA AB | `&#7851;` |
| ậ | U+1EAD | `\u1EAD` | E1 BA AD | `&#7853;` |
| **Nhóm e** | | | | |
| e | U+0065 | `\u0065` | 65 | `&#101;` |
| é | U+00E9 | `\u00E9` | C3 A9 | `&#233;` |
| è | U+00E8 | `\u00E8` | C3 A8 | `&#232;` |
| ẻ | U+1EBB | `\u1EBB` | E1 BA BB | `&#7867;` |
| ẽ | U+1EBD | `\u1EBD` | E1 BA BD | `&#7869;` |
| ẹ | U+1EB9 | `\u1EB9` | E1 BA B9 | `&#7865;` |
| **Nhóm ê** | | | | |
| ê | U+00EA | `\u00EA` | C3 AA | `&#234;` |
| ế | U+1EBF | `\u1EBF` | E1 BA BF | `&#7871;` |
| ề | U+1EC1 | `\u1EC1` | E1 BB 81 | `&#7873;` |
| ể | U+1EC3 | `\u1EC3` | E1 BB 83 | `&#7875;` |
| ễ | U+1EC5 | `\u1EC5` | E1 BB 85 | `&#7877;` |
| ệ | U+1EC7 | `\u1EC7` | E1 BB 87 | `&#7879;` |
| **Nhóm i** | | | | |
| i | U+0069 | `\u0069` | 69 | `&#105;` |
| í | U+00ED | `\u00ED` | C3 AD | `&#237;` |
| ì | U+00EC | `\u00EC` | C3 AC | `&#236;` |
| ỉ | U+1EC9 | `\u1EC9` | E1 BB 89 | `&#7881;` |
| ĩ | U+0129 | `\u0129` | C4 A9 | `&#297;` |
| ị | U+1ECB | `\u1ECB` | E1 BB 8B | `&#7883;` |
| **Nhóm o** | | | | |
| o | U+006F | `\u006F` | 6F | `&#111;` |
| ó | U+00F3 | `\u00F3` | C3 B3 | `&#243;` |
| ò | U+00F2 | `\u00F2` | C3 B2 | `&#242;` |
| ỏ | U+1ECF | `\u1ECF` | E1 BB 8F | `&#7887;` |
| õ | U+00F5 | `\u00F5` | C3 B5 | `&#245;` |
| ọ | U+1ECD | `\u1ECD` | E1 BB 8D | `&#7885;` |
| **Nhóm ô** | | | | |
| ô | U+00F4 | `\u00F4` | C3 B4 | `&#244;` |
| ố | U+1ED1 | `\u1ED1` | E1 BB 91 | `&#7889;` |
| ồ | U+1ED3 | `\u1ED3` | E1 BB 93 | `&#7891;` |
| ổ | U+1ED5 | `\u1ED5` | E1 BB 95 | `&#7893;` |
| ỗ | U+1ED7 | `\u1ED7` | E1 BB 97 | `&#7895;` |
| ộ | U+1ED9 | `\u1ED9` | E1 BB 99 | `&#7897;` |
| **Nhóm ơ** | | | | |
| ơ | U+01A1 | `\u01A1` | C6 A1 | `&#417;` |
| ớ | U+1EDB | `\u1EDB` | E1 BB 9B | `&#7899;` |
| ờ | U+1EDD | `\u1EDD` | E1 BB 9D | `&#7901;` |
| ở | U+1EDF | `\u1EDF` | E1 BB 9F | `&#7903;` |
| ỡ | U+1EE1 | `\u1EE1` | E1 BB A1 | `&#7905;` |
| ợ | U+1EE3 | `\u1EE3` | E1 BB A3 | `&#7907;` |
| **Nhóm u** | | | | |
| u | U+0075 | `\u0075` | 75 | `&#117;` |
| ú | U+00FA | `\u00FA` | C3 BA | `&#250;` |
| ù | U+00F9 | `\u00F9` | C3 B9 | `&#249;` |
| ủ | U+1EE7 | `\u1EE7` | E1 BB A7 | `&#7911;` |
| ũ | U+0169 | `\u0169` | C5 A9 | `&#361;` |
| ụ | U+1EE5 | `\u1EE5` | E1 BB A5 | `&#7909;` |
| **Nhóm ư** | | | | |
| ư | U+01B0 | `\u01B0` | C6 B0 | `&#432;` |
| ứ | U+1EE9 | `\u1EE9` | E1 BB A9 | `&#7913;` |
| ừ | U+1EEB | `\u1EEB` | E1 BB AB | `&#7915;` |
| ử | U+1EED | `\u1EED` | E1 BB AD | `&#7917;` |
| ữ | U+1EEF | `\u1EEF` | E1 BB AF | `&#7919;` |
| ự | U+1EF1 | `\u1EF1` | E1 BB B1 | `&#7921;` |
| **Nhóm y** | | | | |
| y | U+0079 | `\u0079` | 79 | `&#121;` |
| ý | U+00FD | `\u00FD` | C3 BD | `&#253;` |
| ỳ | U+1EF3 | `\u1EF3` | E1 BB B3 | `&#7923;` |
| ỷ | U+1EF7 | `\u1EF7` | E1 BB B7 | `&#7927;` |
| ỹ | U+1EF9 | `\u1EF9` | E1 BB B9 | `&#7929;` |
| ỵ | U+1EF5 | `\u1EF5` | E1 BB B5 | `&#7925;` |

## 2. Nguyên âm — chữ HOA (12 × 6 = 72)

### 2.1 Chữ hoa

| Ký tự | Unicode | JS/C# escape | UTF-8 | HTML |
|:-:|:-:|:-:|:-:|:-:|
| **Nhóm A** | | | | |
| A | U+0041 | `\u0041` | 41 | `&#65;` |
| Á | U+00C1 | `\u00C1` | C3 81 | `&#193;` |
| À | U+00C0 | `\u00C0` | C3 80 | `&#192;` |
| Ả | U+1EA2 | `\u1EA2` | E1 BA A2 | `&#7842;` |
| Ã | U+00C3 | `\u00C3` | C3 83 | `&#195;` |
| Ạ | U+1EA0 | `\u1EA0` | E1 BA A0 | `&#7840;` |
| **Nhóm Ă** | | | | |
| Ă | U+0102 | `\u0102` | C4 82 | `&#258;` |
| Ắ | U+1EAE | `\u1EAE` | E1 BA AE | `&#7854;` |
| Ằ | U+1EB0 | `\u1EB0` | E1 BA B0 | `&#7856;` |
| Ẳ | U+1EB2 | `\u1EB2` | E1 BA B2 | `&#7858;` |
| Ẵ | U+1EB4 | `\u1EB4` | E1 BA B4 | `&#7860;` |
| Ặ | U+1EB6 | `\u1EB6` | E1 BA B6 | `&#7862;` |
| **Nhóm Â** | | | | |
| Â | U+00C2 | `\u00C2` | C3 82 | `&#194;` |
| Ấ | U+1EA4 | `\u1EA4` | E1 BA A4 | `&#7844;` |
| Ầ | U+1EA6 | `\u1EA6` | E1 BA A6 | `&#7846;` |
| Ẩ | U+1EA8 | `\u1EA8` | E1 BA A8 | `&#7848;` |
| Ẫ | U+1EAA | `\u1EAA` | E1 BA AA | `&#7850;` |
| Ậ | U+1EAC | `\u1EAC` | E1 BA AC | `&#7852;` |
| **Nhóm E** | | | | |
| E | U+0045 | `\u0045` | 45 | `&#69;` |
| É | U+00C9 | `\u00C9` | C3 89 | `&#201;` |
| È | U+00C8 | `\u00C8` | C3 88 | `&#200;` |
| Ẻ | U+1EBA | `\u1EBA` | E1 BA BA | `&#7866;` |
| Ẽ | U+1EBC | `\u1EBC` | E1 BA BC | `&#7868;` |
| Ẹ | U+1EB8 | `\u1EB8` | E1 BA B8 | `&#7864;` |
| **Nhóm Ê** | | | | |
| Ê | U+00CA | `\u00CA` | C3 8A | `&#202;` |
| Ế | U+1EBE | `\u1EBE` | E1 BA BE | `&#7870;` |
| Ề | U+1EC0 | `\u1EC0` | E1 BB 80 | `&#7872;` |
| Ể | U+1EC2 | `\u1EC2` | E1 BB 82 | `&#7874;` |
| Ễ | U+1EC4 | `\u1EC4` | E1 BB 84 | `&#7876;` |
| Ệ | U+1EC6 | `\u1EC6` | E1 BB 86 | `&#7878;` |
| **Nhóm I** | | | | |
| I | U+0049 | `\u0049` | 49 | `&#73;` |
| Í | U+00CD | `\u00CD` | C3 8D | `&#205;` |
| Ì | U+00CC | `\u00CC` | C3 8C | `&#204;` |
| Ỉ | U+1EC8 | `\u1EC8` | E1 BB 88 | `&#7880;` |
| Ĩ | U+0128 | `\u0128` | C4 A8 | `&#296;` |
| Ị | U+1ECA | `\u1ECA` | E1 BB 8A | `&#7882;` |
| **Nhóm O** | | | | |
| O | U+004F | `\u004F` | 4F | `&#79;` |
| Ó | U+00D3 | `\u00D3` | C3 93 | `&#211;` |
| Ò | U+00D2 | `\u00D2` | C3 92 | `&#210;` |
| Ỏ | U+1ECE | `\u1ECE` | E1 BB 8E | `&#7886;` |
| Õ | U+00D5 | `\u00D5` | C3 95 | `&#213;` |
| Ọ | U+1ECC | `\u1ECC` | E1 BB 8C | `&#7884;` |
| **Nhóm Ô** | | | | |
| Ô | U+00D4 | `\u00D4` | C3 94 | `&#212;` |
| Ố | U+1ED0 | `\u1ED0` | E1 BB 90 | `&#7888;` |
| Ồ | U+1ED2 | `\u1ED2` | E1 BB 92 | `&#7890;` |
| Ổ | U+1ED4 | `\u1ED4` | E1 BB 94 | `&#7892;` |
| Ỗ | U+1ED6 | `\u1ED6` | E1 BB 96 | `&#7894;` |
| Ộ | U+1ED8 | `\u1ED8` | E1 BB 98 | `&#7896;` |
| **Nhóm Ơ** | | | | |
| Ơ | U+01A0 | `\u01A0` | C6 A0 | `&#416;` |
| Ớ | U+1EDA | `\u1EDA` | E1 BB 9A | `&#7898;` |
| Ờ | U+1EDC | `\u1EDC` | E1 BB 9C | `&#7900;` |
| Ở | U+1EDE | `\u1EDE` | E1 BB 9E | `&#7902;` |
| Ỡ | U+1EE0 | `\u1EE0` | E1 BB A0 | `&#7904;` |
| Ợ | U+1EE2 | `\u1EE2` | E1 BB A2 | `&#7906;` |
| **Nhóm U** | | | | |
| U | U+0055 | `\u0055` | 55 | `&#85;` |
| Ú | U+00DA | `\u00DA` | C3 9A | `&#218;` |
| Ù | U+00D9 | `\u00D9` | C3 99 | `&#217;` |
| Ủ | U+1EE6 | `\u1EE6` | E1 BB A6 | `&#7910;` |
| Ũ | U+0168 | `\u0168` | C5 A8 | `&#360;` |
| Ụ | U+1EE4 | `\u1EE4` | E1 BB A4 | `&#7908;` |
| **Nhóm Ư** | | | | |
| Ư | U+01AF | `\u01AF` | C6 AF | `&#431;` |
| Ứ | U+1EE8 | `\u1EE8` | E1 BB A8 | `&#7912;` |
| Ừ | U+1EEA | `\u1EEA` | E1 BB AA | `&#7914;` |
| Ử | U+1EEC | `\u1EEC` | E1 BB AC | `&#7916;` |
| Ữ | U+1EEE | `\u1EEE` | E1 BB AE | `&#7918;` |
| Ự | U+1EF0 | `\u1EF0` | E1 BB B0 | `&#7920;` |
| **Nhóm Y** | | | | |
| Y | U+0059 | `\u0059` | 59 | `&#89;` |
| Ý | U+00DD | `\u00DD` | C3 9D | `&#221;` |
| Ỳ | U+1EF2 | `\u1EF2` | E1 BB B2 | `&#7922;` |
| Ỷ | U+1EF6 | `\u1EF6` | E1 BB B6 | `&#7926;` |
| Ỹ | U+1EF8 | `\u1EF8` | E1 BB B8 | `&#7928;` |
| Ỵ | U+1EF4 | `\u1EF4` | E1 BB B4 | `&#7924;` |

## 3. Phụ âm đặc biệt

| Ký tự | Unicode | JS/C# escape | UTF-8 | HTML |
|:-:|:-:|:-:|:-:|:-:|
| đ | U+0111 | `\u0111` | C4 91 | `&#273;` |
| Đ | U+0110 | `\u0110` | C4 90 | `&#272;` |

Các phụ âm còn lại (b c d g h k l m n p q r s t v x) là ASCII thường, không cần escape.

## 4. Dấu thanh rời (combining) — dùng khi chuỗi ở dạng NFD

| Dấu | Tên | Unicode | JS/C# escape |
|:-:|:-:|:-:|:-:|
| ◌́ | sắc | U+0301 | `\u0301` |
| ◌̀ | huyền | U+0300 | `\u0300` |
| ◌̉ | hỏi | U+0309 | `\u0309` |
| ◌̃ | ngã | U+0303 | `\u0303` |
| ◌̣ | nặng | U+0323 | `\u0323` |

Ví dụ chữ **ế** — NFC: `\u1EBF` (1 ký tự); NFD: `e` + `\u0302` + `\u0301` (3 ký tự: e + mũ + sắc).

Chữ có 2 dấu (â, ê, ô, ă, ơ, ư + thanh) ở NFD tách thành: base + dấu phụ (`\u0302` mũ, `\u0306` trăng, `\u031B` móc) + dấu thanh.

| Dấu phụ | Tên | Unicode |
|:-:|:-:|:-:|
| ◌̂ | mũ (â ê ô) | U+0302 |
| ◌̆ | trăng (ă) | U+0306 |
| ◌̛ | móc (ơ ư) | U+031B |

## 5. Tổng kết

| Nhóm | Số ký tự |
|:--|--:|
| Nguyên âm có/không dấu thanh — chữ thường | 72 |
| Nguyên âm có/không dấu thanh — chữ hoa | 72 |
| đ, Đ | 2 |
| **Tổng ký tự tiếng Việt cần escape (non-ASCII)** | **134** |

> 144 ô ở mục 1+2 gồm 12 ký tự ASCII thuần (a e i o u y A E I O U Y) không cần escape. 144 − 12 + 2 (đ/Đ) = **134** ký tự non-ASCII.

## 6. Chuỗi sẵn để copy

### 6.1 Toàn bộ ký tự non-ASCII — dạng literal

```
áàảãạăắằẳẵặâấầẩẫậéèẻẽẹêếềểễệíìỉĩịóòỏõọôốồổỗộơớờởỡợúùủũụưứừửữựýỳỷỹỵđ
ÁÀẢÃẠĂẮẰẲẴẶÂẤẦẨẪẬÉÈẺẼẸÊẾỀỂỄỆÍÌỈĨỊÓÒỎÕỌÔỐỒỔỖỘƠỚỜỞỠỢÚÙỦŨỤƯỨỪỬỮỰÝỲỶỸỴĐ
```

### 6.2 Cùng chuỗi trên — dạng escape (JS/C#)

```
\u00E1\u00E0\u1EA3\u00E3\u1EA1\u0103\u1EAF\u1EB1\u1EB3\u1EB5\u1EB7\u00E2\u1EA5\u1EA7\u1EA9\u1EAB\u1EAD\u00E9\u00E8\u1EBB\u1EBD\u1EB9\u00EA\u1EBF\u1EC1\u1EC3\u1EC5\u1EC7\u00ED\u00EC\u1EC9\u0129\u1ECB\u00F3\u00F2\u1ECF\u00F5\u1ECD\u00F4\u1ED1\u1ED3\u1ED5\u1ED7\u1ED9\u01A1\u1EDB\u1EDD\u1EDF\u1EE1\u1EE3\u00FA\u00F9\u1EE7\u0169\u1EE5\u01B0\u1EE9\u1EEB\u1EED\u1EEF\u1EF1\u00FD\u1EF3\u1EF7\u1EF9\u1EF5\u0111

\u00C1\u00C0\u1EA2\u00C3\u1EA0\u0102\u1EAE\u1EB0\u1EB2\u1EB4\u1EB6\u00C2\u1EA4\u1EA6\u1EA8\u1EAA\u1EAC\u00C9\u00C8\u1EBA\u1EBC\u1EB8\u00CA\u1EBE\u1EC0\u1EC2\u1EC4\u1EC6\u00CD\u00CC\u1EC8\u0128\u1ECA\u00D3\u00D2\u1ECE\u00D5\u1ECC\u00D4\u1ED0\u1ED2\u1ED4\u1ED6\u1ED8\u01A0\u1EDA\u1EDC\u1EDE\u1EE0\u1EE2\u00DA\u00D9\u1EE6\u0168\u1EE4\u01AF\u1EE8\u1EEA\u1EEC\u1EEE\u1EF0\u00DD\u1EF2\u1EF6\u1EF8\u1EF4\u0110
```

### 6.3 Mẫu dùng

```javascript
// JavaScript
const s = 'Vi\u1EC7t Nam';          // Việt Nam
const t = 'Ti\u1EBFng Vi\u1EC7t';   // Tiếng Việt
// Chuẩn hoá về NFC trước khi so sánh
a.normalize('NFC') === b.normalize('NFC');
```

```csharp
// C#
string s = "Vi\u1EC7t Nam";
string nfc = input.Normalize(NormalizationForm.FormC);
```

## 7. Tra nhanh — dạng 1 dòng/nguyên âm

| Nguyên âm | Không dấu | Sắc | Huyền | Hỏi | Ngã | Nặng |
|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
| a | a `\u0061` | á `\u00E1` | à `\u00E0` | ả `\u1EA3` | ã `\u00E3` | ạ `\u1EA1` |
| ă | ă `\u0103` | ắ `\u1EAF` | ằ `\u1EB1` | ẳ `\u1EB3` | ẵ `\u1EB5` | ặ `\u1EB7` |
| â | â `\u00E2` | ấ `\u1EA5` | ầ `\u1EA7` | ẩ `\u1EA9` | ẫ `\u1EAB` | ậ `\u1EAD` |
| e | e `\u0065` | é `\u00E9` | è `\u00E8` | ẻ `\u1EBB` | ẽ `\u1EBD` | ẹ `\u1EB9` |
| ê | ê `\u00EA` | ế `\u1EBF` | ề `\u1EC1` | ể `\u1EC3` | ễ `\u1EC5` | ệ `\u1EC7` |
| i | i `\u0069` | í `\u00ED` | ì `\u00EC` | ỉ `\u1EC9` | ĩ `\u0129` | ị `\u1ECB` |
| o | o `\u006F` | ó `\u00F3` | ò `\u00F2` | ỏ `\u1ECF` | õ `\u00F5` | ọ `\u1ECD` |
| ô | ô `\u00F4` | ố `\u1ED1` | ồ `\u1ED3` | ổ `\u1ED5` | ỗ `\u1ED7` | ộ `\u1ED9` |
| ơ | ơ `\u01A1` | ớ `\u1EDB` | ờ `\u1EDD` | ở `\u1EDF` | ỡ `\u1EE1` | ợ `\u1EE3` |
| u | u `\u0075` | ú `\u00FA` | ù `\u00F9` | ủ `\u1EE7` | ũ `\u0169` | ụ `\u1EE5` |
| ư | ư `\u01B0` | ứ `\u1EE9` | ừ `\u1EEB` | ử `\u1EED` | ữ `\u1EEF` | ự `\u1EF1` |
| y | y `\u0079` | ý `\u00FD` | ỳ `\u1EF3` | ỷ `\u1EF7` | ỹ `\u1EF9` | ỵ `\u1EF5` |
| A | A `\u0041` | Á `\u00C1` | À `\u00C0` | Ả `\u1EA2` | Ã `\u00C3` | Ạ `\u1EA0` |
| Ă | Ă `\u0102` | Ắ `\u1EAE` | Ằ `\u1EB0` | Ẳ `\u1EB2` | Ẵ `\u1EB4` | Ặ `\u1EB6` |
| Â | Â `\u00C2` | Ấ `\u1EA4` | Ầ `\u1EA6` | Ẩ `\u1EA8` | Ẫ `\u1EAA` | Ậ `\u1EAC` |
| E | E `\u0045` | É `\u00C9` | È `\u00C8` | Ẻ `\u1EBA` | Ẽ `\u1EBC` | Ẹ `\u1EB8` |
| Ê | Ê `\u00CA` | Ế `\u1EBE` | Ề `\u1EC0` | Ể `\u1EC2` | Ễ `\u1EC4` | Ệ `\u1EC6` |
| I | I `\u0049` | Í `\u00CD` | Ì `\u00CC` | Ỉ `\u1EC8` | Ĩ `\u0128` | Ị `\u1ECA` |
| O | O `\u004F` | Ó `\u00D3` | Ò `\u00D2` | Ỏ `\u1ECE` | Õ `\u00D5` | Ọ `\u1ECC` |
| Ô | Ô `\u00D4` | Ố `\u1ED0` | Ồ `\u1ED2` | Ổ `\u1ED4` | Ỗ `\u1ED6` | Ộ `\u1ED8` |
| Ơ | Ơ `\u01A0` | Ớ `\u1EDA` | Ờ `\u1EDC` | Ở `\u1EDE` | Ỡ `\u1EE0` | Ợ `\u1EE2` |
| U | U `\u0055` | Ú `\u00DA` | Ù `\u00D9` | Ủ `\u1EE6` | Ũ `\u0168` | Ụ `\u1EE4` |
| Ư | Ư `\u01AF` | Ứ `\u1EE8` | Ừ `\u1EEA` | Ử `\u1EEC` | Ữ `\u1EEE` | Ự `\u1EF0` |
| Y | Y `\u0059` | Ý `\u00DD` | Ỳ `\u1EF2` | Ỷ `\u1EF6` | Ỹ `\u1EF8` | Ỵ `\u1EF4` |

