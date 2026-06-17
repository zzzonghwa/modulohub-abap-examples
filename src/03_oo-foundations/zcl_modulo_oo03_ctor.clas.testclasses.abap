CLASS ltcl_sequence DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS created_count_increases FOR TESTING.
    METHODS ids_are_sequential      FOR TESTING.
    METHODS label_is_stored         FOR TESTING.
ENDCLASS.


CLASS ltcl_sequence IMPLEMENTATION.
  METHOD created_count_increases.
    " CLASS-DATA는 세션 누적이므로 절대값이 아니라 증가분을 검증한다.
    DATA(before) = lcl_sequence=>created_count.
    DATA(one) = NEW lcl_sequence( `x` ).
    DATA(two) = NEW lcl_sequence( `y` ).

    cl_abap_unit_assert=>assert_bound( one ).
    cl_abap_unit_assert=>assert_bound( two ).
    cl_abap_unit_assert=>assert_equals(
      act = lcl_sequence=>created_count - before
      exp = 2 ).
  ENDMETHOD.

  METHOD ids_are_sequential.
    DATA(first)  = NEW lcl_sequence( `a` ).
    DATA(second) = NEW lcl_sequence( `b` ).

    cl_abap_unit_assert=>assert_equals(
      act = second->id - first->id
      exp = 1 ).
  ENDMETHOD.

  METHOD label_is_stored.
    DATA(seq) = NEW lcl_sequence( `invoice` ).
    cl_abap_unit_assert=>assert_equals( act = seq->label exp = `invoice` ).
  ENDMETHOD.
ENDCLASS.


CLASS ltcl_config DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS get_instance_is_bound   FOR TESTING.
    METHODS get_instance_is_same    FOR TESTING.
    METHODS state_is_shared         FOR TESTING.
ENDCLASS.


CLASS ltcl_config IMPLEMENTATION.
  METHOD get_instance_is_bound.
    cl_abap_unit_assert=>assert_bound( lcl_config=>get_instance( ) ).
  ENDMETHOD.

  METHOD get_instance_is_same.
    " 두 번 요청해도 동일 인스턴스(참조 동일성).
    cl_abap_unit_assert=>assert_equals(
      act = lcl_config=>get_instance( )
      exp = lcl_config=>get_instance( ) ).
  ENDMETHOD.

  METHOD state_is_shared.
    lcl_config=>get_instance( )->set_value( `region=KR` ).
    cl_abap_unit_assert=>assert_equals(
      act = lcl_config=>get_instance( )->get_value( )
      exp = `region=KR` ).
  ENDMETHOD.
ENDCLASS.
