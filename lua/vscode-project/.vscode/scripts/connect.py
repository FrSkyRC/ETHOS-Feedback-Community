#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Ethos Radio USB HID and deployment interface (cross-platform).

This module provides a unified interface for radio control on Windows and macOS.
Platform-specific drive management is handled by connect_windows.py or connect_macos.py.

Public API (stable across platforms):
  - RadioInterface: Main class for radio HID control and drive discovery
  - RadioInformation: Dataclass with board and storage info
  - flash_device(): Flash a .frsk device file
  - flash_firmware(): Flash a firmware.bin image
"""

import os
import platform
import shutil
import argparse
import time

# Import base and platform-independent constants
from connect_base import RadioInformation

# Select platform-specific implementation
if platform.system() == "Windows":
    from connect_windows import WindowsRadioInterface as RadioInterface, lock_drive, unmount_drive
elif platform.system() == "Darwin":
    from connect_macos import MacOSRadioInterface as RadioInterface
    # Provide no-op implementations for macOS (locking not supported)
    def lock_drive(drive):
        """No-op on macOS: volume locking via FSCTL is not available."""
        pass

    def unmount_drive(drive):
        """Unmount via diskutil; called by RadioInterface.unmount_drives()."""
        pass
else:
    raise SystemExit("System/OS not yet supported")



def flash_device(frsk):
    """Flash a .frsk device file."""
    print("Copy frsk to radio...")
    radio = RadioInterface()
    information = radio.request_information()
    storage_key = information.default_storage
    drive = radio.drives.get(storage_key)
    if not drive:
        raise RuntimeError(f"Radio storage '{storage_key}' not found in {radio.drives}")
    shutil.copy(frsk, os.path.join(drive, "device.frsk"))
    print("Lock the drive...")
    lock_drive(drive)
    print("Flash...")
    radio.flash_frsk()


def flash_firmware(firmware):
    """Flash a firmware.bin image."""
    print("Copy firmware to radio...")
    radio = RadioInterface()
    information = radio.request_information()
    storage_key = information.default_storage
    drive = radio.drives.get(storage_key)
    if not drive:
        raise RuntimeError(f"Radio storage '{storage_key}' not found in {radio.drives}")
    shutil.copy(firmware, os.path.join(drive, "firmware.bin"))
    print("Lock the drive...")
    lock_drive(drive)
    print("Flash...")
    radio.flash_firmware()


def massstorage_test():
    """Test mass storage mode switching."""
    index = 0
    while True:
        index += 1
        print("Test %d ..." % index)
        radio = RadioInterface()
        print("  radio drives:", radio.drives)

        print("  start the debug session during 30s ...")
        radio.start_usb_debug()
        time.sleep(10)

        print("  stop the debug session ...")
        radio = RadioInterface()
        radio.stop_usb_debug()
        time.sleep(1)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--massstorage-test', action="store_true")
    parser.add_argument('--flash-firmware', default=None)
    parser.add_argument('--flash-device', default=None)
    args = parser.parse_args()

    if args.massstorage_test:
        massstorage_test()
    elif args.flash_device:
        flash_device(args.flash_device)
    elif args.flash_firmware:
        flash_firmware(args.flash_firmware)


if __name__ == "__main__":
    main()
