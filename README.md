# Pegasus

Pegasus is a customized Fedora developer environment setup inspired by Omakub.

The goal of Pegasus is to transform a fresh Fedora Workstation installation into a complete, ready-to-use development workstation with pre-configured tools, terminal workflows, desktop themes, and GNOME customizations.

## Requirements

- **OS:** Fedora Workstation 40+
- **Desktop:** GNOME (Wayland)
- **Privileges:** Standard user with `sudo` access
- **Network:** Active Internet connection

### Optional desktop integrations

ASDControl, Google Chrome, Alacritty, Flameshot, and Ulauncher are optional.
Pegasus configures their shortcuts only when the corresponding command or
desktop entry is present. Search Light owns `Super+Space`; Ulauncher uses
`Super+Shift+Space` so both can coexist.

The GNOME profile installs extensions through `gext` and keeps user-installed
assets under `$HOME`: the `macOS-Pegasus` shell theme, macOS cursor, and
`dos-moos/BG1.jpg` wallpaper. No machine-specific `/home/<user>` path or dconf
dump is committed.

---

## Quick Installation

Clone the repository:

```bash
git clone https://github.com/MoisesHsilva1/Pegasus.git ~/.local/share/pegasus
cd ~/.local/share/pegasus
```

Run the automated installer:

```bash
bash install.sh
```

> **Note:** Do **not** run `install.sh` using `sudo`. Pegasus will request administrator permissions when necessary.

The installer targets Fedora Workstation with an active GNOME session. In
interactive mode it checks for the `gum` interface before showing the plan. If
`gum` is missing, Pegasus attempts to install it from Charmbracelet and
validates that the command is usable. If that bootstrap cannot complete, install
it manually and run the installer again:

```bash
sudo dnf install -y gum
bash install.sh
```

Before changing the system, the installer shows an editable plan. Use
`bash install.sh --yes` for the default choices without interactive prompts,
`pegasus install --review` to edit and save choices, or
`pegasus install --resume` to retry only unfinished steps. Progress is stored
without credentials in `~/.config/pegasus/installer-state.json`, with details in
`~/.local/state/pegasus/install.log`.

The base profile does not install Docker databases, Neovim, or LazyVim. The
manual install menu keeps database setup available for an explicit later run.

---

## Pegasus Control Center & Management

Pegasus provides both a terminal CLI interface and native GNOME desktop launchers.

### 1. Pegasus Control Center

Open the central interactive management menu by running in your terminal:

```bash
pegasus
```

Or open GNOME Applications / Ulauncher (`Super + Space`) and search for:

> **Pegasus Control Center**

Features available inside the Control Center:
- **Theme:** Switch visual desktop themes (Tokyo Night, Catppuccin, Nord, Gruvbox, etc.)
- **Font:** Change coding fonts (Cascadia Mono, Fira Mono, JetBrains Mono) and font sizes
- **Install / Uninstall:** Add or remove optional applications and development tools
- **Update:** Upgrade Pegasus and managed packages
- **Manual:** Access online project documentation

---

### 2. Pegasus Theme Manager

To open the interactive theme selector directly from the terminal:

```bash
pegasus theme
```

Or search GNOME Applications / Ulauncher for:

> **Pegasus Theme**

#### Theme CLI Commands:

- **List available themes:**
  ```bash
  pegasus theme list
  ```
- **Show active theme:**
  ```bash
  pegasus theme current
  ```
- **Apply a theme directly (by name or index):**
  ```bash
  pegasus theme apply Nord
  # or
  pegasus theme apply 6
  ```

---

### 3. Programming Font Manager

Change terminal & editor fonts or sizes:

```bash
pegasus font
```

---

### 4. System Diagnostics (Pegasus Doctor)

Verify OS version, package managers, Docker service status, and installed tools:

```bash
pegasus doctor
```

---

### 5. Maintenance Commands

- **Update Pegasus & Packages:**
  ```bash
  pegasus update
  ```

## How to Uninstall Pegasus

To remove Pegasus after it has been installed, run this command from any
directory:

```bash
pegasus-uninstall
```

You can also start it through the Pegasus CLI:

```bash
pegasus uninstall
```

The recommended process is:

1. Preview what will be restored or removed:
   ```bash
   pegasus-uninstall --dry-run
   ```
2. Run the uninstaller normally and answer `y` when it asks for confirmation:
   ```bash
   pegasus-uninstall
   ```
3. If package removal is offered, confirm it separately if you also want to
   remove packages installed by Pegasus.

During installation, Pegasus creates `~/.local/bin/pegasus-uninstall`. This
is a standalone command: it does not depend on the Pegasus checkout, so it
continues to work even if `~/.local/share/pegasus` is deleted first.

The recovery manifest and backups are kept at:

```text
~/.local/state/pegasus/recovery/
```

Useful options:

```bash
pegasus-uninstall --dry-run                    # preview only; change nothing
pegasus-uninstall --yes                        # confirm the complete operation automatically
pegasus-uninstall --report ~/pegasus-report.txt # save a detailed report
pegasus-uninstall --purge-recovery             # delete backups after a successful uninstall
```

The uninstaller is deliberately conservative. It restores a file or GNOME
setting only when it still matches the last value applied by Pegasus. If you
changed it afterward, Pegasus leaves it untouched and records the conflict in
the report. Recovery data and the generated report are preserved unless
`--purge-recovery` is explicitly used.

If `pegasus-uninstall` is not found, the installation did not create the
persistent uninstaller or the user's `~/.local/bin` is not in `PATH`. Run it
using its full path:

```bash
~/.local/bin/pegasus-uninstall
```

---

## Credits & Inspiration

Pegasus is built for Fedora Workstation and inspired by [Omakub](https://omakub.org).
