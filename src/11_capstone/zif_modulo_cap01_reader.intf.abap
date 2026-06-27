"! <p>항공편 데이터 읽기 경계(계약) — DB 접근을 분석 로직에서 떼어 내는 인터페이스.</p>
"! <p>분석기 ZIF_MODULO_CAP01_ANALYZER는 이 계약에만 의존한다. 그래서 단위 테스트는 실제
"! 테이블(ZMODULO_FLIGHT)을 읽는 대신 결정적 행을 돌려주는 더블을 주입해 DB 없이 격리 검증한다.
"! 프로덕션 구현은 ZMODULO_FLIGHT를 SELECT한다(분석기 클래스의 로컬 lcl_db_reader).</p>
"! <p>"책임 분리가 먼저" — 읽기(이 인터페이스)와 계산·필터(analyzer)를 가르면 테스트 더블로
"! 격리할 수 있다. 이것이 캡스톤 설계의 출발점이다.</p>
INTERFACE zif_modulo_cap01_reader PUBLIC.
  "! 항공편 한 건 — 좌석 점유율 계산의 입력. SFLIGHT의 CARRID·CONNID·SEATSMAX·SEATSOCC를
  "! 미러한 ZMODULO_FLIGHT 필드 모양(SEATSMAX·SEATSOCC는 INT4).
  TYPES:
    BEGIN OF flight,
      carrid   TYPE zmodulo_flight-carrid,
      connid   TYPE zmodulo_flight-connid,
      seatsmax TYPE zmodulo_flight-seatsmax,
      seatsocc TYPE zmodulo_flight-seatsocc,
    END OF flight.
  "! 항공편 목록.
  TYPES flights TYPE STANDARD TABLE OF flight WITH EMPTY KEY.

  "! 분석 대상 항공편 전체를 읽는다(데이터 소스는 구현이 결정 — DB·인메모리·테스트 더블).
  "! @parameter result | 항공편 행(없으면 빈 표)
  METHODS read_flights
    RETURNING VALUE(result) TYPE flights.
ENDINTERFACE.
