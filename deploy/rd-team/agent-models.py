#!/usr/bin/env python3
"""List Wulan models or change the shared agent's default model."""

import argparse
from datetime import datetime, timezone
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import urllib.error
import urllib.request


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=["list", "use"])
    parser.add_argument("model", nargs="?")
    args = parser.parse_args()
    if args.action == "use" and not args.model:
        parser.error("use requires a model ID")
    if args.action == "list" and args.model:
        parser.error("list does not accept a model ID")

    path = Path("/etc/rd-team-agent/agent.env")
    lines = path.read_text().splitlines()
    env = {}
    for line in lines:
        if line and not line.startswith("#"):
            name, value = line.split("=", 1)
            env[name] = json.loads(value)

    request = urllib.request.Request(
        env["OPENAI_COMPAT_BASE_URL"].rstrip("/") + "/models",
        headers={"Authorization": "Bearer " + env["OPENAI_COMPAT_API_KEY"]},
    )
    with urllib.request.urlopen(request, timeout=20) as response:
        models = sorted({item["id"] for item in json.load(response)["data"]})

    if args.action == "list":
        print(json.dumps({"current": env["BUZZ_AGENT_MODEL"], "models": models}, indent=2))
        return
    if args.model not in models:
        raise ValueError("The model is absent from Wulan's current catalog.")
    if args.model == env["BUZZ_AGENT_MODEL"]:
        print("The agent already uses this model.")
        return

    backup_dir = path.parent / "backups"
    backup_dir.mkdir(mode=0o700, exist_ok=True)
    stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S.%fZ")
    backup = backup_dir / ("agent-" + stamp + ".env")
    shutil.copy2(path, backup)
    backup.chmod(0o600)
    updated = [
        "BUZZ_AGENT_MODEL=" + json.dumps(args.model)
        if line.startswith("BUZZ_AGENT_MODEL=")
        else line
        for line in lines
    ]
    with tempfile.NamedTemporaryFile(mode="w", dir=path.parent, delete=False) as pending:
        pending.write("\n".join(updated) + "\n")
        pending.flush()
        os.fsync(pending.fileno())
        pending_path = pending.name
    os.replace(pending_path, path)
    subprocess.run(["systemctl", "restart", "rd-team-agent.service"], check=True)
    print("Agent model changed to " + args.model)
    print("Previous configuration: " + str(backup))


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, KeyError, urllib.error.URLError, subprocess.CalledProcessError) as error:
        print("Model operation failed: " + str(error), file=sys.stderr)
        sys.exit(1)
