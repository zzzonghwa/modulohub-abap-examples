CLASS ltcl_clean DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA cut TYPE REF TO zcl_modulo_tst04_clean.
    METHODS setup.
    METHODS weekend_true   FOR TESTING.
    METHODS weekend_false  FOR TESTING.
    METHODS discount_tiers FOR TESTING.
    METHODS first_word_normal FOR TESTING.
    METHODS first_word_guard  FOR TESTING.
ENDCLASS.


CLASS ltcl_clean IMPLEMENTATION.
  METHOD setup.
    cut = NEW #( ).
  ENDMETHOD.

  METHOD weekend_true.
    cl_abap_unit_assert=>assert_true( act = cut->is_weekend( 6 ) ).
    cl_abap_unit_assert=>assert_true( act = cut->is_weekend( 7 ) ).
  ENDMETHOD.

  METHOD weekend_false.
    cl_abap_unit_assert=>assert_false( act = cut->is_weekend( 3 ) ).
  ENDMETHOD.

  METHOD discount_tiers.
    cl_abap_unit_assert=>assert_equals( act = cut->discount_rate( `GOLD` )   exp = 20 ).
    cl_abap_unit_assert=>assert_equals( act = cut->discount_rate( `SILVER` ) exp = 10 ).
    cl_abap_unit_assert=>assert_equals( act = cut->discount_rate( `NONE` )   exp = 0 ).
  ENDMETHOD.

  METHOD first_word_normal.
    cl_abap_unit_assert=>assert_equals( act = cut->first_word( `hello abap world` ) exp = `hello` ).
    cl_abap_unit_assert=>assert_equals( act = cut->first_word( `single` )           exp = `single` ).
  ENDMETHOD.

  METHOD first_word_guard.
    cl_abap_unit_assert=>assert_initial( act = cut->first_word( `` ) ).
  ENDMETHOD.
ENDCLASS.
