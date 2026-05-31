#!/usr/bin/env python3
"""Run native `codex review` and format findings as a Markdown table."""

from __future__ import annotations

import argparse
import os
import re
import subprocess
from dataclasses import dataclass
from pathlib import Path


FINDING_RE = re.compile(
    r"^- \[(P\d+)\]\s+(.+?)\s+[—-]\s+(.+?):(\d+)(?:-(\d+))?\s*$"
)


@dataclass
class Finding:
    priority: str
    title: str
    location: str
    details: str


def run(command: list[str], cwd: str | Path) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        command,
        cwd=cwd,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        check=False,
    )


def git_repo_root(cwd: str) -> Path:
    result = run(["git", "rev-parse", "--show-toplevel"], cwd)
    if result.returncode != 0:
        raise SystemExit("Not inside a Git repository.")
    return Path(result.stdout.strip())


def ref_exists(ref: str, repo: Path) -> bool:
    return run(["git", "rev-parse", "--verify", "--quiet", ref], repo).returncode == 0


def default_remote_ref(repo: Path) -> str | None:
    result = run(["git", "symbolic-ref", "--quiet", "refs/remotes/origin/HEAD"], repo)
    if result.returncode == 0:
        value = result.stdout.strip()
        prefix = "refs/remotes/"
        if value.startswith(prefix):
            return value[len(prefix) :]
    for candidate in ("origin/main", "origin/master"):
        if ref_exists(candidate, repo):
            return candidate
    return None


def choose_base(requested: str, repo: Path) -> str:
    if ref_exists(requested, repo):
        return requested
    return default_remote_ref(repo) or requested


def clean_cell(text: str) -> str:
    return re.sub(r"\s+", " ", text.strip()).replace("|", r"\|")


def parse_findings(output: str, repo: Path) -> list[Finding]:
    findings: list[Finding] = []
    current: Finding | None = None
    details: list[str] = []

    def flush() -> None:
        nonlocal current, details
        if current is not None:
            current.details = clean_cell(" ".join(details))
            findings.append(current)
        current = None
        details = []

    for raw_line in output.splitlines():
        line = raw_line.rstrip()
        match = FINDING_RE.match(line)
        if match:
            flush()
            priority, title, path, start, end = match.groups()
            location = path
            repo_text = str(repo)
            if path.startswith(repo_text + os.sep):
                location = os.path.relpath(path, repo)
            line_range = start if end is None else f"{start}-{end}"
            current = Finding(
                priority=priority,
                title=clean_cell(title),
                location=clean_cell(f"{location}:{line_range}"),
                details="",
            )
            continue

        if current is not None:
            stripped = line.strip()
            if stripped and not stripped.startswith(("exec", "codex", "user")):
                details.append(stripped)

    flush()
    return findings


def markdown_table(findings: list[Finding], command: list[str], exit_code: int) -> str:
    lines = [f"Command: `{' '.join(command)}`", f"Exit code: `{exit_code}`", ""]
    if not findings:
        lines.append("| Result | Details |")
        lines.append("|---|---|")
        lines.append("| Clean | No parsed Codex review findings. |")
        return "\n".join(lines)

    lines.append("| Priority | Finding | Location | Details |")
    lines.append("|---|---|---|---|")
    for finding in findings:
        lines.append(
            "| "
            + " | ".join(
                [
                    clean_cell(finding.priority),
                    clean_cell(finding.title),
                    clean_cell(finding.location),
                    clean_cell(finding.details),
                ]
            )
            + " |"
        )
    return "\n".join(lines)


def review_command(args: argparse.Namespace, repo: Path) -> list[str]:
    if args.uncommitted:
        return ["codex", "review", "--uncommitted"]
    if args.commit:
        return ["codex", "review", "--commit", args.commit]
    return ["codex", "review", "--base", choose_base(args.base, repo)]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--base", default="origin/main", help="Base ref for branch review.")
    parser.add_argument("--commit", help="Review a single commit.")
    parser.add_argument("--uncommitted", action="store_true", help="Review staged, unstaged, and untracked changes.")
    parser.add_argument(
        "--raw-on-fail",
        action="store_true",
        help="Print raw Codex output when no findings are parsed.",
    )
    args = parser.parse_args()

    repo = git_repo_root(os.getcwd())
    command = review_command(args, repo)
    result = run(command, repo)
    findings = parse_findings(result.stdout, repo)
    print(markdown_table(findings, command, result.returncode))

    if args.raw_on_fail and not findings:
        print("\n<details>")
        print("<summary>Raw Codex review output</summary>\n")
        print("```text")
        print(result.stdout.rstrip())
        print("```")
        print("</details>")

    return result.returncode


if __name__ == "__main__":
    raise SystemExit(main())
