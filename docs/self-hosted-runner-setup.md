# Self-Hosted Runner Setup Guide

This guide explains how to set up a GitHub Actions self-hosted runner on your local machine for faster builds.

## Benefits of Self-Hosted Runner

| Aspect | GitHub-Hosted | Self-Hosted |
|--------|---------------|-------------|
| **Speed** | ~5-10 min queue | Instant start |
| **Cost** | Limited free minutes | Free (your machine) |
| **Build time** | Standard | As fast as your PC |
| **Dependencies** | Install each time | Pre-installed |
| **Local testing** | ❌ | ✅ Artifacts on disk |

## Prerequisites

- Windows 10/11 (or your target OS)
- Flutter SDK installed
- Visual Studio Build Tools (for Windows builds)
- ~5 GB disk space for runner

## Setup Steps

### 1. Create a Runner in GitHub

1. Go to your repository on GitHub
2. Navigate to **Settings** → **Actions** → **Runners**
3. Click **New self-hosted runner**
4. Select **Windows** (or your OS)
5. Follow the instructions shown

### 2. Quick Setup Commands (Windows)

```powershell
# Create a folder for the runner
mkdir C:\actions-runner
cd C:\actions-runner

# Download the runner (check GitHub for latest version)
Invoke-WebRequest -Uri https://github.com/actions/runner/releases/download/v2.311.0/actions-runner-win-x64-2.311.0.zip -OutFile actions-runner.zip

# Extract
Expand-Archive -Path actions-runner.zip -DestinationPath .

# Configure (use the token from GitHub)
.\config.cmd --url https://github.com/YOUR_USERNAME/YOUR_REPO --token YOUR_TOKEN

# Run as a service (recommended)
.\svc.cmd install
.\svc.cmd start
```

### 3. Install Dependencies on Runner Machine

```powershell
# Flutter
# Download from https://flutter.dev/docs/get-started/install/windows
# Add to PATH: C:\flutter\bin

# Visual Studio Build Tools (lighter than full VS)
winget install Microsoft.VisualStudio.2022.BuildTools --override "--add Microsoft.VisualStudio.Workload.VCTools --includeRecommended --quiet"

# Android SDK (if building for Android)
# Install Android Studio or standalone SDK

# Verify Flutter
flutter doctor
```

### 4. Configure Runner Labels (Optional)

Edit `.runner` file or use:
```powershell
.\config.cmd --labels flutter,windows,android
```

## Using the Runner

### In Workflow File

The workflow is already configured to use self-hosted:

```yaml
jobs:
  build:
    runs-on: self-hosted  # Uses your local machine
```

To use GitHub-hosted instead:
```yaml
jobs:
  build:
    runs-on: windows-latest  # Uses GitHub's servers
```

### Triggering from Agent

Use the `trigger-ci.ps1` script:

```powershell
# Run tests only
.\scripts\trigger-ci.ps1 -Token $env:GITHUB_TOKEN -Owner "you" -Repo "wg-flutter" -TestOnly

# Build Windows
.\scripts\trigger-ci.ps1 -Token $env:GITHUB_TOKEN -Owner "you" -Repo "wg-flutter" -Platform windows

# Build everything
.\scripts\trigger-ci.ps1 -Token $env:GITHUB_TOKEN -Owner "you" -Repo "wg-flutter" -Platform all
```

## Runner Service Management

```powershell
# Check status
.\svc.cmd status

# Stop
.\svc.cmd stop

# Start
.\svc.cmd start

# Uninstall
.\svc.cmd uninstall
```

## Troubleshooting

### Runner not picking up jobs
- Check runner is online in GitHub Settings → Actions → Runners
- Verify `runs-on: self-hosted` in workflow
- Check runner service is running

### Build failures
- Run `flutter doctor` on the runner machine
- Ensure all dependencies are installed
- Check disk space

### Permission issues
- Run runner as Administrator for first-time setup
- Ensure runner user has access to Flutter and VS Build Tools

## Security Notes

⚠️ **Important**: Self-hosted runners should only be used with **private repositories** or repositories you trust. Public repos could run malicious code on your machine.

For public repos:
1. Use GitHub-hosted runners (`runs-on: windows-latest`)
2. Or set up runner in a dedicated VM/container

## Integration with AI Agents

The agent can:

1. **Trigger builds**: 
   ```powershell
   .\scripts\trigger-ci.ps1 -Token $token -Owner "user" -Repo "wg-flutter"
   ```

2. **Check results**: Script automatically polls and returns result

3. **Access artifacts**: Build outputs are in `build/` folder on your machine

### Environment Variable Setup

For the agent to use the script:

```powershell
# Set environment variable with your PAT
$env:GITHUB_TOKEN = "ghp_your_personal_access_token"

# Or create a .env file (don't commit!)
echo "GITHUB_TOKEN=ghp_xxx" > .env
```

### Creating a GitHub Token

1. Go to GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Generate new token with scopes:
   - `repo` (full control)
   - `workflow` (update workflows)
3. Copy and save the token securely
