CLASS zcl_modulo_exec06_dml DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    "! ADT에서 F9(Run As -> ABAP Application)로 바로 실행해 데모 출력을 본다.
    "!
    "! DB 변경문(INSERT/UPDATE/MODIFY/DELETE)·LUW 문제제기 — DDIC 테이블 ZMODULO_FLIGHT 대상.
    "! - 각 메서드는 sy-subrc(0성공/4없음·중복)·sy-dbcnt(영향 행 수)를 평가한다.
    "! - 변경은 다음 DB 커밋까지 보류 — COMMIT WORK로 확정, ROLLBACK WORK로 취소(LUW).
    "! 표는 import 직후 비어 있다 — F9 출력은 0/실패일 수 있고, 결정적 검증은 ABAP Unit이
    "! osql 더블(CL_OSQL_TEST_ENVIRONMENT, INSERT/UPDATE/MODIFY/DELETE도 가로챔)로 수행한다.
    INTERFACES if_oo_adt_classrun.

    "! INSERT 한 행. 중복 키면 sy-subrc=4 -> abap_false.
    "! @parameter flight | 적재할 항공편(키 CARRID·CONNID + 좌석)
    "! @parameter result | 새로 들어가면 abap_true, 중복이면 abap_false
    METHODS insert_flight
      IMPORTING flight        TYPE zmodulo_flight
      RETURNING VALUE(result) TYPE abap_bool.

    "! UPDATE FROM @wa: 키(CARRID·CONNID)로 한 행을 통째 갱신. 키가 없으면 dbcnt=0.
    "! @parameter flight | 갱신할 항공편(키 + 새 값)
    "! @parameter result | 변경된 행 수(sy-dbcnt)
    METHODS update_flight
      IMPORTING flight        TYPE zmodulo_flight
      RETURNING VALUE(result) TYPE i.

    "! MODIFY = 업서트: 키 없으면 INSERT, 있으면 UPDATE. 멱등.
    "! @parameter flight | 적재/갱신할 항공편
    METHODS upsert_flight
      IMPORTING flight TYPE zmodulo_flight.

    "! DELETE ... WHERE: 키로 한 행 삭제. 없던 행이면 dbcnt=0.
    "! @parameter carrid | 항공사 코드
    "! @parameter connid | 연결 번호
    "! @parameter result | 삭제된 행 수(sy-dbcnt)
    METHODS delete_flight
      IMPORTING carrid        TYPE zmodulo_flight-carrid
                connid        TYPE zmodulo_flight-connid
      RETURNING VALUE(result) TYPE i.

    "! 전체 행 수.
    "! @parameter result | ZMODULO_FLIGHT 행 수
    METHODS count
      RETURNING VALUE(result) TYPE i.
ENDCLASS.


CLASS zcl_modulo_exec06_dml IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    out->write( `=== EXEC06 DB 변경문 (INSERT/UPDATE/MODIFY/DELETE) ===` ).
    out->write( `import 직후 표는 비어 있다 — 결정적 검증은 ABAP Unit(osql 더블).` ).
    DATA(flight) = VALUE zmodulo_flight( carrid = 'AA' connid = '0017' seatsmax = 380 seatsocc = 100 ).
    out->write( |count(시작)   = { count( ) }| ).
    out->write( |insert_flight = { insert_flight( flight ) }| ).
    flight-seatsocc = 222.
    out->write( |update_flight = { update_flight( flight ) }| ).
    upsert_flight( VALUE #( carrid = 'LH' connid = '0400' seatsmax = 280 seatsocc = 10 ) ).
    out->write( |count(업서트) = { count( ) }| ).
    out->write( |delete_flight = { delete_flight( carrid = 'AA' connid = '0017' ) }| ).
    " 데모 변경을 되돌려 표를 깨끗이 둔다 — ROLLBACK WORK = LUW의 보류 변경 폐기.
    ROLLBACK WORK.
  ENDMETHOD.

  METHOD insert_flight.
    INSERT zmodulo_flight FROM @flight.
    " sy-subrc=0 신규 삽입, 4=중복 키.
    result = xsdbool( sy-subrc = 0 ).
  ENDMETHOD.

  METHOD update_flight.
    " 작업영역(@flight)의 키로 행을 찾아 비키 필드를 통째 갱신한다.
    UPDATE zmodulo_flight FROM @flight.
    result = sy-dbcnt.
  ENDMETHOD.

  METHOD upsert_flight.
    " MODIFY = 업서트: 키 없으면 INSERT, 있으면 UPDATE. 멱등.
    MODIFY zmodulo_flight FROM @flight.
  ENDMETHOD.

  METHOD delete_flight.
    DELETE FROM zmodulo_flight
      WHERE carrid = @carrid AND connid = @connid.
    result = sy-dbcnt.
  ENDMETHOD.

  METHOD count.
    SELECT COUNT(*) FROM zmodulo_flight INTO @result.
  ENDMETHOD.
ENDCLASS.
