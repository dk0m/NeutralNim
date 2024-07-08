import winim

proc WaitForDebugEventEx*(lpDebugEvent: LPDEBUG_EVENT, dwMilliseconds: DWORD): WINBOOL {.winapi, stdcall, dynlib: "kernel32", importc.}
