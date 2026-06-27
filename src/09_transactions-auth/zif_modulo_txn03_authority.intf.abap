"! <p>권한 체크 dependency 추상화 — 전역 인터페이스.</p>
"! <p>AUTHORITY-CHECK는 현재 로그온 사용자에 의존해 단위 테스트에서 결정적이지 않다. 이 계약 뒤로
"! 숨겨, 테스트는 인메모리 buffer(test double)로 교체한다. 전역 인터페이스인 이유: 글로벌 클래스의
"! 공개 생성자 시그니처가 이 타입을 참조하므로, 로컬 타입으로는 클래스풀 밖에서 안 보여 활성화되지 않는다.</p>
INTERFACE zif_modulo_txn03_authority PUBLIC.
  "! 체크할 field-value 쌍. value가 비어 있고 dummy=abap_true면 DUMMY로 간주.
  TYPES:
    BEGIN OF check_field,
      name  TYPE string,
      value TYPE string,
      dummy TYPE abap_bool,
    END OF check_field.
  TYPES check_fields TYPE STANDARD TABLE OF check_field WITH EMPTY KEY.

  "! AUTHORITY-CHECK 한 번에 대응. sy-subrc 호환 코드를 돌려준다.
  "! @parameter object | authorization object 이름(대문자)
  "! @parameter fields | 체크할 field-value 쌍 목록(최대 10개)
  "! @parameter user   | FOR USER 대상(비우면 현재 사용자)
  "! @parameter result | sy-subrc 호환: 0 통과 · 4 값불일치/필드오류 · 12 권한없음 · 40 유저무효
  METHODS check
    IMPORTING object        TYPE string
              fields        TYPE check_fields
              user          TYPE string OPTIONAL
    RETURNING VALUE(result) TYPE i.
ENDINTERFACE.
