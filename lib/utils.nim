

# get current process id

when defined(windows):
    proc GetCurrentProcessId*(): int32 {.stdcall, dynlib: "kernel32",
                                        importc: "GetCurrentProcessId".}
else :
  from posix import getpid
  
  proc  GetCurrentProcessId*():
    getpid()

# test
when isMainModule:
    echo   GetCurrentProcessId()

