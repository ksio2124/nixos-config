"""XPS 9370 fan steps, with hysteresis and BIOS fallback on any failure."""

import signal
import socket
import os
import sys
import time
from pathlib import Path


def device(name):
    matches = [p for p in Path('/sys/class/hwmon').glob('hwmon*')
               if (p / 'name').read_text().strip() == name]
    if len(matches) != 1:
        raise RuntimeError(f'Expected exactly one {name} device')
    return matches[0]


def write(path, value):
    path.write_text(str(value))


def restore():
    write(device('dell_smm') / 'pwm1_enable', 2)


def fan_state(temperature, previous):
    if not 0 < temperature < 120000:
        raise ValueError(f'Invalid CPU temperature: {temperature}')
    if temperature >= 70000:
        return 2
    if previous == 2 and temperature >= 62000:
        return 2
    if temperature >= 55000:
        return 1
    if previous >= 1 and temperature >= 48000:
        return 1
    return 0


def heartbeat():
    address = os.environ.get('NOTIFY_SOCKET')
    if address:
        if address.startswith('@'):
            address = '\0' + address[1:]
        with socket.socket(socket.AF_UNIX, socket.SOCK_DGRAM) as sock:
            sock.sendto(b'WATCHDOG=1', address)


def main():
    if '--restore' in sys.argv:
        restore()
        return
    fans = device('dell_smm')
    cpu = device('coretemp')
    if (cpu / 'temp1_label').read_text().strip() != 'Package id 0':
        raise RuntimeError('CPU package sensor not found')

    def stop(*_):
        raise SystemExit(0)

    signal.signal(signal.SIGTERM, stop)
    signal.signal(signal.SIGINT, stop)
    previous = 2
    stalled = {1: 0, 2: 0}
    try:
        # Establish cooling before disabling the firmware controller.
        for number in (1, 2):
            write(fans / f'pwm{number}', 255)
        write(fans / 'pwm1_enable', 1)
        while True:
            temperature = int((cpu / 'temp1_input').read_text())
            state = fan_state(temperature, previous)
            for number in (1, 2):
                write(fans / f'pwm{number}', (0, 128, 255)[state])
                rpm = int((fans / f'fan{number}_input').read_text())
                stalled[number] = stalled[number] + 1 if state and rpm == 0 else 0
                if stalled[number] >= 5:
                    raise RuntimeError(f'Fan {number} failed to spin; returning to BIOS control')
            if state != previous:
                print(f'CPU {temperature / 1000:.1f} C: fans {("off", "low", "high")[state]}', flush=True)
            previous = state
            heartbeat()
            time.sleep(2)
    finally:
        restore()


if __name__ == '__main__':
    main()
