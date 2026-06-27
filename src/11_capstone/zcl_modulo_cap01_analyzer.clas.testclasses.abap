"! 손으로 짠 reader 더블 — 생성 시 받은 고정 행을 read_flights에서 그대로 돌려준다.
"! DB·프레임워크 없이 분석 로직을 격리한다(책임 분리가 가능케 한 테스트 더블).
CLASS lcl_stub_reader DEFINITION CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES zif_modulo_cap01_reader.
    METHODS constructor IMPORTING flights TYPE zif_modulo_cap01_reader=>flights.
  PRIVATE SECTION.
    DATA flights TYPE zif_modulo_cap01_reader=>flights.
ENDCLASS.

CLASS lcl_stub_reader IMPLEMENTATION.
  METHOD constructor.
    me->flights = flights.
  ENDMETHOD.
  METHOD zif_modulo_cap01_reader~read_flights.
    result = flights.
  ENDMETHOD.
ENDCLASS.


"! 좌석 점유율 분석기 단위 테스트 — 책임 분리의 보상. reader를 손으로 짠 더블(lcl_stub_reader)로
"! 교체해 DB 없이 분석 로직만 격리 검증한다. TDD GIVEN(스텁 행)/WHEN(busy_flights)/THEN(단언).
"! 경계 케이스를 테스트로 못 박는다: 점유율 계산·seatsmax 0(ZERO_DIVIDE 방지)·오버부킹·
"! 빈 입력·역치 미만 제외·역치 경계 포함·점유율 내림차순 정렬.
CLASS ltcl_analyzer DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    "! 주어진 행을 돌려주는 더블 reader를 주입한 분석기를 만든다(테스트 픽스처 팩토리).
    "! @parameter flights | 더블이 돌려줄 항공편 행
    "! @parameter result  | 그 행을 읽는 분석기
    METHODS analyzer_reading
      IMPORTING flights       TYPE zif_modulo_cap01_reader=>flights
      RETURNING VALUE(result) TYPE REF TO zif_modulo_cap01_analyzer.

    METHODS pct_basic               FOR TESTING.
    METHODS pct_rounds_not_truncates FOR TESTING.
    METHODS pct_guards_zero_max     FOR TESTING.
    METHODS pct_allows_overbooking  FOR TESTING.
    METHODS empty_reader_empty      FOR TESTING.
    METHODS filters_below_threshold FOR TESTING.
    METHODS threshold_is_inclusive  FOR TESTING.
    METHODS sorted_by_pct_desc      FOR TESTING.
ENDCLASS.


CLASS ltcl_analyzer IMPLEMENTATION.
  METHOD analyzer_reading.
    result = NEW zcl_modulo_cap01_analyzer( NEW lcl_stub_reader( flights ) ).
  ENDMETHOD.

  METHOD pct_basic.
    " 점유율 = 점유 * 100 / 최대(정수 반올림). 240/320=75, 342/380=90.
    DATA(cut) = analyzer_reading( VALUE #( ) ).
    cl_abap_unit_assert=>assert_equals( act = cut->occupancy_pct( seatsmax = 320 seatsocc = 240 ) exp = 75 ).
    cl_abap_unit_assert=>assert_equals( act = cut->occupancy_pct( seatsmax = 380 seatsocc = 342 ) exp = 90 ).
  ENDMETHOD.

  METHOD pct_rounds_not_truncates.
    " ABAP `/`는 반올림한다(절사 DIV이 아니다). 2/3 = 66.67 -> 67(절사면 66).
    " 나누어떨어지지 않는 케이스 — occupancy_pct가 DIV로 바뀌면 이 단언만 실패해 회귀를 잡는다.
    DATA(cut) = analyzer_reading( VALUE #( ) ).
    cl_abap_unit_assert=>assert_equals( act = cut->occupancy_pct( seatsmax = 3 seatsocc = 2 ) exp = 67 ).
  ENDMETHOD.

  METHOD pct_guards_zero_max.
    " 최대 좌석 0이면 ZERO_DIVIDE 없이 0을 돌려준다(가드 절).
    DATA(cut) = analyzer_reading( VALUE #( ) ).
    cl_abap_unit_assert=>assert_equals( act = cut->occupancy_pct( seatsmax = 0 seatsocc = 50 ) exp = 0 ).
  ENDMETHOD.

  METHOD pct_allows_overbooking.
    " 오버부킹(점유 > 최대): 100%를 넘는 값을 가공 없이 그대로(110/100 = 110%).
    DATA(cut) = analyzer_reading( VALUE #( ) ).
    cl_abap_unit_assert=>assert_equals( act = cut->occupancy_pct( seatsmax = 100 seatsocc = 110 ) exp = 110 ).
  ENDMETHOD.

  METHOD empty_reader_empty.
    " reader가 빈 표면 busy_flights도 빈 표(경계: 데이터 없음).
    DATA(busy) = analyzer_reading( VALUE #( ) )->busy_flights( 80 ).
    cl_abap_unit_assert=>assert_initial( busy ).
  ENDMETHOD.

  METHOD filters_below_threshold.
    " AA0017 90%, UA0941 75%. 역치 80 -> AA만 통과(75%는 미만이라 제외).
    DATA(busy) = analyzer_reading(
      VALUE #( ( carrid = 'AA' connid = '0017' seatsmax = 380 seatsocc = 342 )
               ( carrid = 'UA' connid = '0941' seatsmax = 240 seatsocc = 180 ) ) )->busy_flights( 80 ).
    cl_abap_unit_assert=>assert_equals( act = lines( busy ) exp = 1 ).
    cl_abap_unit_assert=>assert_equals( act = busy[ 1 ]-carrid exp = 'AA' ).
  ENDMETHOD.

  METHOD threshold_is_inclusive.
    " LH0400 정확히 100%. 역치 100 -> 포함(>=, 경계 포함을 못 박는다).
    DATA(busy) = analyzer_reading(
      VALUE #( ( carrid = 'LH' connid = '0400' seatsmax = 280 seatsocc = 280 ) ) )->busy_flights( 100 ).
    cl_abap_unit_assert=>assert_equals( act = lines( busy ) exp = 1 ).
  ENDMETHOD.

  METHOD sorted_by_pct_desc.
    " 90% > 75%: 입력 순서와 무관하게 AA가 먼저 와야 한다(점유율 내림차순). 역치 0으로 둘 다 통과.
    DATA(busy) = analyzer_reading(
      VALUE #( ( carrid = 'UA' connid = '0941' seatsmax = 240 seatsocc = 180 )
               ( carrid = 'AA' connid = '0017' seatsmax = 380 seatsocc = 342 ) ) )->busy_flights( 0 ).
    cl_abap_unit_assert=>assert_equals( act = busy[ 1 ]-carrid exp = 'AA' ).
    cl_abap_unit_assert=>assert_equals( act = busy[ 2 ]-carrid exp = 'UA' ).
  ENDMETHOD.
ENDCLASS.
