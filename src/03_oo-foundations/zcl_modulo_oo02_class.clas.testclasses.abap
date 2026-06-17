CLASS ltcl_account DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA cut TYPE REF TO lcl_account.
    METHODS setup.
    METHODS deposit_increases_balance FOR TESTING.
    METHODS withdraw_decreases_balance FOR TESTING.
    METHODS withdraw_insufficient_kept FOR TESTING.
    METHODS instances_are_independent  FOR TESTING.
    METHODS currency_is_constructed    FOR TESTING.
ENDCLASS.


CLASS ltcl_account IMPLEMENTATION.
  METHOD setup.
    cut = NEW #( `KRW` ).
  ENDMETHOD.

  METHOD deposit_increases_balance.
    cut->deposit( 1000 ).
    cl_abap_unit_assert=>assert_equals(
      act = cut->balance( )
      exp = CONV lcl_account=>money( '1000.00' ) ).
  ENDMETHOD.

  METHOD withdraw_decreases_balance.
    cut->deposit( 1000 ).
    DATA(ok) = cut->withdraw( 300 ).

    cl_abap_unit_assert=>assert_true( ok ).
    cl_abap_unit_assert=>assert_equals(
      act = cut->balance( )
      exp = CONV lcl_account=>money( '700.00' ) ).
  ENDMETHOD.

  METHOD withdraw_insufficient_kept.
    cut->deposit( 100 ).
    " 잔액 부족 인출은 거부되고 잔액은 그대로다.
    DATA(ok) = cut->withdraw( 999 ).

    cl_abap_unit_assert=>assert_false( ok ).
    cl_abap_unit_assert=>assert_equals(
      act = cut->balance( )
      exp = CONV lcl_account=>money( '100.00' ) ).
  ENDMETHOD.

  METHOD instances_are_independent.
    DATA(other) = NEW lcl_account( `USD` ).
    cut->deposit( 500 ).
    other->deposit( 20 ).

    " 한 객체의 상태 변화가 다른 객체에 영향을 주지 않는다.
    cl_abap_unit_assert=>assert_equals(
      act = cut->balance( )
      exp = CONV lcl_account=>money( '500.00' ) ).
    cl_abap_unit_assert=>assert_equals(
      act = other->balance( )
      exp = CONV lcl_account=>money( '20.00' ) ).
  ENDMETHOD.

  METHOD currency_is_constructed.
    cl_abap_unit_assert=>assert_equals( act = cut->currency exp = `KRW` ).
  ENDMETHOD.
ENDCLASS.
