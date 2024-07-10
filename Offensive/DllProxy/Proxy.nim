import ../../General/PeParsing/Parser, winim, ptr_math, cligen, strformat, strutils


proc proxyDll*(dllPath: string, outputPath: string, suffix: string, args: seq[string]) = 
    var peNtdll = parsePe(cast[PVOID](LoadLibraryA(dllPath)))

    var peBase = peNtdll.ImageBase
    var expDir = peNtdll.Directories.ExportDirectory

    var funcNames = cast[PDWORD](peBase + expDir.AddressOfNames)
    var funcOrds = cast[PWORD](peBase + expDir.AddressOfNameOrdinals)
    var funcAddrs = cast[PDWORD](peBase + expDir.AddressOfFunctions)

    var outputFile = open(outputPath, fmAppend)
    var amountProxied = 0

    for i in 0 .. expDir.NumberOfNames - 1:
        var fnName: LPCSTR = cast[LPCSTR](peBase + funcNames[i])
        var fnOrdinal: WORD = cast[WORD](funcOrds[i])
        var fnAddr: PVOID = cast[PVOID](peBase + funcAddrs[DWORD(fnOrdinal)])
        
        var fnNameStr = $fnName
        var pragmaDllPath = dllPath.replace(".dll","").replace(r"\",r"\\")
        var mainPart = fmt"/export:{fnNameStr}={pragmaDllPath}{suffix}.{fnNameStr}"

        var pragmaComment = "#pragma comment(linker , " & "\"" & mainPart & "\")\n"

        echo(fmt"Proxying {fnNameStr}")

        outputFile.write(pragmaComment)
        amountProxied += 1

    echo(fmt"Done, Proxied {amountProxied} Functions!")
    outputFile.close()

when isMainModule:
    dispatch proxyDll