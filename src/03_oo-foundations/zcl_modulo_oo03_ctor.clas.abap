"! <p>ADT에서 F9(Run As -> ABAP Application)로 바로 실행해 데모 출력을 본다.</p>
"! <p>인스턴스 constructor(NEW마다 1회)·정적 class_constructor(최초 사용 전 1회)·</p>
"! <p>CLASS-DATA(전 인스턴스 공유)·CREATE PRIVATE+factory 싱글톤·NEW 연산자 패턴.</p>
CLASS zcl_modulo_oo03_ctor DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
ENDCLASS.


CLASS zcl_modulo_oo03_ctor IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    DATA sequences TYPE STANDARD TABLE OF REF TO lcl_sequence WITH EMPTY KEY.

    out->write( `=== OO03 가시성·생성자·NEW ===` ).

    " NEW 연산자: NEW class( ) 명시 타입, 그리고 행 타입에서 유추하는 NEW #( ).
    DATA(alpha) = NEW lcl_sequence( `alpha` ).   " 명시 타입
    APPEND alpha TO sequences.
    APPEND NEW #( `beta` )  TO sequences.         " # = lcl_sequence 유추
    APPEND NEW #( `gamma` ) TO sequences.

    " CLASS-DATA는 인스턴스 수와 무관하게 하나만 존재해 모든 객체가 공유한다.
    out->write( |생성된 인스턴스 수(CLASS-DATA) = { lcl_sequence=>created_count }| ).
    LOOP AT sequences INTO DATA(seq).
      out->write( |  id={ seq->id } label={ seq->label }| ).
    ENDLOOP.

    " CREATE PRIVATE + 정적 factory = 싱글톤. 두 번 요청해도 같은 객체다.
    DATA(config_a) = lcl_config=>get_instance( ).
    config_a->set_value( `theme=dark` ).
    DATA(config_b) = lcl_config=>get_instance( ).
    out->write( |싱글톤 config_b->get_value( ) = { config_b->get_value( ) }| ).
    out->write( |같은 객체인가(IS BOUND·동일 ref) = { xsdbool( config_a = config_b ) }| ).
  ENDMETHOD.
ENDCLASS.
