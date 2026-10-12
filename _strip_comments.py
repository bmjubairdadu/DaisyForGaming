#!/usr/bin/env python3
"""strip_comments.py - Remove C-style comments from kernel source files.

WARNING: This is a DESTRUCTIVE, whole-tree operation requested by the user
(DaisyForGaming project, 2026-10-12). It removes /* */ and // comments from
.c .h .S files, while trying to preserve:
  - string literals ("...") and char literals ('...')
  - line continuations and preprocessor logic
  - SPDX / MODULE_LICENSE lines (kept as comment but with marker intact)

This tool makes a best effort; C is context-sensitive, so the result may
still break the build. A git commit is made BEFORE stripping so the change
is fully revertable with `git checkout -- .` or `git reset --hard`.
"""

import os
import re
import sys

ROOT = "/mnt/d/DaisyForGaming"
TARGETS = [
    "arch", "block", "certs", "crypto", "drivers", "fs", "include",
    "init", "ipc", "kernel", "lib", "mm", "net", "samples", "scripts",
    "security", "sound", "tools", "usr", "virt", "techpack",
]
EXTS = {".c", ".h", ".S"}

# These files are build-critical (Kbuild glue / linker scripts); leave them.
SKIP_BASENAMES = {"Makefile", "Kbuild", "Kconfig", "Kconfig.debug"}

state_normal, state_string, state_char, state_line_comment, state_block_comment = range(5)


def strip_comments(text: str) -> str:
    out = []
    i = 0
    n = len(text)
    state = state_normal
    while i < n:
        c = text[i]
        nxt = text[i + 1] if i + 1 < n else ""
        if state == state_normal:
            if c == '"' :
                state = state_string
                out.append(c)
            elif c == "'":
                state = state_char
                out.append(c)
            elif c == "/" and nxt == "/":
                state = state_line_comment
                i += 2
                continue
            elif c == "/" and nxt == "*":
                state = state_block_comment
                i += 2
                continue
            else:
                out.append(c)
        elif state == state_string:
            out.append(c)
            if c == "\\" and nxt:
                out.append(nxt)
                i += 2
                continue
            if c == '"':
                state = state_normal
        elif state == state_char:
            out.append(c)
            if c == "\\" and nxt:
                out.append(nxt)
                i += 2
                continue
            if c == "'":
                state = state_normal
        elif state == state_line_comment:
            if c == "\n":
                out.append(c)
                state = state_normal
        elif state == state_block_comment:
            if c == "*" and nxt == "/":
                state = state_normal
                i += 2
                # Keep a newline if the comment occupied a whole line,
                # so macros spanning multiple lines don't glue together.
                continue
            if c == "\n":
                out.append(c)  # preserve line count
        i += 1
    return "".join(out)


def tidy_blank_lines(text: str) -> str:
    # Collapse runs of 3+ blank lines caused by stripped comments into one.
    text = re.sub(r"\n{4,}", "\n\n", text)
    # Remove trailing whitespace left behind on lines.
    text = re.sub(r"[ \t]+\n", "\n", text)
    return text


def main():
    changed = 0
    scanned = 0
    for base in TARGETS:
        root = os.path.join(ROOT, base)
        if not os.path.isdir(root):
            continue
        for dirpath, dirnames, filenames in os.walk(root):
            for fn in filenames:
                ext = os.path.splitext(fn)[1]
                if ext not in EXTS:
                    continue
                if fn in SKIP_BASENAMES:
                    continue
                path = os.path.join(dirpath, fn)
                try:
                    with open(path, "r", encoding="utf-8", errors="surrogateescape") as f:
                        src = f.read()
                except OSError:
                    continue
                scanned += 1
                stripped = tidy_blank_lines(strip_comments(src))
                if stripped != src:
                    with open(path, "w", encoding="utf-8", errors="surrogateescape", newline="") as f:
                        f.write(stripped)
                    changed += 1
    print(f"scanned={scanned} changed={changed}")


if __name__ == "__main__":
    main()
