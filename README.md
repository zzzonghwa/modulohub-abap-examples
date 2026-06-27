# ModuloHub ABAP Examples

[ModuloHub](https://modulohub.com) ABAP 학습 트랙의 **실행 가능한 ABAP 예제** 모음입니다. 각 예제는 SAP S/4HANA(ABAP Platform 7.54+)에서 컴파일·실행·ATC 검사를 통과하도록 작성했습니다.

## 사용법 (abapGit import)

1. ABAP 시스템에 [abapGit](https://abapgit.org)을 설치합니다.
2. abapGit에서 "Online" → 이 레포 URL(`https://github.com/zzzonghwa/modulohub-abap-examples`)로 새 저장소를 만들고, 전용 패키지(예: `$MODULOHUB_ABAP` 로컬 또는 `ZMODULOHUB_ABAP` 운반)로 pull합니다.
3. `src/<단원>/` 의 클래스를 활성화합니다.

## 예제 실행·학습

- **바로 실행 (ADT)**: 대부분의 예제는 `IF_OO_ADT_CLASSRUN`을 구현하는 클래스입니다. ADT(Eclipse)에서 클래스를 열고 **F9**(Run As → ABAP Application)를 누르면 `main`이 각 메서드를 호출해 콘솔에 결과를 출력합니다 — 별도 리포트·드라이버 없이 즉시 체험할 수 있습니다.
- **실행형 프로그램(`08 executable-programs`의 `.prog`)**: 선택화면·ALV·WRITE 리스트는 본질이 실행형 리포트라 클래스가 아닌 `Z_MODULO_EXEC0n`(`.prog`)으로 제공하며, **SE38/SA38에서 F8**(또는 ADT에서 리포트로 실행)로 실행합니다(F9 클래스런 아님). 화면 출력이라 결과는 각자 환경에서 확인하는 manual-report입니다. ALV 그리드(`CL_SALV_TABLE`)는 SAP GUI에서만 렌더됩니다.
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
| 05 `abap-sql` | ABAP SQL 토대·결과 매핑 (SELECT 타깃·`sy-subrc`·호스트식 `@`) | `src/05_abap-sql` `ZCL_MODULO_SQL01_BASICS` | [트랙](https://modulohub.com/learn/abap) |
| 05 `abap-sql` | SELECT·WHERE (비교·BETWEEN·IN·LIKE·DISTINCT·ORDER BY) | `src/05_abap-sql` `ZCL_MODULO_SQL02_WHERE` | [트랙](https://modulohub.com/learn/abap) |
| 05 `abap-sql` | JOIN·집계 (INNER/LEFT OUTER JOIN·SUM/MAX·GROUP BY·HAVING — Z 테이블·osql 더블) | `src/05_abap-sql` `ZCL_MODULO_SQL03_JOINAGG` | [트랙](https://modulohub.com/learn/abap) |
| 05 `abap-sql` | released CDS 뷰 소비 (시맨틱 필드·association·읽기전용·API State C1) | `src/05_abap-sql` `ZCL_MODULO_SQL04_CDS` | [트랙](https://modulohub.com/learn/abap) |
| 05 `abap-sql` | CTE·서브쿼리 (`WITH`·스칼라/`IN` 인라인 서브쿼리 — Z 테이블·osql 더블) | `src/05_abap-sql` `ZCL_MODULO_SQL05_CTE` | [트랙](https://modulohub.com/learn/abap) |
| 05 `abap-sql` | 버퍼링·Code Pushdown (집계 푸시다운 vs ABAP loop·ST05/SAT 개념) | `src/05_abap-sql` `ZCL_MODULO_SQL06_PUSHDOWN` | [트랙](https://modulohub.com/learn/abap) |
| 05 `abap-sql` | released API 소비 (API State C1·`CL_ABAP_CONTEXT_INFO`·읽기전용) | `src/05_abap-sql` `ZCL_MODULO_SQL07_API` | [트랙](https://modulohub.com/learn/abap) |
| 06 `modern-expressions` | VALUE·FOR·CORRESPONDING (BASE·`FOR..THEN..UNTIL`·MAPPING) | `src/06_modern-expressions` `ZCL_MODULO_EXPR01_VALUE` | [트랙](https://modulohub.com/learn/abap) |
| 06 `modern-expressions` | COND·SWITCH (범위 분기·값 매칭) | `src/06_modern-expressions` `ZCL_MODULO_EXPR02_COND` | [트랙](https://modulohub.com/learn/abap) |
| 06 `modern-expressions` | REDUCE (fold·다중 누적기·조건 누적) | `src/06_modern-expressions` `ZCL_MODULO_EXPR03_REDUCE` | [트랙](https://modulohub.com/learn/abap) |
| 06 `modern-expressions` | CONV·CAST·REF·EXACT (명시변환·다운캐스트·데이터참조·무손실) | `src/06_modern-expressions` `ZCL_MODULO_EXPR04_CONV` | [트랙](https://modulohub.com/learn/abap) |
| 06 `modern-expressions` | 디자인 패턴·DI 기초 (전략 패턴·인터페이스 분리·생성자 주입·테스트 더블) | `src/06_modern-expressions` `ZCL_MODULO_EXPR05_DI` | [트랙](https://modulohub.com/learn/abap) |
| 07 `testing-quality` | 예외 처리·CX 분류·DbC (`cx_static_check` 도메인 예외·`RAISE`·사전조건) | `src/07_testing-quality` `ZCL_MODULO_TST01_EXCEPT` | [트랙](https://modulohub.com/learn/abap) |
| 07 `testing-quality` | ABAP Unit 심화 (테스트 더블 스텁·스파이·`setup` 픽스처·상호작용 검증) | `src/07_testing-quality` `ZCL_MODULO_TST02_AUNIT` | [트랙](https://modulohub.com/learn/abap) |
| 07 `testing-quality` | ATC·정적 품질 (우선순위·프라그마 `##NEEDED`/`##NO_HANDLER`/`##NO_TEXT`·SWITCH 디스패치) | `src/07_testing-quality` `ZCL_MODULO_TST03_ATC` | [트랙](https://modulohub.com/learn/abap) |
| 07 `testing-quality` | Clean ABAP 규칙 (`xsdbool` 불리언·가드 절·서술적 이름·작은 함수형 메서드) | `src/07_testing-quality` `ZCL_MODULO_TST04_CLEAN` | [트랙](https://modulohub.com/learn/abap) |
| 07 `testing-quality` | 성능·측정 도구 (중첩 LOOP vs HASHED 룩업·ST05/SAT/SQLM·ATC 성능 룰) | `src/07_testing-quality` `ZCL_MODULO_TST05_PERF` | [트랙](https://modulohub.com/learn/abap) |
| 07 `testing-quality` | 디버깅 (Collatz로 브레이크포인트·스텝·watchpoint·변수 검사 연습) | `src/07_testing-quality` `ZCL_MODULO_TST06_DEBUG` | [트랙](https://modulohub.com/learn/abap) |
| 07 `testing-quality` | 표준 테스트 더블 프레임워크 (`CL_ABAP_TESTDOUBLE` 전역 인터페이스 더블·`returning` 스텁·입력별 구성·`and_expect`/`verify_expectations` 목) | `src/07_testing-quality` `ZCL_MODULO_TST07_TDF` (+`ZIF_MODULO_TST07_STOCK` 전역 인터페이스) | [트랙](https://modulohub.com/learn/abap) |
| 07 `testing-quality` | DB 격리 테스트 더블 환경 (`CL_OSQL_TEST_ENVIRONMENT` ABAP SQL 더블·`CL_CDS_TEST_ENVIRONMENT` CDS 뷰 베이스 테이블 더블·`create`/`clear_doubles`/`insert_test_data`/`destroy`) | `src/07_testing-quality` `ZCL_MODULO_TST08_DBDBL` (+CDS 뷰 `ZMODULO_TST08_SEATS`, 베이스 `ZMODULO_FLIGHT` 재사용) | [트랙](https://modulohub.com/learn/abap) |
| 08 `executable-programs` | 실행형 프로그램 뼈대 (`REPORT`·`INITIALIZATION`·`START-OF-SELECTION`·이벤트 블록) | `src/08_executable-programs` `Z_MODULO_EXEC01` (.prog·F8) | [트랙](https://modulohub.com/learn/abap) |
| 08 `executable-programs` | 선택화면·리스트 (`PARAMETERS`·`SELECT-OPTIONS`·`AT SELECTION-SCREEN`·`WRITE`) | `src/08_executable-programs` `Z_MODULO_EXEC02` (.prog·F8) | [트랙](https://modulohub.com/learn/abap) |
| 08 `executable-programs` | ALV (모던 읽기전용 `CL_SALV_TABLE` factory+display) | `src/08_executable-programs` `Z_MODULO_EXEC03` (.prog·F8) | [트랙](https://modulohub.com/learn/abap) |
| 08 `executable-programs` | 편집형 ALV 대조 (`CL_GUI_ALV_GRID` vs `CL_SALV_TABLE` vs REUSE_ALV·도구 선택) | `src/08_executable-programs` `ZCL_MODULO_EXEC04_GRIDALV` | [트랙](https://modulohub.com/learn/abap) |
| 08 `executable-programs` | 클래식 WRITE 리스트 (역사적 대조 — 왜 ALV로) | `src/08_executable-programs` `Z_MODULO_EXEC05` (.prog·F8) | [트랙](https://modulohub.com/learn/abap) |
| 08 `executable-programs` | DB 변경문·LUW (INSERT/UPDATE/MODIFY/DELETE·`sy-subrc`/`sy-dbcnt` — Z 테이블·osql) | `src/08_executable-programs` `ZCL_MODULO_EXEC06_DML` | [트랙](https://modulohub.com/learn/abap) |
| 09 `transactions-auth` | SAP LUW·번들링 (Unit of Work로 commit/rollback/번들 경계 인메모리 시연) | `src/09_transactions-auth` `ZCL_MODULO_TXN01_LUW` | [트랙](https://modulohub.com/learn/abap) |
| 09 `transactions-auth` | ENQUEUE/DEQUEUE·COMMIT WORK (인메모리 lock table·foreign_lock·_scope 개념) | `src/09_transactions-auth` `ZCL_MODULO_TXN02_LOCK` | [트랙](https://modulohub.com/learn/abap) |
| 09 `transactions-auth` | 인증 체크 (`AUTHORITY-CHECK OBJECT 'S_TCODE'`·`sy-subrc` 해석·권한 객체 소비) | `src/09_transactions-auth` `ZCL_MODULO_TXN03_AUTH` | [트랙](https://modulohub.com/learn/abap) |
| 10 `integration-extension` | released API·XCO 소비 (고전 FM 대체·`xco_cp` 문자열·UUID·C1) | `src/10_integration-extension` `ZCL_MODULO_EXT01_XCO` | [트랙](https://modulohub.com/learn/abap) |
| 10 `integration-extension` | XML·JSON 직렬화 (`CALL TRANSFORMATION id` asXML·`/ui2/cl_json` 라운드트립) | `src/10_integration-extension` `ZCL_MODULO_EXT02_SERIAL` | [트랙](https://modulohub.com/learn/abap) |
| 10 `integration-extension` | BAdI·Enhancement 소비 (멀티캐스트 레지스트리·여러 구현 전부 호출) | `src/10_integration-extension` `ZCL_MODULO_EXT03_BADI` | [트랙](https://modulohub.com/learn/abap) |
| 11 `capstone` | 시나리오→OO→ABAP Unit→ATC clean→abapGit (좌석 점유율 분석기 — 읽기/분석 인터페이스 분리·생성자 주입·테스트 더블로 DB 격리·TDD 경계 케이스) | `src/11_capstone` `ZCL_MODULO_CAP01_ANALYZER` (+`ZIF_MODULO_CAP01_READER`·`ZIF_MODULO_CAP01_ANALYZER`, 베이스 `ZMODULO_FLIGHT` 재사용) | [트랙](https://modulohub.com/learn/abap) |
| 11 `capstone` | 실행형 리포트 (선택화면 `PARAMETERS`/`SELECT-OPTIONS` + `CL_SALV_TABLE` ALV — 검증된 분석기를 인메모리 reader 주입으로 재사용·manual-verify) | `src/11_capstone` `Z_MODULO_CAP02` (.prog·F8) | [트랙](https://modulohub.com/learn/abap) |

> `abap-sql` 예제는 **자체 포함**을 위해 SAP 표준 데모 테이블(SFLIGHT 등)에 의존하지 않고 두 가지 데이터 소스를 씁니다. (1) 단일 테이블 예제(토대·WHERE·집계 일부)는 ABAP SQL의 **내부 테이블 소스**(`SELECT ... FROM @itab`, 7.52+) — import 직후 데이터 없이 F9·ABAP Unit 동작. (2) **`JOIN`·인라인 서브쿼리·DB 변경**은 내부 테이블로 불가("문당 내부 테이블 1개", [공식 문서](https://help.sap.com/doc/abapdocu_latest_index_htm/latest/en-US/abapselect_itab.htm))하므로 소형 **Z 데모 테이블**(`ZMODULO_FLIGHT`·`ZMODULO_CARRIER`, `src/05_abap-sql/*.tabl.xml`)을 동봉합니다. 이 표는 import 직후 비어 있으므로 단위 테스트는 **SQL 테스트 더블**(`CL_OSQL_TEST_ENVIRONMENT`)로 결정적 데이터를 주입해 검증합니다(실 DB 미변경). 표 적재는 `08 executable-programs`의 DB 변경 예제 또는 수동으로.

## 출처·라이선스
참고 원전: [SAP-samples/abap-cheat-sheets](https://github.com/SAP-samples/abap-cheat-sheets), [SAP/styleguides](https://github.com/SAP/styleguides) — **인용·참조이며 코드 복제가 아닙니다.** 라이선스: [Apache-2.0](LICENSE).
