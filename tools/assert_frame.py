#!/usr/bin/env python3
"""Assert a rendered frame against the reference formula.

Reads a binary PPM (P6) in display orientation (row 0 = top of image) and
checks center + corner pixels against tools/ref.py within a tolerance.
"""
import sys

from ref import expected_rgb

TOL = 2


def read_ppm(path):
    with open(path, "rb") as f:
        data = f.read()
    if not data.startswith(b"P6"):
        raise ValueError("not a P6 ppm")
    idx = 2
    fields = []
    while len(fields) < 3:
        while idx < len(data) and data[idx] in b" \t\r\n":
            idx += 1
        if idx < len(data) and data[idx:idx + 1] == b"#":
            while idx < len(data) and data[idx] not in b"\r\n":
                idx += 1
            continue
        start = idx
        while idx < len(data) and data[idx] not in b" \t\r\n":
            idx += 1
        fields.append(int(data[start:idx]))
    w, h, maxv = fields
    idx += 1
    px = data[idx:idx + w * h * 3]
    return w, h, px


def main(path):
    w, h, px = read_ppm(path)
    pts = [(0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1), (w // 2, h // 2)]
    ok = True
    for x, row in pts:
        i = (row * w + x) * 3
        actual = (px[i], px[i + 1], px[i + 2])
        gl_y = h - 1 - row  # display row 0 is top, GL origin is bottom
        exp = expected_rgb(x, gl_y, w, h, 0.0)
        diff = max(abs(a - e) for a, e in zip(actual, exp))
        mark = "ok" if diff <= TOL else "FAIL"
        if diff > TOL:
            ok = False
        print(f"  ({x},{row}) got {actual} want {exp} d={diff} {mark}")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1]))
