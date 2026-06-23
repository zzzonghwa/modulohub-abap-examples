"! <p>ADT에서 F9(Run As -> ABAP Application)로 바로 실행해 데모 출력을 본다.</p>
"! <p>DDIC 객체·SQL 토대 — 기본 구문 형태를 자체완결로 시연한다.</p>
"! <ul>
"! <li>FROM 데이터 소스: 내부 테이블(@itab AS alias, since 7.40)과 DDIC 데이터베이스 테이블 둘 다.</li>
"! <li>SELECT 타깃 5종: INTO TABLE / 스칼라 INTO @ / SELECT SINGLE 구조 / SELECT * 구조 /
"! INTO CORRESPONDING FIELDS / APPENDING TABLE.</li>
"! <li>결과 메타: sy-subrc(0=hit·4=empty) / sy-dbcnt.</li>
"! <li>인라인 선언 결과 타입: SELECT INTO TABLE @DATA(itab)는 standard table·empty key.</li>
"! <li>SELECT loop: SELECT ... ENDSELECT(암묵 cursor).</li>
"! </ul>
"! <p>다중 테이블 JOIN은 내부 테이블로 불가("문당 itab 1개")하므로 DDIC 소스 데모는</p>
"! <p>레포 동봉 Z 테이블(ZMODULO_CARRIER)을 쓰고, 결정적 검증은 ABAP Unit이</p>
"! <p>osql 테스트 더블(CL_OSQL_TEST_ENVIRONMENT)로 데이터를 주입해 수행한다.</p>
CLASS zcl_modulo_sql01_basics DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

    "! 항공편 한 건. ABAP SQL 데모의 공통 행 타입.
    "! 실제 시스템에서는 DDIC 데이터베이스 테이블이나 released CDS 뷰가 데이터 소스지만,
    "! 내부 테이블 소스 데모는 자체 포함을 위해 이 타입을 쓴다(SELECT ... FROM @itab, 7.40+).
    TYPES:
      BEGIN OF flight,
        carrier TYPE c LENGTH 3,
        connid  TYPE n LENGTH 4,
        seats   TYPE i,
      END OF flight.
    TYPES flights TYPE STANDARD TABLE OF flight WITH EMPTY KEY.

    "! SELECT ... INTO TABLE: 결과 집합 전체를 내부 테이블 타깃으로 읽는다.
    "! 인라인 @DATA(rows)는 standard table·empty key로 선언된다.
    "! @parameter result | 읽은 행 수(sy-dbcnt와 동일)
    METHODS read_into_table
      RETURNING VALUE(result) TYPE i.

    "! SELECT COUNT(*) ... INTO @scalar: 결과를 스칼라 타깃으로 읽는다.
    "! @parameter result | 전체 행 수
    METHODS count_into_scalar
      RETURNING VALUE(result) TYPE i.

    "! SELECT SINGLE ... WHERE key: 단일 행을 구조 타깃으로 읽는다.
    "! 일치 행이 없으면 sy-subrc = 4, 타깃은 초기값으로 남는다.
    "! @parameter carrier | 항공사 코드
    "! @parameter connid  | 연결편 번호
    "! @parameter result  | 해당 좌석 수, 없으면 0
    METHODS read_single_row
      IMPORTING carrier       TYPE flight-carrier
                connid        TYPE flight-connid
      RETURNING VALUE(result) TYPE i.

    "! sy-subrc 규칙: 결과 집합이 비면 SELECT SINGLE은 sy-subrc = 4를 돌려준다.
    "! @parameter carrier | 항공사 코드
    "! @parameter connid  | 연결편 번호
    "! @parameter result  | hit면 0, empty면 4
    METHODS single_subrc
      IMPORTING carrier       TYPE flight-carrier
                connid        TYPE flight-connid
      RETURNING VALUE(result) TYPE i.

    "! SELECT * ... INTO @struct: 전체 컬럼을 구조 타깃으로 읽는다(행 타입 그대로).
    "! @parameter connid | 연결편 번호
    "! @parameter result | 그 행의 carrier|connid|seats 요약 문자열, 없으면 공백
    METHODS read_star_struct
      IMPORTING connid        TYPE flight-connid
      RETURNING VALUE(result) TYPE string.

    "! INTO CORRESPONDING FIELDS OF: 이름이 같은 컬럼만 타깃 구조에 매핑한다.
    "! 타깃이 SELECT 리스트와 컬럼 순서/구성이 달라도 이름 기준으로 채운다.
    "! @parameter connid | 연결편 번호
    "! @parameter result | 매핑된 좌석 수, 없으면 0
    METHODS read_corresponding
      IMPORTING connid        TYPE flight-connid
      RETURNING VALUE(result) TYPE i.

    "! APPENDING TABLE: 기존 내부 테이블을 비우지 않고 결과를 뒤에 덧붙인다(INTO는 덮어씀).
    "! 두 항공사를 차례로 APPENDING하여 누적 행 수를 본다.
    "! @parameter result | 두 SELECT 누적 후 총 행 수
    METHODS append_two_selects
      RETURNING VALUE(result) TYPE i.

    "! SELECT ... ENDSELECT loop: 행 단위 처리(암묵 database cursor).
    "! 결과 집합을 한 번에 읽지 않고 행마다 work area로 받아 누적한다.
    "! @parameter result | 좌석 합계
    METHODS sum_via_loop
      RETURNING VALUE(result) TYPE i.

    "! UP TO 1 ROWS vs SELECT SINGLE: 정렬 후 첫 행만 읽어 결정적 단일 행을 얻는다.
    "! SINGLE은 순서 미보장이므로, "정렬 기준 첫 행"이 필요하면 ORDER BY + UP TO 1 ROWS.
    "! @parameter result | 좌석 최다 1편의 connid
    METHODS top_one_row
      RETURNING VALUE(result) TYPE flight-connid.

    "! DDIC 데이터베이스 테이블을 FROM 소스로: 내부 테이블이 아닌 실 Z 테이블 대상.
    "! ABAP SQL 엔진은 이 경우 데이터베이스 인터페이스로 라우팅한다.
    "! @parameter result | ZMODULO_CARRIER의 항공사 수
    METHODS count_db_table
      RETURNING VALUE(result) TYPE i.

    "! DDIC 테이블에서 SELECT SINGLE: 키로 한 행 읽기. 암묵적 클라이언트 처리로
    "! WHERE에 MANDT를 직접 쓰지 않는다 — 컴파일러가 현재 클라이언트로 자동 한정한다.
    "! @parameter carrid | 항공사 코드(키)
    "! @parameter result | 항공사명, 없으면 공백
    METHODS read_db_single
      IMPORTING carrid        TYPE zmodulo_carrier-carrid
      RETURNING VALUE(result) TYPE zmodulo_carrier-carrname.

  PRIVATE SECTION.
    "! 데모용 항공편 4건 샘플 데이터(내부 테이블 소스용).
    METHODS sample
      RETURNING VALUE(result) TYPE flights.

    "! DDIC 소스 데모용 데이터 시드 — F9에서 결과가 보이도록 멱등 INSERT.
    "! (ABAP Unit은 이 메서드 대신 osql 더블로 데이터를 주입하므로 실 DB를 건드리지 않는다.)
    METHODS ensure_demo_data.
ENDCLASS.


CLASS zcl_modulo_sql01_basics IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    " DDIC 소스 데모용 데이터를 먼저 시드한다(빈 표면 0 방지).
    ensure_demo_data( ).
    out->write( `=== SQL01 ABAP SQL 토대·데이터 소스·타깃·sy-subrc ===` ).
    out->write( |read_into_table(rows)        = { read_into_table( ) }| ).
    out->write( |count_into_scalar            = { count_into_scalar( ) }| ).
    out->write( |read_single_row(AA,0017)     = { read_single_row( carrier = 'AA' connid = '0017' ) }| ).
    out->write( |single_subrc(AA,0017) hit    = { single_subrc( carrier = 'AA' connid = '0017' ) }| ).
    out->write( |single_subrc(ZZ,9999) empty  = { single_subrc( carrier = 'ZZ' connid = '9999' ) }| ).
    out->write( |read_star_struct(0400)       = { read_star_struct( '0400' ) } (SELECT *)| ).
    out->write( |read_corresponding(0017)     = { read_corresponding( '0017' ) }| ).
    out->write( |append_two_selects           = { append_two_selects( ) } (APPENDING)| ).
    out->write( |sum_via_loop                 = { sum_via_loop( ) } (ENDSELECT)| ).
    out->write( |top_one_row                  = { top_one_row( ) } (UP TO 1 ROWS)| ).
    out->write( |count_db_table               = { count_db_table( ) } (DDIC 테이블 소스)| ).
    out->write( |read_db_single(AA)           = { read_db_single( 'AA' ) }| ).
  ENDMETHOD.

  METHOD read_into_table.
    " 데이터 소스는 호스트 변수여야 한다 — 식 @( sample( ) )은 소스 위치에 올 수 없다.
    DATA(source) = sample( ) ##NEEDED. " @source가 FROM에 쓰이나 정적분석이 못 봄
    " 내부 테이블 타깃: INTO TABLE @DATA(...)로 결과 집합 전체를 받는다(standard·empty key).
    SELECT carrier, connid, seats
      FROM @source AS flight
      INTO TABLE @DATA(rows).
    result = lines( rows ).
  ENDMETHOD.

  METHOD count_into_scalar.
    DATA(source) = sample( ) ##NEEDED. " @source가 FROM에 쓰이나 정적분석이 못 봄
    " 스칼라 타깃: 집계 결과 한 값을 INTO @DATA(...)로 받는다.
    SELECT COUNT(*)
      FROM @source AS flight
      INTO @DATA(count).
    result = count.
  ENDMETHOD.

  METHOD read_single_row.
    DATA(source) = sample( ) ##NEEDED. " @source가 FROM에 쓰이나 정적분석이 못 봄
    " 단일 행: SELECT SINGLE은 키로 한 행만 읽는다. 미스면 sy-subrc = 4.
    SELECT SINGLE seats
      FROM @source AS flight
      WHERE carrier = @carrier
        AND connid  = @connid
      INTO @DATA(seats).
    result = COND #( WHEN sy-subrc = 0 THEN seats ELSE 0 ).
  ENDMETHOD.

  METHOD single_subrc.
    DATA(source) = sample( ) ##NEEDED.
    " sy-subrc 계약: hit -> 0, 빈 결과 -> 4.
    SELECT SINGLE seats
      FROM @source AS flight
      WHERE carrier = @carrier
        AND connid  = @connid
      INTO @DATA(seats) ##NEEDED.
    result = sy-subrc.
  ENDMETHOD.

  METHOD read_star_struct.
    DATA(source) = sample( ) ##NEEDED.
    " SELECT *: 전체 컬럼을 행 타입 그대로 구조 타깃 @DATA(row)에 읽는다.
    SELECT SINGLE *
      FROM @source AS flight
      WHERE connid = @connid
      INTO @DATA(row).
    result = COND #( WHEN sy-subrc = 0
                     THEN |{ row-carrier } { row-connid } { row-seats }|
                     ELSE space ).
  ENDMETHOD.

  METHOD read_corresponding.
    DATA(source) = sample( ) ##NEEDED.
    " 타깃은 SELECT 리스트와 컬럼 구성이 다르다 — 이름이 같은 seats만 매핑된다.
    DATA target TYPE flight.
    SELECT SINGLE connid, seats
      FROM @source AS flight
      WHERE connid = @connid
      INTO CORRESPONDING FIELDS OF @target.
    result = COND #( WHEN sy-subrc = 0 THEN target-seats ELSE 0 ).
  ENDMETHOD.

  METHOD append_two_selects.
    DATA(source) = sample( ) ##NEEDED.
    DATA rows TYPE flights.
    " 첫 SELECT은 INTO TABLE(덮어쓰기)로 시작한다.
    SELECT carrier, connid, seats
      FROM @source AS flight
      WHERE carrier = 'AA'
      INTO TABLE @rows.
    " 둘째 SELECT은 APPENDING TABLE — 앞 결과를 지우지 않고 뒤에 덧붙인다.
    SELECT carrier, connid, seats
      FROM @source AS flight
      WHERE carrier = 'LH'
      APPENDING TABLE @rows.
    result = lines( rows ).
  ENDMETHOD.

  METHOD sum_via_loop.
    DATA(source) = sample( ) ##NEEDED.
    DATA total TYPE i.
    " SELECT ... ENDSELECT: 행마다 work area로 받아 처리한다(암묵 cursor).
    SELECT seats
      FROM @source AS flight
      INTO @DATA(seats).
      total = total + seats.
    ENDSELECT.
    result = total.
  ENDMETHOD.

  METHOD top_one_row.
    DATA(source) = sample( ) ##NEEDED.
    " ORDER BY + UP TO 1 ROWS: SINGLE과 달리 정렬 기준 첫 행을 결정적으로 얻는다.
    SELECT connid
      FROM @source AS flight
      ORDER BY seats DESCENDING, connid ASCENDING
      INTO TABLE @DATA(connids)
      UP TO 1 ROWS.
    result = COND #( WHEN connids IS NOT INITIAL THEN connids[ 1 ]-connid ).
  ENDMETHOD.

  METHOD count_db_table.
    " DDIC 데이터베이스 테이블을 FROM 소스로 직접 지정. 호스트 변수 alias 불필요.
    SELECT COUNT(*)
      FROM zmodulo_carrier
      INTO @DATA(count).
    result = count.
  ENDMETHOD.

  METHOD read_db_single.
    " 암묵적 클라이언트 처리: WHERE에 MANDT를 쓰지 않아도 현재 클라이언트로 자동 한정.
    SELECT SINGLE carrname
      FROM zmodulo_carrier
      WHERE carrid = @carrid
      INTO @DATA(carrname).
    result = COND #( WHEN sy-subrc = 0 THEN carrname ELSE space ).
  ENDMETHOD.

  METHOD sample.
    result = VALUE #(
      ( carrier = 'AA' connid = '0017' seats = 380 )
      ( carrier = 'AA' connid = '0064' seats = 320 )
      ( carrier = 'LH' connid = '0400' seats = 280 )
      ( carrier = 'LH' connid = '2402' seats = 180 ) ).
  ENDMETHOD.

  METHOD ensure_demo_data.
    DATA carriers TYPE STANDARD TABLE OF zmodulo_carrier WITH EMPTY KEY.

    carriers = VALUE #( ( carrid = 'AA' carrname = 'Alpha Air' )
                        ( carrid = 'LH' carrname = 'Luft Air' )
                        ( carrid = 'UA' carrname = 'Union Air' ) ).
    " 값이 없으면 넣고, 이미 있는 키는 건너뛴다(ACCEPTING DUPLICATE KEYS = 멱등).
    INSERT zmodulo_carrier FROM TABLE @carriers ACCEPTING DUPLICATE KEYS.
    COMMIT WORK.
  ENDMETHOD.
ENDCLASS.
