import winim, ../PeParsing/Parser

type
    Cave* = object
     Section*: string
     RawAddress*: LPVOID
     VirtualAddress*: LPVOID

proc findCaves*(peNtdll: PeFile, minSize: int): seq[Cave] =
    for section in peNtdll.Sections:
        var sectionName = toStringFromByteArray(section.Name)
        var ptrToData = section.PointerToRawData
        
        var sectionDataBase = cast[DWORD_PTR](peNtdll.ImageBase + ptrToData)
        var sectionDataSize = section.SizeOfRawData
        var freeBytes = 0
        for i in 0..sectionDataSize:
            var readByte = cast[PBYTE](sectionDataBase + cast[DWORD](i))[]
            if readByte == 0x0:
                freeBytes += 1
            else:
                if freeBytes > minSize:
                    var caveStartAddress = cast[LPVOID](ptrToData + i - freeBytes)
                    var caveVa = cast[LPVOID](peNtdll.Headers.OptHeader.ImageBase + ptrToData + i - freeBytes)
                    result.add(
                        Cave(
                            Section: sectionName,
                            RawAddress: caveStartAddress,
                            VirtualAddress: caveVa
                        )
                    )

                freeBytes = 0   
