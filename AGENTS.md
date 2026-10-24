# AGENTS.md — pi agent 专属空间

本仓库是 **pi agent 的专属工作空间**（workspace root：`D:\AI\pi-s`）。

任何在此目录下工作的 agent / 协作者，开始任务前先读完本文件。

---

## 1. 空间定位

- **目标**：围绕上游项目 `pi`（<https://github.com/earendil-works/pi>）做源码研读、实验与文档沉淀。
- **原则**：上游源码 **只读参考**；本空间只入库自己的产物（文档、配置、实验代码）。
- **边界**：不在本空间内发布或修改上游代码；需要改动上游时，先在下游验证，再单独向上游提 PR。

## 2. 目录约定

| 路径 | 用途 | 入库策略 |
| --- | --- | --- |
| `AGENTS.md` | 本文件：空间规则与工作约定 | ✅ 入库 |
| `README.md` | 仓库说明；**本仓库唯一的 README** | ✅ 入库 |
| `pi.cmd` `pi.ps1` `pi` | 本地 pi 启动器（cmd / PowerShell / Git Bash），从源码直跑 | ✅ 入库 |
| `.gitattributes` | 行尾约定：`*.cmd` 保持 CRLF，根 `pi` 与 `workbuddy-proxy.sh` 保持 LF | ✅ 入库 |
| `.agents/` | agent 运行期状态：临时脚本、草稿、缓存、任务中间产物 | 仅 `.gitkeep`，运行期内容忽略 |
| `docs/` | 正式文档：调研笔记、架构分析、实验记录、决策记录 | 仅 `.gitkeep`，文档入库 |
| `refs/` | 外部参考项目容器 | 仅 `.gitkeep` |
| `refs/pi/` | 上游 `pi` 源码，以 **git submodule** 形式接入 | 父仓库只记录 commit 指针 |
| `refs/workbuddy-openai-proxy/` | WorkBuddy/CodeBuddy 本地 OpenAI/Anthropic 兼容反代源码，以 **git submodule** 形式接入（零依赖 `node server.mjs`） | 父仓库只记录 commit 指针 |
| `workbuddy-proxy.cmd` | WorkBuddy 反代启动器（start/stop/restart/login/status/console/ask），委派给 `refs/workbuddy-openai-proxy/` | ✅ 入库 |
| `workbuddy-proxy.sh` | 同上，Linux / macOS（bash）版本：后台用 `nohup`，控制台用 `xdg-open`，行尾保持 LF | ✅ 入库 |
| `pi-chinese/` | 自研 pi 扩展：**强制全程简体中文**（通过 `before_agent_start` 钩子注入系统提示词），以 **git submodule** 形式接入（远程 `git@github.com:falling-ts/pi-chinese.git`） | 父仓库只记录 commit 指针 |
| `pi-working/` | 自研 pi 扩展：**状态指示器中文化**（Working/请求中/响应中/执行中，`PI_WORKING_LANG` 切英文），以 **git submodule** 形式接入（远程 `git@github.com:falling-ts/pi-working.git`） | 父仓库只记录 commit 指针 |
| `pi-start-command/` | 自研 pi 扩展：**会话开始前运行配置的启动命令**（`PI_START_COMMAND`），以 **git submodule** 形式接入（远程 `git@github.com:falling-ts/pi-start-command.git`） | 父仓库只记录 commit 指针 |
| `.gitignore` | 忽略规则（构建产物、环境密钥、编辑器/系统垃圾、agent 运行期状态） | ✅ 入库 |
| `.gitmodules` | 子项目（submodule）声明：路径、URL、跟踪分支 | ✅ 入库 |

## 3. 硬性规则

1. **不要修改 `refs/pi/` 的工作区**，也不要在这个子模块里提交。它是上游镜像，需要试验时把代码复制到 `.agents/scratch/` 或 `docs/` 下再改。
2. **改动子模块指针必须显式提交**：`git -C refs/pi fetch` 后父仓库会看到 `refs/pi` 有新 commit，只有在确认新 commit 可用后才 `git add refs/pi` 并在提交信息里写明上游 commit 与原因。
3. **不要在父仓库里新增重名的顶层目录**；新增顶层内容前先更新本文件的目录表。
4. **README 只在仓库根目录存在**（`README.md`）：子目录一律不新建 README，目录用途统一写在根 `README.md` 与本文件里；空目录用 `.gitkeep` 占位。
5. 文档放在 `docs/`，一个主题一个文件，命名用 `短横线小写.md`（例：`pi-architecture.md`）。
6. 提交信息用 `type(scope): summary`，例：`docs(pi): 记录 session 生命周期`。
7. 临时产物写入 `.agents/tmp/`（已被忽略），不要污染工作区状态。

## 4. 新系统初始化

在**全新系统**上拉取本仓库后，按顺序做完以下步骤，即可得到与现有环境一致的可用状态。
除注明外，命令都在仓库根目录执行。

| # | 步骤 | 作用 |
| --- | --- | --- |
| 4.1 | 拉取子模块 | 取得 `refs/pi` 上游源码与两个扩展子模块 |
| 4.2 | 重建本地 pi 工作副本 | 让根目录启动器能从源码直跑 pi |
| 4.3 | 加入用户 PATH | 任意目录、任意 shell 裸 `pi` 可用 |
| 4.4 | 软链自研扩展 `pi-chinese` | pi 全局强制全程简体中文 |
| 4.5 | 软链自研扩展 `pi-working` | 状态指示器中文化（Working/请求中/响应中/执行中） |
| 4.6 | 软链自研扩展 `pi-start-command` | 会话开始前运行 `PI_START_COMMAND` 配置的启动命令 |
| 4.7 | 安装扩展包 `pi-boop` | 每轮结束响一声提示 |
| 4.8 | （可选）WorkBuddy 反代快捷方式 | 开始菜单一键启动反代 |

### 4.1 拉取子模块

```powershell
git submodule update --init --recursive
```

### 4.2 重建本地 pi 工作副本

`.agents/scratch/` 不入库，换机器或清理后必须重做：

```powershell
git submodule update --init refs/pi
robocopy refs\pi .agents\scratch\pi /E /XD .git    # 退出码 0-7 均视为成功
cd .agents\scratch\pi
npm.cmd ci --ignore-scripts                        # 必须用 npm.cmd，见下
npm.cmd run hydrate:model-data                     # 联网生成 providers/data（上游 gitignore 的生成物）
```

两个坑：

- **必须用 `npm.cmd` 而不是 `npm`**：本机继承的 `npm_*` 环境变量会让 `npm`（`npm.ps1`）走错路径并报 `Unknown command: "pm"`。
- **`hydrate:model-data` 必不可少且需要联网**：上游把 `packages/ai/src/providers/data/` 写进了 `.gitignore`，它是生成物；缺它时任何 `pi` 调用都会以 `ERR_MODULE_NOT_FOUND: .../providers/data/.manifest.json` 失败。
- **`hydrate:model-data` 要走代理，但 `HTTPS_PROXY` 对 Node 内置 `fetch` 无效**：Node 22 的 undici 默认**不读** `HTTP_PROXY` / `HTTPS_PROXY`（`npm` 自己读，所以 `npm.cmd ci` 只设这两个就够了）。直连 `radius.pi.dev` 会间歇性 `UND_ERR_CONNECT_TIMEOUT`，必须再加 `NODE_USE_ENV_PROXY=1`：
  ```powershell
  $env:HTTP_PROXY="http://127.0.0.1:7890"; $env:HTTPS_PROXY="http://127.0.0.1:7890"; $env:NODE_USE_ENV_PROXY="1"
  npm.cmd run hydrate:model-data
  ```

### 4.3 加入用户 PATH

仓库根 `D:\AI\pi-s` 需加入**用户级** PATH（`HKCU\Environment`，**不要动系统 PATH**），
这样任意目录、任意 shell（cmd / pwsh 命中 `pi.cmd`，Git Bash 命中 `pi`）裸命令 `pi` 都可用。
换机器后需重新添加该条目；旧终端里找不到 `pi` 时重开终端即可。

### 4.4 软链自研扩展 pi-chinese

pi 启动时扫描 `~/.pi/agent/extensions/` 自动加载扩展；把仓库里的 `pi-chinese/` 软链进去即可
（无需构建，pi 通过 `jiti` 直接加载 `.ts`）：

```powershell
New-Item -ItemType SymbolicLink `
  -Path "$env:USERPROFILE\.pi\agent\extensions\pi-chinese" `
  -Target "D:\AI\pi-s\pi-chinese"
```

该扩展经 `before_agent_start` 钩子把"全程简体中文（含思考与中间输出）"写入系统提示词，
对**之后启动的会话**生效（当前会话不受影响）。若只想在单个工程生效，改为软链到 `<工程>/.pi/extensions/pi-chinese`。

### 4.5 软链自研扩展 pi-working

同样软链即可（pi 通过 `jiti` 直读 `.ts`，无需构建）：

```powershell
New-Item -ItemType SymbolicLink `
  -Path "$env:USERPROFILE\.pi\agent\extensions\pi-working" `
  -Target "D:\AI\pi-s\pi-working"
```

该扩展把运行时的状态指示器翻译为中文：`工作中` / `请求中`（已请求模型、等首个 token）/ `响应中`
（收到首个 token）/ `执行中`（工具、命令等非模型工作）；环境变量 `PI_WORKING_LANG=en` 可切英文（默认中文）。

### 4.6 软链自研扩展 pi-start-command

同样软链即可（pi 通过 `jiti` 直读 `.ts`，无需构建）：

```powershell
New-Item -ItemType SymbolicLink `
  -Path "$env:USERPROFILE\.pi\agent\extensions\pi-start-command" `
  -Target "D:\AI\pi-s\pi-start-command"
```

该扩展在每次**用户发起会话**（`before_agent_start` 且 `messageType === "user"`）时先运行
`PI_START_COMMAND` 配置的命令行，完成后 pi 才把 prompt 发给模型；命令失败（非零退出/超时）
只弹通知、不阻断会话。环境变量：`PI_START_COMMAND`（未设则插件完全静默）、
`PI_START_COMMAND_TIMEOUT_MS`（默认 10000）、`PI_START_COMMAND_QUIET=1`（成功不弹通知）。

### 4.7 安装扩展包 pi-boop

```powershell
# 安装 / 更新需走代理：npm 默认未配代理，直连 registry 会超时
$env:HTTPS_PROXY="http://127.0.0.1:7890"; $env:HTTP_PROXY="http://127.0.0.1:7890"
pi install npm:pi-boop
```

`pi-boop` 在 `agent_settled` 且 `ctx.isIdle()` 时响一声（默认写 stderr 的 ASCII BEL / 终端 bell），
提醒本轮结束、等待输入。零依赖（`peerDependencies: @earendil-works/pi-coding-agent`），
装入 `~/.pi/agent/npm/node_modules/pi-boop`，并记入 `~/.pi/agent/settings.json` 的 `packages`。

- 换自定义音效：`PI_BOOP_SOUND=<音频文件>` 或 `--boop-sound`
- 关闭：`PI_BOOP_DISABLE=1` 或 `--boop-off`
- 立即试听：pi 内 `/boop`

注意：**安装需要代理，但运行 pi 时不要给代理**，否则本地 WorkBuddy 反代请求（`127.0.0.1:8788`）
会被错误转发而报 `Connection error`。

### 4.8 （可选）WorkBuddy 反代开始菜单快捷方式

仿 `comfy-server.lnk` 平铺单条目 `WorkBuddy Proxy.lnk`（放在开始菜单 Programs 根目录，双击启动反代）。
该快捷方式不入库、手动创建。

## 5. 常用命令

```powershell
# 跟进上游 main 分支最新提交
git submodule update --remote refs/pi
git add refs/pi && git commit -m "chore(refs): bump pi to <sha>"

# 只做事后核对，不改变指针
git -C refs/pi fetch origin
git -C refs/pi log --oneline --decorate -10 origin/main

# 查看当前记录的指针
git submodule status

# 运行本地 pi（源码直跑，启动器见根目录 pi.cmd / pi.ps1 / pi）
# 用户 PATH 已含 D:\AI\pi-s，故任意目录、任意 shell 都是裸命令：
pi --version       # cmd / pwsh 命中 pi.cmd（纯批处理直调 node），Git Bash 命中 pi
```

## 6. 当前状态

- 本空间远程仓库：`origin` → `git@github.com:falling-ts/pi-s.git`（分支 `main`）
- 子模块：`refs/pi` → <https://github.com/earendil-works/pi>（跟踪分支 `main`）
- 子模块：`refs/workbuddy-openai-proxy` → <https://github.com/yuan240324/workbuddy-openai-proxy.git>（跟踪分支 `main`）：把 WorkBuddy/CodeBuddy 额度包装成本机 OpenAI/Anthropic 兼容接口（默认 `http://127.0.0.1:8788/v1`）；根目录 `workbuddy-proxy.cmd`（Windows）与 `workbuddy-proxy.sh`（Linux / macOS）管理其启停
- 子模块：`pi-chinese` → <https://github.com/falling-ts/pi-chinese.git>（跟踪分支 `main`）：自研 pi 扩展，在每次请求前经 `before_agent_start` 钩子把"全程简体中文（含思考与中间输出）"写入系统提示词（初始化软链见 4.4）。npm: `@falling-ts/pi-chinese@1.4.0`，peer `>=1.4.0`
- 子模块：`pi-working` → <https://github.com/falling-ts/pi-working.git>（跟踪分支 `main`）：自研 pi 扩展，把运行时状态指示器翻译为中文（工作中/请求中/响应中/执行中），`PI_WORKING_LANG=en` 切英文（初始化软链见 4.5）。npm: `@falling-ts/pi-working@1.2.0`，peer `>=1.4.0`
- 子模块：`pi-start-command` → <https://github.com/falling-ts/pi-start-command.git>（跟踪分支 `main`）：自研 pi 扩展，在用户发起会话前运行 `PI_START_COMMAND` 配置的启动命令，失败只通知不阻断（初始化软链见 4.6）。npm: `@falling-ts/pi-start-command@1.2.0`，peer `>=1.4.0`
- 本地 pi 启动器：根目录 `pi.cmd`（纯批处理，直调 `node`）/ `pi.ps1`（PowerShell 原生入口）/ `pi`（Git Bash），运行的是 `.agents/scratch/pi` 这份工作副本（上游 `f321e5bdd`，v1.4.0+59 提交、包版本 1.4.0 的复制）；三者共用 `.agents/scratch/node-compile-cache`（V8 compile cache，不入库，可随时删）
- 仓库说明见 [`README.md`](README.md)（子目录不含 README）
