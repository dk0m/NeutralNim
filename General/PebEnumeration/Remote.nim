import winim
import ../ProcessEnumeration/CreateToolHelp32

proc GetRemotePebAddress*(hProcess: HANDLE): PPEB =
    var pbi: PROCESS_BASIC_INFORMATION
    NtQueryInformationProcess(hProcess, processBasicInformation, &pbi, cast[ULONG](sizeof(pbi)), NULL)
    return pbi.PebBaseAddress


var procId = GetProcessIdFromName("notepad.exe")
var hProcess = OpenProcess(PROCESS_QUERY_INFORMATION, FALSE, procId)

var remPeb = GetRemotePebAddress(hProcess)

echo "Remote Peb Address: " & repr(cast[LPVOID](remPeb))