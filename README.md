# ModuloHub ABAP Examples

[ModuloHub](https://modulohub.com) ABAP 학습 트랙의 **검증된 실행 가능한 ABAP 예제** 모음입니다. 각 예제는 SAP S/4HANA(ABAP Platform 7.54+)에서 컴파일·실행·ATC 검사를 통과합니다.

## 사용법 (abapGit import)

1. ABAP 시스템에 [abapGit](https://abapgit.org)을 설치합니다.
2. abapGit에서 "Online" → 이 레포 URL(`https://github.com/zzzonghwa/modulohub-abap-examples`)로 새 저장소를 만들고, 전용 패키지(예: `$MODULOHUB_ABAP` 로컬 또는 `ZMODULOHUB_ABAP` 운반)로 pull합니다.
3. `src/<단원>/` 의 클래스·프로그램을 활성화해 실행합니다.

## 커리큘럼 로드맵

전체 커리큘럼(12섹션·62편)의 **정본은 [ModuloHub ABAP 트랙](https://modulohub.com/learn/abap)**입니다. 이 레포는 그 커리큘럼의 **실행 코드 동반자**로, 검증을 통과한 단원의 코드를 점증적으로 수록합니다. 아래는 섹션 단위 로드맵입니다.

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

검증(activate → ABAP Unit → ATC)을 통과해 abapGit import가 가능한 단원만 등재합니다. 코드가 추가될 때마다 행이 늘어납니다.

| 섹션 | 단원 | 폴더 | ModuloHub 노트 |
|---|---|---|---|
| 00 `getting-started` | 검증 루프 체험 (첫 프로그램) | `src/00_getting-started` | [트랙](https://modulohub.com/learn/abap) |

## 출처·라이선스

코드는 직접 저작하고 SAP 시스템(비프로덕션 SAP)에서 검증했습니다. 참고 원전: *Clean ABAP*(SAP Press), *ABAP to the Future*(SAP Press), [SAP-samples/abap-cheat-sheets](https://github.com/SAP-samples/abap-cheat-sheets), [SAP/styleguides](https://github.com/SAP/styleguides) — **인용·참조이며 코드 복제가 아닙니다.** 라이선스: [Apache-2.0](LICENSE).
