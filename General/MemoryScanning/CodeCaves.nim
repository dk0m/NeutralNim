import winim, ../PeFileParsing/Parser

type
    Cave* = object
     Section*: PIMAGE_SECTION_HEADER
     SectionName*: string
     Size*: int
     RawAddress*: LPVOID
     VirtualAddress*: LPVOID

proc findCaves*(peFile: PeFile, minSize: int): seq[Cave] =
    for section in peFile.Sections:
        var sectionName = toStringFromByteArray(section.Name)
        var ptrToData = section.PointerToRawData
        
        var sectionDataBase = cast[DWORD_PTR](peFile.ImageBase + ptrToData)
        var sectionDataSize = section.SizeOfRawData
        var freeBytes = 0
        for i in 0..sectionDataSize:
            var readByte = cast[PBYTE](sectionDataBase + cast[DWORD](i))[]
            if readByte == 0x0:
                freeBytes += 1
            else:
                if freeBytes > minSize:
                    var caveStartAddress = cast[LPVOID](ptrToData + i - freeBytes)
                    var caveVa = cast[LPVOID](peFile.Headers.OptHeader.ImageBase + ptrToData + i - freeBytes)
                    result.add(
                        Cave(
                            Section: section,
                            Size: freeBytes,
                            SectionName: sectionName,
                            RawAddress: caveStartAddress,
                            VirtualAddress: caveVa
                        )
                    )

                freeBytes = 0   
