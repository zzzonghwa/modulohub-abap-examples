CLASS zcl_modulo_sql04_cds DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    "! ADT에서 F9(Run As -> ABAP Application)로 바로 실행해 데모 출력을 본다.
    "!
    "! released CDS 뷰 소비(읽기 전용) 패턴을 보인다. 실 시스템에서는 데이터 소스가
    "! released CDS 뷰(API State C1, 예: SELECT ... FROM i_someview)이며, 다음을 따른다.
    "! - 시맨틱 요소명: CDS 뷰는 CamelCase 시맨틱 요소명(예: MaximumCapacity)을 노출한다.
    "! - association: 경로식 \_Carrier-CarrierName 으로 텍스트를 끌어온다(여기선 JOIN으로 대체).
    "! - 읽기 전용·Clean Core: released(C1) 객체만 소비하고 base 테이블 직접 접근은 피한다.
    "! 예제는 자체 포함을 위해 동일 SELECT 구문을 내부 테이블 투영으로 시연한다.
    INTERFACES if_oo_adt_classrun.

    TYPES carrier_code TYPE c LENGTH 3.

    "! released CDS 뷰가 노출하는 투영(소비자가 보는 모양). base 테이블이 아니라 이 투영을 읽는다.
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

    "! released 뷰 소비: 투영 전체를 읽어 행 수를 센다.
    "! @parameter result | 소비한 뷰 행 수
    METHODS consume_count
      RETURNING VALUE(result) TYPE i.

    "! 시맨틱 필드 소비 + 파생 계산: 한 항공편의 좌석 점유율(%).
    "! @parameter carrier | 항공사 코드
    "! @parameter connid  | 연결편 번호
    "! @parameter result  | 점유율 percent(반올림 정수), 미스면 0
    METHODS load_factor_percent
      IMPORTING carrier       TYPE carrier_code
                connid        TYPE flight_view-connid
      RETURNING VALUE(result) TYPE i.

    "! association 소비(JOIN 대체): 항공사 코드로 항공사명을 끌어온다.
    "! @parameter carrier | 항공사 코드
    "! @parameter result  | 항공사명, 미스면 공백
    METHODS carrier_name
      IMPORTING carrier       TYPE carrier_code
      RETURNING VALUE(result) TYPE carrier_text-name.

  PRIVATE SECTION.
    "! released 뷰 투영을 모사한 데모 데이터 5건.
    METHODS sample_view
      RETURNING VALUE(result) TYPE flight_views.
    "! association 대상 텍스트 3건.
    METHODS sample_texts
      RETURNING VALUE(result) TYPE carrier_texts.
ENDCLASS.


CLASS zcl_modulo_sql04_cds IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    out->write( `=== SQL04 released CDS 뷰 소비 ===` ).
    out->write( |consume_count                  = { consume_count( ) }| ).
    out->write( |load_factor_percent(AA,0017)   = { load_factor_percent( carrier = 'AA' connid = '0017' ) }| ).
    out->write( |load_factor_percent(LH,0400)   = { load_factor_percent( carrier = 'LH' connid = '0400' ) }| ).
    out->write( |carrier_name(AA)               = { carrier_name( 'AA' ) }| ).
  ENDMETHOD.

  METHOD consume_count.
    " 소비자는 base 테이블이 아니라 released 뷰의 투영을 읽는다.
    DATA(view) = sample_view( ) ##NEEDED.
    SELECT COUNT(*)
      FROM @view AS flight
      INTO @DATA(rows).
    result = rows.
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

  METHOD carrier_name.
    " 실 CDS에선 경로식 \_Carrier-CarrierName 으로 association을 따라간다.
    " 그 "키로 텍스트를 끌어오는" 의미를 내부 테이블 식(texts[ ... ])으로 그대로 보인다 —
    " 두 내부 테이블 JOIN(7.55+)에 의존하지 않아 7.54에서도 동작한다.
    DATA(texts) = sample_texts( ).
    result = VALUE #( texts[ carrier = carrier ]-name OPTIONAL ).
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
