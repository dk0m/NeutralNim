import winim, os, ptr_math

type
    PeFile = object
     peBase*: DWORD_PTR
     dosHeader*: PIMAGE_DOS_HEADER
     ntHeaders*: PIMAGE_NT_HEADERS
     optHeader*: IMAGE_OPTIONAL_HEADER
     fileHeader*: IMAGE_FILE_HEADER
     exportDirectory*: PIMAGE_EXPORT_DIRECTORY

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


proc parsePe*(pePath: LPCSTR): PeFile =

    var peFileRead = ReadPe(pePath)
    var peBase = cast[DWORD_PTR](peFileRead)

    var dosHeader: PIMAGE_DOS_HEADER = cast[PIMAGE_DOS_HEADER](peBase)
    var ntHeaders: PIMAGE_NT_HEADERS = cast[PIMAGE_NT_HEADERS](peBase + dosHeader.e_lfanew)

    var optHeader: IMAGE_OPTIONAL_HEADER = ntHeaders.OptionalHeader
    var fileHeader: IMAGE_FILE_HEADER = ntHeaders.FileHeader

    var expDataDir = optHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_EXPORT]

    var expDir: PIMAGE_EXPORT_DIRECTORY = cast[PIMAGE_EXPORT_DIRECTORY](peBase + expDataDir.VirtualAddress)

    return PeFile(peBase: peBase, dosHeader: dosHeader, ntHeaders: ntHeaders, optHeader: optHeader, fileHeader: fileHeader, exportDirectory: expDir )


# This Isn't a Full PE Parser, More Features Will Be Added, Section Parsing, IAT Parsing, Relocations, Etc #

# Parsing NTDLL #
#[
var peNtdll = parsePe("C:\\Windows\\System32\\ntdll.dll")
]#

