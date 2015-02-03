# rubygadgets
Tiny ruby utilities for Windows

## cstruct

C::Struct makes easier to import Win32 structure into ruby world. 
It ressemble Struct but with Windows type.

```
require 'cstruct'
LongLongStruct = C::Struct.define {
  ULONG :u1
  ULONG :u2
  HFIELD :h1
}
longlong = LongLongStruct.new(2, 2, 90)
```

## icmpping 

icmpping is not for only windows.
It can fire ICMP echo (with Administrator/root priviledge) using raw socket.

```
require 'icmpping.rb'
include ICMPPing
print ping("localhost")
```

## suexec

suexec transits administrator priviledge using cstruct.

```
require 'suexec'
SuExec.exec('notepad.exe')  # you can get notepad instance with Administrator right
```

## winpath

winpath gives you a Windows short pathname (DOS 8.3 format name).
It is a monkey patch for pathname.

```
require 'winpath'
file = Pathname.new('c:/program files')
p file.shortname  #=> c:/progra~1
```


