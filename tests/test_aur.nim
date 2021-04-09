import unittest
import options

import aur
test "search package":
  let pkgs = search(Name, "google-chrome")
  check pkgs.len != 0

test "search package fails when keyword length is < 2":
  expect AurInvalidSearchKeywordError:
    discard search(Maintainer, "a")

test "get info for packages":
  let pkgs = info(["google-chrome", "sodalite"])
  check pkgs.len == 2

test "get info for packages (varags)":
  let pkgs = info("google-chrome", "sodalite")
  check pkgs.len == 2

test "get info for single package":
  let pkg = info("google-chrome")
  check pkg.isSome

test "get info for non-existent single package":
  let pkg = info("medoesntexist.123")
  check pkg.isNone