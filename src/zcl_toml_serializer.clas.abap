CLASS zcl_toml_serializer DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS serialize
      IMPORTING it_nodes       TYPE zif_toml_types=>ty_nodes
      RETURNING VALUE(rv_toml) TYPE string
      RAISING   zcx_toml_error.

  PRIVATE SECTION.
    DATA mt_nodes TYPE zif_toml_types=>ty_nodes.

    METHODS emit_table
      IMPORTING iv_table_id  TYPE i
                iv_full_path TYPE string
                iv_is_root   TYPE abap_bool
      CHANGING  cv_output    TYPE string
      RAISING   zcx_toml_error.

    METHODS emit_scalars
      IMPORTING it_children TYPE zif_toml_types=>ty_nodes
      CHANGING  cv_output   TYPE string
      RAISING   zcx_toml_error.

    METHODS emit_flat_arrays
      IMPORTING it_children TYPE zif_toml_types=>ty_nodes
      CHANGING  cv_output   TYPE string
      RAISING   zcx_toml_error.

    METHODS emit_inline_tables
      IMPORTING it_children TYPE zif_toml_types=>ty_nodes
      CHANGING  cv_output   TYPE string
      RAISING   zcx_toml_error.

    METHODS emit_sub_tables
      IMPORTING it_children  TYPE zif_toml_types=>ty_nodes
                iv_full_path TYPE string
                iv_is_root   TYPE abap_bool
      CHANGING  cv_output    TYPE string
      RAISING   zcx_toml_error.

    METHODS emit_array_tables
      IMPORTING it_children  TYPE zif_toml_types=>ty_nodes
                iv_full_path TYPE string
                iv_is_root   TYPE abap_bool
      CHANGING  cv_output    TYPE string
      RAISING   zcx_toml_error.

    METHODS header_for
      IMPORTING iv_name          TYPE string
                iv_full_path     TYPE string
                iv_is_root       TYPE abap_bool
      RETURNING VALUE(rv_header) TYPE string.

    METHODS full_path_for
      IMPORTING iv_table_id         TYPE i
      RETURNING VALUE(rv_full_path) TYPE string.

    METHODS escape_key
      IMPORTING iv_key            TYPE string
      RETURNING VALUE(rv_escaped) TYPE string.

    METHODS format_value
      IMPORTING is_node        TYPE zif_toml_types=>ty_node
      RETURNING VALUE(rv_text) TYPE string
      RAISING   zcx_toml_error.

    METHODS format_string
      IMPORTING iv_value       TYPE string
      RETURNING VALUE(rv_text) TYPE string.

    METHODS is_bare_key
      IMPORTING iv_key            TYPE string
      RETURNING VALUE(rv_is_bare) TYPE abap_bool.

    METHODS children_of
      IMPORTING iv_parent          TYPE i
      RETURNING VALUE(rt_children) TYPE zif_toml_types=>ty_nodes.
ENDCLASS.


CLASS zcl_toml_serializer IMPLEMENTATION.
  METHOD serialize.
    mt_nodes = it_nodes.
    CLEAR rv_toml.
    emit_table( EXPORTING iv_table_id  = 0
                          iv_full_path = ''
                          iv_is_root   = abap_true
                CHANGING  cv_output    = rv_toml ).
  ENDMETHOD.

  METHOD emit_table.
    DATA lt_children TYPE zif_toml_types=>ty_nodes.

    lt_children = children_of( iv_table_id ).
    emit_scalars( EXPORTING it_children = lt_children
                  CHANGING  cv_output   = cv_output ).
    emit_flat_arrays( EXPORTING it_children = lt_children
                      CHANGING  cv_output   = cv_output ).
    emit_inline_tables( EXPORTING it_children = lt_children
                        CHANGING  cv_output   = cv_output ).
    emit_sub_tables( EXPORTING it_children  = lt_children
                               iv_full_path = iv_full_path
                               iv_is_root   = iv_is_root
                     CHANGING  cv_output    = cv_output ).
    emit_array_tables( EXPORTING it_children  = lt_children
                                 iv_full_path = iv_full_path
                                 iv_is_root   = iv_is_root
                       CHANGING  cv_output    = cv_output ).
  ENDMETHOD.

  METHOD emit_scalars.
    DATA ls_node TYPE zif_toml_types=>ty_node.
    DATA lv_nl   TYPE string.

    lv_nl = cl_abap_char_utilities=>newline.
    LOOP AT it_children INTO ls_node WHERE     kind <> zif_toml_types=>c_kind_table
                                           AND kind <> zif_toml_types=>c_kind_array.
      cv_output = |{ cv_output }{ escape_key( ls_node-name ) } = { format_value( ls_node ) }{ lv_nl }|.
    ENDLOOP.
  ENDMETHOD.

  METHOD emit_flat_arrays.
    DATA ls_node           TYPE zif_toml_types=>ty_node.
    DATA lv_nl             TYPE string.
    DATA lt_elems          TYPE zif_toml_types=>ty_nodes.
    DATA ls_elem           TYPE zif_toml_types=>ty_node.
    DATA lv_first          TYPE abap_bool.
    DATA lv_is_table_array TYPE abap_bool.

    lv_nl = cl_abap_char_utilities=>newline.
    LOOP AT it_children INTO ls_node WHERE kind = zif_toml_types=>c_kind_array.
      lt_elems = children_of( ls_node-id ).
      lv_is_table_array = abap_false.
      IF lines( lt_elems ) > 0.
        ls_elem = lt_elems[ 1 ].
        IF ls_elem-kind = zif_toml_types=>c_kind_table.
          lv_is_table_array = abap_true.
        ENDIF.
      ENDIF.
      IF lv_is_table_array = abap_true.
        CONTINUE.
      ENDIF.
      cv_output = |{ cv_output }{ escape_key( ls_node-name ) } = [|.
      lv_first = abap_true.
      LOOP AT lt_elems INTO ls_elem.
        IF lv_first = abap_false.
          cv_output = |{ cv_output },|.
        ENDIF.
        cv_output = cv_output && format_value( ls_elem ).
        lv_first = abap_false.
      ENDLOOP.
      cv_output = |{ cv_output }]{ lv_nl }|.
    ENDLOOP.
  ENDMETHOD.

  METHOD emit_inline_tables.
    DATA ls_node  TYPE zif_toml_types=>ty_node.
    DATA lv_nl    TYPE string.
    DATA lt_elems TYPE zif_toml_types=>ty_nodes.
    DATA ls_elem  TYPE zif_toml_types=>ty_node.
    DATA lv_first TYPE abap_bool.

    lv_nl = cl_abap_char_utilities=>newline.
    LOOP AT it_children INTO ls_node WHERE kind = zif_toml_types=>c_kind_table.
      IF ls_node-value <> 'inline'.
        CONTINUE.
      ENDIF.
      cv_output = |{ cv_output }{ escape_key( ls_node-name ) } = \{|.
      lt_elems = children_of( ls_node-id ).
      lv_first = abap_true.
      LOOP AT lt_elems INTO ls_elem.
        IF lv_first = abap_false.
          cv_output = |{ cv_output },|.
        ENDIF.
        cv_output = |{ cv_output }{ escape_key( ls_elem-name ) } = { format_value( ls_elem ) }|.
        lv_first = abap_false.
      ENDLOOP.
      cv_output = |{ cv_output } \}{ lv_nl }|.
    ENDLOOP.
  ENDMETHOD.

  METHOD emit_sub_tables.
    DATA ls_node   TYPE zif_toml_types=>ty_node.
    DATA lv_nl     TYPE string.
    DATA lv_header TYPE string.

    lv_nl = cl_abap_char_utilities=>newline.
    LOOP AT it_children INTO ls_node WHERE kind = zif_toml_types=>c_kind_table.
      IF ls_node-value = 'inline'.
        CONTINUE.
      ENDIF.
      lv_header = header_for( iv_name      = ls_node-name
                              iv_full_path = iv_full_path
                              iv_is_root   = iv_is_root ).
      cv_output = |{ cv_output }{ lv_nl }[{ lv_header }]{ lv_nl }|.
      emit_table( EXPORTING iv_table_id  = ls_node-id
                            iv_full_path = lv_header
                            iv_is_root   = abap_false
                  CHANGING  cv_output    = cv_output ).
    ENDLOOP.
  ENDMETHOD.

  METHOD emit_array_tables.
    DATA ls_node   TYPE zif_toml_types=>ty_node.
    DATA lv_nl     TYPE string.
    DATA lv_header TYPE string.
    DATA lt_elems  TYPE zif_toml_types=>ty_nodes.
    DATA ls_elem   TYPE zif_toml_types=>ty_node.

    lv_nl = cl_abap_char_utilities=>newline.
    LOOP AT it_children INTO ls_node WHERE kind = zif_toml_types=>c_kind_array.
      lt_elems = children_of( ls_node-id ).
      IF lines( lt_elems ) = 0.
        CONTINUE.
      ENDIF.
      ls_elem = lt_elems[ 1 ].
      IF ls_elem-kind <> zif_toml_types=>c_kind_table.
        CONTINUE.
      ENDIF.
      lv_header = header_for( iv_name      = ls_node-name
                              iv_full_path = iv_full_path
                              iv_is_root   = iv_is_root ).
      LOOP AT lt_elems INTO ls_elem.
        cv_output = |{ cv_output }{ lv_nl }[[{ lv_header }]]{ lv_nl }|.
        emit_table( EXPORTING iv_table_id  = ls_elem-id
                              iv_full_path = lv_header
                              iv_is_root   = abap_false
                    CHANGING  cv_output    = cv_output ).
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.

  METHOD header_for.
    IF iv_is_root = abap_true OR iv_full_path IS INITIAL.
      rv_header = escape_key( iv_name ).
    ELSE.
      rv_header = |{ iv_full_path }.{ escape_key( iv_name ) }|.
    ENDIF.
  ENDMETHOD.

  METHOD full_path_for.
    DATA ls_node        TYPE zif_toml_types=>ty_node.
    DATA lv_parent_path TYPE string.

    READ TABLE mt_nodes INTO ls_node WITH KEY id = iv_table_id.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    IF ls_node-parent <= 0 OR ls_node-name IS INITIAL.
      rv_full_path = escape_key( ls_node-name ).
      RETURN.
    ENDIF.
    lv_parent_path = full_path_for( ls_node-parent ).
    IF lv_parent_path IS INITIAL.
      rv_full_path = escape_key( ls_node-name ).
    ELSE.
      rv_full_path = |{ lv_parent_path }.{ escape_key( ls_node-name ) }|.
    ENDIF.
  ENDMETHOD.

  METHOD escape_key.
    IF is_bare_key( iv_key ) = abap_true.
      rv_escaped = iv_key.
    ELSE.
      rv_escaped = |"{ iv_key }"|.
    ENDIF.
  ENDMETHOD.

  METHOD is_bare_key.
    DATA lv_idx TYPE i.
    DATA lv_len TYPE i.
    DATA lv_chr TYPE c LENGTH 1.

    rv_is_bare = abap_true.
    IF iv_key IS INITIAL.
      rv_is_bare = abap_false.
      RETURN.
    ENDIF.
    lv_len = strlen( iv_key ).
    lv_idx = 0.
    WHILE lv_idx < lv_len.
      lv_chr = substring( val = iv_key
                          off = lv_idx
                          len = 1 ).
      IF    ( lv_chr >= 'A' AND lv_chr <= 'Z' ) OR ( lv_chr >= 'a' AND lv_chr <= 'z' )
         OR ( lv_chr >= '0' AND lv_chr <= '9' ) OR lv_chr = '_' OR lv_chr = '-'.
        lv_idx += 1.
        CONTINUE.
      ENDIF.
      rv_is_bare = abap_false.
      RETURN.
    ENDWHILE.
  ENDMETHOD.

  METHOD format_value.
    CASE is_node-kind.
      WHEN zif_toml_types=>c_kind_string.
        rv_text = format_string( is_node-value ).
      WHEN zif_toml_types=>c_kind_integer
          OR zif_toml_types=>c_kind_float
          OR zif_toml_types=>c_kind_boolean
          OR zif_toml_types=>c_kind_datetime
          OR zif_toml_types=>c_kind_date
          OR zif_toml_types=>c_kind_time.
        rv_text = is_node-value.
      WHEN zif_toml_types=>c_kind_array.
        rv_text = '[]'.
      WHEN OTHERS.
        RAISE EXCEPTION NEW zcx_toml_error( iv_text = |Cannot format kind: { is_node-kind }| ).
    ENDCASE.
  ENDMETHOD.

  METHOD format_string.
    DATA lv_out TYPE string.
    DATA lv_idx TYPE i.
    DATA lv_len TYPE i.
    DATA lv_chr TYPE string.

    lv_len = strlen( iv_value ).
    lv_idx = 0.
    CLEAR lv_out.
    WHILE lv_idx < lv_len.
      lv_chr = substring( val = iv_value
                          off = lv_idx
                          len = 1 ).
      CASE lv_chr.
        WHEN '"'.
          lv_out = |{ lv_out }\\"|.
        WHEN '\'.
          lv_out = |{ lv_out }\\\\|.
        WHEN OTHERS.
          CASE lv_chr.
            WHEN cl_abap_char_utilities=>newline.
              lv_out = |{ lv_out }\\n|.
            WHEN cl_abap_char_utilities=>horizontal_tab.
              lv_out = |{ lv_out }\\t|.
            WHEN cl_abap_char_utilities=>cr_lf(1).
              lv_out = |{ lv_out }\\r|.
            WHEN OTHERS.
              lv_out = |{ lv_out }{ lv_chr }|.
          ENDCASE.
      ENDCASE.
      lv_idx += 1.
    ENDWHILE.
    rv_text = |"{ lv_out }"|.
  ENDMETHOD.

  METHOD children_of.
    DATA ls_node TYPE zif_toml_types=>ty_node.

    LOOP AT mt_nodes INTO ls_node WHERE parent = iv_parent.
      INSERT ls_node INTO TABLE rt_children.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
