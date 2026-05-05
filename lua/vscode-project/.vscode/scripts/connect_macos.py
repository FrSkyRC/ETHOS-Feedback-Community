#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
macOS-specific drive management for Ethos radio deployment.

Discovers radio volumes by scanning /Volumes for .cpuid markers.
Eject operations use diskutil. Volume locking is not available on macOS
(no FSCTL_LOCK_VOLUME equivalent), but is not strictly needed since the
deployment workflow is sequential and user-initiated.
"""

import os
import subprocess
from connect_base import RadioInterfaceBase, RadioInformation


class MacOSRadioInterface(RadioInterfaceBase):
    """macOS implementation: drive discovery via /Volumes scanning."""

    def __init__(self, retries=10, retry_delay=0.5):
        super().__init__(retries=retries, retry_delay=retry_delay)
        self._scan_drives_internal()

    def unmount_drives(self):
        """
        Unmount all discovered drives using diskutil.

        On macOS, we first unmount mounted volumes so the radio can switch away
        from mass-storage mode. This is best-effort.
        Volume locking (Windows FSCTL_LOCK_VOLUME) is not available on macOS,
        but is not critical for the sequential, user-initiated deployment workflow.
        """
        for drive in sorted(set(self.drives.values())):
            try:
                result = subprocess.run(
                    ["diskutil", "unmount", drive],
                    capture_output=True,
                    text=True,
                    timeout=5,
                )
                if result.returncode != 0:
                    subprocess.run(
                        ["diskutil", "eject", drive],
                        capture_output=True,
                        text=True,
                        timeout=5,
                    )
            except Exception as e:
                print(f"[macOS] diskutil unmount/eject {drive} failed ({type(e).__name__}: {e}); continuing anyway.")

    def _scan_drives_internal(self):
        """
        Scan /Volumes for Ethos cpuid markers and populate self.drives.

        On macOS, removable volumes are mounted under /Volumes.
        We check for flash.cpuid, sdcard.cpuid, and radio.cpuid markers
        to identify Ethos radio storage partitions.
        """
        self.drives = {}

        volumes_dir = "/Volumes"
        if not os.path.isdir(volumes_dir):
            return

        try:
            entries = os.listdir(volumes_dir)
        except OSError:
            return

        for entry in entries:
            volume_path = os.path.join(volumes_dir, entry)

            # Skip if not a directory or if it's a system volume
            if not os.path.isdir(volume_path):
                continue

            for key in ('flash', 'sdcard', 'radio'):
                cpuid_marker = os.path.join(volume_path, key + ".cpuid")
                if os.path.exists(cpuid_marker):
                    # Store the volume path (normalized)
                    self.drives[key] = os.path.normpath(volume_path)

    def scan_for_drives(self):
        """
        Public API for deploy tooling.
        Rescans /Volumes for cpuid markers and returns self.drives.
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
