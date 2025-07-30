@echo off
echo ========================================
echo Loop Hero Project - GitHub Upload Script
echo ========================================
echo.

:: Check if git is installed
git --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Git is not installed!
    echo.
    echo Please install Git first:
    echo 1. Visit https://git-scm.com/download/win
    echo 2. Download and install Git for Windows
    echo 3. Restart this script after installation
    echo.
    pause
    exit /b 1
)

echo Git is installed. Proceeding with upload...
echo.

:: Get user input for GitHub repository
set /p GITHUB_USERNAME="Enter your GitHub username: "
set /p REPO_NAME="Enter repository name (default: loop-hero-clone): "
if "%REPO_NAME%"=="" set REPO_NAME=loop-hero-clone

echo.
echo Repository URL will be: https://github.com/%GITHUB_USERNAME%/%REPO_NAME%.git
echo.
set /p CONFIRM="Is this correct? (y/n): "
if /i not "%CONFIRM%"=="y" (
    echo Upload cancelled.
    pause
    exit /b 1
)

echo.
echo Starting Git operations...
echo.

:: Initialize git repository
echo [1/6] Initializing Git repository...
git init
if %errorlevel% neq 0 (
    echo ERROR: Failed to initialize Git repository
    pause
    exit /b 1
)

:: Add all files
echo [2/6] Adding files to repository...
git add .
if %errorlevel% neq 0 (
    echo ERROR: Failed to add files
    pause
    exit /b 1
)

:: Commit files
echo [3/6] Committing files...
git commit -m "Initial commit: Loop Hero clone project setup

- Core game managers implemented (GameManager, LoopManager, CardManager, HeroManager, BattleManager)
- Basic UI and game loop structure
- Card system with comprehensive database
- Hero management with stats, equipment, and skills
- Turn-based battle system
- Resource management system
- Complete project documentation
- Godot 4.4 project configuration"
if %errorlevel% neq 0 (
    echo ERROR: Failed to commit files
    pause
    exit /b 1
)

:: Add remote origin
echo [4/6] Adding remote repository...
git remote add origin https://github.com/%GITHUB_USERNAME%/%REPO_NAME%.git
if %errorlevel% neq 0 (
    echo ERROR: Failed to add remote repository
    pause
    exit /b 1
)

:: Set main branch
echo [5/6] Setting main branch...
git branch -M main
if %errorlevel% neq 0 (
    echo ERROR: Failed to set main branch
    pause
    exit /b 1
)

:: Push to GitHub
echo [6/6] Pushing to GitHub...
echo.
echo NOTE: You may be prompted for your GitHub credentials.
echo Use your GitHub username and Personal Access Token (not password).
echo.
git push -u origin main
if %errorlevel% neq 0 (
    echo ERROR: Failed to push to GitHub
    echo.
    echo Common solutions:
    echo 1. Make sure the repository exists on GitHub
    echo 2. Check your credentials (use Personal Access Token)
    echo 3. Verify the repository URL is correct
    pause
    exit /b 1
)

echo.
echo ========================================
echo SUCCESS! Project uploaded to GitHub!
echo ========================================
echo.
echo Repository URL: https://github.com/%GITHUB_USERNAME%/%REPO_NAME%
echo.
echo Next steps:
 echo 1. Visit your repository on GitHub
 echo 2. Add a description and topics
 echo 3. Consider adding a license
 echo 4. Share your project with others!
echo.
echo To update your repository in the future, use:
echo   git add .
echo   git commit -m "Your commit message"
echo   git push
echo.
pause