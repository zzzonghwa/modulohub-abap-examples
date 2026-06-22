CLASS zcl_modulo_tst06_debug DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    "! ADT에서 F9(Run As -> ABAP Application)로 바로 실행해 데모 출력을 본다.
    "! 디버깅 연습: 아래 collatz_steps에 브레이크포인트를 걸고 단계 실행해 본다.
    "!
    "! ADT 디버거 사용법:
    "! - 브레이크포인트: 소스 줄 왼쪽 거터 더블클릭(또는 BREAK-POINT 문 — 운반 전 제거).
    "! - 스텝: F5(Step Into)·F6(Step Over)·F7(Step Return)·F8(Resume).
    "! - watchpoint: 변수가 바뀌거나 조건을 만족할 때 중단(예: value = 1).
    "! - 변수 뷰: 매 스텝마다 value·result의 변화를 관찰한다.
    "! collatz_steps는 value가 오르내리며 1로 수렴 — watchpoint·스텝 연습에 적합하다.
    INTERFACES if_oo_adt_classrun.

    "! 콜라츠 단계 수 — value를 짝수면 /2, 홀수면 3*value+1 하여 1에 닿기까지 횟수.
    "! 사전조건: n >= 1(아니면 0). value가 1로 수렴함은 작은 n에서 경험적으로 성립.
    "! 주의: 큰 홀수는 3*value+1이 i 범위(약 7.15e8 초과)에서 오버플로할 수 있다 — 데모 n은 안전.
    "! @parameter n      | 시작 값(>= 1)
    "! @parameter result | 1에 닿기까지의 단계 수(n=1이면 0)
    METHODS collatz_steps
      IMPORTING n             TYPE i
      RETURNING VALUE(result) TYPE i.
ENDCLASS.


CLASS zcl_modulo_tst06_debug IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    out->write( `=== TST06 디버깅 (ADT 디버거·watchpoint) ===` ).
    out->write( |collatz_steps(1)  = { collatz_steps( 1 ) }| ).
    out->write( |collatz_steps(6)  = { collatz_steps( 6 ) }| ).
    out->write( |collatz_steps(27) = { collatz_steps( 27 ) }| ).
    out->write( `collatz_steps에 브레이크포인트를 걸고 value에 watchpoint를 둬 단계 실행해 본다.` ).
  ENDMETHOD.

  METHOD collatz_steps.
    " 가드: 1 미만이면 수렴이 정의되지 않으므로 즉시 0(무한 루프 방지).
    IF n < 1.
      RETURN.
    ENDIF.
    DATA(value) = n.
    WHILE value <> 1.
      " 짝수면 절반, 홀수면 3배+1. 디버거에서 이 줄을 스텝하며 value를 관찰한다.
      value = COND #( WHEN value MOD 2 = 0 THEN value DIV 2 ELSE 3 * value + 1 ).
      result = result + 1.
    ENDWHILE.
  ENDMETHOD.
ENDCLASS.
