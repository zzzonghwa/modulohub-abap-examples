REPORT z_modulo_exec02.

" 선택화면(selection screen)·리스트 출력 — 노트(08-2)의 구문 형태를 한 실행형 리포트에 모은다.
" 실행: SE38/SA38에서 F8, 또는 ADT에서 "Run As -> ABAP Application". 출력은 화면 리스트라
" manual-report — 각자 환경에서 F8로 실행해 확인한다. (클래스 예제의 F9 클래스런과 다르다.)
" 자기완결을 위해 TABLES(DDIC) 대신 로컬 타입/데이터로 항공편 샘플을 구성한다.
"
" 노트(08-2) 소절 대응:
"  P    PARAMETERS — 타입·길이, OBLIGATORY, DEFAULT, AS CHECKBOX, RADIOBUTTON GROUP, LOWER CASE.
"  SO   SELECT-OPTIONS — 레인지(SIGN/OPTION/LOW/HIGH), WHERE ... IN seltab, NO-INTERVALS.
"  SS   SELECTION-SCREEN — BLOCK WITH FRAME TITLE, COMMENT, SKIP, ULINE, BEGIN OF LINE.
"  ASS  AT SELECTION-SCREEN — ON para(단일), ON BLOCK(블록 일괄), OUTPUT(송신 직전).
"  EV   이벤트 흐름 — INITIALIZATION -> 선택화면 -> START-OF-SELECTION(메서드 위임).
"  LIST 클래식 WRITE 리스트(레거시) — 프로덕션은 CL_SALV_TABLE 권장(EXEC03 참조).

" 행 타입 — 항공편 한 건. 선택화면 입력으로 필터링할 모델 데이터.
TYPES:
  BEGIN OF flight_row,
    carrier TYPE c LENGTH 3,
    connid  TYPE n LENGTH 4,
    seats   TYPE i,
  END OF flight_row.
TYPES flight_rows TYPE STANDARD TABLE OF flight_row WITH EMPTY KEY.

" connid 레인지(SELECT-OPTIONS) 비교용 대표 필드. 선언만으로 화면엔 보이지 않는다.
DATA sample_connid TYPE flight_row-connid.

" --- 선택화면 선언 -------------------------------------------------------------
" SS-02: WITH FRAME TITLE — 프레임과 제목(text-001)으로 입력 요소를 논리 그룹으로 묶는다.
SELECTION-SCREEN BEGIN OF BLOCK filter WITH FRAME TITLE TEXT-001.
" P-04: OBLIGATORY(필수). P-03: TYPE c LENGTH 3(제네릭 길이 타입은 길이 지정 가능).
PARAMETERS p_carr TYPE c LENGTH 3 OBLIGATORY.
" SO-01/SO-03: connid 레인지. WHERE ... IN @s_conn로 SQL과 직접 연동된다.
SELECT-OPTIONS s_conn FOR sample_connid.
" P-04: DEFAULT(초기값). AT SELECTION-SCREEN ON p_min에서 음수 검증한다.
PARAMETERS p_min TYPE i DEFAULT 100.
SELECTION-SCREEN END OF BLOCK filter.

" SS-02/SS-05: 두 번째 블록 — 정렬 방식 선택. COMMENT로 라벨, RADIOBUTTON GROUP으로 배타 선택.
SELECTION-SCREEN BEGIN OF BLOCK options WITH FRAME TITLE TEXT-002.
" SS-05: BEGIN OF LINE + COMMENT — 한 줄에 주석과 입력 요소를 함께 배치한다.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(20) TEXT-003.
" P-04: RADIOBUTTON GROUP sort — 그룹 내 단 하나만 선택된다(연결편순/좌석순).
PARAMETERS p_bycon RADIOBUTTON GROUP sort DEFAULT 'X'.
SELECTION-SCREEN COMMENT 30(12) TEXT-004.
PARAMETERS p_bysea RADIOBUTTON GROUP sort.
SELECTION-SCREEN COMMENT 50(12) TEXT-005.
SELECTION-SCREEN END OF LINE.
" SS-07: SKIP — 공백 줄 1개. P-04: AS CHECKBOX — 내부 타입 c length 1('X'/'').
SELECTION-SCREEN SKIP.
PARAMETERS p_desc AS CHECKBOX DEFAULT 'X'.
SELECTION-SCREEN END OF BLOCK options.

" --- 로직: 선택화면 입력을 받아 순수 함수로 가공(테스트 가능 영역) -----------------
" C18/EV-03/CleanABAP: 이벤트 블록은 얇은 진입점으로 두고 로직은 OO 클래스로 위임한다.
CLASS lcl_report DEFINITION CREATE PRIVATE.
  PUBLIC SECTION.
    "! 정렬 기준 — 라디오 버튼 그룹과 대응.
    TYPES sort_key TYPE c LENGTH 1.
    CONSTANTS:
      BEGIN OF sort_by,
        connid TYPE sort_key VALUE 'C',
        seats  TYPE sort_key VALUE 'S',
      END OF sort_by.

    "! 선택화면 입력을 모은 필터 조건. 이벤트 블록에서 채워 run으로 넘긴다.
    TYPES:
      BEGIN OF filter,
        carrier    TYPE flight_row-carrier,
        connid     TYPE RANGE OF flight_row-connid,
        min_seats  TYPE i,
        sort       TYPE sort_key,
        descending TYPE abap_bool,
      END OF filter.

    "! 진입점 — START-OF-SELECTION이 호출하는 단일 메서드. 필터 적용 + 정렬 결과를 돌려준다.
    "! @parameter conditions | 선택화면에서 모은 필터 조건
    "! @parameter source     | 조회 대상 항공편(테스트는 임의 데이터 주입, 운영은 sample)
    "! @parameter result     | 필터·정렬을 거친 항공편
    CLASS-METHODS run
      IMPORTING conditions    TYPE filter
                source        TYPE flight_rows
      RETURNING VALUE(result) TYPE flight_rows.

    "! 데모용 항공편 6건 샘플 데이터(EXEC03/SQL02와 동일 시드).
    CLASS-METHODS sample
      RETURNING VALUE(result) TYPE flight_rows.

    "! P-01 검증: 항공사 코드는 비어 있으면 안 된다(AT SELECTION-SCREEN에서 호출).
    "! @parameter carrier | 입력한 항공사 코드
    "! @parameter result  | 유효하면 abap_true
    CLASS-METHODS is_carrier_valid
      IMPORTING carrier       TYPE csequence
      RETURNING VALUE(result) TYPE abap_bool.

  PRIVATE SECTION.
    "! WHERE ... IN @range + 비교 필터를 ABAP SQL로 적용한다(@source는 단일 itab).
    CLASS-METHODS apply_filter
      IMPORTING conditions    TYPE filter
                source        TYPE flight_rows
      RETURNING VALUE(result) TYPE flight_rows.

    "! 선택한 키로 정렬한다(연결편순/좌석순, 오름/내림). 동점은 connid를 2차 키로.
    CLASS-METHODS sort_rows
      IMPORTING conditions TYPE filter
      CHANGING  rows       TYPE flight_rows.
ENDCLASS.

CLASS lcl_report IMPLEMENTATION.
  METHOD run.
    " 1) 필터 적용 -> 2) 정렬. 둘 다 화면을 만지지 않는 순수 변환이라 단위 테스트가 쉽다.
    result = apply_filter( conditions = conditions source = source ).
    sort_rows( EXPORTING conditions = conditions CHANGING rows = result ).
  ENDMETHOD.

  METHOD apply_filter.
    " @source가 FROM에 쓰이나 정적분석이 못 봄 -> ##NEEDED로 false positive 억제.
    DATA(rows) = source ##NEEDED.
    " SO-03: WHERE ... IN @range. 빈 레인지는 조건 무시(전체 통과)로 동작한다.
    SELECT FROM @rows AS flight
      FIELDS carrier, connid, seats
      WHERE carrier  = @conditions-carrier
        AND connid  IN @conditions-connid
        AND seats   >= @conditions-min_seats
      INTO TABLE @result.
  ENDMETHOD.

  METHOD sort_rows.
    " 라디오 버튼 선택을 정렬 키로 환산한다. 동점 시 connid로 결정적 순서를 보장한다.
    IF conditions-sort = sort_by-seats.
      IF conditions-descending = abap_true.
        SORT rows BY seats DESCENDING connid ASCENDING.
      ELSE.
        SORT rows BY seats ASCENDING connid ASCENDING.
      ENDIF.
    ELSE.
      IF conditions-descending = abap_true.
        SORT rows BY connid DESCENDING.
      ELSE.
        SORT rows BY connid ASCENDING.
      ENDIF.
    ENDIF.
  ENDMETHOD.

  METHOD is_carrier_valid.
    result = xsdbool( carrier IS NOT INITIAL ).
  ENDMETHOD.

  METHOD sample.
    result = VALUE #(
      ( carrier = 'AA' connid = '0017' seats = 380 )
      ( carrier = 'AA' connid = '0064' seats = 320 )
      ( carrier = 'LH' connid = '0400' seats = 280 )
      ( carrier = 'LH' connid = '2402' seats = 180 )
      ( carrier = 'UA' connid = '0941' seats = 240 )
      ( carrier = 'UA' connid = '3517' seats = 300 ) ).
  ENDMETHOD.
ENDCLASS.

" --- 이벤트 블록 ---------------------------------------------------------------
INITIALIZATION.
  " EV-02: LOAD-OF-PROGRAM 직후·선택화면 전. 선택화면 초기값은 최초 1회만 유효하다.
  p_carr = 'AA'.

AT SELECTION-SCREEN OUTPUT.
  " ASS/EV: 화면 송신 직전(PBO 상당). 여기서 화면 요소를 동적 수정할 수 있다(여기선 미사용).

AT SELECTION-SCREEN ON p_min.
  " ASS-02: 단일 필드 검증 — 실패 시 타입 E 메시지로 사용자는 선택화면에 머문다.
  IF p_min < 0.
    MESSAGE 'Minimum seats must not be negative' TYPE 'E'.
  ENDIF.

AT SELECTION-SCREEN ON BLOCK filter.
  " SS-04/ASS-02: 블록 내 입력을 한꺼번에 검증한다.
  IF lcl_report=>is_carrier_valid( p_carr ) = abap_false.
    MESSAGE 'Carrier must not be empty' TYPE 'E'.
  ENDIF.

START-OF-SELECTION.
  " EV-03/C18: 로직을 직접 쌓지 않고 lcl_report로 위임한다(테스트 가능성 확보).
  " s_conn(RSDSSELOPT 기반)의 4필드를 filter의 connid 레인지로 옮긴다(LOW/HIGH 폭이 달라 행별 변환).
  DATA connid_range TYPE RANGE OF flight_row-connid.
  connid_range = VALUE #( FOR line IN s_conn[]
    ( sign   = line-sign
      option = line-option
      low    = CONV flight_row-connid( line-low )
      high   = CONV flight_row-connid( line-high ) ) ).

  DATA(conditions) = VALUE lcl_report=>filter(
    carrier    = p_carr
    connid     = connid_range
    min_seats  = p_min
    sort       = COND #( WHEN p_bysea = abap_true THEN lcl_report=>sort_by-seats
                         WHEN p_bycon = abap_true THEN lcl_report=>sort_by-connid
                         ELSE lcl_report=>sort_by-connid )
    descending = p_desc ).

  DATA(matches) = lcl_report=>run(
    conditions = conditions
    source     = lcl_report=>sample( ) ).

  " LIST-01/LIST-08: 클래식 WRITE 리스트는 레거시 분류다 — 프로덕션은 CL_SALV_TABLE(EXEC03).
  " 여기서는 선택화면 입력이 결과에 어떻게 반영되는지 보이기 위한 데모 출력이다.
  WRITE: / 'Carrier  :', p_carr.
  WRITE: / 'Connid   :', s_conn-low, '~', s_conn-high.
  WRITE: / 'Min seats:', p_min.
  " 클래식 WRITE 출력 인자엔 생성자식(COND)을 직접 못 쓴다 — 데이터 오브젝트로 분리한다.
  DATA(sort_label) = COND string( WHEN p_bysea = 'X' THEN `seats` ELSE `connid` ).
  DATA(dir_label) = COND string( WHEN p_desc = 'X' THEN `DESC` ELSE `ASC` ).
  WRITE: / 'Sort     :', sort_label, dir_label.
  ULINE.

  WRITE: / 'CARR', 'CONNID', 'SEATS'.
  ULINE.
  LOOP AT matches INTO DATA(flight).
    WRITE: / flight-carrier, flight-connid, flight-seats.
  ENDLOOP.
  ULINE.
  WRITE: / 'Rows:', lines( matches ).
