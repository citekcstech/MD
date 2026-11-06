" APA PRD800 (client 800) - tra cứu phục vụ phân quyền KH 10002000 (Tiếp Phát)
" Chạy từng câu bằng ADT (ABAP SQL console) hoặc SE16N. Gửi lại kết quả để phân tích tiếp.

" ---------------------------------------------------------------
" 1. Các Tcode Z: chương trình + màn hình + tên (xác định Z hay đã copy từ chuẩn)
" ---------------------------------------------------------------
SELECT tcode, pgmna, dypno, cinfo
  FROM tstc
  WHERE tcode IN ( 'ZSD01', 'ZSD02', 'ZSD05', 'ZSD06', 'ZPP10', 'ZWM06',
                   'MD79', 'MD73' )
  ORDER BY tcode.

SELECT tcode, sprsl, ttext
  FROM tstct
  WHERE tcode IN ( 'ZSD01', 'ZSD02', 'ZSD05', 'ZSD06', 'ZPP10', 'ZWM06',
                   'MD79', 'MD73' )
    AND sprsl IN ( 'E', 'V' )
  ORDER BY tcode, sprsl.

" ---------------------------------------------------------------
" 2. Object mà SAP / khách hàng đã gán mặc định cho Tcode (SU24)
"    -> biết Tcode chuẩn đang check những object nào (có object nào liên quan KH không)
"    USOBX = bản SAP, USOBX_C = bản khách hàng chỉnh
" ---------------------------------------------------------------
SELECT name, object, okflag
  FROM usobx
  WHERE type = 'TR'
    AND name IN ( 'VA01', 'VA02', 'VA03', 'VL01N', 'VL02N', 'VF01', 'VF04',
                  'MD79', 'MD73' )
  ORDER BY name, object.

SELECT name, object, okflag, modified
  FROM usobx_c
  WHERE type = 'TR'
    AND name IN ( 'VA01', 'VA02', 'VA03', 'VL01N', 'VL02N', 'VF01', 'VF04',
                  'ZSD01', 'ZSD02', 'ZSD05', 'ZSD06', 'ZPP10', 'ZWM06',
                  'MD79', 'MD73' )
  ORDER BY name, object.

" ---------------------------------------------------------------
" 3. Role đang chứa các Tcode này (phạm vi role phải sửa/kiểm tra)
" ---------------------------------------------------------------
SELECT agr_name, low
  FROM agr_tcodes
  WHERE type = 'TR'
    AND low IN ( 'VA01', 'VA02', 'VA03', 'VL01N', 'VL02N', 'VF01', 'VF04',
                 'ZSD01', 'ZSD02', 'ZSD05', 'ZSD06', 'ZPP10', 'ZWM06',
                 'MD79', 'MD73' )
  ORDER BY low, agr_name.

" ---------------------------------------------------------------
" 4. KH 10002000 trong master data (KUNNR lưu dạng 0010002000)
"    BEGRU = authorization group, KTOKD = account group
" ---------------------------------------------------------------
SELECT kunnr, name1, ktokd, begru, sperr, loevm
  FROM kna1
  WHERE kunnr = '0010002000'.

SELECT kunnr, bukrs, begru, sperr
  FROM knb1
  WHERE kunnr = '0010002000'.

SELECT kunnr, vkorg, vtweg, spart, begru
  FROM knvv
  WHERE kunnr = '0010002000'.

" ---------------------------------------------------------------
" 5. Object custom đã có sẵn cho KH chưa (tránh tạo trùng)
" ---------------------------------------------------------------
SELECT object, fiel1, fiel2, fiel3, fiel4, oclss
  FROM tobj
  WHERE object LIKE 'Z%'
    AND ( fiel1 = 'KUNNR' OR fiel2 = 'KUNNR' OR fiel3 = 'KUNNR' OR fiel4 = 'KUNNR' ).
