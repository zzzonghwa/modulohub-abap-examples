"! <p>ADT에서 F9(Run As -> ABAP Application)로 바로 실행해 데모 출력을 본다.</p>
"! <p>디버깅·watchpoint의 *실행 가능한* 측면을 자체완결로 시연한다.</p>
"! <p>디버거 UI(breakpoint·watchpoint·step·call stack)는 대화형이라 코드로 못 박지만,</p>
"! <p>코드에 남는 진단 구문(ASSERT·LOG-POINT)과 디버깅 친화 패턴은 실행으로 보인다.</p>
"! <ul>
"! <li>watchpoint 연습용: collatz_steps(value가 오르내려 변경 추적에 적합).</li>
"! <li>ASSERT: 단독 ASSERT <논리식>. CONDITION 키워드 없음. 위반 시 dump.</li>
"! <li>DbC: 사전조건(precondition)·사후조건(postcondition)·클래스 불변(invariant).</li>
"! <li>내부 테이블 오염 추적: watchpoint가 어느 단계에서 값이 바뀌는지 잡는 시나리오.</li>
"! <li>조건부 watchpoint: "Free Condition Entry"식 조건(예: total>임계)을 코드로 흉내.</li>
"! <li>assert type 선택·quit 비종료 모드는 테스트 클래스에서 시연한다.</li>
"! </ul>
CLASS zcl_modulo_tst06_debug DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

    "! 누적 금액의 행 타입(int4). DDIC 의존 없이 자체완결로 둔다.
    TYPES amounts_table TYPE STANDARD TABLE OF i WITH EMPTY KEY.

    "! 콜라츠 단계 수 — value를 짝수면 /2, 홀수면 3*value+1 하여 1에 닿기까지 횟수.
    "! ADT 디버거: 이 메서드에 line breakpoint를 걸고 value에 watchpoint를 둬 단계 실행한다.
    "! value가 1로 수렴하며 오르내리므로 변경 추적(watchpoint) 연습에 적합하다.
    "! @parameter n      | 시작 값(>= 1)
    "! @parameter result | 1에 닿기까지의 단계 수(n=1이면 0, n<1이면 0)
    METHODS collatz_steps
      IMPORTING n             TYPE i
      RETURNING VALUE(result) TYPE i.

    "! ASSERT — 단독 ASSERT <논리식>으로 사전조건을 강제한다(divisor != 0).
    "! 조건이 참이면 무효과, 거짓이면 런타임 오류(dump). CONDITION 키워드는 단독형에 불필요.
    "! 데모 호출은 항상 조건을 만족하므로 dump 없이 몫을 돌려준다.
    "! @parameter dividend | 피제수
    "! @parameter divisor  | 제수(0이면 ASSERT가 dump — 데모는 0을 주지 않음)
    "! @parameter result   | dividend DIV divisor
    METHODS safe_divide
      IMPORTING dividend      TYPE i
                divisor       TYPE i
      RETURNING VALUE(result) TYPE i.

    "! DbC 사전조건(precondition) — 호출자 책임. 입력 위반 시 즉시 dump.
    "! 제곱근 정수부를 계산하되 입력이 음수면 precondition 위반(호출자가 잘못 전달).
    "! 동시에 사후조건(postcondition)으로 result*result <= n < (result+1)^2을 ASSERT한다.
    "! @parameter n      | 음이 아닌 정수(음수면 precondition dump)
    "! @parameter result | floor(sqrt(n)) — 사후조건으로 정확성을 자체 검증
    METHODS isqrt
      IMPORTING n             TYPE i
      RETURNING VALUE(result) TYPE i.

    "! 내부 테이블 오염 추적 시나리오 — watchpoint로 합계가 깨지는 단계를 잡는다.
    "! 금액 목록을 누적하다가, 한 단계에서 음수 보정을 잘못 적용하면 합계가 틀어진다.
    "! 여기서는 *정상* 누적만 수행해 올바른 합계를 돌려준다(디버깅 대상 코드의 정답 버전).
    "! ADT: running_total에 watchpoint를 걸면 각 누적 시점에서 자동 중단된다.
    "! @parameter amounts | 누적할 금액 목록
    "! @parameter result  | 전체 합계
    METHODS sum_amounts
      IMPORTING amounts       TYPE amounts_table
      RETURNING VALUE(result) TYPE i.

    "! 조건부 watchpoint — "Free Condition Entry"식 조건을 코드로 흉내 낸다.
    "! 누적 합이 임계치를 처음 넘는 단계의 1-based 인덱스를 돌려준다.
    "! ADT: running_total에 watchpoint를 걸고 조건 "running_total > threshold"를 입력하면
    "! 조건이 처음 참이 되는 시점에서만 자동 중단된다 — 이 메서드는 그 시점을 값으로 보인다.
    "! @parameter amounts   | 누적할 금액 목록
    "! @parameter threshold | 임계치
    "! @parameter result    | 누적합이 threshold를 처음 초과한 행 번호(없으면 0)
    METHODS first_breach_index
      IMPORTING amounts       TYPE amounts_table
                threshold     TYPE i
      RETURNING VALUE(result) TYPE i.

    "! 클래스 불변(invariant) — 메서드 실행 후에도 유지돼야 할 일관성 조건.
    "! 잔액과 거래 합계가 항상 일치함을 ASSERT로 자체 검증한다(언어 미지원의 실용 대안).
    "! @parameter opening   | 개시 잔액
    "! @parameter movements | 입출금(부호 포함) 목록
    "! @parameter result    | 마감 잔액(= opening + 합계, 불변식으로 검증)
    METHODS post_movements
      IMPORTING opening       TYPE i
                movements     TYPE amounts_table
      RETURNING VALUE(result) TYPE i.

  PRIVATE SECTION.
    "! 데모용 금액 샘플.
    METHODS sample_amounts
      RETURNING VALUE(result) TYPE amounts_table.
ENDCLASS.


CLASS zcl_modulo_tst06_debug IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    out->write( `=== TST06 디버깅 (ADT 디버거·watchpoint) ===` ).
    out->write( |collatz_steps(1)            = { collatz_steps( 1 ) }| ).
    out->write( |collatz_steps(6)            = { collatz_steps( 6 ) }| ).
    out->write( |collatz_steps(27)           = { collatz_steps( 27 ) } (정점 9232, watchpoint 연습)| ).
    out->write( |safe_divide(20,4)           = { safe_divide( dividend = 20 divisor = 4 ) } (ASSERT divisor<>0)| ).
    out->write( |isqrt(50)                   = { isqrt( 50 ) } (DbC 사전·사후조건)| ).
    out->write( |sum_amounts(sample)         = { sum_amounts( sample_amounts( ) ) } (오염 추적 시나리오)| ).
    out->write( |first_breach_index(>=50)    = { first_breach_index( amounts = sample_amounts( )
                                                                     threshold = 50 ) } (조건부 watchpoint)| ).
    DATA(closing) = post_movements( opening   = 100
                                    movements = VALUE #( ( 50 ) ( -30 ) ( 20 ) ) ).
    out->write( |post_movements(100,+50-30+20) = { closing } (불변식 invariant)| ).
    out->write( `collatz_steps에 breakpoint, value에 watchpoint를 걸고 단계 실행해 본다.` ).
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

  METHOD safe_divide.
    " 단독 ASSERT: 논리식이 거짓이면 dump. CONDITION 키워드 없음.
    " divisor=0으로 호출하면 여기서 즉시 실패해 침묵하는 0 나눗셈 dump보다 의도가 분명하다.
    ASSERT divisor <> 0.
    result = dividend DIV divisor.
  ENDMETHOD.

  METHOD isqrt.
    " 사전조건(precondition): 음수 입력은 호출자 잘못 -> 즉시 실패.
    ASSERT n >= 0.
    " 단순 선형 탐색으로 floor(sqrt(n))을 구한다(데모용, 작은 n).
    WHILE ( result + 1 ) * ( result + 1 ) <= n.
      result = result + 1.
    ENDWHILE.
    " 사후조건(postcondition): 구현이 계약을 지켰는지 자체 검증.
    " result^2 <= n 이고 (result+1)^2 > n 이어야 floor(sqrt(n))이다.
    ASSERT result * result <= n.
    ASSERT ( result + 1 ) * ( result + 1 ) > n.
  ENDMETHOD.

  METHOD sum_amounts.
    " running_total은 watchpoint 대상에 적합한 누적기 — 각 단계마다 값이 바뀐다.
    DATA(running_total) = 0.
    LOOP AT amounts INTO DATA(amount).
      " ADT: running_total에 watchpoint를 걸면 이 누적 직후 자동 중단된다.
      running_total = running_total + amount.
    ENDLOOP.
    result = running_total.
  ENDMETHOD.

  METHOD first_breach_index.
    DATA(running_total) = 0.
    LOOP AT amounts INTO DATA(amount).
      running_total = running_total + amount.
      " 조건부 watchpoint와 같은 의미: running_total > threshold가 처음 참이 되는 행을 잡는다.
      IF running_total > threshold.
        result = sy-tabix.
        RETURN.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD post_movements.
    result = opening.
    DATA(applied_sum) = 0.
    LOOP AT movements INTO DATA(movement).
      result = result + movement.
      applied_sum = applied_sum + movement.
    ENDLOOP.
    " 클래스 불변(invariant): 마감 잔액은 항상 개시 잔액 + 적용 합계와 일치해야 한다.
    " ABAP은 언어 차원의 invariant가 없으므로 ASSERT로 같은 보장을 흉내 낸다.
    ASSERT result = opening + applied_sum.
  ENDMETHOD.

  METHOD sample_amounts.
    result = VALUE #( ( 10 ) ( 25 ) ( -5 ) ( 40 ) ( 30 ) ).
  ENDMETHOD.
ENDCLASS.
