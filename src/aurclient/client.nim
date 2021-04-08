import 
  httpclient,
  json,
  strformat

let client = newHttpClient()
const endpoint = "https://aur.archlinux.org/rpc/?v=5"

type
  AurPackage* = object
    id*: string
    name: string
    packageBaseId: string
    packageBase: string
    version: string
    description: string
    url: string
    numVotes: int
    popularity: float
    outOfDate: bool
    maintainer: string
    firstSubmitted: string
    lastModified: string

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
  # exit()
  let data = client.getContent(endpoint & &"&type=search&by={by}&arg={keyword}")
  # echo data
  let json_data = parseJson(data)
  echo json_data
  echo typeof(json_data)
  return @[]

proc listOrphanedPackages*(): seq[AurPackage] =
  return query(maintainer, "")


discard query(maintainer, "hnicke")