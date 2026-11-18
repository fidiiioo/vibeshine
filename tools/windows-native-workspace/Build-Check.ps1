#requires -Version 7.2
param(
 [string]$WorkspaceRoot = (Get-Location).Path,
 [Parameter(Mandatory)][string]$ToolRoot,
 [string]$OutputRoot,
 [string]$VcVarsPath,
 [ValidatePattern('^8\.\d+\.\d+$')][string]$DotnetSdkVersion = '8.0.427',
 [ValidatePattern('^[0-9A-Za-z.+-]+$')][string]$HostBuildVersion = '2.1.4-rc.2',
 [ValidatePattern('^[A-Za-z0-9-]+$')][string]$RunName = ('check-'+(Get-Date -Format 'yyyyMMdd-HHmmss'))
)
$ErrorActionPreference='Stop'
$root=(Resolve-Path -LiteralPath $WorkspaceRoot).ProviderPath
$kit=(Resolve-Path -LiteralPath $ToolRoot).ProviderPath
if($root -match '[\r\n"%!]' -or $kit -match '[\r\n"%!]'){throw 'Use literal workspace and tool paths without cmd expansion characters.'}
$hostTree=Join-Path $root 'src\host'
if(Test-Path -LiteralPath (Join-Path $root 'src\installer\CMakeLists.txt')){$hostTree=Join-Path $root 'src\installer'}
foreach($required in (Join-Path $hostTree 'CMakeLists.txt'),(Join-Path $root 'src\common\CMakeLists.txt'),(Join-Path $root 'src\qt\moonlight-qt.pro')){
 if(!(Test-Path -LiteralPath $required -PathType Leaf)){throw "Missing project file $required"}
}
$qtDeps=Join-Path $root 'src\qt\libs\windows'
if(!(Test-Path -LiteralPath $qtDeps -PathType Container)){
 throw 'Stage the Moonlight Windows libraries at src/qt/libs/windows before running this check.'
}
if(!$VcVarsPath){
 $installer=Join-Path ([Environment]::GetFolderPath('ProgramFilesX86')) 'Microsoft Visual Studio\Installer\vswhere.exe'
 if(!(Test-Path -LiteralPath $installer -PathType Leaf)){throw 'Visual Studio Installer not found. Supply -VcVarsPath.'}
 $vs=& $installer -latest -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
 if($LASTEXITCODE -ne 0 -or !$vs){throw 'MSVC tools not found. Supply -VcVarsPath.'}
 $VcVarsPath=Join-Path $vs 'VC\Auxiliary\Build\vcvars64.bat'
}
$vc=(Resolve-Path -LiteralPath $VcVarsPath).ProviderPath
if(!$OutputRoot){$OutputRoot=Join-Path $root 'temp'}
$output=[IO.Path]::GetFullPath($OutputRoot)
$diag=Join-Path $output $RunName
if($vc -match '[\r\n"%!]' -or $diag -match '[\r\n"%!]'){throw 'Use literal compiler and output paths without cmd expansion characters.'}
if(Test-Path -LiteralPath $diag){throw 'The check output directory already exists. Choose a new -RunName.'}
$qtRevision=& git -C (Join-Path $root 'src\qt') rev-parse --short=8 HEAD
if($LASTEXITCODE -ne 0 -or $qtRevision -notmatch '^[a-f0-9]{8,}$'){throw 'Could not determine the Qt checkout revision.'}
New-Item -ItemType Directory -Path $diag,"$diag\tmp","$diag\dotnet","$diag\report" -ErrorAction Stop | Out-Null
$env:TEMP="$diag\tmp";$env:TMP=$env:TEMP
$env:DOTNET_CLI_HOME="$diag\dotnet";$env:DOTNET_CLI_TELEMETRY_OPTOUT='1';$env:DOTNET_NOLOGO='1'
$env:PYTHONDONTWRITEBYTECODE='1';$env:GIT_OPTIONAL_LOCKS='0';$env:GIT_NO_LAZY_FETCH='1';$env:GIT_ALLOW_PROTOCOL='';$env:GIT_TERMINAL_PROMPT='0'
$pre="$kit\ucrt64";$bin="$pre\bin"
$env:PATH="$bin;$kit\wix314;$kit\qt\bin;$env:PATH"
$env:PKG_CONFIG_PATH="$pre\lib\pkgconfig;$pre\share\pkgconfig"
$env:npm_config_offline='true';$env:npm_config_cache="$diag\npm"
$env:CI_VERSION=$qtRevision
$cm="$bin\cmake.exe";$ct="$bin\ctest.exe";$log="$diag\report"
$dot="$kit\dotnet\dotnet.exe"
$ff="$kit\ffmpeg\ffmpeg"
$checks=[ordered]@{}
function Step($name,$command,$arguments){
 $previous=$ErrorActionPreference;$ErrorActionPreference='Continue'
 try { & $command @arguments *> "$log\$name.txt"; $code=$LASTEXITCODE } finally { $ErrorActionPreference=$previous }
 $checks[$name]=$code
 Write-Host "$name exit=$code"
 return $code
}
Push-Location $diag
try{
 $c=Step 'dotnet-sdk' $dot @('--list-sdks')
 if($checks['dotnet-sdk'] -eq 0 -and !(Select-String -LiteralPath "$log\dotnet-sdk.txt" -Pattern ('^'+[regex]::Escape($DotnetSdkVersion)+'\s+\['+[regex]::Escape((Join-Path $kit 'dotnet'))) -Quiet)){ $checks['dotnet-sdk']=91 }
 $c=Step 'common-configure' $cm @('-S',"$root\src\common",'-B',"$diag\common",'-G','Ninja','-DCMAKE_BUILD_TYPE=Release','-DBUILD_SHARED_LIBS=OFF','-DBUILD_AUDIO_REGRESSION_TESTS=ON','-DBUILD_ABI_REGRESSION_TESTS=ON',"-DCMAKE_C_COMPILER=$bin\gcc.exe","-DCMAKE_MAKE_PROGRAM=$bin\ninja.exe","-DOPENSSL_ROOT_DIR=$pre","-DOPENSSL_CRYPTO_LIBRARY=$pre\lib\libcrypto.a",'-DFETCHCONTENT_FULLY_DISCONNECTED=ON')
 if($checks['common-configure'] -eq 0){
  $c=Step 'common-test-build' $cm @('--build',"$diag\common",'--parallel','2','--target','test_audio_protocol')
  if($checks['common-test-build'] -eq 0){ $c=Step 'common-audio-test' $ct @('--test-dir',"$diag\common",'-R','^audio_protocol_and_receive$','--output-on-failure') }
 }
 $hostArgs=@('-S',$hostTree,'-B',"$diag\host",'-G','Ninja','-DCMAKE_BUILD_TYPE=Release',"-DBUILD_VERSION=$HostBuildVersion","-DCMAKE_C_COMPILER=$bin\gcc.exe","-DCMAKE_CXX_COMPILER=$bin\g++.exe","-DCMAKE_MAKE_PROGRAM=$bin\ninja.exe","-DCMAKE_PREFIX_PATH=$pre","-DFFMPEG_PREPARED_BINARIES=$ff",'-DOPENSSL_USE_STATIC_LIBS=ON',"-DOPENSSL_CRYPTO_LIBRARY=$pre\lib\libcrypto.a","-DOPENSSL_SSL_LIBRARY=$pre\lib\libssl.a","-DSUNSHINE_DOTNET_EXECUTABLE=$dot","-DSUNSHINE_NPM_EXECUTABLE=$bin\npm.cmd",'-DBUILD_DOCS=OFF','-DBUILD_TESTS=OFF','-DGLAD_SKIP_PIP_INSTALL=ON',"-DPython_EXECUTABLE=$bin\python.exe",'-DFETCHCONTENT_FULLY_DISCONNECTED=ON','-DSUNSHINE_ENABLE_WEBRTC=OFF','-DSUNSHINE_ENABLE_VIBE_SPEAKERS=ON')
 $c=Step 'host-configure' $cm $hostArgs
 if($checks['host-configure'] -eq 0){
  $c=Step 'host-bridge-test-build' $cm @('--build',"$diag\host",'--parallel','2','--target','VibeUsbBridgeTests')
  if($checks['host-bridge-test-build'] -eq 0){ $c=Step 'host-bridge-test' "$diag\host\VibeUsbBridgeTests.exe" @() }
 }
 $c=Step 'qt-version' "$kit\qt\bin\qmake.exe" @('-query','QT_VERSION')
 $c=Step 'qt-prefix' "$kit\qt\bin\qmake.exe" @('-query','QT_INSTALL_PREFIX')
 $qtCheck="$diag\qt";New-Item -ItemType Directory -Path $qtCheck | Out-Null
 $cmdfile="$qtCheck\configure.cmd"
 @(
  '@echo off'
  ('call "'+$vc+'" >nul')
  'if errorlevel 1 exit /b %errorlevel%'
  ('"'+$kit+'\qt\bin\qmake.exe" -r "'+$root+'\src\qt\moonlight-qt.pro" "CONFIG+=release" "CONFIG-=debug_and_release"')
 ) | Set-Content -LiteralPath $cmdfile -Encoding ascii
 Push-Location $qtCheck
 try{ $c=Step 'qt-configure' 'cmd.exe' @('/d','/c',$cmdfile) } finally{ Pop-Location }
}finally{
 Pop-Location
 $checks | ConvertTo-Json | Set-Content -LiteralPath "$diag\checks.json" -Encoding utf8
}
$checks
if(@($checks.Values | Where-Object {$_ -ne 0}).Count){exit 1}
