# Xiuxian Main UI Stage Initializer v0.9

这是一个 Figma 插件草案，用于批量创建“主界面阶段状态”的低保真骨架页面。

## 用途

- 避免首次创建页面时完全依赖长 Prompt 或 Figma MCP，降低截断和遗漏风险。
- 创建 3 个页面：
  - `UI_MainFrame_Rebuild_v0.9`
  - `UI_MainFrame_Components_v0.9`
  - `UI_MainFrame_Flows_v0.9`
- 在主页面生成 6 个 1920×1080 状态 Frame。
- 使用纯矩形与文本表达布局，不创建最终视觉。
- 不写入当前既有页面；运行后会新建页面。

## 安装方式

1. 在 Figma 中打开插件管理。
2. 选择 `Development` / `Import plugin from manifest...`。
3. 选择本目录中的 `manifest.json`。
4. 运行插件。

## 注意

- 本插件是初始化骨架，不是最终 UI。
- 中文字体优先尝试 `Noto Sans SC`，若不可用会退回 `Inter`。
- 若已有同名页面，插件会继续创建新页面；建议运行前手动清理旧草稿或运行后重命名。
- 可运行后在 Figma 中手动替换顶部冻结栏与底部左下入口为现有已审核组件。
