"! 테스트 더블(spy) — hour를 고정 반환하면서 호출 횟수를 기록한다(상호작용 검증용).
CLASS lcl_clock_spy DEFINITION CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES lif_clock.
    DATA calls TYPE i READ-ONLY.
    METHODS set_hour IMPORTING value TYPE i.
  PRIVATE SECTION.
    DATA hour_value TYPE i.
ENDCLASS.

CLASS lcl_clock_spy IMPLEMENTATION.
  METHOD set_hour.
    hour_value = value.
  ENDMETHOD.

  METHOD lif_clock~hour.
    calls = calls + 1.
    result = hour_value.
  ENDMETHOD.
ENDCLASS.


CLASS ltcl_tst02 DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA cut TYPE REF TO zcl_modulo_tst02_aunit.
    METHODS setup.
    METHODS greet_by_time   FOR TESTING.
    METHODS business_hours  FOR TESTING.
    METHODS double_and_spy  FOR TESTING.
ENDCLASS.


CLASS ltcl_tst02 IMPLEMENTATION.
  METHOD setup.
    " 픽스처: 매 테스트 전에 cut를 새로 만든다.
    cut = NEW #( ).
  ENDMETHOD.

  METHOD greet_by_time.
    cl_abap_unit_assert=>assert_equals( act = cut->greeting_at( 8 )  exp = `Good morning` ).
    cl_abap_unit_assert=>assert_equals( act = cut->greeting_at( 14 ) exp = `Good afternoon` ).
    cl_abap_unit_assert=>assert_equals( act = cut->greeting_at( 20 ) exp = `Good evening` ).
  ENDMETHOD.

  METHOD business_hours.
    cl_abap_unit_assert=>assert_true(  act = cut->is_business_hours_at( 10 ) ).
    cl_abap_unit_assert=>assert_false( act = cut->is_business_hours_at( 20 ) ).
  ENDMETHOD.

  METHOD double_and_spy.
    " 더블을 직접 주입해 lcl_greeter를 격리 검증하고, 상호작용(호출 횟수)도 확인한다.
    DATA(spy) = NEW lcl_clock_spy( ).
    spy->set_hour( 9 ).
    DATA(greeter) = NEW lcl_greeter( spy ).
    cl_abap_unit_assert=>assert_equals( act = greeter->greet( ) exp = `Good morning` ).
    cl_abap_unit_assert=>assert_equals( act = spy->calls exp = 1 ).
  ENDMETHOD.
ENDCLASS.
