---
description: Open the Remote Toolkit SKILL — explicit trigger for the rt CLI guide
argument-hint: '[empty | natural-language request like "deploy sbatch to scratch"]'
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(rt:*), Bash(mutagen:*), Bash(ssh:*), Bash(scp:*), Bash(git:*)
---

Invoke the **remote** skill (`~/.claude/skills/remote/SKILL.md`) for the full Remote Toolkit guide. If `$ARGUMENTS` is non-empty, treat it as the user's intent under that skill — otherwise just load the guide and run `rt status --all` to enumerate profiles.
