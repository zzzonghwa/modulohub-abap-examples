"! ADT에서 F9(Run As -> ABAP Application)로 바로 실행해 데모 출력을 본다.
CLASS zcl_modulo_df09_currency DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

    "! 달러 금액(소수 2자리). DDIC CURR 타입을 프로그램 레벨에서 p로 모사한다.
    TYPES amount_usd TYPE p LENGTH 8 DECIMALS 2.

    "! 원화 금액(소수 0자리). 통화별 소수 자릿수가 타입 속성임을 보인다.
    TYPES amount_krw TYPE p LENGTH 8 DECIMALS 0.

    "! USD 금액 합산.
    METHODS add_usd
      IMPORTING first         TYPE amount_usd
                second        TYPE amount_usd
      RETURNING VALUE(result) TYPE amount_usd.

    "! USD 금액에 비율을 곱한 USD 결과. 결과 타입의 소수 2자리로 반올림.
    METHODS scale_usd
      IMPORTING amount        TYPE amount_usd
                rate          TYPE decfloat34
      RETURNING VALUE(result) TYPE amount_usd.

    "! USD의 일정 퍼센트.
    "! @parameter amount  | USD 금액
    "! @parameter percent | 백분율(예: 10 = 10%)
    "! @parameter result  | amount의 percent%
    METHODS percent_of
      IMPORTING amount        TYPE amount_usd
                percent       TYPE decfloat34
      RETURNING VALUE(result) TYPE amount_usd.

    "! USD를 원화로 환산한다. 원화는 소수 0자리라 정수로 반올림된다.
    METHODS to_krw
      IMPORTING usd           TYPE amount_usd
                rate          TYPE decfloat34
      RETURNING VALUE(result) TYPE amount_krw.

    "! 금액을 n등분한 1인당 USD. n<=0이면 가드 예외.
    "! @parameter amount | 나눌 총액
    "! @parameter shares | 인원 수(1 이상)
    "! @parameter result | 1인당 금액(소수 2자리 반올림)
    "! @raising cx_parameter_invalid_range | shares <= 0일 때
    METHODS split_evenly
      IMPORTING amount        TYPE amount_usd
                shares        TYPE i
      RETURNING VALUE(result) TYPE amount_usd
      RAISING   cx_parameter_invalid_range.

    "! 금액이 0인지(IS INITIAL).
    METHODS is_zero
      IMPORTING amount        TYPE amount_usd
      RETURNING VALUE(result) TYPE abap_bool.
ENDCLASS.


CLASS zcl_modulo_df09_currency IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    out->write( `=== DF09 통화/수량 ===` ).
    out->write( |add_usd( 10.50, 4.50 ) = { add_usd( first = CONV #( '10.50' ) second = CONV #( '4.50' ) ) }| ).
    out->write( |scale_usd( 100, x1.5 )  = { scale_usd( amount = CONV #( '100.00' ) rate = CONV #( '1.5' ) ) }| ).
    out->write( |percent_of( 200, 10% )  = { percent_of( amount = CONV #( '200.00' ) percent = CONV #( '10' ) ) }| ).
    out->write( |to_krw( 10, x1300 )     = { to_krw( usd = CONV #( '10.00' ) rate = CONV #( '1300' ) ) }| ).
    TRY.
        out->write( |split_evenly( 30, 4 )  = { split_evenly( amount = CONV #( '30.00' ) shares = 4 ) }| ).
        split_evenly( amount = CONV #( '30.00' ) shares = 0 ).
      CATCH cx_parameter_invalid_range.
        out->write( `split_evenly( 0명 ) -> 가드 예외(정상)` ).
    ENDTRY.
  ENDMETHOD.

  METHOD add_usd.
    result = first + second.
  ENDMETHOD.

  METHOD scale_usd.
    result = amount * rate.
  ENDMETHOD.

  METHOD percent_of.
    result = amount * percent / 100.
  ENDMETHOD.

  METHOD to_krw.
    result = usd * rate.
  ENDMETHOD.

  METHOD split_evenly.
    IF shares <= 0.
      RAISE EXCEPTION TYPE cx_parameter_invalid_range.
    ENDIF.
    result = amount / shares.
  ENDMETHOD.

  METHOD is_zero.
    result = xsdbool( amount IS INITIAL ).
  ENDMETHOD.
ENDCLASS.
