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

# TODO Add documentation for publicly exposed members

type
  AurQueryError* = object of CatchableError
  AurInvalidSearchKeywordError* = object of AurQueryError

  AurPackage* = object of RootObj
    id*: int
    name: string
    packageBaseId: int
    packageBase: string
    version: string
    description: string
    url: string
    numVotes: int
    popularity: float
    outOfDate: Option[DateTime]
    maintainer: string
    firstSubmitted: DateTime
    lastModified: DateTime
    urlPath: Uri

  AurPackageInfo* = object of AurPackage
    depends: seq[string]
    makeDepends: seq[string]
    optDepends: seq[string]
    conflicts: seq[string]
    provides: seq[string]
    replaces: seq[string]
    groups: seq[string]
    licence: seq[string]
    keywords: seq[string]

  QueryType {.pure.} = enum
    Search = "search"
    Info = "info"

  ResultType {.pure.} = enum
    Search = "search"
    Info = "multiinfo"
    Error = "error"

  QueryBy* {.pure.} = enum
    Name = "name"
    ## search by package name only
    NameDesc = "name-desc"
    ## search by package name and description
    Maintainer = "maintainer"
    ## search by package maintainer
    Depends = "depends"
    ## search for packages that depend on keywords
    Makedepends = "makedepends"
    ## search for packages that makedepend on keywords
    Optdepends = "optdepends"
    ## search for packages that optdepend on keywords
    Checkdepends = "checkdepends"
    ## search for packages that checkdepend on keywords

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
    Depends: seq[string]
    MakeDepends: seq[string]
    OptDepends: seq[string]
    Conflicts: seq[string]
    Provides: seq[string]
    Replaces: seq[string]
    Groups: seq[string]
    Licence: seq[string]
    Keywords: seq[string]

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
    results: seq[PackageSearchResult]
    error: Option[string]

proc toModel(r: PackageSearchResult): AurPackage =
  return AurPackage(
    id: r.ID,
    name: r.Name,
    packageBaseId: r.PackageBaseID,
    packageBase: r.PackageBase,
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
    packageBaseId: r.PackageBaseID,
    packageBase: r.PackageBase,
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
    depends: r.Depends,
    makeDepends: r.MakeDepends,
    optDepends: r.OptDepends,
    conflicts: r.Conflicts,
    provides: r.Provides,
    replaces: r.Replaces,
    groups: r.Groups,
    licence: r.Licence,
    keywords: r.Keywords,
  )

# TODO: declare raised exceptions
proc search*(by: QueryBy = NameDesc, keyword: string): seq[AurPackage] =
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
      raise newException(AurQueryError, queryResult.error.get())
  else:
    raise newException(
        AurInvalidSearchKeywordError,
        &"keyword must be at least 2 chars long (was '{keyword}')"
      )


proc info*(packageNames: seq[string]): seq[AurPackage] =
  let params = @[("v", $apiVersion), ("type", $QueryType.Info)] & packageNames.map(x => ("arg[]", x))
  let uri = endpoint ? params
  let infoResult = client.getContent($uri)
    .parseJson()
    .to(InfoResult)
  if infoResult.error.isNone:
    return infoResult
            .results
            .map(toModel)
  else:
    raise newException(AurQueryError, infoResult.error.get())

proc info*(packageNames: varargs[string]): seq[AurPackage] = info(@packageNames)

proc info*(packageName: string): Option[AurPackage] = 
  let packages = info([packageName])
  if packages.len >= 1:
    return packages[0].some
  else:
    return none(AurPackage)