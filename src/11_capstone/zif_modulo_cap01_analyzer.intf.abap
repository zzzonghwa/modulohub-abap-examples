"! <p>좌석 점유율 분석 계약 — 순수 계산·필터(부수효과·DB 접근 없음).</p>
"! <p>읽기(ZIF_MODULO_CAP01_READER)와 분리해 두 책임을 인터페이스로 가른다. 점유율 계산과
"! 역치 필터는 입력→출력이 결정적이라, 더블 reader만 주입하면 DB 없이 단위 테스트가 가능하다.</p>
INTERFACE zif_modulo_cap01_analyzer PUBLIC.
  "! 점유율이 매겨진 항공편 한 건 — read 행에 pct(점유율 %)를 더한 결과.
  TYPES:
    BEGIN OF occupancy,
      carrid   TYPE zmodulo_flight-carrid,
      connid   TYPE zmodulo_flight-connid,
      seatsmax TYPE zmodulo_flight-seatsmax,
      seatsocc TYPE zmodulo_flight-seatsocc,
      pct      TYPE i,
    END OF occupancy.
  "! 점유율 매겨진 항공편 목록(점유율 내림차순).
  TYPES occupancies TYPE STANDARD TABLE OF occupancy WITH EMPTY KEY.

  "! 좌석 점유율(%) = seatsocc * 100 / seatsmax. seatsmax가 0이면 0(ZERO_DIVIDE 방지).
  "! 오버부킹(seatsocc > seatsmax)이면 100을 넘을 수 있다 — 가공 없이 그대로 둔다.
  "! @parameter seatsmax | 최대 좌석 수
  "! @parameter seatsocc | 점유 좌석 수
  "! @parameter result   | 점유율 %(정수, 반올림)
  METHODS occupancy_pct
    IMPORTING seatsmax      TYPE i
              seatsocc      TYPE i
    RETURNING VALUE(result) TYPE i.

  "! 점유율이 역치 이상(>=)인 항공편만 점유율 내림차순으로 돌려준다.
  "! @parameter min_pct | 점유율 역치 %(이 값 이상만 통과)
  "! @parameter result  | 조건을 만족하는 항공편(점유율 매겨짐, 내림차순)
  METHODS busy_flights
    IMPORTING min_pct       TYPE i
    RETURNING VALUE(result) TYPE occupancies.
ENDINTERFACE.
