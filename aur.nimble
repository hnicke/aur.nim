# Package

version       = "0.2.0"
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

task docGen, "generate docs":
    selfExec "doc --git.url:https://github.com/hnicke/aur.nim --git.commit:master --git.devel=master src/aur.nim"

task docOpen, "open docs":
    exec "xdg-open out/aur.html"