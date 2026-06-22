CLASS zcl_modulo_sql01_basics DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    "! ADT에서 F9(Run As -> ABAP Application)로 바로 실행해 데모 출력을 본다.
    INTERFACES if_oo_adt_classrun.

    "! 항공편 한 건. ABAP SQL 데모의 공통 행 타입.
    "! 실제 시스템에서는 DDIC 데이터베이스 테이블이나 released CDS 뷰가 데이터 소스지만,
    "! 예제는 자체 포함을 위해 내부 테이블을 소스로 쓴다(SELECT ... FROM @itab, 7.52+).
    TYPES:
      BEGIN OF flight,
        carrier TYPE c LENGTH 3,
        connid  TYPE n LENGTH 4,
        seats   TYPE i,
      END OF flight.
    TYPES flights TYPE STANDARD TABLE OF flight WITH EMPTY KEY.

    "! SELECT ... INTO TABLE: 결과 집합 전체를 내부 테이블 타깃으로 읽는다.
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

  PRIVATE SECTION.
    "! 데모용 항공편 4건 샘플 데이터.
    METHODS sample
      RETURNING VALUE(result) TYPE flights.
ENDCLASS.


CLASS zcl_modulo_sql01_basics IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    out->write( `=== SQL01 ABAP SQL 토대·결과 매핑 ===` ).
    out->write( |read_into_table(rows)        = { read_into_table( ) }| ).
    out->write( |count_into_scalar            = { count_into_scalar( ) }| ).
    out->write( |read_single_row(AA,0017)     = { read_single_row( carrier = 'AA' connid = '0017' ) }| ).
    out->write( |read_single_row(ZZ,9999) 미스 = { read_single_row( carrier = 'ZZ' connid = '9999' ) }| ).
  ENDMETHOD.

  METHOD read_into_table.
    " 데이터 소스는 호스트 변수여야 한다 — 식 @( sample( ) )은 소스 위치에 올 수 없다.
    DATA(source) = sample( ) ##NEEDED. " @source가 FROM에 쓰이나 정적분석이 못 봄
    " 내부 테이블 타깃: INTO TABLE @DATA(...)로 결과 집합 전체를 받는다.
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

  METHOD sample.
    result = VALUE #(
      ( carrier = 'AA' connid = '0017' seats = 380 )
      ( carrier = 'AA' connid = '0064' seats = 320 )
      ( carrier = 'LH' connid = '0400' seats = 280 )
      ( carrier = 'LH' connid = '2402' seats = 180 ) ).
  ENDMETHOD.
ENDCLASS.
