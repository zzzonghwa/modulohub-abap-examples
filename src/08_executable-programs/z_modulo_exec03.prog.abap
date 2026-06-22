REPORT z_modulo_exec03.

" 모던 읽기전용 ALV — CL_SALV_TABLE (factory + display). 클래식 WRITE(EXEC05) 대체 정석.
" 풀스크린 ALV 그리드는 SAP GUI(Control Framework)에서만 렌더된다 — ADT 콘솔(F9 클래스런)엔
" 안 나온다. 그래서 실행형 프로그램으로 작성하고 SE38/SA38에서 F8로 실행한다. manual-report.
" 자기완결을 위해 표준 데모 테이블 대신 내부 테이블을 직접 만든다(읽기전용 표시이므로 충분).

TYPES:
  BEGIN OF flight_row,
    carrier  TYPE c LENGTH 3,
    connid   TYPE n LENGTH 4,
    cityfrom TYPE c LENGTH 20,
    cityto   TYPE c LENGTH 20,
    seats    TYPE i,
  END OF flight_row.

DATA flights TYPE STANDARD TABLE OF flight_row WITH EMPTY KEY.

START-OF-SELECTION.
  flights = VALUE #(
    ( carrier = 'AA' connid = '0017' cityfrom = 'NEW YORK' cityto = 'SAN FRANCISCO' seats = 380 )
    ( carrier = 'LH' connid = '0400' cityfrom = 'FRANKFURT' cityto = 'NEW YORK' seats = 280 )
    ( carrier = 'UA' connid = '0941' cityfrom = 'FRANKFURT' cityto = 'SAN FRANCISCO' seats = 240 ) ).

  TRY.
      " factory: 풀스크린 ALV 인스턴스 생성(데이터는 CHANGING 참조 전달).
      cl_salv_table=>factory(
        IMPORTING r_salv_table = DATA(alv)
        CHANGING  t_table      = flights ).

      " 선택 설정: 컬럼 폭 최적화 + 표준 툴바(정렬/필터/엑셀) + 리스트 헤더.
      alv->get_columns( )->set_optimize( abap_true ).
      alv->get_functions( )->set_all( abap_true ).
      alv->get_display_settings( )->set_list_header( |Flight list ({ lines( flights ) })| ).

      alv->display( ).
    CATCH cx_salv_msg INTO DATA(error).
      MESSAGE error->get_text( ) TYPE 'E'.
  ENDTRY.
