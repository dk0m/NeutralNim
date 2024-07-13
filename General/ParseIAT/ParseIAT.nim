import winim, ./PeImageParsing/Parser, ptr_math

# from PeFileParsing but edited a little bit.
type 
    PeImportedFunction* = object
     Name*: string
     FunctionAddress*: PVOID

    PeImport* = object
     Dll*: string
     Functions*: seq[PeImportedFunction]

proc toString(flexableArray: array[1, BYTE]): string =
    var pEntry = cast[PBYTE](addr(flexableArray))
    var i = 0

    while pEntry[i] != cast[BYTE]('\0'):
        result.add(cast[char](pEntry[i]))
        i = i + 1

proc RvaToVa[T](baseAddr: DWORD_PTR, offset: DWORD | ULONGLONG): T =
    return cast[T](baseAddr + offset)

proc parseIat*(): seq[PeImport] =
    var peFile = parsePe(GetCurrentPeBase())
    var importDir = peFile.Directories.ImportDirectory
    var imgBase = peFile.ImageBase

    while (importDir.Name != 0):
        var dllName = RvaToVa[LPCSTR](imgBase, importDir.Name)
        var orgFt = RvaToVa[PIMAGE_THUNK_DATA](imgBase, importDir.union1.OriginalFirstThunk)
        var fT = RvaToVa[PIMAGE_THUNK_DATA](imgBase, importDir.FirstThunk)
        var importedFunctions: seq[PeImportedFunction]
        while orgFt.u1.AddressOfData != 0:
            var fncNameStruct = RvaToVa[PIMAGE_IMPORT_BY_NAME](imgBase, orgFt.u1.AddressOfData)
            var fnName = toString(fncNameStruct.Name)
            var fnAddr = fT.u1.Function
            orgFt = orgFt + 1
            fT = fT + 1
            add(importedFunctions, PeImportedFunction(
                Name: fnName,
                FunctionAddress: cast[PVOID](fnAddr)
            ))

        add(result, PeImport(
                Dll: $dllName,
                Functions: importedFunctions
        ))

        importDir = importDir + 1

proc searchInIat(targetFnName: string): PeImportedFunction =
    for fImport in parseIat():
        for function in fImport.Functions:
            if function.Name == targetFnName:
                return function


when isMainModule:
    var foundFunc = searchInIat("GetCurrentProcessId")
    echo("Found Function At 0x" & repr(foundFunc.FunctionAddress))
