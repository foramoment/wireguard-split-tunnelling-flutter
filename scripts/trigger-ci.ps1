<#
.SYNOPSIS
    Triggers GitHub Actions workflow and waits for results.
    Designed for use by AI agents to run tests remotely.

.DESCRIPTION
    This script:
    1. Triggers a GitHub Actions workflow via API
    2. Polls for completion
    3. Returns the result

.PARAMETER Token
    GitHub Personal Access Token with 'repo' and 'workflow' scopes

.PARAMETER Owner
    Repository owner (username or org)

.PARAMETER Repo
    Repository name

.PARAMETER Workflow
    Workflow file name (e.g., 'build.yml')

.PARAMETER Branch
    Branch to run workflow on (default: 'main')

.PARAMETER TestOnly
    If true, only runs tests without building

.PARAMETER Platform
    Target platform: 'windows', 'android', or 'all'

.EXAMPLE
    .\trigger-ci.ps1 -Token "ghp_xxx" -Owner "myuser" -Repo "wg-flutter" -TestOnly

.EXAMPLE
    .\trigger-ci.ps1 -Token "ghp_xxx" -Owner "myuser" -Repo "wg-flutter" -Platform "android"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$Token,
    
    [Parameter(Mandatory=$true)]
    [string]$Owner,
    
    [Parameter(Mandatory=$true)]
    [string]$Repo,
    
    [string]$Workflow = "build.yml",
    [string]$Branch = "main",
    [switch]$TestOnly,
    [ValidateSet("windows", "android", "all")]
    [string]$Platform = "windows",
    [int]$TimeoutMinutes = 30,
    [int]$PollIntervalSeconds = 10
)

$ErrorActionPreference = "Stop"

$headers = @{
    "Authorization" = "Bearer $Token"
    "Accept" = "application/vnd.github.v3+json"
    "X-GitHub-Api-Version" = "2022-11-28"
}

$baseUrl = "https://api.github.com/repos/$Owner/$Repo"

# Function to make API calls
function Invoke-GitHubApi {
    param($Method, $Endpoint, $Body = $null)
    
    $params = @{
        Uri = "$baseUrl$Endpoint"
        Method = $Method
        Headers = $headers
        ContentType = "application/json"
    }
    
    if ($Body) {
        $params.Body = $Body | ConvertTo-Json -Depth 10
    }
    
    try {
        return Invoke-RestMethod @params
    } catch {
        Write-Error "API Error: $($_.Exception.Message)"
        throw
    }
}

# Step 1: Get the latest workflow run ID before triggering
Write-Host "📋 Getting current workflow runs..." -ForegroundColor Cyan
$beforeRuns = Invoke-GitHubApi -Method GET -Endpoint "/actions/workflows/$Workflow/runs?per_page=1"
$lastRunId = if ($beforeRuns.workflow_runs.Count -gt 0) { $beforeRuns.workflow_runs[0].id } else { 0 }
Write-Host "   Last run ID: $lastRunId"

# Step 2: Trigger the workflow
Write-Host "🚀 Triggering workflow '$Workflow' on branch '$Branch'..." -ForegroundColor Green

$triggerBody = @{
    ref = $Branch
    inputs = @{
        test_only = $TestOnly.ToString().ToLower()
        platform = $Platform
    }
}

try {
    Invoke-GitHubApi -Method POST -Endpoint "/actions/workflows/$Workflow/dispatches" -Body $triggerBody
    Write-Host "   ✅ Workflow triggered successfully!" -ForegroundColor Green
} catch {
    Write-Error "Failed to trigger workflow: $_"
    exit 1
}

# Step 3: Wait a moment for the run to be created
Write-Host "⏳ Waiting for workflow run to start..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

# Step 4: Find the new workflow run
$newRunId = $null
$maxAttempts = 12  # 1 minute total
for ($i = 0; $i -lt $maxAttempts; $i++) {
    $runs = Invoke-GitHubApi -Method GET -Endpoint "/actions/workflows/$Workflow/runs?per_page=5"
    
    foreach ($run in $runs.workflow_runs) {
        if ($run.id -gt $lastRunId -and $run.event -eq "workflow_dispatch") {
            $newRunId = $run.id
            break
        }
    }
    
    if ($newRunId) { break }
    
    Write-Host "   Waiting for run to appear... ($($i + 1)/$maxAttempts)"
    Start-Sleep -Seconds 5
}

if (-not $newRunId) {
    Write-Error "❌ Could not find the triggered workflow run!"
    exit 1
}

Write-Host "   Found run ID: $newRunId" -ForegroundColor Cyan
$runUrl = "https://github.com/$Owner/$Repo/actions/runs/$newRunId"
Write-Host "   URL: $runUrl" -ForegroundColor Blue

# Step 5: Poll for completion
Write-Host "⏳ Waiting for workflow to complete..." -ForegroundColor Yellow
$startTime = Get-Date
$timeout = New-TimeSpan -Minutes $TimeoutMinutes

while ((Get-Date) - $startTime -lt $timeout) {
    $run = Invoke-GitHubApi -Method GET -Endpoint "/actions/runs/$newRunId"
    
    $status = $run.status
    $conclusion = $run.conclusion
    $elapsed = [math]::Round(((Get-Date) - $startTime).TotalMinutes, 1)
    
    Write-Host "   Status: $status | Elapsed: ${elapsed}m" -NoNewline
    
    if ($status -eq "completed") {
        Write-Host ""
        break
    }
    
    Write-Host "`r" -NoNewline
    Start-Sleep -Seconds $PollIntervalSeconds
}

# Step 6: Get final result
$run = Invoke-GitHubApi -Method GET -Endpoint "/actions/runs/$newRunId"

Write-Host ""
Write-Host "=" * 50 -ForegroundColor Gray
Write-Host "📊 WORKFLOW RESULT" -ForegroundColor Cyan
Write-Host "=" * 50 -ForegroundColor Gray
Write-Host ""
Write-Host "   Status: $($run.status)"
Write-Host "   Conclusion: $($run.conclusion)" -ForegroundColor $(if ($run.conclusion -eq "success") { "Green" } else { "Red" })
Write-Host "   Duration: $([math]::Round(((Get-Date) - $startTime).TotalMinutes, 1)) minutes"
Write-Host "   URL: $runUrl"
Write-Host ""

# Step 7: Get job details
$jobs = Invoke-GitHubApi -Method GET -Endpoint "/actions/runs/$newRunId/jobs"

Write-Host "📋 Job Results:" -ForegroundColor Yellow
foreach ($job in $jobs.jobs) {
    $icon = if ($job.conclusion -eq "success") { "✅" } elseif ($job.conclusion -eq "failure") { "❌" } elseif ($job.conclusion -eq "skipped") { "⏭️" } else { "⏳" }
    $color = if ($job.conclusion -eq "success") { "Green" } elseif ($job.conclusion -eq "failure") { "Red" } else { "Yellow" }
    Write-Host "   $icon $($job.name): $($job.conclusion)" -ForegroundColor $color
}

Write-Host ""

# Return exit code based on conclusion
if ($run.conclusion -eq "success") {
    Write-Host "✅ All checks passed!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "❌ Workflow failed or was cancelled." -ForegroundColor Red
    exit 1
}
