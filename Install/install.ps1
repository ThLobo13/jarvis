# ==========================================================================
#  Instalador do Jarvis (Windows 10/11)
#
#  Local (pasta com os arquivos):   .\install.ps1      ou duplo clique no install.bat
#  Remoto (arquivos hospedados):
#     $env:JARVIS_BASE_URL = "https://raw.githubusercontent.com/USUARIO/REPO/main"
#     irm "$env:JARVIS_BASE_URL/install.ps1" | iex
#
#  Variaveis opcionais (defina antes de rodar):
#     JARVIS_DIR         pasta de instalacao (padrao: %USERPROFILE%\jarvis)
#     JARVIS_MODEL       modelo do Ollama   (padrao: qwen2.5:7b; PC fraco: qwen2.5:3b)
#     JARVIS_SKIP_MODEL  1 = nao baixar o modelo agora
# ==========================================================================

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$InstallDir = if ($env:JARVIS_DIR) { $env:JARVIS_DIR } else { Join-Path $env:USERPROFILE "jarvis" }
$Model      = if ($env:JARVIS_MODEL) { $env:JARVIS_MODEL } else { "qwen2.5:7b" }
$SkipModel  = ($env:JARVIS_SKIP_MODEL -eq "1")
$Required   = @("jarvis.py", "requirements.txt")
$Optional   = @("jarvis.bat", "README.md")

function Step($t) { Write-Host ""; Write-Host "==> $t" -ForegroundColor Cyan }
function Ok($t)   { Write-Host "    OK: $t" -ForegroundColor Green }
function Warn($t) { Write-Host "    AVISO: $t" -ForegroundColor Yellow }

function Refresh-Path {
    $m = [Environment]::GetEnvironmentVariable("Path", "Machine")
    $u = [Environment]::GetEnvironmentVariable("Path", "User")
    $env:Path = "$m;$u"
}

function Winget-Install($id) {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        throw "O winget nao foi encontrado. Atualize o 'Instalador de Aplicativo' na Microsoft Store, ou instale '$id' manualmente e rode este instalador de novo."
    }
    winget install -e --id $id --accept-package-agreements --accept-source-agreements
    Refresh-Path
}

function Test-Py($exe, $pyArgs) {
    try {
        $out = & $exe @pyArgs --version 2>&1 | Out-String
        return ($LASTEXITCODE -eq 0 -and $out -match "Python 3\.(10|11|12)\.")
    } catch { return $false }
}

function Find-Python {
    $cands = @(
        @{ Exe = "py";     Args = @("-3.12") },
        @{ Exe = "py";     Args = @("-3.11") },
        @{ Exe = "py";     Args = @("-3.10") },
        @{ Exe = "python"; Args = @() }
    )
    foreach ($c in $cands) {
        if ((Get-Command $c.Exe -ErrorAction SilentlyContinue) -and (Test-Py $c.Exe $c.Args)) { return $c }
    }
    return $null
}

function Find-Ollama {
    $c = Get-Command ollama -ErrorAction SilentlyContinue
    if ($c) { return $c.Source }
    $p = Join-Path $env:LOCALAPPDATA "Programs\Ollama\ollama.exe"
    if (Test-Path $p) { return $p }
    return $null
}

function Ollama-Up {
    try { Invoke-RestMethod "http://localhost:11434/api/tags" -TimeoutSec 3 | Out-Null; return $true }
    catch { return $false }
}

Write-Host ""
Write-Host "  J.A.R.V.I.S. - instalador" -ForegroundColor Cyan
Write-Host "  Pasta de instalacao: $InstallDir"

# ---------------------------------------------------------------- 1. Python
Step "1/5  Python (3.10 a 3.12)"
$py = Find-Python
if (-not $py) {
    Warn "Python 3.10-3.12 nao encontrado. Instalando o Python 3.12..."
    Winget-Install "Python.Python.3.12"
    $py = Find-Python
    if (-not $py) { throw "Python instalado, mas ainda nao encontrado. Feche e abra o terminal e rode o instalador de novo." }
}
Ok ("{0} {1}" -f $py.Exe, ($py.Args -join " "))

# ---------------------------------------------------------------- 2. Arquivos
Step "2/5  Copiando os arquivos do Jarvis"
New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
$srcDir = $PSScriptRoot
if ($srcDir -and (Test-Path (Join-Path $srcDir "jarvis.py"))) {
    if ((Resolve-Path $srcDir).Path -ne (Resolve-Path $InstallDir).Path) {
        foreach ($f in ($Required + $Optional)) {
            $src = Join-Path $srcDir $f
            if (Test-Path $src) { Copy-Item $src $InstallDir -Force }
            elseif ($Required -contains $f) { throw "Arquivo obrigatorio nao encontrado: $f" }
        }
    }
    Ok "copiado de $srcDir"
} elseif ($env:JARVIS_BASE_URL) {
    $base = $env:JARVIS_BASE_URL.TrimEnd("/")
    foreach ($f in ($Required + $Optional)) {
        try { Invoke-WebRequest -UseBasicParsing "$base/$f" -OutFile (Join-Path $InstallDir $f) }
        catch { if ($Required -contains $f) { throw "Falha ao baixar $f de $base" } }
    }
    Ok "baixado de $base"
} else {
    throw "Nao achei o jarvis.py ao lado do instalador. Rode o install.ps1 de dentro da pasta do Jarvis, ou defina JARVIS_BASE_URL."
}

# ---------------------------------------------------------------- 3. Ambiente virtual + dependencias
Step "3/5  Ambiente Python e dependencias (pode demorar alguns minutos)"
$venv = Join-Path $InstallDir "venv"
$vpy  = Join-Path $venv "Scripts\python.exe"
if (-not (Test-Path $vpy)) {
    & $py.Exe @($py.Args) -m venv $venv
    if ($LASTEXITCODE -ne 0) { throw "Falha ao criar o ambiente virtual." }
}
& $vpy -m pip install --upgrade pip --quiet
& $vpy -m pip install -r (Join-Path $InstallDir "requirements.txt")
if ($LASTEXITCODE -ne 0) {
    throw "Falha ao instalar as dependencias (veja o erro acima). Se for o PyAudio, tente: $vpy -m pip install pipwin ; $vpy -m pipwin install pyaudio"
}
Ok "dependencias instaladas"

# ---------------------------------------------------------------- 4. Ollama + modelo
Step "4/5  Ollama (IA local e gratuita)"
$ollama = Find-Ollama
if (-not $ollama) {
    Warn "Ollama nao encontrado. Instalando..."
    Winget-Install "Ollama.Ollama"
    $ollama = Find-Ollama
    if (-not $ollama) { throw "Ollama instalado, mas nao encontrado. Feche e abra o terminal e rode o instalador de novo." }
}
Ok $ollama

if (-not (Ollama-Up)) {
    Start-Process -FilePath $ollama -ArgumentList "serve" -WindowStyle Hidden
    for ($i = 0; $i -lt 30 -and -not (Ollama-Up); $i++) { Start-Sleep -Seconds 2 }
}
if (-not (Ollama-Up)) {
    Warn "Nao consegui iniciar o Ollama automaticamente. Abra o app Ollama e rode: ollama pull $Model"
} elseif ($SkipModel) {
    Warn "Download do modelo ignorado. Depois rode: ollama pull $Model"
} else {
    Write-Host "    Baixando o modelo $Model (varios GB, so na primeira vez)..."
    & $ollama pull $Model
    if ($LASTEXITCODE -ne 0) { throw "Falha ao baixar o modelo $Model." }
    Ok "modelo $Model pronto"
}
if ($Model -ne "qwen2.5:7b") {
    [Environment]::SetEnvironmentVariable("JARVIS_MODEL", $Model, "User")
}

# ---------------------------------------------------------------- 5. Atalhos
Step "5/5  Atalhos"
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if (-not $userPath) { $userPath = "" }
if (($userPath -split ";") -notcontains $InstallDir) {
    [Environment]::SetEnvironmentVariable("Path", ($userPath.TrimEnd(";") + ";" + $InstallDir), "User")
    Ok "comando 'jarvis' adicionado ao PATH (vale em terminais novos)"
}
try {
    $desktop = [Environment]::GetFolderPath("Desktop")
    $ws  = New-Object -ComObject WScript.Shell
    $lnk = $ws.CreateShortcut((Join-Path $desktop "Jarvis.lnk"))
    $lnk.TargetPath = Join-Path $InstallDir "jarvis.bat"
    $lnk.WorkingDirectory = $InstallDir
    $lnk.Save()
    Ok "atalho 'Jarvis' criado na Area de Trabalho"
} catch { Warn "nao consegui criar o atalho da Area de Trabalho." }

Write-Host ""
Write-Host "Instalacao concluida!" -ForegroundColor Green
Write-Host "  Para iniciar: de dois cliques em 'Jarvis' na Area de Trabalho,"
Write-Host "  ou abra um terminal NOVO e digite:  jarvis"
Write-Host "  Teste sem microfone:  jarvis --text"
Write-Host ""
