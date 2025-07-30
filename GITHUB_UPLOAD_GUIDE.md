# GitHub 上传指南

## 前置要求

### 1. 安装 Git

**方法一：从官网下载**
1. 访问 [Git官网](https://git-scm.com/download/win)
2. 下载适合Windows的Git安装包
3. 运行安装程序，使用默认设置即可
4. 安装完成后重启命令行或PowerShell

**方法二：使用包管理器**
```powershell
# 如果已安装 Chocolatey
choco install git

# 如果已安装 Winget
winget install Git.Git
```

### 2. 配置 Git（首次使用）

```bash
# 设置用户名和邮箱
git config --global user.name "你的用户名"
git config --global user.email "你的邮箱@example.com"
```

### 3. 创建 GitHub 仓库

1. 登录 [GitHub](https://github.com)
2. 点击右上角的 "+" 按钮
3. 选择 "New repository"
4. 填写仓库信息：
   - Repository name: `loop-hero-clone`
   - Description: `A Loop Hero inspired game built with Godot 4.4`
   - 选择 Public 或 Private
   - **不要**勾选 "Initialize this repository with a README"
5. 点击 "Create repository"

## 上传步骤

### 1. 初始化本地仓库

在项目目录中打开命令行，执行：

```bash
# 进入项目目录
cd "c:\Users\gaoheng的gpd\Documents\loopHero"

# 初始化 Git 仓库
git init
```

### 2. 创建 .gitignore 文件

```bash
# 创建 .gitignore 文件（排除不需要上传的文件）
echo "# Godot files" > .gitignore
echo ".godot/" >> .gitignore
echo "*.tmp" >> .gitignore
echo "*.import" >> .gitignore
echo "export_presets.cfg" >> .gitignore
echo "" >> .gitignore
echo "# OS files" >> .gitignore
echo ".DS_Store" >> .gitignore
echo "Thumbs.db" >> .gitignore
echo "" >> .gitignore
echo "# IDE files" >> .gitignore
echo ".vscode/" >> .gitignore
echo ".idea/" >> .gitignore
```

### 3. 添加文件到仓库

```bash
# 添加所有文件
git add .

# 提交文件
git commit -m "Initial commit: Loop Hero clone project setup

- Core game managers implemented
- Basic UI and game loop
- Card system with database
- Hero management system
- Battle system
- Complete project documentation"
```

### 4. 连接远程仓库

```bash
# 添加远程仓库（替换为你的GitHub用户名）
git remote add origin https://github.com/你的用户名/loop-hero-clone.git

# 设置主分支
git branch -M main
```

### 5. 推送到 GitHub

```bash
# 推送到远程仓库
git push -u origin main
```

## 完整命令脚本

将以下命令复制到命令行中逐行执行：

```bash
# 1. 进入项目目录
cd "c:\Users\gaoheng的gpd\Documents\loopHero"

# 2. 初始化仓库
git init

# 3. 创建 .gitignore
echo "# Godot files" > .gitignore
echo ".godot/" >> .gitignore
echo "*.tmp" >> .gitignore
echo "*.import" >> .gitignore
echo "export_presets.cfg" >> .gitignore
echo "" >> .gitignore
echo "# OS files" >> .gitignore
echo ".DS_Store" >> .gitignore
echo "Thumbs.db" >> .gitignore

# 4. 添加文件
git add .

# 5. 提交
git commit -m "Initial commit: Loop Hero clone project"

# 6. 添加远程仓库（记得替换用户名）
git remote add origin https://github.com/你的用户名/loop-hero-clone.git

# 7. 推送
git branch -M main
git push -u origin main
```

## 后续更新

当你修改了代码后，使用以下命令更新GitHub仓库：

```bash
# 添加修改的文件
git add .

# 提交修改
git commit -m "描述你的修改内容"

# 推送到GitHub
git push
```

## 常见问题

### 1. 认证问题

如果推送时要求输入用户名和密码：
- 用户名：你的GitHub用户名
- 密码：使用Personal Access Token（不是GitHub密码）

**创建Personal Access Token：**
1. GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Generate new token → 选择适当的权限（至少需要repo权限）
3. 复制生成的token作为密码使用

### 2. 推送失败

如果出现推送失败，可能是因为远程仓库有内容：

```bash
# 强制推送（谨慎使用）
git push -f origin main
```

### 3. 文件太大

GitHub单个文件限制100MB，如果有大文件：
- 将大文件添加到.gitignore
- 或使用Git LFS处理大文件

## 项目描述建议

在GitHub仓库页面，建议添加以下描述：

**简短描述：**
```
A Loop Hero inspired roguelike adventure game built with Godot 4.4
```

**详细README内容：**
- 项目特色和玩法
- 技术栈（Godot 4.4, GDScript）
- 安装和运行说明
- 开发进度
- 贡献指南

## 仓库标签建议

添加以下标签帮助其他人发现你的项目：
- `godot`
- `game-development`
- `roguelike`
- `loop-hero`
- `indie-game`
- `gdscript`
- `2d-game`