CLASS zcl_modulo_df07_datetime DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    "! ADT에서 F9(Run As -> ABAP Application)로 바로 실행해 데모 출력을 본다.
    INTERFACES if_oo_adt_classrun.

    "! 두 날짜 사이의 일수. 타입 d끼리 빼면 결과는 일수(i)다.
    METHODS days_between
      IMPORTING from_date   TYPE d
                to_date     TYPE d
      RETURNING VALUE(days) TYPE i.

    "! 시작일이 종료일보다 늦으면 예외를 던지는 가드 버전.
    "! @parameter from_date | 시작일
    "! @parameter to_date   | 종료일(from 이상)
    "! @parameter days      | 일수
    "! @raising cx_parameter_invalid_range | to_date < from_date일 때
    METHODS days_between_checked
      IMPORTING from_date   TYPE d
                to_date     TYPE d
      RETURNING VALUE(days) TYPE i
      RAISING   cx_parameter_invalid_range.

    "! 날짜에 일수를 더한다. d + i = d (캘린더 연산).
    METHODS add_days
      IMPORTING date          TYPE d
                days          TYPE i
      RETURNING VALUE(result) TYPE d.

    "! 그 달의 1일. d는 flat 문자형이라 오프셋(date+0(6)=yyyymm)으로 구성한다.
    METHODS first_day_of_month
      IMPORTING date          TYPE d
      RETURNING VALUE(result) TYPE d.

    "! 그 달의 마지막 날인지 판정한다. 다음 날의 월(date+4(2)=MM)과 비교.
    METHODS is_month_end
      IMPORTING date          TYPE d
      RETURNING VALUE(result) TYPE abap_bool.

    "! 분기(1~4). 월을 3으로 나눠 올림한다.
    METHODS quarter_of
      IMPORTING date            TYPE d
      RETURNING VALUE(quarter)  TYPE i.
ENDCLASS.


CLASS zcl_modulo_df07_datetime IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    out->write( `=== DF07 날짜/시간 ===` ).
    DATA(jan_first) = CONV d( '20260101' ).
    DATA(feb_first) = CONV d( '20260201' ).
    out->write( |days_between( 1/1, 2/1 ) = { days_between( from_date = jan_first to_date = feb_first ) }| ).
    out->write( |add_days( 1/1, +31 )      = { add_days( date = jan_first days = 31 ) }| ).
    out->write( |first_day_of_month( 2/17 )= { first_day_of_month( CONV #( '20260217' ) ) }| ).
    out->write( |is_month_end( 1/31 )      = { is_month_end( CONV #( '20260131' ) ) }| ).
    out->write( |quarter_of( 8/15 )        = { quarter_of( CONV #( '20260815' ) ) }| ).
    TRY.
        days_between_checked( from_date = feb_first to_date = jan_first ).
      CATCH cx_parameter_invalid_range.
        out->write( `days_between_checked( 역순 ) -> 가드 예외(정상)` ).
    ENDTRY.
  ENDMETHOD.

  METHOD days_between.
    days = to_date - from_date.
  ENDMETHOD.

  METHOD days_between_checked.
    IF to_date < from_date.
      RAISE EXCEPTION TYPE cx_parameter_invalid_range.
    ENDIF.
    days = to_date - from_date.
  ENDMETHOD.

  METHOD add_days.
    result = date + days.
  ENDMETHOD.

  METHOD first_day_of_month.
    result = |{ date+0(6) }01|.
  ENDMETHOD.

  METHOD is_month_end.
    DATA(next_day) = date + 1.
    result = xsdbool( next_day+4(2) <> date+4(2) ).
  ENDMETHOD.

  METHOD quarter_of.
    DATA(month) = CONV i( date+4(2) ).
    quarter = ( month - 1 ) DIV 3 + 1.
  ENDMETHOD.
ENDCLASS.
