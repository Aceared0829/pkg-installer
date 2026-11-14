# archlinuxcn 打包请求

- 入口：https://github.com/archlinuxcn/repo/issues/new/choose → 选「软件打包请求」
- 标题建议：`[package request] pkg-installer`
- 模板原文（`.github/ISSUE_TEMPLATE/10-request.md`）的字段是四个 `* 字段名`，内容直接缩进写在下面，
  **不要改成 `###` 标题**，否则和模板不匹配。

下面这一段可以整段复制：

---

```markdown
### 问题类型 / Type of issues

* 软件打包请求 / package request

----

* 简述 / Brief Description

    pkg-installer 是一个图形界面的安装器，用来在 Arch 上装别的发行版的包（.deb / .rpm / .AppImage / .flatpak），不需要 root，也不写 pacman 数据库。

    目标用户很具体：国内不少客户端（搜狗输入法、WPS、各类 Electron 应用）只发 .deb。Arch 用户装了 dpkg 之后 sudo dpkg -i 能解包，但 /var/lib/dpkg/status 是空的，装出来是个跑不起来的东西；rpm 更是直接不认。这个工具把包里自包含的那部分解出来放进 ~/.local/opt/<包名>/，链一条命令、写一个桌面条目，卸载就是删目录。

    它做的第一件事不是装，而是去官方库和 AUR 搜同名包——有原生包就亮黄条并给出可直接粘的命令，劝用户别折腾这个文件。第二件事是把 deb 的包名 / rpm 的 soname 翻译成 Arch 的包名，缺什么就列出来并附 pacman -S --needed，不认识的名字单独归类，不假装「依赖齐全」。

    GTK4 + libadwaita 的单文件 Python 前端，外面套一个 1177 行的 bash 后端，两者是严格调用关系不是两份实现。

* 主要语言和工具链 / Main Languages and Toolchains

    - 后端：Bash（bin/pkg2local）
    - 前端：Python 3 + GTK4 + libadwaita（bin/pkg-installer）
    - 运行时依赖：bash, libarchive (bsdtar), python-gobject, gtk4, libadwaita

    打包配方已经在仓库里（PKGBUILD + .SRCINFO，.SRCINFO 由 makepkg --printsrcinfo 生成），
    arch=(any)，没有编译步骤，直接把上游 tarball 里的 bin/ desktop/ 装进 /usr 即可。

* 上游链接 / Upstream Link

    - 源码：https://github.com/Aceared0829/pkg-installer
    - 发布：https://github.com/Aceared0829/pkg-installer/releases/tag/v2.2.0
    - 落地页：https://aceared0829.github.io/pkg-installer/

* 为何需要这个软件包 / Why Need This Package

    1. 中文软件生态里 deb-only 的包太多了。搜狗输入法、WPS、各类国产 Electron 客户端，官方只给 .deb。archlinuxcn 本身就在解决「中文软件在 Arch 上装不上」这个问题，这个工具是这条链路上通用的一环。
    2. 有大陆镜像的话，安装这一步会快得多。目前它只挂在 GitHub Pages 上，国内拉取不稳定。
    3. 它不写 pacman 数据库、不需要 root，和 archlinuxcn 仓库本身不冲突——装的是工具，工具再装别人的包。
```

---

## 附：如果需要参考现有 PKGBUILD

仓库根目录的 `PKGBUILD` 可以直接用，但有一处要注意：它的 `source` 指向
`$url/archive/v$pkgver.tar.gz`，而 PKGBUILD 本身就在这个 tarball 里面，
所以 **tag 内那份 PKGBUILD 的 `sha256sums` 天然滞后一个版本**（它不可能包含自己的哈希）。
AUR / 仓库打包应取 `main` 分支的 PKGBUILD 与 .SRCINFO，那份是对准当前 release 的。

v2.2.0 的 tarball sha256：`f8e27d96007321e9ca2c88d10e8aebdc1395f13ab281c08c5f410e8f2a201ecc`
