# Agent instructions

- Read `SPEC.md` before making architectural changes.
- Stay inside Hatchery v1 scope and keep implementations small.
- Prefer Bash and standard Linux tools; do not scaffold v1 non-goals.
- Preserve unrelated user configuration and never commit secrets.
- Do not take destructive actions without explicit user approval.
- Before finishing, run `make validate` and review the complete Git diff.
