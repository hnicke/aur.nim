import unittest

import aurclient
test "fetch package":
  let packages = query(QueryField.name, "google-chrome")
  check packages.len != 0
