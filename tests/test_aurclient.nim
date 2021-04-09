import unittest

import aurclient
test "fetch package":
  let packages = query(Name, "google-chrome")
  check packages.len != 0
