CLASS zcl_modulo_df07_datetime DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
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
