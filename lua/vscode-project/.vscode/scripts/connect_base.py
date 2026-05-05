#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Cross-platform HID protocol and state management for Ethos radio.

This module contains the platform-neutral RadioInterface base class and
the HID protocol constants. Platform-specific drive management is delegated
to connect_windows.py or connect_macos.py.
"""

from dataclasses import dataclass
import time

try:
    import hid
except ModuleNotFoundError:
    raise ImportError("hid module needed; install with: python -m pip install hid")
except ImportError:
    raise ImportError("hidapi library is missing. On macOS, run: brew install hidapi")


# HID Protocol Constants
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

ETHOS_VENDOR_ID = 0x0483
# 0x5750 is the expected HID endpoint for Ethos USB mode control.
# 0x5740 is seen on some devices/firmware states during re-enumeration.
ETHOS_PRODUCT_IDS = (0x5750, 0x5740)


@dataclass
class RadioInformation:
    board: int
    default_storage: str


class RadioInterfaceBase(hid.Device):
    """
    Base class: HID communication with Ethos radio.

    Handles USB HID protocol for mode switching and device queries.
    Platform-specific drive discovery and management is delegated to
    subclasses via the drive_manager interface.
    """

    def __init__(self, retries=10, retry_delay=0.5):
        last_error = None

        for attempt in range(1, retries + 1):
            try:
                self._open_ethos_hid_device()
                break
            except Exception as e:
                last_error = e
                if attempt < retries:
                    time.sleep(retry_delay)
                else:
                    summary = self._summarize_ethos_candidates()
                    raise RuntimeError(f"No Ethos compatible HID device found ({summary})") from last_error

        # Give the platform a moment to finish enumerating/mounting
        time.sleep(1)

        self.drives = {}

    def _open_ethos_hid_device(self):
        """Open the Ethos HID interface using resilient probing strategies."""
        # Strategy 1: direct VID/PID open for known product IDs.
        for pid in ETHOS_PRODUCT_IDS:
            try:
                hid.Device.__init__(self, vid=ETHOS_VENDOR_ID, pid=pid)
                return
            except Exception:
                pass

        # Strategy 2: enumerate interfaces and open by exact device path.
        for dev in self._ethos_candidates_from_enumerate():
            path = dev.get("path")
            if not path:
                continue
            try:
                hid.Device.__init__(self, path=path)
                return
            except Exception:
                continue

        # Strategy 3: last-chance open by any enumerated vendor product id.
        for dev in self._ethos_candidates_from_enumerate():
            pid = dev.get("product_id")
            if pid is None:
                continue
            try:
                hid.Device.__init__(self, vid=ETHOS_VENDOR_ID, pid=pid)
                return
            except Exception:
                continue

        raise RuntimeError("HID open failed for all Ethos candidates")

    def _ethos_candidates_from_enumerate(self):
        """Return HID enumerate rows that look like Ethos devices."""
        candidates = []
        try:
            for dev in hid.enumerate():
                if dev.get("vendor_id") != ETHOS_VENDOR_ID:
                    continue
                pid = dev.get("product_id")
                usage_page = dev.get("usage_page")
                interface_number = dev.get("interface_number")

                # Prefer known Ethos PIDs; otherwise accept likely HID control interfaces.
                if pid in ETHOS_PRODUCT_IDS:
                    candidates.append(dev)
                    continue

                if usage_page in (0xFF00, 0x0001, 0x000C) or interface_number in (0, 1):
                    candidates.append(dev)
        except Exception:
            return []
        return candidates

    def _summarize_ethos_candidates(self):
        """Build a compact diagnostic summary for detection failures."""
        try:
            all_0483 = [d for d in hid.enumerate() if d.get("vendor_id") == ETHOS_VENDOR_ID]
            pids = sorted({d.get("product_id") for d in all_0483 if d.get("product_id") is not None})
            if not all_0483:
                return "vendor 0x0483 not present"
            if not pids:
                return f"vendor present ({len(all_0483)} interfaces), pid unknown"
            pid_text = ",".join(f"0x{p:04X}" for p in pids)
            return f"vendor present ({len(all_0483)} interfaces), pids={pid_text}"
        except Exception:
            return "unable to enumerate HID devices"

    def request_information(self):
        """Query radio board and storage info via HID."""
        self.write(bytes([0x00, ETHOS_SUITE_INFORMATION_REQUEST, 6]))
        result = self.read(256, 200)
        if result:
            board = result[2]
            return RadioInformation(
                board=board,
                default_storage="sdcard" if board in [4, 5, 6, 11] else "radio",
            )
        return None

    def reboot_firmware(self):
        """Reboot the radio firmware via HID."""
        self.write(bytes([0x00, ETHOS_SUITE_REBOOT_REQUEST, 0x66]))

    def start_usb_debug(self):
        """Switch radio to USB debug (serial) mode via HID."""
        unmount = getattr(self, "unmount_drives", None)
        if callable(unmount):
            try:
                unmount()
            except Exception:
                # Best-effort: still try the HID mode switch even if unmount fails.
                pass
        self.write(bytes([0x00, ETHOS_SUITE_USB_MODE_REQUEST, 0x68]))

    def stop_usb_debug(self):
        """Switch radio to mass-storage mode via HID."""
        self.write(bytes([0x00, ETHOS_SUITE_USB_MODE_REQUEST, 0x69]))

    def flash_frsk(self):
        """Trigger .frsk flash via HID."""
        self.write(bytes([0x00, ETHOS_SUITE_FLASH_FRSK_REQUEST]))

    def flash_firmware(self):
        """Trigger firmware flash via HID."""
        self.write(bytes([0x00, ETHOS_SUITE_FLASH_FIRMWARE_REQUEST]))
