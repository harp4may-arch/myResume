# =====================================================================
# build-full.ps1 — 실명 이력서 HTML + PDF 생성 (로컬 전용)
#
# 사용법:  powershell -ExecutionPolicy Bypass -File .\build-full.ps1
#
# 공개용 profile.html(마스킹 버전)에 private\personal.json의 실제
# 개인정보를 병합해 private\profile_full.html 을 만들고,
# Edge 헤드리스로 private\이력서.pdf 를 생성한다.
# private 폴더는 .gitignore 로 git에 올라가지 않는다.
# =====================================================================

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot

# 1. 개인정보 로드
$p = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'private\personal.json') | ConvertFrom-Json

# 2. 마스킹 문자열 → 실제 값 치환
$html = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'profile.html')

$html = $html.Replace('신**', $p.name)
$html = $html.Replace('alt="프로필"', ('alt="' + $p.name + '"'))
$html = $html.Replace('010-****-**16', $p.phone)
$html = $html.Replace('***@naver.com', $p.email)
$html = $html.Replace('서울 **구 **동', $p.address)
$html = $html.Replace('src="MyPic2.png"', 'src="photo.png"')   # 캐리커쳐 → 실사진

$fullHtml = Join-Path $root 'private\profile_full.html'
[System.IO.File]::WriteAllText($fullHtml, $html, (New-Object System.Text.UTF8Encoding $false))
Write-Host "생성: $fullHtml"

# 3. Edge 헤드리스로 PDF 생성
$edge = @(
    "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe",
    "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"
) | Where-Object { Test-Path $_ } | Select-Object -First 1

if ($edge) {
    $pdf = Join-Path $root 'private\이력서_full.pdf'
    $uri = ([System.Uri]$fullHtml).AbsoluteUri
    & $edge --headless --disable-gpu --no-pdf-header-footer --print-to-pdf="$pdf" $uri | Out-Null
    Start-Sleep -Seconds 2
    if (Test-Path $pdf) { Write-Host "생성: $pdf" }
    else { Write-Warning "PDF 생성 실패 — private\profile_full.html 을 브라우저로 열어 [인쇄] 버튼으로 저장하세요." }
} else {
    Write-Warning "Edge를 찾지 못했습니다 — private\profile_full.html 을 브라우저로 열어 [인쇄] 버튼으로 저장하세요."
}
