#!/usr/bin/env python3
"""Bootstrap helper for the Velcord repository.

This script wraps the repository's pnpm workflow so you can install, build,
and launch the app with a single command.
"""

from __future__ import annotations

import argparse
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
PACKAGE_JSON = ROOT / "package.json"


def check_repo_root() -> None:
    if not PACKAGE_JSON.exists():
        print("ERROR: bootstrap.py must be run from the repository root.")
        sys.exit(1)


def check_package_manager() -> tuple[str, str]:
    pnpm = shutil.which("pnpm")
    if pnpm:
        return "pnpm", pnpm

    npm = shutil.which("npm")
    if npm:
        return "npm", npm

    print(
        "ERROR: neither pnpm nor npm is installed or found on PATH."
        " Install pnpm or npm first."
    )
    sys.exit(1)


def run_command(cmd: list[str], env: dict[str, str] | None = None) -> int:
    print("$", " ".join(cmd))
    result = subprocess.run(cmd, cwd=ROOT, env=env)
    return result.returncode


def install_dependencies(manager: str, executable: str) -> int:
    print("Installing dependencies...")
    if manager == "npm":
        return run_command([executable, "install", "--legacy-peer-deps"])
    return run_command([executable, "install"])


def build_dev(manager: str, executable: str) -> int:
    print("Building development bundle...")
    if manager == "pnpm":
        return run_command([executable, "build:dev"])
    return run_command([executable, "run", "build:dev"])


def start_dev(manager: str, executable: str) -> int:
    print("Starting the app in dev mode...")
    if manager == "pnpm":
        return run_command([executable, "start:dev"])
    return run_command([executable, "run", "start:dev"])


def start_watch(manager: str, executable: str) -> int:
    print("Starting the app in watch mode...")
    if manager == "pnpm":
        return run_command([executable, "start:watch"])
    return run_command([executable, "run", "start:watch"])


def electron_run(manager: str, executable: str) -> int:
    print("Launching Electron...")
    if manager == "pnpm":
        return run_command([executable, "electron", "."])
    return run_command([executable, "exec", "electron", "."])


def main() -> int:
    parser = argparse.ArgumentParser(description="Velcord bootstrap installer/compiler script")
    parser.add_argument(
        "command",
        nargs="?",
        default="run",
        choices=["install", "build", "run", "dev", "watch", "all"],
        help="Action to perform",
    )
    args = parser.parse_args()

    check_repo_root()
    manager, executable = check_package_manager()

    if args.command == "install":
        return install_dependencies(manager, executable)
    if args.command == "build":
        return build_dev(manager, executable)
    if args.command == "run":
        return build_dev(manager, executable) or electron_run(manager, executable)
    if args.command == "dev":
        return start_dev(manager, executable)
    if args.command == "watch":
        return start_watch(manager, executable)
    if args.command == "all":
        code = install_dependencies(manager, executable)
        if code != 0:
            return code
        code = build_dev(manager, executable)
        if code != 0:
            return code
        return electron_run(manager, executable)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
