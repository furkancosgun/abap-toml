# abap-toml

TOML v1.0 parser and serializer for ABAP with path-based (ajson-style) access.

## Features

- **Full TOML v1.0 Support**: Bare and quoted keys, dotted keys, multiline and literal strings, integers (decimal, hex, octal, binary), floats, booleans, date-times, arrays, inline tables, and array of tables.
- **Path-Based Access**: Query and mutate documents using XPath/ajson-like slash paths (`/server/host`, `/ports/0`).
- **Bidirectional**: Parse TOML into an in-memory document tree and serialize it back to valid TOML.
- **abapGit Compatible**: Standard file structure ready for deployment via abapGit.

## Installation

Install using [abapGit](https://abapgit.org) by adding this repository to your SAP system.

## Quick Start

### Parsing TOML

```abap
DATA lo_toml TYPE REF TO zcl_toml.
DATA lv_host TYPE string.
DATA lv_port TYPE i.

lo_toml = zcl_toml=>parse( lv_toml_content ).

lv_host = lo_toml->get_string( '/server/host' ).
lv_port = lo_toml->get_integer( '/server/port' ).
```

### Path-Based Mutation & Serialization

```abap
DATA lo_toml TYPE REF TO zcl_toml.
DATA lv_toml TYPE string.

lo_toml = zcl_toml=>create_empty( ).

lo_toml->set_string( iv_path  = '/server/host'
                     iv_value = 'example.com' ).

lo_toml->set_integer( iv_path  = '/server/port'
                      iv_value = 8080 ).

lo_toml->touch_array( '/ports' ).
lo_toml->array_append_integer( iv_path  = '/ports'
                               iv_value = 8080 ).

lv_toml = lo_toml->stringify( ).
```

## API Overview

### `ZCL_TOML` (Facade)

| Method | Parameters | Return | Description |
| :--- | :--- | :--- | :--- |
| `parse` | `iv_toml TYPE string` | `ro_instance TYPE REF TO zcl_toml` | Parses TOML string into instance |
| `create_empty` | - | `ro_instance TYPE REF TO zcl_toml` | Creates empty document |
| `stringify` | - | `rv_toml TYPE string` | Serializes document to TOML |
| `exists` | `iv_path TYPE string` | `rv_exists TYPE abap_bool` | Checks if path exists |
| `get_kind` | `iv_path TYPE string` | `rv_kind TYPE string` | Returns node kind |
| `get_string` | `iv_path TYPE string` | `rv_value TYPE string` | Reads string scalar |
| `get_integer` | `iv_path TYPE string` | `rv_value TYPE i` | Reads integer scalar |
| `get_float` | `iv_path TYPE string` | `rv_value TYPE f` | Reads float scalar |
| `get_boolean` | `iv_path TYPE string` | `rv_value TYPE abap_bool` | Reads boolean scalar |
| `set_string` | `iv_path, iv_value` | - | Sets or creates string node |
| `set_integer` | `iv_path, iv_value` | - | Sets or creates integer node |
| `set_float` | `iv_path, iv_value` | - | Sets or creates float node |
| `set_boolean` | `iv_path, iv_value` | - | Sets or creates boolean node |
| `set_datetime` | `iv_path, iv_value` | - | Sets or creates datetime node |
| `touch_table` | `iv_path TYPE string` | - | Ensures table path exists |
| `touch_array` | `iv_path TYPE string` | - | Ensures array path exists |
| `array_append_string` | `iv_path, iv_value` | - | Appends string to array |
| `array_append_integer`| `iv_path, iv_value` | - | Appends integer to array |
| `array_length` | `iv_path TYPE string` | `rv_len TYPE i` | Returns element count of array |
| `delete_node` | `iv_path TYPE string` | - | Deletes node and descendants |
| `clear` | - | - | Clears entire document |

### Error Handling

Errors raise `ZCX_TOML_ERROR`, which provides:
- `get_message( ) TYPE string`: Human-readable error description
- `get_line( ) TYPE i`: Line number where syntax error occurred (if applicable)

## Architecture

- **`ZCL_TOML`**: Public-facing facade providing path queries and manipulation.
- **`ZCL_TOML_PARSER`**: TOML parser creating the AST node table.
- **`ZCL_TOML_SERIALIZER`**: Serializes AST nodes back to TOML formatted text.
- **`ZIF_TOML_TYPES`**: Shared data types (`ty_node`, `ty_nodes`, `ty_string_table`) and kind constants.
- **`ZCX_TOML_ERROR`**: Exception class for parsing and serialization errors.

## Development & Testing

```bash
# Install dependencies
npm install

# Run linter and ABAP Unit test suite
npm test

# Run unit tests only
npm run unit

# Run linter only
npm run lint
```

## License

MIT
