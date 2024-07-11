import Parser, winim, os

var pe = parsePeFile("C:\\Windows\\System32\\ntoskrnl.exe")

# Example Of Usage (Parsing ntoskrnl) #

when isMainModule:
    for peExport in pe.Exports:
        echo("Export: " & $peExport.Name & " Ordinal: " & $peExport.Ordinal)


    for peImport in pe.Imports:
        echo("[ " & $peImport.DllName & " ]")

        for impFunc in peImport.ImportedFunctions:
            echo("\tImport: " & $impFunc.Name & " RVA: " & repr(impFunc.FunctionRva))

        echo("----------------")