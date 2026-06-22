CLASS ltcl_dml DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    " osql 더블은 SELECT뿐 아니라 INSERT/UPDATE/MODIFY/DELETE도 가로챈다(실 DB 미변경).
    CLASS-DATA environment TYPE REF TO if_osql_test_environment.
    CLASS-METHODS class_setup.
    CLASS-METHODS class_teardown.

    DATA cut TYPE REF TO zcl_modulo_exec06_dml.
    METHODS setup.
    METHODS seed IMPORTING flights TYPE STANDARD TABLE.

    METHODS insert_new_succeeds   FOR TESTING.
    METHODS insert_duplicate_fails FOR TESTING.
    METHODS update_changes_row    FOR TESTING.
    METHODS update_missing_zero   FOR TESTING.
    METHODS upsert_insert_update  FOR TESTING.
    METHODS delete_removes_row    FOR TESTING.
    METHODS delete_missing_zero   FOR TESTING.
ENDCLASS.


CLASS ltcl_dml IMPLEMENTATION.
  METHOD class_setup.
    environment = cl_osql_test_environment=>create(
      i_dependency_list = VALUE #( ( 'ZMODULO_FLIGHT' ) ) ).
  ENDMETHOD.

  METHOD class_teardown.
    environment->destroy( ).
  ENDMETHOD.

  METHOD setup.
    environment->clear_doubles( ).
    cut = NEW #( ).
  ENDMETHOD.

  METHOD seed.
    " MANDT는 비워 둔다 — Open SQL/osql이 암묵 클라이언트 처리.
    environment->insert_test_data( i_data = flights ).
  ENDMETHOD.

  METHOD insert_new_succeeds.
    DATA(ok) = cut->insert_flight(
      VALUE #( carrid = 'AA' connid = '0017' seatsmax = 380 seatsocc = 100 ) ).
    cl_abap_unit_assert=>assert_true( ok ).
    cl_abap_unit_assert=>assert_equals( act = cut->count( ) exp = 1 ).
  ENDMETHOD.

  METHOD insert_duplicate_fails.
    DATA flights TYPE STANDARD TABLE OF zmodulo_flight WITH EMPTY KEY.
    flights = VALUE #( ( carrid = 'AA' connid = '0017' seatsmax = 380 seatsocc = 100 ) ).
    seed( flights ).
    " 같은 키 재삽입 -> sy-subrc=4 -> abap_false.
    DATA(ok) = cut->insert_flight(
      VALUE #( carrid = 'AA' connid = '0017' seatsmax = 380 seatsocc = 200 ) ).
    cl_abap_unit_assert=>assert_false( ok ).
    cl_abap_unit_assert=>assert_equals( act = cut->count( ) exp = 1 ).
  ENDMETHOD.

  METHOD update_changes_row.
    DATA flights TYPE STANDARD TABLE OF zmodulo_flight WITH EMPTY KEY.
    flights = VALUE #( ( carrid = 'AA' connid = '0017' seatsmax = 380 seatsocc = 100 ) ).
    seed( flights ).
    DATA(changed) = cut->update_flight(
      VALUE #( carrid = 'AA' connid = '0017' seatsmax = 380 seatsocc = 222 ) ).
    cl_abap_unit_assert=>assert_equals( act = changed exp = 1 ).
    SELECT SINGLE seatsocc FROM zmodulo_flight
      WHERE carrid = 'AA' AND connid = '0017' INTO @DATA(occ).
    cl_abap_unit_assert=>assert_equals( act = occ exp = 222 ).
  ENDMETHOD.

  METHOD update_missing_zero.
    cl_abap_unit_assert=>assert_equals(
      act = cut->update_flight( VALUE #( carrid = 'ZZ' connid = '9999' seatsmax = 1 seatsocc = 1 ) )
      exp = 0 ).
  ENDMETHOD.

  METHOD upsert_insert_update.
    " 1차: 키 없음 -> INSERT.
    cut->upsert_flight( VALUE #( carrid = 'LH' connid = '0400' seatsmax = 280 seatsocc = 10 ) ).
    cl_abap_unit_assert=>assert_equals( act = cut->count( ) exp = 1 ).
    " 2차: 같은 키 -> UPDATE(행 수 그대로, 값 갱신).
    cut->upsert_flight( VALUE #( carrid = 'LH' connid = '0400' seatsmax = 280 seatsocc = 55 ) ).
    cl_abap_unit_assert=>assert_equals( act = cut->count( ) exp = 1 ).
    SELECT SINGLE seatsocc FROM zmodulo_flight
      WHERE carrid = 'LH' AND connid = '0400' INTO @DATA(occ).
    cl_abap_unit_assert=>assert_equals( act = occ exp = 55 ).
  ENDMETHOD.

  METHOD delete_removes_row.
    DATA flights TYPE STANDARD TABLE OF zmodulo_flight WITH EMPTY KEY.
    flights = VALUE #( ( carrid = 'AA' connid = '0017' seatsmax = 380 seatsocc = 100 )
                       ( carrid = 'AA' connid = '0064' seatsmax = 320 seatsocc = 240 ) ).
    seed( flights ).
    DATA(deleted) = cut->delete_flight( carrid = 'AA' connid = '0017' ).
    cl_abap_unit_assert=>assert_equals( act = deleted exp = 1 ).
    cl_abap_unit_assert=>assert_equals( act = cut->count( ) exp = 1 ).
  ENDMETHOD.

  METHOD delete_missing_zero.
    cl_abap_unit_assert=>assert_equals(
      act = cut->delete_flight( carrid = 'ZZ' connid = '9999' ) exp = 0 ).
  ENDMETHOD.
ENDCLASS.
