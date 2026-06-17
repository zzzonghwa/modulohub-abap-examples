CLASS ltcl_ddic DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA cut TYPE REF TO zcl_modulo_df03_ddic.
    METHODS setup.
    METHODS debit_sign_is_debit   FOR TESTING.
    METHODS credit_sign_not_debit FOR TESTING.
    METHODS credit_sign_is_credit FOR TESTING.
    METHODS fixed_values_valid    FOR TESTING.
    METHODS unknown_not_valid     FOR TESTING.
    METHODS labels_debit          FOR TESTING.
    METHODS label_unknown_raises  FOR TESTING.
    METHODS opposite_of_debit     FOR TESTING.
ENDCLASS.


CLASS ltcl_ddic IMPLEMENTATION.
  METHOD setup.
    cut = NEW #( ).
  ENDMETHOD.

  METHOD debit_sign_is_debit.
    cl_abap_unit_assert=>assert_true( cut->is_debit( zcl_modulo_df03_ddic=>debit ) ).
  ENDMETHOD.

  METHOD credit_sign_not_debit.
    cl_abap_unit_assert=>assert_false( cut->is_debit( zcl_modulo_df03_ddic=>credit ) ).
  ENDMETHOD.

  METHOD credit_sign_is_credit.
    cl_abap_unit_assert=>assert_true( cut->is_credit( zcl_modulo_df03_ddic=>credit ) ).
  ENDMETHOD.

  METHOD fixed_values_valid.
    cl_abap_unit_assert=>assert_true( cut->is_valid( zcl_modulo_df03_ddic=>debit ) ).
    cl_abap_unit_assert=>assert_true( cut->is_valid( zcl_modulo_df03_ddic=>credit ) ).
  ENDMETHOD.

  METHOD unknown_not_valid.
    " GIVEN 'Z' (고정값 아님) / THEN 유효하지 않음 — 런타임은 막지 않으므로 가드 필요
    cl_abap_unit_assert=>assert_false( cut->is_valid( 'Z' ) ).
  ENDMETHOD.

  METHOD labels_debit.
    cl_abap_unit_assert=>assert_equals(
      act = cut->label_of( zcl_modulo_df03_ddic=>debit ) exp = `Debit` ).
  ENDMETHOD.

  METHOD label_unknown_raises.
    TRY.
        cut->label_of( 'Z' ).
        cl_abap_unit_assert=>fail( msg = '고정값 아닌 값은 예외여야 한다' ).
      CATCH cx_parameter_invalid_range.
    ENDTRY.
  ENDMETHOD.

  METHOD opposite_of_debit.
    cl_abap_unit_assert=>assert_equals(
      act = cut->opposite_of( zcl_modulo_df03_ddic=>debit )
      exp = zcl_modulo_df03_ddic=>credit ).
  ENDMETHOD.
ENDCLASS.
