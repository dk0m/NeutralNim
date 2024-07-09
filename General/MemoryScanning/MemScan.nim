import winim, ptr_math
import ../ProcessEnumeration/CreateToolHelp32

proc GetProcessMemoryRegions*(hProcess: HANDLE): seq[MEMORY_BASIC_INFORMATION] =
    var memRegions: seq[MEMORY_BASIC_INFORMATION]
    var mbi: MEMORY_BASIC_INFORMATION
    var baseAddr: LPVOID
    
    while VirtualQueryEx(hProcess, baseAddr, &mbi, cast[SIZE_T](sizeof(mbi))) != 0:
        if (mbi.State and MEM_COMMIT) == MEM_COMMIT:
            memRegions.add(mbi)
        baseAddr = cast[LPVOID](cast[DWORD_PTR](mbi.BaseAddress) + mbi.RegionSize)

    return memRegions


proc ScanFor*[T](hProcess: HANDLE, memRegions: seq[MEMORY_BASIC_INFORMATION], targetValue: T): seq[LPVOID] =
    for memRegion in memRegions:
        var regionBase = memRegion.BaseAddress
        var regionSize = memRegion.RegionSize

        var regionBuffer = HeapAlloc(GetProcessHeap(), HEAP_ZERO_MEMORY, regionSize)
        ReadProcessMemory(hProcess, regionBase, regionBuffer, regionSize, NULL)

        for offset in countup(0, regionSize - sizeof(T), sizeof(T)):
            var readValue = cast[ptr T](regionBuffer + offset)[]
            if readValue == targetValue:
                result.add(cast[LPVOID](regionBase + offset))
            
        HeapFree(GetProcessHeap(), 0, regionBuffer)


proc ScanString*(hProcess: HANDLE, memRegions: seq[MEMORY_BASIC_INFORMATION], targetString: LPCSTR): seq[LPVOID] =
    var stringLen = lstrlenA(targetString)

    for memRegion in memRegions:
        var regionBase = memRegion.BaseAddress
        var regionSize = memRegion.RegionSize

        var regionBuffer = HeapAlloc(GetProcessHeap(), HEAP_ZERO_MEMORY, regionSize)
        ReadProcessMemory(hProcess, regionBase, regionBuffer, regionSize, NULL)

        for offset in countup(0, regionSize - stringLen, stringLen):
            var readValue = cast[LPCSTR](regionBuffer + offset)
            if lstrcmpA(readValue, targetString) == 0:
                result.add(cast[LPVOID](regionBase + offset))
            
        HeapFree(GetProcessHeap(), 0, regionBuffer)

var notepadId = GetProcessIdFromName("notepad.exe")
var hProcess = OpenProcess(PROCESS_ALL_ACCESS, FALSE, notepadId)



# Example Of Usage #

when isMainModule:
    var memRegions = GetProcessMemoryRegions(hProcess)
    var addresses = ScanFor[int](hProcess, memRegions, 4)

    for addr in addresses:
        echo "Found Value 4 At Address: ", addr.repr()

    var strAddresses = ScanString(hProcess, memRegions, "VirtualAlloc")

    for addr in strAddresses:
        echo "Found String 'VirtualAlloc' At Address: ", addr.repr()
