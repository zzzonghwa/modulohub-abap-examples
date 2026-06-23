"! <p>ADT에서 F9(Run As -> ABAP Application)로 바로 실행해 데모 출력을 본다.</p>
"! <p>ATC(ABAP Test Cockpit)·정적 품질 — 노트(07-3)의 구문·패턴을 자체완결로 시연한다.</p>
"! <p>ATC는 활성화 코드를 체크 변형(check variant)으로 정적 검사하며 Code Inspector와 동일 엔진이다.</p>
"! <p>정적 도구 자체는 SAP 시스템에서만 동작하므로, 여기서는 ATC가 *코드에 요구하는* 실행 가능한</p>
"! <p>형태(억제 프라그마·의사주석·ATC 친화 패턴·finding 분류 로직)를 메서드로 시연한다.</p>
"! <ul>
"! <li>A. priority 1/2/3 분류(W-02): finding 우선순위 -> 운반 게이트 동작.</li>
"! <li>B. missing-WHERE(L-A1): WHERE 있는 SELECT가 prio2를 피한다.</li>
"! <li>C. ORDER BY 없는 INDEX 읽기(L-A2): 정렬 후 첫 행 접근이 prio3을 피한다.</li>
"! <li>D. ##NEEDED(L-06/G-03)·E. ##NO_HANDLER(G-04)·F. ##NO_TEXT/"#EC(L-18) 억제.</li>
"! <li>G. baseline exempt vs suppress(L-BL1)·H. exemption 반패턴(L-EX3)·I. 억제엔 이유주석(L-EX2).</li>
"! <li>J. 커스텀 체크 토큰 스캔(L-14)·K. INFORM kind note/error(L-14a)·카테고리 position(L-11).</li>
"! </ul>
CLASS zcl_modulo_tst03_atc DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

    "! 기술 라벨(번역 대상 아님) — ##NO_TEXT로 "텍스트 기호로 빼지 않음"을 명시한다(F·L-18).
    CONSTANTS c_unknown TYPE string VALUE 'UNKNOWN' ##NO_TEXT.

    "! 항공편 한 건. WHERE·정렬 데모(B·C)의 공통 행 타입.
    TYPES:
      BEGIN OF flight,
        carrier TYPE c LENGTH 3,
        connid  TYPE n LENGTH 4,
        seats   TYPE i,
      END OF flight.
    TYPES flights TYPE STANDARD TABLE OF flight WITH EMPTY KEY.

    "! A. 심각도 코드 -> 라벨(W-02). 중첩 IF 대신 SWITCH로 분기(ATC "복잡도" finding 회피).
    "! @parameter code   | 1=error, 2=warning, 3=info
    "! @parameter result | 라벨, 미정의면 c_unknown
    METHODS severity_label
      IMPORTING code          TYPE i
      RETURNING VALUE(result) TYPE string.

    "! A. priority -> 운반(transport) 게이트 동작(W-02·W-03). 1·2는 차단, 3은 알림만.
    "! @parameter priority | ATC finding 우선순위 1/2/3
    "! @parameter result   | 'BLOCK'(1·2) 또는 'NOTIFY'(3), 범위 밖은 c_unknown
    METHODS transport_gate
      IMPORTING priority      TYPE i
      RETURNING VALUE(result) TYPE string.

    "! B. missing-WHERE(L-A1) 회피 — WHERE 있는 SELECT는 prio2 finding을 만들지 않는다.
    "! @parameter min_seats | 좌석 하한
    "! @parameter result    | 좌석이 하한 이상인 행 수
    METHODS count_min_seats
      IMPORTING min_seats     TYPE i
      RETURNING VALUE(result) TYPE i.

    "! C. ORDER BY 없는 INDEX 1 읽기(L-A2) 회피 — 정렬을 명시해 결정적 첫 행을 얻는다.
    "! @parameter result | 좌석 최다 1편의 connid(동점은 connid 2차 키)
    METHODS top_connid_by_seats
      RETURNING VALUE(result) TYPE flight-connid.

    "! D·E. 문자열이 정수로 변환 가능한지. ##NEEDED(변환 결과 미사용)·##NO_HANDLER(의도된 빈 CATCH).
    "! @parameter text   | 검사할 문자열
    "! @parameter result | 숫자면 abap_true
    METHODS is_numeric
      IMPORTING text          TYPE string
      RETURNING VALUE(result) TYPE abap_bool.

    "! G. baseline 추가 모드(L-BL1) — exempt(승인 워크플로) vs suppress(단순 억제).
    "! @parameter exempt | abap_true면 승인형, abap_false면 단순 억제
    "! @parameter result | 'EXEMPT' 또는 'SUPPRESS'
    METHODS baseline_mode
      IMPORTING exempt        TYPE abap_bool
      RETURNING VALUE(result) TYPE string.

    "! H. exemption 신청 반패턴(L-EX3) — "복잡/단순해서 면제"는 거부한다.
    "! @parameter reason | exemption 사유 코드: TOO_COMPLEX·TOO_SIMPLE·FALSE_POSITIVE
    "! @parameter result | 정당한 사유면 abap_true(FALSE_POSITIVE만 허용)
    METHODS exemption_valid
      IMPORTING reason        TYPE string
      RETURNING VALUE(result) TYPE abap_bool.

    "! I. 억제 메타데이터(L-EX2) — pragma/의사주석 억제엔 같은 줄 이유 주석이 필수.
    "! @parameter pragma | 억제 토큰(예: '##NO_HANDLER')
    "! @parameter reason | 같은 줄 이유 주석 텍스트(빈 값이면 부적합)
    "! @parameter result | 'OK <pragma>: <reason>' 또는 'REJECT <pragma>: missing reason'
    METHODS suppression_note
      IMPORTING pragma        TYPE string
                reason        TYPE string
      RETURNING VALUE(result) TYPE string.

    "! J. 커스텀 체크 토큰 스캔(L-14) — 한 statement의 token 중 특정 키워드 출현 횟수.
    "! ref_scan->tokens 구조를 단순화: statement를 공백 분할한 token 테이블에서 키워드를 센다.
    "! @parameter statement | 검사할 ABAP 구문 텍스트(공백 구분)
    "! @parameter keyword   | 찾을 키워드(대문자 비교)
    "! @parameter result    | statement 안 keyword 토큰 개수
    METHODS count_tokens
      IMPORTING statement     TYPE string
                keyword       TYPE string
      RETURNING VALUE(result) TYPE i.

    "! K. INFORM kind(L-14a) — finding을 note(정보) 또는 error(적색)로 분류.
    "! @parameter is_error | abap_true면 error 열, abap_false면 information 열
    "! @parameter result   | 'ERROR' 또는 'NOTE'
    METHODS inform_kind
      IMPORTING is_error      TYPE abap_bool
      RETURNING VALUE(result) TYPE string.

    "! L-11. 커스텀 카테고리 목록 위치 — position '001'은 맨 위, '999'는 맨 아래.
    "! @parameter position | 카테고리 position 문자열('001'..'999')
    "! @parameter result   | 'TOP'('001')·'BOTTOM'('999')·'MIDDLE'(그 외)
    METHODS category_rank
      IMPORTING position      TYPE string
      RETURNING VALUE(result) TYPE string.

  PRIVATE SECTION.
    "! 데모용 항공편 6건 샘플 데이터(B·C 공용).
    METHODS sample
      RETURNING VALUE(result) TYPE flights.
ENDCLASS.


CLASS zcl_modulo_tst03_atc IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    out->write( `=== TST03 ATC·정적 품질 ===` ).
    out->write( |severity_label(1)        = { severity_label( 1 ) }| ).
    out->write( |severity_label(9)        = { severity_label( 9 ) }| ).
    out->write( |transport_gate(2)        = { transport_gate( 2 ) }| ).
    out->write( |transport_gate(3)        = { transport_gate( 3 ) }| ).
    out->write( |count_min_seats(300)     = { count_min_seats( 300 ) } (WHERE -> prio2 회피)| ).
    out->write( |top_connid_by_seats      = { top_connid_by_seats( ) } (ORDER BY -> prio3 회피)| ).
    out->write( |is_numeric('42')         = { is_numeric( `42` ) }| ).
    out->write( |is_numeric('abc')        = { is_numeric( `abc` ) }| ).
    out->write( |baseline_mode(X)         = { baseline_mode( abap_true ) }| ).
    out->write( |exemption_valid(SIMPLE)  = { exemption_valid( `TOO_SIMPLE` ) }| ).
    out->write( |suppression_note         = { suppression_note( pragma = `##NO_HANDLER` reason = `숫자 아님` ) }| ).
    out->write( |count_tokens(WHERE x1)    = | &&
                |{ count_tokens( statement = `SELECT SINGLE FROM t WHERE k = @k` keyword = `WHERE` ) }| ).
    out->write( |inform_kind(X)           = { inform_kind( abap_true ) }| ).
    out->write( |category_rank('001')     = { category_rank( `001` ) }| ).
  ENDMETHOD.

  METHOD severity_label.
    result = SWITCH string( code
                            WHEN 1 THEN `ERROR`
                            WHEN 2 THEN `WARNING`
                            WHEN 3 THEN `INFO`
                            ELSE c_unknown ).
  ENDMETHOD.

  METHOD transport_gate.
    " prio1·2는 운반 릴리스를 차단(BLOCK), prio3은 알림(NOTIFY)만 — W-03.
    result = SWITCH string( priority
                            WHEN 1 THEN `BLOCK`
                            WHEN 2 THEN `BLOCK`
                            WHEN 3 THEN `NOTIFY`
                            ELSE c_unknown ).
  ENDMETHOD.

  METHOD count_min_seats.
    " WHERE를 붙여 missing-WHERE(prio2) finding을 만들지 않는다(L-A1).
    " @source가 FROM에 쓰이나 정적분석이 못 봄 -> ##NEEDED로 false positive 억제.
    DATA(source) = sample( ) ##NEEDED.
    SELECT COUNT(*)
      FROM @source AS flight
      WHERE seats >= @min_seats
      INTO @DATA(matches).
    result = matches.
  ENDMETHOD.

  METHOD top_connid_by_seats.
    " ORDER BY를 명시해 "ORDER BY 없는 INDEX 1 읽기"(prio3) finding을 피한다(L-A2).
    " 동점 시 결정적 결과를 위해 connid를 2차 정렬 키로 둔다.
    DATA(source) = sample( ) ##NEEDED.
    SELECT connid
      FROM @source AS flight
      ORDER BY seats DESCENDING, connid ASCENDING
      INTO TABLE @DATA(connids)
      UP TO 1 ROWS.
    result = COND #( WHEN connids IS NOT INITIAL THEN connids[ 1 ]-connid ).
  ENDMETHOD.

  METHOD is_numeric.
    TRY.
        " 변환 성공 여부만 보고 결과값은 안 씀 -> ##NEEDED(L-06/G-03).
        DATA(parsed) = CONV i( text ) ##NEEDED.
        result = abap_true.
      CATCH cx_sy_conversion_error ##NO_HANDLER.
        " 변환 실패 = 숫자 아님. result는 초기값(abap_false) 유지 — 의도된 빈 CATCH(G-04).
    ENDTRY.
  ENDMETHOD.

  METHOD baseline_mode.
    " exempt: quality expert 승인 워크플로. suppress: 승인 없이 결과에서 제거(L-BL1).
    result = COND #( WHEN exempt = abap_true THEN `EXEMPT` ELSE `SUPPRESS` ).
  ENDMETHOD.

  METHOD exemption_valid.
    " "너무 복잡/단순해서"는 사유가 될 수 없다 — false positive만 정당하다(L-EX3·L-EX2).
    result = xsdbool( reason = `FALSE_POSITIVE` ).
  ENDMETHOD.

  METHOD suppression_note.
    " 억제엔 같은 줄 이유 주석이 필수 — 주석을 못 달면 false positive가 아니다(L-EX2).
    result = COND #( WHEN reason IS NOT INITIAL
                     THEN |OK { pragma }: { reason }|
                     ELSE |REJECT { pragma }: missing reason| ).
  ENDMETHOD.

  METHOD count_tokens.
    " RUN 메서드의 ref_scan->tokens 구조를 단순화: 구문을 token으로 분해해 키워드를 센다(L-14).
    SPLIT to_upper( statement ) AT ` ` INTO TABLE DATA(tokens).
    result = REDUCE i( INIT hits = 0
                       FOR token IN tokens
                       NEXT hits = COND #( WHEN token = to_upper( keyword )
                                           THEN hits + 1
                                           ELSE hits ) ).
  ENDMETHOD.

  METHOD inform_kind.
    " INFORM의 p_kind = c_error(적색) vs c_note(정보 열) — L-14a.
    result = COND #( WHEN is_error = abap_true THEN `ERROR` ELSE `NOTE` ).
  ENDMETHOD.

  METHOD category_rank.
    " position '001' 맨 위(Code Pal), '999' 맨 아래(ABAP Open Checks) — L-11.
    result = SWITCH string( position
                            WHEN `001` THEN `TOP`
                            WHEN `999` THEN `BOTTOM`
                            ELSE `MIDDLE` ).
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
