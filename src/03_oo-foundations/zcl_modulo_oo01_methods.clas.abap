"! <p>ADT에서 F9(Run As -> ABAP Application)로 바로 실행해 데모 출력을 본다.</p>
"! <p>모던 ABAP에서 모듈화의 단위는 FORM/PERFORM이 아니라 메서드다.</p>
"! <p>인스턴스 메서드(->), 정적 메서드(=>), 함수형 메서드(RETURNING)를 대조한다.</p>
CLASS zcl_modulo_oo01_methods DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
ENDCLASS.


CLASS zcl_modulo_oo01_methods IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    out->write( `=== OO01 메서드·모듈화 ===` ).

    " (1) 인스턴스 메서드: 객체를 먼저 만들고 -> 로 호출한다.
    DATA(counter) = NEW lcl_counter( start = 10 ).
    counter->increment( ).            " by 생략 -> DEFAULT 1
    counter->increment( by = 4 ).
    out->write( |인스턴스 value( )      = { counter->value( ) }| ).

    " (2) 정적 메서드: 인스턴스 없이 클래스명=> 로 호출한다(유틸리티).
    out->write( |정적 description( )    = { lcl_counter=>description( ) }| ).

    " (3) 함수형 메서드는 표현식 위치에서 바로 쓴다(= abap_true 비교 불필요는 07-1).
    IF counter->value( ) > 12.
      out->write( `함수형 호출을 IF 조건식에서 직접 사용` ).
    ENDIF.

    " (4) 메서드 체이닝: NEW 결과에 곧바로 함수형 메서드를 잇는다.
    out->write( |체이닝 NEW( )->double( ) = { NEW lcl_counter( start = 21 )->double( ) }| ).

    " (5) 정적 팩토리(=>)로 만든 인스턴스에 인스턴스 메서드(->)를 호출.
    DATA(from_factory) = lcl_counter=>of( 7 ).
    out->write( |팩토리 of( 7 )->value( ) = { from_factory->value( ) }| ).
  ENDMETHOD.
ENDCLASS.
