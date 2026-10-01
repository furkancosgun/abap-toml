CLASS zcl_toml_parser DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS parse
      IMPORTING iv_toml         TYPE string
      RETURNING VALUE(rt_nodes) TYPE zif_toml_types=>ty_nodes
      RAISING   zcx_toml_error.

  PRIVATE SECTION.
    DATA mt_nodes   TYPE zif_toml_types=>ty_nodes.
    DATA mv_next_id TYPE i.
    DATA mv_current TYPE i.

    METHODS init_root.

    METHODS to_logical_lines
      IMPORTING iv_text         TYPE string
      RETURNING VALUE(rt_lines) TYPE zif_toml_types=>ty_string_table.

    METHODS strip_comment
      IMPORTING iv_line        TYPE string
      RETURNING VALUE(rv_line) TYPE string.

    METHODS parse_document
      IMPORTING it_lines TYPE zif_toml_types=>ty_string_table
      RAISING   zcx_toml_error.

    METHODS parse_table_header
      IMPORTING iv_line    TYPE string
                iv_line_no TYPE i
      RAISING   zcx_toml_error.

    METHODS parse_array_table_header
      IMPORTING iv_line    TYPE string
                iv_line_no TYPE i
      RAISING   zcx_toml_error.

    METHODS parse_key_value
      IMPORTING iv_line    TYPE string
                iv_line_no TYPE i
      RAISING   zcx_toml_error.

    METHODS split_key_segments
      IMPORTING iv_key             TYPE string
                iv_line_no         TYPE i
      RETURNING VALUE(rt_segments) TYPE zif_toml_types=>ty_string_table
      RAISING   zcx_toml_error.

    METHODS unquote_key_segment
      IMPORTING iv_segment      TYPE string
      RETURNING VALUE(rv_plain) TYPE string
      RAISING   zcx_toml_error.

    METHODS ensure_table_path
      IMPORTING it_segments     TYPE zif_toml_types=>ty_string_table
                iv_define       TYPE abap_bool
                iv_line_no      TYPE i
      RETURNING VALUE(rv_table) TYPE i
      RAISING   zcx_toml_error.

    METHODS find_child
      IMPORTING iv_parent    TYPE i
                iv_name      TYPE string
      RETURNING VALUE(rv_id) TYPE i.

    METHODS add_table_node
      IMPORTING iv_parent    TYPE i
                iv_name      TYPE string
      RETURNING VALUE(rv_id) TYPE i.

    METHODS parse_value_into
      IMPORTING iv_parent  TYPE i
                iv_name    TYPE string
                iv_raw     TYPE string
                iv_line_no TYPE i
      RAISING   zcx_toml_error.

    METHODS parse_quoted_string_into
      IMPORTING iv_parent  TYPE i
                iv_name    TYPE string
                iv_trim    TYPE string
                iv_line_no TYPE i
      RAISING   zcx_toml_error.

    METHODS parse_array_value_into
      IMPORTING iv_parent  TYPE i
                iv_name    TYPE string
                iv_trim    TYPE string
                iv_line_no TYPE i
      RAISING   zcx_toml_error.

    METHODS parse_inline_table_into
      IMPORTING iv_parent  TYPE i
                iv_name    TYPE string
                iv_trim    TYPE string
                iv_line_no TYPE i
      RAISING   zcx_toml_error.

    METHODS parse_scalar_value_into
      IMPORTING iv_parent  TYPE i
                iv_name    TYPE string
                iv_trim    TYPE string
                iv_line_no TYPE i
      RAISING   zcx_toml_error.

    METHODS is_float_like
      IMPORTING iv_trim            TYPE string
      RETURNING VALUE(rv_is_float) TYPE abap_bool.

    METHODS parse_multiline_string_into
      IMPORTING iv_parent  TYPE i
                iv_name    TYPE string
                iv_raw     TYPE string
                iv_line_no TYPE i
      RAISING   zcx_toml_error.

    METHODS split_top_level
      IMPORTING iv_text         TYPE string
                iv_delim        TYPE c
      RETURNING VALUE(rt_parts) TYPE zif_toml_types=>ty_string_table.

    METHODS unescape_basic
      IMPORTING iv_inner        TYPE string
                iv_line_no      TYPE i
      RETURNING VALUE(rv_plain) TYPE string
      RAISING   zcx_toml_error.

    METHODS is_datetime_like
      IMPORTING iv_raw                TYPE string
      RETURNING VALUE(rv_is_datetime) TYPE abap_bool.

    METHODS is_bare_date
      IMPORTING iv_raw            TYPE string
      RETURNING VALUE(rv_is_date) TYPE abap_bool.

    METHODS classify_datetime
      IMPORTING iv_raw         TYPE string
      RETURNING VALUE(rv_kind) TYPE string.

    METHODS normalize_integer
      IMPORTING iv_raw           TYPE string
                iv_line_no       TYPE i
      RETURNING VALUE(rv_normal) TYPE string
      RAISING   zcx_toml_error.

    METHODS normalize_float
      IMPORTING iv_raw           TYPE string
      RETURNING VALUE(rv_normal) TYPE string.

    METHODS trim_both
      IMPORTING iv_text           TYPE string
      RETURNING VALUE(rv_trimmed) TYPE string.
ENDCLASS.


CLASS zcl_toml_parser IMPLEMENTATION.
  METHOD parse.
    init_root( ).
    mv_current = 0.
    DATA(lt_lines) = to_logical_lines( iv_toml ).
    parse_document( lt_lines ).
    rt_nodes = mt_nodes.
  ENDMETHOD.

  METHOD init_root.
    CLEAR mt_nodes.
    mv_next_id = 1.
    DATA(ls_node) = VALUE zif_toml_types=>ty_node( id     = 0
                                                   parent = -1
                                                   name   = ''
                                                   kind   = zif_toml_types=>c_kind_table
                                                   value  = '' ).
    INSERT ls_node INTO TABLE mt_nodes.
  ENDMETHOD.

  METHOD to_logical_lines.
    DATA lv_normalized TYPE string.
    DATA lv_line       TYPE string.
    DATA lv_buffer     TYPE string.
    DATA lv_depth      TYPE i.
    DATA lv_in_multi   TYPE string.
    DATA lv_in_str     TYPE c LENGTH 1.
    DATA lv_in_lit     TYPE c LENGTH 1.
    DATA lv_escaped    TYPE abap_bool.
    DATA lv_idx        TYPE i.
    DATA lv_len        TYPE i.
    DATA lv_char       TYPE c LENGTH 1.
    DATA lv_next3      TYPE string.

    lv_normalized = iv_text.
    REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>cr_lf IN lv_normalized WITH cl_abap_char_utilities=>newline.
    REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>cr_lf(1) IN lv_normalized WITH cl_abap_char_utilities=>newline.
    SPLIT lv_normalized AT cl_abap_char_utilities=>newline INTO TABLE rt_lines.
    DATA(lt_joined) = VALUE zif_toml_types=>ty_string_table( ).
    CLEAR lv_buffer.
    lv_depth = 0.
    CLEAR lv_in_multi.

    LOOP AT rt_lines INTO lv_line.
      IF lv_buffer IS INITIAL.
        lv_buffer = lv_line.
      ELSE.
        lv_buffer = lv_buffer && cl_abap_char_utilities=>newline && lv_line.
      ENDIF.
      lv_idx = 0.
      lv_len = strlen( lv_buffer ).
      lv_depth = 0.
      lv_in_str = ''.
      lv_in_lit = ''.
      lv_escaped = abap_false.
      CLEAR lv_in_multi.
      WHILE lv_idx < lv_len.
        lv_char = substring( val = lv_buffer
                             off = lv_idx
                             len = 1 ).
        IF lv_idx + 3 <= lv_len.
          lv_next3 = substring( val = lv_buffer
                                off = lv_idx
                                len = 3 ).
        ELSE.
          CLEAR lv_next3.
        ENDIF.
        IF lv_in_multi IS NOT INITIAL.
          IF lv_next3 = lv_in_multi.
            CLEAR lv_in_multi.
            lv_idx += 3.
            CONTINUE.
          ENDIF.
          lv_idx += 1.
          CONTINUE.
        ENDIF.
        IF lv_escaped = abap_true.
          lv_escaped = abap_false.
          lv_idx += 1.
          CONTINUE.
        ENDIF.
        IF lv_in_str = 'X'.
          CASE lv_char.
            WHEN '\'.
              lv_escaped = abap_true.
            WHEN '"'.
              CLEAR lv_in_str.
          ENDCASE.
          lv_idx += 1.
          CONTINUE.
        ENDIF.
        IF lv_in_lit = 'X'.
          IF lv_char = `'`.
            CLEAR lv_in_lit.
          ENDIF.
          lv_idx += 1.
          CONTINUE.
        ENDIF.
        IF lv_next3 = '"""' OR lv_next3 = `'''`.
          lv_in_multi = lv_next3.
          lv_idx += 3.
          CONTINUE.
        ENDIF.
        CASE lv_char.
          WHEN '"'.
            lv_in_str = 'X'.
          WHEN `'`.
            lv_in_lit = 'X'.
          WHEN '[' OR '{'.
            lv_depth += 1.
          WHEN ']' OR '}'.
            IF lv_depth > 0.
              lv_depth -= 1.
            ENDIF.
        ENDCASE.
        lv_idx += 1.
      ENDWHILE.
      IF lv_in_multi IS INITIAL AND lv_depth = 0 AND lv_in_str IS INITIAL AND lv_in_lit IS INITIAL.
        INSERT lv_buffer INTO TABLE lt_joined.
        CLEAR lv_buffer.
      ENDIF.
    ENDLOOP.
    IF lv_buffer IS NOT INITIAL.
      INSERT lv_buffer INTO TABLE lt_joined.
    ENDIF.
    rt_lines = lt_joined.
  ENDMETHOD.

  METHOD strip_comment.
    DATA lv_idx     TYPE i.
    DATA lv_len     TYPE i.
    DATA lv_char    TYPE string.
    DATA lv_in_str  TYPE c LENGTH 1.
    DATA lv_in_lit  TYPE c LENGTH 1.
    DATA lv_in_com  TYPE abap_bool.
    DATA lv_escaped TYPE abap_bool.
    DATA lv_out     TYPE string.

    lv_len = strlen( iv_line ).
    CLEAR lv_in_str.
    CLEAR lv_in_lit.
    lv_in_com = abap_false.
    lv_escaped = abap_false.
    lv_idx = 0.
    CLEAR lv_out.
    WHILE lv_idx < lv_len.
      lv_char = substring( val = iv_line
                           off = lv_idx
                           len = 1 ).
      IF lv_in_com = abap_true.
        IF lv_char = cl_abap_char_utilities=>newline.
          lv_in_com = abap_false.
          lv_out = |{ lv_out }{ lv_char }|.
        ENDIF.
        lv_idx += 1.
        CONTINUE.
      ENDIF.
      IF lv_escaped = abap_true.
        lv_out = |{ lv_out }{ lv_char }|.
        lv_escaped = abap_false.
        lv_idx += 1.
        CONTINUE.
      ENDIF.
      IF lv_in_str = 'X'.
        lv_out = |{ lv_out }{ lv_char }|.
        CASE lv_char.
          WHEN '\'.
            lv_escaped = abap_true.
          WHEN '"'.
            CLEAR lv_in_str.
        ENDCASE.
        lv_idx += 1.
        CONTINUE.
      ENDIF.
      IF lv_in_lit = 'X'.
        lv_out = |{ lv_out }{ lv_char }|.
        IF lv_char = `'`.
          CLEAR lv_in_lit.
        ENDIF.
        lv_idx += 1.
        CONTINUE.
      ENDIF.
      CASE lv_char.
        WHEN '"'.
          lv_in_str = 'X'.
          lv_out = |{ lv_out }{ lv_char }|.
        WHEN `'`.
          lv_in_lit = 'X'.
          lv_out = |{ lv_out }{ lv_char }|.
        WHEN '#'.
          lv_in_com = abap_true.
        WHEN OTHERS.
          lv_out = |{ lv_out }{ lv_char }|.
      ENDCASE.
      lv_idx += 1.
    ENDWHILE.
    rv_line = lv_out.
  ENDMETHOD.

  METHOD parse_document.
    DATA lv_line    TYPE string.
    DATA lv_clean   TYPE string.
    DATA lv_trimmed TYPE string.
    DATA lv_no      TYPE i.

    lv_no = 0.
    LOOP AT it_lines INTO lv_line.
      lv_no += 1.
      lv_clean = strip_comment( lv_line ).
      lv_trimmed = trim_both( lv_clean ).
      IF lv_trimmed IS INITIAL.
        CONTINUE.
      ENDIF.
      IF lv_trimmed CP '[[*'.
        parse_array_table_header( iv_line    = lv_trimmed
                                  iv_line_no = lv_no ).
      ELSEIF lv_trimmed CP '[*'.
        parse_table_header( iv_line    = lv_trimmed
                            iv_line_no = lv_no ).
      ELSE.
        parse_key_value( iv_line    = lv_trimmed
                         iv_line_no = lv_no ).
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD parse_table_header.
    DATA lv_inner    TYPE string.
    DATA lv_len      TYPE i.
    DATA lt_segments TYPE zif_toml_types=>ty_string_table.

    lv_len = strlen( iv_line ).
    IF lv_len < 2 OR substring( val = iv_line
                                off = lv_len - 1
                                len = 1 ) <> ']'.
      RAISE EXCEPTION NEW zcx_toml_error( iv_text = |Invalid table header: { iv_line }|
                                          iv_line = iv_line_no ).
    ENDIF.
    lv_inner = substring( val = iv_line
                          off = 1
                          len = lv_len - 2 ).
    lv_inner = trim_both( lv_inner ).
    IF lv_inner IS INITIAL.
      RAISE EXCEPTION NEW zcx_toml_error( iv_text = 'Empty table header'
                                          iv_line = iv_line_no ).
    ENDIF.
    lt_segments = split_key_segments( iv_key     = lv_inner
                                      iv_line_no = iv_line_no ).
    mv_current = ensure_table_path( it_segments = lt_segments
                                    iv_define   = abap_true
                                    iv_line_no  = iv_line_no ).
  ENDMETHOD.

  METHOD parse_array_table_header.
    DATA lv_inner     TYPE string.
    DATA lv_len       TYPE i.
    DATA lt_segments  TYPE zif_toml_types=>ty_string_table.
    DATA lv_last      TYPE string.
    DATA lt_parents   TYPE zif_toml_types=>ty_string_table.
    DATA lv_parent_id TYPE i.
    DATA lv_arr_id    TYPE i.
    DATA lv_new_id    TYPE i.
    DATA lv_idx       TYPE i.
    DATA ls_found     TYPE zif_toml_types=>ty_node.
    DATA lv_saved_cur TYPE i.

    lv_len = strlen( iv_line ).
    IF lv_len < 4 OR substring( val = iv_line
                                off = lv_len - 2
                                len = 2 ) <> ']]'.
      RAISE EXCEPTION NEW zcx_toml_error( iv_text = |Invalid array table header: { iv_line }|
                                          iv_line = iv_line_no ).
    ENDIF.
    lv_inner = substring( val = iv_line
                          off = 2
                          len = lv_len - 4 ).
    lv_inner = trim_both( lv_inner ).
    lt_segments = split_key_segments( iv_key     = lv_inner
                                      iv_line_no = iv_line_no ).
    IF lines( lt_segments ) = 0.
      RAISE EXCEPTION NEW zcx_toml_error( iv_text = 'Empty array table header'
                                          iv_line = iv_line_no ).
    ENDIF.
    CLEAR lt_parents.
    DO lines( lt_segments ) - 1 TIMES.
      lv_idx = sy-index.
      lv_last = lt_segments[ lv_idx ].
      INSERT lv_last INTO TABLE lt_parents.
    ENDDO.
    lv_last = lt_segments[ lines( lt_segments ) ].
    lv_saved_cur = mv_current.
    mv_current = 0.
    IF lt_parents IS INITIAL.
      lv_parent_id = 0.
    ELSE.
      lv_parent_id = ensure_table_path( it_segments = lt_parents
                                        iv_define   = abap_false
                                        iv_line_no  = iv_line_no ).
    ENDIF.
    mv_current = lv_saved_cur.
    lv_arr_id = find_child( iv_parent = lv_parent_id
                            iv_name   = lv_last ).
    IF lv_arr_id = 0.
      lv_arr_id = mv_next_id.
      mv_next_id += 1.
      INSERT VALUE zif_toml_types=>ty_node( id     = lv_arr_id
                                            parent = lv_parent_id
                                            name   = lv_last
                                            kind   = zif_toml_types=>c_kind_array
                                            value  = '' ) INTO TABLE mt_nodes.
    ELSE.
      READ TABLE mt_nodes INTO ls_found WITH KEY id = lv_arr_id.
      IF sy-subrc <> 0.
        RAISE EXCEPTION NEW zcx_toml_error( iv_text = 'Internal error: array node missing'
                                            iv_line = iv_line_no ).
      ENDIF.
      IF ls_found-kind <> zif_toml_types=>c_kind_array.
        RAISE EXCEPTION NEW zcx_toml_error( iv_text = |Name conflict, not an array table: { lv_last }|
                                            iv_line = iv_line_no ).
      ENDIF.
    ENDIF.
    lv_new_id = mv_next_id.
    mv_next_id += 1.
    INSERT VALUE zif_toml_types=>ty_node( id     = lv_new_id
                                          parent = lv_arr_id
                                          name   = ''
                                          kind   = zif_toml_types=>c_kind_table
                                          value  = '' ) INTO TABLE mt_nodes.
    mv_current = lv_new_id.
  ENDMETHOD.

  METHOD parse_key_value.
    DATA lv_eq        TYPE i.
    DATA lv_key       TYPE string.
    DATA lv_raw       TYPE string.
    DATA lt_segments  TYPE zif_toml_types=>ty_string_table.
    DATA lv_last      TYPE string.
    DATA lt_parents   TYPE zif_toml_types=>ty_string_table.
    DATA lv_parent_id TYPE i.
    DATA lv_idx       TYPE i.

    FIND FIRST OCCURRENCE OF '=' IN iv_line MATCH OFFSET lv_eq.
    IF sy-subrc <> 0.
      RAISE EXCEPTION NEW zcx_toml_error( iv_text = |Missing '=' in line: { iv_line }|
                                          iv_line = iv_line_no ).
    ENDIF.
    lv_key = trim_both( substring( val = iv_line
                                   off = 0
                                   len = lv_eq ) ).
    lv_raw = trim_both( substring( val = iv_line
                                   off = lv_eq + 1 ) ).
    IF lv_key IS INITIAL OR lv_raw IS INITIAL.
      RAISE EXCEPTION NEW zcx_toml_error( iv_text = |Invalid key-value line: { iv_line }|
                                          iv_line = iv_line_no ).
    ENDIF.
    lt_segments = split_key_segments( iv_key     = lv_key
                                      iv_line_no = iv_line_no ).
    IF lines( lt_segments ) = 0.
      RAISE EXCEPTION NEW zcx_toml_error( iv_text = |Empty key: { iv_line }|
                                          iv_line = iv_line_no ).
    ENDIF.
    CLEAR lt_parents.
    DO lines( lt_segments ) - 1 TIMES.
      lv_idx = sy-index.
      lv_last = lt_segments[ lv_idx ].
      INSERT lv_last INTO TABLE lt_parents.
    ENDDO.
    lv_last = lt_segments[ lines( lt_segments ) ].
    IF lt_parents IS INITIAL.
      lv_parent_id = mv_current.
    ELSE.
      lv_parent_id = ensure_table_path( it_segments = lt_parents
                                        iv_define   = abap_false
                                        iv_line_no  = iv_line_no ).
    ENDIF.
    lv_last = lt_segments[ lines( lt_segments ) ].
    IF find_child( iv_parent = lv_parent_id
                   iv_name   = lv_last ) <> 0.
      RAISE EXCEPTION NEW zcx_toml_error( iv_text = |Duplicate key: { lv_last }|
                                          iv_line = iv_line_no ).
    ENDIF.
    parse_value_into( iv_parent  = lv_parent_id
                      iv_name    = lv_last
                      iv_raw     = lv_raw
                      iv_line_no = iv_line_no ).
  ENDMETHOD.

  METHOD split_key_segments.
    DATA lv_idx    TYPE i.
    DATA lv_len    TYPE i.
    DATA lv_char   TYPE c LENGTH 1.
    DATA lv_buf    TYPE string.
    DATA lv_in_str TYPE c LENGTH 1.
    DATA lv_in_lit TYPE c LENGTH 1.
    DATA lv_plain  TYPE string.

    lv_len = strlen( iv_key ).
    lv_idx = 0.
    CLEAR lv_buf.
    CLEAR lv_in_str.
    CLEAR lv_in_lit.
    WHILE lv_idx < lv_len.
      lv_char = substring( val = iv_key
                           off = lv_idx
                           len = 1 ).
      IF lv_in_str = 'X'.
        lv_buf = lv_buf && lv_char.
        IF lv_char = '"'.
          CLEAR lv_in_str.
        ENDIF.
        lv_idx += 1.
        CONTINUE.
      ENDIF.
      IF lv_in_lit = 'X'.
        lv_buf = lv_buf && lv_char.
        IF lv_char = `'`.
          CLEAR lv_in_lit.
        ENDIF.
        lv_idx += 1.
        CONTINUE.
      ENDIF.
      CASE lv_char.
        WHEN '"'.
          lv_in_str = 'X'.
          lv_buf = lv_buf && lv_char.
        WHEN `'`.
          lv_in_lit = 'X'.
          lv_buf = lv_buf && lv_char.
        WHEN '.'.
          lv_plain = trim_both( lv_buf ).
          IF lv_plain IS INITIAL.
            RAISE EXCEPTION NEW zcx_toml_error( iv_text = |Empty key segment in: { iv_key }|
                                                iv_line = iv_line_no ).
          ENDIF.
          INSERT unquote_key_segment( lv_plain ) INTO TABLE rt_segments.
          CLEAR lv_buf.
        WHEN OTHERS.
          lv_buf = lv_buf && lv_char.
      ENDCASE.
      lv_idx += 1.
    ENDWHILE.
    lv_plain = trim_both( lv_buf ).
    IF lv_plain IS INITIAL.
      RAISE EXCEPTION NEW zcx_toml_error( iv_text = |Empty key segment in: { iv_key }|
                                          iv_line = iv_line_no ).
    ENDIF.
    INSERT unquote_key_segment( lv_plain ) INTO TABLE rt_segments.
  ENDMETHOD.

  METHOD unquote_key_segment.
    DATA lv_len TYPE i.

    lv_len = strlen( iv_segment ).
    IF     lv_len >= 2 AND substring( val = iv_segment
                                      off = 0
                                      len = 1 ) = '"'
       AND substring( val = iv_segment
                      off = lv_len - 1
                      len = 1 )         = '"'.
      rv_plain = substring( val = iv_segment
                            off = 1
                            len = lv_len - 2 ).
      rv_plain = unescape_basic( iv_inner   = rv_plain
                                 iv_line_no = 0 ).
      RETURN.
    ENDIF.
    IF     lv_len >= 2 AND substring( val = iv_segment
                                      off = 0
                                      len = 1 ) = `'`
       AND substring( val = iv_segment
                      off = lv_len - 1
                      len = 1 )         = `'`.
      rv_plain = substring( val = iv_segment
                            off = 1
                            len = lv_len - 2 ).
      RETURN.
    ENDIF.
    rv_plain = iv_segment.
  ENDMETHOD.

  METHOD ensure_table_path.
    DATA lv_cur          TYPE i.
    DATA lv_seg          TYPE string.
    DATA lv_found        TYPE i.
    DATA ls_node         TYPE zif_toml_types=>ty_node.
    DATA lt_arr_children TYPE zif_toml_types=>ty_nodes.
    DATA ls_arr_child    TYPE zif_toml_types=>ty_node.

    lv_cur = 0.
    IF mv_current <> 0 AND iv_define = abap_false.
      lv_cur = mv_current.
    ENDIF.
    IF iv_define = abap_true.
      lv_cur = 0.
    ENDIF.
    LOOP AT it_segments INTO lv_seg.
      lv_found = find_child( iv_parent = lv_cur
                             iv_name   = lv_seg ).
      IF lv_found = 0.
        lv_found = add_table_node( iv_parent = lv_cur
                                   iv_name   = lv_seg ).
      ELSE.
        READ TABLE mt_nodes INTO ls_node WITH KEY id = lv_found.
        IF sy-subrc <> 0.
          RAISE EXCEPTION NEW zcx_toml_error( iv_text = 'Internal error: table node missing'
                                              iv_line = iv_line_no ).
        ENDIF.
        IF ls_node-kind = zif_toml_types=>c_kind_array.
          CLEAR lt_arr_children.
          LOOP AT mt_nodes INTO ls_arr_child WHERE parent = lv_found.
            INSERT ls_arr_child INTO TABLE lt_arr_children.
          ENDLOOP.
          IF lines( lt_arr_children ) > 0.
            SORT lt_arr_children BY id DESCENDING.
            lv_found = lt_arr_children[ 1 ]-id.
          ELSE.
            RAISE EXCEPTION NEW zcx_toml_error( iv_text = |Array table empty: { lv_seg }|
                                                iv_line = iv_line_no ).
          ENDIF.
        ELSEIF ls_node-kind <> zif_toml_types=>c_kind_table.
          RAISE EXCEPTION NEW zcx_toml_error( iv_text = |Path conflict, not a table: { lv_seg }|
                                              iv_line = iv_line_no ).
        ENDIF.
      ENDIF.
      lv_cur = lv_found.
    ENDLOOP.
    IF iv_define = abap_true.
      READ TABLE mt_nodes INTO ls_node WITH KEY id = lv_cur.
      IF sy-subrc = 0 AND ls_node-id <> 0.
        IF ls_node-value = 'defined'.
          RAISE EXCEPTION NEW zcx_toml_error( iv_text = 'Duplicate table definition'
                                              iv_line = iv_line_no ).
        ENDIF.
        ls_node-value = 'defined'.
        MODIFY mt_nodes FROM ls_node TRANSPORTING value WHERE id = lv_cur.
      ENDIF.
    ENDIF.
    rv_table = lv_cur.
  ENDMETHOD.

  METHOD find_child.
    DATA ls_node TYPE zif_toml_types=>ty_node.

    rv_id = 0.
    LOOP AT mt_nodes INTO ls_node WHERE parent = iv_parent AND name = iv_name.
      rv_id = ls_node-id.
      RETURN.
    ENDLOOP.
  ENDMETHOD.

  METHOD add_table_node.
    rv_id = mv_next_id.
    mv_next_id += 1.
    INSERT VALUE zif_toml_types=>ty_node( id     = rv_id
                                          parent = iv_parent
                                          name   = iv_name
                                          kind   = zif_toml_types=>c_kind_table
                                          value  = '' ) INTO TABLE mt_nodes.
  ENDMETHOD.

  METHOD parse_value_into.
    DATA lv_trim          TYPE string.
    DATA lv_len           TYPE i.
    DATA lv_first         TYPE string.
    DATA lv_starts_triple TYPE abap_bool.

    lv_trim = trim_both( iv_raw ).
    lv_len = strlen( lv_trim ).
    IF lv_len = 0.
      RAISE EXCEPTION NEW zcx_toml_error( iv_text = 'Empty value'
                                          iv_line = iv_line_no ).
    ENDIF.
    lv_first = substring( val = lv_trim
                          off = 0
                          len = 1 ).
    lv_starts_triple = abap_false.
    IF lv_len >= 3 AND substring( val = lv_trim
                                  off = 0
                                  len = 3 ) = '"""'.
      lv_starts_triple = abap_true.
    ENDIF.
    IF lv_len >= 3 AND substring( val = lv_trim
                                  off = 0
                                  len = 3 ) = `'''`.
      lv_starts_triple = abap_true.
    ENDIF.
    IF lv_starts_triple = abap_true.
      parse_multiline_string_into( iv_parent  = iv_parent
                                   iv_name    = iv_name
                                   iv_raw     = lv_trim
                                   iv_line_no = iv_line_no ).
      RETURN.
    ENDIF.
    CASE lv_first.
      WHEN '"'.
        parse_quoted_string_into( iv_parent  = iv_parent
                                  iv_name    = iv_name
                                  iv_trim    = lv_trim
                                  iv_line_no = iv_line_no ).
      WHEN `'`.
        parse_quoted_string_into( iv_parent  = iv_parent
                                  iv_name    = iv_name
                                  iv_trim    = lv_trim
                                  iv_line_no = iv_line_no ).
      WHEN '['.
        parse_array_value_into( iv_parent  = iv_parent
                                iv_name    = iv_name
                                iv_trim    = lv_trim
                                iv_line_no = iv_line_no ).
      WHEN '{'.
        parse_inline_table_into( iv_parent  = iv_parent
                                 iv_name    = iv_name
                                 iv_trim    = lv_trim
                                 iv_line_no = iv_line_no ).
      WHEN OTHERS.
        parse_scalar_value_into( iv_parent  = iv_parent
                                 iv_name    = iv_name
                                 iv_trim    = lv_trim
                                 iv_line_no = iv_line_no ).
    ENDCASE.
  ENDMETHOD.

  METHOD parse_quoted_string_into.
    DATA lv_len    TYPE i.
    DATA lv_inner  TYPE string.
    DATA lv_normal TYPE string.

    lv_len = strlen( iv_trim ).
    IF substring( val = iv_trim
                  off = 0
                  len = 1 ) = '"'.
      IF lv_len < 2 OR substring( val = iv_trim
                                  off = lv_len - 1
                                  len = 1 ) <> '"'.
        RAISE EXCEPTION NEW zcx_toml_error( iv_text = |Unterminated string: { iv_trim }|
                                            iv_line = iv_line_no ).
      ENDIF.
      lv_inner = substring( val = iv_trim
                            off = 1
                            len = lv_len - 2 ).
      lv_normal = unescape_basic( iv_inner   = lv_inner
                                  iv_line_no = iv_line_no ).
    ELSE.
      IF lv_len < 2 OR substring( val = iv_trim
                                  off = lv_len - 1
                                  len = 1 ) <> `'`.
        RAISE EXCEPTION NEW zcx_toml_error( iv_text = |Unterminated literal: { iv_trim }|
                                            iv_line = iv_line_no ).
      ENDIF.
      lv_normal = substring( val = iv_trim
                             off = 1
                             len = lv_len - 2 ).
    ENDIF.
    INSERT VALUE zif_toml_types=>ty_node( id     = mv_next_id
                                          parent = iv_parent
                                          name   = iv_name
                                          kind   = zif_toml_types=>c_kind_string
                                          value  = lv_normal ) INTO TABLE mt_nodes.
    mv_next_id += 1.
  ENDMETHOD.

  METHOD parse_array_value_into.
    DATA lv_len    TYPE i.
    DATA lv_arr_id TYPE i.
    DATA lt_parts  TYPE zif_toml_types=>ty_string_table.
    DATA lv_part   TYPE string.
    DATA lv_elem   TYPE string.
    DATA lv_inner  TYPE string.

    lv_len = strlen( iv_trim ).
    IF substring( val = iv_trim
                  off = lv_len - 1
                  len = 1 ) <> ']'.
      RAISE EXCEPTION NEW zcx_toml_error( iv_text = |Unterminated array: { iv_trim }|
                                          iv_line = iv_line_no ).
    ENDIF.
    lv_arr_id = mv_next_id.
    mv_next_id += 1.
    INSERT VALUE zif_toml_types=>ty_node( id     = lv_arr_id
                                          parent = iv_parent
                                          name   = iv_name
                                          kind   = zif_toml_types=>c_kind_array
                                          value  = '' ) INTO TABLE mt_nodes.
    lv_inner = substring( val = iv_trim
                          off = 1
                          len = lv_len - 2 ).
    lv_inner = trim_both( lv_inner ).
    IF lv_inner IS INITIAL.
      RETURN.
    ENDIF.
    lt_parts = split_top_level( iv_text  = lv_inner
                                iv_delim = ',' ).
    LOOP AT lt_parts INTO lv_part.
      lv_elem = trim_both( lv_part ).
      IF lv_elem IS INITIAL.
        CONTINUE.
      ENDIF.
      IF substring( val = lv_elem
                    off = 0
                    len = 1 ) = '#'.
        CONTINUE.
      ENDIF.
      parse_value_into( iv_parent  = lv_arr_id
                        iv_name    = ''
                        iv_raw     = lv_elem
                        iv_line_no = iv_line_no ).
    ENDLOOP.
  ENDMETHOD.

  METHOD parse_inline_table_into.
    DATA lv_len    TYPE i.
    DATA lv_tab_id TYPE i.
    DATA lt_parts  TYPE zif_toml_types=>ty_string_table.
    DATA lv_part   TYPE string.
    DATA lv_elem   TYPE string.
    DATA lv_inner  TYPE string.
    DATA lv_saved  TYPE i.

    lv_len = strlen( iv_trim ).
    IF substring( val = iv_trim
                  off = lv_len - 1
                  len = 1 ) <> '}'.
      RAISE EXCEPTION NEW zcx_toml_error( iv_text = |Unterminated inline table: { iv_trim }|
                                          iv_line = iv_line_no ).
    ENDIF.
    lv_tab_id = mv_next_id.
    mv_next_id += 1.
    INSERT VALUE zif_toml_types=>ty_node( id     = lv_tab_id
                                          parent = iv_parent
                                          name   = iv_name
                                          kind   = zif_toml_types=>c_kind_table
                                          value  = 'inline' ) INTO TABLE mt_nodes.
    lv_inner = substring( val = iv_trim
                          off = 1
                          len = lv_len - 2 ).
    lv_inner = trim_both( lv_inner ).
    IF lv_inner IS INITIAL.
      RETURN.
    ENDIF.
    lt_parts = split_top_level( iv_text  = lv_inner
                                iv_delim = ',' ).
    lv_saved = mv_current.
    mv_current = lv_tab_id.
    LOOP AT lt_parts INTO lv_part.
      lv_elem = trim_both( lv_part ).
      IF lv_elem IS INITIAL.
        CONTINUE.
      ENDIF.
      parse_key_value( iv_line    = lv_elem
                       iv_line_no = iv_line_no ).
    ENDLOOP.
    mv_current = lv_saved.
  ENDMETHOD.

  METHOD parse_scalar_value_into.
    DATA lv_kind   TYPE string.
    DATA lv_normal TYPE string.

    IF iv_trim = 'true' OR iv_trim = 'false'.
      INSERT VALUE zif_toml_types=>ty_node( id     = mv_next_id
                                            parent = iv_parent
                                            name   = iv_name
                                            kind   = zif_toml_types=>c_kind_boolean
                                            value  = iv_trim ) INTO TABLE mt_nodes.
      mv_next_id += 1.
      RETURN.
    ENDIF.
    IF is_datetime_like( iv_trim ) = abap_true.
      lv_kind = classify_datetime( iv_trim ).
      INSERT VALUE zif_toml_types=>ty_node( id     = mv_next_id
                                            parent = iv_parent
                                            name   = iv_name
                                            kind   = lv_kind
                                            value  = iv_trim ) INTO TABLE mt_nodes.
      mv_next_id += 1.
      RETURN.
    ENDIF.
    IF is_float_like( iv_trim ) = abap_true.
      lv_normal = normalize_float( iv_trim ).
      INSERT VALUE zif_toml_types=>ty_node( id     = mv_next_id
                                            parent = iv_parent
                                            name   = iv_name
                                            kind   = zif_toml_types=>c_kind_float
                                            value  = lv_normal ) INTO TABLE mt_nodes.
      mv_next_id += 1.
      RETURN.
    ENDIF.
    lv_normal = normalize_integer( iv_raw     = iv_trim
                                   iv_line_no = iv_line_no ).
    INSERT VALUE zif_toml_types=>ty_node( id     = mv_next_id
                                          parent = iv_parent
                                          name   = iv_name
                                          kind   = zif_toml_types=>c_kind_integer
                                          value  = lv_normal ) INTO TABLE mt_nodes.
    mv_next_id += 1.
  ENDMETHOD.

  METHOD is_float_like.
    DATA lv_lower TYPE string.

    rv_is_float = abap_false.
    lv_lower = to_lower( iv_trim ).
    IF lv_lower CP '0x*' OR lv_lower CP '+0x*' OR lv_lower CP '-0x*'.
      RETURN.
    ENDIF.
    IF lv_lower CP '0o*' OR lv_lower CP '0b*'.
      RETURN.
    ENDIF.
    IF iv_trim CP '*.*' OR iv_trim CP '*e*' OR iv_trim CP '*E*'.
      rv_is_float = abap_true.
      RETURN.
    ENDIF.
    IF    iv_trim = 'inf' OR iv_trim = '+inf' OR iv_trim = '-inf'
       OR iv_trim = 'nan' OR iv_trim = '+nan' OR iv_trim = '-nan'.
      rv_is_float = abap_true.
    ENDIF.
  ENDMETHOD.

  METHOD parse_multiline_string_into.
    DATA lv_len      TYPE i.
    DATA lv_is_basic TYPE abap_bool.
    DATA lv_inner    TYPE string.
    DATA lv_plain    TYPE string.
    DATA lv_nl       TYPE string.

    lv_len = strlen( iv_raw ).
    lv_nl = cl_abap_char_utilities=>newline.
    IF     lv_len >= 6 AND substring( val = iv_raw
                                      off = 0
                                      len = 3 ) = '"""'
       AND substring( val = iv_raw
                      off = lv_len - 3
                      len = 3 )         = '"""'.
      lv_is_basic = abap_true.
      lv_inner = substring( val = iv_raw
                            off = 3
                            len = lv_len - 6 ).
    ELSEIF     lv_len >= 6 AND substring( val = iv_raw
                                          off = 0
                                          len = 3 ) = `'''`
           AND substring( val = iv_raw
                          off = lv_len - 3
                          len = 3 )         = `'''`.
      lv_is_basic = abap_false.
      lv_inner = substring( val = iv_raw
                            off = 3
                            len = lv_len - 6 ).
    ELSE.
      RAISE EXCEPTION NEW zcx_toml_error( iv_text = |Unterminated multi-line string|
                                          iv_line = iv_line_no ).
    ENDIF.
    IF substring( val = lv_inner
                  off = 0
                  len = 1 ) = lv_nl.
      lv_inner = substring( val = lv_inner
                            off = 1 ).
    ENDIF.
    IF lv_is_basic = abap_true.
      lv_plain = unescape_basic( iv_inner   = lv_inner
                                 iv_line_no = iv_line_no ).
    ELSE.
      lv_plain = lv_inner.
    ENDIF.
    INSERT VALUE zif_toml_types=>ty_node( id     = mv_next_id
                                          parent = iv_parent
                                          name   = iv_name
                                          kind   = zif_toml_types=>c_kind_string
                                          value  = lv_plain ) INTO TABLE mt_nodes.
    mv_next_id += 1.
  ENDMETHOD.

  METHOD split_top_level.
    DATA lv_idx     TYPE i.
    DATA lv_len     TYPE i.
    DATA lv_char    TYPE c LENGTH 1.
    DATA lv_buf     TYPE string.
    DATA lv_depth_b TYPE i.
    DATA lv_depth_c TYPE i.
    DATA lv_in_str  TYPE c LENGTH 1.
    DATA lv_in_lit  TYPE c LENGTH 1.
    DATA lv_escaped TYPE abap_bool.

    lv_depth_b = 0.
    lv_depth_c = 0.
    CLEAR lv_in_str.
    CLEAR lv_in_lit.
    lv_escaped = abap_false.
    lv_len = strlen( iv_text ).
    lv_idx = 0.
    WHILE lv_idx < lv_len.
      lv_char = substring( val = iv_text
                           off = lv_idx
                           len = 1 ).
      IF lv_escaped = abap_true.
        lv_buf = lv_buf && lv_char.
        lv_escaped = abap_false.
        lv_idx += 1.
        CONTINUE.
      ENDIF.
      IF lv_in_str = 'X'.
        lv_buf = lv_buf && lv_char.
        CASE lv_char.
          WHEN '\'.
            lv_escaped = abap_true.
          WHEN '"'.
            CLEAR lv_in_str.
        ENDCASE.
        lv_idx += 1.
        CONTINUE.
      ENDIF.
      IF lv_in_lit = 'X'.
        lv_buf = lv_buf && lv_char.
        IF lv_char = `'`.
          CLEAR lv_in_lit.
        ENDIF.
        lv_idx += 1.
        CONTINUE.
      ENDIF.
      CASE lv_char.
        WHEN '"'.
          lv_in_str = 'X'.
          lv_buf = lv_buf && lv_char.
        WHEN `'`.
          lv_in_lit = 'X'.
          lv_buf = lv_buf && lv_char.
        WHEN '[' OR '{'.
          CASE lv_char.
            WHEN '['.
              lv_depth_b += 1.
            WHEN OTHERS.
              lv_depth_c += 1.
          ENDCASE.
          lv_buf = lv_buf && lv_char.
        WHEN ']' OR '}'.
          CASE lv_char.
            WHEN ']'.
              lv_depth_b -= 1.
            WHEN OTHERS.
              lv_depth_c -= 1.
          ENDCASE.
          lv_buf = lv_buf && lv_char.
        WHEN OTHERS.
          IF lv_char = iv_delim AND lv_depth_b = 0 AND lv_depth_c = 0.
            INSERT lv_buf INTO TABLE rt_parts.
            CLEAR lv_buf.
          ELSE.
            lv_buf = lv_buf && lv_char.
          ENDIF.
      ENDCASE.
      lv_idx += 1.
    ENDWHILE.
    INSERT lv_buf INTO TABLE rt_parts.
  ENDMETHOD.

  METHOD unescape_basic.
    DATA lv_idx  TYPE i.
    DATA lv_len  TYPE i.
    DATA lv_char TYPE string.
    DATA lv_next TYPE string.
    DATA lv_hex  TYPE string.

    lv_len = strlen( iv_inner ).
    lv_idx = 0.
    CLEAR rv_plain.
    WHILE lv_idx < lv_len.
      lv_char = substring( val = iv_inner
                           off = lv_idx
                           len = 1 ).
      IF lv_char <> '\'.
        rv_plain = |{ rv_plain }{ lv_char }|.
        lv_idx += 1.
        CONTINUE.
      ENDIF.
      IF lv_idx + 1 >= lv_len.
        RAISE EXCEPTION NEW zcx_toml_error( iv_text = 'Trailing backslash in string'
                                            iv_line = iv_line_no ).
      ENDIF.
      lv_next = substring( val = iv_inner
                           off = lv_idx + 1
                           len = 1 ).
      CASE lv_next.
        WHEN 'n'.
          rv_plain = rv_plain && cl_abap_char_utilities=>newline.
        WHEN 't'.
          rv_plain = rv_plain && cl_abap_char_utilities=>horizontal_tab.
        WHEN 'r'.
          rv_plain = rv_plain && cl_abap_char_utilities=>cr_lf(1).
        WHEN 'b'.
          rv_plain = rv_plain && cl_abap_char_utilities=>newline.
        WHEN 'f'.
          rv_plain = rv_plain && cl_abap_char_utilities=>newline.
        WHEN '\' OR '"' OR '/'.
          rv_plain = rv_plain && lv_next.
        WHEN 'u' OR 'U'.
          IF lv_next = 'u'.
            IF lv_idx + 6 > lv_len.
              RAISE EXCEPTION NEW zcx_toml_error( iv_text = 'Bad unicode escape'
                                                  iv_line = iv_line_no ).
            ENDIF.
            lv_hex = substring( val = iv_inner
                                off = lv_idx + 2
                                len = 4 ).
            rv_plain = rv_plain && lv_hex.
            lv_idx += 4.
          ELSE.
            IF lv_idx + 10 > lv_len.
              RAISE EXCEPTION NEW zcx_toml_error( iv_text = 'Bad unicode escape'
                                                  iv_line = iv_line_no ).
            ENDIF.
            lv_hex = substring( val = iv_inner
                                off = lv_idx + 2
                                len = 8 ).
            rv_plain = rv_plain && lv_hex.
            lv_idx += 8.
          ENDIF.
        WHEN OTHERS.
          RAISE EXCEPTION NEW zcx_toml_error( iv_text = |Bad escape: \\{ lv_next }|
                                              iv_line = iv_line_no ).
      ENDCASE.
      lv_idx += 2.
    ENDWHILE.
  ENDMETHOD.

  METHOD is_datetime_like.
    DATA lv_tmp TYPE string.

    rv_is_datetime = abap_false.
    lv_tmp = trim_both( iv_raw ).
    IF strlen( lv_tmp ) < 3.
      RETURN.
    ENDIF.
    IF is_bare_date( lv_tmp ) = abap_true.
      rv_is_datetime = abap_true.
      RETURN.
    ENDIF.
    IF lv_tmp CP '*-*-*' AND ( lv_tmp CP '*:*' OR lv_tmp CP '*T*' OR lv_tmp CP '* *' ).
      rv_is_datetime = abap_true.
      RETURN.
    ENDIF.
    IF lv_tmp CP '*:*:*'.
      rv_is_datetime = abap_true.
    ENDIF.
  ENDMETHOD.

  METHOD is_bare_date.
    DATA lv_pos TYPE i.
    DATA lv_chr TYPE c LENGTH 1.

    rv_is_date = abap_false.
    IF strlen( iv_raw ) <> 10.
      RETURN.
    ENDIF.
    IF substring( val = iv_raw
                  off = 4
                  len = 1 ) <> '-'.
      RETURN.
    ENDIF.
    IF substring( val = iv_raw
                  off = 7
                  len = 1 ) <> '-'.
      RETURN.
    ENDIF.
    lv_pos = 0.
    WHILE lv_pos < 10.
      IF lv_pos = 4 OR lv_pos = 7.
        lv_pos += 1.
        CONTINUE.
      ENDIF.
      lv_chr = substring( val = iv_raw
                          off = lv_pos
                          len = 1 ).
      IF lv_chr < '0' OR lv_chr > '9'.
        RETURN.
      ENDIF.
      lv_pos += 1.
    ENDWHILE.
    rv_is_date = abap_true.
  ENDMETHOD.

  METHOD classify_datetime.
    IF iv_raw CP '*:*' AND iv_raw CP '*-*'.
      rv_kind = zif_toml_types=>c_kind_datetime.
    ELSEIF iv_raw CP '*-*'.
      rv_kind = zif_toml_types=>c_kind_date.
    ELSE.
      rv_kind = zif_toml_types=>c_kind_time.
    ENDIF.
  ENDMETHOD.

  METHOD normalize_integer.
    DATA lv_tmp     TYPE string.
    DATA lv_neg     TYPE abap_bool.
    DATA lv_prefix  TYPE string.
    DATA lv_pos     TYPE i.
    DATA lv_chr     TYPE c LENGTH 1.
    DATA lv_first_c TYPE c LENGTH 1.

    lv_tmp = iv_raw.
    REPLACE ALL OCCURRENCES OF '_' IN lv_tmp WITH ''.
    lv_tmp = condense( val  = lv_tmp
                       from = ` `
                       to   = `` ).
    lv_neg = abap_false.
    lv_first_c = substring( val = lv_tmp
                            off = 0
                            len = 1 ).
    IF lv_first_c = '+'.
      lv_tmp = substring( val = lv_tmp
                          off = 1 ).
    ELSEIF lv_first_c = '-'.
      lv_neg = abap_true.
      lv_tmp = substring( val = lv_tmp
                          off = 1 ).
    ENDIF.
    IF strlen( lv_tmp ) >= 2.
      lv_prefix = substring( val = lv_tmp
                             off = 0
                             len = 2 ).
      lv_prefix = to_lower( lv_prefix ).
      IF lv_prefix = '0x' OR lv_prefix = '0o' OR lv_prefix = '0b'.
        rv_normal = iv_raw.
        REPLACE ALL OCCURRENCES OF '_' IN rv_normal WITH ''.
        RETURN.
      ENDIF.
    ENDIF.
    lv_pos = 0.
    WHILE lv_pos < strlen( lv_tmp ).
      lv_chr = substring( val = lv_tmp
                          off = lv_pos
                          len = 1 ).
      IF lv_chr < '0' OR lv_chr > '9'.
        RAISE EXCEPTION NEW zcx_toml_error( iv_text = |Invalid integer: { iv_raw }|
                                            iv_line = iv_line_no ).
      ENDIF.
      lv_pos += 1.
    ENDWHILE.
    IF lv_neg = abap_true.
      rv_normal = |-{ lv_tmp }|.
    ELSE.
      rv_normal = lv_tmp.
    ENDIF.
  ENDMETHOD.

  METHOD normalize_float.
    DATA lv_tmp TYPE string.

    lv_tmp = iv_raw.
    REPLACE ALL OCCURRENCES OF '_' IN lv_tmp WITH ''.
    lv_tmp = condense( val  = lv_tmp
                       from = ` `
                       to   = `` ).
    lv_tmp = to_lower( lv_tmp ).
    rv_normal = lv_tmp.
  ENDMETHOD.

  METHOD trim_both.
    DATA lv_changed TYPE abap_bool.
    DATA lv_len     TYPE i.
    DATA lv_first   TYPE string.
    DATA lv_last    TYPE string.

    rv_trimmed = iv_text.
    lv_changed = abap_true.
    WHILE lv_changed = abap_true.
      lv_changed = abap_false.
      IF rv_trimmed IS INITIAL.
        RETURN.
      ENDIF.
      lv_len = strlen( rv_trimmed ).
      lv_first = substring( val = rv_trimmed
                            off = 0
                            len = 1 ).
      IF    lv_first = ` `
         OR lv_first = cl_abap_char_utilities=>horizontal_tab
         OR lv_first = cl_abap_char_utilities=>newline
         OR lv_first = cl_abap_char_utilities=>cr_lf(1).
        rv_trimmed = substring( val = rv_trimmed
                                off = 1 ).
        lv_changed = abap_true.
        CONTINUE.
      ENDIF.
      lv_last = substring( val = rv_trimmed
                           off = lv_len - 1
                           len = 1 ).
      IF    lv_last = ` `
         OR lv_last = cl_abap_char_utilities=>horizontal_tab
         OR lv_last = cl_abap_char_utilities=>newline
         OR lv_last = cl_abap_char_utilities=>cr_lf(1).
        rv_trimmed = substring( val = rv_trimmed
                                off = 0
                                len = lv_len - 1 ).
        lv_changed = abap_true.
        CONTINUE.
      ENDIF.
    ENDWHILE.
  ENDMETHOD.
ENDCLASS.
