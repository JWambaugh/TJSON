set path="C:\Program Files\WinRAR\";%path%
del haxelib\*.zip
mkdir haxelib
mkdir haxelib\tjson
xcopy  lib\*.* haxelib\tjson /e /y
cd haxelib
winrar.exe a -afzip tjson.zip tjson
haxelib install tjson.zip
cd ..
