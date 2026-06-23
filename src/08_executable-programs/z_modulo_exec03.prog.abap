REPORT z_modulo_exec03.

" 모던 읽기전용 ALV — CL_SALV_TABLE. 클래식 WRITE 대체 정석. ALV 구문 폭을 한 리포트에 모은다.
" 풀스크린 ALV 그리드는 SAP GUI(Control Framework)에서만 렌더된다 — ADT 콘솔(F9 클래스런)엔 안 나온다.
" 그래서 실행형 프로그램으로 작성하고 SE38/SA38에서 F8(또는 "Run As -> ABAP Application")로 실행한다.
" 자기완결을 위해 표준 데모 테이블 대신 내부 테이블을 직접 만든다(읽기전용 표시이므로 충분).
"
" 구성 단계:
"  FACTORY          CL_SALV_TABLE=>FACTORY(IMPORTING r_salv_table CHANGING t_table) — NEW 불가, 정적 팩토리만.
"  CX_SALV_MSG      FACTORY는 CX_SALV_MSG를 던질 수 있어 TRY/CATCH 필수.
"  필드 카탈로그 자동 — 내부 테이블 구조에서 SALV가 컬럼을 만든다(수동 카탈로그 불필요).
"  get_columns      set_optimize(폭 최적화) + 개별 컬럼 set_long_text/set_tooltip/set_visible/set_technical.
"  get_functions    set_all(표준 툴바 일괄 활성 — 정렬/필터/엑셀).
"  get_sorts        add_sort + IF_SALV_C_SORT=>SORT_DOWN/SORT_UP, subtotal 그룹.
"  get_aggregations add_aggregation(소계 컬럼, 기본 TOTAL).
"  get_display_settings set_list_header + set_striped_pattern(zebra).
"  get_layout       set_key(SY-CPROG) + set_save_restriction — 레이아웃 변형 저장.
"  get_event        SET HANDLER로 link_click(핫스팟)/added_function(&IC1 더블클릭) 등록.
"  display          화면 출력. REFRESH로 데이터 변경 후 갱신.
"  대조             REUSE_ALV_GRID_DISPLAY(레거시·수동 카탈로그) vs CL_SALV_GUI_TABLE_IDA(대용량 IDA).

" --- 행 타입 — 항공편 한 건. SALV가 이 구조에서 필드 카탈로그를 자동 생성한다. ---
TYPES:
  BEGIN OF flight_row,
    carrier  TYPE c LENGTH 3,
    connid   TYPE n LENGTH 4,
    cityfrom TYPE c LENGTH 20,
    cityto   TYPE c LENGTH 20,
    seats    TYPE i,
    price    TYPE p LENGTH 9 DECIMALS 2,
  END OF flight_row.
TYPES flight_rows TYPE STANDARD TABLE OF flight_row WITH EMPTY KEY.

" --- 보고서 로직 — 이벤트 블록은 얇은 진입점으로 두고 SALV 구성은 OO 클래스로 위임한다(CleanABAP). ---
CLASS lcl_report DEFINITION CREATE PRIVATE.
  PUBLIC SECTION.
    "! 데모용 항공편 6건 샘플 데이터(price 컬럼 포함).
    CLASS-METHODS sample
      RETURNING VALUE(result) TYPE flight_rows.

    "! 진입점 — START-OF-SELECTION이 호출한다. 샘플을 풀스크린 ALV로 구성·표시한다.
    CLASS-METHODS run.

  PRIVATE SECTION.
    " 핸들러 등록 대상이라 인스턴스가 필요하다(SET HANDLER는 인스턴스 메서드에 건다).
    CLASS-DATA singleton TYPE REF TO lcl_report.
    " CHANGING t_table은 표시 동안 살아 있어야 하므로 인스턴스 속성으로 보관한다.
    DATA flights TYPE flight_rows.
    DATA alv TYPE REF TO cl_salv_table.

    "! 컬럼 폭·라벨·툴팁·표시여부를 제어한다. 존재하지 않는 컬럼명은 CX_SALV_NOT_FOUND.
    METHODS configure_columns
      RAISING cx_salv_not_found.

    "! seats 내림차순 정렬 + carrier 그룹 소계 기준을 추가한다.
    METHODS configure_sorts
      RAISING cx_salv_data_error
              cx_salv_not_found
              cx_salv_existing.

    "! price·seats 합계(소계) 집계 컬럼을 지정한다.
    METHODS configure_aggregations
      RAISING cx_salv_data_error
              cx_salv_existing
              cx_salv_not_found.

    "! 리스트 헤더·zebra 줄무늬·레이아웃 변형 저장을 설정한다.
    METHODS configure_appearance.

    "! 핫스팟 클릭·더블클릭(&IC1) 이벤트 핸들러를 등록한다.
    METHODS register_events.

    "! 핫스팟/명령 이벤트 — 선택 행의 항공사 코드를 정보 메시지로 보여준다(데모).
    METHODS on_link_click
      FOR EVENT link_click OF cl_salv_events_table
      IMPORTING row.

    "! 더블클릭(&IC1)·툴바 명령 이벤트 — function code를 정보 메시지로 보여준다(데모).
    METHODS on_user_command
      FOR EVENT added_function OF cl_salv_events_table
      IMPORTING e_salv_function.
ENDCLASS.

CLASS lcl_report IMPLEMENTATION.
  METHOD sample.
    result = VALUE #(
      ( carrier = 'AA' connid = '0017' cityfrom = 'NEW YORK'  cityto = 'SAN FRANCISCO' seats = 380 price = '899.00' )
      ( carrier = 'AA' connid = '0064' cityfrom = 'SAN FRANCISCO' cityto = 'NEW YORK'  seats = 320 price = '799.00' )
      ( carrier = 'LH' connid = '0400' cityfrom = 'FRANKFURT' cityto = 'NEW YORK'     seats = 280 price = '650.00' )
      ( carrier = 'LH' connid = '2402' cityfrom = 'FRANKFURT' cityto = 'BERLIN'       seats = 180 price = '120.00' )
      ( carrier = 'UA' connid = '0941' cityfrom = 'FRANKFURT' cityto = 'SAN FRANCISCO' seats = 240 price = '720.00' )
      ( carrier = 'UA' connid = '3517' cityfrom = 'CHICAGO'   cityto = 'BOSTON'       seats = 300 price = '210.00' ) ).
  ENDMETHOD.

  METHOD run.
    " 단일 인스턴스를 만들어 데이터와 SALV 객체를 인스턴스 속성으로 보관한다(핸들러 등록 때문).
    singleton = NEW #( ).
    singleton->flights = sample( ).

    TRY.
        " FACTORY: 풀스크린 ALV 인스턴스 생성. NEW/CREATE OBJECT 불가(생성자 비공개), 팩토리만.
        " CHANGING t_table로 넘긴 내부 테이블 구조에서 SALV가 필드 카탈로그를 자동 생성한다.
        cl_salv_table=>factory(
          IMPORTING r_salv_table = singleton->alv
          CHANGING  t_table      = singleton->flights ).

        " 표준 툴바 일괄 활성(정렬/필터/합계/엑셀). FACTORY는 기본적으로 툴바를 켜지 않는다.
        singleton->alv->get_functions( )->set_all( abap_true ).

        singleton->configure_columns( ).
        singleton->configure_sorts( ).
        singleton->configure_aggregations( ).
        singleton->configure_appearance( ).
        singleton->register_events( ).

        " display: 보고서를 화면에 출력한다(런타임 출력은 SAP GUI에서만 확인 가능).
        singleton->alv->display( ).
      CATCH cx_salv_msg INTO DATA(factory_error).
        " FACTORY 단계의 예외. 컬럼/정렬/집계 예외와 메시지를 통일해 사용자는 콘솔에서 원인을 본다.
        MESSAGE factory_error->get_text( ) TYPE 'E'.
      CATCH cx_salv_not_found cx_salv_data_error cx_salv_existing INTO DATA(config_error).
        MESSAGE config_error->get_text( ) TYPE 'E'.
    ENDTRY.
  ENDMETHOD.

  METHOD configure_columns.
    " get_columns: 컬럼 컬렉션. set_optimize로 내용에 맞춰 폭을 자동 조정한다.
    DATA(columns) = alv->get_columns( ).
    columns->set_optimize( abap_true ).

    " 개별 컬럼은 get_column( name )으로 얻는다. 없는 이름이면 CX_SALV_NOT_FOUND.
    " 헤더 라벨(긴/중간/짧은 텍스트)과 툴팁을 코드로 지정한다. 풀스크린 폭에 따라 SALV가 적절한 길이를 고른다.
    DATA(carrier_column) = columns->get_column( 'CARRIER' ).
    carrier_column->set_long_text( 'Airline carrier' ).
    carrier_column->set_medium_text( 'Carrier' ).
    carrier_column->set_short_text( 'Carr' ).
    carrier_column->set_tooltip( 'Two-character airline code' ).

    " 핫스팟 셀 — 클릭 시 link_click 이벤트가 발생한다. CAST로 테이블 컬럼 전용 set_cell_type 사용.
    CAST cl_salv_column_table( carrier_column )->set_cell_type( if_salv_c_cell_type=>hotspot ).

    " set_visible( abap_false ) — 데이터는 유지하되 화면에서 숨긴다(완전 제거 아님).
    DATA(cityfrom_column) = columns->get_column( 'CITYFROM' ).
    cityfrom_column->set_long_text( 'Departure city' ).
    cityfrom_column->set_medium_text( 'From' ).

    DATA(cityto_column) = columns->get_column( 'CITYTO' ).
    cityto_column->set_long_text( 'Arrival city' ).
    cityto_column->set_medium_text( 'To' ).

    DATA(price_column) = columns->get_column( 'PRICE' ).
    price_column->set_long_text( 'Ticket price' ).
    price_column->set_medium_text( 'Price' ).
  ENDMETHOD.

  METHOD configure_sorts.
    " get_sorts: 정렬 컬렉션. add_sort로 좌석 내림차순 + carrier 그룹 소계 기준을 추가한다.
    DATA(sorts) = alv->get_sorts( ).
    " carrier로 그룹화하고 그 그룹마다 소계 줄을 만든다(subtotal = TRUE). 집계와 함께 작동한다.
    sorts->add_sort(
      columnname = 'CARRIER'
      sequence   = if_salv_c_sort=>sort_up
      subtotal   = abap_true ).
    " seats는 내림차순(SORT_DOWN)으로 정렬한다.
    sorts->add_sort(
      columnname = 'SEATS'
      sequence   = if_salv_c_sort=>sort_down ).
  ENDMETHOD.

  METHOD configure_aggregations.
    " get_aggregations: 집계 컬렉션. add_aggregation으로 합계(소계) 컬럼을 지정한다.
    " 기본 집계 타입은 TOTAL이다. carrier 그룹 소계(configure_sorts의 subtotal)와 결합돼 그룹별 합이 나온다.
    DATA(aggregations) = alv->get_aggregations( ).
    aggregations->add_aggregation( columnname = 'SEATS' ).
    aggregations->add_aggregation( columnname = 'PRICE' ).
  ENDMETHOD.

  METHOD configure_appearance.
    " get_display_settings: 리스트 헤더(제목)와 zebra 줄무늬를 설정한다.
    DATA(display_settings) = alv->get_display_settings( ).
    display_settings->set_list_header( |Flight list ({ lines( flights ) } rows)| ).
    display_settings->set_striped_pattern( abap_true ).

    " get_layout: 레이아웃 변형(variant) 저장. SET_KEY의 REPORT에 SY-CPROG를 넣어야
    " 변형이 올바른 프로그램에 연결된다. 저장 제한은 사용자·기본 변형 모두 허용.
    DATA(layout) = alv->get_layout( ).
    layout->set_key( VALUE #( report = sy-cprog ) ).
    layout->set_save_restriction( if_salv_c_layout=>restrict_none ).
  ENDMETHOD.

  METHOD register_events.
    " get_event: 이벤트 객체를 얻어 SET HANDLER로 핸들러를 건다.
    DATA(events) = alv->get_event( ).
    " 핫스팟 셀 클릭 -> link_click(row, column). 더블클릭/툴바 명령 -> added_function(e_salv_function, &IC1).
    SET HANDLER on_link_click FOR events.
    SET HANDLER on_user_command FOR events.
  ENDMETHOD.

  METHOD on_link_click.
    " 핫스팟 클릭 행의 항공사 코드를 정보 메시지로 보여준다. row는 클릭된 행 인덱스.
    DATA(clicked) = VALUE #( flights[ row ] OPTIONAL ).
    MESSAGE |Carrier { clicked-carrier } / connid { clicked-connid }| TYPE 'I'.
  ENDMETHOD.

  METHOD on_user_command.
    " 더블클릭 시 시스템이 e_salv_function에 '&IC1'을 자동 설정한다. 그 값을 표시한다.
    MESSAGE |Function: { e_salv_function }| TYPE 'I'.
  ENDMETHOD.
ENDCLASS.

START-OF-SELECTION.
  " CleanABAP: 이벤트 블록은 얇게 — SALV 구성·표시는 lcl_report=>run으로 위임한다.
  lcl_report=>run( ).
