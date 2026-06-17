"! 계좌(account) — 명사 클래스. 잔액은 PRIVATE에 캡슐화하고 동사 메서드로만 변경한다.
CLASS lcl_account DEFINITION CREATE PUBLIC.
  PUBLIC SECTION.
    "! 금액 타입은 길이·소수 고정(제네릭 RETURNING 금지). 클래스 내부 단일 진실.
    TYPES money TYPE p LENGTH 13 DECIMALS 2.

    "! READ-ONLY 공개 속성 — 외부는 읽기만 가능, 대입은 구문 오류로 차단된다.
    DATA currency TYPE string READ-ONLY.

    METHODS constructor
      IMPORTING currency TYPE string DEFAULT `KRW`.

    "! 입금 — 잔액을 늘린다.
    METHODS deposit
      IMPORTING amount TYPE money.

    "! 출금 — 잔액이 충분할 때만 차감한다(비즈니스 규칙 캡슐화).
    "! @parameter success | 잔액 부족이면 abap_false, 변경 없음
    METHODS withdraw
      IMPORTING amount         TYPE money
      RETURNING VALUE(success) TYPE abap_bool.

    "! getter — 내부 잔액을 노출 없이 중개한다.
    METHODS balance
      RETURNING VALUE(result) TYPE money.

    "! 불리언 getter(로직 포함) — 잔액이 음수인지.
    METHODS is_overdrawn
      RETURNING VALUE(result) TYPE abap_bool.
  PRIVATE SECTION.
    "! 캡슐화된 상태 — 오직 이 클래스의 메서드만 접근한다.
    DATA current_balance TYPE money.
ENDCLASS.


CLASS lcl_account IMPLEMENTATION.
  METHOD constructor.
    me->currency = currency.
  ENDMETHOD.

  METHOD deposit.
    current_balance = current_balance + amount.
  ENDMETHOD.

  METHOD withdraw.
    IF amount > current_balance.
      success = abap_false.
      RETURN.
    ENDIF.
    current_balance = current_balance - amount.
    success = abap_true.
  ENDMETHOD.

  METHOD balance.
    result = current_balance.
  ENDMETHOD.

  METHOD is_overdrawn.
    result = xsdbool( current_balance < 0 ).
  ENDMETHOD.
ENDCLASS.
