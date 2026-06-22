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

    METHODS insert_new_succeeds    FOR TESTING.
    METHODS insert_duplicate_fails FOR TESTING.
    METHODS insert_via_values_ok   FOR TESTING.
    METHODS insert_bulk_skips_dup  FOR TESTING.
    METHODS update_changes_row     FOR TESTING.
    METHODS update_missing_zero    FOR TESTING.
    METHODS set_occupancy_only_col FOR TESTING.
    METHODS upsert_insert_update   FOR TESTING.
    METHODS upsert_bulk_mixed      FOR TESTING.
    METHODS delete_removes_row     FOR TESTING.
    METHODS delete_missing_zero    FOR TESTING.
    METHODS delete_bulk_keys       FOR TESTING.
    METHODS delete_all_clears      FOR TESTING.
    METHODS transfer_commits       FOR TESTING.
    METHODS transfer_rolls_back    FOR TESTING.
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

  METHOD insert_via_values_ok.
    " VALUES 호스트식 INSERT — 신규 키는 성공(abap_true), 행 1개.
    DATA(ok) = cut->insert_via_values( carrid = 'AA' connid = '0064' seatsmax = 320 ).
    cl_abap_unit_assert=>assert_true( ok ).
    cl_abap_unit_assert=>assert_equals( act = cut->count( ) exp = 1 ).
  ENDMETHOD.

  METHOD insert_bulk_skips_dup.
    DATA flights TYPE STANDARD TABLE OF zmodulo_flight WITH EMPTY KEY.
    flights = VALUE #( ( carrid = 'AA' connid = '0017' seatsmax = 380 seatsocc = 100 ) ).
    seed( flights ).
    " 3행 중 1행(AA/0017)은 중복 -> 건너뜀. 실제 삽입은 2행.
    DATA(inserted) = cut->insert_bulk( VALUE zcl_modulo_exec06_dml=>flight_tab(
      ( carrid = 'AA' connid = '0017' seatsmax = 380 seatsocc = 999 )
      ( carrid = 'AA' connid = '0064' seatsmax = 320 seatsocc = 240 )
      ( carrid = 'LH' connid = '0400' seatsmax = 280 seatsocc = 280 ) ) ).
    cl_abap_unit_assert=>assert_equals( act = inserted exp = 2 ).
    cl_abap_unit_assert=>assert_equals( act = cut->count( ) exp = 3 ).
  ENDMETHOD.

  METHOD update_changes_row.
    DATA flights TYPE STANDARD TABLE OF zmodulo_flight WITH EMPTY KEY.
    flights = VALUE #( ( carrid = 'AA' connid = '0017' seatsmax = 380 seatsocc = 100 ) ).
    seed( flights ).
    DATA(changed) = cut->update_flight(
      VALUE #( carrid = 'AA' connid = '0017' seatsmax = 380 seatsocc = 222 ) ).
    cl_abap_unit_assert=>assert_equals( act = changed exp = 1 ).
    cl_abap_unit_assert=>assert_equals(
      act = cut->occupancy( carrid = 'AA' connid = '0017' ) exp = 222 ).
  ENDMETHOD.

  METHOD update_missing_zero.
    cl_abap_unit_assert=>assert_equals(
      act = cut->update_flight( VALUE #( carrid = 'ZZ' connid = '9999' seatsmax = 1 seatsocc = 1 ) )
      exp = 0 ).
  ENDMETHOD.

  METHOD set_occupancy_only_col.
    DATA flights TYPE STANDARD TABLE OF zmodulo_flight WITH EMPTY KEY.
    flights = VALUE #( ( carrid = 'AA' connid = '0017' seatsmax = 380 seatsocc = 100 ) ).
    seed( flights ).
    DATA(changed) = cut->set_occupancy( carrid = 'AA' connid = '0017' seatsocc = 290 ).
    cl_abap_unit_assert=>assert_equals( act = changed exp = 1 ).
    " seatsocc만 290으로 바뀌고 seatsmax(380)는 보존되어야 한다.
    SELECT SINGLE seatsmax, seatsocc FROM zmodulo_flight
      WHERE carrid = 'AA' AND connid = '0017' INTO @DATA(row).
    cl_abap_unit_assert=>assert_equals( act = row-seatsmax exp = 380 ).
    cl_abap_unit_assert=>assert_equals( act = row-seatsocc exp = 290 ).
  ENDMETHOD.

  METHOD upsert_insert_update.
    " 1차: 키 없음 -> INSERT.
    cut->upsert_flight( VALUE #( carrid = 'LH' connid = '0400' seatsmax = 280 seatsocc = 10 ) ).
    cl_abap_unit_assert=>assert_equals( act = cut->count( ) exp = 1 ).
    " 2차: 같은 키 -> UPDATE(행 수 그대로, 값 갱신).
    cut->upsert_flight( VALUE #( carrid = 'LH' connid = '0400' seatsmax = 280 seatsocc = 55 ) ).
    cl_abap_unit_assert=>assert_equals( act = cut->count( ) exp = 1 ).
    cl_abap_unit_assert=>assert_equals(
      act = cut->occupancy( carrid = 'LH' connid = '0400' ) exp = 55 ).
  ENDMETHOD.

  METHOD upsert_bulk_mixed.
    DATA flights TYPE STANDARD TABLE OF zmodulo_flight WITH EMPTY KEY.
    flights = VALUE #( ( carrid = 'AA' connid = '0017' seatsmax = 380 seatsocc = 100 ) ).
    seed( flights ).
    " 2행: 기존 AA/0017은 UPDATE, 신규 LH/0400은 INSERT -> 처리 2행, 총 2행.
    DATA(touched) = cut->upsert_bulk( VALUE zcl_modulo_exec06_dml=>flight_tab(
      ( carrid = 'AA' connid = '0017' seatsmax = 380 seatsocc = 333 )
      ( carrid = 'LH' connid = '0400' seatsmax = 280 seatsocc = 50 ) ) ).
    cl_abap_unit_assert=>assert_equals( act = touched exp = 2 ).
    cl_abap_unit_assert=>assert_equals( act = cut->count( ) exp = 2 ).
    cl_abap_unit_assert=>assert_equals(
      act = cut->occupancy( carrid = 'AA' connid = '0017' ) exp = 333 ).
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

  METHOD delete_bulk_keys.
    DATA flights TYPE STANDARD TABLE OF zmodulo_flight WITH EMPTY KEY.
    flights = VALUE #( ( carrid = 'AA' connid = '0017' seatsmax = 380 seatsocc = 100 )
                       ( carrid = 'AA' connid = '0064' seatsmax = 320 seatsocc = 240 )
                       ( carrid = 'LH' connid = '0400' seatsmax = 280 seatsocc = 280 ) ).
    seed( flights ).
    " 키 2개로 일괄 삭제(비키 필드는 무시) -> 2행 삭제, 1행 잔존.
    DATA(deleted) = cut->delete_bulk( VALUE zcl_modulo_exec06_dml=>flight_tab(
      ( carrid = 'AA' connid = '0017' )
      ( carrid = 'LH' connid = '0400' ) ) ).
    cl_abap_unit_assert=>assert_equals( act = deleted exp = 2 ).
    cl_abap_unit_assert=>assert_equals( act = cut->count( ) exp = 1 ).
  ENDMETHOD.

  METHOD delete_all_clears.
    DATA flights TYPE STANDARD TABLE OF zmodulo_flight WITH EMPTY KEY.
    flights = VALUE #( ( carrid = 'AA' connid = '0017' seatsmax = 380 seatsocc = 100 )
                       ( carrid = 'LH' connid = '0400' seatsmax = 280 seatsocc = 280 ) ).
    seed( flights ).
    " WHERE 없는 DELETE -> 전체 삭제. dbcnt=직전 행 수(2), 이후 0행.
    DATA(deleted) = cut->delete_all( ).
    cl_abap_unit_assert=>assert_equals( act = deleted exp = 2 ).
    cl_abap_unit_assert=>assert_equals( act = cut->count( ) exp = 0 ).
  ENDMETHOD.

  METHOD transfer_commits.
    DATA flights TYPE STANDARD TABLE OF zmodulo_flight WITH EMPTY KEY.
    flights = VALUE #( ( carrid = 'AA' connid = '0017' seatsmax = 380 seatsocc = 100 )
                       ( carrid = 'AA' connid = '0064' seatsmax = 320 seatsocc = 200 ) ).
    seed( flights ).
    " 두 행 모두 존재 -> 두 UPDATE 성공 -> COMMIT, abap_true.
    DATA(ok) = cut->transfer_seats(
      carrid = 'AA' from_connid = '0017' to_connid = '0064' seats = 30 ).
    cl_abap_unit_assert=>assert_true( ok ).
    " 100 - 30 = 70, 200 + 30 = 230.
    cl_abap_unit_assert=>assert_equals(
      act = cut->occupancy( carrid = 'AA' connid = '0017' ) exp = 70 ).
    cl_abap_unit_assert=>assert_equals(
      act = cut->occupancy( carrid = 'AA' connid = '0064' ) exp = 230 ).
  ENDMETHOD.

  METHOD transfer_rolls_back.
    DATA flights TYPE STANDARD TABLE OF zmodulo_flight WITH EMPTY KEY.
    flights = VALUE #( ( carrid = 'AA' connid = '0017' seatsmax = 380 seatsocc = 100 ) ).
    seed( flights ).
    " to_connid가 없음 -> 두 번째 UPDATE 미매칭 -> ROLLBACK, abap_false.
    DATA(ok) = cut->transfer_seats(
      carrid = 'AA' from_connid = '0017' to_connid = '9999' seats = 30 ).
    cl_abap_unit_assert=>assert_false( ok ).
  ENDMETHOD.
ENDCLASS.
