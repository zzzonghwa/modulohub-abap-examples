"! <p>ADT에서 F9(Run As -> ABAP Application)로 바로 실행해 데모 출력을 본다.</p>
"! <p>표현식 중심 OO 패턴·인터페이스 분리·DI 기초(노트 06-5). 모던 표현식이 패턴에서 어떻게</p>
"! <p>쓰이는지를 자체완결 로컬 타입으로 시연한다.</p>
"! <ul>
"! <li>Strategy + DI: 할인 정책을 인터페이스(lif_discount)로 분리하고 생성자 주입으로 교체(노트 G-07·G-10).</li>
"! <li>Factory: CREATE PRIVATE + SWITCH+NEW로 구체 타입을 감추고 인터페이스 레퍼런스 반환(노트 G-01).</li>
"! <li>Singleton: CREATE PRIVATE + IS NOT BOUND lazy 초기화, 내부 세션 1인스턴스(노트 G-04·G-05).</li>
"! <li>Adapter: 합성 기반으로 레거시 시그니처를 계약으로 변환(노트 G-09).</li>
"! <li>추상 클래스 + 인터페이스 합성 + ALIASES: 공통 골격 강제와 짧은 선택자(노트 W-01·W-07·W-08).</li>
"! </ul>
"! <p>로컬 타입은 locals_imp(lif_discount·lcl_pricing·lcl_discount_factory·lcl_tax 등)에 있다.</p>
CLASS zcl_modulo_expr05_di DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

    "! 금액 리스트 — 로컬 가격 계산기가 공유하는 입력 타입.
    TYPES int_list TYPE STANDARD TABLE OF i WITH EMPTY KEY.

    "! [Strategy/DI] 무할인 전략을 주입한 합계.
    "! @parameter result | 샘플 금액 합계(할인 없음)
    METHODS net_no_discount
      RETURNING VALUE(result) TYPE i.

    "! [Strategy/DI] 정률 할인 전략을 주입한 합계 — 계산기는 동일, 전략만 교체.
    "! @parameter percent | 할인율(%)
    "! @parameter result  | 각 금액에 할인 적용 후 합계
    METHODS net_percent
      IMPORTING percent       TYPE i
      RETURNING VALUE(result) TYPE i.

    "! [DI] 생성자 인자를 생략하면 OPTIONAL+IS BOUND 가드가 기본 전략을 만든다(노트 G-10).
    "! @parameter result | 무할인 기본 전략으로 계산한 합계
    METHODS net_default_dependency
      RETURNING VALUE(result) TYPE i.

    "! [Factory] 종류 상수로 전략을 만들어 합계를 낸다 — 클라이언트는 구체 클래스명을 모른다(노트 G-01).
    "! @parameter kind      | 전략 종류(0 none·1 percent·2 flat)
    "! @parameter parameter | percent면 할인율, flat이면 정액
    "! @parameter result    | 해당 전략으로 계산한 합계
    METHODS net_via_factory
      IMPORTING kind          TYPE i
                parameter     TYPE i DEFAULT 0
      RETURNING VALUE(result) TYPE i.

    "! [Factory] 미지원 종류를 주면 도메인 예외를 던진다 — 잡아서 -1로 표시한다.
    "! @parameter result | 정상 -1(예외가 잡혔음을 뜻함)
    METHODS factory_rejects_unknown
      RETURNING VALUE(result) TYPE i.

    "! [Adapter] 레거시 천분율 API를 계약(lif_discount)으로 변환해 합계를 낸다(노트 G-09).
    "! @parameter per_mille | 천분율 할인(예: 50 = 5%)
    "! @parameter result    | 어댑터를 거친 합계
    METHODS net_via_adapter
      IMPORTING per_mille     TYPE i
      RETURNING VALUE(result) TYPE i.

    "! [Singleton] 세율 싱글턴으로 세금 포함 금액을 낸다(노트 G-04).
    "! @parameter net    | 세전 금액
    "! @parameter result | 세금 10% 포함 금액
    METHODS gross_with_tax
      IMPORTING net           TYPE i
      RETURNING VALUE(result) TYPE i.

    "! [Singleton] 여러 번 instance( )를 호출해도 초기화는 한 번뿐임을 보인다(노트 G-05).
    "! @parameter result | 초기화 횟수(싱글턴이면 1)
    METHODS singleton_init_count
      RETURNING VALUE(result) TYPE i.

    "! [추상/합성] 추상 베이스의 공통 골격에 하위가 채운 가중치(2)를 곱한 합계(노트 W-01).
    "! @parameter result | 각 금액 x2의 합계
    METHODS weighted_via_abstract
      RETURNING VALUE(result) TYPE i.

    "! [ALIASES/합성] lif_audit~note를 ALIASES log로 호출해 기록한 문구를 되읽는다(노트 W-07·W-08).
    "! @parameter result | 기록된 감사 문구
    METHODS audit_roundtrip
      RETURNING VALUE(result) TYPE string.

  PRIVATE SECTION.
    "! 데모용 금액 3건(합 600).
    METHODS sample
      RETURNING VALUE(result) TYPE int_list.
ENDCLASS.


CLASS zcl_modulo_expr05_di IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    out->write( `=== EXPR05 표현식 중심 OO 패턴·DI 기초 ===` ).
    out->write( |net_no_discount            = { net_no_discount( ) } (Strategy+DI)| ).
    out->write( |net_percent(10)            = { net_percent( 10 ) }| ).
    out->write( |net_default_dependency     = { net_default_dependency( ) } (OPTIONAL 가드)| ).
    out->write( |net_via_factory(percent,10)= { net_via_factory( kind = 1 parameter = 10 ) } (Factory)| ).
    out->write( |net_via_factory(flat,50)   = { net_via_factory( kind = 2 parameter = 50 ) }| ).
    out->write( |factory_rejects_unknown    = { factory_rejects_unknown( ) } (예외 잡힘)| ).
    out->write( |net_via_adapter(50)        = { net_via_adapter( 50 ) } (Adapter)| ).
    out->write( |gross_with_tax(600)        = { gross_with_tax( 600 ) } (Singleton)| ).
    out->write( |singleton_init_count       = { singleton_init_count( ) } (초기화 1회)| ).
    out->write( |weighted_via_abstract      = { weighted_via_abstract( ) } (추상 골격 x2)| ).
    out->write( |audit_roundtrip            = { audit_roundtrip( ) } (ALIASES log)| ).
    out->write( `전략만 바꿔 동작이 달라진다 — 계산기 코드는 그대로(개방-폐쇄).` ).
  ENDMETHOD.

  METHOD net_no_discount.
    " 무할인 전략을 주입한다.
    DATA(pricing) = NEW lcl_pricing( NEW lcl_none( ) ).
    result = pricing->net_total( sample( ) ).
  ENDMETHOD.

  METHOD net_percent.
    " 정률 할인 전략을 주입한다 — 계산기는 동일, 전략만 교체.
    DATA(pricing) = NEW lcl_pricing( NEW lcl_percent( percent ) ).
    result = pricing->net_total( sample( ) ).
  ENDMETHOD.

  METHOD net_default_dependency.
    " 의존을 생략 — 생성자의 OPTIONAL+IS BOUND 가드가 무할인 기본을 만든다.
    DATA(pricing) = NEW lcl_pricing( ).
    result = pricing->net_total( sample( ) ).
  ENDMETHOD.

  METHOD net_via_factory.
    " 팩토리가 SWITCH+NEW로 구체 전략을 만들어 인터페이스 레퍼런스로 돌려준다.
    TRY.
        DATA(strategy) = lcl_discount_factory=>create( kind = kind parameter = parameter ).
        result = NEW lcl_pricing( strategy )->net_total( sample( ) ).
      CATCH lcx_unknown.
        result = -1.
    ENDTRY.
  ENDMETHOD.

  METHOD factory_rejects_unknown.
    " 미지원 종류(99) -> 도메인 예외. 잡아서 -1로 표시한다.
    TRY.
        lcl_discount_factory=>create( 99 ).
        result = 0.
      CATCH lcx_unknown.
        result = -1.
    ENDTRY.
  ENDMETHOD.

  METHOD net_via_adapter.
    " 레거시 인스턴스를 어댑터로 감싸 계약(lif_discount)으로 주입한다.
    DATA(adapter) = NEW lcl_promo_adapter( legacy    = NEW lcl_legacy_promo( )
                                           per_mille = per_mille ).
    result = NEW lcl_pricing( adapter )->net_total( sample( ) ).
  ENDMETHOD.

  METHOD gross_with_tax.
    " 싱글턴 인스턴스를 얻어 세금 포함 금액을 계산한다.
    result = lcl_tax=>instance( )->gross( net ).
  ENDMETHOD.

  METHOD singleton_init_count.
    " 격리를 위해 비우고, 세 번 호출해도 초기화는 한 번뿐임을 확인한다.
    lcl_tax=>reset( ).
    lcl_tax=>instance( ).
    lcl_tax=>instance( ).
    lcl_tax=>instance( ).
    result = lcl_tax=>init_count( ).
  ENDMETHOD.

  METHOD weighted_via_abstract.
    " CAST로 구체 객체를 추상 베이스 레퍼런스로 다룬다(다형성) — 골격은 공유, 가중치는 하위가 제공.
    DATA(base) = CAST lcl_calc_base( NEW lcl_double_calc( ) ).
    result = base->weighted_total( sample( ) ).
  ENDMETHOD.

  METHOD audit_roundtrip.
    DATA(calc) = NEW lcl_double_calc( ).
    " ALIASES log( )가 lif_audit~note를 호출 — 짧은 선택자로 합성 인터페이스 메서드 접근.
    calc->log( `discount applied` ).
    result = calc->last_note( ).
  ENDMETHOD.

  METHOD sample.
    result = VALUE #( ( 100 ) ( 200 ) ( 300 ) ).
  ENDMETHOD.
ENDCLASS.
