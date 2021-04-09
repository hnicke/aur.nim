import unittest

import aurclient
test "search package":
  let packages = search(Name, "google-chrome")
  check packages.len != 0

test "search package fails when keyword length is < 2":
  expect AurInvalidSearchKeywordError:
    discard search(Maintainer, "a")

test "get info for package":
  let packages = info(@["google-chrome"])
  check packages.len == 1

test "get info for packages":
  let packages = info(@["google-chrome", "sodalite"])
  check packages.len == 2
