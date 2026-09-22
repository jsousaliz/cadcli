# Tools

Arquivos usados para gerar a entrega Win64 do CadCli.

| Arquivo | Papel |
| --- | --- |
| `CopiarBplsEntrega.ps1` | roda no pós-build Release do `CadCli.dproj` e copia para `bin\Win64\Release` exatamente o fechamento transitivo das BPLs importadas por `CadCli.exe` (AD-011) |
| `CadCli.iss` | script Inno Setup do instalador Win64 |
| `CompilarInstalador.ps1` | localiza o `ISCC.exe`, compila o `CadCli.iss` com a versão informada e gera o `.sha256` |
| `Firebird3.exe` | instalador oficial do Firebird 3.0.13 x64, incorporado ao setup como payload interno |

## Gerar o instalador

Compile antes a aplicação em Release Win64; o instalador empacota `bin\Win64\Release`.

```powershell
.\tools\CompilarInstalador.ps1 -Versao 1.0.0
```

A saída vai para `dist\CadCli-Setup-x64.exe`, com `dist\CadCli-Setup-x64.exe.sha256` ao lado. `dist\` é ignorado pelo git; a entrega publicada sai do workflow `Criar release CadCli`.

O instalador exige administrador, recusa sistemas não compatíveis com x64, instala em `{localappdata}\Programs\CadCli` e oferece a tarefa `Instalar Firebird 3`, marcada por padrão. Não copia DLL do Firebird, build Win32, BPL própria da aplicação, executável auxiliar nem arquivo SQL externo. Atualizações não sobrescrevem `cadcli.fdb` e a desinstalação preserva o banco, informando onde ele permaneceu.
