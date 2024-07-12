import winim, ptr_math

type
    WLAN_INTERFACE_STATE* = enum
     wlan_interface_state_not_ready
     wlan_interface_state_connected
     wlan_interface_state_ad_hoc_network_formed
     wlan_interface_state_disconnecting
     wlan_interface_state_disconnected
     wlan_interface_state_associating
     wlan_interface_state_discovering
     wlan_interface_state_authenticating

    DOT11_BSS_TYPE = enum
     dot11_BSS_type_infrastructure  = 1
     dot11_BSS_type_independent     = 2
     dot11_BSS_type_any             = 3

    DOT11_SSID = object
     uSSIDLength: ULONG
     ucSSID: array[256, UCHAR]

    WLAN_INTERFACE_INFO* = object
     InterfaceGuid*: GUID
     strInterfaceDescription*: array[256, WCHAR]
     isState*: WLAN_INTERFACE_STATE

    WLAN_INTERFACE_INFO_LIST* = object
     dwNumberOfItems*: DWORD
     dwIndex*: DWORD
     InterfaceInfo*: array[1, WLAN_INTERFACE_INFO]

    PWLAN_INTERFACE_INFO_LIST* = ptr WLAN_INTERFACE_INFO_LIST


    WLAN_PROFILE_INFO* = object
     strProfileName*: array[256, WCHAR]
     dwFlags*: DWORD

    WLAN_PROFILE_INFO_LIST* = object
     dwNumberOfItems*: DWORD
     dwIndex*: DWORD
     ProfileInfo*: array[1, WLAN_PROFILE_INFO]

    PWLAN_PROFILE_INFO_LIST* = ptr WLAN_PROFILE_INFO_LIST


proc WlanOpenHandle*(dwClientVersion: DWORD, pReserved: PVOID, pdwNegotiatedVersion: PDWORD, phClientHandle: PHANDLE): DWORD {.winapi, stdcall, dynlib: "wlanapi", importc.}
proc WlanEnumInterfaces*(hClientHandle: HANDLE, pReserved: PVOID, ppInterfaceList: ptr PWLAN_INTERFACE_INFO_LIST): DWORD {.winapi, stdcall, dynlib: "wlanapi", importc.}
proc WlanGetProfileList*(hClientHandle: HANDLE, pInterfaceGuid: ptr GUID, pReserved: PVOID, ppProfileList: ptr PWLAN_PROFILE_INFO_LIST): DWORD {.winapi, stdcall, dynlib: "wlanapi", importc.}
proc WlanGetProfile*(hClientHandle: HANDLE, pInterfaceGuid: ptr GUID, strProfileName: LPCWSTR, pReserved: PVOID, pstrProfileXml: ptr LPWSTR, pdwFlags: PDWORD, pdwGrantedAccess: PDWORD): DWORD {.winapi, stdcall, dynlib: "wlanapi", importc.}

proc `{}`[T](flexableArray: array[1, T], index: int): T =
    var pEntry = cast[ptr T](addr(flexableArray) + index)
    return cast[T](pEntry[])

proc toStringW(chars: openArray[WCHAR]): string =
    for c in chars:
        if cast[char](c) == '\0':
            break
        result.add(cast[char](c))

template WLAN_SUCCESS*(status: DWORD): bool = status == ERROR_SUCCESS

var negVersion: DWORD
var wlanHandle: HANDLE

WlanOpenHandle(
    1,
    NULL,
    &negVersion,
    &wlanHandle
)
var interfaceInfoList: PWLAN_INTERFACE_INFO_LIST

WlanEnumInterfaces(wlanHandle, NULL, &interfaceInfoList)

for i in 0 ..< interfaceInfoList.dwNumberOfItems:
    var interfaceInfo = interfaceInfoList.InterfaceInfo{i}
    var interfaceGuid = interfaceInfo.InterfaceGuid
    var profileList: PWLAN_PROFILE_INFO_LIST

    WlanGetProfileList(wlanHandle, &interfaceGuid, NULL, &profileList)

    for x in 0 .. profileList.dwNumberOfItems:
        var profile = profileList.ProfileInfo{i}
        var profileName = profile.strProfileName
        var profileXml: LPWSTR
        var profileFlags: DWORD = DWORD(0x4) # WLAN_PROFILE_GET_PLAINTEXT_KEY
        WlanGetProfile(
            wlanHandle,
            &interfaceGuid,
            cast[LPCWSTR](&profileName[0]),
            NULL,
            &profileXml,
            &profileFlags,
            NULL
        )

        echo($profileXml)