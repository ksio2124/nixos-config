"""Set only the XPS 9370 MMIO sustained package power limit."""

import sys
import time
from pathlib import Path


def set_limit(watts, root=Path('/sys'), sleep=time.sleep):
    zone = root / 'class/powercap/intel-rapl-mmio:0'
    limit = zone / 'constraint_0_power_limit_uw'
    for _ in range(30):
        if limit.exists():
            break
        sleep(1)
    else:
        raise RuntimeError('MMIO package power control did not appear')
    if (zone / 'name').read_text().strip() != 'package-0':
        raise RuntimeError('Unexpected MMIO power domain')
    if (zone / 'constraint_0_name').read_text().strip() != 'long_term':
        raise RuntimeError('Unexpected MMIO power constraint')
    target = watts * 1_000_000
    limit.write_text(str(target))
    actual = int(limit.read_text())
    if actual != target:
        raise RuntimeError(f'MMIO power readback {actual} does not match {target}')
    print(f'MMIO sustained CPU package power set to {watts} W', flush=True)


if __name__ == '__main__':
    if sys.argv[1:] == ['--apply']:
        set_limit(25)
    elif sys.argv[1:] == ['--restore']:
        set_limit(15)
    else:
        raise SystemExit('Expected --apply or --restore')
