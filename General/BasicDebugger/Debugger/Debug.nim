import winim, Functions, strutils

proc AttachToDebugger*(processId: DWORD): BOOL =
    return DebugActiveProcess(processId)

proc HandleExceptionDebugInfo(exceptionInfo: EXCEPTION_DEBUG_INFO) =
    var exceptionRecord = exceptionInfo.ExceptionRecord
    echo("[Exception] " & repr(exceptionRecord.ExceptionAddress) & " [" & toHex(exceptionRecord.ExceptionCode) & "] ")


proc HandleDllLoadDebugInfo(dllLoadInfo: LOAD_DLL_DEBUG_INFO) =
    var dllBase = dllLoadInfo.lpBaseOfDll
    var dllPathAddress = dllLoadInfo.lpImageName

    echo("[LoadDll] DllBase: " & repr(dllBase))
    
proc HandleDebugEvent(dbgEvent: DEBUG_EVENT) =
    var eventCode = dbgEvent.dwDebugEventCode

    case eventCode:
        of EXCEPTION_DEBUG_EVENT:
            HandleExceptionDebugInfo(dbgEvent.u.Exception)

        of CREATE_THREAD_DEBUG_EVENT:
            discard

        of CREATE_PROCESS_DEBUG_EVENT:
            discard

        of EXIT_THREAD_DEBUG_EVENT:
            discard

        of EXIT_PROCESS_DEBUG_EVENT:
            discard

        of LOAD_DLL_DEBUG_EVENT:
            HandleDllLoadDebugInfo(dbgEvent.u.LoadDll)

        of UNLOAD_DLL_DEBUG_EVENT:
            discard

        of OUTPUT_DEBUG_STRING_EVENT:
            discard

        of RIP_EVENT:
            discard

        else:
            discard

proc MainDebuggingLoop*() =

    while true:
        var dbgEvent: DEBUG_EVENT
        WaitForDebugEventEx(&dbgEvent, INFINITE)

        var processId = dbgEvent.dwProcessId
        var threadId = dbgEvent.dwThreadId
        var eventCode = dbgEvent.dwDebugEventCode 

        HandleDebugEvent(dbgEvent)

        if eventCode == EXIT_PROCESS_DEBUG_EVENT:
            break

        ContinueDebugEvent(processId, threadId, DBG_EXCEPTION_NOT_HANDLED)