# Repository Instructions

## Default Delivery

When you complete a requested code change in this repository:

1. Run the relevant verification commands when feasible.
2. Stage the files changed for the task.
3. Create a git commit with a concise message.
4. Push the current branch to `origin`.

Do this by default unless the user explicitly asks you not to commit or not to push.

## Safety

- Do not revert or overwrite unrelated user changes.
- If verification fails, report the failure before committing.
- If push fails because of authentication, network, or remote state, report the exact blocker.
- Every committed change should include a version bump in `pubspec.yaml`.
- Keep any in-app version file in sync with `pubspec.yaml`.
- Keep `CHANGELOG.md` updated in the same change.
