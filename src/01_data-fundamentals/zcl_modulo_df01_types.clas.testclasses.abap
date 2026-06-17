CLASS ltcl_types DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA cut TYPE REF TO zcl_modulo_df01_types.
    METHODS setup.
    METHODS empty_list_is_empty   FOR TESTING.
    METHODS filled_list_not_empty FOR TESTING.
    METHODS picks_the_maximum     FOR TESTING.
    METHODS max_empty_is_zero     FOR TESTING.
    METHODS picks_the_minimum     FOR TESTING.
    METHODS sums_the_list         FOR TESTING.
    METHODS averages_the_list     FOR TESTING.
    METHODS average_empty_raises  FOR TESTING.
ENDCLASS.


CLASS ltcl_types IMPLEMENTATION.
  METHOD setup.
    cut = NEW #( ).
  ENDMETHOD.

  METHOD empty_list_is_empty.
    cl_abap_unit_assert=>assert_true( cut->is_empty( VALUE #( ) ) ).
  ENDMETHOD.

  METHOD filled_list_not_empty.
    cl_abap_unit_assert=>assert_false( cut->is_empty( VALUE #( ( 1 ) ) ) ).
  ENDMETHOD.

  METHOD picks_the_maximum.
    DATA(counts) = VALUE zcl_modulo_df01_types=>count_list( ( 3 ) ( 7 ) ( 2 ) ).
    cl_abap_unit_assert=>assert_equals( act = cut->highest_count( counts ) exp = 7 ).
  ENDMETHOD.

  METHOD max_empty_is_zero.
    cl_abap_unit_assert=>assert_equals( act = cut->highest_count( VALUE #( ) ) exp = 0 ).
  ENDMETHOD.

  METHOD picks_the_minimum.
    DATA(counts) = VALUE zcl_modulo_df01_types=>count_list( ( 3 ) ( 7 ) ( 2 ) ).
    cl_abap_unit_assert=>assert_equals( act = cut->lowest_count( counts ) exp = 2 ).
  ENDMETHOD.

  METHOD sums_the_list.
    DATA(counts) = VALUE zcl_modulo_df01_types=>count_list( ( 10 ) ( 20 ) ( 5 ) ).
    cl_abap_unit_assert=>assert_equals( act = cut->total_count( counts ) exp = 35 ).
  ENDMETHOD.

  METHOD averages_the_list.
    " GIVEN (2,4,6) / WHEN 평균 / THEN 4
    DATA(counts) = VALUE zcl_modulo_df01_types=>count_list( ( 2 ) ( 4 ) ( 6 ) ).
    cl_abap_unit_assert=>assert_equals(
      act = cut->average_count( counts )
      exp = CONV decfloat34( '4' ) ).
  ENDMETHOD.

  METHOD average_empty_raises.
    " GIVEN 빈 리스트 / WHEN 평균 / THEN 가드 예외
    TRY.
        cut->average_count( VALUE #( ) ).
        cl_abap_unit_assert=>fail( msg = '빈 리스트는 예외여야 한다' ).
      CATCH cx_parameter_invalid_range.
        " THEN 기대한 예외
    ENDTRY.
  ENDMETHOD.
ENDCLASS.
