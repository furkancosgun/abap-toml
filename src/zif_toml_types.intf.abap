INTERFACE zif_toml_types
  PUBLIC.

  CONSTANTS c_kind_table    TYPE string VALUE 'table'.
  CONSTANTS c_kind_array    TYPE string VALUE 'array'.
  CONSTANTS c_kind_string   TYPE string VALUE 'string'.
  CONSTANTS c_kind_integer  TYPE string VALUE 'integer'.
  CONSTANTS c_kind_float    TYPE string VALUE 'float'.
  CONSTANTS c_kind_boolean  TYPE string VALUE 'boolean'.
  CONSTANTS c_kind_datetime TYPE string VALUE 'datetime'.
  CONSTANTS c_kind_date     TYPE string VALUE 'date'.
  CONSTANTS c_kind_time     TYPE string VALUE 'time'.

  TYPES: BEGIN OF ty_node,
           id     TYPE i,
           parent TYPE i,
           name   TYPE string,
           kind   TYPE string,
           value  TYPE string,
         END OF ty_node.

  TYPES ty_nodes        TYPE STANDARD TABLE OF ty_node WITH EMPTY KEY.

  TYPES ty_string_table TYPE STANDARD TABLE OF string WITH EMPTY KEY.

ENDINTERFACE.
