import algorithm
import parseopt2
import sequtils
import strutils
import tables
import typetraits


type
  assignmentProc = proc(value: string)
  Quantifier {.pure.} = enum
    single, oneOrMore, zeroOrMore
  Assigner = tuple[assign: assignmentProc, quantity: Quantifier]
  # We only allow one level of Subcommand, so not a recursive definition
  Subcommand = ref object
    argumentAssigners: seq[Assigner]
    index: int
    shortOptionAssigners: TableRef[string, Assigner]
    longOptionAssigners: TableRef[string, Assigner]
    activate: proc()


proc newSubcommand(p: proc() = proc()=discard): Subcommand =
  new(result)
  result.argumentAssigners = newSeq[Assigner]()
  result.index = 0
  result.shortOptionAssigners = newTable[string, Assigner]()
  result.longOptionAssigners = newTable[string, Assigner]()
  result.activate = p


proc mergeIn(s1: var Subcommand, s2: Subcommand) =
  s1.argumentAssigners = s2.argumentAssigners
  for key, value in s2.shortOptionAssigners.pairs():
    s1.shortOptionAssigners[key] = value
  for key, value in s2.longOptionAssigners.pairs():
    s1.longOptionAssigners[key] = value
  s1.activate = s2.activate


proc getOptionAssigner(s: Subcommand, key: string): Assigner =
  if key in s.longOptionAssigners:
    return s.longOptionAssigners[key]
  elif key in s.shortOptionAssigners:
    return s.shortOptionAssigners[key]
  else:
    # Ignore superfluous extra option
    return (proc(value: string) {.closure.} = discard, Quantifier.single)


var errorMessage: string = ""
var currentSubcommand = newSubcommand()
var subCommands = newTable[string, Subcommand]()
var cliTokens: seq[GetoptResult]
var inSubcommand = false

## Debugging procs ##

proc `$`*(f: assignmentProc): string = "assignmentProc"


proc `$`*(s: Subcommand): string =
  result =
    "{" &
    "argumentAssigners: " & $s.argumentAssigners & ", " &
    "shorts: " & $s.shortOptionAssigners & ", " &
    "longs: " & $s.longOptionAssigners &
    "}"


## Conversion procs ##

proc assignConversion(variable: var int, value: string) =
  variable = strutils.parseInt(value)


proc assignConversion(variable: var seq[int], value: string) =
  variable.add(strutils.parseInt(value))


proc assignConversion(variable: var float, value: string) =
  variable = strutils.parseFloat(value)


proc assignConversion(variable: var seq[float], value: string) =
  variable.add(strutils.parseFloat(value))


proc assignConversion(variable: var string, value: string) =
  if value == "": raise newException(ValueError, "Empty string")
  variable = value


proc assignConversion(variable: var seq[string], value: string) =
  variable.add(value)


proc assignConversion(variable: var bool, value: string) =
  ## will accept "yes", "true", "on", "1" as true values
  ## the only way we get an empty string here is because of a key
  ## with no value, in which case the presence of the key is enough
  ## to return true
  variable = if value == "": true else: strutils.parseBool(value)


proc assignConversion(variable: var seq[bool], value: string) =
  variable.add(if value == "": true else: strutils.parseBool(value))


proc assignConversion(variable: var char, value: string) =
  if value == "": raise newException(ValueError, "Empty string")
  variable = value[0]


proc assignConversion(variable: var seq[char], value: string) =
  variable.add(value[0])


## Interpretation of the tokens  ##

type
  CmdTokenKind {.pure.} = enum
    argument, option, subcommand, empty
  CmdToken = tuple
    getOptResult: GetoptResult
    kind: CmdTokenKind


proc key(cmdToken: CmdToken): string =
  return cmdToken.getOptResult.key


proc value(cmdToken: CmdToken): string =
  if cmdToken.kind == CmdTokenKind.argument:
    # key is the value for cmdArgument
    return cmdToken.getOptResult.key
  return cmdToken.getOptResult.val


proc obtainCmdToken(consume: bool): CmdToken =
  if cliTokens.len() > 0:
    let cliToken = if consume: cliTokens.pop() else: cliTokens[^1]
    if not inSubcommand and currentSubcommand.index == 0 and cliToken.key in subcommands:
      return (getOptResult: cliToken, kind: CmdTokenKind.subcommand)
    elif cliToken.kind in [parseopt2.cmdLongOption, parseopt2.cmdShortOption]:
      return (getOptResult: cliToken, kind: CmdTokenKind.option)
    else:
      return (getOptResult: cliToken, kind: CmdTokenKind.argument)
  return (getOptResult: (kind: CmdLineKind.cmdEnd, key: "", val: ""), kind: CmdTokenKind.empty)


proc readCmdToken(): CmdToken =
  return obtainCmdToken(consume=true)


proc peekCmdToken(): CmdToken =
  return obtainCmdToken(consume=false)


proc addToken(token: CmdToken) =
  cliTokens.add(token.getOptResult)


proc exitWithErrorMessage(msg="") =
  if msg != "" and errorMessage != "":
    quit msg & "\n" & errorMessage, QuitFailure
  elif msg != "":
    quit msg, QuitFailure
  elif errorMessage != "":
    quit errorMessage, QuitFailure
  else:
    quit QuitFailure


proc interpretCli() =
  while true:
    var token = readCmdToken()

    case token.kind
    of CmdTokenKind.empty:
      # If didn't fulfill required arguments
      if currentSubcommand.index < len(currentSubcommand.argumentAssigners):
        let last = high(currentSubcommand.argumentAssigners)
        for assigner in currentSubcommand.argumentAssigners[currentSubcommand.index..last]:
          if assigner.quantity != Quantifier.zeroOrMore:
            exitWithErrorMessage("Missing command line arguments")
      break

    of CmdTokenKind.subcommand:
      currentSubcommand.mergeIn(subcommands[token.key])
      currentSubcommand.activate()

    of CmdTokenKind.argument:
      # Ignore superfluous extra arguments
      if currentSubcommand.index >= len(currentSubcommand.argumentAssigners):
        continue

      var assigner = currentSubcommand.argumentAssigners[currentSubcommand.index]
      var atLeastOneAssignment = false

      try:
        assigner.assign(token.value)
        atLeastOneAssignment = true

        # arguments?
        if assigner.quantity in [Quantifier.zeroOrMore, Quantifier.oneOrMore]:
          # broken by emptiness, conversion, option
          while peekCmdToken().kind == CmdTokenKind.argument:
            token = readCmdToken()
            assigner.assign(token.value)
      except ValueError:
        case assigner.quantity
        of Quantifier.zeroOrMore:
          addToken(token)
        of Quantifier.single, Quantifier.oneOrMore:
          if atLeastOneAssignment:
            addToken(token)
          else:
            exitWithErrorMessage(getCurrentExceptionMsg())

      inc(currentSubcommand.index)

    of CmdTokenKind.option:
      var assigner = currentSubcommand.getOptionAssigner(token.key)

      try:
        assigner.assign(token.value)
      except ValueError:
        # There might be a space separating key and value
        # The value is the next token
        if peekCmdToken().kind == CmdTokenKind.argument:
          token = readCmdToken()
          try:
            assigner.assign(token.value)
          except ValueError:
            exitWithErrorMessage(getCurrentExceptionMsg())
        elif token.value != "":
          # Conversion error
          exitWithErrorMessage(getCurrentExceptionMsg())
        else:
          exitWithErrorMessage("Missing value for option '" & token.key & "'")


## Command line dsl keywords ##

template argument*(identifier: untyped, t: typeDesc): untyped =
  var identifier: t
  currentSubcommand.argumentAssigners.add((
    proc(value: string) {.closure.} =
      try:
        assignConversion(identifier, value)
      except ValueError:
        raise newException(
          ValueError,
          "Couldn't convert '" & value & "' to " & name(t)
        )
    ,
    Quantifier.single
  ))


template arguments*(identifier: untyped, t: typeDesc, atLeast1: bool=true): untyped =
  var identifier = newSeq[t]()
  currentSubcommand.argumentAssigners.add(
    (
      proc(value: string) {.closure.} =
        try:
          assignConversion(identifier, value)
        except ValueError:
          raise newException(
            ValueError,
            "Couldn't convert '" & value & "' to " & name(t)
          )
      ,
      if atLeast1: Quantifier.oneOrMore else: Quantifier.zeroOrMore
    )
  )


template option*(identifier: untyped, t: typeDesc, long, short: string,
                 default: t): untyped =
  var identifier: t = default
  var assigner = (
    proc(value: string) {.closure.} =
      try:
        assignConversion(identifier, value)
      except ValueError:
        raise newException(
          ValueError,
          "Couldn't convert '" & value & "' to " & name(t)
        )
    ,
    Quantifier.single
  )
  currentSubcommand.longOptionAssigners[long] = assigner
  currentSubcommand.shortOptionAssigners[short] = assigner


template option*(identifier: untyped, t: typeDesc, long, short: string): untyped =
  var identifier: t
  var assigner = (
    proc(value: string) {.closure.} =
      try:
        assignConversion(identifier, value)
      except ValueError:
        raise newException(
          ValueError,
          "Couldn't convert '" & value & "' to " & name(t)
        )
    ,
    Quantifier.single
  )
  currentSubcommand.longOptionAssigners[long] = assigner
  currentSubcommand.shortOptionAssigners[short] = assigner


template exitoption*(long, short, msg: string): untyped =
  var exiter = (
    (proc(value: string) {.closure.} = quit msg, QuitSuccess),
    Quantifier.single
  )
  currentSubcommand.longOptionAssigners[long] = exiter
  currentSubcommand.shortOptionAssigners[short] = exiter


template errormsg*(msg: string): untyped =
  errorMessage = msg


template subcommand*(identifier: untyped, subcommandNames: varargs[string],
                     statements: untyped): untyped =
  var identifier: bool = false
  var thisSubcommand = newSubcommand(
    proc() =
      identifier = true
      inSubcommand = true
  )

  var tmpSubcommand = currentSubcommand
  currentSubcommand = thisSubcommand
  statements
  currentSubcommand = tmpSubcommand

  for subcommandName in subcommandNames:
    subCommands[subcommandName] = thisSubcommand

template commandline*(statements: untyped): untyped =
  cliTokens = reversed(toSeq(parseopt2.getopt()))
  statements
  interpretCli()
