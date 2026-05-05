#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Windows-specific drive management for Ethos radio deployment.

Uses win32api, win32file, and ctypes to query and control removable volumes.
"""

import os
import time
import ctypes
import ctypes.wintypes as wintypes
from ctypes import windll

import win32api
import win32file

from connect_base import RadioInterfaceBase, RadioInformation


# Windows drive control constants
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
    """Send FSCTL commands to a Windows drive."""
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
    """Unmount a Windows drive using FSCTL commands."""
    fsctl_drive(drive, [FSCTL_LOCK_VOLUME, FSCTL_DISMOUNT_VOLUME, IOCTL_STORAGE_MEDIA_REMOVAL, IOCTL_STORAGE_EJECT_MEDIA])


def lock_drive(drive):
    """Lock a Windows drive using FSCTL_LOCK_VOLUME."""
    fsctl_drive(drive, [FSCTL_LOCK_VOLUME])


class WindowsRadioInterface(RadioInterfaceBase):
    """Windows implementation: drive management via win32 APIs."""

    def __init__(self, retries=10, retry_delay=0.5):
        super().__init__(retries=retries, retry_delay=retry_delay)
        self._scan_drives_internal()

    def unmount_drives(self):
        """Unmount all discovered drives."""
        for drive in self.drives.values():
            unmount_drive(drive)

    def _scan_drives_internal(self):
        """Scan removable drives for Ethos cpuid markers and populate self.drives."""
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
        """Return the mounted scripts directory, or None."""
        self.scan_for_drives()

        # Prefer sdcard / radio over flash
        for key in ("sdcard", "radio", "flash"):
            root = self.drives.get(key)
            if root:
                scripts = os.path.join(root, "scripts")
                if os.path.isdir(scripts):
                    return os.path.normpath(scripts)

        return None
