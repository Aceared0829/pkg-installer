# Arch BBS 发帖稿（Community Contributions）

- 板块：https://bbs.archlinux.org/viewforum.php?id=27
- 注意：BBS 允许发自己的作品，但**不要连发多个板块**，也不要把它写成广告。
  版规对「项目公告」的要求是：说清是什么、解决什么问题、为什么不直接用现成方案。

标题建议：`pkg-installer: install .deb/.rpm/AppImage/flatpak on Arch without root`

---

I kept running into the same thing: a vendor ships only a `.deb`, I unpack it with
`dpkg -d` or `bsdtar`, and then spend the next hour chasing `libwebkit2gtk-4.1-0`
through the AUR. The package works, but nothing in the system knows it exists —
no desktop entry, no icon, no way to uninstall it cleanly.

So I wrote a small GUI for it. It is a GTK4/libadwaita front end over a bash
backend, and it does three things:

**1. It tells you not to use it.** Before touching the package it greps the
official repos and the AUR. If there is a native package it shows a yellow banner
with a ready-to-paste `paru -S` command. Most of the time that is the right answer,
because a native package upgrades with `pacman -Syu` and a sideloaded one does not.

**2. It translates dependency names.** Debian writes package names
(`libwebkit2gtk-4.1-0` → `webkit2gtk-4.1`); RPM writes sonames
(`libgtk-3.so.0` → `gtk3`) with `()(64bit)` and `(GLIBC_2.34)` decorations to strip
first. 176 Debian-name mappings, 102 soname mappings and 17 RPM capability names
are built in. Missing ones are listed with a `pacman -S --needed` line. Names it
does not recognise are reported separately — it will not claim "all dependencies
satisfied" for something it cannot map.

**3. It installs into `~/.local`.** Files go to `~/.local/opt/<pkg>/`, one symlink
in `~/.local/bin`, one desktop entry with `Exec=` rewritten to an absolute path.
Uninstalling deletes those and nothing else. That was the main design constraint:
**nothing should end up in the pacman database that pacman did not put there.**
If you want a real FHS install, `distrobox` is the better tool and I say so in the
README.

Screenshots and a short recording: https://aceared0829.github.io/pkg-installer/

Source: https://github.com/Aceared0829/pkg-installer

Install (pacman repo, unsigned — `SigLevel = Optional TrustAll` is required for it):

```
[pkg-installer]
SigLevel = Optional TrustAll
Server = https://aceared0829.github.io/pkg-installer/x86_64
```

or into `~/.local` with no root at all:

```
curl -fsSL https://raw.githubusercontent.com/Aceared0829/pkg-installer/main/install.sh | bash
```

Known limits, because I would rather say them than have them found: it is for
self-contained applications (Electron, Tauri, Go single binaries). Anything that
wants absolute `/usr` paths, systemd units or kernel modules will not work. The
dependency tables are hand-written and will have gaps. The repo is unsigned.

Feedback on the mappings is the most useful thing anyone could send — a
`libfoo-bar1` that maps to the wrong Arch package is a one-line fix, and I would
rather have it reported than silently wrong.
