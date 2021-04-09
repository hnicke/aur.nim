import 
  httpclient,
  json,
  strformat,
  options,
  sequtils

let client = newHttpClient()
const endpoint = "https://aur.archlinux.org/rpc/?v=5"


type
  AurPackage = object
    id*: int
    name: string
    packageBaseId: int
    packageBase: string
    version: string
    description: string
    url: string
    numVotes: int
    popularity: float
    outOfDate: Option[int]
    maintainer: string
    firstSubmitted: int
    lastModified: int
    urlPath: string

  QueryType = enum
    search
    info

  QueryField* = enum
    name                    ## search by package name only
    nameDesc  = "name-desc" ## search by package name and description
    maintainer              ## search by package maintainer
    depends                 ## search for packages that depend on keywords
    makedepends             ## search for packages that makedepend on keywords
    optdepends              ## search for packages that optdepend on keywords
    checkdepends            ## search for packages that checkdepend on keywords

  AurPackageResult* = object
    ID*: int
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

  QueryResult = object
    version: int
    `type`: QueryType
    resultcount: int
    results: seq[AurPackageResult]


proc toModel(r: AUrPackageResult): AurPackage =
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
    outOfDate: r.OutOfDate,
    maintainer: r.Maintainer,
    firstSubmitted: r.FirstSubmitted,
    lastModified: r.LastModified,
    urlPath: r.URLPath,
  )


# proc request(parameter: string): string {.raises: [].} =
  # return client.getContent(string)


proc query*(by: QueryField = QueryField.nameDesc, keyword: string): seq[AurPackage] =
  let data = client.getContent(endpoint & &"&type={QueryType.search}&by={by}&arg={keyword}")
  return parseJson(data)
    .to(QueryResult)
    .results
    .map(toModel)

proc listOrphanedPackages*(): seq[AurPackage] =
  return query(maintainer, "")
