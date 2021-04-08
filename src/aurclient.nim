import 
  httpclient,
  json,
  strformat,
  options

let client = newHttpClient()
const endpoint = "https://aur.archlinux.org/rpc/?v=5"

type
  AurPackage* = object
    ID*: int
    Name: string
    PackageBaseID: int
    PackageBase: string
    Version: string
    Description: string
    URL: string
    NumVotes: int
    Popularity: float
    OutOfDate: Option[bool]
    Maintainer: string
    FirstSubmitted: int
    LastModified: int
    URLPath: string

  QueryField* = enum
    name                    ## search by package name only
    nameDesc  = "name-desc" ## search by package name and description
    maintainer              ## search by package maintainer
    depends                 ## search for packages that depend on keywords
    makedepends             ## search for packages that makedepend on keywords
    optdepends              ## search for packages that optdepend on keywords
    checkdepends            ## search for packages that checkdepend on keywords


# proc request(parameter: string): string {.raises: [].} =
  # return client.getContent(string)


proc query*(by: QueryField = QueryField.nameDesc, keyword: string): seq[AurPackage] =
  echo endpoint & &"&type=search&by={by}&arg={keyword}"
  let data = client.getContent(endpoint & &"&type=search&by={by}&arg={keyword}")
  let json_data = parseJson(data)
  # TODO handle error response
  var packages = newSeq[AurPackage]()
  for elem in json_data["results"].elems:
      echo elem
      let package = json.to(elem, AurPackage)
      packages.add(package)
  return packages

proc listOrphanedPackages*(): seq[AurPackage] =
  return query(maintainer, "")
