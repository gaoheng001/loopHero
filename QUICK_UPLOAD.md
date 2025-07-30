# 快速上传到 GitHub

## 前提条件

1. **安装 Git**
   - 下载：https://git-scm.com/download/win
   - 安装后重启命令行

2. **在 GitHub 创建仓库**
   - 登录 GitHub
   - 点击 "+" → "New repository"
   - 仓库名：`loop-hero-clone`
   - **不要**勾选 "Initialize with README"
   - 点击 "Create repository"

## 上传命令（复制粘贴执行）

```bash
# 1. 进入项目目录
cd "c:\Users\gaoheng的gpd\Documents\loopHero"

# 2. 初始化 Git
git init

# 3. 添加所有文件
git add .

# 4. 提交文件
git commit -m "Initial commit: Loop Hero clone project"

# 5. 连接远程仓库（替换 YOUR_USERNAME）
git remote add origin https://github.com/YOUR_USERNAME/loop-hero-clone.git

# 6. 推送到 GitHub
git branch -M main
git push -u origin main
```

## 重要提醒

- 将 `YOUR_USERNAME` 替换为你的 GitHub 用户名
- 推送时使用 Personal Access Token 作为密码
- 确保 GitHub 仓库已创建且为空

## 自动化脚本

项目中包含两个自动化脚本：
- `upload_to_github.ps1` - PowerShell 脚本
- `upload_to_github.bat` - 批处理脚本

运行方式：
```powershell
# PowerShell
.\upload_to_github.ps1

# 或双击
upload_to_github.bat
```