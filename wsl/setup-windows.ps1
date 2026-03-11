# setup-windows.ps1 — Install dev tools on Windows via winget
# Usage (PowerShell as Administrator):
#   Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
#   .\setup-windows.ps1
#
# Installs: JDK 17, JDK 21, Python, VS Code, Docker Desktop, pCloud
# Uses winget (built into Windows 11). Idempotent — skips already installed.

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Windows Dev Setup — devops-toolbox" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check winget
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "[ERR] winget not found. Install 'App Installer' from Microsoft Store." -ForegroundColor Red
    exit 1
}

# Package list: winget-id | display-name
$packages = @(
    @{ Id = "Microsoft.OpenJDK.17";          Name = "OpenJDK 17 (Microsoft)" },
    @{ Id = "Microsoft.OpenJDK.21";          Name = "OpenJDK 21 (Microsoft)" },
    @{ Id = "Python.Python.3.12";            Name = "Python 3.12" },
    @{ Id = "Microsoft.VisualStudioCode";    Name = "Visual Studio Code" },
    @{ Id = "Docker.DockerDesktop";          Name = "Docker Desktop" },
    @{ Id = "PCloud.pCloud";                 Name = "pCloud Drive" },
    @{ Id = "Git.Git";                       Name = "Git for Windows" },
    @{ Id = "Apache.Maven.3";               Name = "Apache Maven" }
)

foreach ($pkg in $packages) {
    Write-Host ">>> Checking $($pkg.Name)..." -NoNewline

    # Check if already installed
    $installed = winget list --id $pkg.Id --accept-source-agreements 2>$null |
                 Select-String $pkg.Id

    if ($installed) {
        Write-Host " [SKIP] already installed" -ForegroundColor Yellow
    } else {
        Write-Host ""
        Write-Host "    Installing $($pkg.Name)..."
        winget install --id $pkg.Id --accept-package-agreements --accept-source-agreements --silent
        if ($LASTEXITCODE -eq 0) {
            Write-Host "    [OK] $($pkg.Name) installed" -ForegroundColor Green
        } else {
            Write-Host "    [ERR] Failed to install $($pkg.Name)" -ForegroundColor Red
        }
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Post-install steps" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Restart your terminal to pick up new PATH entries"
Write-Host "2. Docker Desktop: enable WSL integration (Settings > Resources > WSL Integration)"
Write-Host "3. pCloud: sign in and verify drive letter (default P:)"
Write-Host "4. VS Code: install the 'WSL' extension, then open WSL and run setup-vscode.sh"
Write-Host ""
Write-Host "Verify Java:"
Write-Host "  java -version"
Write-Host "  where java        # should show Microsoft OpenJDK path"
Write-Host ""
Write-Host "Switch Java version (Windows):"
Write-Host "  Set JAVA_HOME to the desired JDK path in System Environment Variables"
Write-Host "  Default paths:"
Write-Host "    JDK 17: C:\Program Files\Microsoft\jdk-17.*"
Write-Host "    JDK 21: C:\Program Files\Microsoft\jdk-21.*"
Write-Host ""
Write-Host "[OK] Done." -ForegroundColor Green
