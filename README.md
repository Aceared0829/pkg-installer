# deb-installer

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Arch_Linux-1793d1)](https://archlinux.org)
[![Built with](https://img.shields.io/badge/GTK4-libadwaita-4a86cf)](https://gnome.org)

<img src="docs/icon.png" width="96" align="right" alt="">

**在 Arch 上双击安装 .deb 文件，免 root，不污染 pacman 数据库。**

很多软件只发 `.deb`。Arch 上你有 `dpkg`，但 `/var/lib/dpkg/status` 是空的——`sudo dpkg -i` 会解包成功然后装出一个跑不起来的东西。

这个工具换个思路：**不试图让 Arch 变成 Debian，而是把 .deb 里自包含的那部分解出来，装进你的家目录。**

![界面](docs/screenshots/02-aur-hit.png)

[English](#english)

## 它做三件事

**1. 先告诉你有没有更好的办法**

拿到一个 `.deb`，它第一件事不是装，是去 `pacman` 官方库和 AUR 里搜同名包。搜到了就亮黄条：

> AUR 已有：`aur/gearlever` —— 直接 `paru -S gearlever` 更省事，跟着系统一起升级，不用担心依赖漂移。

旁边一个按钮，点了就把命令复制到剪贴板。**这是我最想要的行为**：绝大多数国产客户端在 AUR 或 Flathub 上都有，用原生的包意味着以后 `pacman -Syu` 就能升级，而不用回去重新下 deb。

**2. 把 deb 的依赖名翻译成 Arch 的**

`libwebkit2gtk-4.1-0` → `webkit2gtk-4.1`，`libayatana-appindicator3-1` → `libayatana-appindicator`……内置 88 条映射（覆盖 76 个 Arch 包）。

缺什么就红条列出来，附一条可以直接粘的 `sudo pacman -S --needed ...`。不认识的名字单独归类（不假装「依赖齐全」）——因为我确实不认识它，那你也不该信我。

![缺依赖](docs/screenshots/03-missing-deps.png)

**3. 解包、链接、导入图标，全过程不要 root**

```
.deb ──dpkg-deb -x──> ~/.local/opt/<包名>/
                       ├── usr/bin/app          ← 程序本体
                       ├── usr/share/applications/app.desktop
                       └── usr/share/icons/...
                              ↓
      ~/.local/bin/app ──软链──┘
      ~/.local/share/applications/app.desktop  （Exec= 改成绝对路径）
```

卸载就是删掉那个目录和几条软链，**系统里不会留下任何 pacman 不认识的东西**。

![安装中](docs/screenshots/04-installing.png)
![已安装](docs/screenshots/05-installed.png)

## 装到你的机器上

```bash
git clone https://github.com/Aceared0829/deb-installer.git
cd deb-installer
./install.sh
```

或者不 clone：

```bash
curl -fsSL https://raw.githubusercontent.com/Aceared0829/deb-installer/main/install.sh | bash
```

装完：

```bash
deb-installer                    # 打开界面
deb-installer ~/下载/xxx.deb      # 直接载入
deb2local ~/下载/xxx.deb          # 纯命令行，一样的逻辑
xdg-open ~/下载/xxx.deb           # 等价于文件管理器里双击
```

卸载本项目（不影响你用 deb 装的那些应用）：

```bash
./install.sh --uninstall
```

### 依赖

`dpkg` `python-gobject` `gtk4` `libadwaita` —— 在 CachyOS 上全都已经是装好的。检查一下：

```bash
pacman -Q dpkg python-gobject gtk4 libadwaita
```

## 命令行

后端 `deb2local` 是个独立的 bash 脚本，图形界面只是它的壳。你可以完全不用 GUI：

```bash
deb2local 包.deb            # 安装
deb2local 包.deb -y         # 安装，不询问
deb2local 包.deb --deps     # 只检查依赖，不装
deb2local 包.deb --json     # 机器可读输出，给脚本/前端用
deb2local --uninstall 名    # 卸载
```

`--json` 输出长这样，`deb-installer` 就是靠它工作的：

```json
{
  "package": "clash-verge-rev",
  "version": "2.5.0",
  "arch": "amd64",
  "arch_equivalent": "aur/clash-verge-rev-bin",
  "unknown_deps": [],
  "missing_deps": ["webkit2gtk-4.1"]
}
```

## 同名命令冲突：会备份，不会覆盖

这是这个项目里我最在意的一个细节。

如果要链接的命令 `~/.local/bin/foo` 已经存在，而且**不是**本工具之前创建的软链，它会：

```bash
mv ~/.local/bin/foo  ~/.local/bin/foo.bak-20261113-135137
ln -sfn ~/.local/opt/新包/usr/bin/foo  ~/.local/bin/foo
```

并打一行黄色警告。**永不静默覆盖。**

这不是假想的谨慎。开发过程中测试同名冲突时，这个工具的第一版差点吃掉我手写的一个启动器脚本——一个 691 字节的 bash 包装器，带 `bwrap` 命名空间映射。如果被覆盖，那个应用就再也起不来了。桌面条目那一层也有同样的保护。

## 已知限制

| 限制 | 说明 |
|---|---|
| 只处理 `.deb` | rpm / AppImage / snap 都不认。AppImage 用 [Gearlever](https://github.com/mijorus/gearlever)，rpm 用 `rpmextract` |
| 不自动装系统依赖 | 只告诉缺什么，不替你 `pacman -S`。装系统包应该你确认 |
| 硬编码 `/usr` 的程序会崩 | 部分 Electron 应用和带服务/内核模块的包。日志里会提示改用 distrobox |
| 卸载不清 `~/.config` | 配置留着，和 pacman 行为一致 |
| 只支持 Arch 系 | 需要 `pacman`。Debian/Ubuntu 上你本来就用 `apt`，不需要这个 |

## 为什么不用现有的工具

| 工具 | 为什么我没用 |
|---|---|
| `dpkg -i` | Arch 上没有 dpkg 数据库，依赖全部不认识 |
| `debtap` | 把 deb 转成 `.pkg.tar.zst` 再 `pacman -U`。要 root，装进系统，升级时和 pacman 打架 |
| `alien` | 同上的老方案，转换质量更差 |
| `distrobox` | 重量级（一个完整 Ubuntu 容器），适合真的需要一个 Debian 用户空间的时候。对一个自包含的 Electron 应用来说是杀鸡用牛刀 |
| `bauh` | 图形化的多后端管理器，但它的 deb 支持也是走 `dpkg`，踩同一个坑 |

这个工具的定位是**第四种**：假装 deb 是一个自解压的 tarball，装进用户目录。它不解决所有情况，但解决了最常见的那种——「官方只发 deb，我要用它，但我不想为它装一整个 Debian」。

## 项目结构

```
bin/deb2local       后端（bash，398 行），所有实际逻辑在这里
bin/deb-installer   图形前端（Python + GTK4 + libadwaita，727 行）
desktop/            桌面条目模板和应用图标
docs/screenshots/   真机截图，非设计稿
install.sh          安装 / 卸载
```

前端和后端是**严格的调用关系**，不是两份实现：GUI 里的每个动作都是 `subprocess` 调 `deb2local`，所以两者行为不可能漂移。

---

<a id="english"></a>

# English

**Double-click to install `.deb` files on Arch Linux — no root, no pollution of the pacman database.**

Plenty of software ships only a `.deb`. Arch has `dpkg`, but its status database is empty, so `sudo dpkg -i` unpacks the files and then leaves you with a program that can't find its dependencies.

This tool takes a different angle: **instead of turning Arch into Debian, it extracts the self-contained part of a `.deb` and installs it into your home directory.**

### What it does

1. **Checks for a native package first.** Before installing anything, it searches the official repos and the AUR. If there's a match, it says so and offers a one-click copy of `paru -S <pkg>`. Native packages upgrade with `pacman -Syu`; a sideloaded `.deb` doesn't.
2. **Translates Debian dependency names to Arch ones.** 88 Debian-to-Arch mappings built in (`libwebkit2gtk-4.1-0` → `webkit2gtk-4.1`, etc.). Missing packages are listed with a ready-to-paste `pacman` command. Unrecognized names are reported separately rather than being counted as satisfied.
3. **Unpacks, links, imports icons — entirely without root.** Files go to `~/.local/opt/<pkg>/`, a symlink into `~/.local/bin/`, a desktop entry with `Exec=` rewritten to an absolute path. Uninstalling removes those and nothing else.

### Install

```bash
git clone https://github.com/Aceared0829/deb-installer.git
cd deb-installer && ./install.sh
```

Requires `dpkg`, `python-gobject`, `gtk4`, `libadwaita` — all present by default on CachyOS/EndeavourOS.

### Never overwrites your files

If `~/.local/bin/foo` already exists and wasn't created by this tool, it gets renamed to `foo.bak-<timestamp>` before the new symlink is made, with a warning. This isn't theoretical caution: during development an early version nearly clobbered a hand-written launcher script of mine.

### Limitations

`.deb` only. Doesn't install system dependencies for you (it tells you what's missing). Programs that hardcode `/usr` paths, or ship systemd units or kernel modules, will not work — use [distrobox](https://github.com/89luca89/distrobox) for those. Arch-family only.

## License

MIT
