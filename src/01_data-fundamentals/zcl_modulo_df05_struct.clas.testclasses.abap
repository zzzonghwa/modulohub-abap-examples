CLASS ltcl_struct DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA cut TYPE REF TO zcl_modulo_df05_struct.
    METHODS setup.
    METHODS formats_a_label      FOR TESTING.
    METHODS complete_when_filled FOR TESTING.
    METHODS incomplete_when_blank FOR TESTING.
    METHODS replaces_only_city   FOR TESTING.
    METHODS clears_the_city      FOR TESTING.
    METHODS maps_name_to_contact FOR TESTING.
ENDCLASS.


CLASS ltcl_struct IMPLEMENTATION.
  METHOD setup.
    cut = NEW #( ).
  ENDMETHOD.

  METHOD formats_a_label.
    DATA(addr) = VALUE zcl_modulo_df05_struct=>address(
      person_name = `Kim` city = `Seoul` ).
    cl_abap_unit_assert=>assert_equals(
      act = cut->format_label( addr ) exp = `Kim, Seoul` ).
  ENDMETHOD.

  METHOD complete_when_filled.
    DATA(addr) = VALUE zcl_modulo_df05_struct=>address(
      person_name = `Kim` city = `Seoul` ).
    cl_abap_unit_assert=>assert_true( cut->is_complete( addr ) ).
  ENDMETHOD.

  METHOD incomplete_when_blank.
    DATA(addr) = VALUE zcl_modulo_df05_struct=>address( person_name = `Kim` ).
    cl_abap_unit_assert=>assert_false( cut->is_complete( addr ) ).
  ENDMETHOD.

  METHOD replaces_only_city.
    DATA(addr) = VALUE zcl_modulo_df05_struct=>address(
      person_name = `Kim` city = `Seoul` ).
    DATA(moved) = cut->with_city( addr = addr city = `Busan` ).
    cl_abap_unit_assert=>assert_equals( act = moved-person_name exp = `Kim` ).
    cl_abap_unit_assert=>assert_equals( act = moved-city        exp = `Busan` ).
  ENDMETHOD.

  METHOD clears_the_city.
    DATA(addr) = VALUE zcl_modulo_df05_struct=>address(
      person_name = `Kim` city = `Seoul` ).
    DATA(result) = cut->clear_city( addr ).
    cl_abap_unit_assert=>assert_equals( act = result-person_name exp = `Kim` ).
    cl_abap_unit_assert=>assert_initial( result-city ).
  ENDMETHOD.

  METHOD maps_name_to_contact.
    " GIVEN 주소 / WHEN CORRESPONDING / THEN 동명 컴포넌트(person_name)만 이동
    DATA(addr) = VALUE zcl_modulo_df05_struct=>address(
      person_name = `Kim` city = `Seoul` ).
    DATA(result) = cut->to_contact( addr ).
    cl_abap_unit_assert=>assert_equals( act = result-person_name exp = `Kim` ).
    cl_abap_unit_assert=>assert_initial( result-phone ).
  ENDMETHOD.
ENDCLASS.
