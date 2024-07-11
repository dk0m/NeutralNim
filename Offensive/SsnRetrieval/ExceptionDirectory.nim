import winim, ../../General/PeImageParsing/Parser, ptr_math, strutils

# OffensivsNim's SSDT Dump But My Version Using Pe Parser

type 
    SystemCall* = object
     Ssn: int
     Name: string
     Address: PVOID


proc GetSSDT*(): seq[SystemCall] =

    var peImage = parsePe(cast[PVOID](GetModuleHandleA("NTDLL")))
    var peBase = peImage.ImageBase

    var peDirs = peImage.Directories

    var exceptionDir = peDirs.RtfEntryDirectory
    var exportDir = peDirs.ExportDirectory

    var funcNames = cast[PDWORD](peBase + exportDir.AddressOfNames)
    var funcOrds = cast[PWORD](peBase + exportDir.AddressOfNameOrdinals)
    var funcAddrs = cast[PDWORD](peBase + exportDir.AddressOfFunctions)


    var currentIndex = 0
    var ssn = 0

    while exceptionDir[currentIndex].BeginAddress != 0:
        var beginAddress = exceptionDir[currentIndex].BeginAddress    

        for x in 0 ..< exportDir.NumberOfFunctions:
            var fnName: string = $(cast[LPCSTR](peBase + funcNames[x]))
            var fnOrdinal: WORD = cast[WORD](funcOrds[x])
            var fnAddrRva = funcAddrs[DWORD(fnOrdinal)]

            if (fnAddrRva == beginAddress and fnName.startsWith("Zw")):
                var fnAddr = cast[PVOID](peBase + fnAddrRva)

                result.add(
                    SystemCall(
                        Ssn: ssn,
                        Name: fnName,
                        Address: fnAddr
                    )
                )
                
                ssn = ssn + 1
                break


        currentIndex = currentIndex + 1


# Example Of Usage (Note This may take a while if you did NOT build with -d:release flag), You can also edit this code to use the 'yield' approach that is present in OffensiveNim #

when isMainModule:
    var ssdt = GetSSDT()

    for syscall in ssdt:
        echo("-----------------")
        echo("Name: " & syscall.Name)
        echo("SSN: " & $syscall.Ssn & " ( " & toHex(syscall.Ssn) & " )")
        echo("Address: " & repr(syscall.Address))