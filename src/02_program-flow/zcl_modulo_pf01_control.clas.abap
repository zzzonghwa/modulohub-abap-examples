CLASS zcl_modulo_pf01_control DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    "! ADT에서 F9(Run As -> ABAP Application)로 바로 실행해 데모 출력을 본다.
    INTERFACES if_oo_adt_classrun.

    TYPES number_list TYPE STANDARD TABLE OF i WITH EMPTY KEY.
    TYPES text_list   TYPE STANDARD TABLE OF string WITH EMPTY KEY.
    "! 등급 한 글자. RETURNING은 완전 타입이어야 하므로(제네릭 c 금지)
    "! 길이를 고정한 별칭을 쓴다.
    TYPES grade_value TYPE c LENGTH 1.

    "! 점수를 등급으로 분류한다. IF/ELSEIF/ELSE 체인.
    "! @parameter score | 점수
    "! @parameter grade | A(>=90) / B(>=80) / C(그 외)
    METHODS classify
      IMPORTING score        TYPE i
      RETURNING VALUE(grade) TYPE grade_value.

    "! 요일 번호를 이름으로 변환한다. CASE ... WHEN ... WHEN OTHERS.
    "! @parameter day  | 1=월 ... 7=일
    "! @parameter name | 요일명(범위 밖은 Unknown)
    METHODS weekday_name
      IMPORTING day         TYPE i
      RETURNING VALUE(name) TYPE string.

    "! 팩토리얼을 DO ... TIMES로 계산한다. sy-index가 1..n 카운터다.
    "! 음수는 정의되지 않으므로 가드 예외를 던진다.
    "! @parameter n      | 0 이상의 정수
    "! @parameter result | n! (0! = 1)
    "! @raising cx_parameter_invalid_range | n < 0일 때
    METHODS factorial
      IMPORTING n             TYPE i
      RETURNING VALUE(result) TYPE i
      RAISING   cx_parameter_invalid_range.

    "! 자릿수 합. WHILE로 10으로 나눠가며 끝자리를 더한다.
    "! @parameter number | 0 이상의 정수
    "! @parameter result | 각 자리 숫자의 합
    METHODS digit_sum
      IMPORTING number        TYPE i
      RETURNING VALUE(result) TYPE i.

    "! 양수만 누적 합산한다. LOOP 안에서 CHECK로 음수·0을 건너뛴다.
    "! @parameter numbers | 정수들
    "! @parameter total   | 양수들의 합
    METHODS sum_positives
      IMPORTING numbers      TYPE number_list
      RETURNING VALUE(total) TYPE i.

    "! 임계값을 처음 초과하는 값을 찾는다. LOOP + EXIT로 조기 종료.
    "! 없으면 가드 예외.
    "! @parameter numbers   | 정수들
    "! @parameter threshold | 임계값
    "! @parameter result    | threshold를 초과하는 첫 값
    "! @raising cx_parameter_invalid_range | 초과값이 없을 때
    METHODS first_over
      IMPORTING numbers       TYPE number_list
                threshold     TYPE i
      RETURNING VALUE(result) TYPE i
      RAISING   cx_parameter_invalid_range.

    "! 1..n FizzBuzz. DO + IF/MOD 조합. 3배수 Fizz, 5배수 Buzz, 공배수 FizzBuzz.
    "! @parameter n     | 상한
    "! @parameter lines | n개의 결과 문자열
    METHODS fizzbuzz
      IMPORTING n            TYPE i
      RETURNING VALUE(lines) TYPE text_list.
ENDCLASS.


CLASS zcl_modulo_pf01_control IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    out->write( `=== PF01 제어 구조 ===` ).
    out->write( |classify( 95 )     = { classify( 95 ) }| ).
    out->write( |weekday_name( 1 )  = { weekday_name( 1 ) }| ).
    out->write( |digit_sum( 12345 ) = { digit_sum( 12345 ) }| ).
    DATA(numbers) = VALUE number_list( ( 1 ) ( -5 ) ( 2 ) ( 0 ) ( 3 ) ).
    out->write( |sum_positives      = { sum_positives( numbers ) }| ).
    out->write( |fizzbuzz( 1..5 )| ).
    out->write( fizzbuzz( 5 ) ).
    TRY.
        out->write( |factorial( 5 )     = { factorial( 5 ) }| ).
        factorial( -1 ).
      CATCH cx_parameter_invalid_range.
        out->write( `factorial( -1 ) -> 가드 예외(정상)` ).
    ENDTRY.
  ENDMETHOD.

  METHOD classify.
    IF score >= 90.
      grade = 'A'.
    ELSEIF score >= 80.
      grade = 'B'.
    ELSE.
      grade = 'C'.
    ENDIF.
  ENDMETHOD.

  METHOD weekday_name.
    CASE day.
      WHEN 1.
        name = `Monday`.
      WHEN 2.
        name = `Tuesday`.
      WHEN 3.
        name = `Wednesday`.
      WHEN 4.
        name = `Thursday`.
      WHEN 5.
        name = `Friday`.
      WHEN 6.
        name = `Saturday`.
      WHEN 7.
        name = `Sunday`.
      WHEN OTHERS.
        name = `Unknown`.
    ENDCASE.
  ENDMETHOD.

  METHOD factorial.
    IF n < 0.
      RAISE EXCEPTION TYPE cx_parameter_invalid_range.
    ENDIF.
    result = 1.
    DO n TIMES.
      result = result * sy-index.
    ENDDO.
  ENDMETHOD.

  METHOD digit_sum.
    DATA(rest) = abs( number ).
    WHILE rest > 0.
      result = result + rest MOD 10.
      rest = rest DIV 10.
    ENDWHILE.
  ENDMETHOD.

  METHOD sum_positives.
    LOOP AT numbers INTO DATA(number).
      CHECK number > 0.
      total = total + number.
    ENDLOOP.
  ENDMETHOD.

  METHOD first_over.
    LOOP AT numbers INTO DATA(number).
      IF number > threshold.
        result = number.
        RETURN.
      ENDIF.
    ENDLOOP.
    RAISE EXCEPTION TYPE cx_parameter_invalid_range.
  ENDMETHOD.

  METHOD fizzbuzz.
    DO n TIMES.
      DATA(value) = sy-index.
      IF value MOD 15 = 0.
        APPEND `FizzBuzz` TO lines.
      ELSEIF value MOD 3 = 0.
        APPEND `Fizz` TO lines.
      ELSEIF value MOD 5 = 0.
        APPEND `Buzz` TO lines.
      ELSE.
        APPEND |{ value }| TO lines.
      ENDIF.
    ENDDO.
  ENDMETHOD.
ENDCLASS.
