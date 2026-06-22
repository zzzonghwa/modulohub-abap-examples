CLASS ltcl_reduce DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA cut TYPE REF TO zcl_modulo_expr03_reduce.
    METHODS setup.
    METHODS factorial_five    FOR TESTING.
    METHODS factorial_zero    FOR TESTING.
    METHODS sum_compound      FOR TESTING.
    METHODS sum_empty         FOR TESTING.
    METHODS join_separator    FOR TESTING.
    METHODS csv_concat        FOR TESTING.
    METHODS multi_accum       FOR TESTING.
    METHODS conditional_count FOR TESTING.
    METHODS max_value         FOR TESTING.
    METHODS max_empty         FOR TESTING.
    METHODS longest           FOR TESTING.
    METHODS even_square_build FOR TESTING.
    METHODS where_filter      FOR TESTING.
    METHODS triangular_until  FOR TESTING.
    METHODS triangular_zero   FOR TESTING.
    METHODS while_count       FOR TESTING.
    METHODS while_zero        FOR TESTING.
    METHODS step_iteration    FOR TESTING.
    METHODS init_type_average FOR TESTING.
    METHODS group_aggregate   FOR TESTING.
ENDCLASS.


CLASS ltcl_reduce IMPLEMENTATION.
  METHOD setup.
    cut = NEW #( ).
  ENDMETHOD.

  METHOD factorial_five.
    cl_abap_unit_assert=>assert_equals( act = cut->factorial( 5 ) exp = 120 ).
  ENDMETHOD.

  METHOD factorial_zero.
    cl_abap_unit_assert=>assert_equals( act = cut->factorial( 0 ) exp = 1 ).
  ENDMETHOD.

  METHOD sum_compound.
    " 1+2+3+4+5 = 15.
    cl_abap_unit_assert=>assert_equals(
      act = cut->sum_of( VALUE #( ( 1 ) ( 2 ) ( 3 ) ( 4 ) ( 5 ) ) ) exp = 15 ).
  ENDMETHOD.

  METHOD sum_empty.
    " 빈 입력 -> FOR 0회, 초기값 0.
    cl_abap_unit_assert=>assert_equals( act = cut->sum_of( VALUE #( ) ) exp = 0 ).
  ENDMETHOD.

  METHOD join_separator.
    cl_abap_unit_assert=>assert_equals( act = cut->join_with( `-` ) exp = `ABAP-is-fun` ).
  ENDMETHOD.

  METHOD csv_concat.
    cl_abap_unit_assert=>assert_equals( act = cut->to_csv( ) exp = `1,2,3,4,5` ).
  ENDMETHOD.

  METHOD multi_accum.
    cl_abap_unit_assert=>assert_equals( act = cut->sum_and_count( ) exp = `15/5` ).
  ENDMETHOD.

  METHOD conditional_count.
    cl_abap_unit_assert=>assert_equals( act = cut->count_evens( ) exp = 2 ).
  ENDMETHOD.

  METHOD max_value.
    cl_abap_unit_assert=>assert_equals(
      act = cut->max_of( VALUE #( ( 3 ) ( 9 ) ( 1 ) ( 7 ) ) ) exp = 9 ).
  ENDMETHOD.

  METHOD max_empty.
    cl_abap_unit_assert=>assert_equals( act = cut->max_of( VALUE #( ) ) exp = 0 ).
  ENDMETHOD.

  METHOD longest.
    " go(2) ABAP(4) is(2) clean(5) -> clean.
    cl_abap_unit_assert=>assert_equals( act = cut->longest_word( ) exp = `clean` ).
  ENDMETHOD.

  METHOD even_square_build.
    " 1..5 중 짝수 2,4 -> 제곱 4,16.
    cl_abap_unit_assert=>assert_equals(
      act = cut->even_squares( ) exp = VALUE zcl_modulo_expr03_reduce=>numbers( ( 4 ) ( 16 ) ) ).
  ENDMETHOD.

  METHOD where_filter.
    " AA: 380+320 = 700, LH: 280+180 = 460.
    cl_abap_unit_assert=>assert_equals( act = cut->seats_of_carrier( 'AA' ) exp = 700 ).
    cl_abap_unit_assert=>assert_equals( act = cut->seats_of_carrier( 'LH' ) exp = 460 ).
  ENDMETHOD.

  METHOD triangular_until.
    " 1+2+3+4+5 = 15.
    cl_abap_unit_assert=>assert_equals( act = cut->triangular( 5 ) exp = 15 ).
  ENDMETHOD.

  METHOD triangular_zero.
    " UNTIL pre-test: i=1, 1>0 즉시 참 -> 0회 -> 0.
    cl_abap_unit_assert=>assert_equals( act = cut->triangular( 0 ) exp = 0 ).
  ENDMETHOD.

  METHOD while_count.
    " i=1,2,3 (i<4) -> 3.
    cl_abap_unit_assert=>assert_equals( act = cut->count_while( 4 ) exp = 3 ).
  ENDMETHOD.

  METHOD while_zero.
    " WHILE pre-test: i=1, 1<1 거짓 -> 0회 -> 0.
    cl_abap_unit_assert=>assert_equals( act = cut->count_while( 1 ) exp = 0 ).
  ENDMETHOD.

  METHOD step_iteration.
    " STEP 2: 1,3,5,7,9 = 25.
    cl_abap_unit_assert=>assert_equals( act = cut->sum_odd_steps( 9 ) exp = 25 ).
  ENDMETHOD.

  METHOD init_type_average.
    " total 15 / count 5 = 3.
    cl_abap_unit_assert=>assert_equals(
      act = cut->average_of( VALUE #( ( 1 ) ( 2 ) ( 3 ) ( 4 ) ( 5 ) ) ) exp = 3 ).
  ENDMETHOD.

  METHOD group_aggregate.
    " AA=700; LH=460 (carrier 오름차순).
    cl_abap_unit_assert=>assert_equals( act = cut->seats_per_carrier( ) exp = `AA=700;LH=460` ).
  ENDMETHOD.
ENDCLASS.
