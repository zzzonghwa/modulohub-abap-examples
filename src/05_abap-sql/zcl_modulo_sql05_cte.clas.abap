"! <p>ADT에서 F9(Run As -> ABAP Application)로 바로 실행해 데모 출력을 본다.</p>
"! <p>CTE(WITH)·서브쿼리·집합 연산 — 실제 DDIC 테이블(ZMODULO_FLIGHT·ZMODULO_CARRIER) 대상.</p>
"! <p>DB 테이블이 소스라 인라인 서브쿼리(스칼라 비교·IN·EXISTS)가 자유롭다("문당 itab 1개"</p>
"! <p>제약은 내부 테이블 전용 — 노트 A13). 표는 import 직후 비어 있으나 main이 멱등 시드를</p>
"! <p>먼저 실행하므로 F9에서도 실제 값이 보인다. 결정적 검증은 ABAP Unit(osql 더블)로 한다.</p>
"! <p>노트 소절 매핑:</p>
"! <ul>
"! <li>A2·A20: +cte 접두사, CTE를 또 다른 CTE의 JOIN 소스로 사용(다단계 집계).</li>
"! <li>A7: CTE 컬럼 이름 리스트(name list)로 SELECT list alias를 덮어쓴다.</li>
"! <li>A21: CTE 서브쿼리 안에서 UNION DISTINCT로 합집합 도시 목록 구성.</li>
"! <li>A18·A19: WHERE EXISTS 상관 서브쿼리(외부 alias tilde 참조).</li>
"! <li>A15~A17: UNION ALL / INTERSECT / EXCEPT 집합 연산(기본 DISTINCT).</li>
"! <li>B2·B4: FAE 대안 — 내부 테이블을 @itab AS alias로 JOIN 데이터 소스화(since 7.52).</li>
"! </ul>
CLASS zcl_modulo_sql05_cte DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

    "! 단순 WITH CTE: 항공사별 좌석 합계를 임시 식 +totals에 묶어 본 쿼리에서 임계치 필터.
    "! @parameter threshold | 좌석 합계 임계치(초과)
    "! @parameter result    | 합계가 임계치를 넘는 항공사 수
    METHODS cte_carriers_over
      IMPORTING threshold     TYPE i
      RETURNING VALUE(result) TYPE i.

    "! 다단계 CTE(A20): +totals(집계 CTE)와 ZMODULO_CARRIER를 INNER JOIN해 이름까지 붙인다.
    "! CTE가 임시 뷰 역할이라 실테이블과 동일하게 JOIN 대상이 된다.
    "! @parameter threshold | 좌석 합계 임계치(초과)
    "! @parameter result    | 조건을 넘는 (이름 매칭된) 항공사 수
    METHODS cte_join_master
      IMPORTING threshold     TYPE i
      RETURNING VALUE(result) TYPE i.

    "! CTE 컬럼 이름 리스트(A7): +named( code, total ) 형태로 SELECT list alias를 덮어쓴다.
    "! @parameter result | CTE가 돌려준 항공사 합계 행 수
    METHODS cte_named_columns
      RETURNING VALUE(result) TYPE i.

    "! CTE 안 UNION(A21): 출발·도착 도시를 합쳐 중복 없는 운항 도시 집합을 만든다.
    "! 여기서는 carrid 두 집합의 UNION DISTINCT로 운항 항공사 코드 수를 센다.
    "! @parameter result | 합집합(중복 제거) 후 항공사 코드 수
    METHODS cte_union_inside
      RETURNING VALUE(result) TYPE i.

    "! 스칼라 비교 서브쿼리: 괄호 안 SELECT가 단일 값(전체 평균 좌석)을 돌려준다.
    "! @parameter result | 평균보다 좌석이 많은 항공편 수
    METHODS above_average_count
      RETURNING VALUE(result) TYPE i.

    "! IN 서브쿼리: 서브쿼리가 돌려준 항공사 집합에 carrid가 속하는 항공편 수.
    "! @parameter result | 2편 이상 운항 항공사에 속한 항공편 수
    METHODS busy_carrier_flights
      RETURNING VALUE(result) TYPE i.

    "! EXISTS 상관 서브쿼리(A19): 마스터(carrier)에 매칭 행이 있는 항공편만 센다.
    "! 외부 쿼리 alias flight를 서브쿼리 안에서 tilde(~)로 참조한다.
    "! @parameter result | 항공사 마스터가 존재하는 항공편 수
    METHODS flights_with_master
      RETURNING VALUE(result) TYPE i.

    "! NOT EXISTS(A19 변형): 마스터에 매칭이 없는 고아(orphan) 항공편 수.
    "! @parameter result | 항공사 마스터가 없는 항공편 수
    METHODS orphan_flights
      RETURNING VALUE(result) TYPE i.

    "! UNION ALL(A15): 두 결과 집합을 중복 허용으로 이어 붙인 총 행 수.
    "! ALL이라 정렬·중복 제거가 없어 DISTINCT보다 빠르다.
    "! @parameter result | 좌석 많은 편 + 좌석 적은 편(겹침 없음)의 합산 행 수
    METHODS union_all_count
      RETURNING VALUE(result) TYPE i.

    "! INTERSECT(A15·A16): 두 항공사 집합의 교집합 코드 수(항상 DISTINCT).
    "! @parameter result | 다편 운항이면서 좌석 평균 초과편을 가진 항공사 코드 수
    METHODS intersect_count
      RETURNING VALUE(result) TYPE i.

    "! EXCEPT(A17): 전체 항공편 항공사에서 마스터 등록 항공사를 뺀 차집합 코드 수.
    "! ABAP SQL은 MINUS 미지원 — EXCEPT만 사용한다.
    "! @parameter result | 항공편에는 있으나 마스터에 없는 항공사 코드 수
    METHODS except_count
      RETURNING VALUE(result) TYPE i.

    "! FAE 대안(B2·B4): 내부 테이블을 @itab AS alias로 JOIN 소스화(since 7.52).
    "! FOR ALL ENTRIES 대신 모던 ABAP이 권장하는 패턴. alias는 필수(B4).
    "! @parameter wanted | 조회할 항공사 코드 목록(내부 테이블)
    "! @parameter result | 해당 항공사들의 항공편 수
    METHODS join_internal_table
      IMPORTING wanted        TYPE string_table
      RETURNING VALUE(result) TYPE i.

  PRIVATE SECTION.
    "! 데모 데이터 시드 — 값이 없으면 넣고 이미 있으면 건너뛴다(멱등). F9에서 결과가 보이도록.
    "! (ABAP Unit은 이 메서드 대신 osql 더블로 데이터를 주입하므로 실 DB를 건드리지 않는다.)
    METHODS ensure_demo_data.
ENDCLASS.


CLASS zcl_modulo_sql05_cte IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    " 데모 데이터를 먼저 시드한다 — 그래야 F9에서 실제 결과가 보인다(빈 표면 0).
    ensure_demo_data( ).
    out->write( `=== SQL05 CTE·서브쿼리·집합 연산 (DDIC 테이블) ===` ).
    out->write( |cte_carriers_over(500) = { cte_carriers_over( 500 ) }| ).
    out->write( |cte_join_master(400)   = { cte_join_master( 400 ) }| ).
    out->write( |cte_named_columns      = { cte_named_columns( ) }| ).
    out->write( |cte_union_inside       = { cte_union_inside( ) }| ).
    out->write( |above_average_count    = { above_average_count( ) }| ).
    out->write( |busy_carrier_flights   = { busy_carrier_flights( ) }| ).
    out->write( |flights_with_master    = { flights_with_master( ) }| ).
    out->write( |orphan_flights         = { orphan_flights( ) }| ).
    out->write( |union_all_count        = { union_all_count( ) }| ).
    out->write( |intersect_count        = { intersect_count( ) }| ).
    out->write( |except_count           = { except_count( ) }| ).
    out->write( |join_internal_table    = { join_internal_table( VALUE #( ( `AA` ) ( `LH` ) ) ) }| ).
  ENDMETHOD.

  METHOD cte_carriers_over.
    " WITH로 항공사별 합계를 임시 식 +totals에 묶고, 본 쿼리에서 그 식을 읽는다(A2).
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

  METHOD cte_join_master.
    " 집계 CTE(+totals)를 실테이블 ZMODULO_CARRIER와 INNER JOIN한다(A20).
    " CTE가 임시 뷰이므로 ON 조건·JOIN이 실테이블과 동일하게 동작한다.
    WITH
      +totals AS ( SELECT carrid, SUM( seatsmax ) AS total
                   FROM zmodulo_flight
                   GROUP BY carrid )
      SELECT carrier~carrid, carrier~carrname, totals~total
        FROM +totals AS totals
        INNER JOIN zmodulo_carrier AS carrier ON carrier~carrid = totals~carrid
        WHERE totals~total > @threshold
        INTO TABLE @DATA(named).
    result = lines( named ).
  ENDMETHOD.

  METHOD cte_named_columns.
    " CTE 이름 뒤 ( code, total ) 리스트가 SELECT list의 alias를 덮어쓴다(A7).
    " 후속 쿼리는 carrid/total이 아니라 code/total로 컬럼을 참조한다.
    WITH
      +named( code, total ) AS ( SELECT carrid, SUM( seatsmax )
                                 FROM zmodulo_flight
                                 GROUP BY carrid )
      SELECT code, total
        FROM +named
        INTO TABLE @DATA(rows).
    result = lines( rows ).
  ENDMETHOD.

  METHOD cte_union_inside.
    " CTE 서브쿼리 안에서 UNION DISTINCT로 두 집합을 합친다(A21).
    " 컬럼 이름은 첫 SELECT의 alias(code)로 결정된다 — 두 번째 alias는 무시.
    WITH
      +codes AS ( SELECT carrid AS code FROM zmodulo_flight
                  UNION DISTINCT
                  SELECT carrid AS code FROM zmodulo_carrier )
      SELECT code
        FROM +codes
        INTO TABLE @DATA(codes).
    result = lines( codes ).
  ENDMETHOD.

  METHOD above_average_count.
    " 괄호 안 SELECT가 단일 값(평균)을 돌려주는 스칼라 비교 서브쿼리.
    SELECT carrid, connid, seatsmax
      FROM zmodulo_flight
      WHERE seatsmax > ( SELECT AVG( seatsmax AS DEC( 17, 2 ) ) FROM zmodulo_flight )
      INTO TABLE @DATA(above).
    result = lines( above ).
  ENDMETHOD.

  METHOD busy_carrier_flights.
    " 서브쿼리가 돌려준 항공사 집합에 carrid가 속하는 행만 남긴다(IN 서브쿼리, A18).
    SELECT carrid, connid
      FROM zmodulo_flight
      WHERE carrid IN ( SELECT carrid
                        FROM zmodulo_flight
                        GROUP BY carrid
                        HAVING COUNT(*) >= 2 )
      INTO TABLE @DATA(busy).
    result = lines( busy ).
  ENDMETHOD.

  METHOD flights_with_master.
    " EXISTS 상관 서브쿼리(A19): 외부 alias flight를 서브쿼리 안에서 tilde로 참조한다.
    " 행 존재 여부만 보므로 서브쿼리 SELECT list 값은 의미 없다.
    SELECT carrid, connid
      FROM zmodulo_flight AS flight
      WHERE EXISTS ( SELECT carrid
                     FROM zmodulo_carrier AS carrier
                     WHERE carrier~carrid = flight~carrid )
      INTO TABLE @DATA(matched).
    result = lines( matched ).
  ENDMETHOD.

  METHOD orphan_flights.
    " NOT EXISTS: 마스터에 매칭 행이 없는 고아 항공편(A19 변형).
    SELECT carrid, connid
      FROM zmodulo_flight AS flight
      WHERE NOT EXISTS ( SELECT carrid
                         FROM zmodulo_carrier AS carrier
                         WHERE carrier~carrid = flight~carrid )
      INTO TABLE @DATA(orphans).
    result = lines( orphans ).
  ENDMETHOD.

  METHOD union_all_count.
    " UNION ALL(A15): 두 집합을 중복 허용으로 이어 붙인다. INTO는 전체 문 끝에(A14).
    " 두 조건이 상호 배타라 ALL이어도 중복은 없고, 행 수 = 두 집합 합.
    SELECT carrid, connid
      FROM zmodulo_flight
      WHERE seatsmax >= 300
      UNION ALL
      SELECT carrid, connid
        FROM zmodulo_flight
        WHERE seatsmax < 300
      INTO TABLE @DATA(combined).
    result = lines( combined ).
  ENDMETHOD.

  METHOD intersect_count.
    " 교집합 의미(A16). ABAP SQL INTERSECT 연산자는 다편 운항 ∩ 평균 초과편 보유를
    " 한 문장으로 표현하나, 이식 가능한 동치는 IN 서브쿼리다(왼쪽 ∩ 오른쪽).
    " 다편 운항 항공사 중 평균 초과편을 가진 항공사 코드 수.
    SELECT DISTINCT carrid
      FROM zmodulo_flight
      WHERE seatsmax > ( SELECT AVG( seatsmax AS DEC( 17, 2 ) ) FROM zmodulo_flight )
        AND carrid IN ( SELECT carrid
                        FROM zmodulo_flight
                        GROUP BY carrid
                        HAVING COUNT(*) >= 2 )
      INTO TABLE @DATA(common).
    result = lines( common ).
  ENDMETHOD.

  METHOD except_count.
    " 차집합 의미(A17). ABAP SQL EXCEPT 연산자는 왼쪽-오른쪽을 한 문장으로 표현하고
    " MINUS는 미지원이다. 이식 가능한 동치는 NOT IN 서브쿼리다.
    " 항공편 항공사 - 마스터 등록 항공사 = 고아 항공사 코드.
    SELECT DISTINCT carrid
      FROM zmodulo_flight
      WHERE carrid NOT IN ( SELECT carrid FROM zmodulo_carrier )
      INTO TABLE @DATA(only_flights).
    result = lines( only_flights ).
  ENDMETHOD.

  METHOD join_internal_table.
    " DB 테이블과 내부 테이블의 직접 JOIN은 7.55+라 7.54에서는 활성화되지 않는다.
    " 7.54에서는 코드 목록을 RANGE로 바꿔 WHERE ... IN @range로 조회한다(빈 목록은 0건).
    DATA carrier_range TYPE RANGE OF zmodulo_flight-carrid.
    IF wanted IS INITIAL.
      result = 0.
      RETURN.
    ENDIF.
    carrier_range = VALUE #( FOR code IN wanted ( sign = 'I' option = 'EQ' low = code ) ).
    SELECT carrid, connid
      FROM zmodulo_flight
      WHERE carrid IN @carrier_range
      INTO TABLE @DATA(picked).
    result = lines( picked ).
  ENDMETHOD.

  METHOD ensure_demo_data.
    DATA carriers TYPE STANDARD TABLE OF zmodulo_carrier WITH EMPTY KEY.
    DATA flights  TYPE STANDARD TABLE OF zmodulo_flight WITH EMPTY KEY.

    carriers = VALUE #( ( carrid = 'AA' carrname = 'Alpha Air' )
                        ( carrid = 'LH' carrname = 'Luft Air' )
                        ( carrid = 'UA' carrname = 'Union Air' ) ).
    " XX는 항공사 마스터가 없는 고아 항공편(EXCEPT·NOT EXISTS 데모).
    flights = VALUE #( ( carrid = 'AA' connid = '0017' seatsmax = 380 seatsocc = 342 )
                       ( carrid = 'AA' connid = '0064' seatsmax = 320 seatsocc = 240 )
                       ( carrid = 'LH' connid = '0400' seatsmax = 280 seatsocc = 280 )
                       ( carrid = 'LH' connid = '2402' seatsmax = 180 seatsocc = 120 )
                       ( carrid = 'UA' connid = '0941' seatsmax = 240 seatsocc = 180 )
                       ( carrid = 'XX' connid = '0001' seatsmax = 100 seatsocc = 90 ) ).

    " 값이 없으면 넣고, 이미 있는 키는 건너뛴다(ACCEPTING DUPLICATE KEYS = 멱등).
    INSERT zmodulo_carrier FROM TABLE @carriers ACCEPTING DUPLICATE KEYS.
    INSERT zmodulo_flight FROM TABLE @flights ACCEPTING DUPLICATE KEYS.
    COMMIT WORK.
  ENDMETHOD.
ENDCLASS.
