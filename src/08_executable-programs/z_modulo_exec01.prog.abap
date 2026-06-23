REPORT z_modulo_exec01.

" 실행형 프로그램(type 1)의 뼈대 — 리포트 이벤트 블록 7종과 실행 순서를 한 프로그램에 모은다.
" 실행: SE38/SA38에서 F8, 또는 ADT에서 "Run As -> ABAP Application(Console)".
" (클래스 예제의 F9 클래스런과 달리, 실행형 프로그램은 F8로 실행된다.)
" 출력은 화면 리스트라 manual-report — 각자 환경에서 실행해 확인한다.
"
" 이벤트 블록 정리:
"  이벤트 블록은 닫는 키워드가 없다 -> 각 블록 끝을 주석으로 표시한다.
"  이벤트 블록 안 DATA 선언은 사실상 프로그램 전역이다 -> 전역 DATA는 REPORT 직후에 모은다.
"  LOAD-OF-PROGRAM은 프로그램 생성자(내부 세션당 1회).
"  INITIALIZATION은 LOAD-OF-PROGRAM 직후·선택화면 전(초기값은 최초 1회만 유효).
"  AT SELECTION-SCREEN OUTPUT는 화면 송신 직전, AT SELECTION-SCREEN ON은 입력 검증.
"  START-OF-SELECTION은 표준 처리 블록(묵시적 블록 -> 명시적 블록 순).
"  END-OF-SELECTION은 LDB 연결 시에만 유의미(LDB 없으면 실용 의미 없음).
"  실행 순서: LOAD-OF-PROGRAM -> INITIALIZATION -> AT SELECTION-SCREEN OUTPUT ->
"      [사용자 입력] -> AT SELECTION-SCREEN -> START-OF-SELECTION -> END-OF-SELECTION.
"  START-OF-SELECTION 안에 로직을 쌓지 말고 메서드(여기선 lcl_report)를 호출한다(모던 스탠스).
"  PARAMETERS 선언으로 표준 선택화면이 자동 생성된다.

" 이벤트 블록 안 선언은 전역으로 올라가므로, 전역 데이터는 REPORT 직후 한 곳에 모은다.
DATA trace TYPE string_table.

" PARAMETERS 선언으로 표준 선택화면(관행상 번호 1000)이 자동 생성된다.
" 선언은 이벤트 블록보다 앞에 모아 둔다(INITIALIZATION이 초기값을 설정하기 전에 보이도록).
PARAMETERS p_run TYPE string LOWER CASE.

" Clean ABAP: 이벤트 블록은 얇은 진입점으로 두고 로직은 OO 클래스로 위임한다.
CLASS lcl_report DEFINITION CREATE PRIVATE.
  PUBLIC SECTION.
    "! 진입점 — START-OF-SELECTION이 호출하는 단일 메서드.
    CLASS-METHODS run
      IMPORTING events        TYPE string_table
                run_label     TYPE csequence
      RETURNING VALUE(report) TYPE string_table.
ENDCLASS.

CLASS lcl_report IMPLEMENTATION.
  METHOD run.
    " 관측된 이벤트 추적을 사람이 읽을 리포트 라인으로 가공한다(순수 함수 — 화면 미접근).
    report = VALUE #(
      ( |=== { run_label } ===| )
      ( |관측된 이벤트 블록 수: { lines( events ) }| ) ).
    LOOP AT events INTO DATA(event).
      INSERT |{ sy-tabix } { event }| INTO TABLE report.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.

LOAD-OF-PROGRAM.
  " 프로그램 생성자 — 내부 세션이 열릴 때 최초 1회 실행된다.
  " 이 블록은 완전히 실행되어야 하며 중간 탈출(STOP·REJECT)은 런타임 오류를 낸다.
  INSERT `LOAD-OF-PROGRAM (프로그램 생성자, 세션당 1회)` INTO TABLE trace.
  "--- END OF LOAD-OF-PROGRAM ---

INITIALIZATION.
  " LOAD-OF-PROGRAM 직후·선택화면 전. 선택화면 초기값 설정은 최초 1회만 유효하다.
  p_run = `데모 실행`.
  INSERT `INITIALIZATION (선택화면 전, 초기값 1회)` INTO TABLE trace.
  "--- END OF INITIALIZATION ---

AT SELECTION-SCREEN OUTPUT.
  " 화면 송신 직전 — 화면 필드 표시 가공에 쓴다(여기선 추적만).
  INSERT `AT SELECTION-SCREEN OUTPUT (화면 송신 직전)` INTO TABLE trace.
  "--- END OF AT SELECTION-SCREEN OUTPUT ---

AT SELECTION-SCREEN.
  " 사용자 입력 후 검증. 서브스크린 포함 구조에서는 최소 2회 발생한다(여기선 단일 화면).
  INSERT `AT SELECTION-SCREEN (입력 검증)` INTO TABLE trace.
  IF p_run IS INITIAL.
    " 빈 입력이면 화면에 머문다(검증 실패 메시지).
    MESSAGE 'Run label must not be empty' TYPE 'E'.
  ENDIF.
  "--- END OF AT SELECTION-SCREEN ---

START-OF-SELECTION.
  " 표준 처리 블록 — 실제 처리의 진입점.
  " 로직을 직접 쌓지 않고 lcl_report로 위임한다.
  INSERT `START-OF-SELECTION (표준 처리, 메서드 위임)` INTO TABLE trace.
  DATA(report) = lcl_report=>run( events = trace run_label = p_run ).
  LOOP AT report INTO DATA(line).
    WRITE / line.
  ENDLOOP.
  "--- END OF START-OF-SELECTION ---

END-OF-SELECTION.
  " LDB 연결 시에만 유의미. LDB 없는 리포트에선 실용 의미가 없다(대조용 깃발).
  WRITE / `완료 (END-OF-SELECTION — LDB 없으면 실용 의미 없음).`.
  "--- END OF END-OF-SELECTION ---
