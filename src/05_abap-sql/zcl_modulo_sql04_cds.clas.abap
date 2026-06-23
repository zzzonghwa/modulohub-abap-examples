"! <p>ADT에서 F9(Run As -> ABAP Application)로 바로 실행해 데모 출력을 본다.</p>
"! <p>released CDS 뷰 소비(읽기 전용) 구문 형태를 자체완결로 시연한다.</p>
"! <p>released CDS entity는 ABAP SQL FROM에서 일반 DB 테이블과 동일하게 취급된다.</p>
"! <p>실 시스템 데이터 소스는 released CDS entity(예: I_CompanyCode·I_Timezone)이며,</p>
"! <p>base 테이블(T001·SCARR) 직접 접근 대신 released entity만 소비한다(Clean Core).</p>
"! <p>두 가지 소비 표면을 함께 보인다.</p>
"! <ul>
"! <li>CamelCase 시맨틱 요소 소비: released CDS는 base 컬럼(MANDT·CARRID) 대신 시맨틱
"! 요소명(Carrier·MaximumSeats)을 노출한다. 단일 itab SELECT(FROM @view AS)로 시연한다.</li>
"! <li>association 경로식 소비: 실 CDS는 경로식 \_Carrier-CarrierName 으로 텍스트를 끌어온다.
"! 경로식은 논리적 조인이라 요청한 테이블만 SQL에 포함된다. 7.54 자체완결을 위해
"! 동등한 결과를 두 Z 테이블 JOIN(ZMODULO_FLIGHT·ZMODULO_CARRIER)으로 보인다.</li>
"! </ul>
"! <p>Z 테이블 대상 메서드는 import 직후 표가 비어 F9 출력이 0일 수 있다. 결정적 검증은 ABAP Unit이</p>
"! <p>osql SQL 테스트 더블(CL_OSQL_TEST_ENVIRONMENT)로 데이터를 주입해 수행한다. CDS entity 전용</p>
"! <p>테스트는 CL_CDS_TEST_ENVIRONMENT(since 7.51)를 쓰지만 본 예제엔 실 CDS DDL이 없어 osql만 쓴다.</p>
CLASS zcl_modulo_sql04_cds DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

    TYPES carrier_code TYPE c LENGTH 3.
    "! SELECT-OPTIONS식 레인지 타입(access control 모사 WHERE ... IN @range 데모용).
    TYPES range_of_carrier TYPE RANGE OF carrier_code.

    "! released CDS 뷰가 노출하는 투영(소비자가 보는 모양). base 테이블이 아니라 이 투영을 읽는다.
    "! 요소명은 실 released CDS의 CamelCase 시맨틱 요소명을 모사한다(예: MaximumSeats).
    TYPES:
      BEGIN OF flight_view,
        carrier        TYPE carrier_code,
        connid         TYPE n LENGTH 4,
        maximum_seats  TYPE i,
        occupied_seats TYPE i,
      END OF flight_view.
    TYPES flight_views TYPE STANDARD TABLE OF flight_view WITH EMPTY KEY.

    "! association \_Carrier 대상 텍스트 뷰의 투영.
    TYPES:
      BEGIN OF carrier_text,
        carrier TYPE carrier_code,
        name    TYPE c LENGTH 20,
      END OF carrier_text.
    TYPES carrier_texts TYPE STANDARD TABLE OF carrier_text WITH EMPTY KEY.

    "! 점유율 라벨이 붙은 한 행(SELECT 리스트 CASE 데모용).
    TYPES:
      BEGIN OF load_row,
        carrier TYPE carrier_code,
        connid  TYPE n LENGTH 4,
        band    TYPE c LENGTH 5,
      END OF load_row.
    TYPES load_rows TYPE STANDARD TABLE OF load_row WITH EMPTY KEY.

    "! released 뷰 소비: 투영 전체를 읽어 행 수를 센다(일반 테이블과 동일 구문).
    "! @parameter result | 소비한 뷰 행 수
    METHODS consume_count
      RETURNING VALUE(result) TYPE i.

    "! SELECT SINGLE 소비: 키로 한 행을 읽어 시맨틱 요소를 본다(I_Timezone SINGLE 패턴).
    "! @parameter carrier | 항공사 코드
    "! @parameter connid  | 연결편 번호
    "! @parameter result  | 해당 항공편의 최대 좌석, 미스면 0
    METHODS single_maximum_seats
      IMPORTING carrier       TYPE carrier_code
                connid        TYPE flight_view-connid
      RETURNING VALUE(result) TYPE i.

    "! 시맨틱 필드 소비 + 파생 계산: 한 항공편의 좌석 점유율(%).
    "! @parameter carrier | 항공사 코드
    "! @parameter connid  | 연결편 번호
    "! @parameter result  | 점유율 percent(반올림 정수), 미스면 0
    METHODS load_factor_percent
      IMPORTING carrier       TYPE carrier_code
                connid        TYPE flight_view-connid
      RETURNING VALUE(result) TYPE i.

    "! SELECT 리스트 CASE: 점유 좌석 수를 밴드 라벨로 분류해 투영한다(파생 컬럼 소비).
    "! band: occupied_seats >= 300 FULL, >= 150 HIGH, else LOW.
    "! @parameter result | (carrier·connid·band) 행, carrier·connid 오름차순 정렬
    METHODS load_bands
      RETURNING VALUE(result) TYPE load_rows.

    "! access control 모사: released CDS는 DCL access condition이 WHERE에 암묵 추가된다.
    "! 소비자가 명시하지 않은 필터가 붙는 효과를 호스트 레인지로 시연한다 — 허용 항공사만 반환.
    "! @parameter result | access condition(AA·LH 허용)을 통과한 행 수
    METHODS authorized_count
      RETURNING VALUE(result) TYPE i.

    "! association 소비(itab 식): 항공사 코드로 항공사명을 끌어온다 — 경로식의 "키로 텍스트" 의미.
    "! @parameter carrier | 항공사 코드
    "! @parameter result  | 항공사명, 미스면 공백
    METHODS carrier_name
      IMPORTING carrier       TYPE carrier_code
      RETURNING VALUE(result) TYPE carrier_text-name.

    "! association 경로식 소비: 경로식 \_Carrier-CarrierName 을 7.54 자체완결로 JOIN 시연.
    "! 실 released CDS에선 SELECT carrier~connid, \_Carrier-CarrierName FROM I_Flight 형태다.
    "! @parameter carrier | 항공사 코드
    "! @parameter result  | (해당 항공사 항공편마다) 항공편+항공사명 텍스트 행 수
    METHODS path_text_rows
      IMPORTING carrier       TYPE carrier_code
      RETURNING VALUE(result) TYPE i.

    "! association은 요청한 테이블만 SQL에 포함된다 — 텍스트가 불필요하면 base만 읽는다.
    "! 경로식을 쓰지 않은 SELECT는 carrier 텍스트 테이블을 조인하지 않음을 행 수로 시연한다.
    "! @parameter carrier | 항공사 코드
    "! @parameter result  | 텍스트 조인 없이 읽은 항공편 수(path_text_rows와 동일 건수)
    METHODS base_only_rows
      IMPORTING carrier       TYPE carrier_code
      RETURNING VALUE(result) TYPE i.

  PRIVATE SECTION.
    "! released 뷰 투영을 모사한 데모 데이터 5건(단일 itab SELECT용).
    METHODS sample_view
      RETURNING VALUE(result) TYPE flight_views.
    "! association 대상 텍스트 3건(itab 식 데모용).
    METHODS sample_texts
      RETURNING VALUE(result) TYPE carrier_texts.
ENDCLASS.


CLASS zcl_modulo_sql04_cds IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    out->write( `=== SQL04 released CDS 뷰 소비 ===` ).
    out->write( |consume_count                   = { consume_count( ) }| ).
    out->write( |single_maximum_seats(AA,0017)    = { single_maximum_seats( carrier = 'AA' connid = '0017' ) }| ).
    out->write( |load_factor_percent(AA,0017)     = { load_factor_percent( carrier = 'AA' connid = '0017' ) }| ).
    out->write( |load_factor_percent(LH,0400)     = { load_factor_percent( carrier = 'LH' connid = '0400' ) }| ).
    out->write( |authorized_count(access control)  = { authorized_count( ) }| ).
    out->write( |carrier_name(AA)                 = { carrier_name( 'AA' ) }| ).
    " Z 테이블 대상(경로식·base): import 직후 비어 있으면 0. 결정 검증은 ABAP Unit.
    out->write( |path_text_rows(AA) (경로식)        = { path_text_rows( 'AA' ) }| ).
    out->write( |base_only_rows(AA) (텍스트 미조인)  = { base_only_rows( 'AA' ) }| ).
  ENDMETHOD.

  METHOD consume_count.
    " 소비자는 base 테이블이 아니라 released 뷰의 투영을 읽는다(DB 테이블과 동일 구문).
    DATA(view) = sample_view( ) ##NEEDED.
    SELECT COUNT(*)
      FROM @view AS flight
      INTO @DATA(rows).
    result = rows.
  ENDMETHOD.

  METHOD single_maximum_seats.
    " SELECT SINGLE * FROM i_timezone WHERE ... 와 같은 키 단일 행 소비 패턴.
    DATA(view) = sample_view( ) ##NEEDED.
    SELECT SINGLE carrier, maximum_seats
      FROM @view AS flight
      WHERE carrier = @carrier
        AND connid  = @connid
      INTO @DATA(row).
    result = COND #( WHEN sy-subrc = 0 THEN row-maximum_seats ELSE 0 ).
  ENDMETHOD.

  METHOD load_factor_percent.
    DATA(view) = sample_view( ) ##NEEDED.
    " 시맨틱 필드(maximum_seats·occupied_seats)를 읽어 ABAP에서 파생값을 계산한다.
    SELECT SINGLE maximum_seats, occupied_seats
      FROM @view AS flight
      WHERE carrier = @carrier
        AND connid  = @connid
      INTO @DATA(seats).
    result = COND #( WHEN sy-subrc = 0 AND seats-maximum_seats > 0
                     THEN seats-occupied_seats * 100 / seats-maximum_seats
                     ELSE 0 ).
  ENDMETHOD.

  METHOD load_bands.
    DATA(view) = sample_view( ) ##NEEDED.
    " SELECT 리스트 CASE — 행별 파생 컬럼(band)을 SQL에서 계산해 투영한다.
    SELECT carrier,
           connid,
           CASE WHEN occupied_seats >= 300 THEN 'FULL'
                WHEN occupied_seats >= 150 THEN 'HIGH'
                ELSE 'LOW' END AS band
      FROM @view AS flight
      ORDER BY carrier, connid
      INTO TABLE @result.
  ENDMETHOD.

  METHOD authorized_count.
    DATA(view) = sample_view( ) ##NEEDED.
    " DCL access condition은 런타임에 WHERE로 암묵 추가된다(예: 허용 항공사 레인지).
    " 소비 코드가 AUTHORITY-CHECK를 쓰지 않아도 결과가 자동 필터됨을 레인지로 모사한다.
    DATA(allowed) = VALUE range_of_carrier(
      ( sign = 'I' option = 'EQ' low = 'AA' )
      ( sign = 'I' option = 'EQ' low = 'LH' ) ).
    SELECT COUNT(*)
      FROM @view AS flight
      WHERE carrier IN @allowed
      INTO @DATA(rows).
    result = rows.
  ENDMETHOD.

  METHOD carrier_name.
    " 실 CDS에선 경로식 \_Carrier-CarrierName 으로 association을 따라간다.
    " 그 "키로 텍스트를 끌어오는" 의미를 내부 테이블 식(texts[ ... ])으로 그대로 보인다 —
    " 두 내부 테이블 JOIN(7.55+)에 의존하지 않아 7.54에서도 동작한다.
    DATA(texts) = sample_texts( ).
    result = VALUE #( texts[ carrier = carrier ]-name OPTIONAL ).
  ENDMETHOD.

  METHOD path_text_rows.
    " 경로식의 실 DB 등가: released CDS의 \_Carrier-CarrierName 은 carrier 텍스트로의
    " 논리적 조인이다. 7.54 자체완결을 위해 동일 결과를 두 Z 테이블 INNER JOIN으로 보인다.
    SELECT flight~carrid, flight~connid, carrier~carrname
      FROM zmodulo_flight AS flight
      INNER JOIN zmodulo_carrier AS carrier ON carrier~carrid = flight~carrid
      WHERE flight~carrid = @carrier
      INTO TABLE @DATA(joined).
    result = lines( joined ).
  ENDMETHOD.

  METHOD base_only_rows.
    " 경로식(텍스트)을 안 쓰면 carrier 테이블은 SQL에 포함되지 않는다 — base만 읽는다.
    " 같은 항공사 항공편이라도 텍스트 조인 없이 base 테이블 단독 SELECT로 같은 건수를 얻는다.
    SELECT carrid, connid
      FROM zmodulo_flight
      WHERE carrid = @carrier
      INTO TABLE @DATA(rows).
    result = lines( rows ).
  ENDMETHOD.

  METHOD sample_view.
    result = VALUE #(
      ( carrier = 'AA' connid = '0017' maximum_seats = 380 occupied_seats = 342 )
      ( carrier = 'AA' connid = '0064' maximum_seats = 320 occupied_seats = 240 )
      ( carrier = 'LH' connid = '0400' maximum_seats = 280 occupied_seats = 280 )
      ( carrier = 'LH' connid = '2402' maximum_seats = 180 occupied_seats = 90 )
      ( carrier = 'UA' connid = '0941' maximum_seats = 240 occupied_seats = 180 ) ).
  ENDMETHOD.

  METHOD sample_texts.
    result = VALUE #(
      ( carrier = 'AA' name = 'Alpha Air' )
      ( carrier = 'LH' name = 'Luft Air' )
      ( carrier = 'UA' name = 'Union Air' ) ).
  ENDMETHOD.
ENDCLASS.
