# Source and license notices

The USB Audio Class 2 implementation and tests are distributed under GPL-3.0-or-later. This version adapts the Vibe Speakers user-mode implementation to a single proposed product identity and disables live attachment pending assignment. The GPL text is in the repository LICENSE.

The USB/IP request framing and Windows transport adapt GPL-3.0-or-later code from Vibeshine. The following public revision contains the same three input files as the development snapshot. Their SPDX declarations and third-party notices apply.

- [USB/IP transport](https://github.com/Nonary/vibeshine/blob/9c02f262a799acd2733c203cbb7c4e59a55dd8fc/src/platform/windows/dualsense_usbip_transport.cpp)
- [USB/IP protocol](https://github.com/Nonary/vibeshine/blob/9c02f262a799acd2733c203cbb7c4e59a55dd8fc/src/platform/windows/dualsense_usbip_protocol.cpp)
- [Windows driver ABI header](https://github.com/Nonary/vibeshine/blob/9c02f262a799acd2733c203cbb7c4e59a55dd8fc/src/platform/windows/usbip_win2_abi.h)

The ABI declarations adapt the usbip-win2 header published by Vadym Hrynchyshyn. include/usbip_win2_abi.h retains its copyright, BSD-2-Clause terms and disclaimer. Reproduce them in accompanying materials when redistributing binaries containing this code.

- [usbip-win2 source license](https://github.com/vadimgrn/usbip-win2/blob/55e1fa7f0c2157017b02dc1f3236e98169a535e4/LICENSE.txt)

Windows supplies its own USB audio class driver. Neither that driver nor the usbip-win2 kernel binaries, Microsoft SDK files or signing materials are included in this module.
