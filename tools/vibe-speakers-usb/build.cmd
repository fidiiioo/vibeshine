@echo off
setlocal
set "src=%~dp0"
cl /nologo /std:c++20 /EHsc /O2 /W4 /WX /MT /guard:cf /DUNICODE /D_UNICODE /DNOMINMAX /I"%src%include" /c "%src%src\protocol.cpp" "%src%src\clock_evidence.cpp" "%src%src\transport.cpp"
if errorlevel 1 exit /b 1
lib /nologo /out:vibe_speakers_usb.lib protocol.obj clock_evidence.obj transport.obj
if errorlevel 1 exit /b 1
cl /nologo /std:c++20 /EHsc /O2 /W4 /WX /MT /guard:cf /DUNICODE /D_UNICODE /DNOMINMAX /I"%src%include" "%src%tests\protocol_tests.cpp" vibe_speakers_usb.lib /Fe:protocol_tests.exe /link /guard:cf ws2_32.lib cfgmgr32.lib ole32.lib propsys.lib uuid.lib bcrypt.lib advapi32.lib avrt.lib
if errorlevel 1 exit /b 1
.\protocol_tests.exe
exit /b %errorlevel%
