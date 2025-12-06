# CI Integration Prompt (Appendix for Coding Agent)

## Using CI for Testing

You have access to a GitHub Actions CI pipeline that runs on a self-hosted runner.
This allows you to verify your changes build and pass tests remotely.

### When to Trigger CI

1. **After implementing a feature** - Verify everything builds
2. **Before marking a feature as passing** - Confirm tests pass
3. **If unsure about changes** - Run tests to validate

### How to Trigger CI

Use the PowerShell script:

```powershell
# Test only (fastest)
.\scripts\trigger-ci.ps1 -Token $env:GITHUB_TOKEN -Owner "OWNER" -Repo "wg-flutter" -TestOnly

# Full build for Windows
.\scripts\trigger-ci.ps1 -Token $env:GITHUB_TOKEN -Owner "OWNER" -Repo "wg-flutter" -Platform windows

# Full build for all platforms
.\scripts\trigger-ci.ps1 -Token $env:GITHUB_TOKEN -Owner "OWNER" -Repo "wg-flutter" -Platform all
```

### Interpreting Results

The script will output:
- ✅ **success** - All checks passed
- ❌ **failure** - Something failed (check logs)
- ⏭️ **skipped** - Job was skipped (conditional)

### Before Triggering CI

1. **Commit your changes**:
   ```bash
   git add .
   git commit -m "feat: implement feature X"
   ```

2. **Push to GitHub**:
   ```bash
   git push origin main
   ```

3. **Then trigger**:
   ```powershell
   .\scripts\trigger-ci.ps1 ...
   ```

### If CI Fails

1. Check the GitHub Actions run URL (printed by script)
2. Look at the failed step's logs
3. Fix the issue
4. Commit, push, and re-trigger

### Required Setup

For CI integration to work:
- GitHub token must be set: `$env:GITHUB_TOKEN`
- Repository must be pushed to GitHub
- Self-hosted runner must be online (or use `windows-latest`)

### Workflow Inputs

| Input | Description | Default |
|-------|-------------|---------|
| `test_only` | Skip builds, only run tests | `false` |
| `platform` | Target: `windows`, `android`, `all` | `windows` |

### Estimated Times (Self-Hosted)

| Action | Time |
|--------|------|
| Tests only | ~1-2 min |
| Windows build | ~3-5 min |
| Android build | ~5-8 min |
| All platforms | ~10-15 min |

### Example Workflow

```
1. Implement feature
2. Run local tests: flutter test
3. Commit changes
4. Push to GitHub
5. Trigger CI: .\scripts\trigger-ci.ps1 -TestOnly
6. If passes, verify build: .\scripts\trigger-ci.ps1 -Platform windows
7. If all passes, mark feature as completed
```

## Note on Local vs CI Testing

- **Local testing** (`flutter test`) is faster for quick iteration
- **CI testing** ensures the build works in a clean environment
- Use both: local for development, CI for verification
