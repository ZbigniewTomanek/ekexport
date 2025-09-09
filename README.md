**ekexport**

A minimal Swift Package (CLI) scaffold that prints a hello world message. This is set up to compile and run on macOS using Swift Package Manager.

**Requirements**
- Xcode command line tools or Swift toolchain installed

**Build**
- `swift build`

**Run**
- `swift run ekexport`

**Makefile**
- `make help` — list available targets
- `make build` — build debug binary
- `make run ARGS="..."` — run with optional args
- `make release` — build optimized binary
- `make release-run ARGS="..."` — run optimized binary
- `make test` — run tests (none yet)
- `make clean` — clean build artifacts
- `make install` — install to `/usr/local/bin` (override with `PREFIX=/some/path`)
- `make uninstall` — remove the installed binary

**Structure**
- `Package.swift` – SwiftPM manifest
- `Sources/ekexport/main.swift` – CLI entry point
