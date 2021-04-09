# aur.nim

A nim client for the [Arch User Repository](https://aur.archlinux.org/) (AUR).

This simple wrapper for the [Aurweb RPC interface](https://wiki.archlinux.org/index.php/Aurweb_RPC_interface) allows searching the AUR for information about packages.


## Installation

Add the following to your `.nimble` file:

```
# Dependencies

requires "aur >= 0.1.0"
```

Or, to install globally to your Nimble cache run the following command:

```
nimble install aur
```

## Usage

```nim
import aur, options

# retrieve information about a specific package
let pkg = info("google-chrome")
if pkg.isSome:
    echo pkg.get().description
    echo pkg.get().numVotes
    echo pkg.get().maintainer

# search for packages
let pkgs = search(QueryBy.Maintainer, keyword="luzifer")
for pkg in pkgs:
    echo pkg.name 
    echo pkg.description
```