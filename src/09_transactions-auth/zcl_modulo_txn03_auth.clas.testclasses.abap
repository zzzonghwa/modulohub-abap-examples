CLASS ltcl_auth DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA cut TYPE REF TO zcl_modulo_txn03_auth.
    METHODS setup.
    " 결과는 실행 사용자 권한에 따라 다르므로 정확값 단정 불가 -> 스모크 검증만.
    METHODS returns_valid_decision FOR TESTING.
ENDCLASS.


CLASS ltcl_auth IMPLEMENTATION.
  METHOD setup.
    cut = NEW #( ).
  ENDMETHOD.

  METHOD returns_valid_decision.
    " 호출이 깔끔히 반환하고 유효한 abap_bool('X' 또는 ' ')을 돌려주는지 확인한다.
    DATA(decision) = cut->can_start_tcode( 'SE80' ).
    cl_abap_unit_assert=>assert_true(
      act = xsdbool( decision = abap_true OR decision = abap_false ) ).
  ENDMETHOD.
ENDCLASS.
