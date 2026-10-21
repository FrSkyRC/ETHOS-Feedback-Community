## Introduction

Config script for FrSky stabilizer receiver.

## Update

- Introduce JA translation
- CN translation update
- New designed UI.
- Refine and categorize configuration items.
- Add a responsive configuration wizard process.
- Solution for Calibration Interface.
- Support for new receivers.
- Translation updated.
- Translation for Chinese added (Only support ETHOS version later than 1.7.0).

## Enhancement

- Add special calibration bitmaps and labels when script detects it is a SR6 Mini (E).
- Add a quick activation dialog when \"Gyro mode\" check fails.

## Fixes

- Fix the issue where configuring with an external module using scripts was not working.
- Fix an issue in Ethos 1.6.2 that could cause a read failure.
- Fix the issue where the script fails to load properly when certain languages are selected.
- Fix the issue where six-axis calibration does not work properly with certain receivers.
- Enlarged the bitmaps for receivers on the calibration page.

## V3.0.13

- Added missing translation string.

## V3.0.14

- Isolate script globals so they are not overwritten by other scripts.
- Fixed the backup and restore dialog text display issue.

## V3.0.15

- Improve display performance in light mode.

## V3.0.16

- Introduce the support for SR6BL15A
- Improve label display in calibration page.
- Add missing translation strings in some pages.

If you are running Ethos 1.6.0 or later, you can find it in the Device Config menu.
