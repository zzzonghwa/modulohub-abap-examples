"! <p>재고 게이트웨이 계약 — 표준 테스트 더블 프레임워크(CL_ABAP_TESTDOUBLE)의 더블링 대상.</p>
"! <p>CL_ABAP_TESTDOUBLE은 전역(글로벌) 인터페이스만 더블링한다. 그래서 더블을 손으로 짜던
"! TST02(로컬 lif_clock)와 달리, 의존 계약을 전역 인터페이스로 추출한다. 프로덕션에선 재고
"! 테이블·외부 서비스를 치는 느리고 비결정적인 경계를, 테스트에선 프레임워크가 생성한 더블로 대체한다.</p>
INTERFACE zif_modulo_tst07_stock PUBLIC.
  "! 주어진 SKU의 가용 수량(쿼리). 프로덕션에선 재고 테이블 조회.
  "! @parameter sku | 자재 코드
  "! @parameter qty | 가용 수량(미등록이면 0)
  METHODS available
    IMPORTING sku        TYPE string
    RETURNING VALUE(qty) TYPE i.

  "! 주어진 SKU를 수량만큼 예약(커맨드·부수효과). 목(mock) 상호작용 검증의 대상.
  "! @parameter sku | 자재 코드
  "! @parameter qty | 예약 수량
  METHODS reserve
    IMPORTING sku TYPE string
              qty TYPE i.
ENDINTERFACE.
