CLASS zcl_modulo_tst02_aunit DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    "! ADT에서 F9(Run As -> ABAP Application)로 바로 실행해 데모 출력을 본다.
    "! 테스트(Ctrl+Shift+F10)에서 픽스처·테스트 더블(스텁·스파이) 사용법을 본다.
    "!
    "! ABAP Unit 심화: 의존을 인터페이스로 분리(lif_clock)하고 주입하면,
    "! 테스트가 시간 같은 비결정 의존을 더블로 대체해 결정적으로 검증할 수 있다.
    "! - 픽스처(setup): 매 테스트 전에 cut를 새로 만들어 격리한다.
    "! - 스텁(lcl_fixed_clock): 정해진 값을 돌려준다.
    "! - 스파이(lcl_clock_spy, testclasses): 호출 여부·횟수를 기록해 상호작용을 검증한다.
    INTERFACES if_oo_adt_classrun.

    "! 주어진 시(0..23)의 인사말. 내부적으로 고정 클록을 주입한 인사기를 쓴다.
    "! @parameter hour   | 시(0..23)
    "! @parameter result | 시간대별 인사말
    METHODS greeting_at
      IMPORTING hour          TYPE i
      RETURNING VALUE(result) TYPE string.

    "! 주어진 시가 업무시간(09~17)인지.
    "! @parameter hour   | 시(0..23)
    "! @parameter result | 업무시간이면 abap_true
    METHODS is_business_hours_at
      IMPORTING hour          TYPE i
      RETURNING VALUE(result) TYPE abap_bool.
ENDCLASS.


CLASS zcl_modulo_tst02_aunit IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    out->write( `=== TST02 ABAP Unit 심화·테스트더블·픽스처 ===` ).
    out->write( |greeting_at(8)            = { greeting_at( 8 ) }| ).
    out->write( |greeting_at(14)           = { greeting_at( 14 ) }| ).
    out->write( |greeting_at(20)           = { greeting_at( 20 ) }| ).
    out->write( |is_business_hours_at(10)  = { is_business_hours_at( 10 ) }| ).
    out->write( |is_business_hours_at(20)  = { is_business_hours_at( 20 ) }| ).
  ENDMETHOD.

  METHOD greeting_at.
    result = NEW lcl_greeter( NEW lcl_fixed_clock( hour ) )->greet( ).
  ENDMETHOD.

  METHOD is_business_hours_at.
    result = NEW lcl_greeter( NEW lcl_fixed_clock( hour ) )->is_business_hours( ).
  ENDMETHOD.
ENDCLASS.
