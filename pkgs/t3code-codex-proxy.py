#!/usr/bin/env python3
"""Compatibility proxy for the released T3 Code Codex provider.

Only the model-list metadata is adjusted for T3 Code: released T3 versions
cannot decode the newer max/ultra reasoning effort names. All normal Codex
requests, authentication, and user configuration pass through unchanged.
"""

import json
import subprocess
import sys
import threading


UNSUPPORTED = {"max", "ultra"}


def normalize(value):
    if isinstance(value, list):
        return [normalize(item) for item in value]
    if not isinstance(value, dict):
        return value

    adjusted = {}
    for key, item in value.items():
        if key == "supportedReasoningEfforts" and isinstance(item, list):
            adjusted[key] = [
                normalize(entry)
                for entry in item
                if not (
                    isinstance(entry, dict)
                    and entry.get("reasoningEffort") in UNSUPPORTED
                )
            ]
        elif key in {"reasoningEffort", "defaultReasoningEffort"} and item in UNSUPPORTED:
            adjusted[key] = "xhigh"
        else:
            adjusted[key] = normalize(item)
    return adjusted


def copy_input(destination):
    for line in sys.stdin.buffer:
        destination.write(line)
        destination.flush()
    destination.close()


def main():
    if len(sys.argv) < 2:
        raise SystemExit("missing real Codex executable")

    child = subprocess.Popen(
        sys.argv[1:],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=None,
    )
    threading.Thread(target=copy_input, args=(child.stdin,), daemon=True).start()

    for raw_line in child.stdout:
        try:
            payload = json.loads(raw_line)
            sys.stdout.write(json.dumps(normalize(payload), separators=(",", ":")) + "\n")
            sys.stdout.flush()
        except (UnicodeDecodeError, json.JSONDecodeError):
            sys.stdout.buffer.write(raw_line)
            sys.stdout.buffer.flush()

    raise SystemExit(child.wait())


if __name__ == "__main__":
    main()
