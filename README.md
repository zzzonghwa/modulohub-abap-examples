# ModuloHub ABAP Examples

[ModuloHub](https://modulohub.com) ABAP 학습 트랙의 **실행 가능한 ABAP 예제** 모음입니다. 각 예제는 SAP S/4HANA(ABAP Platform 7.54+)에서 컴파일·실행·ATC 검사를 통과하도록 작성했습니다.

## 사용법 (abapGit import)

1. ABAP 시스템에 [abapGit](https://abapgit.org)을 설치합니다.
2. abapGit에서 "Online" → 이 레포 URL(`https://github.com/zzzonghwa/modulohub-abap-examples`)로 새 저장소를 만들고, 전용 패키지(예: `$MODULOHUB_ABAP` 로컬 또는 `ZMODULOHUB_ABAP` 운반)로 pull합니다.
3. `src/<단원>/` 의 클래스를 활성화합니다.

## 예제 실행·학습

- **바로 실행 (ADT)**: 모든 예제 클래스는 `IF_OO_ADT_CLASSRUN`을 구현합니다. ADT(Eclipse)에서 클래스를 열고 **F9**(Run As → ABAP Application)를 누르면 `main`이 각 메서드를 호출해 콘솔에 결과를 출력합니다 — 별도 리포트·드라이버 없이 즉시 체험할 수 있습니다.
- **테스트 확인**: 각 클래스의 `LTCL_*` 테스트 클래스를 ADT에서 `Ctrl+Shift+F10`(Run As → ABAP Unit Test)로 실행합니다.
- **`/deps` 폴더**: `IF_OO_ADT_CLASSRUN`·`IF_OO_ADT_OUTPUT`의 **abaplint 전용 스텁**입니다. abapGit `STARTING_FOLDER`(`/src/`) 밖이라 SAP에 import되지 않으며(표준 객체와 무관), 로컬 정적 검사 시 인터페이스 해석에만 쓰입니다.

## 커리큘럼 로드맵

전체 커리큘럼(12섹션·62편)의 **정본은 [ModuloHub ABAP 트랙](https://modulohub.com/learn/abap)**입니다. 이 레포는 그 커리큘럼의 **실행 코드 동반자**로, 준비된 단원의 코드를 점증적으로 수록합니다. 아래는 섹션 단위 로드맵입니다.

| NN | 섹션 슬러그 | 편수 |
|---|---|---|
| 00 | `getting-started` | 5 |
| 01 | `data-fundamentals` | 8 |
| 02 | `program-flow` | 3 |
| 03 | `oo-foundations` | 6 |
| 04 | `internal-tables` | 6 |
| 05 | `abap-sql` | 7 |
| 06 | `modern-expressions` | 5 |
| 07 | `testing-quality` | 6 |
| 08 | `executable-programs` | 6 |
| 09 | `transactions-auth` | 3 |
| 10 | `integration-extension` | 4 |
| 11 | `capstone` | 3 |

## 수록 예제
abapGit import가 가능한 단원을 등재합니다. 코드가 추가될 때마다 행이 늘어납니다. import 후 ADT에서 활성화 → ABAP Unit(`Ctrl+Shift+F10`) → ATC를 각자 환경에서 수행해 확인하세요.

| 섹션 | 단원 | 폴더 | ModuloHub 노트 |
|---|---|---|---|
| 00 `getting-started` | 검증 루프 체험 (첫 프로그램) | `src/00_getting-started` | [트랙](https://modulohub.com/learn/abap) |
| 01 `data-fundamentals` | 타입 시스템·TYPES/DATA·인라인 선언 | `src/01_data-fundamentals` `ZCL_MODULO_DF01_TYPES` | [트랙](https://modulohub.com/learn/abap) |
| 01 `data-fundamentals` | 기본 타입·CONV·EXACT | `src/01_data-fundamentals` `ZCL_MODULO_DF02_CONVERT` | [트랙](https://modulohub.com/learn/abap) |
| 01 `data-fundamentals` | DDIC 타입·도메인·데이터 요소 | `src/01_data-fundamentals` `ZCL_MODULO_DF03_DDIC` (+`ZMODULO_DEBIT_CREDIT` 도메인·데이터 요소) | [트랙](https://modulohub.com/learn/abap) |
| 01 `data-fundamentals` | 상수·텍스트 기호·ENUM | `src/01_data-fundamentals` `ZCL_MODULO_DF04_CONSTANTS` | [트랙](https://modulohub.com/learn/abap) |
| 01 `data-fundamentals` | 구조(structure) | `src/01_data-fundamentals` `ZCL_MODULO_DF05_STRUCT` | [트랙](https://modulohub.com/learn/abap) |
| 01 `data-fundamentals` | 숫자 연산 (DIV·MOD·계산 타입) | `src/01_data-fundamentals` `ZCL_MODULO_DF06_NUMERIC` | [트랙](https://modulohub.com/learn/abap) |
| 01 `data-fundamentals` | 날짜·시간·타임스탬프 | `src/01_data-fundamentals` `ZCL_MODULO_DF07_DATETIME` | [트랙](https://modulohub.com/learn/abap) |
| 01 `data-fundamentals` | 문자열·정규식·문자열 함수 | `src/01_data-fundamentals` `ZCL_MODULO_DF08_STRINGS` | [트랙](https://modulohub.com/learn/abap) |
| 01 `data-fundamentals` | 통화·수량 처리 | `src/01_data-fundamentals` `ZCL_MODULO_DF09_CURRENCY` | [트랙](https://modulohub.com/learn/abap) |
| 02 `program-flow` | 제어 구조 (IF·CASE·DO·WHILE) | `src/02_program-flow` `ZCL_MODULO_PF01_CONTROL` | [트랙](https://modulohub.com/learn/abap) |
| 02 `program-flow` | 논리식·술어 함수 | `src/02_program-flow` `ZCL_MODULO_PF02_LOGIC` | [트랙](https://modulohub.com/learn/abap) |
| 02 `program-flow` | 메시지·로깅 | `src/02_program-flow` `ZCL_MODULO_PF03_MESSAGE` | [트랙](https://modulohub.com/learn/abap) |
| 03 `oo-foundations` | 메서드·모듈화 (인스턴스·정적·함수형) | `src/03_oo-foundations` `ZCL_MODULO_OO01_METHODS` | [트랙](https://modulohub.com/learn/abap) |
| 03 `oo-foundations` | 클래스·객체·캡슐화·네이밍 | `src/03_oo-foundations` `ZCL_MODULO_OO02_CLASS` | [트랙](https://modulohub.com/learn/abap) |
| 03 `oo-foundations` | 가시성·생성자·NEW | `src/03_oo-foundations` `ZCL_MODULO_OO03_CTOR` | [트랙](https://modulohub.com/learn/abap) |
| 03 `oo-foundations` | 메서드 시그니처 (IMPORTING~RAISING) | `src/03_oo-foundations` `ZCL_MODULO_OO04_SIGNATURE` | [트랙](https://modulohub.com/learn/abap) |
| 03 `oo-foundations` | 상속·다형성·인터페이스 | `src/03_oo-foundations` `ZCL_MODULO_OO05_INHERIT` | [트랙](https://modulohub.com/learn/abap) |
| 03 `oo-foundations` | ABAP Unit 최소 사용법 | `src/03_oo-foundations` `ZCL_MODULO_OO06_AUNIT` | [트랙](https://modulohub.com/learn/abap) |
| 04 `internal-tables` | 테이블 타입·선언 (STANDARD·SORTED·HASHED·키) | `src/04_internal-tables` `ZCL_MODULO_IT01_TABTYPES` | [트랙](https://modulohub.com/learn/abap) |
| 04 `internal-tables` | 채우기·읽기 (APPEND·INSERT·READ·테이블 식·line_exists) | `src/04_internal-tables` `ZCL_MODULO_IT02_READFILL` | [트랙](https://modulohub.com/learn/abap) |
| 04 `internal-tables` | 순회·변경 (LOOP·ASSIGNING·REFERENCE·MODIFY·DELETE) | `src/04_internal-tables` `ZCL_MODULO_IT03_LOOPMOD` | [트랙](https://modulohub.com/learn/abap) |
| 04 `internal-tables` | 정렬·집계·중복 (SORT·DELETE ADJACENT DUPLICATES·COLLECT·GROUP BY) | `src/04_internal-tables` `ZCL_MODULO_IT04_SORTAGG` | [트랙](https://modulohub.com/learn/abap) |
| 04 `internal-tables` | 모던 생성자식 (VALUE·FOR·REDUCE·FILTER·CORRESPONDING) | `src/04_internal-tables` `ZCL_MODULO_IT05_CTOREXPR` | [트랙](https://modulohub.com/learn/abap) |
| 04 `internal-tables` | 실전 패턴·성능 (조인·요약 리포트·top-N·룩업맵) | `src/04_internal-tables` `ZCL_MODULO_IT06_PATTERNS` | [트랙](https://modulohub.com/learn/abap) |

## 출처·라이선스
참고 원전: [SAP-samples/abap-cheat-sheets](https://github.com/SAP-samples/abap-cheat-sheets), [SAP/styleguides](https://github.com/SAP/styleguides) — **인용·참조이며 코드 복제가 아닙니다.** 라이선스: [Apache-2.0](LICENSE).
