CLASS zcl_modulo_oo04_signature DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    "! ADT에서 F9(Run As -> ABAP Application)로 바로 실행해 데모 출력을 본다.
    "! 메서드 시그니처: IMPORTING/EXPORTING/CHANGING/RETURNING/RAISING,
    "! VALUE vs 참조 전달, OPTIONAL/DEFAULT/IS SUPPLIED, PREFERRED PARAMETER.
    INTERFACES if_oo_adt_classrun.
ENDCLASS.


CLASS zcl_modulo_oo04_signature IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    DATA running TYPE i VALUE 100.

    out->write( `=== OO04 메서드 시그니처 ===` ).
    DATA(calc) = NEW lcl_calc( ).

    " RETURNING(함수형) — 표현식 위치에서 그대로 사용.
    out->write( |add(3,4) = { calc->add( a = 3 b = 4 ) }| ).

    " EXPORTING — 복수 출력은 수신 위치 인라인 선언으로 받는다.
    calc->split(
      EXPORTING total = 17 parts = 5
      IMPORTING quotient = DATA(quotient) remainder = DATA(remainder) ).
    out->write( |split(17,5) -> 몫={ quotient } 나머지={ remainder }| ).

    " CHANGING — 호출자 변수(running)를 제자리에서 갱신.
    calc->accumulate( EXPORTING amount = 25 CHANGING running_total = running ).
    out->write( |accumulate(+25) -> running = { running }| ).

    " OPTIONAL/DEFAULT + IS SUPPLIED.
    out->write( |greet( )                = { calc->greet( ) }| ).
    out->write( |greet(name=Kim)         = { calc->greet( name = `Kim` ) }| ).
    out->write( |greet(greeting=Hi,Lee)  = { calc->greet( greeting = `Hi` name = `Lee` ) }| ).

    " PREFERRED PARAMETER — 이름 없이 단일 인자 전달.
    out->write( |label( `core` )         = { calc->label( `core` ) }| ).

    " RAISING — 정상/예외 경로를 TRY/CATCH로 함께 시연.
    TRY.
        DATA(good) = calc->divide( dividend = 10 divisor = 2 ).
        out->write( |divide(10,2) = { good }| ).
        DATA(bad) = calc->divide( dividend = 10 divisor = 0 ).
        out->write( |divide(10,0) = { bad }| ).
      CATCH cx_sy_zerodivide.
        out->write( `divide(10,0) -> cx_sy_zerodivide 발생(0으로 나눌 수 없음)` ).
    ENDTRY.
  ENDMETHOD.
ENDCLASS.
