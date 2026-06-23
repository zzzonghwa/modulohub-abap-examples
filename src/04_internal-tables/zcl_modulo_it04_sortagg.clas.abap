"! <p>ADT에서 F9(Run As -> ABAP Application)로 바로 실행해 데모 출력을 본다.</p>
CLASS zcl_modulo_it04_sortagg DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

    "! 매출 한 건. 정렬·집계·중복 데모의 공통 행 타입.
    TYPES amount TYPE p LENGTH 13 DECIMALS 2.
    TYPES:
      BEGIN OF sale,
        id       TYPE i,
        category TYPE string,
        city     TYPE string,
        amount   TYPE amount,
      END OF sale.
    TYPES sales TYPE STANDARD TABLE OF sale WITH DEFAULT KEY.

    "! 카테고리별 합계 행. COLLECT 대상 구조.
    TYPES:
      BEGIN OF category_total,
        category TYPE string,
        amount   TYPE amount,
      END OF category_total.
    TYPES category_totals TYPE STANDARD TABLE OF category_total WITH DEFAULT KEY.

    "! 문자열 리스트(중복 제거 데모용).
    TYPES texts TYPE STANDARD TABLE OF string WITH DEFAULT KEY.

    "! SORT ... DESCENDING: 금액 내림차순 정렬 후 1위 행을 고른다.
    "! @parameter result | 최고 금액 행의 id
    METHODS sort_by_amount_desc
      RETURNING VALUE(result) TYPE i.

    "! SORT ... BY f1 ASC f2 DESC: 다중 필드 정렬(도시 오름차순, 금액 내림차순).
    "! @parameter result | 정렬된 순서의 id를 콤마로 이은 문자열
    METHODS sort_multi
      RETURNING VALUE(result) TYPE string.

    "! SORT 후 DELETE ADJACENT DUPLICATES: 인접 중복 제거로 distinct 개수를 센다.
    "! @parameter result | 서로 다른 카테고리 수
    METHODS dedup_categories
      RETURNING VALUE(result) TYPE i.

    "! 같은 방식으로 서로 다른 도시 수를 센다.
    "! @parameter result | 서로 다른 도시 수
    METHODS distinct_cities
      RETURNING VALUE(result) TYPE i.

    "! COLLECT: 키(category)별로 숫자 필드(amount)를 자동 누적한다.
    "! @parameter category | 합계를 볼 카테고리
    "! @parameter result   | 해당 카테고리 합계(없으면 0)
    METHODS collect_by_category
      IMPORTING category      TYPE string
      RETURNING VALUE(result) TYPE amount.

    "! LOOP ... GROUP BY: 그룹별로 묶어 그룹 합계를 구하고 최댓값을 돌려준다.
    "! @parameter result | 카테고리 그룹 합계 중 최댓값
    METHODS group_by_totals
      RETURNING VALUE(result) TYPE amount.

  PRIVATE SECTION.
    "! 데모용 매출 8건(카테고리 3종·도시 3종) 샘플 데이터.
    METHODS sample
      RETURNING VALUE(result) TYPE sales.
ENDCLASS.


CLASS zcl_modulo_it04_sortagg IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    out->write( `=== IT04 정렬·집계·중복 ===` ).
    out->write( |sort_by_amount_desc       = { sort_by_amount_desc( ) }| ).
    out->write( |sort_multi(city,amount)   = { sort_multi( ) }| ).
    out->write( |dedup_categories          = { dedup_categories( ) }| ).
    out->write( |distinct_cities           = { distinct_cities( ) }| ).
    out->write( |collect_by_category(BOOK) = { collect_by_category( `BOOK` ) }| ).
    out->write( |group_by_totals(max)      = { group_by_totals( ) }| ).
  ENDMETHOD.

  METHOD sort_by_amount_desc.
    DATA(tab) = sample( ).
    SORT tab BY amount DESCENDING.
    result = tab[ 1 ]-id.
  ENDMETHOD.

  METHOD sort_multi.
    DATA(tab) = sample( ).
    SORT tab BY city ASCENDING amount DESCENDING.
    result = REDUCE string( INIT text = ``
                            FOR row IN tab
                            NEXT text = COND #( WHEN text IS INITIAL THEN |{ row-id }|
                                                ELSE |{ text },{ row-id }| ) ).
  ENDMETHOD.

  METHOD dedup_categories.
    DATA(cats) = VALUE texts( FOR row IN sample( ) ( row-category ) ).
    SORT cats.
    DELETE ADJACENT DUPLICATES FROM cats.
    result = lines( cats ).
  ENDMETHOD.

  METHOD distinct_cities.
    DATA(cities) = VALUE texts( FOR row IN sample( ) ( row-city ) ).
    SORT cities.
    DELETE ADJACENT DUPLICATES FROM cities.
    result = lines( cities ).
  ENDMETHOD.

  METHOD collect_by_category.
    DATA(tab) = sample( ).
    DATA totals TYPE category_totals.
    LOOP AT tab INTO DATA(row).
      COLLECT VALUE category_total( category = row-category amount = row-amount ) INTO totals.
    ENDLOOP.
    READ TABLE totals WITH KEY category = category INTO DATA(found).
    result = COND #( WHEN sy-subrc = 0 THEN found-amount ).
  ENDMETHOD.

  METHOD group_by_totals.
    DATA(tab) = sample( ).
    LOOP AT tab INTO DATA(row) GROUP BY ( category = row-category ) INTO DATA(group_key).
      DATA(group_sum) = CONV amount( 0 ).
      LOOP AT GROUP group_key INTO DATA(member).
        group_sum = group_sum + member-amount.
      ENDLOOP.
      result = COND #( WHEN group_sum > result THEN group_sum ELSE result ).
    ENDLOOP.
  ENDMETHOD.

  METHOD sample.
    result = VALUE #(
      ( id = 1 category = `BOOK` city = `Seoul`   amount = '10.00' )
      ( id = 2 category = `FOOD` city = `Busan`   amount = '5.00' )
      ( id = 3 category = `BOOK` city = `Seoul`   amount = '20.00' )
      ( id = 4 category = `TECH` city = `Incheon` amount = '100.00' )
      ( id = 5 category = `FOOD` city = `Seoul`   amount = '5.00' )
      ( id = 6 category = `BOOK` city = `Busan`   amount = '30.00' )
      ( id = 7 category = `TECH` city = `Seoul`   amount = '50.00' )
      ( id = 8 category = `FOOD` city = `Busan`   amount = '15.00' ) ).
  ENDMETHOD.
ENDCLASS.
