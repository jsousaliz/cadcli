# Tools

Esta pasta concentrará os arquivos-fonte e scripts usados para gerar o instalador Win64 do CadCli com Inno Setup.

O instalador será implementado na Parte 05 e não deve incluir o banco `cadcli.fdb`, builds Win32, BPLs da aplicação, executáveis auxiliares ou arquivos SQL externos.

O script `CopiarBplsEntrega.ps1` roda no pós-build Release do `CadCli.dproj` e copia para `bin\Win64\Release` exatamente o fechamento transitivo das BPLs importadas por `CadCli.exe` (AD-011).
