CLASS zcl_modulo_sql05_cte DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    "! ADT에서 F9(Run As -> ABAP Application)로 바로 실행해 데모 출력을 본다.
    "!
    "! CTE(WITH)·서브쿼리 — 실제 DDIC 테이블(ZMODULO_FLIGHT) 대상.
    "! DB 테이블이 소스라 인라인 서브쿼리(스칼라·IN)가 자유롭다("문당 itab 1개" 제약은 내부 테이블 전용).
    "! 표는 import 직후 비어 있다 — 결정적 검증은 ABAP Unit(osql 더블)로 한다. 적재는 08.6/수동.
    INTERFACES if_oo_adt_classrun.

    "! WITH 공통 테이블 식(CTE): 항공사별 합계를 임시 식으로 묶어 본 쿼리에서 소비.
    "! @parameter threshold | 좌석 합계 임계치(초과)
    "! @parameter result    | 합계가 임계치를 넘는 항공사 수
    METHODS cte_carriers_over
      IMPORTING threshold     TYPE i
      RETURNING VALUE(result) TYPE i.

    "! 스칼라 서브쿼리: 전체 평균 좌석을 넘는 항공편 수.
    "! @parameter result | 평균보다 좌석이 많은 항공편 수
    METHODS above_average_count
      RETURNING VALUE(result) TYPE i.

    "! IN 서브쿼리: 2편 이상 운항하는 항공사의 항공편 수.
    "! @parameter result | 다편 운항 항공사에 속한 항공편 수
    METHODS busy_carrier_flights
      RETURNING VALUE(result) TYPE i.
ENDCLASS.


CLASS zcl_modulo_sql05_cte IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    out->write( `=== SQL05 CTE·서브쿼리 (DDIC 테이블) ===` ).
    out->write( `표가 비어 있으면 값은 0 — ABAP Unit(osql 더블)이 결정적 데이터로 검증한다.` ).
    out->write( |cte_carriers_over(500) = { cte_carriers_over( 500 ) }| ).
    out->write( |above_average_count    = { above_average_count( ) }| ).
    out->write( |busy_carrier_flights   = { busy_carrier_flights( ) }| ).
  ENDMETHOD.

  METHOD cte_carriers_over.
    " WITH로 항공사별 합계를 임시 식 +totals에 묶고, 본 쿼리에서 그 식을 읽는다.
    WITH
      +totals AS ( SELECT carrid, SUM( seatsmax ) AS total
                   FROM zmodulo_flight
                   GROUP BY carrid )
      SELECT carrid
        FROM +totals
        WHERE total > @threshold
        INTO TABLE @DATA(big).
    result = lines( big ).
  ENDMETHOD.

  METHOD above_average_count.
    " 괄호 안 SELECT가 단일 값(평균)을 돌려주는 스칼라 서브쿼리.
    SELECT carrid, connid, seatsmax
      FROM zmodulo_flight
      WHERE seatsmax > ( SELECT AVG( seatsmax ) FROM zmodulo_flight )
      INTO TABLE @DATA(above).
    result = lines( above ).
  ENDMETHOD.

  METHOD busy_carrier_flights.
    " 서브쿼리가 돌려준 항공사 집합에 carrid가 속하는 행만 남긴다.
    SELECT carrid, connid
      FROM zmodulo_flight
      WHERE carrid IN ( SELECT carrid
                        FROM zmodulo_flight
                        GROUP BY carrid
                        HAVING COUNT(*) >= 2 )
      INTO TABLE @DATA(busy).
    result = lines( busy ).
  ENDMETHOD.
ENDCLASS.
