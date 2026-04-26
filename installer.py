#!/usr/bin/env python3
"""Installer/bootstrap script for the Velcord repository.

    This helper installs dependencies, builds the app, and launches Electron so you
    can run Velcord from the repository without manually typing pnpm commands.
"""

from __future__ import annotations

import argparse
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
PACKAGE_JSON = ROOT / "package.json"

NODE_MIN_MAJOR = 18


def fail(message: str) -> int:
    print(f"ERROR: {message}")
    return 1


def check_repo_root() -> bool:
    if PACKAGE_JSON.exists():
        return True

    print("ERROR: installer.py must be run from the repository root.")
    return False


def find_executable(names: list[str]) -> str | None:
    for name in names:
        path = shutil.which(name)
        if path:
            return path
    return None


def get_node_executable() -> str | None:
    return find_executable(["node", "node.exe"])


def get_package_manager() -> tuple[str, str] | None:
    pnpm = find_executable(["pnpm", "pnpm.cmd"])
    if pnpm:
        return "pnpm", pnpm

    npm = find_executable(["npm", "npm.cmd"])
    if npm:
        return "npm", npm

    return None


def check_node_version(node: str) -> bool:
    try:
        result = subprocess.run([node, "-v"], capture_output=True, text=True, check=True)
        version = result.stdout.strip().lstrip("v")
        major = int(version.split(".")[0])
        if major < NODE_MIN_MAJOR:
            print(f"WARNING: Node.js {version} detected. Velcord requires Node {NODE_MIN_MAJOR} or newer.")
            return False
        return True
    except Exception:
        return False


def run_command(cmd: list[str]) -> int:
    print("$", " ".join(cmd))
    return subprocess.run(cmd, cwd=ROOT).returncode


def install_dependencies(manager: str, executable: str) -> int:
    print("Installing repository dependencies...")
    if manager == "npm":
        return run_command([executable, "install", "--legacy-peer-deps"])
    return run_command([executable, "install"])


def build_dev(manager: str, executable: str) -> int:
    print("Building the app for development...")
    if manager == "pnpm":
        return run_command([executable, "build:dev"])
    return run_command([executable, "run", "build:dev"])


def launch_app(manager: str, executable: str) -> int:
    print("Launching Velcord...")
    if manager == "pnpm":
        return run_command([executable, "electron", "."])
    return run_command([executable, "exec", "electron", "."])


def main() -> int:
    parser = argparse.ArgumentParser(description="Installer/bootstrap for Velcord")
    parser.add_argument(
        "command",
        nargs="?",
        default="run",
        choices=["install", "build", "run", "launch", "all"],
        help="Action to perform",
    )
    args = parser.parse_args()

    if not check_repo_root():
        return 1

    node = get_node_executable()
    if not node:
        return fail("Node.js is not installed or not available on PATH. Install Node.js first.")

    if not check_node_version(node):
        return fail(f"Node.js {NODE_MIN_MAJOR}+ is required.")

    pm = get_package_manager()
    if not pm:
        return fail("Neither pnpm nor npm is installed or available on PATH.")

    manager, executable = pm
    print(f"Using package manager: {manager}")

    if args.command == "install":
        return install_dependencies(manager, executable)

    if args.command == "build":
        return build_dev(manager, executable)

    if args.command in {"run", "launch"}:
        code = build_dev(manager, executable)
        if code != 0:
            return code
        return launch_app(manager, executable)

    if args.command == "all":
        code = install_dependencies(manager, executable)
        if code != 0:
            return code
        code = build_dev(manager, executable)
        if code != 0:
            return code
        return launch_app(manager, executable)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
