CLASS ltcl_logic DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA cut TYPE REF TO zcl_modulo_pf02_logic.
    METHODS setup.
    METHODS empty_text_is_blank   FOR TESTING.
    METHODS filled_text_not_blank FOR TESTING.
    METHODS either_blank_detects  FOR TESTING.
    METHODS value_within_range    FOR TESTING.
    METHODS value_outside_range   FOR TESTING.
    METHODS finds_existing_value  FOR TESTING.
    METHODS misses_absent_value   FOR TESTING.
    METHODS all_positive_true     FOR TESTING.
    METHODS all_positive_false    FOR TESTING.
    METHODS detects_substring     FOR TESTING.
    METHODS detects_prefix        FOR TESTING.
    METHODS bound_and_unbound     FOR TESTING.
ENDCLASS.


CLASS ltcl_logic IMPLEMENTATION.
  METHOD setup.
    cut = NEW #( ).
  ENDMETHOD.

  METHOD empty_text_is_blank.
    cl_abap_unit_assert=>assert_true( cut->is_blank( `` ) ).
  ENDMETHOD.

  METHOD filled_text_not_blank.
    cl_abap_unit_assert=>assert_false( cut->is_blank( `x` ) ).
  ENDMETHOD.

  METHOD either_blank_detects.
    cl_abap_unit_assert=>assert_true(
      cut->either_blank( first = `a` second = `` ) ).
    cl_abap_unit_assert=>assert_false(
      cut->either_blank( first = `a` second = `b` ) ).
  ENDMETHOD.

  METHOD value_within_range.
    cl_abap_unit_assert=>assert_true(
      cut->in_range( value = 5 low = 1 high = 10 ) ).
  ENDMETHOD.

  METHOD value_outside_range.
    cl_abap_unit_assert=>assert_false(
      cut->in_range( value = 11 low = 1 high = 10 ) ).
  ENDMETHOD.

  METHOD finds_existing_value.
    DATA(numbers) = VALUE zcl_modulo_pf02_logic=>number_list( ( 1 ) ( 2 ) ( 3 ) ).
    cl_abap_unit_assert=>assert_true(
      cut->contains_value( numbers = numbers value = 2 ) ).
  ENDMETHOD.

  METHOD misses_absent_value.
    DATA(numbers) = VALUE zcl_modulo_pf02_logic=>number_list( ( 1 ) ( 2 ) ( 3 ) ).
    cl_abap_unit_assert=>assert_false(
      cut->contains_value( numbers = numbers value = 9 ) ).
  ENDMETHOD.

  METHOD all_positive_true.
    DATA(numbers) = VALUE zcl_modulo_pf02_logic=>number_list( ( 1 ) ( 2 ) ( 3 ) ).
    cl_abap_unit_assert=>assert_true( cut->all_positive( numbers ) ).
  ENDMETHOD.

  METHOD all_positive_false.
    DATA(numbers) = VALUE zcl_modulo_pf02_logic=>number_list( ( 1 ) ( -2 ) ( 3 ) ).
    cl_abap_unit_assert=>assert_false( cut->all_positive( numbers ) ).
  ENDMETHOD.

  METHOD detects_substring.
    cl_abap_unit_assert=>assert_true(
      cut->mentions( text = `clean abap` word = `abap` ) ).
  ENDMETHOD.

  METHOD detects_prefix.
    cl_abap_unit_assert=>assert_true(
      cut->starts_with( text = `abapGit` prefix = `abap` ) ).
    cl_abap_unit_assert=>assert_false(
      cut->starts_with( text = `clean` prefix = `abap` ) ).
  ENDMETHOD.

  METHOD bound_and_unbound.
    DATA unbound TYPE REF TO object.
    cl_abap_unit_assert=>assert_false( cut->is_bound( unbound ) ).
    cl_abap_unit_assert=>assert_true( cut->is_bound( NEW zcl_modulo_pf02_logic( ) ) ).
  ENDMETHOD.
ENDCLASS.
