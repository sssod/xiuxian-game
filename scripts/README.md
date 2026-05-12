# Scripts

## ChatGPT Library Design Docs Sync

`scripts/sync_design_docs_chatgpt.py` 用于在本地正式设计文档包和 ChatGPT Web Library 之间做扁平化往返同步。

来源目录：

```text
docs/xiuxian_design_docs/
```

默认导出：

```bash
python3 scripts/sync_design_docs_chatgpt.py export --clean
```

输出目录：

```text
outputs/xiuxian-design-docs-chatgpt/
```

输出内容：

- 编号后的扁平 Markdown 文档，文件名保留原包内路径信息。
- `README.md`：上传和回合并说明。
- `INDEX_ChatGPT扁平索引.md`：Web Library 侧入口索引。
- `manifest.json`：本地回合并校验清单，包含原始路径和 SHA-256。

从 Web 下载修改后的 Markdown 后，先预览：

```bash
python3 scripts/sync_design_docs_chatgpt.py plan-import --input <下载目录>
```

确认后写回本地正式包：

```bash
python3 scripts/sync_design_docs_chatgpt.py import --input <下载目录>
```

导入默认会阻止覆盖“导出后本地也发生过变化”的源文件；确需覆盖时再显式加 `--allow-source-drift`。

`scripts/export_canonical_docs.py` 仅保留为兼容入口，当前会转发到上述同步脚本。
