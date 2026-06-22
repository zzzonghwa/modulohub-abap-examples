CLASS ltcl_value DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA cut TYPE REF TO zcl_modulo_expr01_value.
    METHODS setup.
    METHODS for_then_until      FOR TESTING.
    METHODS while_increment     FOR TESTING.
    METHODS base_extends        FOR TESTING.
    METHODS base_partial_update FOR TESTING.
    METHODS deep_nested         FOR TESTING.
    METHODS step_two            FOR TESTING.
    METHODS optional_default     FOR TESTING.
    METHODS range_in_match       FOR TESTING.
    METHODS range_in_miss        FOR TESTING.
    METHODS for_where_filter     FOR TESTING.
    METHODS reverse_index        FOR TESTING.
    METHODS nested_for           FOR TESTING.
    METHODS using_key            FOR TESTING.
    METHODS corr_vs_move         FOR TESTING.
    METHODS corresponding_map    FOR TESTING.
    METHODS corresponding_base   FOR TESTING.
    METHODS table_convert        FOR TESTING.
    METHODS new_object           FOR TESTING.
    METHODS filter_sorted        FOR TESTING.
ENDCLASS.


CLASS ltcl_value IMPLEMENTATION.
  METHOD setup.
    cut = NEW #( ).
  ENDMETHOD.

  METHOD for_then_until.
    " UNTIL pre-test: i=1,2,3,4 (i=5에서 i>4 종료) -> 1,4,9,16.
    cl_abap_unit_assert=>assert_equals( act = cut->squares_up_to( 4 ) exp = `1,4,9,16` ).
  ENDMETHOD.

  METHOD while_increment.
    " WHILE k<4 + THEN 생략 자동증가: k=1,2,3 -> 합 6.
    cl_abap_unit_assert=>assert_equals( act = cut->while_auto_increment( 4 ) exp = 6 ).
  ENDMETHOD.

  METHOD base_extends.
    cl_abap_unit_assert=>assert_equals( act = cut->extend_with_base( ) exp = 4 ).
  ENDMETHOD.

  METHOD base_partial_update.
    " salary 5000 + 5000*10/100 = 5500, name·dept 보존.
    cl_abap_unit_assert=>assert_equals( act = cut->raise_salary( 10 ) exp = `Kim IT 5500` ).
  ENDMETHOD.

  METHOD deep_nested.
    cl_abap_unit_assert=>assert_equals( act = cut->build_segment( ) exp = `L1 (0,0)->(3,4)` ).
  ENDMETHOD.

  METHOD step_two.
    " 1 THEN i+2 UNTIL i>6 -> 1,3,5.
    cl_abap_unit_assert=>assert_equals( act = cut->every_second( ) exp = `1,3,5` ).
  ENDMETHOD.

  METHOD optional_default.
    cl_abap_unit_assert=>assert_equals( act = cut->name_or_default( 2 ) exp = `Lee` ).
    cl_abap_unit_assert=>assert_equals( act = cut->name_or_default( 99 ) exp = `N/A` ).
  ENDMETHOD.

  METHOD range_in_match.
    cl_abap_unit_assert=>assert_equals( act = cut->range_includes( 15 ) exp = abap_true ).
  ENDMETHOD.

  METHOD range_in_miss.
    cl_abap_unit_assert=>assert_equals( act = cut->range_includes( 7 ) exp = abap_false ).
  ENDMETHOD.

  METHOD for_where_filter.
    " salary >= 4000: Kim 5000, Park 4200, Choi 6100 -> 3.
    cl_abap_unit_assert=>assert_equals( act = cut->high_earners( 4000 ) exp = 3 ).
  ENDMETHOD.

  METHOD reverse_index.
    cl_abap_unit_assert=>assert_equals( act = cut->names_reversed( ) exp = `Choi,Park,Lee,Kim` ).
  ENDMETHOD.

  METHOD nested_for.
    " 직원 4 x 부서 2 = 8.
    cl_abap_unit_assert=>assert_equals( act = cut->cross_join_count( ) exp = 8 ).
  ENDMETHOD.

  METHOD using_key.
    " id 오름차순 첫 직원 id = 1.
    cl_abap_unit_assert=>assert_equals( act = cut->first_by_key( ) exp = 1 ).
  ENDMETHOD.

  METHOD corr_vs_move.
    " 표현식은 비매핑 full_name 초기화(공백), 문장은 보존(OLD).
    cl_abap_unit_assert=>assert_equals(
      act = cut->corresponding_vs_move( ) exp = `expr:[] move:[OLD]` ).
  ENDMETHOD.

  METHOD corresponding_map.
    cl_abap_unit_assert=>assert_equals( act = cut->map_employee( ) exp = `1 Kim 5000` ).
  ENDMETHOD.

  METHOD corresponding_base.
    " BASE(target) 보존 + source 매핑: full_name=Kim 보존, salary=7000 갱신.
    cl_abap_unit_assert=>assert_equals( act = cut->map_with_base( ) exp = `Kim 7000` ).
  ENDMETHOD.

  METHOD table_convert.
    cl_abap_unit_assert=>assert_equals( act = cut->convert_table( ) exp = 4 ).
  ENDMETHOD.

  METHOD new_object.
    cl_abap_unit_assert=>assert_equals( act = cut->new_data_object( ) exp = `Lee 6000` ).
  ENDMETHOD.

  METHOD filter_sorted.
    " id > 2: 3, 4 -> 2.
    cl_abap_unit_assert=>assert_equals( act = cut->filter_by_id( 2 ) exp = 2 ).
  ENDMETHOD.
ENDCLASS.
