CLASS ltcl_conv DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA cut TYPE REF TO zcl_modulo_expr04_conv.
    METHODS setup.
    METHODS conv_string_to_int FOR TESTING.
    METHODS cast_downcast      FOR TESTING.
    METHODS ref_mutates_source FOR TESTING.
    METHODS exact_lossless     FOR TESTING.
    METHODS exact_lossy_guard  FOR TESTING.
ENDCLASS.


CLASS ltcl_conv IMPLEMENTATION.
  METHOD setup.
    cut = NEW #( ).
  ENDMETHOD.

  METHOD conv_string_to_int.
    cl_abap_unit_assert=>assert_equals( act = cut->to_integer( `42` ) exp = 42 ).
  ENDMETHOD.

  METHOD cast_downcast.
    cl_abap_unit_assert=>assert_equals( act = cut->cast_dog_fetch( ) exp = `fetch!` ).
  ENDMETHOD.

  METHOD ref_mutates_source.
    cl_abap_unit_assert=>assert_equals( act = cut->bump_via_ref( ) exp = 15 ).
  ENDMETHOD.

  METHOD exact_lossless.
    cl_abap_unit_assert=>assert_equals( act = cut->exact_int( '4' ) exp = 4 ).
  ENDMETHOD.

  METHOD exact_lossy_guard.
    " 4.5는 정수로 무손실 변환 불가 -> EXACT가 예외 -> -1.
    cl_abap_unit_assert=>assert_equals( act = cut->exact_int( '4.5' ) exp = -1 ).
  ENDMETHOD.
ENDCLASS.
