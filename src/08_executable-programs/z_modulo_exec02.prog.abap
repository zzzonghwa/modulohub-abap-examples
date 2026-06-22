REPORT z_modulo_exec02.

" 선택화면(selection screen)·리스트 — PARAMETERS·SELECT-OPTIONS·선택화면 이벤트·WRITE 리스트.
" 실행: SE38/SA38에서 F8. 출력은 화면 리스트라 manual-report — 각자 환경에서 확인한다.
" 자기완결을 위해 TABLES(DDIC) 대신 로컬 타입/데이터를 선언한다.

TYPES connection_id TYPE n LENGTH 4.

DATA sample_conn TYPE connection_id.

SELECTION-SCREEN BEGIN OF BLOCK filter WITH FRAME TITLE TEXT-001.
PARAMETERS p_carr TYPE c LENGTH 3 OBLIGATORY.
SELECT-OPTIONS s_conn FOR sample_conn.
PARAMETERS p_min TYPE i DEFAULT 0.
SELECTION-SCREEN END OF BLOCK filter.

AT SELECTION-SCREEN ON p_min.
  " 단일 필드 검증 — 실패 시 사용자는 선택화면에 머문다.
  IF p_min < 0.
    MESSAGE 'Minimum seats must not be negative' TYPE 'E'.
  ENDIF.

START-OF-SELECTION.
  WRITE: / '항공사       :', p_carr.
  WRITE: / '연결편 범위  :', s_conn-low, '~', s_conn-high.
  WRITE: / '최소 좌석    :', p_min.
  ULINE.
  WRITE: / '선택 조건으로 조회를 수행한다(데모: 입력값만 출력).'.
