CLASS ltcl_cond DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA cut TYPE REF TO zcl_modulo_expr02_cond.
    METHODS setup.
    METHODS cond_ranges        FOR TESTING.
    METHODS cond_abs_diff      FOR TESTING.
    METHODS cond_two_vars      FOR TESTING.
    METHODS cond_let_in        FOR TESTING.
    METHODS cond_else_omitted  FOR TESTING.
    METHODS cond_explicit_type FOR TESTING.
    METHODS cond_else_throw    FOR TESTING RAISING cx_static_check.
    METHODS cond_throw_raises  FOR TESTING.
    METHODS switch_weekday     FOR TESTING.
    METHODS switch_no_match    FOR TESTING.
    METHODS switch_string      FOR TESTING.
    METHODS switch_when_or     FOR TESTING.
    METHODS switch_else_init   FOR TESTING.
    METHODS switch_loop_throw  FOR TESTING.
ENDCLASS.


CLASS ltcl_cond IMPLEMENTATION.
  METHOD setup.
    cut = NEW #( ).
  ENDMETHOD.

  METHOD cond_ranges.
    cl_abap_unit_assert=>assert_equals( act = cut->classify_size( 5 )   exp = `small` ).
    cl_abap_unit_assert=>assert_equals( act = cut->classify_size( 50 )  exp = `medium` ).
    cl_abap_unit_assert=>assert_equals( act = cut->classify_size( 500 ) exp = `large` ).
  ENDMETHOD.

  METHOD cond_abs_diff.
    cl_abap_unit_assert=>assert_equals( act = cut->abs_diff( first = 3 second = 8 ) exp = 5 ).
    cl_abap_unit_assert=>assert_equals( act = cut->abs_diff( first = 8 second = 3 ) exp = 5 ).
  ENDMETHOD.

  METHOD cond_two_vars.
    cl_abap_unit_assert=>assert_equals( act = cut->monster_mood( sanity = 100 day = `Friday` )
                                        exp = `perfectly sane` ).
    cl_abap_unit_assert=>assert_equals( act = cut->monster_mood( sanity = 1 day = `Tuesday` )
                                        exp = `having an off day` ).
    " sanity = 1 이지만 Tuesday가 아니므로 두 번째 WHEN은 건너뛰고 세 번째(< 20)에서 잡힌다.
    cl_abap_unit_assert=>assert_equals( act = cut->monster_mood( sanity = 1 day = `Monday` )
                                        exp = `losing it` ).
    cl_abap_unit_assert=>assert_equals( act = cut->monster_mood( sanity = 50 day = `Monday` )
                                        exp = `coping` ).
  ENDMETHOD.

  METHOD cond_let_in.
    cl_abap_unit_assert=>assert_equals( act = cut->greeting_at( '073000' ) exp = `Good morning` ).
    cl_abap_unit_assert=>assert_equals( act = cut->greeting_at( '150000' ) exp = `Good afternoon` ).
    cl_abap_unit_assert=>assert_equals( act = cut->greeting_at( '200000' ) exp = `Good evening` ).
    cl_abap_unit_assert=>assert_equals( act = cut->greeting_at( '230000' ) exp = `Good night` ).
  ENDMETHOD.

  METHOD cond_else_omitted.
    " ELSE 생략 -> 초기값 abap_false.
    cl_abap_unit_assert=>assert_equals( act = cut->has_content( `` )    exp = abap_false ).
    cl_abap_unit_assert=>assert_equals( act = cut->has_content( `hi` )  exp = abap_true ).
  ENDMETHOD.

  METHOD cond_explicit_type.
    " 결과는 c(30)로 고정되나 char 비교는 우측 공백을 무시하므로 'B'와 동치.
    cl_abap_unit_assert=>assert_equals( act = cut->grade_label( 2 ) exp = 'B' ).
    cl_abap_unit_assert=>assert_equals( act = cut->grade_label( 9 ) exp = '?' ).
  ENDMETHOD.

  METHOD cond_else_throw.
    cl_abap_unit_assert=>assert_equals( act = cut->safe_divide( dividend = 10 divisor = 2 ) exp = 5 ).
    " 10 / 3 = 3.33... -> 정수 반올림 3.
    cl_abap_unit_assert=>assert_equals( act = cut->safe_divide( dividend = 10 divisor = 3 ) exp = 3 ).
  ENDMETHOD.

  METHOD cond_throw_raises.
    TRY.
        cut->safe_divide( dividend = 10 divisor = 0 ).
        cl_abap_unit_assert=>fail( msg = 'divisor 0이면 예외가 발생해야 한다' ).
      CATCH lcx_bad_input INTO DATA(error).
        cl_abap_unit_assert=>assert_equals( act = error->get_reason( ) exp = `division by zero` ).
    ENDTRY.
  ENDMETHOD.

  METHOD switch_weekday.
    cl_abap_unit_assert=>assert_equals( act = cut->weekday_name( 7 ) exp = `Sun` ).
  ENDMETHOD.

  METHOD switch_no_match.
    cl_abap_unit_assert=>assert_equals( act = cut->weekday_name( 9 ) exp = `?` ).
  ENDMETHOD.

  METHOD switch_string.
    cl_abap_unit_assert=>assert_equals( act = cut->traffic_action( `green` ) exp = `go` ).
    cl_abap_unit_assert=>assert_equals( act = cut->traffic_action( `blue` )  exp = `?` ).
  ENDMETHOD.

  METHOD switch_when_or.
    cl_abap_unit_assert=>assert_equals( act = cut->partner_role( 'AG' ) exp = `sold-to` ).
    cl_abap_unit_assert=>assert_equals( act = cut->partner_role( 'WE' ) exp = `ship-to` ).
    cl_abap_unit_assert=>assert_equals( act = cut->partner_role( 'RG' ) exp = `bill-to` ).
    cl_abap_unit_assert=>assert_equals( act = cut->partner_role( 'XX' ) exp = `other` ).
  ENDMETHOD.

  METHOD switch_else_init.
    " ELSE 생략 -> string 초기값 ''.
    cl_abap_unit_assert=>assert_equals( act = cut->flag_state( 'X' ) exp = `on` ).
    cl_abap_unit_assert=>assert_equals( act = cut->flag_state( ' ' ) exp = `off` ).
    cl_abap_unit_assert=>assert_equals( act = cut->flag_state( '?' ) exp = `` ).
  ENDMETHOD.

  METHOD switch_loop_throw.
    " A=1, B=2 누적 후 Z에서 예외로 탈출 -> 3.
    cl_abap_unit_assert=>assert_equals(
      act = cut->sum_until_unknown( VALUE #( ( `A` ) ( `B` ) ( `Z` ) ( `A` ) ) )
      exp = 3 ).
  ENDMETHOD.
ENDCLASS.
