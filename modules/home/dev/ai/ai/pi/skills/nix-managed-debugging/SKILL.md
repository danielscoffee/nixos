---
name: nix-managed-debugging
description: Debug Nix-managed path failures by proving ownership, version drift, and declarative source fixes before mutation.
---

# Nix-Managed Debugging

1. Reproduce and record the exact failing command and exact error.
2. Before any mutation, inspect the path's symlink destination, Nix store ownership, relevant `home.file` and XDG configuration, and module import chain.
3. Classify the destination as managed, generated, runtime, or unmanaged. Treat Nix store and managed symlink targets as immutable.
4. Check the installed tool version and current primary documentation for version or interface drift.
5. Fix the source NixOS or Home Manager module, not a generated target. Never run initialization commands into managed paths.
6. Validate the smallest relevant evaluation or build first, then run broader relevant checks.
7. Explain activation collisions, including which owner conflicts, and explain rollback path before activation.
8. Never delete user data automatically. Request explicit approval for any destructive remediation.
