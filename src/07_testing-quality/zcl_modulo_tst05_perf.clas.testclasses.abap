CLASS ltcl_perf DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA cut TYPE REF TO zcl_modulo_tst05_perf.
    METHODS setup.
    METHODS nested_counts   FOR TESTING.
    METHODS hashed_counts   FOR TESTING.
    METHODS same_result     FOR TESTING.
ENDCLASS.


CLASS ltcl_perf IMPLEMENTATION.
  METHOD setup.
    cut = NEW #( ).
  ENDMETHOD.

  METHOD nested_counts.
    cl_abap_unit_assert=>assert_equals( act = cut->match_nested( ) exp = 3 ).
  ENDMETHOD.

  METHOD hashed_counts.
    cl_abap_unit_assert=>assert_equals( act = cut->match_hashed( ) exp = 3 ).
  ENDMETHOD.

  METHOD same_result.
    " 최적화는 결과를 바꾸지 않는다 — 두 알고리즘의 출력은 동일해야 한다.
    cl_abap_unit_assert=>assert_equals( act = cut->match_hashed( ) exp = cut->match_nested( ) ).
  ENDMETHOD.
ENDCLASS.
