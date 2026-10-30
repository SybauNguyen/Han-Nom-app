$ErrorActionPreference = 'Stop'

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$FontDirectory = Join-Path $ProjectRoot 'assets\fonts'
$FontPath = Join-Path $FontDirectory 'NomNaTong-Regular.ttf'
$DownloadUrl = 'https://github.com/nomfoundation/font/releases/download/v5.18/NomNaTong-Regular.ttf'
$ExpectedSha256 = '37bd8506257d0905d499395e7f0bc2b6a2ae619dbb635a82ea0905b75b2ff5f3'

New-Item -ItemType Directory -Force -Path $FontDirectory | Out-Null

# Windows normally ignores filename case, but asset paths are case-sensitive
# on Linux/CI and must match pubspec.yaml exactly. Normalize common variants.
$Candidates = Get-ChildItem -Path $FontDirectory -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -ieq 'NomNaTong-Regular.ttf' }
foreach ($Candidate in $Candidates) {
    $CandidateHash = (Get-FileHash -Path $Candidate.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($CandidateHash -eq $ExpectedSha256) {
        if ($Candidate.FullName -ne $FontPath) {
            Copy-Item -Force -Path $Candidate.FullName -Destination $FontPath
        }
        Write-Host 'Nom Na Tong v5.18 da co san, dung ten file chuan va SHA-256 hop le.' -ForegroundColor Green
        exit 0
    }
}
if (Test-Path $FontPath) {
    $CurrentHash = (Get-FileHash -Path $FontPath -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($CurrentHash -ne $ExpectedSha256) {
        Write-Host 'Font co san khong trung SHA-256 cua ban v5.18; se tai lai.' -ForegroundColor Yellow
    }
}

$TempPath = Join-Path $env:TEMP ('NomNaTong-Regular-' + [Guid]::NewGuid().ToString('N') + '.ttf')
try {
    Write-Host 'Dang tai Nom Na Tong v5.18 tu GitHub chinh thuc...'
    Invoke-WebRequest -Uri $DownloadUrl -OutFile $TempPath
    $DownloadedHash = (Get-FileHash -Path $TempPath -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($DownloadedHash -ne $ExpectedSha256) {
        throw "SHA-256 khong khop. Nhan duoc: $DownloadedHash"
    }
    Move-Item -Force -Path $TempPath -Destination $FontPath
    Write-Host "Da cai font: $FontPath" -ForegroundColor Green
}
catch {
    if (Test-Path $TempPath) { Remove-Item -Force $TempPath }
    Write-Error @"
Khong tai duoc Nom Na Tong v5.18. Hay kiem tra ket noi mang.
Ban cung co the tai thu cong tu:
$DownloadUrl
Sau do dat file vao:
$FontPath
SHA-256 mong doi: $ExpectedSha256
"@
    exit 1
}
finally {
    if (Test-Path $TempPath) { Remove-Item -Force $TempPath -ErrorAction SilentlyContinue }
}
