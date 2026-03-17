# Contributing to WorkTracker / 贡献指南

Thank you for your interest in contributing!
感谢你对 WorkTracker 的关注，欢迎贡献！

---

## Reporting Bugs / 报告问题

Please open a [GitHub Issue](../../issues) and include:
请在 [GitHub Issues](../../issues) 中提交，并附上：

- macOS version / macOS 版本
- Steps to reproduce / 复现步骤
- Expected vs actual behavior / 预期与实际行为

---

## Submitting a Pull Request / 提交 PR

1. Fork this repository / Fork 本仓库
2. Create a feature branch / 创建功能分支
   ```bash
   git checkout -b feat/your-feature-name
   ```
3. Make your changes / 进行修改
4. Run tests and make sure they pass / 运行测试，确保通过
   ```bash
   cd WorkTracker
   swift test
   ```
5. Commit with a clear message / 提交清晰的说明
   ```bash
   git commit -m "feat: add your feature"
   ```
6. Open a Pull Request against `main` / 向 `main` 分支发起 PR

---

## Building the Project / 编译运行

See [README.md](README.md#installation--安装) for build instructions.
编译方法见 [README.md](README.md#installation--安装)。

---

## Code Style / 代码风格

- Follow SwiftUI conventions and Apple's Human Interface Guidelines
- No additional linter is configured; keep code clean and readable
- 遵循 SwiftUI 惯例和 Apple HIG
- 无额外 lint 工具，保持代码整洁可读
