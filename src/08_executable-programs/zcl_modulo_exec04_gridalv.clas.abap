CLASS zcl_modulo_exec04_gridalv DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    "! ADT에서 F9(Run As -> ABAP Application)로 바로 실행해 도구 선택 가이드를 본다.
    "!
    "! 편집형/이벤트형 ALV — CL_GUI_ALV_GRID 대조(개념·국내 실무).
    "! ALV 도구 3선택지:
    "! - CL_SALV_TABLE: 읽기전용 풀스크린(모던 정석, 화면 코딩 최소). -> EXEC03.
    "! - CL_GUI_ALV_GRID: 셀 편집·이벤트(double_click, data_changed) 처리(국내 실무 다수).
    "!   Dynpro 화면 + 커스텀 컨테이너(CL_GUI_CUSTOM_CONTAINER)가 필요해 자체완결 콘솔 예제로는
    "!   부적합 — 코드 형태는 아래 주석으로 보인다.
    "! - REUSE_ALV_GRID_DISPLAY: 고전 함수모듈(레거시). 신규 개발은 위 클래스 기반으로.
    "!
    "! CL_GUI_ALV_GRID 골격(Dynpro 0100의 PBO에서):
    "!   DATA container TYPE REF TO cl_gui_custom_container.
    "!   DATA grid      TYPE REF TO cl_gui_alv_grid.
    "!   container = NEW #( container_name = 'CC_ALV' ).   " 화면의 커스텀 컨트롤 이름
    "!   grid = NEW #( i_parent = container ).
    "!   grid->set_table_for_first_display(
    "!     CHANGING  it_outtab       = flights
    "!     EXPORTING is_layout       = VALUE #( cwidth_opt = abap_true edit = abap_true ) ).
    "!   " 이벤트: SET HANDLER lcl_handler=>on_double_click FOR grid. 등
    INTERFACES if_oo_adt_classrun.

    "! 시나리오에 맞는 ALV 도구를 추천한다(편집/이벤트 필요 여부 기준).
    "! @parameter editable | 셀 편집·이벤트 처리가 필요한가
    "! @parameter result   | 권장 클래스명
    METHODS recommend_alv
      IMPORTING editable      TYPE abap_bool
      RETURNING VALUE(result) TYPE string.
ENDCLASS.


CLASS zcl_modulo_exec04_gridalv IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    out->write( `=== EXEC04 편집형 ALV (CL_GUI_ALV_GRID) 대조 ===` ).
    out->write( |읽기전용 -> { recommend_alv( abap_false ) } (EXEC03)| ).
    out->write( |편집/이벤트 -> { recommend_alv( abap_true ) } (Dynpro 화면+컨테이너 필요)| ).
    out->write( `레거시: REUSE_ALV_GRID_DISPLAY 함수모듈 — 신규 개발은 클래스 기반 ALV 사용.` ).
    out->write( `CL_GUI_ALV_GRID 골격은 클래스 주석 참고(자체완결 콘솔 예제 범위 밖).` ).
  ENDMETHOD.

  METHOD recommend_alv.
    result = COND #( WHEN editable = abap_true
                     THEN `CL_GUI_ALV_GRID`
                     ELSE `CL_SALV_TABLE` ).
  ENDMETHOD.
ENDCLASS.
