# archlinuxcn 打包请求 —— 已提交为 PR #5019

- PR：https://github.com/archlinuxcn/repo/pull/5019
- 标题：`addpkg: pkg-installer`
- 来源分支：`Aceared0829:addpkg-pkg-installer` → `archlinuxcn:master`
- 内容：`archlinuxcn/pkg-installer/{PKGBUILD,lilac.yaml}`（2 个文件，+53 行）

## 这里的写法与原先的猜测不同

原先的计划是「开一个 issue，照 `10-request.md` 模板填四个字段」。实际查了仓库才发现：
**archlinuxcn 的新包是直接开 PR 交 PKGBUILD + lilac.yaml，不是开 issue。**
仓库里 6 个 ISSE_TEMPLATE 分别是 request / out-of-date / orphaning / official / other / error，
其中 `10-request.md` 是给「希望别人帮你打包」用的；自己把包打好了，走 PR。
证据：近 30 个 PR 里有 #5016 addpkg: auv、#5013 addpkg: qui、#5012 addpkg: alltap，
合并后直接在 `archlinuxcn/<pkgname>/` 下出现 PKGBUILD 与 lilac.yaml（参考已合并的 #4964）。

## 目录约定

```
archlinuxcn/pkg-installer/PKGBUILD
archlinuxcn/pkg-installer/lilac.yaml
```

`.SRCINFO` **不要放**——仓库里没有这个文件，lilac 构建时自己生成。

## lilac.yaml 的写法依据

```yaml
maintainers:
  - github: Aceared0829
    email: zzn1982638980@gmail.com

pre_build_script: |
  update_pkgver_and_pkgrel(_G.newver.lstrip('v'))
  run_protected(['updpkgsums'])

post_build_script: |
  git_pkgbuild_commit()

update_on:
  - source: github
    github: Aceared0829/pkg-installer
    use_latest_release: true
    prefix: v

build_prefix: extra-x86_64
```

- `maintainers` 是 schema 里唯一必填字段（`required: [maintainers]`），见仓库根的 `lilac-yaml-schema.yaml`。
- `updpkgsums` 必须跑：release tarball 的 sha256 每次都变，不重算会在下一次自动更新时校验失败。
  参照 `archlinuxcn/opendrop/lilac.py` 与 `archlinuxcn/tome4/lilac.py` 的 `run_cmd(['updpkgsums'])`。
- `build_prefix` 只能是 schema 里的枚举值之一，脚本类包用 `extra-x86_64`。

## 已做的验证

1. `PKGBUILD` 与 `lilac.yaml` 都按仓库根的 schema / pre-commit 规则检查过。
2. 在本地跑了完整的 `./pre-commit --all`（仓库自带的 CI 脚本，2,534 行输出，exit=0），
   `archlinuxcn/pkg-installer/PKGBUILD` 在 1833 行被检查且无报错。
3. `makepkg -f --nodeps` 从 v2.2.0 tarball 实际构建成功：
   `pkg-installer-2.2.0-1-any.pkg.tar.zst`，65,631 字节，含 7 个文件。
4. 在隔离 pacman root 里装过，`pacman -Q pkg-installer` → `2.2.0-1`。

## 现在的状态

- PR 已开，`mergeable: true`。
- Actions 显示 `action_required`：这是**首次贡献者的 workflow 审批门**，不是构建失败。
  上游 `Packaging consistency check` 的 run 43552852212 在等维护者点「Approve and run」。
  因为 CI 没跑，也就不可能出结论——这一条只能等，没法自己推。

## 如果维护者要求改动，可能要处理的两点

1. **`arch=('any')`**。脚本类包是 `any`，但仓库里也有脚本包写具体架构；
   如果被要求改成 `x86_64`，改 `arch` 一行即可，`package()` 不用动。
2. **`source` 用 tarball 而不是 `git+`**。tarball 有固定 sha256 可复核；
   如果用 `git+...#tag=v$pkgver` 配 `sha256sums=('SKIP')` 也能构建，但可复核性差一点。
   仓库里两种都有（86box 用 `git+`）。
