#requires -Version 5.1
<#
.SYNOPSIS
    把 my-ui 自建组件库推到 GitHub，并回填 DSH 的 shadcn-selfhost 配置。
.DESCRIPTION
    前提：已在 GitHub 网页上手动创建了空仓库（不要勾选 README / .gitignore）。
    首次运行会弹出浏览器要求 GitHub 登录授权，属正常。
.EXAMPLE
    powershell -NoProfile -ExecutionPolicy Bypass -File publish.ps1 -User yourname
.EXAMPLE
    powershell -NoProfile -ExecutionPolicy Bypass -File publish.ps1 -User yourname -RepoName my-ui
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$User,
    [string]$RepoName = 'my-ui',
    [string]$RepoDir
)

$ErrorActionPreference = 'Continue'
$noBom = New-Object System.Text.UTF8Encoding($false)

if (-not $RepoDir) { $RepoDir = $PSScriptRoot }
$RepoDir = (Resolve-Path $RepoDir).Path

function Write-Step($m)  { Write-Host "==> $m" -ForegroundColor Cyan }
function Write-Ok($m)    { Write-Host "  OK  $m" -ForegroundColor Green }
function Write-Warn2($m) { Write-Host "  !   $m" -ForegroundColor Yellow }

if (-not (Test-Path (Join-Path $RepoDir '.git'))) {
    Write-Host "FAIL  目标目录不是 git 仓库：$RepoDir" -ForegroundColor Red
    exit 1
}

$remoteUrl = 'https://github.com/' + $User + '/' + $RepoName + '.git'
$pagesBase = 'https://' + $User + '.github.io/' + $RepoName + '/r'

Push-Location $RepoDir
try {
    Write-Step '配置远程'
    $existing = & git remote 2>$null
    if ($existing -contains 'origin') {
        & git remote set-url origin $remoteUrl
    } else {
        & git remote add origin $remoteUrl
    }
    Write-Ok $remoteUrl

    Write-Step '推送（首次会弹 GitHub 登录窗口，请授权）'
    & git push -u origin main
    if ($LASTEXITCODE -ne 0) {
        Write-Warn2 '推送失败。常见原因：'
        Write-Warn2 '  1) GitHub 上还没建仓库 → 去 https://github.com/new 建一个叫 ' + $RepoName + ' 的空仓库（不要勾 README）'
        Write-Warn2 '  2) 未登录 → 重新运行本脚本，在弹出的窗口完成授权'
        Write-Warn2 '  3) 用户名写错 → 检查 -User 参数'
        exit 1
    }
    Write-Ok '推送完成'

    # ---------- 回填 DSH 配置 ----------
    Write-Step '回填 shadcn-selfhost 配置'
    $cfgPath = Join-Path $env:DSH_HOME 'skills\shadcn-selfhost\config.json'
    if (Test-Path $cfgPath) {
        $cfg = [System.IO.File]::ReadAllText($cfgPath, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
        $cfg.repo = 'https://github.com/' + $User + '/' + $RepoName
        $cfg.registryBase = $pagesBase
        [System.IO.File]::WriteAllText($cfgPath, ($cfg | ConvertTo-Json -Depth 10), $noBom)
        Write-Ok ('repo         -> ' + $cfg.repo)
        Write-Ok ('registryBase -> ' + $cfg.registryBase)
    } else {
        Write-Warn2 ('找不到配置：' + $cfgPath)
    }

    # ---------- 收尾指引 ----------
    Write-Host ''
    Write-Step '还差一步：开启 GitHub Pages'
    $guide = @(
        '  1. 打开 https://github.com/' + $User + '/' + $RepoName + '/settings/pages'
        '  2. Source 选 "Deploy from a branch"'
        '  3. Branch 选 main，目录选 /public，点 Save'
        '  4. 等 1 分钟，然后验证：'
        '       curl -s ' + $pagesBase + '/registry.json'
        ''
        '  验证通过后，任何项目里都能这样用：'
        '       npx shadcn@latest add @myui/button'
        ''
        '  或者直接让 DSH 接管：'
        '       powershell -NoProfile -ExecutionPolicy Bypass -File ' + (Join-Path $env:DSH_HOME 'skills\shadcn-selfhost\scripts\init-project.ps1') + ' -Target <新项目目录>'
    )
    Write-Host ($guide -join "`r`n") -ForegroundColor Gray
}
finally {
    Pop-Location
}
