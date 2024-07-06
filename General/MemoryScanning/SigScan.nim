import winim, ptr_math, ./MemScan, strutils
import ../ProcessEnumeration/CreateToolHelp32
import ../ModuleEnumeration/EnumProcessModules

proc SigScan*(hProcess: HANDLE, startAddress: LPVOID, regionSize: SIZE_T, signatureString: string): seq[LPVOID] =
    var sigSplit = signatureString.split(" ")
    var bytesLen = sigSplit.len() - 1

    var regionBuffer = HeapAlloc(GetProcessHeap(), HEAP_ZERO_MEMORY, regionSize)
    ReadProcessMemory(hProcess, startAddress, regionBuffer, regionSize, NULL)

    for offset in countup(0, regionSize - bytesLen, bytesLen):
        var foundSig = true

        for i in 0 .. bytesLen:
            var currentByte = cast[PBYTE](regionBuffer + offset + i)[]

            var cmpByte = toUpper(sigSplit[i])
            var cmp2Byte = toHex(currentByte)

            if cmpByte == "??":
                continue   

            if cmpByte != cmp2Byte:
                foundSig = false
        
        if foundSig:
            result.add(cast[LPVOID](cast[DWORD_PTR](startAddress) + offset))
        

# Scanning For System Call Stubs #

#[
Use This For Assembling & Disassembling: https://defuse.ca/online-x86-assembler.htm#disassembly2

var notepadId = GetProcessIdFromName("notepad.exe")
var hProcess = OpenProcess(PROCESS_ALL_ACCESS, FALSE, notepadId)
var memRegions = GetProcessMemoryRegions(hProcess)

var ntdllInfo = GetModuleInfo(hProcess, "ntdll.dll")

var foundSyscallStubs = SigScan(hProcess, ntdllInfo.lpBaseOfDll, ntdllInfo.SizeOfImage, "4C 8B D1 B8 ?? ?? ?? ?? F6")

for stubAddress in foundSyscallStubs:
    echo "Syscall Stub Found At " & repr(stubAddress)

]#
