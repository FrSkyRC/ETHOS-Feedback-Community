import subprocess
from ctypes import wintypes
import msvcrt
import contextlib
import os
import ctypes
import time

kernel32 = ctypes.WinDLL("kernel32", use_last_error=True)

GENERIC_READ = 0x80000000
GENERIC_WRITE = 0x40000000
FILE_SHARE_READ = 1
FILE_SHARE_WRITE = 2
CONSOLE_TEXTMODE_BUFFER = 1
INVALID_HANDLE_VALUE = wintypes.HANDLE(-1).value
STD_OUTPUT_HANDLE = wintypes.DWORD(-11)
STD_ERROR_HANDLE = wintypes.DWORD(-12)


def _check_zero(result, func, args):
    return args
    if not result:
        raise ctypes.WinError(ctypes.get_last_error())
    return args


def _check_invalid(result, func, args):
    if result == INVALID_HANDLE_VALUE:
        raise ctypes.WinError(ctypes.get_last_error())
    return args


if not hasattr(wintypes, "LPDWORD"):  # Python 2
    wintypes.LPDWORD = ctypes.POINTER(wintypes.DWORD)
    wintypes.PSMALL_RECT = ctypes.POINTER(wintypes.SMALL_RECT)


class COORD(ctypes.Structure):
    _fields_ = (("X", wintypes.SHORT), ("Y", wintypes.SHORT))


class CONSOLE_SCREEN_BUFFER_INFOEX(ctypes.Structure):
    _fields_ = (
        ("cbSize", wintypes.ULONG),
        ("dwSize", COORD),
        ("dwCursorPosition", COORD),
        ("wAttributes", wintypes.WORD),
        ("srWindow", wintypes.SMALL_RECT),
        ("dwMaximumWindowSize", COORD),
        ("wPopupAttributes", wintypes.WORD),
        ("bFullscreenSupported", wintypes.BOOL),
        ("ColorTable", wintypes.DWORD * 16),
    )

    def __init__(self, *args, **kwds):
        super(CONSOLE_SCREEN_BUFFER_INFOEX, self).__init__(*args, **kwds)
        self.cbSize = ctypes.sizeof(self)


PCONSOLE_SCREEN_BUFFER_INFOEX = ctypes.POINTER(CONSOLE_SCREEN_BUFFER_INFOEX)
LPSECURITY_ATTRIBUTES = wintypes.LPVOID

kernel32.GetStdHandle.errcheck = _check_invalid
kernel32.GetStdHandle.restype = wintypes.HANDLE
kernel32.GetStdHandle.argtypes = (wintypes.DWORD,)  # _In_ nStdHandle

kernel32.CreateConsoleScreenBuffer.errcheck = _check_invalid
kernel32.CreateConsoleScreenBuffer.restype = wintypes.HANDLE
kernel32.CreateConsoleScreenBuffer.argtypes = (
    wintypes.DWORD,  # _In_       dwDesiredAccess
    wintypes.DWORD,  # _In_       dwShareMode
    LPSECURITY_ATTRIBUTES,  # _In_opt_   lpSecurityAttributes
    wintypes.DWORD,  # _In_       dwFlags
    wintypes.LPVOID,
)  # _Reserved_ lpScreenBufferData

kernel32.GetConsoleScreenBufferInfoEx.errcheck = _check_zero
kernel32.GetConsoleScreenBufferInfoEx.argtypes = (
    wintypes.HANDLE,  # _In_  hConsoleOutput
    PCONSOLE_SCREEN_BUFFER_INFOEX,
)  # _Out_ lpConsoleScreenBufferInfo

kernel32.SetConsoleScreenBufferInfoEx.errcheck = _check_zero
kernel32.SetConsoleScreenBufferInfoEx.argtypes = (
    wintypes.HANDLE,  # _In_  hConsoleOutput
    PCONSOLE_SCREEN_BUFFER_INFOEX,
)  # _In_  lpConsoleScreenBufferInfo

kernel32.SetConsoleWindowInfo.errcheck = _check_zero
kernel32.SetConsoleWindowInfo.argtypes = (
    wintypes.HANDLE,  # _In_ hConsoleOutput
    wintypes.BOOL,  # _In_ bAbsolute
    wintypes.PSMALL_RECT,
)  # _In_ lpConsoleWindow

kernel32.FillConsoleOutputCharacterW.errcheck = _check_zero
kernel32.FillConsoleOutputCharacterW.argtypes = (
    wintypes.HANDLE,  # _In_  hConsoleOutput
    wintypes.WCHAR,  # _In_  cCharacter
    wintypes.DWORD,  # _In_  nLength
    COORD,  # _In_  dwWriteCoord
    wintypes.LPDWORD,
)  # _Out_ lpNumberOfCharsWritten

kernel32.ReadConsoleOutputCharacterW.errcheck = _check_zero
kernel32.ReadConsoleOutputCharacterW.argtypes = (
    wintypes.HANDLE,  # _In_  hConsoleOutput
    wintypes.LPWSTR,  # _Out_ lpCharacter
    wintypes.DWORD,  # _In_  nLength
    COORD,  # _In_  dwReadCoord
    wintypes.LPDWORD,
)  # _Out_ lpNumberOfCharsRead


@contextlib.contextmanager
def allocate_console():
    allocated = kernel32.AllocConsole()
    try:
        yield allocated
    finally:
        if allocated:
            kernel32.FreeConsole()


@contextlib.contextmanager
def console_screen(ncols=None, nrows=None):
    info = CONSOLE_SCREEN_BUFFER_INFOEX()
    new_info = CONSOLE_SCREEN_BUFFER_INFOEX()
    nwritten = (wintypes.DWORD * 1)()
    hStdOut = kernel32.GetStdHandle(STD_OUTPUT_HANDLE)
    kernel32.GetConsoleScreenBufferInfoEx(hStdOut, ctypes.byref(info))
    if ncols is None:
        ncols = info.dwSize.X
    if nrows is None:
        nrows = info.dwSize.Y
    elif nrows > 9999:
        raise ValueError("nrows must be 9999 or less")
    fd_screen = None
    hScreen = kernel32.CreateConsoleScreenBuffer(
        GENERIC_READ | GENERIC_WRITE,
        FILE_SHARE_READ | FILE_SHARE_WRITE,
        None,
        CONSOLE_TEXTMODE_BUFFER,
        None,
    )
    try:
        fd_screen = msvcrt.open_osfhandle(hScreen, os.O_RDWR | os.O_BINARY)
        kernel32.GetConsoleScreenBufferInfoEx(hScreen, ctypes.byref(new_info))
        new_info.dwSize = COORD(ncols, nrows)
        new_info.srWindow = wintypes.SMALL_RECT(
            Left=0,
            Top=0,
            Right=(ncols - 1),
            Bottom=(info.srWindow.Bottom - info.srWindow.Top),
        )
        kernel32.SetConsoleScreenBufferInfoEx(hScreen, ctypes.byref(new_info))
        kernel32.SetConsoleWindowInfo(hScreen, True, ctypes.byref(new_info.srWindow))
        kernel32.FillConsoleOutputCharacterW(
            hScreen, "\0", ncols * nrows, COORD(0, 0), nwritten
        )
        kernel32.SetConsoleActiveScreenBuffer(hScreen)
        try:
            yield fd_screen
        finally:
            kernel32.SetConsoleScreenBufferInfoEx(hStdOut, ctypes.byref(info))
            kernel32.SetConsoleWindowInfo(hStdOut, True, ctypes.byref(info.srWindow))
            kernel32.SetConsoleActiveScreenBuffer(hStdOut)
    finally:
        if fd_screen is not None:
            os.close(fd_screen)
        else:
            kernel32.CloseHandle(hScreen)


def read_screen(fd, encode):
    hScreen = msvcrt.get_osfhandle(fd)
    csbi = CONSOLE_SCREEN_BUFFER_INFOEX()
    kernel32.GetConsoleScreenBufferInfoEx(hScreen, ctypes.byref(csbi))
    ncols = csbi.dwSize.X
    pos = csbi.dwCursorPosition
    length = ncols * pos.Y + pos.X + 1
    buf = (ctypes.c_wchar * length)()
    n = (wintypes.DWORD * 1)()
    kernel32.ReadConsoleOutputCharacterA(hScreen, buf, length, COORD(0, 0), n)
    lines = [buf[i : i + ncols].rstrip("\0") for i in range(0, n[0], ncols)]
    if encode:
        return [q.encode("utf-16-le") for q in lines]
    return lines


def subprocess_conout(*args, nrows=9999, encode=True, **kwargs):
    # based on https://stackoverflow.com/a/38749458/15096247
    r"""
    Function to run a subprocess and capture its CONOUT$ console output.

    Args:
        *args: Variable length argument list.
        nrows: Number of rows to capture from the console output (default is 9999).
        encode: Boolean indicating whether to encode the console output (default is True).
        **kwargs: Variable length keyword argument list.

    Returns:
        The captured console output.
    """
    ret_line = "Sim exited"
    with allocate_console() as allocated:
        with console_screen(nrows=nrows) as fd_conout:
            child = subprocess.Popen(*args, **kwargs)
            try:
                while child.poll() is None:
                    time.sleep(0.2)
                    conout = read_screen(fd_conout, encode)
                    for line in conout:
                        if "error:" in line.decode("utf-8"):
                            child.kill()
                            ret_line = "Sim closed due to error: \n\033[31m"+line.decode("utf-8")+"\033[0m"
                            break
            finally:
                if child.poll() is None:
                    child.kill()
                    return ret_line
    return ret_line