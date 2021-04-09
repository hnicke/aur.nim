# Package

version       = "0.1.0"
author        = "Heiko Nickerl"
description   = "A client for the Arch Linux User Repository (AUR)"
license       = "MIT"
srcDir        = "src"


# Dependencies

requires "nim >= 1.4.0"

task fmt, "format the codebase":
    exec r"git ls-files . | grep '\.nim$' | xargs nimpretty"
    echo "Formatted source code"

task clean, "remove build artifacts":
    rmDir(thisDir() & "/out")
