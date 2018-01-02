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
    var cmd = "tests" / jo["file name"].str & " " & jo["args"].str
    try:
      exitTuple = execCmdEx(cmd)
      doAssert(exitTuple.exitCode == jo["expect"].num)
      if jo.hasKey("msg"): doAssert(jo["msg"].str == exitTuple.output)
      write(stdout, ".")
    except:
      write(stdout, "F")
      echo ""
      echo "Test '", jo["test name"].str, "' failed."
      echo "Ran " & cmd
      echo "Expected: ", if jo.hasKey("msg"): repr(jo["msg"].str) else: $jo["expect"].num
      echo "Got: ", repr(exitTuple.output)
      quit(QuitFailure)

  echo ""
  echo "Tests pass!"
