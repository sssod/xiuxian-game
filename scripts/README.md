# Scripts

## Export Canonical Docs

导出 `docs/index.md` 中“当前 canonical 文档”表列出的正式文档，用于导入 Notion、ChatGPT Library 或其他知识库。
`docs/index.md` 中“已归档参考”的文档不会导出。

默认导出：

```bash
python3 scripts/export_canonical_docs.py
```

输出目录：

```text
outputs/canonical-docs-export/
```

输出内容：

- 编号后的独立 Markdown 文档。
- `README.md`：简单导入索引。
- `manifest.json`：脚本化校验用清单，包含原始路径和 SHA-256。

常用参数：

```bash
python3 scripts/export_canonical_docs.py --output outputs/notion-import --clean
python3 scripts/export_canonical_docs.py --output outputs/chatgpt-library --clean
```

`--clean` 只会清理空目录或此前由该脚本生成过的目录。
