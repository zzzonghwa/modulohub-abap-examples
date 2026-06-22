* 이 클래스의 CCDEF(Class-relevant Local Types)는 비어 있다.
* 로컬 예외 lcx_invalid_arg/lcx_overdrawn/lcx_precondition(cx_dynamic_check)은 locals_imp(CCIMP)에 정의한다.
* public 메서드 시그니처는 로컬 타입을 참조할 수 없으므로(공개 API 제약) CCDEF가 불필요하다.
* (이 빈 CCDEF는 이전 커밋이 남긴 CCDEF 정의를 pull 시 덮어 비우기 위함.)
