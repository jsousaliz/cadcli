param(
    [Parameter(Mandatory = $true)][string]$Executavel,
    [Parameter(Mandatory = $true)][string]$Origens
)

$ErrorActionPreference = 'Stop'

function Obter-Importacoes([string]$Caminho) {
    $bytes = [System.IO.File]::ReadAllBytes($Caminho)
    $offsetPE = [BitConverter]::ToInt32($bytes, 0x3C)
    if ([BitConverter]::ToUInt32($bytes, $offsetPE) -ne 0x00004550) {
        throw "Cabeçalho PE inválido: $Caminho"
    }
    $cabecalho = $offsetPE + 4
    $quantidadeSecoes = [BitConverter]::ToUInt16($bytes, $cabecalho + 2)
    $tamanhoOpcional = [BitConverter]::ToUInt16($bytes, $cabecalho + 16)
    $opcional = $cabecalho + 20
    if ([BitConverter]::ToUInt16($bytes, $opcional) -ne 0x20B) {
        throw "Somente PE32+ (Win64) é suportado: $Caminho"
    }
    $rvaImportacoes = [BitConverter]::ToUInt32($bytes, $opcional + 112 + 8)
    $secoes = $opcional + $tamanhoOpcional
    $converter = {
        param([uint32]$Rva)
        for ($i = 0; $i -lt $quantidadeSecoes; $i++) {
            $secao = $secoes + 40 * $i
            $tamanhoVirtual = [BitConverter]::ToUInt32($bytes, $secao + 8)
            $enderecoVirtual = [BitConverter]::ToUInt32($bytes, $secao + 12)
            $tamanhoBruto = [BitConverter]::ToUInt32($bytes, $secao + 16)
            $ponteiroBruto = [BitConverter]::ToUInt32($bytes, $secao + 20)
            $extensao = [Math]::Max($tamanhoVirtual, $tamanhoBruto)
            if ($Rva -ge $enderecoVirtual -and $Rva -lt $enderecoVirtual + $extensao) {
                return [int]($Rva - $enderecoVirtual + $ponteiroBruto)
            }
        }
        throw "RVA fora das seções: $Rva"
    }
    $resultado = @()
    if ($rvaImportacoes -eq 0) { return $resultado }
    $descritor = & $converter $rvaImportacoes
    while ($true) {
        $rvaNome = [BitConverter]::ToUInt32($bytes, $descritor + 12)
        if ($rvaNome -eq 0) { break }
        $inicio = & $converter $rvaNome
        $fim = $inicio
        while ($bytes[$fim] -ne 0) { $fim++ }
        $resultado += [System.Text.Encoding]::ASCII.GetString($bytes, $inicio, $fim - $inicio)
        $descritor += 20
    }
    return $resultado
}

$diretorio = Split-Path -Parent ([System.IO.Path]::GetFullPath($Executavel))
$listaOrigens = $Origens.Split(';') | Where-Object { $_ -and (Test-Path $_) }

Get-ChildItem -Path $diretorio -Filter '*.bpl' -File | Remove-Item -Force

$pendentes = New-Object System.Collections.Queue
$visitados = @{}
foreach ($nome in (Obter-Importacoes $Executavel)) {
    if ($nome -like '*.bpl') { $pendentes.Enqueue($nome.ToLowerInvariant()) }
}

while ($pendentes.Count -gt 0) {
    $nome = $pendentes.Dequeue()
    if ($visitados.ContainsKey($nome)) { continue }
    $visitados[$nome] = $true
    $origem = $null
    foreach ($pasta in $listaOrigens) {
        $candidato = Get-ChildItem -Path $pasta -Filter $nome -File | Select-Object -First 1
        if ($candidato) { $origem = $candidato.FullName; break }
    }
    if (-not $origem) {
        Write-Error "BPL importada não encontrada nas origens: $nome"
        exit 1
    }
    $destino = Join-Path $diretorio ([System.IO.Path]::GetFileName($origem))
    Copy-Item -Path $origem -Destination $destino -Force
    foreach ($importada in (Obter-Importacoes $destino)) {
        if ($importada -like '*.bpl') { $pendentes.Enqueue($importada.ToLowerInvariant()) }
    }
}

Write-Output ("BPLs copiadas para {0}: {1}" -f $diretorio, (($visitados.Keys | Sort-Object) -join ', '))
exit 0
