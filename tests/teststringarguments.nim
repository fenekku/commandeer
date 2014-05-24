## When testing commandeer run it as follows on the command line:
## ./teststringarguments file1 file2 file3 --testing

import unittest

import commandeer

commandLine:
  arguments filenames, string, false
  option testing, bool, "testing", "t"

echo("filenames = ", filenames)

if testing:

  check filenames[0] == "file1"
  check filenames[1] == "file2"
  check filenames[2] == "file3"

  echo "Tests Pass"