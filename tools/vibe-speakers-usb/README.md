# Vibe Speakers USB device

This Windows user-mode library implements a virtual USB Audio Class 2 playback device for game streaming. Its PCM callback receives the audio written by Windows. Device descriptors and USB/IP requests are implemented in src/protocol.cpp. The controller in src/transport.cpp connects to usbip-win2 over its published ABI and exposes the device over loopback.

The device supports 48 kHz stereo, rear and side 5.1, 7.1 and 7.1.4 using PCM16 or 24 valid bits in 32-bit containers. Each session selects one format. The device and USB/IP descriptors use the same proposed identity across all formats.

## Allocation and integration status

1209:7140 is the requested identity. Live attachment is disabled pending allocation. The offline test uses the proposed descriptor in memory. After allocation, host integration must verify Windows selects the requested profile and restores the preceding endpoint across profile changes with a single PID. This source snapshot does not install drivers or enable streaming in Vibeshine.

## Build and test

In an x64 Native Tools Command Prompt for Visual Studio 2022 with the Windows SDK, change to an empty build directory and invoke the absolute path to build.cmd. The script produces vibe_speakers_usb.lib and protocol_tests.exe in the working directory and runs the offline protocol tests. No Administrator rights or installed USB/IP driver are needed for this test.

The source license is GPL-3.0-or-later, with a BSD-2-Clause notice in the driver ABI header. See THIRD-PARTY.md and the repository LICENSE.
