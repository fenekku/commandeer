import commandeer


commandline:
  argument first_required, string
  option first_optional, string, "optional1", "o1"
  option testing, bool, "testing", "t"

echo "First Required: ", first_required
echo "First Optional: ", first_optional

if testing:
  doAssert(first_required == "1")
  doAssert(first_optional == "2")
else:
  if first_optional == "2":
    quit "--testing was supposed to be true", QuitFailure
