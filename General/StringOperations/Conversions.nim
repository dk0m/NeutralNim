import winim

proc toStringW(chars: openArray[WCHAR]): string =
    for c in chars:
        if cast[char](c) == '\0':
            break
        result.add(cast[char](c))

proc toStringA(chars: openArray[CHAR]): string =
    for c in chars:
        if c == '\0':
            break
        result.add((c))

# Notes #

#[

1 - To convert from LPWSTR, LPCWSTR, PWSTR, PWCSTR to a Nim string, Use the `$` operator.

]#