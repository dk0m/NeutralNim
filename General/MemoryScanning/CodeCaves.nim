import winim, ../PeParsing/Parser

var peNtdll = parsePe("C:\\Windows\\System32\\ntdll.dll")
var minSize = 50

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
                var caveStartAddress = cast[LPVOID](ptrToData + i - freeBytes - 1)
                var caveVa = cast[LPVOID](peNtdll.Headers.OptHeader.ImageBase + ptrToData + i - freeBytes - 1)
                echo "======== Found Cave ========"
                echo "Section: " & sectionName
                echo "Cave Size: " & $freeBytes
                echo "Cave Raw Address: " & repr(caveStartAddress)
                echo "Cave Virtual Address: " & repr(caveVa)
                echo "=========================\n\n"

            freeBytes = 0   
    