CLASS ltcl_api DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA cut TYPE REF TO zcl_modulo_sql07_api.
    METHODS setup.
    " 출력값은 비결정적(시점 의존)이라 스모크 검증만 한다 — released API가 값을 돌려주는지.
    METHODS date_is_filled FOR TESTING.
ENDCLASS.


CLASS ltcl_api IMPLEMENTATION.
  METHOD setup.
    cut = NEW #( ).
  ENDMETHOD.

  METHOD date_is_filled.
    " 실 시스템에서 시스템 날짜는 항상 채워진다(오늘) -> 초기값이 아니다.
    cl_abap_unit_assert=>assert_not_initial( act = cut->system_date( ) ).
  ENDMETHOD.
ENDCLASS.
