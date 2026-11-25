# Agent instructions

## In this repository

- Keep the installer compatible with Windows PowerShell 5.1 and PowerShell 7. Prefer the standard library and small changes.
- Before changing routing or package versions, consult official Codex and Headroom documentation. Validate the exact CLI flags and update both README sections.
- Run the smoke test after changes. Keep real credentials and authenticated model requests out of automated tests.
- Project files, auth files, Git metadata, Codex config and PowerShell profiles belong to the developer. Preserve them during install, update, start and uninstall.

## In a project launched with Codex Dev Memory

- Follow that project's own agent instructions. Read STATE.md from the memory directory named in the launch prompt. Use older notes only when relevant and verify them against the code.
- Put the current goal, verified progress, outstanding tasks and a concrete next step in STATE.md. Keep it within about 40 lines.
- Append dated entries to DECISIONS.md for lasting choices and their rationale. Append dated milestones and verification to PROGRESS.md. Coordinate edits when several sessions target the same project.
- Record summaries. Do not include secrets, environment dumps, customer information, transcripts, raw logs or credentials. Never paste these files wholesale into replies.
- Use narrow searches and short command outputs. Protect the normal sandbox and ask for approval through Codex if a memory write needs it.
