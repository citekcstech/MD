" Log đổi VALUE Characteristic (MM02/MM03 -> Classification) — change document object CLASSIFY
" Giá trị characteristic lưu ở AUSP, gán class ở KSSK. Log ở CDHDR/CDPOS.
" Chạy bằng ABAP SQL (DBACOCKPIT hoặc report tạm). Chưa kiểm chứng trên DE1/900.

" ---- 1) Xem 50 thay đổi CLASSIFY mới nhất — để biết dạng OBJECTID/TABKEY thực tế của hệ ----
SELECT h~objectclas, h~objectid, h~changenr, h~username, h~udate, h~utime, h~tcode,
       p~tabname, p~tabkey, p~fname, p~chngind, p~value_old, p~value_new
  FROM cdhdr AS h
  INNER JOIN cdpos AS p
     ON p~objectclas = h~objectclas
    AND p~objectid   = h~objectid
    AND p~changenr   = h~changenr
  WHERE h~objectclas = 'CLASSIFY'
    AND p~tabname    = 'AUSP'
  ORDER BY h~udate DESCENDING, h~utime DESCENDING
  UP TO 50 ROWS.

" ---- 2) Log đổi value của 1 material (ví dụ 11010000000005) ----
" AUSP-TABKEY = MANDT(3)+OBJEK(50)+ATINN(10)+ATZHL(3)+MAFID(1)+KLART(3)+ADZHL(4)
" ATINN là mã nội bộ -> đổi ra tên characteristic bằng CABN-ATNAM (xem câu 3).
" FNAME: ATWRT = value dạng char, ATFLV = value dạng số.
SELECT h~objectid, h~changenr, h~username, h~udate, h~utime, h~tcode,
       p~tabkey, p~fname, p~chngind, p~value_old, p~value_new
  FROM cdhdr AS h
  INNER JOIN cdpos AS p
     ON p~objectclas = h~objectclas
    AND p~objectid   = h~objectid
    AND p~changenr   = h~changenr
  WHERE h~objectclas = 'CLASSIFY'
    AND p~tabname    = 'AUSP'
    AND h~objectid LIKE '%11010000000005%'
  ORDER BY h~udate DESCENDING, h~utime DESCENDING.

" ---- 3) Tra tên characteristic từ ATINN trong TABKEY ----
SELECT atinn, atnam
  FROM cabn
  WHERE atnam IN ('SKU', 'COLOR', 'BRAND')   " sửa theo tên characteristic cần tra
  ORDER BY atinn.

" ---- 4) Cấu hình hiện tại của Class Type 001 (xem cờ Multiple objs / Change docs) ----
" TCLA-MULTOBJ = Multiple objs allowed, TCLA-AEBLGZUORD = Change Documents for Classification
SELECT * FROM tcla WHERE klart = '001'.

" Các object type (OBTAB) của Class Type 001 — dòng MARA là Material, là dòng cần xem cờ Change docs / Change mgmt trong O1CL
SELECT * FROM tclao WHERE klart = '001'.

" ---- 5) Material này có dòng INOB không? Có -> Class Type 001 đang dùng INOB (multiple objs), AUSP/KSSK-OBJEK = INOB-CUOBJ ----
SELECT i~objek, i~cuobj, i~klart, i~obtab
  FROM inob AS i
  WHERE i~klart = '001'
    AND i~objek LIKE '%11010000000005%'
  UP TO 5 ROWS.
