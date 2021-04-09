import unittest
import options

import aur
test "search package":
  let packages = search(Name, "google-chrome")
  check packages.len != 0

test "search package fails when keyword length is < 2":
  expect AurInvalidSearchKeywordError:
    discard search(Maintainer, "a")

test "get info for packages":
  let packages = info(["google-chrome", "sodalite"])
  check packages.len == 2

test "get info for packages (varags)":
  let packages = info("google-chrome", "sodalite")
  check packages.len == 2

test "get info for single package":
  let package = info("google-chrome")
  check package.isSome

test "get info for non-existent single package":
  let package = info("medoesntexist.123")
  check package.isNone