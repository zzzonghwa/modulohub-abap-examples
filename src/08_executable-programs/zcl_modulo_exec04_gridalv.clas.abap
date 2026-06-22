CLASS zcl_modulo_exec04_gridalv DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    "! ADT에서 F9(Run As -> ABAP Application)로 바로 실행해 데모 출력을 본다.
    "!
    "! 편집형/이벤트형 ALV — CL_GUI_ALV_GRID 대조(노트 08-4의 구문 형태를 자체완결로 시연).
    "! CL_GUI_ALV_GRID는 SAP GUI 컨트롤 프레임워크(CFW) 위에서만 동작해 콘솔(IF_OO_ADT_CLASSRUN)에서
    "! 실제 그리드를 띄울 수 없다. 그래서 이 예제는 *그리드 표시 자체*가 아니라, 표시를 구동하는
    "! 데이터 구조와 결정 로직(필드카탈로그·셀 스타일 테이블·이벤트 등록·툴바 버튼·도구 선택)을
    "! 계산해 보여 준다 — 실 API(LVC_S_FCAT / LVC_S_STYL / STB_BUTTON 등)와 같은 필드 모양의
    "! 로컬 타입으로 모델링한다(ABAP Doc에 대응 표준 타입 명시).
    "!
    "! 노트 소절 매핑:
    "! - A 컨테이너 선택: choose_container (CUSTOM vs DOCKING).
    "! - B set_table_for_first_display: build_fieldcat / i_save_meaning / buffer_conflict / layout_edit_all.
    "! - C 편집 이벤트: edit_event_constant / build_style_table / commit_in_pai (LUW 경계).
    "! - D 이벤트 핸들러: event_param / build_toolbar / hotspot_columns.
    "! - E SALV 내부 그리드: salv_edit_supported (비표준 우회 — 코드 미제공, 사실만).
    "! - 종합 대조: recommend_alv / reuse_needs_pf_status / cloud_available.
    INTERFACES if_oo_adt_classrun.

    "! 필드카탈로그 한 행. 실 API LVC_S_FCAT의 핵심 필드를 미러링한다.
    "! (fieldname/coltext/edit/hotspot/key — 셀 편집·링크·키 컬럼 제어).
    TYPES:
      BEGIN OF field_catalog,
        fieldname TYPE c LENGTH 30,
        coltext   TYPE c LENGTH 40,
        edit      TYPE abap_bool,
        hotspot   TYPE abap_bool,
        key       TYPE abap_bool,
      END OF field_catalog.
    "! 필드카탈로그 테이블 — 실 API LVC_T_FCAT 대응.
    TYPES field_catalogs TYPE STANDARD TABLE OF field_catalog WITH EMPTY KEY.

    "! 셀 스타일 한 칸. 실 API LVC_S_STYL의 fieldname/style 쌍을 미러링한다.
    "! style 값은 CL_GUI_ALV_GRID=>MC_STYLE_ENABLED/MC_STYLE_DISABLED를 흉내 낸 상수.
    TYPES:
      BEGIN OF cell_style,
        fieldname TYPE c LENGTH 30,
        style     TYPE i,
      END OF cell_style.
    "! 셀 스타일 테이블 — 실 API LVC_T_STYL 대응(내부 테이블 행 안의 stylefname 컬럼에 담는다).
    TYPES cell_styles TYPE STANDARD TABLE OF cell_style WITH EMPTY KEY.

    "! 툴바 버튼 한 개. 실 API STB_BUTTON의 function/text/icon 핵심 필드를 미러링한다.
    TYPES:
      BEGIN OF toolbar_button,
        function TYPE c LENGTH 20,
        text     TYPE c LENGTH 40,
        icon     TYPE c LENGTH 30,
      END OF toolbar_button.
    "! 툴바 버튼 목록 — 실 API e_object->mt_toolbar(CL_ALV_EVENT_TOOLBAR_SET) 대응.
    TYPES toolbar_buttons TYPE STANDARD TABLE OF toolbar_button WITH EMPTY KEY.

    "! 편집 이벤트 등록 값. 실 상수 CL_GUI_ALV_GRID=>MC_EVT_ENTER/MC_EVT_MODIFIED를 흉내 낸다.
    "! register_edit_event는 display 전에 호출해야 data_changed가 발화한다(노트 C-9).
    CONSTANTS:
      "! Enter 키 입력 시 data_changed 발화(MC_EVT_ENTER 대응).
      event_enter    TYPE i VALUE 1,
      "! 셀 이탈(modified) 시 data_changed 발화(MC_EVT_MODIFIED 대응).
      event_modified TYPE i VALUE 2.

    "! 셀 편집 가능/불가 스타일. 실 상수 MC_STYLE_ENABLED/MC_STYLE_DISABLED 대응(노트 atf L27627).
    CONSTANTS:
      "! 편집 가능 셀.
      style_enabled  TYPE i VALUE 1,
      "! 읽기 전용 셀.
      style_disabled TYPE i VALUE 2.

    "! A. 컨테이너 선택 — Dynpro 화면 설계 없이 빠르게 띄울지에 따라.
    "! @parameter need_dynpro_screen | 미리 그려 둔 Custom Control 영역에 붙일지 여부
    "! @parameter result             | CL_GUI_CUSTOM_CONTAINER 또는 CL_GUI_DOCKING_CONTAINER
    METHODS choose_container
      IMPORTING need_dynpro_screen TYPE abap_bool
      RETURNING VALUE(result)      TYPE string.

    "! B. 필드카탈로그 생성 — set_table_for_first_display의 it_fieldcatalog(LVC_T_FCAT) 구성.
    "! editable=abap_true면 seatsocc(점유 좌석) 컬럼만 편집 가능, 키 컬럼은 잠근다.
    "! @parameter editable | 그리드를 편집 모드로 만들지 여부
    "! @parameter result   | 필드카탈로그 행 목록(키/편집/링크 플래그 포함)
    METHODS build_fieldcat
      IMPORTING editable      TYPE abap_bool
      RETURNING VALUE(result) TYPE field_catalogs.

    "! B. is_layout-edit = 'X'면 그리드 전체가 편집 모드로 시작(셀 단위 제어는 stylefname).
    "! @parameter result | 편집 가능 컬럼(edit=X) 수
    METHODS count_editable_columns
      IMPORTING fieldcat      TYPE field_catalogs
      RETURNING VALUE(result) TYPE i.

    "! B. i_save 파라미터의 레이아웃 변형 저장 권한 의미를 사람이 읽는 라벨로.
    "! 'A'=All, 'U'=User only, ' '=불가. 'X'는 문서 근거 미확인(노트 B-6).
    "! @parameter i_save | i_save 파라미터 값('A'/'U'/' '/'X')
    "! @parameter result | 저장 권한 설명
    METHODS i_save_meaning
      IMPORTING i_save        TYPE c
      RETURNING VALUE(result) TYPE string.

    "! B. i_buffer_active와 i_bypassing_buffer를 동시에 ABAP_TRUE로 두면 모순(노트 B-7).
    "! @parameter buffer_active   | 내부 버퍼 활성(대용량 스크롤 성능)
    "! @parameter bypassing_buffer | 버퍼 우회(최신 데이터 강제 갱신)
    "! @parameter result          | 설정이 모순이면 abap_true
    METHODS buffer_conflict
      IMPORTING buffer_active    TYPE abap_bool
                bypassing_buffer TYPE abap_bool
      RETURNING VALUE(result)    TYPE abap_bool.

    "! C. register_edit_event 등록 값 선택 — Enter 발화냐 셀 이탈 발화냐.
    "! @parameter on_enter | abap_true면 Enter 키, abap_false면 셀 이탈 시 발화
    "! @parameter result   | event_enter 또는 event_modified
    METHODS edit_event_constant
      IMPORTING on_enter      TYPE abap_bool
      RETURNING VALUE(result) TYPE i.

    "! C. 셀 단위 편집 제어 — 행마다 stylefname 컬럼(LVC_T_STYL)을 만든다.
    "! 키 컬럼은 disabled, 나머지는 enabled로 두는 표준 편집 행 1줄을 구성한다.
    "! @parameter fieldcat | 필드카탈로그(key 플래그로 잠금 여부 판단)
    "! @parameter result   | 셀 스타일 목록(fieldname-style 쌍)
    METHODS build_style_table
      IMPORTING fieldcat      TYPE field_catalogs
      RETURNING VALUE(result) TYPE cell_styles.

    "! C. data_changed 핸들러에서 COMMIT WORK 금지 — DB 반영은 PAI user_command에서 일괄(노트 C-11).
    "! @parameter in_data_changed | 현재 위치가 data_changed 핸들러 안인가
    "! @parameter result          | 이 위치에서 COMMIT WORK가 허용되면 abap_true
    METHODS commit_allowed_here
      IMPORTING in_data_changed TYPE abap_bool
      RETURNING VALUE(result)   TYPE abap_bool.

    "! D. 이벤트별 핵심 IMPORTING 파라미터명(7.54 라이브 확정 — 노트 D-13 표).
    "! @parameter event_name | data_changed/user_command/toolbar/hotspot_click/after_refresh
    "! @parameter result     | 해당 이벤트의 핵심 IMPORTING 파라미터(없으면 공백)
    METHODS event_param
      IMPORTING event_name    TYPE string
      RETURNING VALUE(result) TYPE string.

    "! D. 커스텀 툴바 — toolbar 이벤트 핸들러에서 e_object-mt_toolbar에 STB_BUTTON 행 추가.
    "! 표준 편집 시나리오용 버튼(저장·행추가·행삭제) 목록을 구성한다.
    "! @parameter result | 추가할 툴바 버튼 목록
    METHODS build_toolbar
      RETURNING VALUE(result) TYPE toolbar_buttons.

    "! D. hotspot_click — 필드카탈로그 hotspot='X'인 컬럼이 클릭 가능 링크가 된다.
    "! @parameter fieldcat | 필드카탈로그
    "! @parameter result   | hotspot 컬럼명 목록
    METHODS hotspot_columns
      IMPORTING fieldcat      TYPE field_catalogs
      RETURNING VALUE(result) TYPE string_table.

    "! E. SALV 내부에도 CL_GUI_ALV_GRID가 있으나 편집 API는 공식 미노출(노트 E-16).
    "! @parameter result | SALV로 편집이 공식 지원되는가 -> abap_false
    METHODS salv_edit_supported
      RETURNING VALUE(result) TYPE abap_bool.

    "! 종합. 시나리오에 맞는 ALV 도구 추천(편집/이벤트 필요 여부 기준).
    "! @parameter editable | 셀 편집·이벤트 처리가 필요한가
    "! @parameter result   | 권장 클래스명
    METHODS recommend_alv
      IMPORTING editable      TYPE abap_bool
      RETURNING VALUE(result) TYPE string.

    "! 종합. REUSE_ALV로 커스텀 툴바 버튼을 넣으려면 PF-Status가 필수다(노트 D-14, 대조표).
    "! @parameter result | REUSE_ALV에 커스텀 버튼 추가 시 PF-Status가 필요하면 abap_true
    METHODS reuse_needs_pf_status
      RETURNING VALUE(result) TYPE abap_bool.

    "! 종합. 세 ALV 도구 모두 클래식 GUI/Dynpro 의존 -> ABAP Cloud에서 불가(노트 클라우드 깃발).
    "! @parameter result | 클라우드(BTP Steampunk)에서 사용 가능하면 abap_true
    METHODS cloud_available
      RETURNING VALUE(result) TYPE abap_bool.
ENDCLASS.


CLASS zcl_modulo_exec04_gridalv IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    out->write( `=== EXEC04 편집형 ALV (CL_GUI_ALV_GRID) 대조 ===` ).
    out->write( |A choose_container(need_dynpro=X)  = { choose_container( abap_true ) }| ).
    out->write( |A choose_container(need_dynpro= )  = { choose_container( abap_false ) }| ).
    DATA(fieldcat) = build_fieldcat( abap_true ).
    out->write( |B build_fieldcat(편집) 컬럼수      = { lines( fieldcat ) }| ).
    out->write( |B count_editable_columns           = { count_editable_columns( fieldcat ) }| ).
    out->write( |B i_save_meaning('A')              = { i_save_meaning( 'A' ) }| ).
    out->write( |B i_save_meaning('X')              = { i_save_meaning( 'X' ) }| ).
    out->write( |B buffer_conflict(X,X)             = { buffer_conflict( buffer_active = abap_true
                                                                         bypassing_buffer = abap_true ) }| ).
    out->write( |C edit_event_constant(on_enter=X)  = { edit_event_constant( abap_true ) }| ).
    out->write( |C build_style_table 칸수            = { lines( build_style_table( fieldcat ) ) }| ).
    out->write( |C commit_allowed_here(in_dc=X)     = { commit_allowed_here( abap_true ) }| ).
    out->write( |D event_param('toolbar')           = { event_param( `toolbar` ) }| ).
    out->write( |D event_param('hotspot_click')     = { event_param( `hotspot_click` ) }| ).
    out->write( |D build_toolbar 버튼수             = { lines( build_toolbar( ) ) }| ).
    out->write( |D hotspot_columns 수               = { lines( hotspot_columns( fieldcat ) ) }| ).
    out->write( |E salv_edit_supported              = { salv_edit_supported( ) }| ).
    out->write( |* recommend_alv(읽기전용)          = { recommend_alv( abap_false ) } (EXEC03)| ).
    out->write( |* recommend_alv(편집/이벤트)       = { recommend_alv( abap_true ) }| ).
    out->write( |* reuse_needs_pf_status            = { reuse_needs_pf_status( ) }| ).
    out->write( |* cloud_available                  = { cloud_available( ) } (셋 다 온프렘 전용)| ).
  ENDMETHOD.

  METHOD choose_container.
    " Custom Control은 SE51에서 영역 배치가 선행, Docking은 sy-repid/sy-dynnr로 즉시 생성.
    result = COND #( WHEN need_dynpro_screen = abap_true
                     THEN `CL_GUI_CUSTOM_CONTAINER`
                     ELSE `CL_GUI_DOCKING_CONTAINER` ).
  ENDMETHOD.

  METHOD build_fieldcat.
    " 키 2컬럼(carrid/connid) + 편집 후보 1컬럼(seatsocc). 편집 모드면 비키 컬럼만 edit=X.
    " connid는 마스터 탐색용 링크(hotspot)로 둔다.
    result = VALUE #(
      ( fieldname = 'CARRID'   coltext = 'Airline'        key = abap_true )
      ( fieldname = 'CONNID'   coltext = 'Connection'     key = abap_true  hotspot = abap_true )
      ( fieldname = 'SEATSOCC' coltext = 'Occupied seats' edit = editable ) ).
  ENDMETHOD.

  METHOD count_editable_columns.
    result = REDUCE i( INIT count = 0
                       FOR row IN fieldcat
                       NEXT count = count + COND i( WHEN row-edit = abap_true THEN 1 ELSE 0 ) ).
  ENDMETHOD.

  METHOD i_save_meaning.
    result = SWITCH #( i_save
                       WHEN 'A'  THEN `All (global + user)`
                       WHEN 'U'  THEN `User only`
                       WHEN ' '  THEN `No save`
                       WHEN 'X'  THEN `Undocumented`
                       ELSE `Unknown` ).
  ENDMETHOD.

  METHOD buffer_conflict.
    " 버퍼 활성과 버퍼 우회를 동시에 켜는 것은 모순이다.
    result = xsdbool( buffer_active = abap_true AND bypassing_buffer = abap_true ).
  ENDMETHOD.

  METHOD edit_event_constant.
    result = COND #( WHEN on_enter = abap_true THEN event_enter ELSE event_modified ).
  ENDMETHOD.

  METHOD build_style_table.
    " 키 컬럼은 disabled, 나머지는 enabled. 행마다 이런 LVC_T_STYL을 stylefname 컬럼에 채운다.
    result = VALUE #( FOR row IN fieldcat
                      ( fieldname = row-fieldname
                        style     = COND #( WHEN row-key = abap_true
                                            THEN style_disabled
                                            ELSE style_enabled ) ) ).
  ENDMETHOD.

  METHOD commit_allowed_here.
    " data_changed 핸들러 안에서는 COMMIT 금지 — LUW 원칙상 PAI에서 일괄 처리.
    result = xsdbool( in_data_changed = abap_false ).
  ENDMETHOD.

  METHOD event_param.
    result = SWITCH #( event_name
                       WHEN `data_changed`  THEN `er_data_changed`
                       WHEN `user_command`  THEN `e_ucomm`
                       WHEN `toolbar`       THEN `e_object`
                       WHEN `hotspot_click` THEN `e_row_id`
                       WHEN `after_refresh` THEN ``
                       ELSE `` ).
  ENDMETHOD.

  METHOD build_toolbar.
    " toolbar 이벤트에서 e_object-mt_toolbar에 추가할 표준 편집 버튼.
    result = VALUE #(
      ( function = 'SAVE'   text = 'Save'        icon = 'ICON_SYSTEM_SAVE' )
      ( function = 'INSROW' text = 'Insert row'  icon = 'ICON_INSERT_ROW' )
      ( function = 'DELROW' text = 'Delete row'  icon = 'ICON_DELETE_ROW' ) ).
  ENDMETHOD.

  METHOD hotspot_columns.
    result = VALUE #( FOR row IN fieldcat
                      WHERE ( hotspot = abap_true )
                      ( CONV string( row-fieldname ) ) ).
  ENDMETHOD.

  METHOD salv_edit_supported.
    " SALV 내부에 CL_GUI_ALV_GRID가 있어도 편집 API는 공식 미노출. 우회는 비표준(노트 E-17).
    result = abap_false.
  ENDMETHOD.

  METHOD recommend_alv.
    result = COND #( WHEN editable = abap_true
                     THEN `CL_GUI_ALV_GRID`
                     ELSE `CL_SALV_TABLE` ).
  ENDMETHOD.

  METHOD reuse_needs_pf_status.
    " REUSE_ALV는 커스텀 버튼에 PF-Status(SE41)가 필수. OO 그리드는 toolbar 이벤트로 동적 추가.
    result = abap_true.
  ENDMETHOD.

  METHOD cloud_available.
    " CL_GUI_ALV_GRID/REUSE_ALV/CL_SALV_TABLE 모두 클래식 GUI 의존 -> BTP Steampunk 불가.
    result = abap_false.
  ENDMETHOD.
ENDCLASS.
