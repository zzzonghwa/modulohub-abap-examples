REPORT z_modulo_exec01.

" 실행형 프로그램(type 1)의 뼈대 — 리포트 이벤트 블록의 실행 순서를 보인다.
" 실행: SE38/SA38에서 F8, 또는 ADT에서 "Run As -> ABAP Application(Console)".
" (클래스 예제의 F9 클래스런과 달리, 실행형 프로그램은 F8로 실행된다.)
" 출력은 화면 리스트라 manual-report — 각자 환경에서 실행해 확인한다.

DATA run_count TYPE i.

INITIALIZATION.
  " 선택화면을 그리기 전 1회 실행 — 기본값 초기화 등에 쓴다.
  run_count = 0.

START-OF-SELECTION.
  " 주 처리 이벤트 — 데이터 조회·가공의 진입점.
  run_count = run_count + 1.
  WRITE: / 'ModuloHub 실행형 프로그램 뼈대'.
  ULINE.
  WRITE: / 'INITIALIZATION -> START-OF-SELECTION -> END-OF-SELECTION 순으로 실행'.
  WRITE: / 'START-OF-SELECTION 실행 횟수:', run_count.

END-OF-SELECTION.
  " 리스트 처리 종료 — 합계·마무리 출력에 쓴다.
  WRITE: / '완료.'.
