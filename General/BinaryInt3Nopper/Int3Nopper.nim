import winim, cligen, ../PeParsing/Parser

proc fetchFileSize(filePath: string): DWORD =
    var peFile: HANDLE = CreateFileA(filePath, GENERIC_READ, 0, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, cast[HANDLE](NULL))
    var peFileSize = GetFileSize(peFile, NULL)
    CloseHandle(peFile)
    return peFileSize

proc NopAllInt3s(filePath: string, outputNopped: string, args: seq[string]) =
    var peFile = parsePe(filePath)
    var peSections = peFile.Sections

    var textSection = peSections.getSection(".text")

    var ptrToData = textSection.PointerToRawData
    var sectionDataBase = cast[DWORD_PTR](peFile.ImageBase + ptrToData)
    var sectionDataSize = textSection.SizeOfRawData
    var noppedCount = 0
    for i in 0..sectionDataSize:
        var readByte = cast[PBYTE](sectionDataBase + cast[DWORD](i))[]
        if readByte == 0xCC:
            cast[PBYTE](sectionDataBase + cast[DWORD](i))[] = cast[BYTE](0x90)
            noppedCount += 1

    echo("Nopped Out " & $noppedCount & " Int3s!")

    var outputFile = CreateFileA(outputNopped, GENERIC_WRITE, 0, NULL, CREATE_NEW, FILE_ATTRIBUTE_NORMAL, cast[HANDLE](NULL))
    if WriteFile(outputFile, cast[LPVOID](peFile.ImageBase), fetchFileSize(filePath), NULL, NULL) == 1:
        echo("Wrote Nopped-Out Binary Successfully!")
    CloseHandle(outputFile)

dispatch NopAllInt3s
