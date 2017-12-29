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
  # We only allow one level of SubCommand, so not
  # a recursive definition
  SubCommand = ref object
    argumentAssigners: seq[Assigner]
    index: int
    shortOptionAssigners: TableRef[string, assignmentProc]
    longOptionAssigners: TableRef[string, assignmentProc]
    activate: proc()


proc newSubCommand(p: proc() = proc()=discard): SubCommand =
  new(result)
  result.argumentAssigners = newSeq[Assigner]()
  result.index = 0
  result.shortOptionAssigners = newTable[string, assignmentProc]()
  result.longOptionAssigners = newTable[string, assignmentProc]()
  result.activate = p  # proc() = discard


var errorMessage: string = ""
var currentSubCommand = newSubCommand()
var subCommands = newTable[string, SubCommand]()
subCommands[""] = currentSubCommand
var cliTokens: seq[GetoptResult]


## Debugging, conversion and utility procs ##

# proc `$`*(f: assignmentProc): string = "assignmentProc"


# proc `$`*(s: SubCommand): string =
#   result =
#     "{" &
#     "argumentAssigners: " & $s.argumentAssigners & ", " &
#     "shorts: " & $s.shortOptionAssigners & ", " &
#     "longs: " & $s.longOptionAssigners &
#     "}"


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


proc exitWithErrorMessage(msg="") =
  if msg != "" and errorMessage != "":
    quit msg & "\n" & errorMessage, QuitFailure
  elif msg != "":
    quit msg, QuitFailure
  elif errorMessage != "":
    quit errorMessage, QuitFailure
  else:
    quit QuitFailure


proc getOptionAssignment(key: string): assignmentProc =
  var tmpSubCommand = currentSubCommand
  var optionAssignmentProcs: TableRef[string, assignmentProc]

  while not tmpSubCommand.isNil and optionAssignmentProcs.isNil:
    if key in tmpSubCommand.longOptionAssigners:
      optionAssignmentProcs = tmpSubCommand.longOptionAssigners
    elif key in tmpSubCommand.shortOptionAssigners:
      optionAssignmentProcs = tmpSubCommand.shortOptionAssigners
    else:
      if tmpSubCommand == subcommands[""]:
        tmpSubCommand = nil
      else:
        tmpSubCommand = subcommands[""]

  if tmpSubCommand.isNil:
    return nil
  else:
    return optionAssignmentProcs[key]


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
    if currentSubCommand.index == 0 and cliToken.key in subcommands:
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


proc interpretCli() =
  while true:
    var token = readCmdToken()

    case token.kind
    of CmdTokenKind.empty:
      # If didn't fulfill required arguments
      if currentSubCommand.index < len(currentSubCommand.argumentAssigners):
        let last = high(currentSubCommand.argumentAssigners)
        for assigner in currentSubCommand.argumentAssigners[currentSubCommand.index..last]:
          if assigner.quantity != Quantifier.zeroOrMore:
            exitWithErrorMessage("Missing command line arguments")
      break

    of CmdTokenKind.subcommand:
      currentSubCommand = subcommands[token.key]
      currentSubCommand.activate()

    of CmdTokenKind.argument:
      # Ignore superfluous extra arguments
      if currentSubCommand.index >= len(currentSubCommand.argumentAssigners):
        continue

      var assigner = currentSubCommand.argumentAssigners[currentSubCommand.index]
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

      inc(currentSubCommand.index)

    of CmdTokenKind.option:
      var assign = getOptionAssignment(token.key)

      if assign.isNil:
        # Ignore superfluous extra option
        continue

      try:
        assign(token.value)
      except ValueError:
        if peekCmdToken().kind == CmdTokenKind.argument:
          # There might be a space separating key and value
          # The value is the next token
          token = readCmdToken()
          try:
            assign(token.value)
          except ValueError:
            exitWithErrorMessage(getCurrentExceptionMsg())
        elif token.value != "":
          exitWithErrorMessage(getCurrentExceptionMsg())
        else:
          exitWithErrorMessage("Missing value for option '" & token.key & "'")



## Command line dsl keywords ##

template argument*(identifier: untyped, t: typeDesc): untyped =
  var identifier: t
  currentSubCommand.argumentAssigners.add((
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
  currentSubCommand.argumentAssigners.add(
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
  var assignment = proc(value: string) =
    try:
      assignConversion(identifier, value)
    except ValueError:
      raise newException(
        ValueError,
        "Couldn't convert '" & value & "' to " & name(t)
      )
  currentSubCommand.longOptionAssigners[long] = assignment
  currentSubCommand.shortOptionAssigners[short] = assignment


template option*(identifier: untyped, t: typeDesc, long, short: string): untyped =
  var identifier: t
  var assignment = proc(value: string) =
    try:
      assignConversion(identifier, value)
    except ValueError:
      raise newException(
        ValueError,
        "Couldn't convert '" & value & "' to " & name(t)
      )
  currentSubCommand.longOptionAssigners[long] = assignment
  currentSubCommand.shortOptionAssigners[short] = assignment


template exitoption*(long, short, msg: string): untyped =
  var exiter = proc(value: string) =
    quit msg, QuitSuccess
  currentSubCommand.longOptionAssigners[long] = exiter
  currentSubCommand.shortOptionAssigners[short] = exiter


template errormsg*(msg: string): untyped =
  errorMessage = msg


template subcommand*(identifier: untyped, subcommandNames: varargs[string],
                     statements: untyped): untyped =
  var identifier: bool = false
  var thisSubCommand = newSubCommand(proc() = identifier = true)

  currentSubCommand = thisSubCommand
  statements
  currentSubCommand = subCommands[""]

  for subcommandName in subcommandNames:
    subCommands[subcommandName] = thisSubCommand


template commandline*(statements: untyped): untyped =
  cliTokens = reversed(toSeq(parseopt2.getopt()))
  statements
  interpretCli()
