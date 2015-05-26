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
      break

if compiled == 0:
  var j = parseFile("tests/tests.json")
  var exitTuple : tuple[output: TaintedString, exitCode: int]
  for jo in j["tests"].items():
    try:
      exitTuple = execCmdEx("tests" / jo["file name"].str & " " & jo["args"].str)
      doAssert(exitTuple.exitCode == jo["expect"].num)
      if exitTuple.exitCode != 0:
        doAssert(jo["msg"].str == exitTuple.output)
      write(stdout, ".")
    except:
      write(stdout, "F")
      echo ""
      echo "Test '", jo["test name"].str, "' failed."
      echo "Expected: ", if jo["msg"] != nil: jo["msg"].str else: $jo["expect"].num
      echo "Got: ", exitTuple.output
      quit(QuitFailure)

  echo ""
  echo "Tests pass!"
