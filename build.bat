cmake . -Bbuild -G "Visual Studio 17 2022" -A Win32 -DCMAKE_POLICY_VERSION_MINIMUM=3.5
if %ERRORLEVEL% NEQ 0 exit /b %ERRORLEVEL%
cmake --build build --config Release
if %ERRORLEVEL% NEQ 0 exit /b %ERRORLEVEL%

cmake . -Bbuild64 -G "Visual Studio 17 2022" -A x64 -DCMAKE_POLICY_VERSION_MINIMUM=3.5
if %ERRORLEVEL% NEQ 0 exit /b %ERRORLEVEL%
cmake --build build64 --config Release --target PIMETextService
if %ERRORLEVEL% NEQ 0 exit /b %ERRORLEVEL%

cmake . -Bbuild_arm64 -G "Visual Studio 17 2022" -A ARM64 -DCMAKE_POLICY_VERSION_MINIMUM=3.5
if %ERRORLEVEL% NEQ 0 exit /b %ERRORLEVEL%
cmake --build build_arm64 --config Release --target PIMETextService
if %ERRORLEVEL% NEQ 0 exit /b %ERRORLEVEL%

echo "Generating ARM64X forwarder..."
echo EXPORTS > build_arm64\arm64.def
echo DllCanUnloadNow=PIMETextService_arm64.DllCanUnloadNow >> build_arm64\arm64.def
echo DllGetClassObject=PIMETextService_arm64.DllGetClassObject >> build_arm64\arm64.def
echo DllRegisterServer=PIMETextService_arm64.DllRegisterServer >> build_arm64\arm64.def
echo DllUnregisterServer=PIMETextService_arm64.DllUnregisterServer >> build_arm64\arm64.def

echo EXPORTS > build_arm64\x64.def
echo DllCanUnloadNow=PIMETextService_x64.DllCanUnloadNow >> build_arm64\x64.def
echo DllGetClassObject=PIMETextService_x64.DllGetClassObject >> build_arm64\x64.def
echo DllRegisterServer=PIMETextService_x64.DllRegisterServer >> build_arm64\x64.def
echo DllUnregisterServer=PIMETextService_x64.DllUnregisterServer >> build_arm64\x64.def

set "VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
set "VCVARS="
if exist "%VSWHERE%" (
    for /f "usebackq tokens=*" %%i in (`"%VSWHERE%" -latest -prerelease -property installationPath`) do (
        if exist "%%i\VC\Auxiliary\Build\vcvarsall.bat" set "VCVARS=%%i\VC\Auxiliary\Build\vcvarsall.bat"
    )
)
if "%VCVARS%"=="" (
    if exist "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvarsall.bat" (
        set "VCVARS=C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvarsall.bat"
    ) else if exist "C:\Program Files\Microsoft Visual Studio\2022\Enterprise\VC\Auxiliary\Build\vcvarsall.bat" (
        set "VCVARS=C:\Program Files\Microsoft Visual Studio\2022\Enterprise\VC\Auxiliary\Build\vcvarsall.bat"
    )
)
if "%VCVARS%"=="" (
    echo Error: Could not locate vcvarsall.bat for ARM64X linking.
    exit /b 1
)

call "%VCVARS%" x64_arm64
if %ERRORLEVEL% NEQ 0 (
    echo Error: Failed to initialize VC environment for ARM64X.
    exit /b %ERRORLEVEL%
)
link /nologo /dll /noentry /nodefaultlib /machine:arm64x /defArm64Native:build_arm64\arm64.def /def:build_arm64\x64.def /out:build_arm64\PIMETextService_forwarder.dll
if %ERRORLEVEL% NEQ 0 (
    echo Error: Failed to link ARM64X forwarder DLL.
    exit /b %ERRORLEVEL%
)
set "Platform="

copy /y build_arm64\PIMETextService\Release\PIMETextService.dll build_arm64\PIMETextService\Release\PIMETextService_arm64.dll
if %ERRORLEVEL% NEQ 0 exit /b %ERRORLEVEL%
copy /y build64\PIMETextService\Release\PIMETextService.dll build_arm64\PIMETextService\Release\PIMETextService_x64.dll
if %ERRORLEVEL% NEQ 0 exit /b %ERRORLEVEL%
copy /y build_arm64\PIMETextService_forwarder.dll build_arm64\PIMETextService\Release\PIMETextService.dll
if %ERRORLEVEL% NEQ 0 exit /b %ERRORLEVEL%

echo "Start building McBopomofo"
cd McBopomofoWeb
cmd /C npm install
cmd /C npm run build:pime
cd ..

echo "Copy McBopomofo to node\input_methods\McBopomofo"
cmd /C rd /s /q node\input_methods\McBopomofo
cmd /C mkdir node\input_methods\McBopomofo
cmd /C xcopy /s /q /y /f McBopomofoWeb\output\pime node\input_methods\McBopomofo\.


echo "Start building McFoximWeb"
cd McFoximWeb
cmd /C npm install
cmd /C npm run build:pime
cd ..

echo "Copy McFoximWeb to node\input_methods\McFoxim"
cmd /C rd /s /q node\input_methods\McFoxim
cmd /C mkdir node\input_methods\McFoxim
cmd /C xcopy /s /q /y /f McFoximWeb\output\pime node\input_methods\McFoxim\.

echo "Start building McTabimWeb"
cd McTabimWeb
cmd /C npm install
cmd /C npm run build:pime
cd ..

echo "Copy McTabimWeb to node\input_methods\McTabim"
cmd /C rd /s /q node\input_methods\McTabim
cmd /C mkdir node\input_methods\McTabim
cmd /C xcopy /s /q /y /f McTabimWeb\output\pime node\input_methods\McTabim\.

echo "Start building PIME Installer"
cd installer
..\python\python3\python.exe stage_payload.py
if %ERRORLEVEL% NEQ 0 exit /b %ERRORLEVEL%
..\python\python3\python.exe generate_harvest_wxs.py
if %ERRORLEVEL% NEQ 0 exit /b %ERRORLEVEL%
    set "Platform="
    dotnet build PIME_Core\PIME_Core.wixproj -c Release
    if %ERRORLEVEL% NEQ 0 exit /b %ERRORLEVEL%
    
    echo "Creating single multilingual MSI..."
    cmd /C build_multilingual.bat
    if %ERRORLEVEL% NEQ 0 exit /b %ERRORLEVEL%
    cd ..

