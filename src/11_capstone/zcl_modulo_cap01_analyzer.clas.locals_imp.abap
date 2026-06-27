"! ZMODULO_FLIGHT를 읽는 프로덕션 reader — zif_modulo_cap01_reader의 실 구현.
"! F9 데모(IF_OO_ADT_CLASSRUN)에서 기본 주입된다. "경계만 더블한다": 테스트는 이 실물 대신
"! 인메모리 더블(testclasses의 lcl_stub_reader)을 주입해 DB 없이 분석 로직을 격리 검증한다.
CLASS lcl_db_reader DEFINITION CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES zif_modulo_cap01_reader.
ENDCLASS.

CLASS lcl_db_reader IMPLEMENTATION.
  METHOD zif_modulo_cap01_reader~read_flights.
    " 필드 순서가 reader 행 타입과 일치하므로 INTO TABLE @result로 직접 받는다.
    SELECT carrid, connid, seatsmax, seatsocc
      FROM zmodulo_flight
      INTO TABLE @result.
  ENDMETHOD.
ENDCLASS.
