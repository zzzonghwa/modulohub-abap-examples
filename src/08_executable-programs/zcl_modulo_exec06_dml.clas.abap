"! ADT에서 F9(Run As -> ABAP Application)로 바로 실행해 데모 출력을 본다.
"!
"! DB 변경문(INSERT/UPDATE/MODIFY/DELETE)·LUW 문제제기 — DDIC 테이블 ZMODULO_FLIGHT 대상.
"! - 각 메서드는 sy-subrc(0성공/4없음·중복)·sy-dbcnt(영향 행 수)를 평가한다.
"! - 변경은 다음 DB 커밋까지 보류 — COMMIT WORK로 확정, ROLLBACK WORK로 취소(LUW).
"! - INSERT 4종(단일행 FROM @wa·VALUES·내부테이블 FROM TABLE @itab·호스트식 @( )),
"!   UPDATE(FROM @wa 전체 덮어쓰기·SET ... WHERE 컬럼 지정),
"!   MODIFY(단일행·내부테이블 업서트), DELETE(FROM @wa·FROM TABLE @itab·WHERE·전체삭제)를 시연.
"! 표는 import 직후 비어 있다 — main은 먼저 시드한 뒤 출력하고 끝에 ROLLBACK으로 되돌린다.
"! 결정적 검증은 ABAP Unit이 osql 더블(CL_OSQL_TEST_ENVIRONMENT,
"! INSERT/UPDATE/MODIFY/DELETE도 가로챔)로 수행한다.
CLASS zcl_modulo_exec06_dml DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

    "! 항공편 묶음 — 일괄 INSERT/MODIFY/DELETE 입력용(WITH EMPTY KEY = 순서 보존).
    TYPES flight_tab TYPE STANDARD TABLE OF zmodulo_flight WITH EMPTY KEY.

    "! INSERT 한 행(FROM @wa). 중복 키면 sy-subrc=4 -> abap_false.
    "! @parameter flight | 적재할 항공편(키 CARRID·CONNID + 좌석)
    "! @parameter result | 새로 들어가면 abap_true, 중복이면 abap_false
    METHODS insert_flight
      IMPORTING flight        TYPE zmodulo_flight
      RETURNING VALUE(result) TYPE abap_bool.

    "! INSERT ... VALUES @( VALUE #( ... ) ): 호스트식으로 작업영역 선언 없이 한 행 삽입.
    "! 단일행 INSERT의 두 variant(FROM @wa / INTO ... VALUES @wa)는 동작 동일·구문만 다름.
    "! @parameter carrid | 항공사 코드
    "! @parameter connid | 연결 번호
    "! @parameter seatsmax | 최대 좌석
    "! @parameter result | 새로 들어가면 abap_true, 중복이면 abap_false
    METHODS insert_via_values
      IMPORTING carrid        TYPE zmodulo_flight-carrid
                connid        TYPE zmodulo_flight-connid
                seatsmax      TYPE zmodulo_flight-seatsmax
      RETURNING VALUE(result) TYPE abap_bool.

    "! INSERT ... FROM TABLE @itab ACCEPTING DUPLICATE KEYS: 내부테이블 일괄 삽입.
    "! ACCEPTING DUPLICATE KEYS면 중복 행을 건너뛰고 sy-subrc=4로 계속(멱등 적재).
    "! @parameter flights | 적재할 항공편 묶음
    "! @parameter result  | 실제로 삽입된 행 수(sy-dbcnt)
    METHODS insert_bulk
      IMPORTING flights       TYPE STANDARD TABLE
      RETURNING VALUE(result) TYPE i.

    "! UPDATE FROM @wa: 키(CARRID·CONNID)로 한 행을 통째 갱신. 키가 없으면 dbcnt=0.
    "! @parameter flight | 갱신할 항공편(키 + 새 값)
    "! @parameter result | 변경된 행 수(sy-dbcnt)
    METHODS update_flight
      IMPORTING flight        TYPE zmodulo_flight
      RETURNING VALUE(result) TYPE i.

    "! UPDATE ... SET col = ... WHERE: 특정 컬럼만 지정 갱신(나머지 보존).
    "! FROM @wa(전체 덮어쓰기)와 달리 SET은 명시한 컬럼만 바꾼다.
    "! @parameter carrid | 항공사 코드
    "! @parameter connid | 연결 번호
    "! @parameter seatsocc | 새 점유 좌석
    "! @parameter result | 변경된 행 수(sy-dbcnt). WHERE 미매칭이면 0(sy-subrc=4)
    "! (호스트변수 @carrid/@connid/@seatsocc는 SET ... WHERE에 쓰이나 정적분석이 못 봄 -> ##NEEDED.)
    METHODS set_occupancy
      IMPORTING carrid        TYPE zmodulo_flight-carrid ##NEEDED
                connid        TYPE zmodulo_flight-connid ##NEEDED
                seatsocc      TYPE zmodulo_flight-seatsocc ##NEEDED
      RETURNING VALUE(result) TYPE i.

    "! MODIFY FROM @wa = 업서트: 키 없으면 INSERT, 있으면 UPDATE. 멱등.
    "! @parameter flight | 적재/갱신할 항공편
    METHODS upsert_flight
      IMPORTING flight TYPE zmodulo_flight.

    "! MODIFY ... FROM TABLE @itab: 내부테이블 일괄 업서트(행마다 INSERT 또는 UPDATE).
    "! @parameter flights | 적재/갱신할 항공편 묶음
    "! @parameter result  | 처리된 행 수(sy-dbcnt)
    METHODS upsert_bulk
      IMPORTING flights       TYPE STANDARD TABLE
      RETURNING VALUE(result) TYPE i.

    "! DELETE ... WHERE: 키로 한 행 삭제. 없던 행이면 dbcnt=0(멱등 삭제).
    "! @parameter carrid | 항공사 코드
    "! @parameter connid | 연결 번호
    "! @parameter result | 삭제된 행 수(sy-dbcnt)
    METHODS delete_flight
      IMPORTING carrid        TYPE zmodulo_flight-carrid
                connid        TYPE zmodulo_flight-connid
      RETURNING VALUE(result) TYPE i.

    "! DELETE target FROM TABLE @itab: 내부테이블의 키로 복수 행 일괄 삭제(루프보다 적은 라운드트립).
    "! 비키 필드는 무시되고 키(CARRID·CONNID)만 사용된다.
    "! @parameter flights | 삭제 대상 키를 담은 항공편 묶음
    "! @parameter result  | 삭제된 행 수(sy-dbcnt)
    METHODS delete_bulk
      IMPORTING flights       TYPE STANDARD TABLE
      RETURNING VALUE(result) TYPE i.

    "! DELETE FROM target (WHERE 없음): 전체 행 삭제. 데이터 손실 위험 -> 자기 소유 테이블에만.
    "! @parameter result | 삭제된 행 수(sy-dbcnt) = 직전 전체 행 수
    METHODS delete_all
      RETURNING VALUE(result) TYPE i.

    "! LUW 번들: 한 항공편의 좌석을 다른 항공편으로 옮긴다(UPDATE 두 번을 한 LUW로).
    "! 둘 다 성공이면 COMMIT WORK, 어느 하나라도 미매칭이면 ROLLBACK WORK로 원자성 보장.
    "! @parameter from_connid | 좌석을 빼는 항공편(같은 항공사)
    "! @parameter to_connid   | 좌석을 더하는 항공편
    "! @parameter carrid      | 항공사 코드
    "! @parameter seats       | 옮길 좌석 수
    "! @parameter result      | 두 행 모두 갱신되면 abap_true, 아니면 abap_false(롤백)
    METHODS transfer_seats
      IMPORTING carrid        TYPE zmodulo_flight-carrid ##NEEDED
                from_connid   TYPE zmodulo_flight-connid
                to_connid     TYPE zmodulo_flight-connid
                seats         TYPE zmodulo_flight-seatsocc
      RETURNING VALUE(result) TYPE abap_bool.

    "! 한 항공편의 점유 좌석을 읽는다(검증·데모용).
    "! @parameter carrid | 항공사 코드
    "! @parameter connid | 연결 번호
    "! @parameter result | 점유 좌석(없으면 0)
    METHODS occupancy
      IMPORTING carrid        TYPE zmodulo_flight-carrid
                connid        TYPE zmodulo_flight-connid
      RETURNING VALUE(result) TYPE i.

    "! 전체 행 수.
    "! @parameter result | ZMODULO_FLIGHT 행 수
    METHODS count
      RETURNING VALUE(result) TYPE i.

  PRIVATE SECTION.
    "! 데모 데이터 시드 — 값이 없으면 넣고 이미 있으면 건너뛴다(멱등). F9에서 결과가 보이도록.
    "! (ABAP Unit은 이 메서드 대신 osql 더블로 데이터를 주입하므로 실 DB를 건드리지 않는다.)
    METHODS ensure_demo_data.
ENDCLASS.


CLASS zcl_modulo_exec06_dml IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    " 데모 데이터를 먼저 시드한다 — 그래야 F9에서 실제 결과가 보인다(빈 표면 0).
    ensure_demo_data( ).
    out->write( `=== EXEC06 DB 변경문 (INSERT/UPDATE/MODIFY/DELETE) ===` ).
    out->write( |count(시작)        = { count( ) }| ).
    out->write( |insert_flight      = { insert_flight(
      VALUE #( carrid = 'AA' connid = '0017' seatsmax = 380 seatsocc = 100 ) ) }| ).
    out->write( |insert_via_values  = { insert_via_values(
      carrid = 'AA' connid = '0064' seatsmax = 320 ) } (VALUES 호스트식)| ).
    DATA(more) = VALUE flight_tab( ( carrid = 'LH' connid = '0400' seatsmax = 280 seatsocc = 10 )
                                   ( carrid = 'UA' connid = '0941' seatsmax = 240 seatsocc = 80 ) ).
    out->write( |insert_bulk        = { insert_bulk( more ) } (FROM TABLE @itab)| ).
    out->write( |update_flight      = { update_flight(
      VALUE #( carrid = 'AA' connid = '0017' seatsmax = 380 seatsocc = 222 ) ) }| ).
    out->write( |set_occupancy(AA)  = { set_occupancy(
      carrid = 'AA' connid = '0064' seatsocc = 290 ) } (SET ... WHERE)| ).
    upsert_flight( VALUE #( carrid = 'LH' connid = '2402' seatsmax = 180 seatsocc = 20 ) ).
    out->write( |count(업서트 후)    = { count( ) }| ).
    out->write( |transfer_seats     = { transfer_seats(
      carrid = 'AA' from_connid = '0017' to_connid = '0064' seats = 50 ) } (LUW: UPDATE x2)| ).
    out->write( |delete_flight      = { delete_flight( carrid = 'UA' connid = '0941' ) }| ).
    out->write( |count(끝)          = { count( ) }| ).
    " 데모 변경을 되돌려 표를 깨끗이 둔다 — ROLLBACK WORK = LUW의 보류 변경 폐기.
    ROLLBACK WORK.
  ENDMETHOD.

  METHOD insert_flight.
    INSERT zmodulo_flight FROM @flight.
    " sy-subrc=0 신규 삽입, 4=중복 키.
    result = xsdbool( sy-subrc = 0 ).
  ENDMETHOD.

  METHOD insert_via_values.
    " 단일행 INSERT의 INTO ... VALUES variant. @( VALUE #( ... ) )로 작업영역 선언을 생략한다.
    INSERT INTO zmodulo_flight VALUES @( VALUE #(
      carrid = carrid connid = connid seatsmax = seatsmax ) ).
    result = xsdbool( sy-subrc = 0 ).
  ENDMETHOD.

  METHOD insert_bulk.
    " 중복 키가 섞여 있어도 그 행만 건너뛴다(ACCEPTING DUPLICATE KEYS). sy-dbcnt=실제 삽입 수.
    INSERT zmodulo_flight FROM TABLE @flights ACCEPTING DUPLICATE KEYS.
    result = sy-dbcnt.
  ENDMETHOD.

  METHOD update_flight.
    " 작업영역(@flight)의 키로 행을 찾아 비키 필드를 통째 갱신한다.
    UPDATE zmodulo_flight FROM @flight.
    result = sy-dbcnt.
  ENDMETHOD.

  METHOD set_occupancy.
    " SET은 명시한 컬럼(seatsocc)만 바꾼다 — seatsmax 등 나머지는 그대로 유지된다.
    UPDATE zmodulo_flight
      SET seatsocc = @seatsocc
      WHERE carrid = @carrid AND connid = @connid.
    result = sy-dbcnt.
  ENDMETHOD.

  METHOD upsert_flight.
    " MODIFY = 업서트: 키 없으면 INSERT, 있으면 UPDATE. 멱등.
    MODIFY zmodulo_flight FROM @flight.
  ENDMETHOD.

  METHOD upsert_bulk.
    " 내부테이블 업서트 — 행마다 키 존재 여부로 INSERT/UPDATE가 갈린다.
    MODIFY zmodulo_flight FROM TABLE @flights.
    result = sy-dbcnt.
  ENDMETHOD.

  METHOD delete_flight.
    DELETE FROM zmodulo_flight
      WHERE carrid = @carrid AND connid = @connid.
    result = sy-dbcnt.
  ENDMETHOD.

  METHOD delete_bulk.
    " 키 기반 일괄 삭제 — 내부테이블의 키 값만 사용(비키 필드 무시).
    DELETE zmodulo_flight FROM TABLE @flights.
    result = sy-dbcnt.
  ENDMETHOD.

  METHOD delete_all.
    " WHERE 없는 DELETE는 전체 행 삭제 — 일반 테이블에서는 데이터 손실 위험이 크다.
    DELETE FROM zmodulo_flight.
    result = sy-dbcnt.
  ENDMETHOD.

  METHOD transfer_seats.
    " 두 UPDATE를 하나의 LUW로 묶는다. 어느 하나라도 미매칭이면 전체 롤백(원자성).
    UPDATE zmodulo_flight
      SET seatsocc = seatsocc - @seats
      WHERE carrid = @carrid AND connid = @from_connid.
    IF sy-subrc <> 0.
      ROLLBACK WORK.
      result = abap_false.
      RETURN.
    ENDIF.
    UPDATE zmodulo_flight
      SET seatsocc = seatsocc + @seats
      WHERE carrid = @carrid AND connid = @to_connid.
    IF sy-subrc <> 0.
      ROLLBACK WORK.
      result = abap_false.
      RETURN.
    ENDIF.
    COMMIT WORK.
    result = abap_true.
  ENDMETHOD.

  METHOD occupancy.
    SELECT SINGLE seatsocc FROM zmodulo_flight
      WHERE carrid = @carrid AND connid = @connid
      INTO @result.
  ENDMETHOD.

  METHOD count.
    SELECT COUNT(*) FROM zmodulo_flight INTO @result.
  ENDMETHOD.

  METHOD ensure_demo_data.
    DATA flights TYPE STANDARD TABLE OF zmodulo_flight WITH EMPTY KEY.
    flights = VALUE #( ( carrid = 'AA' connid = '0017' seatsmax = 380 seatsocc = 342 )
                       ( carrid = 'AA' connid = '0064' seatsmax = 320 seatsocc = 240 )
                       ( carrid = 'LH' connid = '0400' seatsmax = 280 seatsocc = 280 ) ).
    " 값이 없으면 넣고, 이미 있는 키는 건너뛴다(ACCEPTING DUPLICATE KEYS = 멱등).
    INSERT zmodulo_flight FROM TABLE @flights ACCEPTING DUPLICATE KEYS.
    COMMIT WORK.
  ENDMETHOD.
ENDCLASS.
