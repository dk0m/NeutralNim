import winim
type
    IMAGE_RUNTIME_FUNCTION_ENTRY* = object
     BeginAddress*: ULONG
     EndAddress*: ULONG
     ExceptionHandler*: PVOID
     HandlerData*: PVOID
     PrologEndAddress*: ULONG
    
    PIMAGE_RUNTIME_FUNCTION_ENTRY* = ptr IMAGE_RUNTIME_FUNCTION_ENTRY

     