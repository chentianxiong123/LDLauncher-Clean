# GitHub 推送指南

本文档说明如何将 LDLauncher-Clean 项目推送到 GitHub。

## 目录

1. [准备工作](#准备工作)
2. [创建 GitHub 仓库](#创建-github-仓库)
3. [推送到 GitHub](#推送到-github)
4. [发布 Release](#发布-release)
5. [常见问题](#常见问题)

---

## 准备工作

### 1. 安装 Git

```bash
# 检查 Git 是否安装
git --version

# 如未安装，从 https://git-scm.com/download/win 下载并安装
```

### 2. 配置 Git 用户信息

```bash
# 设置用户名
git config --global user.name "Your Name"

# 设置邮箱
git config --global user.email "your@email.com"

# 验证配置
git config --global --list
```

### 3. 配置 SSH 密钥（推荐）

```bash
# 生成 SSH 密钥
ssh-keygen -t ed25519 -C "your@email.com"

# 查看公钥
cat ~/.ssh/id_ed25519.pub

# 复制输出内容
```

### 4. 添加 SSH 密钥到 GitHub

1. 登录 GitHub
2. 点击头像 → Settings
3. SSH and GPG keys → New SSH key
4. 粘贴公钥内容
5. 点击 Add SSH key

### 5. 测试 SSH 连接

```bash
ssh -T git@github.com
# 应该看到：Hi username! You've successfully authenticated...
```

---

## 创建 GitHub 仓库

### 方法 1：通过 GitHub 网页创建

1. 登录 GitHub：https://github.com
2. 点击右上角 **+** → **New repository**
3. 填写仓库信息：
   - Repository name: `LDLauncher-Clean`
   - Description: `雷电模拟器 9 启动器去广告版 - 纯净桌面，无广告干扰`
   - Public/Private: 根据需求选择（建议 Public）
   - 不要勾选 "Add a README file"
   - 不要勾选 "Add a .gitignore"
   - 不要勾选 "Choose a license"
4. 点击 **Create repository**

### 方法 2：使用 GitHub CLI

```bash
# 安装 GitHub CLI（如未安装）
# 从 https://cli.github.com/ 下载

# 创建仓库
gh repo create LDLauncher-Clean --public --description "雷电模拟器 9 启动器去广告版"
```

---

## 推送到 GitHub

### 1. 进入项目目录

```bash
cd C:\Users\a1\AppData\Local\Temp\LDLauncher-Clean
```

### 2. 添加远程仓库

```bash
# 使用 SSH（推荐）
git remote add origin git@github.com:your-username/LDLauncher-Clean.git

# 或使用 HTTPS
git remote add origin https://github.com/your-username/LDLauncher-Clean.git

# 验证远程仓库
git remote -v
```

### 3. 推送代码

```bash
# 推送 master 分支
git push -u origin master

# 或推送 main 分支（如果已重命名）
git push -u origin main
```

### 4. 验证推送

打开浏览器访问：https://github.com/your-username/LDLauncher-Clean

---

## 发布 Release

### 1. 创建标签

```bash
# 创建标签
git tag -a v1.0.0 -m "v1.0.0: 首个稳定版本"

# 推送标签
git push origin v1.0.0
```

### 2. 在 GitHub 创建 Release

1. 访问仓库页面
2. 点击右侧 **Releases** → **Draft a new release**
3. 选择标签：`v1.0.0`
4. 填写 Release 信息：
   - Release title: `v1.0.0`
   - Description: 
     ```
     ## 新功能
     - 移除所有广告组件
     - 提供一键安装脚本
     - 完整的技术文档
     
     ## 修复
     - 无
     
     ## 已知问题
     - 无
     ```
5. 添加发布说明
6. 点击 **Publish release**

### 3. 上传 APK 文件

1. 在 Release 页面，点击 **Attach binaries**
2. 上传以下文件：
   - `LDLauncher-Clean-1.0.apk`
   - `install.bat`（可选）
3. 等待上传完成

### 4. Release 页面示例

```
📦 Release v1.0.0
📅 2026-10-12

## 新功能
- 移除所有广告组件
- 提供一键安装脚本
- 完整的技术文档

## 下载
- LDLauncher-Clean-1.0.apk (5.0 MB)
- install.bat (2.4 KB)

## 安装说明
双击 install.bat 即可一键安装
```

---

## 常见问题

### 问题 1：推送时提示权限不足

**错误信息**：
```
Permission denied (publickey).
```

**解决方案**：
```bash
# 1. 检查 SSH 配置
ssh -T git@github.com

# 2. 如失败，检查密钥是否正确添加
ls -la ~/.ssh/
cat ~/.ssh/id_ed25519.pub

# 3. 重新添加密钥到 GitHub
```

### 问题 2：仓库已存在同名文件

**错误信息**：
```
fatal: the remote already exists
```

**解决方案**：
```bash
# 1. 检查远程仓库
git remote -v

# 2. 删除现有远程仓库
git remote remove origin

# 3. 重新添加
git remote add origin git@github.com:your-username/LDLauncher-Clean.git

# 4. 重新推送
git push -u origin master
```

### 问题 3：APK 文件太大被拒绝

**错误信息**：
```
error: RPC failed; curl 56 GnuTLS recv error
```

**解决方案**：
```bash
# 1. 使用 Git LFS 管理大文件
git lfs install
git lfs track "*.apk"
git add .gitattributes
git add release/*.apk
git commit -m "Add APK using LFS"
git push origin master

# 2. 或分拆提交
git rm --cached release/*.apk
git commit -m "Remove APK"
git push origin master
git add release/*.apk
git commit -m "Add APK"
git push origin master
```

### 问题 4：如何修改默认分支为 main

```bash
# 1. 重命名本地分支
git branch -m master main

# 2. 推送新分支
git push -u origin main

# 3. 删除旧分支（可选）
git push origin --delete master

# 4. 在 GitHub 设置中更改默认分支
# Settings → General → Default branch → main → Change
```

---

## 后续维护

### 更新版本

```bash
# 1. 修改代码
# ...

# 2. 提交更改
git add .
git commit -m "v1.0.1: 修复安装脚本问题"

# 3. 创建新标签
git tag -a v1.0.1 -m "v1.0.1: 修复安装脚本问题"

# 4. 推送
git push origin main
git push origin v1.0.1
```

### 处理 Issue

1. 访问仓库 Issues 页面
2. 查看用户报告的问题
3. 标记问题（bug, feature request, question）
4. 回复并解决问题
5. 关闭已解决的问题

### 接受贡献

1. 用户 Fork 仓库
2. 用户提交 Pull Request
3. 审查代码
4. 合并到主分支
5. 更新版本和文档

---

## 完整推送流程示例

```bash
# 1. 配置用户信息
git config --global user.name "Your Name"
git config --global user.email "your@email.com"

# 2. 进入项目目录
cd C:\Users\a1\AppData\Local\Temp\LDLauncher-Clean

# 3. 添加远程仓库
git remote add origin git@github.com:your-username/LDLauncher-Clean.git

# 4. 推送代码
git push -u origin master

# 5. 创建标签
git tag -a v1.0.0 -m "v1.0.0: 首个稳定版本"
git push origin v1.0.0

# 6. 在 GitHub 网页创建 Release
# 访问：https://github.com/your-username/LDLauncher-Clean/releases
```

---

## 检查清单

推送前检查：

- [ ] Git 已安装并配置
- [ ] SSH 密钥已配置并添加到 GitHub
- [ ] GitHub 仓库已创建
- [ ] 本地代码已提交
- [ ] APK 文件已包含在仓库中
- [ ] README 文档完整
- [ ] 所有脚本可运行

---

**文档版本**：1.0.0  
**最后更新**：2026-10-12  
**预计时间**：5-10 分钟完成推送