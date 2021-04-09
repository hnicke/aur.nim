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
