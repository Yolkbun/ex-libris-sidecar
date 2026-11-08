# Ex Libris 侧车（fanqie sidecar）

这是 [Ex Libris 藏书票](https://github.com/Yolkbun/obsidian-ex-libris) 的**可选**本机侧车：
一个无窗口的 Windows exe，只在 `127.0.0.1` 上提供 HTTP/JSON 接口，让 Obsidian 插件能够
搜索番茄小说、拉目录、解密正文、读只读书评。

> 插件本身不包含这个 exe，也不会自动下载或安装它。
> 本仓库**不提交** Obsidian 社区目录；社区插件只包含 `main.js` / `manifest.json` / `styles.css`。

## 它做什么

```
Obsidian 插件 ──HTTP(127.0.0.1, X-FQ-Token)──> fqsidecar.exe
                                                  │
                                                  ├─ 复用 vendor/fqapp 的 Rust core
                                                  │   （设备注册、Gorgon/Argus 签名、AES 解密）
                                                  └─ 访问番茄上游接口
```

- `sidecar-upstream/`：真实上游适配层（默认发布）
- `sidecar/`：零依赖的离线样章版本，用于无网自检与契约测试
- `vendor/fqapp/`：来自 [ch6vip/fqapp](https://github.com/ch6vip/fqapp) 的 GPL-3.0 源码快照
  （`c29b279`，2026-11-08），原样保留，见 `vendor/fqapp/COMMIT.txt`

## 下载 / 安装

从 [Releases](https://github.com/Yolkbun/ex-libris-sidecar/releases) 下载：

| 文件 | 用途 |
|---|---|
| `fqsidecar.exe` | 已经装好插件，只补侧车 |
| `ex-libris-full-0.1.7.zip` | 完整版：插件三件套 + `bin/fqsidecar.exe`，解压即用 |

手动放到：

```
<vault>/.obsidian/plugins/ex-libris/bin/fqsidecar.exe
```

然后 Obsidian → 设置 → Ex Libris → “重启并检查”，应显示“侧车就绪”。

## 构建

需要 Rust + GNU 链接器。最省空间的组合是 MSYS2：

```powershell
winget install --id MSYS2.MSYS2 -e
C:\msys64\usr\bin\bash.exe -lc "pacman -S --noconfirm mingw-w64-x86_64-rust mingw-w64-x86_64-gcc"
powershell -NoProfile -File scripts/build-sidecar.ps1
```

产物：`bin/fqsidecar.exe`（约 4.9 MB，单文件，无运行时 DLL）。

也可以构建零依赖的离线样章版：

```powershell
powershell -NoProfile -File scripts/build-sidecar.ps1 -Demo
```

## 运行参数

插件自动拉起：

```
fqsidecar.exe --port <p> --data-dir <abs dir> --parent-pid <obsidian pid>
```

环境变量 `FQ_TOKEN` 必须存在，之后每个请求带 `X-FQ-Token`。

| 参数 | 默认 | 说明 |
|---|---|---|
| `--provider` | fanqie | `demo` 走离线样章 |
| `--idle-ms` | 300000 | 闲置退出阈值 |
| `--probe "/api/v1/books/<id>"` | — | 调试：初始化后打印上游原始 JSON |

## 生命周期

- 端口由插件预分配，通过 `--port` 传入
- `GET /health` 就绪后插件才开始使用
- 三重退出：`POST /shutdown` / stdin EOF / 每 10s 检查父进程
- 连续 5 分钟无请求退出
- 无窗口、无托盘、不写注册表

## HTTP 契约

错误统一 `{"error":{"code":"...","message":"..."}}`。

| 方法 | 路径 |
|---|---|
| GET | `/health` |
| GET | `/search?q=&page=1&limit=20` |
| POST | `/resolve` `{url}` |
| GET | `/book/<bookId>` |
| GET | `/book/<bookId>/chapters` |
| GET | `/chapter/<chapterId>` |
| GET | `/book/<bookId>/comments?page=1` |
| POST | `/shutdown` |

## 上游映射

| 本地 | fqapi_core | 上游 |
|---|---|---|
| `/search` | `/api/v1/search` | `bookapi/search/tab` |
| `/book/<id>` | `/api/v1/books/<id>` | `bookapi/detail` |
| `/book/<id>/chapters` | `/api/v1/books/<id>/directory` | `directory/all_items` |
| `/chapter/<id>` | `/api/v1/chapters/<id>` | `reader/full` + AES 解密 |
| `/book/<id>/comments` | `/api/v1/books/<id>/comments` | `novel_comment/book`（书评） |

段评（`idea_list`）需要正文的 `item_version`，拿不到内容，所以 UI 用书评，不伪装成章评。

## 更新

番茄官方改接口/签名/加密后，现有 exe 会开始报 `UPSTREAM_TIMEOUT` / `DECRYPT_FAILED`。
处理方式：

1. 用新的 [ch6vip/fqapp](https://github.com/ch6vip/fqapp) 源码替换 `vendor/fqapp/rust` 与 `vendor/fqapp/native`；
2. `powershell -NoProfile -File scripts/build-sidecar.ps1`
3. 发新的 `sidecar-x.y.z` release，并更新插件 README/引导里的下载链接。

## 许可与免责

- 本项目：GPL-3.0-or-later，见 [`LICENSE`](LICENSE)。
- `vendor/fqapp`：ch6vip/fqapp，GPL-3.0；完整源码已随仓库提供。
- 与 ByteDance / 番茄小说、豆瓣、Obsidian、Clarivate / Ex Libris 均无关联。
- 仅用于个人学习研究，处理你有权访问的内容；不提供、不托管、不分发正文。
- 对上游接口的访问可能受服务条款与当地法律限制；使用风险由使用者承担。
