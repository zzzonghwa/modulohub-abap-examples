CLASS ltcl_debug DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA cut TYPE REF TO zcl_modulo_tst06_debug.
    METHODS setup.

    " collatz_steps — watchpoint 연습 대상.
    METHODS already_one         FOR TESTING.
    METHODS six_steps           FOR TESTING.
    METHODS power_of_two        FOR TESTING.
    METHODS long_chain          FOR TESTING.
    METHODS guard_non_positive  FOR TESTING.

    " safe_divide — 단독 ASSERT(A5) 정상 경로.
    METHODS divides_exactly     FOR TESTING.
    METHODS div_truncates       FOR TESTING.

    " isqrt — DbC 사전·사후조건(G1).
    METHODS isqrt_perfect       FOR TESTING.
    METHODS isqrt_between       FOR TESTING.
    METHODS isqrt_zero          FOR TESTING.

    " sum_amounts / first_breach_index — 내부 테이블·조건부 watchpoint(C3).
    METHODS sums_sample         FOR TESTING.
    METHODS breach_at_fourth    FOR TESTING.
    METHODS breach_none         FOR TESTING.

    " post_movements — 클래스 불변(invariant, G4).
    METHODS closing_balance     FOR TESTING.

    " F2/CA1/CA3 assert type 선택 + F3/F4 quit 비종료 모드 시연.
    METHODS right_assert_type   FOR TESTING.
ENDCLASS.


CLASS ltcl_debug IMPLEMENTATION.
  METHOD setup.
    cut = NEW #( ).
  ENDMETHOD.

  METHOD already_one.
    cl_abap_unit_assert=>assert_equals( act = cut->collatz_steps( 1 ) exp = 0 ).
  ENDMETHOD.

  METHOD six_steps.
    " 6 -> 3 -> 10 -> 5 -> 16 -> 8 -> 4 -> 2 -> 1 = 8 단계.
    cl_abap_unit_assert=>assert_equals( act = cut->collatz_steps( 6 ) exp = 8 ).
  ENDMETHOD.

  METHOD power_of_two.
    " 4 -> 2 -> 1 = 2 단계.
    cl_abap_unit_assert=>assert_equals( act = cut->collatz_steps( 4 ) exp = 2 ).
  ENDMETHOD.

  METHOD long_chain.
    " 27은 정점 9232까지 오르내리며 111단계에 1로 수렴 — watchpoint 연습에 좋다.
    cl_abap_unit_assert=>assert_equals( act = cut->collatz_steps( 27 ) exp = 111 ).
  ENDMETHOD.

  METHOD guard_non_positive.
    cl_abap_unit_assert=>assert_equals( act = cut->collatz_steps( 0 ) exp = 0 ).
  ENDMETHOD.

  METHOD divides_exactly.
    cl_abap_unit_assert=>assert_equals( act = cut->safe_divide( dividend = 20 divisor = 4 ) exp = 5 ).
  ENDMETHOD.

  METHOD div_truncates.
    " DIV는 절단 정수 나눗셈 — 7 DIV 2 = 3.
    cl_abap_unit_assert=>assert_equals( act = cut->safe_divide( dividend = 7 divisor = 2 ) exp = 3 ).
  ENDMETHOD.

  METHOD isqrt_perfect.
    " 49는 완전제곱수 -> 7. 사후조건 7^2<=49<8^2 만족.
    cl_abap_unit_assert=>assert_equals( act = cut->isqrt( 49 ) exp = 7 ).
  ENDMETHOD.

  METHOD isqrt_between.
    " 50 -> 7(49<=50<64), 48 -> 6(36<=48<49).
    cl_abap_unit_assert=>assert_equals( act = cut->isqrt( 50 ) exp = 7 ).
    cl_abap_unit_assert=>assert_equals( act = cut->isqrt( 48 ) exp = 6 ).
  ENDMETHOD.

  METHOD isqrt_zero.
    cl_abap_unit_assert=>assert_equals( act = cut->isqrt( 0 ) exp = 0 ).
  ENDMETHOD.

  METHOD sums_sample.
    " 10+25-5+40+30 = 100.
    cl_abap_unit_assert=>assert_equals(
      act = cut->sum_amounts( VALUE #( ( 10 ) ( 25 ) ( -5 ) ( 40 ) ( 30 ) ) )
      exp = 100 ).
  ENDMETHOD.

  METHOD breach_at_fourth.
    " 누적: 10, 35, 30, 70. threshold 50을 처음 넘는 행 = 4.
    cl_abap_unit_assert=>assert_equals(
      act = cut->first_breach_index( amounts   = VALUE #( ( 10 ) ( 25 ) ( -5 ) ( 40 ) ( 30 ) )
                                     threshold = 50 )
      exp = 4 ).
  ENDMETHOD.

  METHOD breach_none.
    " 누적 최대 100 < 1000 -> 한 번도 안 넘으므로 0.
    cl_abap_unit_assert=>assert_equals(
      act = cut->first_breach_index( amounts   = VALUE #( ( 10 ) ( 25 ) ( -5 ) ( 40 ) ( 30 ) )
                                     threshold = 1000 )
      exp = 0 ).
  ENDMETHOD.

  METHOD closing_balance.
    " 100 + 50 - 30 + 20 = 140. 불변식 ASSERT가 통과해야 정상 반환.
    cl_abap_unit_assert=>assert_equals(
      act = cut->post_movements( opening   = 100
                                 movements = VALUE #( ( 50 ) ( -30 ) ( 20 ) ) )
      exp = 140 ).
  ENDMETHOD.

  METHOD right_assert_type.
    " F2/CA1: assert_true( xsdbool( act = exp ) ) 대신 assert_equals를 쓰면
    " 실패 시 act/exp 값이 메시지에 자동 포함돼 디버거 진입 없이 원인을 안다.
    " F3/F4: quit = if_abap_unit_constant=>quit-no 면 실패해도 다음 assert가 계속 실행된다.
    " 여기서는 두 assert 모두 통과하므로 quit 모드와 무관하게 정상 종료한다.
    cl_abap_unit_assert=>assert_equals( act  = cut->safe_divide( dividend = 9 divisor = 3 )
                                        exp  = 3
                                        quit = if_abap_unit_constant=>quit-no ).
    cl_abap_unit_assert=>assert_equals( act  = cut->isqrt( 1 )
                                        exp  = 1
                                        quit = if_abap_unit_constant=>quit-no ).
  ENDMETHOD.
ENDCLASS.
