REPORT z_modulo_cap02.

" 실전 캡스톤 실행형 — 선택화면 + ALV로 좌석 점유율 분석기를 소비한다.
" 실행: SE38/SA38에서 F8(또는 ADT "Run As -> ABAP Application"). 화면 출력이라 manual-report.
" 캡스톤 핵심: OO 코어(ZCL_MODULO_CAP01_ANALYZER)를 코드 변경 없이 재사용한다. 리포트는
" reader만 인메모리 샘플로 갈아끼워 주입한다(DI) — DB·테이블 없이 자체완결로 F8 실행된다.
"   분석 로직(점유율·역치 필터·정렬)은 단위 테스트가 검증한 클래스를 그대로 호출한다.
" ALV: CL_SALV_TABLE factory + display — SAP GUI에서만 렌더(BTP/콘솔 불가).
"
" 선택화면:
"   p_min  PARAMETERS     — 점유율 역치 %(이 값 이상만 표시). 기본 80.
"   s_carr SELECT-OPTIONS — 항공사 코드 레인지(빈 값이면 전체).

" 항공사 레인지 비교용 대표 필드 — 선언만으로 화면엔 보이지 않는다.
DATA sample_carrid TYPE zmodulo_flight-carrid.

SELECTION-SCREEN BEGIN OF BLOCK filter WITH FRAME TITLE TEXT-001.
PARAMETERS     p_min  TYPE i DEFAULT 80.
SELECT-OPTIONS s_carr FOR sample_carrid.
SELECTION-SCREEN END OF BLOCK filter.

" 인메모리 reader 더블 — 리포트가 분석기에 주입할 샘플 데이터 소스(자체완결, DB 미접촉).
" 같은 ZIF_MODULO_CAP01_READER 계약을 구현하므로 분석기는 출처를 구분하지 않는다(DI의 힘).
CLASS lcl_sample_reader DEFINITION CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES zif_modulo_cap01_reader.
ENDCLASS.

CLASS lcl_sample_reader IMPLEMENTATION.
  METHOD zif_modulo_cap01_reader~read_flights.
    result = VALUE #( ( carrid = 'AA' connid = '0017' seatsmax = 380 seatsocc = 342 )
                      ( carrid = 'AA' connid = '0064' seatsmax = 320 seatsocc = 240 )
                      ( carrid = 'LH' connid = '0400' seatsmax = 280 seatsocc = 280 )
                      ( carrid = 'LH' connid = '2402' seatsmax = 180 seatsocc = 99 )
                      ( carrid = 'UA' connid = '0941' seatsmax = 240 seatsocc = 180 )
                      ( carrid = 'UA' connid = '3517' seatsmax = 300 seatsocc = 285 ) ).
  ENDMETHOD.
ENDCLASS.

START-OF-SELECTION.
  " 캡스톤 재사용: 단위 테스트로 검증된 분석기에 인메모리 reader를 주입한다(코어 불변, reader만 교체).
  DATA(busy) = NEW zcl_modulo_cap01_analyzer( NEW lcl_sample_reader( )
    )->zif_modulo_cap01_analyzer~busy_flights( p_min ).

  " 선택화면 항공사 레인지로 거른다(빈 레인지면 전체 통과).
  DELETE busy WHERE carrid NOT IN s_carr.

  " ALV 표시 — CL_SALV_TABLE factory+display. 정렬·필터·엑셀 내보내기는 ALV가 무료로 준다.
  " factory는 CHANGING 내부 테이블 구조에서 필드 카탈로그를 자동 생성한다(수동 카탈로그 불필요).
  TRY.
      cl_salv_table=>factory( IMPORTING r_salv_table = DATA(alv)
                              CHANGING  t_table      = busy ).
      alv->get_columns( )->set_optimize( abap_true ).
      alv->get_functions( )->set_all( abap_true ).
      alv->display( ).
    CATCH cx_salv_msg INTO DATA(error).
      MESSAGE error->get_text( ) TYPE 'I'.
  ENDTRY.
