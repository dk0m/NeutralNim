import winim

{.passC:"-masm=intel".}

proc GetPeb*(): PPEB {.asmNoStackFrame.} =
    asm """
    mov rax, gs:[0x60]
    ret
    """

# Example Of Usage #

when isMainModule:
    var processPeb = GetPeb()

    var processParams = processPeb.ProcessParameters

    var imagePathName = processParams.ImagePathName
    var commandLine = processParams.CommandLine

    echo "Image Path Name: " & $imagePathName.Buffer
    echo "Command Line: " & $commandLine.Buffer
