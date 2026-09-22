[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^\d+\.\d+\.\d+$')]
    [string] $Versao,

    [string] $DiretorioSaida
)

$ErrorActionPreference = 'Stop'

$raiz = Split-Path -Parent $PSScriptRoot
$script = Join-Path $PSScriptRoot 'CadCli.iss'

if (-not $DiretorioSaida) {
    $DiretorioSaida = Join-Path $raiz 'dist'
}

function Resolver-ISCC {
    $candidatos = @(
        (Join-Path $env:LOCALAPPDATA 'Programs\Inno Setup 6\ISCC.exe'),
        (Join-Path ${env:ProgramFiles(x86)} 'Inno Setup 6\ISCC.exe'),
        (Join-Path $env:ProgramFiles 'Inno Setup 6\ISCC.exe')
    )
    foreach ($candidato in $candidatos) {
        if ($candidato -and (Test-Path $candidato)) { return $candidato }
    }
    $noPath = Get-Command 'ISCC.exe' -ErrorAction SilentlyContinue
    if ($noPath) { return $noPath.Source }
    throw 'ISCC.exe nao encontrado. Instale o Inno Setup 6 ou informe-o no PATH.'
}

$iscc = Resolver-ISCC

if (-not (Test-Path (Join-Path $raiz 'bin\Win64\Release\CadCli.exe'))) {
    throw 'bin\Win64\Release\CadCli.exe nao encontrado. Compile a aplicacao em Release Win64 antes.'
}

if (-not (Test-Path (Join-Path $PSScriptRoot 'Firebird3.exe'))) {
    throw 'tools\Firebird3.exe nao encontrado. O instalador oficial do Firebird 3 x64 e obrigatorio.'
}

New-Item -ItemType Directory -Force -Path $DiretorioSaida | Out-Null

& $iscc $script "/DVersao=$Versao" "/O$DiretorioSaida"
if ($LASTEXITCODE -ne 0) {
    throw "ISCC.exe terminou com o codigo $LASTEXITCODE."
}

$instalador = Join-Path $DiretorioSaida 'CadCli-Setup-x64.exe'
if (-not (Test-Path $instalador)) {
    throw "O compilador nao produziu $instalador."
}

$hash = (Get-FileHash -Path $instalador -Algorithm SHA256).Hash.ToLowerInvariant()
"$hash *CadCli-Setup-x64.exe" | Out-File -FilePath "$instalador.sha256" -Encoding ascii -NoNewline

Write-Host "Instalador: $instalador"
Write-Host "SHA-256   : $hash"
