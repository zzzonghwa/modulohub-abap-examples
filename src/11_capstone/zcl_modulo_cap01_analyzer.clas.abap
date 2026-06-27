"! <p>ADT에서 F9(Run As -> ABAP Application)로 데모 출력을, Ctrl+Shift+F10으로 테스트를 본다.</p>
"! <p>실전 캡스톤 — 트랙에서 배운 능력을 하나로 잇는다: 책임 분리(읽기/분석 인터페이스),
"! 생성자 주입(DI), 순수 계산, ABAP Unit(테스트 더블로 DB 격리), Clean ABAP·ATC.</p>
"! <p>도메인: 좌석 점유율 분석기 — 점유율(seatsocc/seatsmax)을 계산해 역치 이상인 편만 돌려준다.</p>
"! <ul>
"! <li>읽기 경계 ZIF_MODULO_CAP01_READER로 DB 접근을 분리 — 분석은 reader 계약에만 의존한다.</li>
"! <li>생성자 주입: reader 미지정 시 ZMODULO_FLIGHT를 읽는 로컬 lcl_db_reader를 기본 사용한다.</li>
"! <li>occupancy_pct·busy_flights는 순수 함수 — 테스트는 더블 reader로 DB 없이 격리 검증한다.</li>
"! </ul>
"! <p>표는 import 직후 비어 있다 — F9는 ensure_demo_data로 시드해 결과를 보인다(결정적 검증은
"! ABAP Unit이 더블로 수행, 실 DB 미접촉). 같은 분석기를 실행형 리포트 Z_MODULO_CAP02가
"! 인메모리 reader로 재사용한다(코어 불변).</p>
CLASS zcl_modulo_cap01_analyzer DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
    INTERFACES zif_modulo_cap01_analyzer.

    "! reader를 생성자 주입한다. 미지정 시 ZMODULO_FLIGHT를 읽는 lcl_db_reader를 기본 사용.
    "! @parameter reader | 항공편 읽기 경계(테스트는 더블, 프로덕션·F9는 DB reader)
    METHODS constructor
      IMPORTING reader TYPE REF TO zif_modulo_cap01_reader OPTIONAL.

  PRIVATE SECTION.
    DATA reader TYPE REF TO zif_modulo_cap01_reader.

    "! 데모 데이터 시드 — 없으면 넣고 있으면 건너뛴다(멱등). F9에서 결과가 보이도록.
    "! (ABAP Unit은 이 메서드 대신 더블 reader로 데이터를 주입하므로 실 DB를 건드리지 않는다.)
    METHODS ensure_demo_data.
ENDCLASS.


CLASS zcl_modulo_cap01_analyzer IMPLEMENTATION.
  METHOD constructor.
    " DI 기본값: 주입이 없으면 실 DB를 읽는 프로덕션 reader를 쓴다(F9 데모용). 테스트는 더블을 넘긴다.
    IF reader IS BOUND.
      me->reader = reader.
    ELSE.
      me->reader = NEW lcl_db_reader( ).
    ENDIF.
  ENDMETHOD.

  METHOD if_oo_adt_classrun~main.
    ensure_demo_data( ).
    DATA(busy) = zif_modulo_cap01_analyzer~busy_flights( 80 ).
    out->write( `=== CAP01 좌석 점유율 분석기 (책임 분리·DI·ABAP Unit) ===` ).
    out->write( |점유율 80% 이상 항공편 { lines( busy ) }건 (ZMODULO_FLIGHT 읽기):| ).
    LOOP AT busy INTO DATA(flight).
      out->write( |{ flight-carrid } { flight-connid }  { flight-seatsocc }/{ flight-seatsmax }  { flight-pct }%| ).
    ENDLOOP.
    out->write( `결정적 검증은 LTCL_ANALYZER (더블 reader로 DB 격리) — Ctrl+Shift+F10.` ).
  ENDMETHOD.

  METHOD zif_modulo_cap01_analyzer~occupancy_pct.
    " 가드 절: 최대 좌석 0이면 0(ZERO_DIVIDE 덤프 방지). 오버부킹은 100% 초과를 그대로 둔다.
    IF seatsmax = 0.
      RETURN.
    ENDIF.
    result = seatsocc * 100 / seatsmax.
  ENDMETHOD.

  METHOD zif_modulo_cap01_analyzer~busy_flights.
    " 1) 읽기 경계에서 행을 받고(데이터 소스 불문) 2) 점유율을 매겨 3) 역치 이상만 거른다.
    LOOP AT reader->read_flights( ) INTO DATA(flight).
      DATA(pct) = zif_modulo_cap01_analyzer~occupancy_pct( seatsmax = flight-seatsmax
                                                           seatsocc = flight-seatsocc ).
      IF pct >= min_pct.
        INSERT VALUE #( carrid   = flight-carrid
                        connid   = flight-connid
                        seatsmax = flight-seatsmax
                        seatsocc = flight-seatsocc
                        pct      = pct ) INTO TABLE result.
      ENDIF.
    ENDLOOP.
    " 점유율 내림차순 — 가장 붐비는 편이 위로.
    SORT result BY pct DESCENDING.
  ENDMETHOD.

  METHOD ensure_demo_data.
    DATA flights TYPE STANDARD TABLE OF zmodulo_flight WITH EMPTY KEY.

    flights = VALUE #( ( carrid = 'AA' connid = '0017' seatsmax = 380 seatsocc = 342 )
                       ( carrid = 'AA' connid = '0064' seatsmax = 320 seatsocc = 240 )
                       ( carrid = 'LH' connid = '0400' seatsmax = 280 seatsocc = 280 )
                       ( carrid = 'UA' connid = '0941' seatsmax = 240 seatsocc = 180 ) ).

    INSERT zmodulo_flight FROM TABLE @flights ACCEPTING DUPLICATE KEYS.
    COMMIT WORK.
  ENDMETHOD.
ENDCLASS.
