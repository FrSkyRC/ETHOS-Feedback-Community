#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from dataclasses import dataclass
import os
import time
import argparse
import ctypes
import ctypes.wintypes as wintypes
from ctypes import windll
import win32api
import win32file
import shutil

try:
    import hid
except ModuleNotFoundError:
    print("Error: hid module needed, you may use this command 'python -m pip install hid'")
    exit(-1)
except ImportError:
    print("Error: hidapi.dll is missing, you need to copy it from this project https://github.com/libusb/hidapi to C:\\Windows\\System32\\")
    exit(-1)

GENERIC_READ = 0x80000000
GENERIC_WRITE = 0x40000000
FILE_SHARE_READ = 0x00000001
FILE_SHARE_WRITE = 0x00000002
OPEN_EXISTING = 3
FSCTL_LOCK_VOLUME = 0x00090018
FSCTL_UNLOCK_VOLUME = 0x0009001c
FSCTL_DISMOUNT_VOLUME = 0x00090020
IOCTL_STORAGE_MEDIA_REMOVAL = 0x002d4804
IOCTL_STORAGE_EJECT_MEDIA = 0x002d4808
FILE_ATTRIBUTE_NORMAL = 0x00000080
INVALID_HANDLE_VALUE = -1


def fsctl_drive(drive, commands):
    handle = windll.kernel32.CreateFileW(
            ctypes.c_wchar_p(r'\\.\%s' % drive),
            GENERIC_READ | GENERIC_WRITE,
            FILE_SHARE_READ | FILE_SHARE_WRITE,
            0,
            OPEN_EXISTING,
            FILE_ATTRIBUTE_NORMAL,
            0)
    if handle != INVALID_HANDLE_VALUE:
        for command in commands:
            bytes_returned = wintypes.DWORD()
            inBuffer = wintypes.DWORD()
            retry = 10
            while retry > 0:
                status = windll.kernel32.DeviceIoControl(handle, command, ctypes.byref(inBuffer), 4, None, 0, ctypes.byref(bytes_returned), 0)
                if status > 0:
                    break
                retry -= 1
                if retry > 0:
                    print("DiskIoControl(%s, %X) failed, retrying after 1 second ..." % (drive, command))
                    time.sleep(1)
                else:
                    print("DiskIoControl(%s, %X) failed" % (drive, command))
    else:
        print("Open drive %s failed" % drive)


def unmount_drive(drive):
    fsctl_drive(drive, [FSCTL_LOCK_VOLUME, FSCTL_DISMOUNT_VOLUME, IOCTL_STORAGE_MEDIA_REMOVAL, IOCTL_STORAGE_EJECT_MEDIA])


def lock_drive(drive):
    fsctl_drive(drive, [FSCTL_LOCK_VOLUME])


ETHOS_SUITE_INFORMATION_REQUEST = 0x21
ETHOS_SUITE_INFORMATION_RESPONSE = 0x22
ETHOS_SUITE_FLASH_FIRMWARE_REQUEST = 0x41
ETHOS_SUITE_FLASH_FIRMWARE_RESPONSE = 0x42
ETHOS_SUITE_FLASH_FRSK_REQUEST = 0x51
ETHOS_SUITE_FLASH_FRSK_RESPONSE = 0x52
ETHOS_SUITE_REBOOT_REQUEST = 0x61
ETHOS_SUITE_FORMAT_STORAGE_REQUEST = 0x71
ETHOS_SUITE_FORMAT_STORAGE_RESPONSE = 0x72
ETHOS_SUITE_USB_MODE_REQUEST = 0x81
ETHOS_SUITE_USB_MODE_RESPONSE = 0x82


@dataclass
class RadioInformation:
    board: int
    default_storage: str  


class RadioInterface(hid.Device):
    def __init__(self, retries=10, retry_delay=0.5):
        last_error = None

        for attempt in range(1, retries + 1):
            try:
                hid.Device.__init__(self, vid=0x0483, pid=0x5750)
                break
            except hid.HIDException as e:
                last_error = e
                if attempt < retries:
                    time.sleep(retry_delay)
                else:
                    print("Error: No Ethos compatible device found!")
                    exit(-1)

        # Give Windows a moment to finish mounting volumes
        time.sleep(1)

        self.drives = {}
        self._scan_drives_internal()

    def unmount_drives(self):
        for drive in self.drives.values():
            unmount_drive(drive)

    def request_information(self):
        self.write(bytes([0x00, ETHOS_SUITE_INFORMATION_REQUEST, 6]))
        result = self.read(256, 200)
        if result:
            # print([hex(b) for b in result])
            board = result[2]
            return RadioInformation(
                board = board,
                default_storage = "sdcard" if board in [4, 5, 6, 11] else "radio",
            )

    def reboot_firmware(self):
        self.write(bytes([0x00, ETHOS_SUITE_REBOOT_REQUEST, 0x66]))

    def start_usb_debug(self):
        self.unmount_drives()
        self.write(bytes([0x00, ETHOS_SUITE_USB_MODE_REQUEST, 0x68]))
    
    def stop_usb_debug(self):
        self.write(bytes([0x00, ETHOS_SUITE_USB_MODE_REQUEST, 0x69]))

    def flash_frsk(self):
        self.write(bytes([0x00, ETHOS_SUITE_FLASH_FRSK_REQUEST]))

    def flash_firmware(self):
        self.write(bytes([0x00, ETHOS_SUITE_FLASH_FIRMWARE_REQUEST]))

    def _scan_drives_internal(self):
        """
        Scan removable drives for Ethos cpuid markers and populate self.drives.
        """
        self.drives = {}

        for drive in win32api.GetLogicalDriveStrings().split('\x00')[:-1]:
            dtype = win32file.GetDriveType(drive)
            if dtype != win32file.DRIVE_REMOVABLE:
                continue

            for key in ('flash', 'sdcard', 'radio'):
                if os.path.exists(os.path.join(drive, key + ".cpuid")):
                    # Normalise like existing code (e.g. 'H:')
                    self.drives[key] = drive.replace("\\", "")

    def scan_for_drives(self):
        """
        Public API for deploy tooling.
        Rescans removable drives and returns self.drives.
        """
        self._scan_drives_internal()
        return self.drives

    def get_scripts_dir(self):
        """
        Return the mounted scripts directory, or None.
        """
        self.scan_for_drives()

        # Prefer sdcard / radio over flash
        for key in ("sdcard", "radio", "flash"):
            root = self.drives.get(key)
            if root:
                scripts = os.path.join(root, "scripts")
                if os.path.isdir(scripts):
                    return os.path.normpath(scripts)

        return None


def massstorage_test():
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


def flash_device(frsk):
    print("Copy frsk to radio...")
    radio = RadioInterface()
    information = radio.request_information()
    shutil.copy(frsk, radio.drives[information.default_storage] + "/device.frsk")
    print("Lock the drive...")
    lock_drive(radio.drives[information.default_storage])
    print("Flash...")
    radio.flash_frsk()


def flash_firmware(firmware):
    print("Copy firmware to radio...")
    radio = RadioInterface()
    information = radio.request_information()
    shutil.copy(firmware, radio.drives[information.default_storage] + "/firmware.bin")
    print("Lock the drive...")
    lock_drive(radio.drives[information.default_storage])
    print("Flash...")
    radio.flash_firmware()


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
