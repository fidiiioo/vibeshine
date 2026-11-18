# Windows native audio development checks

Use separate local checkouts under `src/host`, `src/qt`, and `src/common`. The verified starting points are:

| Checkout | Fork branch | Commit |
| --- | --- | --- |
| Host | `fidiiioo/vibeshine:feature/vibe-speakers-native-714` | `09e2d81a8ecff7e487a47b697d4bc87391cdcc4c` |
| Qt | `fidiiioo/moonlight-qt:feature/windows-spatial-audio-71` | `71ed01ea4aee44332f3f85d52f193b379ebb387d` |
| Common | `fidiiioo/moonlight-common-c:feature/native-audio-714` | `662def61a99d365d9cf7a6413d66eba01bfa6c33` |

Initialize the pinned submodules for each checkout. The installer source revision `5ab640d0a8b94658590b49495bb28c965f0ca054` is the direct parent of the Host commit above. An optional `src/installer` checkout selects that tree for the Host smoke test. The matching Windows virtual display payload is the [libvirtualdisplay 1.6.5 release](https://github.com/Nonary/libvirtualdisplay/releases/tag/v1.6.5) pinned by `third-party/libvirtualdisplay-release/windows-x64.json`.

The PowerShell helper uses Visual Studio 2022 Build Tools and Windows SDK 26100 from their normal installation paths. Under `-ToolRoot`, prepare the UCRT64 GCC/CMake/Ninja environment in `ucrt64`, .NET SDK 8.0.427 in `dotnet`, Qt 6.11.1 Release in `qt`, WiX in `wix314`, and the pinned Host FFmpeg libraries in `ffmpeg/ffmpeg`. For Moonlight, use the [v8 Windows prebuilt dependencies](https://github.com/moonlight-stream/moonlight-qt-deps/releases/tag/v8) in the Qt checkout's `libs/windows`.

From PowerShell 7, run the helper with `-WorkspaceRoot` pointing to the checkout workspace and pass `-ToolRoot` with the prepared portable dependencies. Each run uses a new check directory. It configures Common, builds and runs its focused audio protocol test, configures the Host and runs the Bridge smoke test, and generates the Qt Release makefiles. It performs no installer staging or deployment. Installer packaging additionally needs the USB/IP inputs pinned in the Host source. Consult the existing project rules for source changes and full release builds.

## Running the checks

In the workspace, run the helper in a dedicated PowerShell 7 process.
The tool root and workspace can live on any accessible Windows drive.

    pwsh -NoProfile -File .\src\host\tools\windows-native-workspace\Build-Check.ps1 -WorkspaceRoot . -ToolRoot D:\native-tools

The default output directory is temp/check-<timestamp> within the workspace.
Override its parent with -OutputRoot or choose a unique name with -RunName.
The report directory contains per-command logs and checks.json records the
exit codes. The helper uses vswhere to locate MSVC, with an explicit
-VcVarsPath override. The .NET SDK and Host build version defaults match the
starting points above and can be set via -DotnetSdkVersion and
-HostBuildVersion. The Qt revision comes from its checkout.

Prepare and pin dependencies before running the checks. The helper asks
CMake and npm to use local dependencies and blocks Git transport during the
build steps. It keeps toolchain environment changes in the child process
when run as shown above.
