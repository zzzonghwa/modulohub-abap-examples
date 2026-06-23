"! <p>ADT에서 F9(Run As -> ABAP Application)로 바로 실행해 데모 출력을 본다.</p>
"! <p>클래스=객체의 템플릿, 객체=클래스의 인스턴스. 같은 클래스의 두 인스턴스는</p>
"! <p>독립된 상태를 가진다. 상태(잔액)는 PRIVATE에 두고 public 메서드로만 바꾼다(캡슐화).</p>
"! <p>네이밍은 접두사 없이 — 클래스=명사, 메서드=동사, 불리언=is_/has_ (Clean ABAP).</p>
CLASS zcl_modulo_oo02_class DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
ENDCLASS.


CLASS zcl_modulo_oo02_class IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    out->write( `=== OO02 클래스·캡슐화·네이밍 ===` ).

    " 같은 클래스에서 두 객체를 만든다 — 상태는 인스턴스마다 독립이다.
    DATA(savings) = NEW lcl_account( `KRW` ).
    DATA(travel)  = NEW lcl_account( `USD` ).

    savings->deposit( 1000 ).
    savings->withdraw( 300 ).
    travel->deposit( 50 ).

    " READ-ONLY 공개 속성은 읽기만 가능(외부 대입 시 구문 오류).
    out->write( |savings { savings->currency }: balance = { savings->balance( ) }| ).
    out->write( |travel  { travel->currency }: balance = { travel->balance( ) }| ).

    " 비즈니스 규칙도 캡슐화 — 잔액 부족 인출은 거부된다.
    DATA(ok) = travel->withdraw( 999 ).
    out->write( |travel withdraw 999 성공? = { ok } / balance = { travel->balance( ) }| ).

    " 불리언 getter는 is_ 로 시작해 읽기 흐름이 자연스럽다.
    out->write( |savings is_overdrawn = { savings->is_overdrawn( ) }| ).
  ENDMETHOD.
ENDCLASS.
