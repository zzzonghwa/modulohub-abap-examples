CLASS zcl_modulo_it02_readfill DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    "! ADT에서 F9(Run As -> ABAP Application)로 바로 실행해 데모 출력을 본다.
    INTERFACES if_oo_adt_classrun.

    "! 제품 한 줄. 채우기·읽기 데모의 공통 행 타입.
    TYPES price TYPE p LENGTH 11 DECIMALS 2.
    TYPES:
      BEGIN OF product,
        id    TYPE i,
        name  TYPE string,
        price TYPE price,
      END OF product.
    TYPES products TYPE STANDARD TABLE OF product WITH DEFAULT KEY.

    "! APPEND로 빈 테이블에 행을 차례로 덧붙인다(끝에 추가).
    "! @parameter result | APPEND한 행 수(3)
    METHODS append_then_count
      RETURNING VALUE(result) TYPE i.

    "! INSERT ... INDEX n: 지정 위치에 행을 끼워 넣어 뒤 행을 밀어낸다.
    "! @parameter result | INDEX 2에 끼워 넣은 뒤 2번째 행 이름
    METHODS insert_at_index
      RETURNING VALUE(result) TYPE string.

    "! READ TABLE ... INDEX: 위치(1-based)로 행을 읽는다.
    "! @parameter index  | 읽을 위치
    "! @parameter result | 그 행의 이름
    METHODS read_by_index
      IMPORTING index         TYPE i
      RETURNING VALUE(result) TYPE string.

    "! READ TABLE ... WITH KEY: 필드값으로 행을 찾는다(sy-subrc로 성공 판정).
    "! @parameter name   | 찾을 제품명
    "! @parameter result | 그 제품 id(없으면 0)
    METHODS read_by_key
      IMPORTING name          TYPE string
      RETURNING VALUE(result) TYPE i.

    "! 테이블 식 itab[ key = ... ]: 한 줄로 행을 읽는다(없으면 예외).
    "! @parameter id     | 찾을 제품 id
    "! @parameter result | 그 제품 이름
    METHODS expr_by_key
      IMPORTING id            TYPE i
      RETURNING VALUE(result) TYPE string.

    "! line_exists( ): 행 존재 여부만 판정(읽기 없이).
    "! @parameter id     | 확인할 제품 id
    "! @parameter result | 존재하면 abap_true
    METHODS exists
      IMPORTING id            TYPE i
      RETURNING VALUE(result) TYPE abap_bool.

    "! line_index( ): 테이블 식이 가리키는 행의 위치를 돌려준다(없으면 0).
    "! @parameter id     | 확인할 제품 id
    "! @parameter result | 그 행의 위치
    METHODS index_of
      IMPORTING id            TYPE i
      RETURNING VALUE(result) TYPE i.

    "! 없는 행을 테이블 식으로 읽으면 CX_SY_ITAB_LINE_NOT_FOUND가 발생한다.
    "! @parameter result | 예외가 잡히면 abap_true
    METHODS missing_raises
      RETURNING VALUE(result) TYPE abap_bool.

  PRIVATE SECTION.
    "! 데모용 제품 6종 샘플 데이터.
    METHODS sample
      RETURNING VALUE(result) TYPE products.
ENDCLASS.


CLASS zcl_modulo_it02_readfill IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    out->write( `=== IT02 채우기·읽기 ===` ).
    out->write( |append_then_count   = { append_then_count( ) }| ).
    out->write( |insert_at_index     = { insert_at_index( ) }| ).
    out->write( |read_by_index( 2 )  = { read_by_index( 2 ) }| ).
    out->write( |read_by_key(Eraser) = { read_by_key( `Eraser` ) }| ).
    out->write( |expr_by_key( 4 )    = { expr_by_key( 4 ) }| ).
    out->write( |exists( 5 )         = { exists( 5 ) }| ).
    out->write( |index_of( 5 )       = { index_of( 5 ) }| ).
    out->write( |missing_raises      = { missing_raises( ) }| ).
  ENDMETHOD.

  METHOD append_then_count.
    DATA tab TYPE products.
    APPEND VALUE #( id = 1 name = `Pen` price = '1.50' ) TO tab.
    APPEND VALUE #( id = 2 name = `Notebook` price = '3.20' ) TO tab.
    APPEND VALUE #( id = 3 name = `Eraser` price = '0.80' ) TO tab.
    result = lines( tab ).
  ENDMETHOD.

  METHOD insert_at_index.
    DATA(tab) = sample( ).
    INSERT VALUE #( id = 99 name = `Inserted` price = '0.00' ) INTO tab INDEX 2.
    result = tab[ 2 ]-name.
  ENDMETHOD.

  METHOD read_by_index.
    DATA(tab) = sample( ).
    READ TABLE tab INDEX index INTO DATA(row).
    result = COND #( WHEN sy-subrc = 0 THEN row-name ).
  ENDMETHOD.

  METHOD read_by_key.
    DATA(tab) = sample( ).
    READ TABLE tab WITH KEY name = name INTO DATA(row).
    result = COND #( WHEN sy-subrc = 0 THEN row-id ).
  ENDMETHOD.

  METHOD expr_by_key.
    DATA(tab) = sample( ).
    result = tab[ id = id ]-name.
  ENDMETHOD.

  METHOD exists.
    DATA(tab) = sample( ).
    result = xsdbool( line_exists( tab[ id = id ] ) ).
  ENDMETHOD.

  METHOD index_of.
    DATA(tab) = sample( ).
    result = line_index( tab[ id = id ] ).
  ENDMETHOD.

  METHOD missing_raises.
    DATA(tab) = sample( ).
    TRY.
        result = xsdbool( tab[ id = 999 ]-id > 0 ).
      CATCH cx_sy_itab_line_not_found.
        result = abap_true.
    ENDTRY.
  ENDMETHOD.

  METHOD sample.
    result = VALUE #(
      ( id = 1 name = `Pen`      price = '1.50' )
      ( id = 2 name = `Notebook` price = '3.20' )
      ( id = 3 name = `Eraser`   price = '0.80' )
      ( id = 4 name = `Marker`   price = '2.10' )
      ( id = 5 name = `Folder`   price = '4.50' )
      ( id = 6 name = `Stapler`  price = '7.90' ) ).
  ENDMETHOD.
ENDCLASS.
