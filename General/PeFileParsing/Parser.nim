import winim, os, ptr_math

# Types #
type
    IMAGE_RUNTIME_FUNCTION_ENTRY* = object
     BeginAddress*: ULONG
     EndAddress*: ULONG
     ExceptionHandler*: PVOID
     HandlerData*: PVOID
     PrologEndAddress*: ULONG
    
    PIMAGE_RUNTIME_FUNCTION_ENTRY* = ptr IMAGE_RUNTIME_FUNCTION_ENTRY

type
    PeHeaders = object
     DosHeader*: PIMAGE_DOS_HEADER
     NtHeaders*: PIMAGE_NT_HEADERS
     OptHeader*: IMAGE_OPTIONAL_HEADER
     FileHeader*: IMAGE_FILE_HEADER

    PeDirectories = object
     ExportDirectory*: PIMAGE_EXPORT_DIRECTORY
     ImportDirectory*: PIMAGE_IMPORT_DESCRIPTOR
     TlsDirectory*: PIMAGE_TLS_DIRECTORY
     RelocsDirectory*: PIMAGE_BASE_RELOCATION
     RtfEntryDirectory*: PIMAGE_RUNTIME_FUNCTION_ENTRY 

    PeExport* = object
     Name*: LPCSTR
     Ordinal*: WORD
     FunctionRva*: PVOID

    PeImportedFunction* = object
     Name*: LPCSTR
     FunctionRva*: PVOID

    PeImport* = object
     DllName*: LPCSTR
     ImportedFunctions*: seq[PeImportedFunction]

    PeFile = object
     ImageBase*: DWORD_PTR
     Headers*: PeHeaders
     Directories*: PeDirectories
     Sections*: seq[PIMAGE_SECTION_HEADER]

     Exports*: seq[PeExport]
     Imports*: seq[PeImport]

proc toStringFromByteArray*(chars: openArray[BYTE]): string =
    for c in chars:
        if cast[char](c) == '\0':
            break
        result.add(cast[char](c))

proc ReadPe*(filePath: LPCSTR): LPVOID =
    var peFile: HANDLE = CreateFileA(filePath, GENERIC_READ, 0, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, cast[HANDLE](NULL))
    var peFileSize = GetFileSize(peFile, NULL)

    var peBuffer = HeapAlloc(GetProcessHeap(), HEAP_ZERO_MEMORY, peFileSize)

    if (ReadFile(
        peFile,
        peBuffer,
        peFileSize,
        NULL,
        NULL
    ) == FALSE):
        CloseHandle(peFile)
        return NULL

    CloseHandle(peFile)
    return peBuffer

proc GetCurrentPeBase*(): LPVOID =
    return cast[LPVOID](GetModuleHandleA(NULL))

proc RvaToVa*[T](baseAddr: DWORD_PTR, offset: DWORD): T =
    return cast[T](baseAddr + offset)


proc getDataSectionIn*(dataVA: DWORD, peSections: seq[PIMAGE_SECTION_HEADER]): PIMAGE_SECTION_HEADER =
    var destSect: PIMAGE_SECTION_HEADER

    for section in peSections:
        if dataVA >= section.VirtualAddress and dataVA <= (section.VirtualAddress + section.Misc.VirtualSize):
            destSect = section

    return destSect



proc parsePeFile*(peFilePath: LPCSTR): PeFile =
    var peBase = cast[DWORD_PTR](ReadPe(peFilePath))

    ## Headers ##
    
    var
        dosHeader = cast[PIMAGE_DOS_HEADER](peBase)
        ntHeaders = cast[PIMAGE_NT_HEADERS](peBase + dosHeader.e_lfanew)
        optHeader = ntHeaders.OptionalHeader
        fileHeader = ntHeaders.FileHeader

    ## Sections ##
    
    var 
        peSections: seq[PIMAGE_SECTION_HEADER]
        numbOfSections = fileHeader.NumberOfSections
        fSectionHdr = RvaToVa[PIMAGE_SECTION_HEADER](cast[DWORD_PTR](ntHeaders), cast[DWORD](sizeof(IMAGE_NT_HEADERS)))

    for i in 0..int(numbOfSections) - 1:
        peSections.add(fSectionHdr)
        fSectionHdr = RvaToVa[PIMAGE_SECTION_HEADER](cast[DWORD_PTR](fSectionHdr), cast[DWORD](sizeof(IMAGE_SECTION_HEADER)))

    # Data Directories Other Than Imports And Exports #

    var 
        tlsDirectory = RvaToVa[PIMAGE_TLS_DIRECTORY](peBase, optHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_TLS].VirtualAddress)
        relocsDirectory = RvaToVa[PIMAGE_BASE_RELOCATION](peBase, optHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_BASERELOC].VirtualAddress)
        runtimeFuncEntryDirectory = RvaToVa[PIMAGE_RUNTIME_FUNCTION_ENTRY](peBase, optHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_EXCEPTION].VirtualAddress)


    # Preparing Seqs Of Exports And Imports

    var peExports: seq[PeExport]
    var peImports: seq[PeImport]

    # Data Directories (Parsing Exports) #

    var expDirVA = optHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_EXPORT].VirtualAddress
    var expDir: PIMAGE_EXPORT_DIRECTORY

    if expDirVA != 0:
        var expDirSect = getDataSectionIn(expDirVA, peSections)
        
        if expDirSect != nil:
        
            var expRawOffset = cast[DWORD_PTR](peBase + expDirSect.PointerToRawData)

            expDir = cast[PIMAGE_EXPORT_DIRECTORY](expRawOffset + expDirVA - expDirSect.VirtualAddress)

            var addressOfNames = cast[PDWORD](expRawOffset + expDir.AddressOfNames - expDirSect.VirtualAddress)
            var addressOfOrdinals = cast[PWORD](expRawOffset + expDir.AddressOfNameOrdinals - expDirSect.VirtualAddress)
            var addressOfFunctions = cast[PDWORD](expRawOffset + expDir.AddressOfFunctions - expDirSect.VirtualAddress)

            for i in 0..int(expDir.NumberOfNames) - 1:

                var name = cast[LPCSTR](expRawOffset + addressOfNames[i] - expDirSect.VirtualAddress)
                var ordinal = cast[WORD](addressOfOrdinals[i])
                var fncAddrRva = cast[PVOID](addressOfFunctions[DWORD(ordinal)])

                var peExport = PeExport(
                    Name: name,
                    Ordinal: ordinal,
                    FunctionRva: fncAddrRva,
                )

                add(peExports, peExport)
        
    # Parsing Imports #
    var importDirVA = optHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_IMPORT].VirtualAddress
    var importDirSect = getDataSectionIn(importDirVA, peSections)
    var importRawOffset = cast[DWORD_PTR](peBase + importDirSect.PointerToRawData)

    var importDir = cast[PIMAGE_IMPORT_DESCRIPTOR](importRawOffset + importDirVA - importDirSect.VirtualAddress)

    while (importDir.Name != 0):

        var importDllName: LPCSTR = cast[LPCSTR](importRawOffset + importDir.Name - importDirSect.VirtualAddress)
        var peImport = PeImport(DllName: importDllName)
        var thunkData = cast[PIMAGE_THUNK_DATA](importRawOffset + importDir.union1.OriginalFirstThunk - importDirSect.VirtualAddress)

        while thunkData.u1.AddressOfData != 0:
            var funcName: LPCSTR = cast[LPCSTR](importRawOffset + (thunkData.u1.AddressOfData - importDirSect.VirtualAddress + 2))
            var funcAddrRva: PVOID = cast[PVOID](thunkData.u1.AddressOfData)
            
            add(peImport.ImportedFunctions, PeImportedFunction(
                Name: funcName,
                FunctionRva: funcAddrRva
            ))

            thunkData = thunkData + 1
        
        add(peImports, peImport)

        importDir = importDir + 1
    ## Return PE ##
    
    return PeFile(
        ImageBase: peBase,
        Headers: PeHeaders(DosHeader: dosHeader, NtHeaders: ntHeaders, OptHeader: optHeader, FileHeader: fileHeader),
        Directories: PeDirectories(ExportDirectory: expDir, TlsDirectory: tlsDirectory, RelocsDirectory: relocsDirectory, RtfEntryDirectory: runtimeFuncEntryDirectory),
        Sections: peSections,
        Exports: peExports,
        Imports: peImports
    )


