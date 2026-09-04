# Daily workflow

Hatchery keeps the terminal session on the VPS while Git remains the durable record of the work.

## Connect and enter a session

From a Mac terminal or the Termius host on your phone:

```bash
ssh <user>@<server>
tmux attach -t codex
```

If the session does not exist yet, create it:

```bash
tmux new -s codex
```

Use a separate session for Hermes when useful:

```bash
tmux new -s hermes
```

Detach with `Ctrl+b`, then `d`. Closing SSH after detaching does not stop commands inside tmux.

## Work in a project

Each repository is independent and lives under `~/projects`:

```bash
cd ~/projects
git clone <repository-url>
cd <repository>
git switch -c <branch-name>
```

Do not work directly on `main` unless explicitly instructed. Start the agent from the repository root so it receives the correct project context:

```bash
codex
# or
hermes
```

## Verify and publish

After the agent finishes, use the project's own test and formatting commands. Then inspect all changes before committing:

```bash
git status --short
git diff
git diff --staged
```

Stage only the intended files, commit, and push the branch:

```bash
git add <files>
git commit -m "Describe the change"
git push -u origin <branch-name>
```

Open a pull request with GitHub CLI:

```bash
gh pr create
```

The complete loop is: SSH -> tmux -> `~/projects/<repo>` -> branch -> Codex or Hermes -> project checks -> diff review -> commit -> push -> pull request.
