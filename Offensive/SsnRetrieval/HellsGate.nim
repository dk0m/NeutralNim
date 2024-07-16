import ../../General/PeImageParsing/Parser, winim, ptr_math, strutils, os, std/options


type
    VxTableEntry* = object
     pAddress*: PVOID
     wSystemCall*: WORD
    
proc getVxTableEntry*(fnAddress: PVOID): Option[VxTableEntry] =
    var fnAddr = cast[PBYTE](fnAddress)
    var cw = 0

    while true:
        
        if (cast[PBYTE](fnAddr + cw)[] == 0x0f and cast[PBYTE](fnAddr + cw + 1)[] == 0x05):
            return none(VxTableEntry)

        if (cast[PBYTE](fnAddr + cw)[] == 0xC3):
            return none(VxTableEntry)
        
        if cast[PBYTE](fnAddr + cw)[] == 0x4C and cast[PBYTE](fnAddr + 1 + cw)[] == 0x8B and cast[PBYTE](fnAddr + 2 + cw)[] == 0xD1 and cast[PBYTE](fnAddr + 3 + cw)[] == 0xB8 and cast[PBYTE](fnAddr + 6 + cw)[] == 0x00 and cast[PBYTE](fnAddr + 7 + cw)[] == 0x00:
            var pHigh = cast[PBYTE](fnAddr + 5 + cw)[]
            var pLow = cast[PBYTE](fnAddr + 4 + cw)[]

            var ssn = (pHigh shl 8) or pLow

            return some(VxTableEntry(
                pAddress: fnAddress,
                wSystemCall: cast[WORD](ssn)
            ))


        cw = cw + 1



# Simplified version of Hells Gate, You can add function name hashing, But This is only meant to bea  way to retrieve SSNs from ntdll memory.

# Example Of Usage (Dumping SSNs From NTDLL Memory) #

when isMainModule:
    var peNtdll = parsePe(cast[PVOID](LoadLibraryA("NTDLL")))

    var peBase = peNtdll.ImageBase
    var expDir = peNtdll.Directories.ExportDirectory

    var funcNames = cast[PDWORD](peBase + expDir.AddressOfNames)
    var funcOrds = cast[PWORD](peBase + expDir.AddressOfNameOrdinals)
    var funcAddrs = cast[PDWORD](peBase + expDir.AddressOfFunctions)

    for i in 0 .. expDir.NumberOfFunctions - 1:
        var fnName: LPCSTR = cast[LPCSTR](peBase + funcNames[i])
        var fnOrdinal: WORD = cast[WORD](funcOrds[i])
        var fnAddr: PVOID = cast[PVOID](peBase + funcAddrs[DWORD(fnOrdinal)])

        if ($fnName).startsWith("Zw"):
            var tableEntry = getVxTableEntry(fnAddr)
            if tableEntry.isSome():
                var aTableEntry = tableEntry.get()
                echo($fnName & " " & aTableEntry.wSystemCall.toHex())
