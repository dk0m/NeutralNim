import winim

proc toStringA(chars: openArray[CHAR]): string =
    for c in chars:
        if c == '\0':
            break
        result.add((c))


proc GetDriversBases*(): seq[LPVOID] =
    var driverBases: array[1024, LPVOID]
    var neededSize: DWORD

    EnumDeviceDrivers(&driverBases[0], cast[DWORD](sizeof(driverBases)), &neededSize)
    var amountOfDrvs = int(neededSize / sizeof(LPVOID))

    return driverBases[0 .. amountOfDrvs - 1]


proc GetDriverName*(driverBase: LPVOID): string =
    var drvName: array[MAX_PATH, CHAR]
    GetDeviceDriverBaseNameA(driverBase, &drvName[0], cast[DWORD](sizeof(drvName)))
    return drvName.toStringA()

proc GetDriverFileName*(driverBase: LPVOID): string =
    var drvFileName: array[MAX_PATH, CHAR]
    GetDeviceDriverFileNameA(driverBase, &drvFileName[0], cast[DWORD](sizeof(drvFileName)))
    return drvFileName.toStringA()

when isMainModule:
    var drvs = GetDriversBases()

    for drvBase in drvs:
        var drvFileName = GetDriverFileName(drvBase)
        var drvBaseName = GetDriverName(drvBase)
        var drvBaseRepr = drvBase.repr()

        echo "Driver Base: " & drvBaseRepr
        echo "Driver Name: " & drvBaseName
        echo "Driver File Path: " & drvFileName

        echo "---------------------"