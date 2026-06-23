"! ADT에서 F9(Run As -> ABAP Application)로 바로 실행해 데모 출력을 본다.
CLASS zcl_modulo_it01_tabtypes DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

    "! 고객 한 명. 모든 테이블 종류 데모의 공통 행 타입.
    TYPES:
      BEGIN OF customer,
        id   TYPE i,
        name TYPE string,
        city TYPE string,
      END OF customer.

    "! STANDARD: 인덱스 접근, 중복 허용. 기본 테이블 종류.
    TYPES customers TYPE STANDARD TABLE OF customer WITH DEFAULT KEY.

    "! SORTED: 키(name)로 항상 정렬 유지, 이진 탐색. NON-UNIQUE라 동명 허용.
    TYPES sorted_customers TYPE SORTED TABLE OF customer WITH NON-UNIQUE KEY name.

    "! HASHED: 유니크 키(id) 해시 접근. 인덱스 없음, 대량 키 조회에 유리.
    TYPES hashed_customers TYPE HASHED TABLE OF customer WITH UNIQUE KEY id.

    "! STANDARD + 보조 정렬 키(by_city). 기본 접근은 인덱스, 도시 조회는 키.
    TYPES:
      city_indexed TYPE STANDARD TABLE OF customer
        WITH EMPTY KEY
        WITH NON-UNIQUE SORTED KEY by_city COMPONENTS city.

    "! STANDARD 테이블은 키 검사가 없어 동일 행도 그대로 쌓인다.
    "! @parameter result | 첫 행을 한 번 더 APPEND한 뒤의 행 수(7)
    METHODS standard_allows_dups
      RETURNING VALUE(result) TYPE i.

    "! SORTED 테이블은 INSERT 순서와 무관하게 키(name) 오름차순을 유지한다.
    "! @parameter result | 정렬된 이름을 콤마로 이은 문자열
    METHODS sorted_keeps_order
      RETURNING VALUE(result) TYPE string.

    "! HASHED 테이블은 유니크 키로 행을 인덱스 없이 직접 조회한다.
    "! @parameter id     | 찾을 고객 id
    "! @parameter result | 해당 고객 이름(없으면 빈 문자열)
    METHODS hashed_lookup
      IMPORTING id            TYPE i
      RETURNING VALUE(result) TYPE string.

    "! 유니크 키 테이블에 중복 키를 INSERT하면 행이 추가되지 않고 sy-subrc=4.
    "! @parameter result | 두 번째 INSERT 직후의 sy-subrc(4)
    METHODS unique_rejects_dup
      RETURNING VALUE(result) TYPE i.

    "! 보조 키(by_city)로 도시별 행을 조회한다. USING KEY로 키를 명시.
    "! @parameter target_city | 도시명
    "! @parameter result      | 해당 도시 고객 수
    METHODS via_secondary_key
      IMPORTING target_city   TYPE string
      RETURNING VALUE(result) TYPE i.

  PRIVATE SECTION.
    "! 데모용 고객 6명(도시 4종) 샘플 데이터.
    METHODS sample
      RETURNING VALUE(result) TYPE customers.
ENDCLASS.


CLASS zcl_modulo_it01_tabtypes IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    out->write( `=== IT01 내부테이블 타입·선언 ===` ).
    out->write( |standard_allows_dups     = { standard_allows_dups( ) }| ).
    out->write( |sorted_keeps_order       = { sorted_keeps_order( ) }| ).
    out->write( |hashed_lookup( 3 )       = { hashed_lookup( 3 ) }| ).
    out->write( |unique_rejects_dup       = { unique_rejects_dup( ) }| ).
    out->write( |via_secondary_key(Seoul) = { via_secondary_key( `Seoul` ) }| ).
  ENDMETHOD.

  METHOD standard_allows_dups.
    DATA(tab) = sample( ).
    APPEND tab[ 1 ] TO tab.
    result = lines( tab ).
  ENDMETHOD.

  METHOD sorted_keeps_order.
    DATA(sorted) = CONV sorted_customers( sample( ) ).
    result = REDUCE string( INIT text = ``
                            FOR row IN sorted
                            NEXT text = COND #( WHEN text IS INITIAL THEN row-name
                                                ELSE |{ text },{ row-name }| ) ).
  ENDMETHOD.

  METHOD hashed_lookup.
    DATA(hashed) = CONV hashed_customers( sample( ) ).
    READ TABLE hashed WITH KEY id = id INTO DATA(row).
    result = COND #( WHEN sy-subrc = 0 THEN row-name ).
  ENDMETHOD.

  METHOD unique_rejects_dup.
    DATA hashed TYPE hashed_customers.
    INSERT VALUE #( id = 1 name = `Kim` city = `Seoul` ) INTO TABLE hashed.
    INSERT VALUE #( id = 1 name = `Clone` city = `Busan` ) INTO TABLE hashed.
    result = sy-subrc.
  ENDMETHOD.

  METHOD via_secondary_key.
    DATA(tab) = CONV city_indexed( sample( ) ).
    result = lines( FILTER #( tab USING KEY by_city WHERE city = target_city ) ).
  ENDMETHOD.

  METHOD sample.
    result = VALUE #(
      ( id = 1 name = `Kim`  city = `Seoul` )
      ( id = 2 name = `Lee`  city = `Busan` )
      ( id = 3 name = `Park` city = `Incheon` )
      ( id = 4 name = `Choi` city = `Seoul` )
      ( id = 5 name = `Ahn`  city = `Busan` )
      ( id = 6 name = `Yoon` city = `Daegu` ) ).
  ENDMETHOD.
ENDCLASS.
