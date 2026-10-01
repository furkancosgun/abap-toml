CLASS zcl_toml DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    CLASS-METHODS parse
      IMPORTING iv_toml            TYPE string
      RETURNING VALUE(rv_instance) TYPE REF TO zcl_toml
      RAISING   zcx_toml_error.

    CLASS-METHODS create_empty
      RETURNING VALUE(rv_instance) TYPE REF TO zcl_toml.

    METHODS stringify
      RETURNING VALUE(rv_toml) TYPE string
      RAISING   zcx_toml_error.

    METHODS exists
      IMPORTING iv_path          TYPE string
      RETURNING VALUE(rv_exists) TYPE abap_bool.

    METHODS get_kind
      IMPORTING iv_path        TYPE string
      RETURNING VALUE(rv_kind) TYPE string
      RAISING   zcx_toml_error.

    METHODS get_string
      IMPORTING iv_path         TYPE string
      RETURNING VALUE(rv_value) TYPE string
      RAISING   zcx_toml_error.

    METHODS get_integer
      IMPORTING iv_path         TYPE string
      RETURNING VALUE(rv_value) TYPE i
      RAISING   zcx_toml_error.

    METHODS get_float
      IMPORTING iv_path         TYPE string
      RETURNING VALUE(rv_value) TYPE f
      RAISING   zcx_toml_error.

    METHODS get_boolean
      IMPORTING iv_path         TYPE string
      RETURNING VALUE(rv_value) TYPE abap_bool
      RAISING   zcx_toml_error.

    METHODS set_string
      IMPORTING iv_path  TYPE string
                iv_value TYPE string
      RAISING   zcx_toml_error.

    METHODS set_integer
      IMPORTING iv_path  TYPE string
                iv_value TYPE i
      RAISING   zcx_toml_error.

    METHODS set_float
      IMPORTING iv_path  TYPE string
                iv_value TYPE f
      RAISING   zcx_toml_error.

    METHODS set_boolean
      IMPORTING iv_path  TYPE string
                iv_value TYPE abap_bool
      RAISING   zcx_toml_error.

    METHODS set_datetime
      IMPORTING iv_path  TYPE string
                iv_value TYPE string
      RAISING   zcx_toml_error.

    METHODS touch_table
      IMPORTING iv_path TYPE string
      RAISING   zcx_toml_error.

    METHODS touch_array
      IMPORTING iv_path TYPE string
      RAISING   zcx_toml_error.

    METHODS array_append_string
      IMPORTING iv_path  TYPE string
                iv_value TYPE string
      RAISING   zcx_toml_error.

    METHODS array_append_integer
      IMPORTING iv_path  TYPE string
                iv_value TYPE i
      RAISING   zcx_toml_error.

    METHODS array_length
      IMPORTING iv_path       TYPE string
      RETURNING VALUE(rv_len) TYPE i
      RAISING   zcx_toml_error.

    METHODS delete_node
      IMPORTING iv_path TYPE string
      RAISING   zcx_toml_error.

    METHODS clear.

    METHODS constructor
      IMPORTING iv_nodes TYPE zif_toml_types=>ty_nodes OPTIONAL.

  PRIVATE SECTION.
    DATA mv_nodes   TYPE zif_toml_types=>ty_nodes.
    DATA mv_next_id TYPE i.

    METHODS split_path
      IMPORTING iv_path            TYPE string
      RETURNING VALUE(rv_segments) TYPE zif_toml_types=>ty_string_table.

    METHODS resolve_node
      IMPORTING iv_path      TYPE string
      RETURNING VALUE(rv_id) TYPE i.

    METHODS resolve_parent
      IMPORTING iv_path        TYPE string
                iv_create      TYPE abap_bool
      EXPORTING ev_parent      TYPE i
                ev_leaf        TYPE string
                ev_leaf_is_idx TYPE abap_bool
      RAISING   zcx_toml_error.

    METHODS find_child
      IMPORTING iv_parent    TYPE i
                iv_name      TYPE string
      RETURNING VALUE(rv_id) TYPE i.

    METHODS array_child_at
      IMPORTING iv_parent    TYPE i
                iv_index     TYPE i
      RETURNING VALUE(rv_id) TYPE i.

    METHODS is_index_segment
      IMPORTING iv_segment         TYPE string
      RETURNING VALUE(rv_is_index) TYPE abap_bool.

    METHODS upsert_scalar
      IMPORTING iv_path  TYPE string
                iv_kind  TYPE string
                iv_value TYPE string
      RAISING   zcx_toml_error.

    METHODS collect_subtree
      IMPORTING iv_root             TYPE i
      RETURNING VALUE(rv_collected) TYPE zif_toml_types=>ty_nodes.
ENDCLASS.


CLASS zcl_toml IMPLEMENTATION.
  METHOD constructor.
    IF iv_nodes IS SUPPLIED AND lines( iv_nodes ) > 0.
      mv_nodes = iv_nodes.
      mv_next_id = 0.
      DATA(lv_node) = VALUE zif_toml_types=>ty_node( ).
      LOOP AT mv_nodes INTO lv_node.
        IF lv_node-id >= mv_next_id.
          mv_next_id = lv_node-id + 1.
        ENDIF.
      ENDLOOP.
    ELSE.
      CLEAR mv_nodes.
      INSERT VALUE zif_toml_types=>ty_node( id     = 0
                                            parent = -1
                                            name   = ''
                                            kind   = zif_toml_types=>c_kind_table
                                            value  = '' ) INTO TABLE mv_nodes.
      mv_next_id = 1.
    ENDIF.
  ENDMETHOD.

  METHOD parse.
    DATA(lv_parser) = NEW zcl_toml_parser( ).
    DATA(lv_nodes) = lv_parser->parse( iv_toml ).
    rv_instance = NEW zcl_toml( iv_nodes = lv_nodes ).
  ENDMETHOD.

  METHOD create_empty.
    rv_instance = NEW zcl_toml( ).
  ENDMETHOD.

  METHOD stringify.
    DATA(lv_ser) = NEW zcl_toml_serializer( ).
    rv_toml = lv_ser->serialize( mv_nodes ).
  ENDMETHOD.

  METHOD split_path.
    DATA lv_tmp TYPE string.
    DATA lv_seg TYPE string.

    lv_tmp = iv_path.
    lv_tmp = condense( val  = lv_tmp
                       from = ` `
                       to   = `` ).
    SPLIT lv_tmp AT '/' INTO TABLE rv_segments.
    DATA(lv_clean) = VALUE zif_toml_types=>ty_string_table( ).
    LOOP AT rv_segments INTO lv_seg.
      IF lv_seg IS INITIAL.
        CONTINUE.
      ENDIF.
      INSERT lv_seg INTO TABLE lv_clean.
    ENDLOOP.
    rv_segments = lv_clean.
  ENDMETHOD.

  METHOD is_index_segment.
    DATA lv_idx TYPE i.
    DATA lv_len TYPE i.
    DATA lv_chr TYPE c LENGTH 1.

    rv_is_index = abap_true.
    IF iv_segment IS INITIAL.
      rv_is_index = abap_false.
      RETURN.
    ENDIF.
    lv_len = strlen( iv_segment ).
    lv_idx = 0.
    WHILE lv_idx < lv_len.
      lv_chr = substring( val = iv_segment
                          off = lv_idx
                          len = 1 ).
      IF lv_chr < '0' OR lv_chr > '9'.
        rv_is_index = abap_false.
        RETURN.
      ENDIF.
      lv_idx += 1.
    ENDWHILE.
  ENDMETHOD.

  METHOD find_child.
    DATA lv_node TYPE zif_toml_types=>ty_node.

    rv_id = 0.
    LOOP AT mv_nodes INTO lv_node WHERE parent = iv_parent AND name = iv_name.
      rv_id = lv_node-id.
      RETURN.
    ENDLOOP.
  ENDMETHOD.

  METHOD array_child_at.
    DATA lv_node TYPE zif_toml_types=>ty_node.
    DATA lv_pos  TYPE i.
    DATA lv_kids TYPE zif_toml_types=>ty_nodes.

    LOOP AT mv_nodes INTO lv_node WHERE parent = iv_parent.
      INSERT lv_node INTO TABLE lv_kids.
    ENDLOOP.
    SORT lv_kids BY id.
    lv_pos = 0.
    LOOP AT lv_kids INTO lv_node.
      IF lv_pos = iv_index.
        rv_id = lv_node-id.
        RETURN.
      ENDIF.
      lv_pos += 1.
    ENDLOOP.
    rv_id = -1.
  ENDMETHOD.

  METHOD resolve_node.
    DATA lv_segs TYPE zif_toml_types=>ty_string_table.
    DATA lv_seg  TYPE string.
    DATA lv_cur  TYPE i.
    DATA lv_node TYPE zif_toml_types=>ty_node.

    lv_segs = split_path( iv_path ).
    IF lines( lv_segs ) = 0.
      rv_id = 0.
      RETURN.
    ENDIF.
    lv_cur = 0.
    LOOP AT lv_segs INTO lv_seg.
      READ TABLE mv_nodes INTO lv_node WITH KEY id = lv_cur.
      IF sy-subrc <> 0.
        rv_id = -1.
        RETURN.
      ENDIF.
      IF lv_node-kind = zif_toml_types=>c_kind_array.
        IF is_index_segment( lv_seg ) = abap_false.
          rv_id = -1.
          RETURN.
        ENDIF.
        lv_cur = array_child_at( iv_parent = lv_cur
                                 iv_index  = CONV i( lv_seg ) ).
        IF lv_cur = -1.
          rv_id = -1.
          RETURN.
        ENDIF.
      ELSEIF is_index_segment( lv_seg ) = abap_true.
        READ TABLE mv_nodes INTO lv_node WITH KEY id = lv_cur.
        IF sy-subrc <> 0.
          rv_id = -1.
          RETURN.
        ENDIF.
        IF lv_node-kind <> zif_toml_types=>c_kind_array.
          lv_cur = find_child( iv_parent = lv_cur
                               iv_name   = lv_seg ).
          IF lv_cur = 0.
            rv_id = -1.
            RETURN.
          ENDIF.
        ELSE.
          lv_cur = array_child_at( iv_parent = lv_cur
                                   iv_index  = CONV i( lv_seg ) ).
          IF lv_cur = -1.
            rv_id = -1.
            RETURN.
          ENDIF.
        ENDIF.
      ELSE.
        lv_cur = find_child( iv_parent = lv_cur
                             iv_name   = lv_seg ).
        IF lv_cur = 0.
          rv_id = -1.
          RETURN.
        ENDIF.

      ENDIF.
    ENDLOOP.
    rv_id = lv_cur.
  ENDMETHOD.

  METHOD resolve_parent.
    DATA lv_segs  TYPE zif_toml_types=>ty_string_table.
    DATA lv_seg   TYPE string.
    DATA lv_cur   TYPE i.
    DATA lv_prev  TYPE i.
    DATA lv_idx   TYPE i.
    DATA lv_total TYPE i.
    DATA lv_node  TYPE zif_toml_types=>ty_node.
    DATA lv_new   TYPE i.
    DATA lv_found TYPE i.

    CLEAR ev_parent.
    CLEAR ev_leaf.
    CLEAR ev_leaf_is_idx.
    lv_segs = split_path( iv_path ).
    lv_total = lines( lv_segs ).
    IF lv_total = 0.
      RAISE EXCEPTION NEW zcx_toml_error( iv_text = 'Empty path' ).
    ENDIF.
    ev_leaf = lv_segs[ lv_total ].
    ev_leaf_is_idx = is_index_segment( ev_leaf ).
    lv_cur = 0.
    lv_idx = 1.
    WHILE lv_idx < lv_total.
      lv_seg = lv_segs[ lv_idx ].
      lv_prev = lv_cur.
      READ TABLE mv_nodes INTO lv_node WITH KEY id = lv_cur.
      IF sy-subrc <> 0.
        RAISE EXCEPTION NEW zcx_toml_error( iv_text = |Path not found: { iv_path }| ).
      ENDIF.
      IF lv_node-kind = zif_toml_types=>c_kind_array.
        lv_cur = array_child_at( iv_parent = lv_cur
                                 iv_index  = CONV i( lv_seg ) ).
        IF lv_cur = -1.
          RAISE EXCEPTION NEW zcx_toml_error( iv_text = |Array index out of bounds: { lv_seg } in { iv_path }| ).
        ENDIF.
      ELSE.
        lv_found = find_child( iv_parent = lv_prev
                               iv_name   = lv_seg ).
        IF lv_found = 0.
          IF iv_create = abap_true.
            lv_new = mv_next_id.
            mv_next_id += 1.
            INSERT VALUE zif_toml_types=>ty_node( id     = lv_new
                                                  parent = lv_prev
                                                  name   = lv_seg
                                                  kind   = zif_toml_types=>c_kind_table
                                                  value  = '' ) INTO TABLE mv_nodes.
            lv_cur = lv_new.
          ELSE.
            RAISE EXCEPTION NEW zcx_toml_error( iv_text = |Path not found: { iv_path }| ).
          ENDIF.
        ELSE.
          lv_cur = lv_found.
        ENDIF.
      ENDIF.
      lv_idx += 1.
    ENDWHILE.
    ev_parent = lv_cur.
  ENDMETHOD.

  METHOD exists.
    rv_exists = abap_false.
    IF resolve_node( iv_path ) >= 0.
      rv_exists = abap_true.
    ENDIF.
  ENDMETHOD.

  METHOD get_kind.
    DATA lv_id   TYPE i.
    DATA lv_node TYPE zif_toml_types=>ty_node.

    lv_id = resolve_node( iv_path ).
    IF lv_id < 0.
      RAISE EXCEPTION NEW zcx_toml_error( iv_text = |Path not found: { iv_path }| ).
    ENDIF.
    READ TABLE mv_nodes INTO lv_node WITH KEY id = lv_id.
    IF sy-subrc <> 0.
      RAISE EXCEPTION NEW zcx_toml_error( iv_text = |Node not found| ).
    ENDIF.
    rv_kind = lv_node-kind.
  ENDMETHOD.

  METHOD get_string.
    DATA lv_id   TYPE i.
    DATA lv_node TYPE zif_toml_types=>ty_node.

    lv_id = resolve_node( iv_path ).
    IF lv_id < 0.
      RAISE EXCEPTION NEW zcx_toml_error( iv_text = |Path not found: { iv_path }| ).
    ENDIF.
    READ TABLE mv_nodes INTO lv_node WITH KEY id = lv_id.
    IF sy-subrc <> 0.
      RAISE EXCEPTION NEW zcx_toml_error( iv_text = |Node not found| ).
    ENDIF.
    IF     lv_node-kind <> zif_toml_types=>c_kind_string
       AND lv_node-kind <> zif_toml_types=>c_kind_datetime
       AND lv_node-kind <> zif_toml_types=>c_kind_date
       AND lv_node-kind <> zif_toml_types=>c_kind_time.
      RAISE EXCEPTION NEW zcx_toml_error( iv_text = |Not a string at: { iv_path }| ).
    ENDIF.
    rv_value = lv_node-value.
  ENDMETHOD.

  METHOD get_integer.
    DATA lv_id   TYPE i.
    DATA lv_node TYPE zif_toml_types=>ty_node.

    lv_id = resolve_node( iv_path ).
    IF lv_id < 0.
      RAISE EXCEPTION NEW zcx_toml_error( iv_text = |Path not found: { iv_path }| ).
    ENDIF.
    READ TABLE mv_nodes INTO lv_node WITH KEY id = lv_id.
    IF sy-subrc <> 0.
      RAISE EXCEPTION NEW zcx_toml_error( iv_text = |Node not found| ).
    ENDIF.
    IF lv_node-kind <> zif_toml_types=>c_kind_integer.
      RAISE EXCEPTION NEW zcx_toml_error( iv_text = |Not an integer at: { iv_path }| ).
    ENDIF.
    TRY.
        rv_value = CONV i( lv_node-value ).
      CATCH cx_sy_conversion_no_number.
        RAISE EXCEPTION NEW zcx_toml_error( iv_text = |Bad integer value at: { iv_path }| ).
    ENDTRY.
  ENDMETHOD.

  METHOD get_float.
    DATA lv_id   TYPE i.
    DATA lv_node TYPE zif_toml_types=>ty_node.

    lv_id = resolve_node( iv_path ).
    IF lv_id < 0.
      RAISE EXCEPTION NEW zcx_toml_error( iv_text = |Path not found: { iv_path }| ).
    ENDIF.
    READ TABLE mv_nodes INTO lv_node WITH KEY id = lv_id.
    IF sy-subrc <> 0.
      RAISE EXCEPTION NEW zcx_toml_error( iv_text = |Node not found| ).
    ENDIF.
    IF     lv_node-kind <> zif_toml_types=>c_kind_float
       AND lv_node-kind <> zif_toml_types=>c_kind_integer.
      RAISE EXCEPTION NEW zcx_toml_error( iv_text = |Not a float at: { iv_path }| ).
    ENDIF.
    TRY.
        rv_value = CONV f( lv_node-value ).
      CATCH cx_sy_conversion_no_number.
        RAISE EXCEPTION NEW zcx_toml_error( iv_text = |Bad float value at: { iv_path }| ).
    ENDTRY.
  ENDMETHOD.

  METHOD get_boolean.
    DATA lv_id   TYPE i.
    DATA lv_node TYPE zif_toml_types=>ty_node.

    lv_id = resolve_node( iv_path ).
    IF lv_id < 0.
      RAISE EXCEPTION NEW zcx_toml_error( iv_text = |Path not found: { iv_path }| ).
    ENDIF.
    READ TABLE mv_nodes INTO lv_node WITH KEY id = lv_id.
    IF sy-subrc <> 0.
      RAISE EXCEPTION NEW zcx_toml_error( iv_text = |Node not found| ).
    ENDIF.
    IF lv_node-kind <> zif_toml_types=>c_kind_boolean.
      RAISE EXCEPTION NEW zcx_toml_error( iv_text = |Not a boolean at: { iv_path }| ).
    ENDIF.
    rv_value = xsdbool( lv_node-value = 'true' ).
  ENDMETHOD.

  METHOD upsert_scalar.
    DATA lv_parent TYPE i.
    DATA lv_leaf   TYPE string.
    DATA lv_is_idx TYPE abap_bool.
    DATA lv_id     TYPE i.
    DATA lv_node   TYPE zif_toml_types=>ty_node.

    resolve_parent( EXPORTING iv_path        = iv_path
                              iv_create      = abap_true
                    IMPORTING ev_parent      = lv_parent
                              ev_leaf        = lv_leaf
                              ev_leaf_is_idx = lv_is_idx ).
    IF lv_is_idx = abap_true.
      RAISE EXCEPTION NEW zcx_toml_error( iv_text = |Use array_append_* for array elements: { iv_path }| ).
    ENDIF.
    lv_id = find_child( iv_parent = lv_parent
                        iv_name   = lv_leaf ).
    IF lv_id = 0.
      INSERT VALUE zif_toml_types=>ty_node( id     = mv_next_id
                                            parent = lv_parent
                                            name   = lv_leaf
                                            kind   = iv_kind
                                            value  = iv_value ) INTO TABLE mv_nodes.
      mv_next_id += 1.
      RETURN.
    ENDIF.
    READ TABLE mv_nodes INTO lv_node WITH KEY id = lv_id.
    IF sy-subrc <> 0.
      RAISE EXCEPTION NEW zcx_toml_error( iv_text = |Node not found| ).
    ENDIF.
    IF    lv_node-kind = zif_toml_types=>c_kind_table
       OR lv_node-kind = zif_toml_types=>c_kind_array.
      RAISE EXCEPTION NEW zcx_toml_error( iv_text = |Path is table/array, cannot overwrite: { iv_path }| ).
    ENDIF.
    lv_node-kind  = iv_kind.
    lv_node-value = iv_value.
    MODIFY mv_nodes FROM lv_node TRANSPORTING kind value WHERE id = lv_id.
  ENDMETHOD.

  METHOD set_string.
    upsert_scalar( iv_path  = iv_path
                   iv_kind  = zif_toml_types=>c_kind_string
                   iv_value = iv_value ).
  ENDMETHOD.

  METHOD set_integer.
    DATA lv_str TYPE string.

    lv_str = |{ iv_value }|.
    lv_str = condense( val  = lv_str
                       from = ` `
                       to   = `` ).
    upsert_scalar( iv_path  = iv_path
                   iv_kind  = zif_toml_types=>c_kind_integer
                   iv_value = lv_str ).
  ENDMETHOD.

  METHOD set_float.
    DATA lv_str TYPE string.

    lv_str = |{ iv_value }|.
    lv_str = condense( val  = lv_str
                       from = ` `
                       to   = `` ).
    upsert_scalar( iv_path  = iv_path
                   iv_kind  = zif_toml_types=>c_kind_float
                   iv_value = lv_str ).
  ENDMETHOD.

  METHOD set_boolean.
    DATA lv_str TYPE string.

    IF iv_value = abap_true.
      lv_str = 'true'.
    ELSE.
      lv_str = 'false'.
    ENDIF.
    upsert_scalar( iv_path  = iv_path
                   iv_kind  = zif_toml_types=>c_kind_boolean
                   iv_value = lv_str ).
  ENDMETHOD.

  METHOD set_datetime.
    upsert_scalar( iv_path  = iv_path
                   iv_kind  = zif_toml_types=>c_kind_datetime
                   iv_value = iv_value ).
  ENDMETHOD.

  METHOD touch_table.
    DATA lv_parent TYPE i.
    DATA lv_leaf   TYPE string.
    DATA lv_is_idx TYPE abap_bool.
    DATA lv_id     TYPE i.
    DATA lv_node   TYPE zif_toml_types=>ty_node.

    resolve_parent( EXPORTING iv_path        = iv_path
                              iv_create      = abap_true
                    IMPORTING ev_parent      = lv_parent
                              ev_leaf        = lv_leaf
                              ev_leaf_is_idx = lv_is_idx ).
    IF lv_is_idx = abap_true.
      RAISE EXCEPTION NEW zcx_toml_error( iv_text = |Table name cannot be numeric index: { iv_path }| ).
    ENDIF.
    lv_id = find_child( iv_parent = lv_parent
                        iv_name   = lv_leaf ).
    IF lv_id = 0.
      INSERT VALUE zif_toml_types=>ty_node( id     = mv_next_id
                                            parent = lv_parent
                                            name   = lv_leaf
                                            kind   = zif_toml_types=>c_kind_table
                                            value  = '' ) INTO TABLE mv_nodes.
      mv_next_id += 1.
      RETURN.
    ENDIF.
    READ TABLE mv_nodes INTO lv_node WITH KEY id = lv_id.
    IF sy-subrc <> 0.
      RAISE EXCEPTION NEW zcx_toml_error( iv_text = |Node not found| ).
    ENDIF.
    IF lv_node-kind <> zif_toml_types=>c_kind_table.
      RAISE EXCEPTION NEW zcx_toml_error( iv_text = |Path exists but is not a table: { iv_path }| ).
    ENDIF.
  ENDMETHOD.

  METHOD touch_array.
    DATA lv_parent TYPE i.
    DATA lv_leaf   TYPE string.
    DATA lv_is_idx TYPE abap_bool.
    DATA lv_id     TYPE i.
    DATA lv_node   TYPE zif_toml_types=>ty_node.

    resolve_parent( EXPORTING iv_path        = iv_path
                              iv_create      = abap_true
                    IMPORTING ev_parent      = lv_parent
                              ev_leaf        = lv_leaf
                              ev_leaf_is_idx = lv_is_idx ).
    IF lv_is_idx = abap_true.
      RAISE EXCEPTION NEW zcx_toml_error( iv_text = |Array name cannot be numeric index: { iv_path }| ).
    ENDIF.
    lv_id = find_child( iv_parent = lv_parent
                        iv_name   = lv_leaf ).
    IF lv_id = 0.
      INSERT VALUE zif_toml_types=>ty_node( id     = mv_next_id
                                            parent = lv_parent
                                            name   = lv_leaf
                                            kind   = zif_toml_types=>c_kind_array
                                            value  = '' ) INTO TABLE mv_nodes.
      mv_next_id += 1.
      RETURN.
    ENDIF.
    READ TABLE mv_nodes INTO lv_node WITH KEY id = lv_id.
    IF sy-subrc <> 0.
      RAISE EXCEPTION NEW zcx_toml_error( iv_text = |Node not found| ).
    ENDIF.
    IF lv_node-kind <> zif_toml_types=>c_kind_array.
      RAISE EXCEPTION NEW zcx_toml_error( iv_text = |Path exists but is not an array: { iv_path }| ).
    ENDIF.
  ENDMETHOD.

  METHOD array_append_string.
    DATA lv_id   TYPE i.
    DATA lv_node TYPE zif_toml_types=>ty_node.

    lv_id = resolve_node( iv_path ).
    IF lv_id < 0.
      RAISE EXCEPTION NEW zcx_toml_error( iv_text = |Array not found: { iv_path }| ).
    ENDIF.
    READ TABLE mv_nodes INTO lv_node WITH KEY id = lv_id.
    IF sy-subrc <> 0.
      RAISE EXCEPTION NEW zcx_toml_error( iv_text = |Node not found| ).
    ENDIF.
    IF lv_node-kind <> zif_toml_types=>c_kind_array.
      RAISE EXCEPTION NEW zcx_toml_error( iv_text = |Not an array: { iv_path }| ).
    ENDIF.
    INSERT VALUE zif_toml_types=>ty_node( id     = mv_next_id
                                          parent = lv_id
                                          name   = ''
                                          kind   = zif_toml_types=>c_kind_string
                                          value  = iv_value ) INTO TABLE mv_nodes.
    mv_next_id += 1.
  ENDMETHOD.

  METHOD array_append_integer.
    DATA lv_id   TYPE i.
    DATA lv_node TYPE zif_toml_types=>ty_node.
    DATA lv_str  TYPE string.

    lv_id = resolve_node( iv_path ).
    IF lv_id < 0.
      RAISE EXCEPTION NEW zcx_toml_error( iv_text = |Array not found: { iv_path }| ).
    ENDIF.
    READ TABLE mv_nodes INTO lv_node WITH KEY id = lv_id.
    IF sy-subrc <> 0.
      RAISE EXCEPTION NEW zcx_toml_error( iv_text = |Node not found| ).
    ENDIF.
    IF lv_node-kind <> zif_toml_types=>c_kind_array.
      RAISE EXCEPTION NEW zcx_toml_error( iv_text = |Not an array: { iv_path }| ).
    ENDIF.
    lv_str = |{ iv_value }|.
    lv_str = condense( val  = lv_str
                       from = ` `
                       to   = `` ).
    INSERT VALUE zif_toml_types=>ty_node( id     = mv_next_id
                                          parent = lv_id
                                          name   = ''
                                          kind   = zif_toml_types=>c_kind_integer
                                          value  = lv_str ) INTO TABLE mv_nodes.
    mv_next_id += 1.
  ENDMETHOD.

  METHOD array_length.
    DATA lv_id   TYPE i.
    DATA lv_node TYPE zif_toml_types=>ty_node.
    " TODO: variable is assigned but never used (ABAP cleaner)
    DATA lv_row  TYPE zif_toml_types=>ty_node.

    lv_id = resolve_node( iv_path ).
    IF lv_id < 0.
      RAISE EXCEPTION NEW zcx_toml_error( iv_text = |Array not found: { iv_path }| ).
    ENDIF.
    READ TABLE mv_nodes INTO lv_node WITH KEY id = lv_id.
    IF sy-subrc <> 0.
      RAISE EXCEPTION NEW zcx_toml_error( iv_text = |Node not found| ).
    ENDIF.
    IF lv_node-kind <> zif_toml_types=>c_kind_array.
      RAISE EXCEPTION NEW zcx_toml_error( iv_text = |Not an array: { iv_path }| ).
    ENDIF.
    rv_len = 0.
    LOOP AT mv_nodes INTO lv_row WHERE parent = lv_id.
      rv_len += 1.
    ENDLOOP.
  ENDMETHOD.

  METHOD delete_node.
    DATA lv_id   TYPE i.
    DATA lv_dead TYPE zif_toml_types=>ty_nodes.
    DATA lv_row  TYPE zif_toml_types=>ty_node.
    DATA lv_keep TYPE zif_toml_types=>ty_nodes.

    lv_id = resolve_node( iv_path ).
    IF lv_id < 0.
      RAISE EXCEPTION NEW zcx_toml_error( iv_text = |Path not found: { iv_path }| ).
    ENDIF.
    IF lv_id = 0.
      RAISE EXCEPTION NEW zcx_toml_error( iv_text = 'Cannot delete root' ).
    ENDIF.
    lv_dead = collect_subtree( lv_id ).
    LOOP AT mv_nodes INTO lv_row.
      IF line_exists( lv_dead[ id = lv_row-id ] ) = abap_false.
        INSERT lv_row INTO TABLE lv_keep.
      ENDIF.
    ENDLOOP.
    mv_nodes = lv_keep.
  ENDMETHOD.

  METHOD collect_subtree.
    DATA lv_row  TYPE zif_toml_types=>ty_node.
    DATA lv_kids TYPE zif_toml_types=>ty_nodes.
    DATA lv_kid  TYPE zif_toml_types=>ty_node.
    DATA lv_sub  TYPE zif_toml_types=>ty_nodes.

    INSERT VALUE zif_toml_types=>ty_node( id     = iv_root
                                          parent = 0
                                          name   = ''
                                          kind   = ''
                                          value  = '' ) INTO TABLE rv_collected.
    LOOP AT mv_nodes INTO lv_row WHERE parent = iv_root.
      INSERT lv_row INTO TABLE lv_kids.
    ENDLOOP.
    LOOP AT lv_kids INTO lv_kid.
      lv_sub = collect_subtree( lv_kid-id ).
      LOOP AT lv_sub INTO lv_row.
        INSERT lv_row INTO TABLE rv_collected.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.

  METHOD clear.
    CLEAR mv_nodes.
    INSERT VALUE zif_toml_types=>ty_node( id     = 0
                                          parent = -1
                                          name   = ''
                                          kind   = zif_toml_types=>c_kind_table
                                          value  = '' ) INTO TABLE mv_nodes.
    mv_next_id = 1.
  ENDMETHOD.
ENDCLASS.
