"! 테스트 더블 — lif_discount를 구현해 입력과 무관하게 고정값(1)을 돌려준다.
"! DI 덕분에 실제 전략 대신 이 더블을 주입해 lcl_pricing을 격리 검증한다.
CLASS lcl_fixed_discount DEFINITION CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES lif_discount.
ENDCLASS.

CLASS lcl_fixed_discount IMPLEMENTATION.
  METHOD lif_discount~apply.
    result = 1.
  ENDMETHOD.
ENDCLASS.


CLASS ltcl_di DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA cut TYPE REF TO zcl_modulo_expr05_di.
    METHODS setup.
    METHODS no_discount_sums    FOR TESTING.
    METHODS percent_discounts   FOR TESTING.
    METHODS di_injects_double   FOR TESTING.
ENDCLASS.


CLASS ltcl_di IMPLEMENTATION.
  METHOD setup.
    cut = NEW #( ).
  ENDMETHOD.

  METHOD no_discount_sums.
    cl_abap_unit_assert=>assert_equals( act = cut->net_no_discount( ) exp = 600 ).
  ENDMETHOD.

  METHOD percent_discounts.
    " 100·200·300 각 10% 할인 -> 90·180·270 = 540.
    cl_abap_unit_assert=>assert_equals( act = cut->net_percent( 10 ) exp = 540 ).
  ENDMETHOD.

  METHOD di_injects_double.
    " 더블을 주입하면 계산기는 더블의 동작만 따른다(각 금액 -> 1, 3건 -> 3).
    DATA(pricing) = NEW lcl_pricing( NEW lcl_fixed_discount( ) ).
    cl_abap_unit_assert=>assert_equals(
      act = pricing->net_total( VALUE #( ( 100 ) ( 200 ) ( 300 ) ) ) exp = 3 ).
  ENDMETHOD.
ENDCLASS.
