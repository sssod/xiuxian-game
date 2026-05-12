# ChatGPT Library 同步与扁平导入导出规范

适用范围：`docs/xiuxian_design_docs` 与 ChatGPT Web Library 之间的文档导出、Web 端修订和本地回合并。

## 1. 当前定位

本文负责说明正式设计文档包如何转换为 ChatGPT Library 可索引的扁平版本，以及 Web 端修改后如何安全写回本地多级目录。

本流程只服务当前正式设计文档包。历史参考文档、包外 inbox 材料和旧 canonical 文档不进入默认导出，也不通过此流程重新变成当前设计依据。

## 2. 使用方式

1. 本地上传前运行 `python3 scripts/sync_design_docs_chatgpt.py export --clean` 生成扁平导出包。
2. 将导出目录中的编号 Markdown 文档和 `INDEX_ChatGPT扁平索引.md` 上传到 ChatGPT Library。
3. Web 端修订时优先修改对应编号文档，避免只修改导出 README 或扁平索引。
4. 下载 Web 端修改后的 Markdown 到本地目录。
5. 先运行 `python3 scripts/sync_design_docs_chatgpt.py plan-import --input <下载目录>` 查看写回计划。
6. 确认后运行 `python3 scripts/sync_design_docs_chatgpt.py import --input <下载目录>` 写回本地正式包。

## 3. 导出包结构

默认输出目录为 `outputs/xiuxian-design-docs-chatgpt/`。

| 文件 | 用途 |
| --- | --- |
| `README.md` | 面向上传者说明导出时间、来源、上传和回合并方式 |
| `INDEX_ChatGPT扁平索引.md` | 面向 Web Library 的扁平入口，恢复原目录结构和主题分组 |
| `manifest.json` | 本地脚本校验用清单，记录源路径、导出文件名和源文件 SHA-256 |
| `NNN__*.md` | 从正式包导出的实际设计文档 |

编号文档的文件名由原包内路径转换而来，例如：

```text
02_系统设计/01_流程设计/01_单人游戏与多人共玩流程.md
```

导出后会变成类似：

```text
004__02_系统设计__01_流程设计__01_单人游戏与多人共玩流程.md
```

## 4. Metadata 规则

每个编号 Markdown 文件顶部带有脚本生成的 YAML metadata：

```yaml
---
xiuxian_export: "xiuxian_design_docs_chatgpt_flat_v1"
export_id: "004"
source_path: "docs/xiuxian_design_docs/02_系统设计/01_流程设计/01_单人游戏与多人共玩流程.md"
package_path: "02_系统设计/01_流程设计/01_单人游戏与多人共玩流程.md"
source_sha256: "..."
exported_at: "..."
---
```

这些字段用于回合并时定位本地源文件并判断本地源文件是否已在导出后变动。Web 端修改正文时应尽量保留该 metadata。

若 Web 端下载结果丢失 metadata，脚本会尝试使用同目录 `manifest.json`，或默认导出目录中的 `manifest.json` 按文件名恢复映射。文件名和 manifest 都不可用时，该文件需要人工合并。

## 5. 回合并规则

导入命令只处理能映射到 `docs/xiuxian_design_docs` 内源文件的编号 Markdown 文件。生成用的 `README.md` 和 `INDEX_ChatGPT扁平索引.md` 不会作为设计正文写回。

导入计划会把文件分为以下状态：

| 状态 | 含义 | 默认处理 |
| --- | --- | --- |
| `unchanged` | 下载文件与本地源文件一致 | 不写回 |
| `changed` | 下载文件变化，且本地源文件未在导出后变化 | 可写回 |
| `source_drift` | 下载文件变化，但本地源文件也在导出后变化 | 阻止写回，需人工判断 |
| `blocked` | 源文件缺失或路径不合法 | 阻止写回 |

确需覆盖 `source_drift` 文件时，可显式使用 `--allow-source-drift`。该参数代表放弃脚本的本地变更保护，应先确认本地变更不需要保留。

## 6. Web 端修订边界

1. Web 端可以修订正式包内的设计正文、待裁决项、维护记录和包内引用。
2. Web 端不应把新设计结论只写在导出 README 或扁平索引中；稳定结论必须落到对应主题文档。
3. 新增主题文档时，应先在 Web 端写明建议路径和归属；下载后由本地人工创建正式文件并更新包内索引。
4. 包外历史材料只能作为恢复线索。采纳内容必须改写进正式包内，不能只保留外链或旧路径。

## 7. 包内关联文档

| 文档 | 关系 |
| --- | --- |
| `INDEX_总索引.md` | 承接：提供正式包主题入口和文档清单 |
| `文档模板与包内引用规范.md` | 唯一信源：提供正式包文档模板、引用格式和治理细则 |
| `../README.md` | 承接：面向读者说明正式包用途和当前维护方式 |

## 8. 维护记录

2026-05-12：新增 ChatGPT Library 扁平导出与本地回合并规范，配套 `scripts/sync_design_docs_chatgpt.py`。
