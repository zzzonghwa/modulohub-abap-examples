REPORT z_modulo_exec05.

" 클래식 리스트 출력(WRITE) — 역사적 대조.
" 모던 ABAP은 목록을 ALV(CL_SALV_TABLE)로 그린다. WRITE 리스트는 SAP GUI 렌더러에
" 종속적이라 정렬·필터·엑셀 내보내기를 직접 구현해야 하고, 화면·커서 위치에
" 묶여 단위 테스트가 구조적으로 어렵다 — "왜 ALV/SALV로 옮겨갔는가"를 보이는 단원.
"
" 실행: SE38/SA38에서 F8(또는 ADT "Run As -> ABAP Application"). manual-report.
"   7.52+ ADT는 F9로 ABAP Console에 WRITE 결과를 보낼 수 있으나 기초 테스트·로깅 전용이다.
"   BTP ABAP 환경엔 SAP GUI가 없어 executable program 자체가 불가하다 — 온프렘 전용 데모.
"
" 이 리포트가 시연하는 *실행 가능한* WRITE 리스트 구문 폭:
"  WRITE 컬럼 위치     WRITE: / col 'text' — 고정 컬럼 위치로 수작업 포맷(수작업 정렬).
"  FORMAT/색·강조      FORMAT COLOR / INTENSIFIED / INVERSE — 행 단위 시각 속성(GUI 종속).
"  WRITE 옵션          LEFT/RIGHT-JUSTIFIED·NO-ZERO·NO-GAP·NO-SIGN — 필드별 출력 옵션.
"  숫자/통화 편집      WRITE ... DECIMALS·CURRENCY·USING EDIT MASK — 숫자 표시 가공.
"  날짜/시간 편집      WRITE ... DD/MM/YYYY·USING EDIT MASK '__:__:__' — 환경 독립 포맷.
"  레이아웃 제어       ULINE·SKIP·NEW-LINE·WRITE UNDER — 줄·구분선·세로 정렬.
"  text 기호           TEXT-001.. — 번역 가능한 리스트 헤더(하드코딩 회피).
"  집계 라인           소계·합계를 LOOP에서 직접 누적(SALV get_aggregations가 자동화하는 것).
"  대조 요약           각 WHY를 한 줄로 — 같은 표를 ALV(SALV)가 어떻게 무료로 주는가.
" 비실행(SE51 화면 필요) 구문은 코드로 시연 불가 — 주석 대조로만 남긴다:
"  MODULE OUTPUT/INPUT(PBO/PAI)·CALL SCREEN·SY-UCOMM은 SE51 일반 Dynpro 전제라
"  abapGit serialize 포맷 단일 REPORT로는 재현 불가. WHY: 화면 정의와 플로우 로직이 리포지터리
"  객체에 묶여 코드만으로 자체완결이 안 된다 — 이 결합 자체가 클래식 Dynpro 폐기의 근본 이유.

" --- 행 타입 — 항공편 한 건. WRITE 리스트가 한 줄씩 그릴 모델 데이터. ---
TYPES:
  BEGIN OF flight_row,
    carrier  TYPE c LENGTH 3,
    connid   TYPE n LENGTH 4,
    cityfrom TYPE c LENGTH 20,
    seats    TYPE i,
    price    TYPE p LENGTH 9 DECIMALS 2,
    flydate  TYPE d,
  END OF flight_row.
TYPES flight_rows TYPE STANDARD TABLE OF flight_row WITH EMPTY KEY.

" 통화 코드 — WRITE ... CURRENCY가 소수 자릿수를 결정할 때 참조한다.
CONSTANTS report_currency TYPE c LENGTH 5 VALUE 'USD'.

" WRITE 컬럼 위치는 리터럴(12·22·44·54)로 직접 준다 — 클래식 WRITE에서 위치가 변수면 AT가
" 필요하고 길이 `col(len)`은 변수에 붙일 수 없어, 정석은 리터럴이다. 이 흩뿌려진 "매직 넘버"가
" 바로 컬럼 위치 방식의 취약점(컬럼 폭이 바뀌면 전부 수동 수정) — ALV(SALV)는 이걸 자동화한다.

" --- 보고서 로직 — 이벤트 블록은 얇게, 데이터·집계는 OO 클래스로 위임한다(Clean ABAP). ---
" WRITE 출력 자체는 화면 의존이라 클래스 밖(START-OF-SELECTION)에 둔다 — 테스트는 순수 계산부만 건다.
CLASS lcl_report DEFINITION CREATE PRIVATE.
  PUBLIC SECTION.
    "! 데모용 항공편 6건 샘플 데이터(날짜 컬럼 포함).
    CLASS-METHODS sample
      RETURNING VALUE(result) TYPE flight_rows.

    "! 집계: 전체 좌석 합계. SALV get_aggregations(add_aggregation)가 자동화하는 것을 직접 계산한다.
    "! @parameter rows   | 집계 대상 항공편
    "! @parameter result | 좌석 수 총합
    CLASS-METHODS total_seats
      IMPORTING rows          TYPE flight_rows
      RETURNING VALUE(result) TYPE i.

    "! 집계: 전체 가격 합계(소계 라인용). REDUCE 누적기는 price 타입으로 초기화해 절단을 피한다.
    "! @parameter rows   | 집계 대상 항공편
    "! @parameter result | 가격 총합
    CLASS-METHODS total_price
      IMPORTING rows          TYPE flight_rows
      RETURNING VALUE(result) TYPE flight_row-price.

    "! 그룹 소계: 한 항공사의 좌석 합계(carrier 그룹 소계 라인 계산).
    "! @parameter rows    | 집계 대상 항공편
    "! @parameter carrier | 합계를 낼 항공사 코드
    "! @parameter result  | 해당 항공사 좌석 합계
    CLASS-METHODS seats_of_carrier
      IMPORTING rows          TYPE flight_rows
                carrier       TYPE flight_row-carrier
      RETURNING VALUE(result) TYPE i.
ENDCLASS.

CLASS lcl_report IMPLEMENTATION.
  METHOD sample.
    result = VALUE #(
      ( carrier = 'AA' connid = '0017' cityfrom = 'NEW YORK'      seats = 380 price = '899.00' flydate = '20260601' )
      ( carrier = 'AA' connid = '0064' cityfrom = 'SAN FRANCISCO' seats = 320 price = '799.00' flydate = '20260615' )
      ( carrier = 'LH' connid = '0400' cityfrom = 'FRANKFURT'     seats = 280 price = '650.00' flydate = '20260620' )
      ( carrier = 'LH' connid = '2402' cityfrom = 'FRANKFURT'     seats = 180 price = '120.00' flydate = '20260622' )
      ( carrier = 'UA' connid = '0941' cityfrom = 'FRANKFURT'     seats = 240 price = '720.00' flydate = '20260701' )
      ( carrier = 'UA' connid = '3517' cityfrom = 'CHICAGO'       seats = 300 price = '210.00' flydate = '20260705' ) ).
  ENDMETHOD.

  METHOD total_seats.
    " REDUCE로 좌석을 누적한다. SALV였다면 add_aggregation( 'SEATS' ) 한 줄로 끝난다.
    result = REDUCE i( INIT sum = 0 FOR flight IN rows NEXT sum = sum + flight-seats ).
  ENDMETHOD.

  METHOD total_price.
    " 누적기 sum은 price 타입(p DECIMALS 2)으로 초기화 — i로 두면 소수가 절단된다(IT 단원 교훈 재사용).
    result = REDUCE flight_row-price( INIT sum TYPE flight_row-price
                                      FOR flight IN rows
                                      NEXT sum = sum + flight-price ).
  ENDMETHOD.

  METHOD seats_of_carrier.
    " 그룹 소계 = WHERE carrier = 로 거른 뒤 좌석 합. SALV는 sort subtotal + aggregation이 자동 결합한다.
    result = REDUCE i( INIT sum = 0
                       FOR flight IN rows
                       WHERE ( carrier = carrier )
                       NEXT sum = sum + flight-seats ).
  ENDMETHOD.
ENDCLASS.

START-OF-SELECTION.
  " Clean ABAP: 이벤트 블록은 얇게 — 데이터·집계는 lcl_report에 위임하고 여기선 WRITE 포맷만 다룬다.
  DATA(flights) = lcl_report=>sample( ).

  " === text 기호 — 번역 가능한 리스트 헤더(하드코딩 회피). =======================
  " text-001은 .prog.xml TPOOL의 KEY=001과 연결된다(없으면 키 문자열이 그대로 출력).
  WRITE: / TEXT-001.
  ULINE.

  " === 컬럼 위치 + FORMAT + 컬럼 헤더 ====================================
  " FORMAT COLOR COL_HEADING — 헤더 줄에 색/강조 부여(GUI 렌더러 종속, WHY 클라우드 불가).
  FORMAT COLOR COL_HEADING INTENSIFIED ON.
  " "/ col 'text'" — 다음 출력 위치를 고정 컬럼으로 지정하는 수작업 포맷(WHY: 컬럼 폭 변화에 수동 대응).
  WRITE: /  TEXT-002,
         12 TEXT-003,
         22 TEXT-004,
         44 TEXT-005,
         54 TEXT-006.
  FORMAT COLOR OFF INTENSIFIED OFF.
  ULINE.

  " === 본문 행 — 출력 옵션 + 숫자/통화 + 날짜 편집 ============================
  LOOP AT flights INTO DATA(flight).
    " INVERSE: carrier가 'AA'인 행만 반전 강조 — 행별 시각 속성을 코드에서 직접 제어(SALV는 컬러 컬럼/규칙).
    " FORMAT 옵션 값은 변수로 넘긴다(동적 토글) — 피연산자는 숫자 0/1이어야 한다.
    " abap_bool('X'/' ')를 넘기면 'X'를 숫자로 못 바꿔 CONVT_NO_NUMBER 덤프가 난다.
    DATA(highlight) = COND i( WHEN flight-carrier = 'AA' THEN 1 ELSE 0 ).
    FORMAT INVERSE = highlight.

    WRITE: / flight-carrier.
    " NO-ZERO: connid는 N(4) 타입 — 선행 0을 출력에서 제거(여기선 NO-ZERO로 '17' 표시).
    WRITE: 12 flight-connid NO-ZERO.
    " LEFT-JUSTIFIED: 문자 필드를 컬럼 시작에 붙인다.
    WRITE: 22 flight-cityfrom LEFT-JUSTIFIED.
    " 길이 8 + DECIMALS 0: 정수 좌석을 우측 정렬(col(len)은 리터럴에 붙여 쓴다).
    WRITE: 44(8) flight-seats DECIMALS 0 RIGHT-JUSTIFIED.
    " CURRENCY: 통화 코드로 소수 자릿수를 결정해 금액 출력(USD -> 2자리).
    WRITE: 54(12) flight-price CURRENCY report_currency.

    FORMAT INVERSE OFF.
  ENDLOOP.
  ULINE.

  " === 집계 라인 — 그룹 소계 + 총합. SALV add_aggregation/subtotal이 자동화하는 것을 수작업으로. ===
  " carrier 그룹 소계: DISTINCT carrier마다 seats_of_carrier로 합을 낸다(직접 그룹핑 — SALV는 sort subtotal).
  DATA(carriers) = VALUE flight_rows( ).
  LOOP AT flights INTO DATA(grouped).
    " 이미 본 carrier는 건너뛴다(중복 소계 라인 방지).
    CHECK NOT line_exists( carriers[ carrier = grouped-carrier ] ).
    INSERT grouped INTO TABLE carriers.
    DATA(subtotal) = lcl_report=>seats_of_carrier( rows = flights carrier = grouped-carrier ).
    WRITE: / |Subtotal { grouped-carrier }|,
           44(8) subtotal DECIMALS 0 RIGHT-JUSTIFIED.
  ENDLOOP.
  ULINE.

  " 총합 라인 — FORMAT COLOR COL_TOTAL로 강조. 좌석 총합 + 가격 총합.
  FORMAT COLOR COL_TOTAL.
  " WRITE는 함수 호출을 직접 못 받으므로 합계를 먼저 변수로 계산한다.
  DATA(grand_seats) = lcl_report=>total_seats( flights ).
  DATA(grand_price) = lcl_report=>total_price( flights ).
  WRITE: / TEXT-007,
         44(8)  grand_seats DECIMALS 0 RIGHT-JUSTIFIED,
         54(12) grand_price CURRENCY report_currency.
  FORMAT COLOR OFF.

  " === 레이아웃 제어 — SKIP(빈 줄) + 날짜 편집 데모 ==========================
  SKIP.
  " 날짜: 첫 항공편 날짜를 DD/MM/YYYY 포맷으로(환경 사용자 설정과 무관한 고정 포맷).
  DATA(first_date) = VALUE #( flights[ 1 ]-flydate OPTIONAL ).
  WRITE: / TEXT-008, first_date DD/MM/YYYY.
  " USING EDIT MASK: 마스크로 N 필드에 구분 기호를 끼워 출력(connid 4자리를 '00-00' 꼴로).
  DATA(first_connid) = VALUE #( flights[ 1 ]-connid OPTIONAL ).
  WRITE: / TEXT-009, first_connid USING EDIT MASK '__-__'.

  " === 대조 요약 — 위 표를 ALV(SALV)가 어떻게 무료로 주는가. =================
  SKIP.
  ULINE.
  WRITE: / TEXT-010.
  WRITE: / |- { TEXT-011 }|.
  WRITE: / |- { TEXT-012 }|.
  WRITE: / |- { TEXT-013 }|.
  WRITE: / |- { TEXT-014 }|.
  WRITE: / TEXT-015.
