"! ADT에서 F9(Run As -> ABAP Application)로 바로 실행해 데모 출력을 본다.
CLASS zcl_modulo_it06_patterns DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

    TYPES amount TYPE p LENGTH 13 DECIMALS 2.

    "! 고객 마스터. HASHED + 유니크 키(id) = 빠른 룩업 맵(dictionary) 패턴.
    TYPES:
      BEGIN OF customer,
        id   TYPE i,
        name TYPE string,
        city TYPE string,
      END OF customer.
    TYPES customers TYPE HASHED TABLE OF customer WITH UNIQUE KEY id.

    "! 주문 트랜잭션. customer_id로 고객 마스터를 참조한다.
    TYPES:
      BEGIN OF sales_order,
        id          TYPE i,
        customer_id TYPE i,
        category    TYPE string,
        amount      TYPE amount,
      END OF sales_order.
    TYPES sales_orders TYPE STANDARD TABLE OF sales_order WITH DEFAULT KEY.

    "! 주문 + 고객명/도시를 합친 조인 결과 행.
    TYPES:
      BEGIN OF enriched,
        order_id TYPE i,
        customer TYPE string,
        city     TYPE string,
        amount   TYPE amount,
      END OF enriched.
    TYPES enriched_list TYPE STANDARD TABLE OF enriched WITH DEFAULT KEY.

    "! 카테고리별 요약(건수·합계) 리포트 행.
    TYPES:
      BEGIN OF cat_summary,
        category TYPE string,
        count    TYPE i,
        total    TYPE amount,
      END OF cat_summary.
    TYPES cat_summaries TYPE STANDARD TABLE OF cat_summary WITH DEFAULT KEY.

    "! 두 테이블 조인: 주문마다 HASHED 고객 맵을 룩업해 이름·도시를 채운다.
    "! @parameter result | 주문 수만큼의 조인 결과 테이블
    METHODS enrich_orders
      RETURNING VALUE(result) TYPE enriched_list.

    "! 조인 결과에서 특정 주문의 고객명을 돌려준다.
    "! @parameter order_id | 주문 id
    "! @parameter result   | 그 주문 고객명(없으면 빈 문자열)
    METHODS customer_of_order
      IMPORTING order_id      TYPE i
      RETURNING VALUE(result) TYPE string.

    "! GROUP BY로 카테고리별 건수·합계 요약 리포트를 만든다.
    "! @parameter result | 카테고리별 요약 테이블
    METHODS summary_by_category
      RETURNING VALUE(result) TYPE cat_summaries.

    "! SORT 후 상위 n건의 주문 id를 돌려준다(금액 내림차순).
    "! @parameter n      | 상위 건수
    "! @parameter result | 상위 n 주문 id를 콤마로 이은 문자열
    METHODS top_n
      IMPORTING n             TYPE i
      RETURNING VALUE(result) TYPE string.

    "! 룩업 맵 패턴: HASHED 고객 맵에서 id로 이름을 직접 조회한다.
    "! @parameter customer_id | 고객 id
    "! @parameter result      | 고객명(없으면 빈 문자열)
    METHODS lookup_map_name
      IMPORTING customer_id   TYPE i
      RETURNING VALUE(result) TYPE string.

    "! 전체 주문 금액 합(REDUCE).
    "! @parameter result | 총액
    METHODS grand_total
      RETURNING VALUE(result) TYPE amount.

  PRIVATE SECTION.
    "! 데모용 고객 마스터 3명(HASHED 맵).
    METHODS customer_map
      RETURNING VALUE(result) TYPE customers.

    "! 데모용 주문 6건.
    METHODS orders_sample
      RETURNING VALUE(result) TYPE sales_orders.
ENDCLASS.


CLASS zcl_modulo_it06_patterns IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    out->write( `=== IT06 실전 패턴·성능 ===` ).
    out->write( |grand_total            = { grand_total( ) }| ).
    out->write( |customer_of_order( 3 ) = { customer_of_order( 3 ) }| ).
    out->write( |lookup_map_name( 2 )   = { lookup_map_name( 2 ) }| ).
    out->write( |top_n( 2 )             = { top_n( 2 ) }| ).
    out->write( `enrich_orders:` ).
    out->write( enrich_orders( ) ).
    out->write( `summary_by_category:` ).
    out->write( summary_by_category( ) ).
  ENDMETHOD.

  METHOD enrich_orders.
    DATA(custs) = customer_map( ).
    DATA(ords) = orders_sample( ).
    LOOP AT ords INTO DATA(o).
      DATA(c) = VALUE customer( custs[ id = o-customer_id ] OPTIONAL ).
      APPEND VALUE #( order_id = o-id customer = c-name city = c-city amount = o-amount ) TO result.
    ENDLOOP.
  ENDMETHOD.

  METHOD customer_of_order.
    DATA(list) = enrich_orders( ).
    READ TABLE list WITH KEY order_id = order_id INTO DATA(row).
    result = COND #( WHEN sy-subrc = 0 THEN row-customer ).
  ENDMETHOD.

  METHOD summary_by_category.
    DATA(ords) = orders_sample( ).
    LOOP AT ords INTO DATA(o) GROUP BY ( category = o-category ) INTO DATA(group_key).
      DATA(count) = 0.
      DATA(total) = CONV amount( 0 ).
      LOOP AT GROUP group_key INTO DATA(member).
        count = count + 1.
        total = total + member-amount.
      ENDLOOP.
      APPEND VALUE #( category = group_key-category count = count total = total ) TO result.
    ENDLOOP.
  ENDMETHOD.

  METHOD top_n.
    DATA(ords) = orders_sample( ).
    SORT ords BY amount DESCENDING.
    DATA(ids) = ``.
    LOOP AT ords INTO DATA(o).
      IF sy-tabix > n.
        EXIT.
      ENDIF.
      ids = COND #( WHEN ids IS INITIAL THEN |{ o-id }| ELSE |{ ids },{ o-id }| ).
    ENDLOOP.
    result = ids.
  ENDMETHOD.

  METHOD lookup_map_name.
    DATA(custs) = customer_map( ).
    DATA(c) = VALUE customer( custs[ id = customer_id ] OPTIONAL ).
    result = c-name.
  ENDMETHOD.

  METHOD grand_total.
    DATA(ords) = orders_sample( ).
    result = REDUCE amount( INIT sum = CONV amount( 0 ) FOR o IN ords NEXT sum = sum + o-amount ).
  ENDMETHOD.

  METHOD customer_map.
    result = VALUE #(
      ( id = 1 name = `Kim`  city = `Seoul` )
      ( id = 2 name = `Lee`  city = `Busan` )
      ( id = 3 name = `Park` city = `Incheon` ) ).
  ENDMETHOD.

  METHOD orders_sample.
    result = VALUE #(
      ( id = 1 customer_id = 1 category = `BOOK` amount = '10.00' )
      ( id = 2 customer_id = 2 category = `FOOD` amount = '5.00' )
      ( id = 3 customer_id = 1 category = `TECH` amount = '100.00' )
      ( id = 4 customer_id = 3 category = `BOOK` amount = '20.00' )
      ( id = 5 customer_id = 2 category = `TECH` amount = '50.00' )
      ( id = 6 customer_id = 1 category = `FOOD` amount = '15.00' ) ).
  ENDMETHOD.
ENDCLASS.
