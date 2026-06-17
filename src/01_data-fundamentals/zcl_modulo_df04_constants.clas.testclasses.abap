CLASS ltcl_constants DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA cut TYPE REF TO zcl_modulo_df04_constants.
    METHODS setup.
    METHODS default_is_info        FOR TESTING.
    METHODS error_blocks           FOR TESTING.
    METHODS warning_blocks         FOR TESTING.
    METHODS info_does_not_block    FOR TESTING.
    METHODS renders_level_text     FOR TESTING.
    METHODS escalates_info         FOR TESTING.
    METHODS error_stays_error      FOR TESTING.
    METHODS retries_hit_the_limit  FOR TESTING.
    METHODS remaining_is_clamped   FOR TESTING.
ENDCLASS.


CLASS ltcl_constants IMPLEMENTATION.
  METHOD setup.
    cut = NEW #( ).
  ENDMETHOD.

  METHOD default_is_info.
    cl_abap_unit_assert=>assert_equals(
      act = cut->default_level( ) exp = zcl_modulo_df04_constants=>info ).
  ENDMETHOD.

  METHOD error_blocks.
    cl_abap_unit_assert=>assert_true( cut->is_blocking( zcl_modulo_df04_constants=>error ) ).
  ENDMETHOD.

  METHOD warning_blocks.
    cl_abap_unit_assert=>assert_true( cut->is_blocking( zcl_modulo_df04_constants=>warning ) ).
  ENDMETHOD.

  METHOD info_does_not_block.
    cl_abap_unit_assert=>assert_false( cut->is_blocking( zcl_modulo_df04_constants=>info ) ).
  ENDMETHOD.

  METHOD renders_level_text.
    cl_abap_unit_assert=>assert_equals(
      act = cut->level_text( zcl_modulo_df04_constants=>warning ) exp = `warning` ).
  ENDMETHOD.

  METHOD escalates_info.
    cl_abap_unit_assert=>assert_equals(
      act = cut->escalate( zcl_modulo_df04_constants=>info )
      exp = zcl_modulo_df04_constants=>warning ).
  ENDMETHOD.

  METHOD error_stays_error.
    cl_abap_unit_assert=>assert_equals(
      act = cut->escalate( zcl_modulo_df04_constants=>error )
      exp = zcl_modulo_df04_constants=>error ).
  ENDMETHOD.

  METHOD retries_hit_the_limit.
    cl_abap_unit_assert=>assert_true( cut->retries_exhausted( 3 ) ).
    cl_abap_unit_assert=>assert_false( cut->retries_exhausted( 2 ) ).
  ENDMETHOD.

  METHOD remaining_is_clamped.
    " GIVEN 1회 시도 / THEN 2 남음
    cl_abap_unit_assert=>assert_equals( act = cut->remaining_retries( 1 ) exp = 2 ).
    " GIVEN 5회(한도 초과) / THEN 0으로 가드
    cl_abap_unit_assert=>assert_equals( act = cut->remaining_retries( 5 ) exp = 0 ).
  ENDMETHOD.
ENDCLASS.
