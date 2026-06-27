"! 표준 테스트 더블 프레임워크 실증 — CL_ABAP_TESTDOUBLE이 전역 인터페이스
"! ZIF_MODULO_TST07_STOCK로부터 더블을 자동 생성한다. 손으로 짠 스텁/스파이(TST02) 없이
"! returning(스텁)·입력별 구성·and_expect/verify_expectations(목)을 '구성'으로 표현한다.
"! 패턴: configure_call로 동작을 심고 더블 메서드를 1회 호출해 그 구성을 '기록'한 뒤, CUT를
"! 실행하고, 목은 verify_expectations로 호출 횟수·인자를 자동 검증한다.
CLASS ltcl_order_service DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA stock TYPE REF TO zif_modulo_tst07_stock.
    DATA cut   TYPE REF TO lcl_order_service.
    METHODS setup.
    METHODS reserves_when_in_stock   FOR TESTING.
    METHODS skips_reserve_when_short FOR TESTING.
    METHODS stubs_per_sku            FOR TESTING.
ENDCLASS.


CLASS ltcl_order_service IMPLEMENTATION.
  METHOD setup.
    " 픽스처: 매 테스트 전 전역 인터페이스로부터 더블을 새로 만들고 CUT에 주입한다.
    stock ?= cl_abap_testdouble=>create( 'ZIF_MODULO_TST07_STOCK' ).
    cut = NEW lcl_order_service( stock ).
  ENDMETHOD.

  METHOD reserves_when_in_stock.
    " given(스텁): 어떤 SKU든 가용 10을 돌려주게 심는다(returning + ignore_all_parameters).
    cl_abap_testdouble=>configure_call( stock )->returning( 10 )->ignore_all_parameters( ).
    stock->available( `` ).
    " given(목): reserve가 정확히 1회, 주어진 인자로 불릴 것을 기대한다.
    cl_abap_testdouble=>configure_call( stock )->and_expect( )->is_called_times( 1 ).
    stock->reserve( sku = `SKU-1` qty = 3 ).

    " when/then: 충분한 재고에서 주문 -> 예약 수량 반환.
    cl_abap_unit_assert=>assert_equals( act = cut->place( sku = `SKU-1` qty = 3 ) exp = 3 ).
    " 상호작용 자동 검증: reserve 호출 횟수·인자가 기대와 일치하는지 프레임워크가 단언한다.
    cl_abap_testdouble=>verify_expectations( stock ).
  ENDMETHOD.

  METHOD skips_reserve_when_short.
    " given(스텁): 가용 2. given(목): reserve는 절대 호출되면 안 된다.
    cl_abap_testdouble=>configure_call( stock )->returning( 2 )->ignore_all_parameters( ).
    stock->available( `` ).
    cl_abap_testdouble=>configure_call( stock )->and_expect( )->is_never_called( ).
    stock->reserve( sku = `` qty = 0 ).

    " when/then: 재고 부족에서 주문 -> 0 반환, reserve 미호출.
    cl_abap_unit_assert=>assert_equals( act = cut->place( sku = `SKU-1` qty = 5 ) exp = 0 ).
    cl_abap_testdouble=>verify_expectations( stock ).
  ENDMETHOD.

  METHOD stubs_per_sku.
    " 입력별 스텁: 같은 메서드라도 인자에 따라 다른 값을 돌려주도록 더블을 구성한다.
    cl_abap_testdouble=>configure_call( stock )->returning( 4 ).
    stock->available( `SKU-A` ).
    cl_abap_testdouble=>configure_call( stock )->returning( 0 ).
    stock->available( `SKU-B` ).

    " then: A는 충분(4>=2)->예약 2, B는 부족(0<1)->0. reserve는 기대 미설정이라 자유 통과.
    cl_abap_unit_assert=>assert_equals( act = cut->place( sku = `SKU-A` qty = 2 ) exp = 2 ).
    cl_abap_unit_assert=>assert_equals( act = cut->place( sku = `SKU-B` qty = 1 ) exp = 0 ).
  ENDMETHOD.
ENDCLASS.
