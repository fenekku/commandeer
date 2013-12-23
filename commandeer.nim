
import strutils
import tables


var
  arguments = newSeq[ string ]()
  shortOptions = initTable[string, string](32)
  longOptions = initTable[string, string](32)
  argNumber = 0
  error : ref E_Base

## String conversion
proc convert(s : string, typ : char): char =
  result = s[0]
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
  bind error

  var identifier : typ

  if arguments.len <= argNumber:
    error = newException(E_Base, "Not enough command-line arguments")
  else:
    var typeVar : typ
    try:
      identifier = convert(arguments[argNumber], typeVar)
      inc(argNumber)
    except EInvalidValue:
      error = getCurrentException()


template option*(identifier : expr, typ : expr, lName : string, sName : string): stmt {.immediate.} =
  bind shortOptions
  bind longOptions
  bind convert
  bind error

  var identifier : typ

  block:
    var typeVar : typ
    if longOptions.hasKey(lName):
      try:
        identifier = convert(longOptions[lName], typeVar)
      except EInvalidValue:
        error = getCurrentException()
    elif shortOptions.hasKey(sName):
      try:
        identifier = convert(shortOptions[sName], typeVar)
      except EInvalidValue:
        error = getCurrentException()


template exitoption*(lName, sName, msg : string): stmt =
  bind shortOptions
  bind longOptions

  if longOptions.hasKey(lName):
    quit msg
  elif shortOptions.hasKey(sName):
    quit msg


template commandLine*(s : stmt): stmt {.immediate.} =
  bind arguments
  bind shortOptions
  bind longOptions
  bind error

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
  if not error.isNil:
    quit error.msg


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