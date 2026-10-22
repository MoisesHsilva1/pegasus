# Repository Guidelines

## Project Structure & Module Organization

Pegasus is a Fedora Workstation/GNOME setup project implemented primarily in Bash. Root entry points are `install.sh`, `update.sh`, `uninstall.sh`, and `boot.sh`. Installation steps are grouped under `install/`, reusable actions under `scripts/`, and interactive commands under `bin/` and `bin/pegasus-sub/`. Application installers live in `applications/` and `install/**/optional/`. Defaults are in `defaults/` and `configs/`; themes are in `themes/`; historical upgrades belong in `migrations/`. Keep new functionality in the matching subsystem.

## Build, Test, and Development Commands

There is no compilation step or automated test framework. Run syntax validation before submitting changes:

```bash
find . -type f -name '*.sh' -print0 | xargs -0 -n1 bash -n
```

Run supported user flows on a Fedora GNOME test system:

```bash
bash install.sh       # install Pegasus and its base configuration
pegasus doctor        # check OS, package managers, services, and tools
pegasus theme list    # verify theme discovery
```

`install.sh` should not be run with `sudo`; it requests elevation when needed. Use `git diff --check` to catch whitespace errors.

## Coding Style & Naming Conventions

Use Bash with two-space indentation, readable lowercase variable names, and quoted variables unless word splitting is intentional. Prefer existing helper functions and absolute paths derived from the repository location. Name scripts descriptively in lowercase with hyphens where appropriate (for example, `select-dev-language.sh`); retain timestamp names for migration scripts. Preserve executable permissions and keep user-facing output consistent with the existing `gum`-based UI.

## Testing Guidelines

For script changes, run `bash -n` on all modified scripts and exercise the affected command or installer path on Fedora 40+ with GNOME/Wayland. Validate both success and missing-dependency paths where practical. There are no coverage thresholds or test naming conventions currently in use.

## Commit & Pull Request Guidelines

Use concise, imperative commit subjects. Existing history commonly uses prefixes such as `feat:`, `refactor:`, and `Update`; prefer Conventional Commit forms such as `feat:`, `fix:`, `refactor:`, or `docs:` for new work. Pull requests should explain the user-visible effect, identify affected scripts/themes, include validation commands and results, link related issues, and attach screenshots for GNOME, launcher, or theme changes.

## Security & Configuration Tips

Installer scripts alter packages, services, shell configuration, and desktop settings. Review command targets and privilege boundaries before execution; do not commit credentials, machine-specific paths, or generated configuration containing secrets. Test destructive uninstall behavior separately from installation changes.
