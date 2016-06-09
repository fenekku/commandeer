import
  osproc,
  os,
  json,
  strutils


var compiled = -1

for nimFile in walkDir("tests/"):
  if nimFile.kind == pcFile and nimFile.path.endswith(".nim"):
    compiled = execCmd("nim compile --verbosity:0 --hints:off --warnings:off " & nimFile.path)
    if compiled != 0:
      echo "Could not compile " & nimFile.path
      quit(QuitFailure)

if compiled == 0:
  var j = parseFile("tests/tests.json")
  var exitTuple : tuple[output: string, exitCode: int]

  for jo in j["tests"].items():
    try:
      exitTuple = execCmdEx("tests" / jo["file name"].str & " " & jo["args"].str)
      doAssert(exitTuple.exitCode == jo["expect"].num)

      try:
        doAssert(jo["msg"].str == exitTuple.output)
      except KeyError:
        discard

      write(stdout, ".")
    except:
      write(stdout, "F")
      echo ""
      echo "Test '", jo["test name"].str, "' failed."
      echo "Expected: ", try: repr(jo["msg"].str) except KeyError: $jo["expect"].num
      echo "Got: ", repr(exitTuple.output)
      quit(QuitFailure)

  echo ""
  echo "Tests pass!"
