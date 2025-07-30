# Loop Hero Project - GitHub Upload Script (PowerShell)
# ========================================

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Loop Hero Project - GitHub Upload Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if git is installed
try {
    $gitVersion = git --version 2>$null
    Write-Host "Git is installed: $gitVersion" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Git is not installed!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please install Git first:" -ForegroundColor Yellow
    Write-Host "1. Visit https://git-scm.com/download/win" -ForegroundColor Yellow
    Write-Host "2. Download and install Git for Windows" -ForegroundColor Yellow
    Write-Host "3. Restart PowerShell and run this script again" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Alternative installation methods:" -ForegroundColor Yellow
    Write-Host "- Chocolatey: choco install git" -ForegroundColor Yellow
    Write-Host "- Winget: winget install Git.Git" -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""

# Get user input for GitHub repository
$githubUsername = Read-Host "Enter your GitHub username"
if ([string]::IsNullOrWhiteSpace($githubUsername)) {
    Write-Host "Username cannot be empty!" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

$repoName = Read-Host "Enter repository name (default: loop-hero-clone)"
if ([string]::IsNullOrWhiteSpace($repoName)) {
    $repoName = "loop-hero-clone"
}

Write-Host ""
Write-Host "Repository URL will be: https://github.com/$githubUsername/$repoName.git" -ForegroundColor Yellow
Write-Host ""
$confirm = Read-Host "Is this correct? (y/n)"
if ($confirm -ne "y" -and $confirm -ne "Y") {
    Write-Host "Upload cancelled." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""
Write-Host "Starting Git operations..." -ForegroundColor Green
Write-Host ""

try {
    # Initialize git repository
    Write-Host "[1/6] Initializing Git repository..." -ForegroundColor Cyan
    git init
    if ($LASTEXITCODE -ne 0) { throw "Failed to initialize Git repository" }
    
    # Add all files
    Write-Host "[2/6] Adding files to repository..." -ForegroundColor Cyan
    git add .
    if ($LASTEXITCODE -ne 0) { throw "Failed to add files" }
    
    # Commit files
    Write-Host "[3/6] Committing files..." -ForegroundColor Cyan
    $commitMessage = @"
Initial commit: Loop Hero clone project setup

- Core game managers implemented (GameManager, LoopManager, CardManager, HeroManager, BattleManager)
- Basic UI and game loop structure
- Card system with comprehensive database
- Hero management with stats, equipment, and skills
- Turn-based battle system
- Resource management system
- Complete project documentation
- Godot 4.4 project configuration
"@
    git commit -m $commitMessage
    if ($LASTEXITCODE -ne 0) { throw "Failed to commit files" }
    
    # Add remote origin
    Write-Host "[4/6] Adding remote repository..." -ForegroundColor Cyan
    git remote add origin "https://github.com/$githubUsername/$repoName.git"
    if ($LASTEXITCODE -ne 0) { throw "Failed to add remote repository" }
    
    # Set main branch
    Write-Host "[5/6] Setting main branch..." -ForegroundColor Cyan
    git branch -M main
    if ($LASTEXITCODE -ne 0) { throw "Failed to set main branch" }
    
    # Push to GitHub
    Write-Host "[6/6] Pushing to GitHub..." -ForegroundColor Cyan
    Write-Host ""
    Write-Host "NOTE: You may be prompted for your GitHub credentials." -ForegroundColor Yellow
    Write-Host "Use your GitHub username and Personal Access Token (not password)." -ForegroundColor Yellow
    Write-Host ""
    git push -u origin main
    if ($LASTEXITCODE -ne 0) { throw "Failed to push to GitHub" }
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "SUCCESS! Project uploaded to GitHub!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Repository URL: https://github.com/$githubUsername/$repoName" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "1. Visit your repository on GitHub" -ForegroundColor Yellow
    Write-Host "2. Add a description and topics" -ForegroundColor Yellow
    Write-Host "3. Consider adding a license" -ForegroundColor Yellow
    Write-Host "4. Share your project with others!" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "To update your repository in the future, use:" -ForegroundColor Cyan
    Write-Host "  git add ." -ForegroundColor White
    Write-Host "  git commit -m 'Your commit message'" -ForegroundColor White
    Write-Host "  git push" -ForegroundColor White
    
} catch {
    Write-Host ""
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Common solutions:" -ForegroundColor Yellow
    Write-Host "1. Make sure the repository exists on GitHub" -ForegroundColor Yellow
    Write-Host "2. Check your credentials (use Personal Access Token)" -ForegroundColor Yellow
    Write-Host "3. Verify the repository URL is correct" -ForegroundColor Yellow
    Write-Host "4. Ensure you have internet connection" -ForegroundColor Yellow
}

Write-Host ""
Read-Host "Press Enter to exit"