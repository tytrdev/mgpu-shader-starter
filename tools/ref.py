#!/usr/bin/env python3
"""Single source of truth for the starter shader.

col = 0.5 + 0.5*cos(iTime + uv.xyx + vec3(0,2,4)), uv = fragCoord/iResolution.xy

fragCoord is a pixel center with origin at the bottom-left (GL/Shadertoy).
"""
import math
import sys


def expected_rgb(px, py, w, h, t=0.0):
    ux = (px + 0.5) / w
    uy = (py + 0.5) / h
    r = 0.5 + 0.5 * math.cos(t + ux + 0.0)
    g = 0.5 + 0.5 * math.cos(t + uy + 2.0)
    b = 0.5 + 0.5 * math.cos(t + ux + 4.0)
    return tuple(int(round(min(max(c, 0.0), 1.0) * 255.0)) for c in (r, g, b))


if __name__ == "__main__":
    w, h, px, py = (float(a) for a in sys.argv[1:5])
    t = float(sys.argv[5]) if len(sys.argv) > 5 else 0.0
    print(*expected_rgb(px, py, w, h, t))
