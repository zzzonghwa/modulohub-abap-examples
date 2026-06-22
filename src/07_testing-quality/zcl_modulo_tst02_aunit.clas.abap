CLASS zcl_modulo_tst02_aunit DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    "! ADT에서 F9(Run As -> ABAP Application)로 데모 출력을, Ctrl+Shift+F10으로 테스트를 본다.
    "!
    "! ABAP Unit 심화(단원 07-2) — 의존을 인터페이스로 분리(lif_clock·lif_notifier)하고
    "! 생성자 주입하면, 테스트가 시간·발송 같은 비결정/부수효과 의존을 더블로 대체해
    "! 결정적으로 검증할 수 있다. 이 글로벌 클래스는 더블을 주입한 도메인 객체의 얇은
    "! 파사드이고, 노트가 가르치는 *테스트 패턴*의 실물은 테스트 인클루드에 모여 있다:
    "! - 픽스처(setup·class_setup): 매 테스트 전 cut 재생성·1회성 공유 준비(B절).
    "! - 단언 다양체: assert_equals·true·false·differs·bound·initial·char_cp(E절·주장11).
    "! - 예외 기대 패턴: TRY-CALL-FAIL-CATCH(F·주장37), RAISING 전달(주장38).
    "! - 수동 더블: 스텁(lcl_fixed_clock)·스파이(lcl_clock_spy)·PARTIALLY IMPLEMENTED(H절·주장14).
    "! - 커스텀 단언 헬퍼 클래스(G·주장39), Only Mock What's Needed 실 구현 활용(주장40).
    "! - given-when-then 서브메서드 추출(M·주장26·27), 픽스처 4종(B·주장6·7).
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

    "! 주어진 시에 발송을 시도해 실제 발송 건수(0 또는 1)를 돌려준다.
    "! 업무시간 밖이면 싱크를 건드리지 않고 0. 내부 발송기는 인사용 고정 클록과
    "! 실 싱크(메모리 누적)를 쓴다 — main 데모용이며, 테스트는 더블을 주입한다.
    "! @parameter hour   | 시(0..23)
    "! @parameter result | 발송 건수(0 또는 1)
    METHODS dispatch_at
      IMPORTING hour          TYPE i
      RETURNING VALUE(result) TYPE i.

    "! 한도 내 발송은 amount를, 초과는 -1을 돌려준다(예외를 흡수한 파사드).
    "! @parameter amount | 발송 금액
    "! @parameter limit  | 허용 한도
    "! @parameter result | 정상 시 amount, 초과 시 -1
    METHODS dispatch_within_limit_at
      IMPORTING amount        TYPE i
                limit         TYPE i
      RETURNING VALUE(result) TYPE i.
ENDCLASS.


CLASS zcl_modulo_tst02_aunit IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    out->write( `=== TST02 ABAP Unit 심화·테스트더블·픽스처 ===` ).
    out->write( |greeting_at(8)               = { greeting_at( 8 ) }| ).
    out->write( |greeting_at(14)              = { greeting_at( 14 ) }| ).
    out->write( |greeting_at(20)              = { greeting_at( 20 ) }| ).
    out->write( |is_business_hours_at(10)     = { is_business_hours_at( 10 ) }| ).
    out->write( |is_business_hours_at(20)     = { is_business_hours_at( 20 ) }| ).
    out->write( |dispatch_at(10)              = { dispatch_at( 10 ) } (업무시간 발송)| ).
    out->write( |dispatch_at(22)              = { dispatch_at( 22 ) } (시간 밖 미발송)| ).
    out->write( |dispatch_within_limit(50,80) = { dispatch_within_limit_at( amount = 50 limit = 80 ) }| ).
    out->write( |dispatch_within_limit(99,80) = { dispatch_within_limit_at( amount = 99 limit = 80 ) } (초과 -1)| ).
  ENDMETHOD.

  METHOD greeting_at.
    result = NEW lcl_greeter( NEW lcl_fixed_clock( hour ) )->greet( ).
  ENDMETHOD.

  METHOD is_business_hours_at.
    result = NEW lcl_greeter( NEW lcl_fixed_clock( hour ) )->is_business_hours( ).
  ENDMETHOD.

  METHOD dispatch_at.
    " main 데모: 실 싱크(메모리 누적 stub)와 고정 클록을 조립한다.
    result = NEW lcl_dispatcher( clock    = NEW lcl_fixed_clock( hour )
                                 notifier = NEW lcl_memory_sink( ) )->dispatch( `demo` ).
  ENDMETHOD.

  METHOD dispatch_within_limit_at.
    " 파사드: 도메인 예외를 흡수해 음수 코드로 변환(노트 주장37 전파 vs 흡수 대비).
    TRY.
        result = NEW lcl_dispatcher( clock    = NEW lcl_fixed_clock( 10 )
                                     notifier = NEW lcl_memory_sink( )
                                   )->dispatch_within_limit( amount = amount limit = limit ).
      CATCH lcx_rejected.
        result = -1.
    ENDTRY.
  ENDMETHOD.
ENDCLASS.
