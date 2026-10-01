# abap-toml

TOML v1.0 parser / serializer for ABAP, with ajson-style path access.
Clean, extensible, SOLID + DRY: facade (`ZCL_TOML`), parser
(`ZCL_TOML_PARSER`), serializer (`ZCL_TOML_SERIALIZER`), shared
types (`ZIF_TOML_TYPES`), typed errors (`ZCX_TOML_ERROR`).

## 🚀 Getting Started

```bash
# Navigate to project directory
cd abap-toml

# Install dependencies
npm install

# Run the TOML demo program
PROGRAM=ztoml_demo npm run run

# Run lint + unit tests
npm test
```

## 📖 Usage (ajson-like)

```abap
DATA lo_toml TYPE REF TO zcl_toml.

" Read
lo_toml = zcl_toml=>parse( lv_toml_text ).
DATA lv_host TYPE string.
lv_host = lo_toml->get_string( '/server/host' ).
DATA lv_port TYPE i.
lv_port = lo_toml->get_integer( '/server/port' ).

" Write (tables are auto-created along the path)
lo_toml->set_string(
  iv_path  = '/server/host'
  iv_value = 'example.com' ).
lo_toml->touch_array( '/ports' ).
lo_toml->array_append_integer(
  iv_path  = '/ports'
  iv_value = 8080 ).

" Serialize back to TOML
DATA lv_out TYPE string.
lv_out = lo_toml->stringify( ).
```

Path syntax: `/a/b/c`, array index `/ports/0`, `/` = root.
Typed getters: `get_string`, `get_integer`, `get_float`,
`get_boolean`, plus `get_kind`, `exists`, `array_length`,
`delete_node`, `clear`. Errors raise `ZCX_TOML_ERROR`
(`get_message( )`, `get_line( )`).

## 🧩 abapGit File Format

Source files are stored in the [abapGit serialized file format](https://docs.abapgit.org/), so the repository can be synced to a real SAP system via [abapGit](https://docs.abapgit.org/). Classes, interfaces and programs use their standard abapGit layouts (`.clas.abap` + `.clas.xml`, `.intf.abap` + `.intf.xml`, `.prog.abap`).

## 🛠️ Available Commands

- **`npm run build`** - Transpile ABAP sources to JavaScript (`output/`)
- **`npm start`** - Start Express ICF Web Server (`http://localhost:3000`)
- **`npm run run`** - Transpile and run default `zhello_world` executable program
- **`PROGRAM=myprogram npm run run`** - Run a specific ABAP program
- **`npm test`** - Run linting and unit tests (`npm run lint && npm run unit`)
- **`npm run unit`** - Run ABAP Unit test suite
- **`npm run lint`** - Analyze ABAP code with abaplint
- **`npm run lint:fix`** - Auto-fix fixable issues
- **`npm run clean`** - Remove the transpiled `output/` directory
- **`npm run deps`** - Update git submodule dependencies

## 📂 Project Structure

```
abap-toml/
├── src/                            # ABAP source files (abapGit format)
│   ├── zhello_world.prog.abap     # Sample executable program
│   ├── zhello_world.prog.xml      # Sample program (abapGit metadata)
│   ├── zif_hello_world.intf.abap  # Sample interface (source)
│   ├── zif_hello_world.intf.xml   # Sample interface (abapGit metadata)
│   ├── zcl_hello_world.clas.abap  # Sample class (source)
│   ├── zcl_hello_world.clas.xml   # Sample class (abapGit metadata)
│   ├── zcl_hello_world.clas.testclasses.abap  # Sample ABAP Unit tests
│   ├── zcl_sicf_node.clas.abap    # Sample SICF HTTP handler (if_http_extension)
│   └── zcl_sicf_node.clas.xml     # Sample SICF HTTP handler (metadata)
├── scripts/                        # Utility and lifecycle scripts
│   ├── clean.mjs                  # Removes transpiler output directory
│   ├── setup.mjs                  # SQLite database setup
│   ├── run.mjs                    # Cross-platform program runner
│   └── server.mjs                 # Express ICF HTTP server runner
├── deps/                           # Git submodule dependencies (open-abap libraries)
├── output/                         # Transpiled JavaScript (generated)
├── package.json                    # Project configuration
├── abaplint.json                   # Linter configuration
├── abaplint-transpiler.json        # Transpiler configuration
├── .abapgit.xml                    # abapGit repository config
├── .gitmodules                     # Git submodules configuration
├── .gitignore                      # Git ignore rules
└── README.md                       # This file
```

## 🔧 Configuration Files

- **`abaplint.json`** - abaplint code analysis rules
- **`abaplint-transpiler.json`** - Transpiler settings (input/output folders, libraries)
- **`.gitmodules`** - Git submodule tracking for open-abap dependencies under `deps/`
- **`scripts/setup.mjs`** - SQLite database connection setup
- **`scripts/run.mjs`** - Runs the transpiled program selected via the `PROGRAM` environment variable
- **`scripts/clean.mjs`** - Removes the transpiled output directory
- **`package.json`** - npm dependencies and scripts

## 📦 Dependencies

- **@abaplint/runtime** - ABAP runtime environment
- **@abaplint/transpiler-cli** - ABAP to JavaScript transpiler
- **@abaplint/database-sqlite** - SQLite database support

Transpilation pulls in the [open-abap](https://github.com/open-abap) libraries (core, RAP, XCO, GUI, REST, ADT, SEO and more) so a broad range of ABAP features can run locally.

## 🔗 Useful Links

- [abaplint GitHub](https://github.com/abaplint/abaplint)
- [open-abap](https://github.com/open-abap/open-abap)
- [abapGit](https://docs.abapgit.org/)
- [ABAP Language Reference](https://help.sap.com/doc/abapdocu_latest_index_htm/latest/en-US/index.htm)

---

Created with ❤️ by **abap-kit**
