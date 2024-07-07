import winim, os, ptr_math

type
    PeHeaders = object
     DosHeader*: PIMAGE_DOS_HEADER
     NtHeaders*: PIMAGE_NT_HEADERS
     OptHeader*: IMAGE_OPTIONAL_HEADER
     FileHeader*: IMAGE_FILE_HEADER

    PeDirectories = object
     ExportDirectory: PIMAGE_EXPORT_DIRECTORY
     ImportDirectory: PIMAGE_IMPORT_DESCRIPTOR
     TlsDirectory: PIMAGE_TLS_DIRECTORY
     RelocsDirectory: PIMAGE_BASE_RELOCATION
    
    PeFile = object
     ImageBase*: DWORD_PTR
     Headers: PeHeaders
     Directories: PeDirectories
     Sections: seq[PIMAGE_SECTION_HEADER]

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

proc parsePe*(pePath: LPCSTR): PeFile =
    var peBase = cast[DWORD_PTR](ReadPe(pePath))
    ## Headers ##
    
    var
        dosHeader = cast[PIMAGE_DOS_HEADER](peBase)
        ntHeaders = cast[PIMAGE_NT_HEADERS](peBase + dosHeader.e_lfanew)
        optHeader = ntHeaders.OptionalHeader
        fileHeader = ntHeaders.FileHeader

    ## Directories ##
    
    var 
        exportDirectory = RvaToVa[PIMAGE_EXPORT_DIRECTORY](peBase, optHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_EXPORT].VirtualAddress)
        importDirectory = RvaToVa[PIMAGE_IMPORT_DESCRIPTOR](peBase, optHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_IMPORT].VirtualAddress)
        tlsDirectory = RvaToVa[PIMAGE_TLS_DIRECTORY](peBase, optHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_TLS].VirtualAddress)
        relocsDirectory = RvaToVa[PIMAGE_BASE_RELOCATION](peBase, optHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_BASERELOC].VirtualAddress)
    
    ## Sections ##
    
    var 
        peSections: seq[PIMAGE_SECTION_HEADER]
        numbOfSections = fileHeader.NumberOfSections
        fSectionHdr = RvaToVa[PIMAGE_SECTION_HEADER](cast[DWORD_PTR](ntHeaders), cast[DWORD](sizeof(IMAGE_NT_HEADERS)))

    for i in 0..int(numbOfSections) - 1:
        peSections.add(fSectionHdr)
        fSectionHdr = RvaToVa[PIMAGE_SECTION_HEADER](cast[DWORD_PTR](fSectionHdr), cast[DWORD](sizeof(IMAGE_SECTION_HEADER)))

    ## Return PE ##
    
    return PeFile(
        ImageBase: peBase,
        Headers: PeHeaders(DosHeader: dosHeader, NtHeaders: ntHeaders, OptHeader: optHeader, FileHeader: fileHeader),
        Directories: PeDirectories(ExportDirectory: exportDirectory, ImportDirectory: importDirectory, TlsDirectory: tlsDirectory, RelocsDirectory: relocsDirectory),
        Sections: peSections
    )


# Parsing NTDLL PE Sections #

#[
var pe = parsePe("C:\\Windows\\System32\\ntdll.dll")

echo "-----------------"
for section in pe.Sections:
    echo "Section: " & toStringFromByteArray(section.Name)
    echo "RVA: " & repr(cast[LPVOID](section.VirtualAddress))
    echo "VA: " & repr(RvaToVa[LPVOID](pe.ImageBase, section.VirtualAddress))
    echo "Characteristics: " & toHex(section.Characteristics)
    echo "-----------------"

]#
