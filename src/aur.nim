##[  
# Usage

This is a nim client for the [Arch User Repository](https://aur.archlinux.org/) (AUR).

It's a simple wrapper around the [Aurweb RPC interface](https://wiki.archlinux.org/index.php/Aurweb_RPC_interface) which allows searching the AUR for information about packages.

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

]##
import
  httpclient,
  json,
  options,
  sequtils,
  uri,
  strformat,
  times,
  sugar


let client = newHttpClient()
const apiVersion = 5
const endpoint = parseUri("https://aur.archlinux.org/rpc")

type
  AurPackage* = object of RootObj
    ## Package information.
    id*: int
    name*: string
    pkgBaseId*: int
    pkgBase*: string
    version*: string
    description*: string
    url*: string
    numVotes*: int
    popularity*: float
    outOfDate*: Option[DateTime]
    maintainer*: string
    firstSubmitted*: DateTime
    lastModified*: DateTime
    urlPath*: Uri

  AurPackageInfo* = object of AurPackage
    ## Detailed package information.
    depends*: seq[string]
    makeDepends*: seq[string]
    optDepends*: seq[string]
    conflicts*: seq[string]
    provides*: seq[string]
    replaces*: seq[string]
    groups*: seq[string]
    licence*: seq[string]
    keywords*: seq[string]

  QueryBy* {.pure.} = enum
    ## Search criteria.
    ## 
    ## ``Name`` Search by package name only.
    ## 
    ## ``NameDesc`` Search by package name and description.
    ## 
    ## ``Maintainer`` Search by package maintainer.
    ## 
    ## ``Depends`` Search for packages that depend on keywords.
    ## 
    ## ``Makedepends`` Search for packages that makedepend on keywords.
    ## 
    ## ``Optdepends`` Search for packages that optdepend on keywords.
    ## 
    ## ``Checkdepends`` Search for packages that checkdepend on keywords.
    Name = "name"
    NameDesc = "name-desc"
    Maintainer = "maintainer"
    Depends = "depends"
    Makedepends = "makedepends"
    Optdepends = "optdepends"
    Checkdepends = "checkdepends"
  
  QueryError* = object of CatchableError
    ## Raised if the AUR responded with an application level error.

  IllegalKeywordError* = object of QueryError
    ## Raised if a supplied search keyword length is shorter than 2 charcters

  QueryType {.pure.} = enum
    Search = "search"
    Info = "info"

  ResultType {.pure.} = enum
    Search = "search"
    Info = "multiinfo"
    Error = "error"

  PackageSearchResult = object of RootObj
    ID: int
    Name: string
    PackageBaseID: int
    PackageBase: string
    Version: string
    Description: string
    URL: string
    NumVotes: int
    Popularity: float
    OutOfDate: Option[int]
    Maintainer: string
    FirstSubmitted: int
    LastModified: int
    URLPath: string

  PackageInfoResult = object of PackageSearchResult
    Depends: Option[seq[string]]
    MakeDepends: Option[seq[string]]
    OptDepends: Option[seq[string]]
    Conflicts: Option[seq[string]]
    Provides: Option[seq[string]]
    Replaces: Option[seq[string]]
    Groups: Option[seq[string]]
    Licence: Option[seq[string]]
    Keywords: Option[seq[string]]

  QueryResult = object
    version: int
    `type`: ResultType
    resultcount: int
    results: seq[PackageSearchResult]
    error: Option[string]

  InfoResult = object
    version: int
    `type`: ResultType
    resultcount: int
    results: seq[PackageInfoResult]
    error: Option[string]

proc toModel(r: PackageSearchResult): AurPackage =
  return AurPackage(
    id: r.ID,
    name: r.Name,
    pkgBaseId: r.PackageBaseID,
    pkgBase: r.PackageBase,
    version: r.Version,
    description: r.Description,
    url: r.URL,
    numVotes: r.NumVotes,
    popularity: r.Popularity,
    outOfDate: r.OutOfDate.map(x => x.fromUnix().inZone(utc())),
    maintainer: r.Maintainer,
    firstSubmitted: r.FirstSubmitted.fromUnix().inZone(utc()),
    lastModified: r.LastModified.fromUnix().inZone(utc()),
    urlPath: parseUri(r.URLPath),
  )

proc toModel(r: PackageInfoResult): AurPackageInfo =
  return AurPackageInfo(
    id: r.ID,
    name: r.Name,
    pkgBaseId: r.PackageBaseID,
    pkgBase: r.PackageBase,
    version: r.Version,
    description: r.Description,
    url: r.URL,
    numVotes: r.NumVotes,
    popularity: r.Popularity,
    outOfDate: r.OutOfDate.map(x => x.fromUnix().inZone(utc())),
    maintainer: r.Maintainer,
    firstSubmitted: r.FirstSubmitted.fromUnix().inZone(utc()),
    lastModified: r.LastModified.fromUnix().inZone(utc()),
    urlPath: parseUri(r.URLPath),
    depends: r.Depends.get(@[]),
    makeDepends: r.MakeDepends.get(@[]),
    optDepends: r.OptDepends.get(@[]),
    conflicts: r.Conflicts.get(@[]),
    provides: r.Provides.get(@[]),
    replaces: r.Replaces.get(@[]),
    groups: r.Groups.get(@[]),
    licence: r.Licence.get(@[]),
    keywords: r.Keywords.get(@[]),
  )

proc search*(by: QueryBy = NameDesc, keyword: string): seq[AurPackage] =
  ## Search the AUR for packages.
  ## 
  ## ``by`` specifies the search criteria, defaults to NameDesc.
  ## 
  ## ``keyword`` the keyword to search for.
  if keyword.len > 1:
    let params = {"v": $apiVersion, "type": $QueryType.Search,
                  "by": $by, "arg": keyword}
    let uri = endpoint ? params
    let queryResult = client.getContent($uri)
      .parseJson()
      .to(QueryResult)
    if queryResult.error.isNone:
      queryResult
        .results
        .map(toModel)
    else:
      raise newException(QueryError, queryResult.error.get())
  else:
    raise newException(
        IllegalKeywordError,
        &"keyword must be at least 2 chars long (was '{keyword}')"
      )

proc info*(pkgNames: seq[string]): seq[AurPackageInfo] =
  ## Retrieve detailed package information for each package in ``pkgNames``.
  ## 
  ## Under the hood, issues only one request to the AUR.
  let params = @[("v", $apiVersion), ("type", $QueryType.Info)] & pkgNames.map(x => ("arg[]", x))
  let uri = endpoint ? params
  let infoResult = client.getContent($uri)
    .parseJson()
    .to(InfoResult)
  if infoResult.error.isNone:
    return infoResult
            .results
            .map(toModel)
  else:
    raise newException(QueryError, infoResult.error.get())

proc info*(pkgNames: varargs[string]): seq[AurPackageInfo] = info(@pkgNames)
  ## Retrieve detailed package information for each package in ``pkgNames``.
  ## 
  ## Under the hood, issues only one request to the AUR.

proc info*(pkgName: string): Option[AurPackageInfo] = 
  ## Retrieve detailed package information for package ``pkgName``.
  let pkgs = info([pkgName])
  if pkgs.len >= 1:
    return pkgs[0].some