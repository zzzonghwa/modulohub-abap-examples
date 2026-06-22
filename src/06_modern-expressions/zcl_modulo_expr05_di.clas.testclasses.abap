"! 테스트 더블 — lif_discount를 구현해 입력과 무관하게 고정값(1)을 돌려준다.
"! DI 덕분에 실제 전략 대신 이 더블을 주입해 lcl_pricing을 격리 검증한다(노트 L-07).
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
    METHODS no_discount_sums      FOR TESTING.
    METHODS percent_discounts     FOR TESTING.
    METHODS default_dependency    FOR TESTING.
    METHODS di_injects_double     FOR TESTING.
    METHODS factory_percent       FOR TESTING.
    METHODS factory_flat          FOR TESTING.
    METHODS factory_unknown       FOR TESTING.
    METHODS adapter_converts      FOR TESTING.
    METHODS singleton_taxes       FOR TESTING.
    METHODS singleton_inits_once  FOR TESTING.
    METHODS abstract_weights      FOR TESTING.
    METHODS aliases_log           FOR TESTING.
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

  METHOD default_dependency.
    " OPTIONAL 생략 -> 무할인 기본 -> 600.
    cl_abap_unit_assert=>assert_equals( act = cut->net_default_dependency( ) exp = 600 ).
  ENDMETHOD.

  METHOD di_injects_double.
    " 더블을 주입하면 계산기는 더블의 동작만 따른다(각 금액 -> 1, 3건 -> 3).
    DATA(pricing) = NEW lcl_pricing( NEW lcl_fixed_discount( ) ).
    cl_abap_unit_assert=>assert_equals(
      act = pricing->net_total( VALUE #( ( 100 ) ( 200 ) ( 300 ) ) ) exp = 3 ).
  ENDMETHOD.

  METHOD factory_percent.
    " 팩토리 percent(10) -> net_percent와 동일한 540.
    cl_abap_unit_assert=>assert_equals(
      act = cut->net_via_factory( kind = 1 parameter = 10 ) exp = 540 ).
  ENDMETHOD.

  METHOD factory_flat.
    " 정액 50 차감 -> 50·150·250 = 450.
    cl_abap_unit_assert=>assert_equals(
      act = cut->net_via_factory( kind = 2 parameter = 50 ) exp = 450 ).
  ENDMETHOD.

  METHOD factory_unknown.
    " 미지원 종류 -> 도메인 예외 -> -1.
    cl_abap_unit_assert=>assert_equals( act = cut->factory_rejects_unknown( ) exp = -1 ).
  ENDMETHOD.

  METHOD adapter_converts.
    " 천분율 50 = 5% 할인 -> 95·190·285 = 570.
    cl_abap_unit_assert=>assert_equals( act = cut->net_via_adapter( 50 ) exp = 570 ).
  ENDMETHOD.

  METHOD singleton_taxes.
    " 세율 10% -> 600 + 60 = 660.
    lcl_tax=>reset( ).
    cl_abap_unit_assert=>assert_equals( act = cut->gross_with_tax( 600 ) exp = 660 ).
  ENDMETHOD.

  METHOD singleton_inits_once.
    " 여러 번 instance( )를 호출해도 초기화는 한 번뿐 -> 1.
    cl_abap_unit_assert=>assert_equals( act = cut->singleton_init_count( ) exp = 1 ).
  ENDMETHOD.

  METHOD abstract_weights.
    " 추상 골격 + 하위 가중치 2 -> 200·400·600 = 1200.
    cl_abap_unit_assert=>assert_equals( act = cut->weighted_via_abstract( ) exp = 1200 ).
  ENDMETHOD.

  METHOD aliases_log.
    " ALIASES log( )로 기록한 문구를 그대로 되읽는다.
    cl_abap_unit_assert=>assert_equals( act = cut->audit_roundtrip( ) exp = `discount applied` ).
  ENDMETHOD.
ENDCLASS.
