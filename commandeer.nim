
import strutils
import tables

var
  arguments = newSeq[ string ]()
  shortOptions = initTable[string, string](32)
  longOptions = initTable[string, string](32)
  argNumber = 0

## String conversion
proc convert(s : string, typ : int): int =
  result = parseInt(s)
proc convert(s : string, typ : float): float =
  result = parseFloat(s)
proc convert(s : string, typ : bool): bool =
  ## will accept "yes", "true" as true values
  if s == "":
    ## the only way we get an empty string here is because of a key
    ## with no value, in which case the presence of the key is enough
    ## to return true
    result = true
  else:
    result = parseBool(s)
proc convert(s : string, typ : string): string =
    result = s.strip


template argument*(identifier : expr, typ : expr): stmt {.immediate.} =
  bind arguments
  bind argNumber
  bind convert

  if arguments.len <= argNumber:
    quit "Not enough command-line arguments"

  var identifier : typ
  block:
    var typeVar : typ
    identifier = convert(arguments[argNumber], typeVar)
    inc(argNumber)

template option*(identifier : expr, typ : expr, lName : string, sName : string): stmt {.immediate.} =
  bind shortOptions
  bind longOptions
  bind convert

  var identifier : typ
  block:
    var typeVar : typ
    if longOptions.hasKey(lName):
      identifier = convert(longOptions[lName], typeVar)
    elif shortOptions.hasKey(sName):
      identifier = convert(shortOptions[sName], typeVar)


template commandLine*(s : stmt): stmt {.immediate.} =
  bind arguments
  bind shortOptions
  bind longOptions

  import parseopt
  import tables
  for kind, key, val in getopt():
    case kind
    of cmdArgument:
      arguments.add(key)
    of cmdLongOption:
      longOptions.add(key, val)
    of cmdShortOption:
      shortOptions[key] = val
    else:
      echo "other kind"

  #Call the passed statements so that the above templates are called
  s


when isMainModule:
  import unittest

  test "convert returns type value from strings":
    var intVar : int
    var floatVar : float
    var boolVar : bool
    var stringVar : string

    check convert("10", intVar) == 10
    check convert("10.0", floatVar) == 10
    check convert("10", floatVar) == 10
    check convert("yes", boolVar) == true
    check convert("false", boolVar) == false
    check convert("no ", stringVar) == "no"