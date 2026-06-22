REPORT z_modulo_exec05.

" 클래식 리스트 출력(WRITE) — 역사적 대조(level=대조).
" 모던 ABAP은 목록을 ALV(CL_SALV_TABLE, EXEC03)로 그린다. WRITE 리스트는 화면·커서 위치에
" 종속적이라 정렬·필터·엑셀 내보내기를 직접 구현해야 하고 재사용이 어렵다 — 왜 ALV로 옮겨갔는가.
" 실행: SE38/SA38에서 F8. manual-report.

TYPES:
  BEGIN OF flight_row,
    carrier TYPE c LENGTH 3,
    connid  TYPE n LENGTH 4,
    seats   TYPE i,
  END OF flight_row.

DATA flights TYPE STANDARD TABLE OF flight_row WITH EMPTY KEY.

START-OF-SELECTION.
  flights = VALUE #( ( carrier = 'AA' connid = '0017' seats = 380 )
                     ( carrier = 'LH' connid = '0400' seats = 280 )
                     ( carrier = 'UA' connid = '0941' seats = 240 ) ).

  " 헤더 + 구분선 + 각 행을 고정 컬럼 위치에 WRITE 한다(수작업 포맷팅).
  WRITE: / 'Carrier', 12 'Conn', 22 'Seats'.
  ULINE.
  LOOP AT flights INTO DATA(flight).
    WRITE: / flight-carrier, 12 flight-connid, 22 flight-seats.
  ENDLOOP.
  ULINE.
  WRITE: / 'Rows:', lines( flights ).
