# README ledger format

Use these stable sections in a NixOS recovery repository:

1. Purpose and machine scope
2. Current validated snapshot
3. Restored components
4. Excluded runtime and personal state
5. Validation and restoration procedure
6. Significant change ledger

## Current snapshot

Record the date, flake configuration name, source/live commit synchronized,
last successful full-build output, and activation status. Update this only from
observed results.

## Significant change ledger

Use newest-first entries. Prefer one heading per day or accepted milestone:

```markdown
### YYYY-MM-DD — Short milestone name

- **Changed:** Major components, policies, packages, or workflows added or changed.
- **Reason:** User-facing goal or problem addressed.
- **Validated:** Evaluation, build, hardware/application tests, and secret scan.
- **State:** Built only, activated, persistent, or user-tested.
```

Record additions or changes involving desktop/session architecture, hardware
drivers, power management, storage/boot policy, networking, authentication,
security, package sources or pins, major applications, device integrations,
themes, and keybinding/workflow conventions.

Do not add entries for spelling corrections, comments, formatting, generated
lock noise already explained by a named input update, or internal script
refactoring with no recovery impact.

Keep entries concise. Git commits remain the detailed audit trail; the ledger
is the human-readable map of system evolution.
