"! ADT에서 F9(Run As -> ABAP Application)로 바로 실행해 데모 출력을 본다.
CLASS zcl_modulo_it03_loopmod DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

    "! 주문 라인. 순회·변경 데모의 공통 행 타입.
    TYPES amount TYPE p LENGTH 13 DECIMALS 2.
    TYPES:
      BEGIN OF item,
        id     TYPE i,
        name   TYPE string,
        qty    TYPE i,
        price  TYPE amount,
        active TYPE abap_bool,
      END OF item.
    TYPES items TYPE STANDARD TABLE OF item WITH DEFAULT KEY.

    "! LOOP ... INTO: 행을 작업영역으로 복사해 읽기 전용 순회(원본 불변).
    "! @parameter result | 전체 수량 합
    METHODS total_qty
      RETURNING VALUE(result) TYPE i.

    "! LOOP ... ASSIGNING <fs>: 필드심볼로 원본 행을 제자리 수정한다.
    "! @parameter result | 모든 가격을 10% 인상한 뒤의 가격 합
    METHODS raise_prices
      RETURNING VALUE(result) TYPE amount.

    "! LOOP ... REFERENCE INTO: 데이터 참조로 원본 행을 제자리 수정한다.
    "! @parameter result | 모든 수량을 +1 한 뒤의 수량 합
    METHODS bump_qty_ref
      RETURNING VALUE(result) TYPE i.

    "! LOOP ... WHERE: 조건에 맞는 행만 순회한다.
    "! @parameter result | active 행 수
    METHODS count_active
      RETURNING VALUE(result) TYPE i.

    "! LOOP ... FROM .. TO ..: 인덱스 구간만 순회한다.
    "! @parameter result | 2~4번째 행 이름을 콤마로 이은 문자열
    METHODS names_from_to
      RETURNING VALUE(result) TYPE string.

    "! MODIFY ... TRANSPORTING f WHERE cond: 조건 행의 특정 필드만 일괄 변경.
    "! @parameter threshold | 이 가격 미만이면 비활성화
    "! @parameter result    | 변경 후 남은 active 행 수
    METHODS deactivate_cheap
      IMPORTING threshold     TYPE amount
      RETURNING VALUE(result) TYPE i.

    "! DELETE ... WHERE cond: 조건 행을 일괄 삭제한다.
    "! @parameter result | inactive 행 삭제 후 남은 행 수
    METHODS delete_inactive
      RETURNING VALUE(result) TYPE i.

  PRIVATE SECTION.
    "! 데모용 주문 라인 6건(active/inactive 혼재) 샘플 데이터.
    METHODS sample
      RETURNING VALUE(result) TYPE items.
ENDCLASS.


CLASS zcl_modulo_it03_loopmod IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    out->write( `=== IT03 순회·변경 ===` ).
    out->write( |total_qty            = { total_qty( ) }| ).
    out->write( |raise_prices         = { raise_prices( ) }| ).
    out->write( |bump_qty_ref         = { bump_qty_ref( ) }| ).
    out->write( |count_active         = { count_active( ) }| ).
    out->write( |names_from_to(2..4)  = { names_from_to( ) }| ).
    out->write( |deactivate_cheap(2)  = { deactivate_cheap( '2.00' ) }| ).
    out->write( |delete_inactive      = { delete_inactive( ) }| ).
  ENDMETHOD.

  METHOD total_qty.
    DATA(tab) = sample( ).
    LOOP AT tab INTO DATA(row).
      result = result + row-qty.
    ENDLOOP.
  ENDMETHOD.

  METHOD raise_prices.
    DATA(tab) = sample( ).
    LOOP AT tab ASSIGNING FIELD-SYMBOL(<row>).
      <row>-price = <row>-price * '1.1'.
    ENDLOOP.
    " REDUCE 누적 변수의 타입은 INIT 식에서 추론된다. INIT sum = 0(정수 리터럴)이면
    " sum이 i로 잡혀 행마다 정수 반올림돼 소수 합이 틀어진다(22.00 대신 23.00).
    " → 합산 대상이 소수면 INIT를 소수 타입으로 명시 초기화한다.
    result = REDUCE amount( INIT sum = CONV amount( 0 ) FOR row IN tab NEXT sum = sum + row-price ).
  ENDMETHOD.

  METHOD bump_qty_ref.
    DATA(tab) = sample( ).
    LOOP AT tab REFERENCE INTO DATA(ref).
      ref->qty = ref->qty + 1.
    ENDLOOP.
    result = REDUCE i( INIT sum = 0 FOR row IN tab NEXT sum = sum + row-qty ).
  ENDMETHOD.

  METHOD count_active.
    DATA(tab) = sample( ).
    LOOP AT tab TRANSPORTING NO FIELDS WHERE active = abap_true.
      result = result + 1.
    ENDLOOP.
  ENDMETHOD.

  METHOD names_from_to.
    DATA(tab) = sample( ).
    DATA names TYPE string.
    LOOP AT tab INTO DATA(row) FROM 2 TO 4.
      names = COND #( WHEN names IS INITIAL THEN row-name ELSE |{ names },{ row-name }| ).
    ENDLOOP.
    result = names.
  ENDMETHOD.

  METHOD deactivate_cheap.
    DATA(tab) = sample( ).
    MODIFY tab FROM VALUE #( active = abap_false ) TRANSPORTING active WHERE price < threshold.
    LOOP AT tab TRANSPORTING NO FIELDS WHERE active = abap_true.
      result = result + 1.
    ENDLOOP.
  ENDMETHOD.

  METHOD delete_inactive.
    DATA(tab) = sample( ).
    DELETE tab WHERE active = abap_false.
    result = lines( tab ).
  ENDMETHOD.

  METHOD sample.
    result = VALUE #(
      ( id = 1 name = `Pen`     qty = 2  price = '1.50' active = abap_true )
      ( id = 2 name = `Notebook` qty = 5  price = '3.20' active = abap_true )
      ( id = 3 name = `Eraser`  qty = 10 price = '0.80' active = abap_false )
      ( id = 4 name = `Marker`  qty = 3  price = '2.10' active = abap_true )
      ( id = 5 name = `Folder`  qty = 1  price = '4.50' active = abap_false )
      ( id = 6 name = `Stapler` qty = 4  price = '7.90' active = abap_true ) ).
  ENDMETHOD.
ENDCLASS.
