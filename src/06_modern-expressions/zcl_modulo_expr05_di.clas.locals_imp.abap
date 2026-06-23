"! 알 수 없는 전략 종류 — 팩토리가 미지원 enum을 받으면 던지는 도메인 예외.
"! CX_STATIC_CHECK 기반이라 RAISING 절에 선언해 호출자에게 처리를 강제한다.
CLASS lcx_unknown DEFINITION INHERITING FROM cx_static_check.
ENDCLASS.

CLASS lcx_unknown IMPLEMENTATION.
ENDCLASS.


"! 할인 전략 계약 — 모든 전략이 공유하는 좁은 인터페이스(인터페이스 분리 원칙).
"! 인터페이스로 공개 메서드를 노출하면 의존을 디커플하고 테스트 더블 교체가 쉬워진다.
INTERFACE lif_discount.
  METHODS apply IMPORTING amount        TYPE i
                RETURNING VALUE(result) TYPE i.
ENDINTERFACE.


"! 로깅 계약 — 인터페이스 합성 데모용 좁은 계약.
INTERFACE lif_audit.
  METHODS note IMPORTING text TYPE string.
ENDINTERFACE.


"! 합성 인터페이스 — lif_audit를 포함한다. 이 계약을 구현하는 클래스는
"! note( )까지 모두 구현해야 한다.
INTERFACE lif_priced_audit.
  INTERFACES lif_audit.
  METHODS apply IMPORTING amount        TYPE i
                RETURNING VALUE(result) TYPE i.
ENDINTERFACE.


"! 무할인 전략 — 금액을 그대로 돌려준다(기본/Null Object).
CLASS lcl_none DEFINITION CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES lif_discount.
ENDCLASS.

CLASS lcl_none IMPLEMENTATION.
  METHOD lif_discount~apply.
    result = amount.
  ENDMETHOD.
ENDCLASS.


"! 정률 할인 전략 — 생성자로 퍼센트를 받아 그만큼 깎는다.
CLASS lcl_percent DEFINITION CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES lif_discount.
    METHODS constructor IMPORTING percent TYPE i.
  PRIVATE SECTION.
    DATA rate TYPE i.
ENDCLASS.

CLASS lcl_percent IMPLEMENTATION.
  METHOD constructor.
    rate = percent.
  ENDMETHOD.

  METHOD lif_discount~apply.
    " 정수 나눗셈은 반올림한다 — 데모 금액은 100의 배수라 정확. 실무는 통화 반올림 규칙을 따른다.
    result = amount - amount * rate / 100.
  ENDMETHOD.
ENDCLASS.


"! 정액 할인 전략 — Factory의 세 번째 분기. 금액에서 고정액을 뺀다(0 미만은 0).
CLASS lcl_flat DEFINITION CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES lif_discount.
    METHODS constructor IMPORTING amount TYPE i.
  PRIVATE SECTION.
    DATA cut TYPE i.
ENDCLASS.

CLASS lcl_flat IMPLEMENTATION.
  METHOD constructor.
    cut = amount.
  ENDMETHOD.

  METHOD lif_discount~apply.
    result = COND #( WHEN amount - cut > 0 THEN amount - cut ELSE 0 ).
  ENDMETHOD.
ENDCLASS.


"! 할인 전략 팩토리 — CREATE PRIVATE으로 생성 게이트를 잠그고,
"! 정적 팩토리 메서드가 SWITCH+NEW로 구체 타입을 골라 인터페이스 레퍼런스로 돌려준다.
"! 클라이언트는 구체 클래스명을 모른 채 enum 상수만으로 전략을 얻는다.
CLASS lcl_discount_factory DEFINITION CREATE PRIVATE.
  PUBLIC SECTION.
    "! 전략 종류 — 인터페이스 상수가 아니라 팩토리 상수로 SWITCH 분기 키를 노출한다.
    CONSTANTS:
      none    TYPE i VALUE 0,
      percent TYPE i VALUE 1,
      flat    TYPE i VALUE 2.
    "! 종류와 파라미터로 전략을 만든다. 새 전략은 분기만 추가하면 되고 클라이언트는 무변경.
    CLASS-METHODS create
      IMPORTING kind          TYPE i
                parameter     TYPE i DEFAULT 0
      RETURNING VALUE(result) TYPE REF TO lif_discount
      RAISING   lcx_unknown.
ENDCLASS.

CLASS lcl_discount_factory IMPLEMENTATION.
  METHOD create.
    result = SWITCH #( kind
      WHEN none    THEN NEW lcl_none( )
      WHEN percent THEN NEW lcl_percent( parameter )
      WHEN flat    THEN NEW lcl_flat( parameter )
      ELSE THROW lcx_unknown( ) ).
  ENDMETHOD.
ENDCLASS.


"! 어댑터가 감쌀 레거시 API — 계약(lif_discount)과 맞지 않는 시그니처(deduct, 천분율 반환).
CLASS lcl_legacy_promo DEFINITION CREATE PUBLIC.
  PUBLIC SECTION.
    "! 천분율(per mille) 할인 후 금액을 돌려주는 옛 메서드 — 이름·단위가 계약과 불일치.
    METHODS deduct
      IMPORTING gross         TYPE i
                per_mille     TYPE i
      RETURNING VALUE(result) TYPE i.
ENDCLASS.

CLASS lcl_legacy_promo IMPLEMENTATION.
  METHOD deduct.
    result = gross - gross * per_mille / 1000.
  ENDMETHOD.
ENDCLASS.


"! 어댑터 — 합성 기반(Object Adapter). 레거시를 DATA 속성으로 보유하고
"! lif_discount 계약으로 변환만 한다(글루 코드). 단일 상속 제약 영향 없음.
CLASS lcl_promo_adapter DEFINITION CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES lif_discount.
    METHODS constructor
      IMPORTING legacy    TYPE REF TO lcl_legacy_promo
                per_mille TYPE i.
  PRIVATE SECTION.
    DATA legacy    TYPE REF TO lcl_legacy_promo.
    DATA per_mille TYPE i.
ENDCLASS.

CLASS lcl_promo_adapter IMPLEMENTATION.
  METHOD constructor.
    me->legacy    = legacy.
    me->per_mille = per_mille.
  ENDMETHOD.

  METHOD lif_discount~apply.
    " 변환만 — 계약의 apply(amount)를 레거시 deduct(gross, per_mille)로 위임한다.
    result = legacy->deduct( gross = amount per_mille = per_mille ).
  ENDMETHOD.
ENDCLASS.


"! 세율 싱글턴 — CREATE PRIVATE + IS NOT BOUND lazy 초기화. 내부 세션당 1인스턴스.
"! 고비용 초기화(여기선 카운터)를 한 번만 수행함을 hits로 보인다.
CLASS lcl_tax DEFINITION CREATE PRIVATE.
  PUBLIC SECTION.
    "! 인스턴스 접근 — 없으면 만들고, 있으면 재사용한다.
    CLASS-METHODS instance RETURNING VALUE(result) TYPE REF TO lcl_tax.
    "! 초기화가 몇 번 일어났는지 — 싱글턴이면 항상 1.
    CLASS-METHODS init_count RETURNING VALUE(result) TYPE i.
    "! 세금 포함 금액.
    METHODS gross
      IMPORTING net           TYPE i
      RETURNING VALUE(result) TYPE i.
    "! 테스트 격리용 — 세션 전역 싱글턴 상태를 비운다.
    CLASS-METHODS reset.
  PRIVATE SECTION.
    CLASS-DATA singleton TYPE REF TO lcl_tax.
    CLASS-DATA inits     TYPE i.
    DATA rate_percent    TYPE i.
    METHODS constructor.
ENDCLASS.

CLASS lcl_tax IMPLEMENTATION.
  METHOD instance.
    IF singleton IS NOT BOUND.
      singleton = NEW lcl_tax( ).
    ENDIF.
    result = singleton.
  ENDMETHOD.

  METHOD constructor.
    " 고비용 초기화 가정 — 싱글턴이면 세션당 한 번만 증가한다.
    inits        = inits + 1.
    rate_percent = 10.
  ENDMETHOD.

  METHOD gross.
    result = net + net * rate_percent / 100.
  ENDMETHOD.

  METHOD init_count.
    result = inits.
  ENDMETHOD.

  METHOD reset.
    CLEAR singleton.
    CLEAR inits.
  ENDMETHOD.
ENDCLASS.


"! 가격 계산기 — 할인 전략을 생성자 주입(DI)으로 받는다.
"! 전략을 바꾸면 동작이 바뀌고(개방-폐쇄), 테스트는 더블을 주입해 격리 검증한다.
"! OPTIONAL + IS BOUND 가드 — 생략 시 기본 전략을 자체 생성한다.
CLASS lcl_pricing DEFINITION CREATE PUBLIC.
  PUBLIC SECTION.
    METHODS constructor IMPORTING strategy TYPE REF TO lif_discount OPTIONAL.
    METHODS net_total
      IMPORTING amounts       TYPE zcl_modulo_expr05_di=>int_list
      RETURNING VALUE(result) TYPE i.
  PRIVATE SECTION.
    DATA strategy TYPE REF TO lif_discount.
ENDCLASS.

CLASS lcl_pricing IMPLEMENTATION.
  METHOD constructor.
    " 주입되면 그대로 쓰고, 생략되면 무할인 기본을 만든다 — 프로덕션 호출 무변경 + 테스트 주입 가능.
    me->strategy = COND #( WHEN strategy IS BOUND THEN strategy ELSE NEW lcl_none( ) ).
  ENDMETHOD.

  METHOD net_total.
    result = REDUCE i( INIT sum = 0
                       FOR amount IN amounts
                       NEXT sum = sum + strategy->apply( amount ) ).
  ENDMETHOD.
ENDCLASS.


"! 추상 계산기 베이스 — 추상 메서드 강제 + 인터페이스 합성 + ALIASES + DEFAULT IGNORE 데모.
"! INTERFACES lif_priced_audit는 포함된 lif_audit~note까지 구현 의무를 지운다.
"! lif_audit~note를 ALIASES log로 짧게 참조한다.
"! 추상 메서드 weight는 하위가 반드시 구현한다.
CLASS lcl_calc_base DEFINITION ABSTRACT CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES lif_priced_audit.
    ALIASES log FOR lif_audit~note.
    "! 하위가 정의하는 가중치 — 추상 메서드는 하위 클래스에서만 구현한다.
    METHODS weight ABSTRACT RETURNING VALUE(result) TYPE i.
    "! 가중치를 곱해 합계를 낸다 — 공통 골격(Template Method식 공유 구현).
    METHODS weighted_total
      IMPORTING amounts       TYPE zcl_modulo_expr05_di=>int_list
      RETURNING VALUE(result) TYPE i.
    "! 마지막으로 기록된 감사 문구 — ALIASES log( )가 실제로 동작함을 보인다.
    METHODS last_note RETURNING VALUE(result) TYPE string.
  PRIVATE SECTION.
    DATA logged TYPE string.
ENDCLASS.

CLASS lcl_calc_base IMPLEMENTATION.
  METHOD lif_priced_audit~apply.
    " 합성 인터페이스의 apply — 베이스에서 공통 동작(그대로 통과)을 둔다.
    result = amount.
  ENDMETHOD.

  METHOD log.
    " ALIASES로 짧아진 lif_audit~note 구현 — 받은 문구를 보관한다.
    logged = text.
  ENDMETHOD.

  METHOD last_note.
    result = logged.
  ENDMETHOD.

  METHOD weighted_total.
    result = REDUCE i( INIT sum = 0
                       FOR amount IN amounts
                       NEXT sum = sum + amount * weight( ) ).
  ENDMETHOD.
ENDCLASS.


"! 구체 계산기 — 추상 weight를 구현한다(가중치 2). 추상 클래스 계약을 완성.
CLASS lcl_double_calc DEFINITION INHERITING FROM lcl_calc_base CREATE PUBLIC.
  PUBLIC SECTION.
    METHODS weight REDEFINITION.
ENDCLASS.

CLASS lcl_double_calc IMPLEMENTATION.
  METHOD weight.
    result = 2.
  ENDMETHOD.
ENDCLASS.
