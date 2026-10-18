"""Bounded PTY controls and backend-panic probe against the public run API.

Usage: python3 pty_probe.py /absolute/path/to/probe/binary
No HOME changes or history access. The probe only reads neutral input.
"""
import errno
import fcntl
import os
import pty
import select
import signal
import struct
import subprocess
import sys
import termios
import time


def exercise(mode):
    pid, master = pty.fork()
    if pid == 0:
        os.environ["TERM"] = "xterm-256color"
        os.execv(sys.argv[1], [sys.argv[1], mode])
    fcntl.ioctl(master, termios.TIOCSWINSZ, struct.pack("HHHH", 24, 80, 0, 0))
    output = bytearray()
    first_sent = False
    quit_sent = False
    started = time.monotonic()
    status = None
    timed_out = False
    try:
        while time.monotonic() - started < 5:
            ready, _, _ = select.select([master], [], [], 0.05)
            if ready:
                try:
                    data = os.read(master, 65536)
                except OSError as error:
                    if error.errno == errno.EIO:
                        data = b""
                    else:
                        raise
                output.extend(data)
                if b"\x1b[6n" in data:
                    os.write(master, b"\x1b[1;1R")
            elapsed = time.monotonic() - started
            if not first_sent and elapsed > 0.5:
                os.write(master, b"\x04" if mode == "eof" else b"hello\r")
                first_sent = True
            if mode == "normal" and b"HANDLED:hello" in output and not quit_sent:
                # Allow reedline to consume its next prompt pulse.
                time.sleep(0.1)
                os.write(master, b"quit\r")
                quit_sent = True
            found, status_now = os.waitpid(pid, os.WNOHANG)
            if found:
                status = status_now
                break
        else:
            timed_out = True
    finally:
        if status is None:
            os.kill(pid, signal.SIGTERM)
            _, status = os.waitpid(pid, 0)
        os.close(master)
    print(f"MODE={mode} timeout={timed_out} wait_status={status}")
    print(repr(bytes(output)))
    if mode == "panic":
        assert b"PROBE_BACKEND_PANIC" in output and timed_out
        assert b"PROBE_RETURNED" not in output
    else:
        assert not timed_out and status == 0 and b"PROBE_RETURNED:Ok(())" in output
        if mode == "normal":
            assert b"HANDLED:hello" in output


assert os.path.isfile(sys.argv[1]), "build the neutral probe binary first"
for probe_mode in ("normal", "eof", "panic"):
    exercise(probe_mode)

failed_input = subprocess.run(
    [sys.argv[1], "normal"], stdin=subprocess.DEVNULL,
    capture_output=True, timeout=5, check=False,
)
print(f"MODE=no-tty exit={failed_input.returncode}")
print(repr(failed_input.stdout), repr(failed_input.stderr))
# This failed-input oracle is for the recorded macOS audit environment.
assert b"input error:" in failed_input.stdout
assert b"PROBE_RETURNED:Ok(())" in failed_input.stderr
