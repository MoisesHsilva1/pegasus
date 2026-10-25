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
- **Safely uninstall Pegasus:**
  ```bash
  pegasus uninstall
  ```

During installation, Pegasus creates the persistent `pegasus-uninstall`
command at `~/.local/bin/pegasus-uninstall`. It uses the recovery manifest and
backups stored under `~/.local/state/pegasus/recovery`, so it remains available
even after the Pegasus checkout is removed.

Available options:

```bash
pegasus-uninstall --dry-run             # preview changes without modifying files
pegasus-uninstall --yes                 # run without interactive confirmation
pegasus-uninstall --report FILE         # save a detailed report
pegasus-uninstall --purge-recovery      # remove recovery data after success
```

The uninstaller restores files and GNOME settings only when they still match
the last state applied by Pegasus. Files or settings changed afterward are
preserved and reported as conflicts. Packages installed by Pegasus are listed
separately and require explicit confirmation before removal. Recovery data and
the report are preserved by default.

---

## Credits & Inspiration

Pegasus is built for Fedora Workstation and inspired by [Omakub](https://omakub.org).
