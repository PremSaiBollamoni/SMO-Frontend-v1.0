# Configure git user email
git config user.email "premsai200804@gmail.com"

# Get all changed files
$files = git diff --name-only --cached
if ($files.Count -eq 0) {
    $files = git status -s | ForEach-Object { $_.Substring(3) }
}

Write-Host "Found $($files.Count) files to commit individually" -ForegroundColor Cyan

$count = 0

# Commit each file separately
foreach ($file in $files) {
    $file = $file.Trim()
    if ([string]::IsNullOrWhiteSpace($file)) { continue }

    $status = git status --short -- "$file"

    if ($status -match "^\s*D\s") {
        # Deleted file
        git add "$file" 2>$null
        git commit -m "chore: remove $file" 2>$null
        $count++
    }
    elseif ($status -match "^\s*\?\?") {
        # New file
        git add "$file" 2>$null
        $msg = switch -Regex ($file) {
            "README" { "docs: add $([System.IO.Path]::GetFileName($file))" }
            "\.java$" { "feat: implement $([System.IO.Path]::GetFileNameWithoutExtension($file))" }
            "\.dart$" { "feat: implement $([System.IO.Path]::GetFileNameWithoutExtension($file))" }
            "\.gradle" { "build: update gradle configuration" }
            "\.yaml|\.yml" { "config: update configuration" }
            "\.json" { "config: update JSON configuration" }
            "\.sql" { "db: update database script" }
            default { "feat: add $([System.IO.Path]::GetFileName($file))" }
        }
        git commit -m "$msg" 2>$null
        $count++
    }
    else {
        # Modified file
        git add "$file" 2>$null
        $msg = switch -Regex ($file) {
            "README" { "docs: update $([System.IO.Path]::GetFileName($file))" }
            "attendance" { "feat: attendance module updates" }
            "supervisor" { "feat: supervisor module updates" }
            "efficiency" { "feat: efficiency tracking implementation" }
            "assignment_history" { "feat: assignment history tracking" }
            "AttendanceService" { "refactor: improve attendance service logic" }
            "Repository\.java$" { "refactor: update repository queries" }
            "\.gradle" { "build: update gradle dependencies" }
            "\.yaml|\.yml" { "config: update configuration" }
            "theme" { "style: update app theme" }
            "utils" { "refactor: improve utility functions" }
            "widgets" { "refactor: improve widget implementations" }
            default { "refactor: update $([System.IO.Path]::GetFileName($file))" }
        }
        git commit -m "$msg" 2>$null
        $count++
    }

    Write-Progress -Activity "Committing files" -Status "Processing $file" -PercentComplete ([math]::Min(($count/$files.Count)*100, 100))
}

Write-Host "`nTotal commits created: $count" -ForegroundColor Green

# Push all commits
Write-Host "Pushing all $count commits to remote..." -ForegroundColor Cyan
git push -u origin main

Write-Host "All $count commits pushed successfully!" -ForegroundColor Green
Write-Host "Tracked by: premsai200804@gmail.com" -ForegroundColor Yellow
