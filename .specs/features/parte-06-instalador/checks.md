# Parte 06 - Instalador Win64 e release por CI checks

Profile: ui
Plan: `.specs/features/parte-06-instalador/plan.md`

28 checks em 2 slices · 4 one-way doors · 0 questões abertas (as decisões tomadas ao derivar estão em `Decisões`, revisáveis antes do build)

## Nível das provas

Esta parte entrega dois artefatos declarativos: o script Inno Setup e o workflow do GitHub Actions. As provas observam esses artefatos em dois níveis, e a distinção vale para todo check abaixo:

| Nível | O que a prova executa | Checks |
| --- | --- | --- |
| artefato compilado | `ISCC.exe` compila `tools\CadCli.iss` e a prova assere sobre o código de saída, sobre o log do compilador (linhas `Compressing: <caminho>`) e sobre o arquivo produzido | C1, C2 |
| contrato declarado | a prova lê o texto do `.iss` ou do `.yml` já compilado/versionado e assere seção, diretiva, flag ou condição literal | C3-C28 |

Decisões do usuário, tomadas antes de qualquer código e registradas como AD-020 (a gravar no build):

- Nenhuma prova executa o `CadCli-Setup-x64.exe`. `PrivilegesRequired=admin` exige um shell elevado e a execução alteraria a máquina de desenvolvimento (serviço Firebird, registro de desinstalação). A instalação, a atualização e a desinstalação reais ficam como verificação manual em sandbox, descrita no `Independent test` do plano.
- Esta parte não acrescenta nenhum teste DUnitX à suíte. Cada `Proof:` abaixo é um comando PowerShell executável, rodado a partir da raiz do repositório, cujo resultado o usuário confere contra o texto do check. A suíte das partes anteriores continua intacta e não é tocada por esta parte.

## Checks

Agrupados pelos slices do plano; a numeração corre por toda a parte.

### S1 - Pacote Inno Setup Win64 · 3 files · ~30 KB · ~8k

**C1** - `ISCC.exe tools\CadCli.iss /DVersao=9.9.9` termina com código 0 e produz exatamente um arquivo, `CadCli-Setup-x64.exe`, no diretório de saída, com tamanho maior que o de `tools\Firebird3.exe` (10.895.486 bytes) e assinatura PE válida (AC 1)
Proof: `powershell -NoProfile -File tools\CompilarInstalador.ps1 -Versao 9.9.9 ; Get-ChildItem dist\CadCli-Setup-x64.exe`

**C2** - O log do `ISCC.exe` lista como `Compressing:` exatamente o conjunto `bin\Win64\Release\CadCli.exe` + todas as `bin\Win64\Release\*.bpl` + `tools\Firebird3.exe`, nenhum arquivo com extensão `.sql`, `.fdb`, `.pas` ou `.dcu`, e nenhum caminho contendo `Win32`; o `CadCli.exe` comprimido tem cabeçalho PE `AMD64` (`$8664`) (AC 1, AC 11)
Proof: `powershell -NoProfile -File tools\CompilarInstalador.ps1 -Versao 9.9.9 | Select-String -Pattern "Compressing:"`

**C3** - O `[Setup]` declara `PrivilegesRequired=admin` e não declara `PrivilegesRequiredOverridesAllowed`, de modo que a elevação não é dispensável pelo usuário nem pela linha de comando (AC 2; door 1)
Proof: `Select-String -Path tools\CadCli.iss -Pattern "^PrivilegesRequired=admin$","PrivilegesRequiredOverridesAllowed"`

**C4** - `[Icons]` cria `{group}\CadCli` e `{group}\Desinstalar CadCli` sem condição, e cria `{autodesktop}\CadCli` apenas com `Tasks: desktopicon`; `[Tasks]` declara `desktopicon` com `Flags: unchecked` (AC 2)
Proof: `Select-String -Path tools\CadCli.iss -Pattern "^Name: \"\{group\}","^Name: \"\{autodesktop\}","desktopicon"`

**C5** - `[Tasks]` declara `instalarfirebird` com `Description: "Instalar Firebird 3"` e sem a flag `unchecked`, e nenhuma linha `[Code]` desmarca essa tarefa (AC 3, AC 6; door 3)
Proof: `Select-String -Path tools\CadCli.iss -Pattern "Name: \"instalarfirebird\""`

**C6** - Com a tarefa selecionada, o `[Code]` executa `{tmp}\Firebird3.exe` com `/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /TASKS="UseSuperServerTask,UseServiceTask,AutoStartTask,CopyFbClientToSysTask" /SYSDBAPASSWORD="masterkey"`, em `ewWaitUntilTerminated`, e nenhum outro parâmetro é passado ao instalador oficial (AC 4; door 3)
Proof: `Select-String -Path tools\CadCli.iss -Pattern "PARAMETROS_FIREBIRD","UseSuperServerTask","ewWaitUntilTerminated"`

**C7** - Quando `Exec` devolve `False` ou código de saída diferente de 0, o `[Code]` informa o erro com `SuppressibleMsgBox(..., mbCriticalError, ...)` citando o código; a falha nunca é descartada silenciosamente (AC 4; Observable: error state)
Proof: `Select-String -Path tools\CadCli.iss -Pattern "MENSAGEM_FALHA_FIREBIRD","mbCriticalError"`

**C8** - Todas as referências a `Firebird3.exe` no script estão condicionadas a `instalarfirebird` (entrada `[Files]` com `Tasks: instalarfirebird` e o `Exec` guardado por `WizardIsTaskSelected('instalarfirebird')`), e o script não contém `[UninstallRun]`, `RegWrite`, `net stop`, `instsvc` nem qualquer outra chamada que repare, reconfigure ou remova o Firebird (AC 5; door 3)
Proof: `Select-String -Path tools\CadCli.iss -Pattern "Firebird3.exe","WizardIsTaskSelected","UninstallRun","RegWrite","instsvc"`

**C9** - O `[Setup]` declara `UsedUserAreasWarning=no` e as 2 caixas de mensagem do `[Code]` são `SuppressibleMsgBox`; o script não usa `MsgBox(` nem `TaskDialogMsgBox(`, então `/VERYSILENT /SUPPRESSMSGBOXES` não abre diálogo (AC 6)
Proof: `Select-String -Path tools\CadCli.iss -Pattern "UsedUserAreasWarning=no","SuppressibleMsgBox","MsgBox\("`

**C10** - O `[Setup]` declara um `AppId` GUID fixo, `UninstallDisplayName=CadCli`, `UninstallDisplayIcon={app}\CadCli.exe` e não declara `Uninstallable=no` nem `CreateUninstallRegKey=no`, então a instalação aparece no desinstalador do Windows (AC 6)
Proof: `Select-String -Path tools\CadCli.iss -Pattern "^AppId=","^UninstallDisplay","Uninstallable","CreateUninstallRegKey"`

**C11** - `[Setup]` declara `DefaultDirName={localappdata}\Programs\CadCli` e as entradas `[Files]` com destino `{app}` são exatamente `bin\Win64\Release\CadCli.exe` e `bin\Win64\Release\*.bpl`; nenhuma entrega `fbclient.dll`, `ib_util.dll`, `icu*.dll`, `firebird.msg`, `firebird.conf`, `plugins.conf`, `*.sql` ou `*.fdb` (AC 7, AC 11; door 1)
Proof: `Select-String -Path tools\CadCli.iss -Pattern "^DefaultDirName=","^Source:","fbclient","\.sql","\.fdb"`

**C12** - Toda entrada `[Files]` com destino `{app}` usa `Flags: ignoreversion`, e o script não contém `[InstallDelete]`, `[UninstallDelete]` nem qualquer referência a `cadcli.fdb` fora da mensagem de preservação da desinstalação (AC 8; door 2)
Proof: `Select-String -Path tools\CadCli.iss -Pattern "ignoreversion","InstallDelete","UninstallDelete","cadcli.fdb"`

**C13** - `CurUninstallStepChanged` em `usPostUninstall` testa `FileExists({app}\cadcli.fdb)` e informa o caminho completo do banco preservado; nenhuma linha do script apaga esse arquivo (AC 9; door 2)
Proof: `Select-String -Path tools\CadCli.iss -Pattern "CurUninstallStepChanged","usPostUninstall","MENSAGEM_BANCO_PRESERVADO"`

**C14** - O fluxo de desinstalação não referencia `Firebird3.exe`, o desinstalador do Firebird, o serviço `FirebirdServerDefaultInstance` nem o diretório de instalação do Firebird (AC 9)
Proof: `Select-String -Path tools\CadCli.iss -Pattern "FirebirdServerDefaultInstance","unins","Firebird_3_0"`

**C15** - O `[Setup]` declara `ArchitecturesAllowed=x64compatible` e `ArchitecturesInstallIn64BitMode=x64compatible`, de modo que o Inno Setup recusa a instalação antes de copiar arquivos em sistema incompatível (AC 10; door 1)
Proof: `Select-String -Path tools\CadCli.iss -Pattern "^Architectures"`

**C16** - A entrada `[Files]` de `Firebird3.exe` tem `DestDir: "{tmp}"` e `Flags: deleteafterinstall`, e nenhuma entrada `[Files]` copia um `.exe` que não seja `CadCli.exe` para `{app}` (AC 11)
Proof: `Select-String -Path tools\CadCli.iss -Pattern "DestDir: \"\{tmp\}\"","deleteafterinstall","DestDir: \"\{app\}\""`

**C17** - O script declara `[Languages]` com `compiler:Languages\BrazilianPortuguese.isl` e os 7 textos próprios do instalador são, literalmente: `Instalar Firebird 3`, `Criar um atalho na área de trabalho`, `Banco de dados:`, `Atalhos adicionais:`, `Instalando o Firebird 3...`, `Não foi possível instalar o Firebird 3. O instalador oficial terminou com o código %1.` e `O banco de dados do CadCli foi preservado em:` (AC 2, AC 3, AC 4, AC 9; Observable: installer interactive)
Proof: `Select-String -Path tools\CadCli.iss -Pattern "BrazilianPortuguese","Description: \"","GroupDescription: \"","MENSAGEM_"`

### S2 - Workflow de release · 2 files · ~14 KB · ~4k

**C18** - `.github/workflows/criar-release.yml` tem `name: Criar release CadCli`, a chave `on:` contém somente `workflow_dispatch` (sem `push`, `pull_request`, `schedule` ou `tags`) e o job declara `runs-on: [self-hosted, Windows, X64, delphi]` (AC 12; door 4)
Proof: `Select-String -Path .github\workflows\criar-release.yml -Pattern "^name:","^on:","workflow_dispatch","runs-on","push:","schedule:"`

**C19** - `workflow_dispatch.inputs` declara exatamente 3 entradas: `versao` (`required: true`, `type: string`), `modo_notas` (`type: choice` com as opções `arquivo` e `automaticas`, `default: arquivo`) e `publicar_release` (`type: boolean`, `default: false`) (AC 12, AC 17, AC 18, AC 19)
Proof: `Select-String -Path .github\workflows\criar-release.yml -Pattern "versao:","modo_notas:","publicar_release:","type:","default:"`

**C20** - O passo de validação roda antes de qualquer passo de compilação, aplica o padrão `^\d+\.\d+\.\d+$` à versão informada, recusa explicitamente `0.0.0` e termina com `exit 1` em cada recusa (AC 13)
Proof: `Select-String -Path .github\workflows\criar-release.yml -Pattern "notmatch","0\.0\.0","exit 1"`

**C21** - O mesmo passo de validação consulta a tag `v$versao` com `git rev-parse` e termina com `exit 1` quando ela já existe (AC 13)
Proof: `Select-String -Path .github\workflows\criar-release.yml -Pattern "git rev-parse --verify"`

**C22** - Quando `modo_notas` é `arquivo`, a validação testa `docs/notas-de-versao/v$versao.md` e termina com `exit 1` se o arquivo não existir (AC 14)
Proof: `Select-String -Path .github\workflows\criar-release.yml -Pattern "notas-de-versao","Test-Path"`

**C23** - Depois da validação, o workflow chama `rsvars.bat` e `MSBuild.exe CadCli.dproj /t:Build /p:Config=Release /p:Platform=Win64` e, somente em um passo posterior, `ISCC.exe tools\CadCli.iss /DVersao=$versao`; não há passo com `Platform=Win32` (AC 15)
Proof: `Select-String -Path .github\workflows\criar-release.yml -Pattern "rsvars.bat","Platform=Win64","CompilarInstalador.ps1","Win32"`

**C24** - Todo passo `run:` em PowerShell declara `$ErrorActionPreference = 'Stop'` e verifica `$LASTEXITCODE`, nenhum passo declara `continue-on-error`, e nenhum passo de tag ou release usa `if: always()` ou `if: failure()` (AC 16)
Proof: `Select-String -Path .github\workflows\criar-release.yml -Pattern "ErrorActionPreference","LASTEXITCODE","continue-on-error","always\(\)"`

**C25** - O passo `actions/upload-artifact` envia `CadCli-Setup-x64.exe` e `CadCli-Setup-x64.exe.sha256` e não tem condição `if:` referenciando `publicar_release` (AC 17)
Proof: `Select-String -Path .github\workflows\criar-release.yml -Pattern "upload-artifact","sha256"`

**C26** - Os passos que criam a tag `v$versao` e que publicam a GitHub Release com os 2 arquivos anexados declaram `if: inputs.publicar_release` e a release recebe `--notes-file` no modo `arquivo` e `--generate-notes` no modo `automaticas` (AC 18)
Proof: `Select-String -Path .github\workflows\criar-release.yml -Pattern "git tag","gh release create","notes-file","generate-notes","publicar_release"`

**C27** - Nenhuma ocorrência de `git tag`, `git push`, `gh release create` ou `softprops/action-gh-release` aparece em passo sem a condição `inputs.publicar_release` (AC 19)
Proof: `Select-String -Path .github\workflows\criar-release.yml -Pattern "git tag","git push","gh release create","if: inputs.publicar_release" -Context 3,0`

**C28** - O job declara `if: github.ref == 'refs/heads/main' && github.actor == 'jsousaliz'`, de modo que nenhum passo executa em outro branch ou por outro ator (AC 20; door 4)
Proof: `Select-String -Path .github\workflows\criar-release.yml -Pattern "refs/heads/main","github.actor"`

## Coverage

| Set (size) | Member -> proof | Unproven |
| --- | --- | --- |
| critérios do plano (20) | AC 1 C1/C2 · AC 2 C3/C4 · AC 3 C5 · AC 4 C6/C7 · AC 5 C8 · AC 6 C5/C9/C10 · AC 7 C11 · AC 8 C12 · AC 9 C13/C14 · AC 10 C15 · AC 11 C2/C11/C16 · AC 12 C18/C19 · AC 13 C20/C21 · AC 14 C22 · AC 15 C23 · AC 16 C24 · AC 17 C25 · AC 18 C26 · AC 19 C27 · AC 20 C28 | - |
| one-way doors de `Landing` (4) | pacote Win64 C3/C11/C15 · preservação de dados C12/C13 · serviço Firebird opcional C5/C6/C8 · pipeline de build/release C18/C28 | - |
| tarefas do instalador (2) | `instalarfirebird` marcada C5 · `desktopicon` desmarcada C4 | - |
| ramos da tarefa Firebird (3) | marcada executa C6 · marcada e falha reporta C7 · desmarcada não toca C8 | - |
| seções do `.iss` asseridas (7) | `[Setup]` C3/C9/C10/C11/C15 · `[Languages]` C17 · `[Tasks]` C4/C5 · `[Files]` C2/C11/C12/C16 · `[Icons]` C4 · `[Code]` instalação C6/C7 · `[Code]` desinstalação C13/C14 | - |
| destinos de arquivo do instalador (3) | `{app}` C11/C12/C16 · `{tmp}` com `deleteafterinstall` C16 · `{group}` e `{autodesktop}` C4 | - |
| arquivos proibidos no pacote (7) | `fbclient.dll` C11 · `ib_util.dll` C11 · `icu*.dll` C11 · `firebird.conf` C11 · `*.sql` C2/C11 · `*.fdb` C2/C11 · binário Win32 C2 | - |
| inputs do workflow (3) | `versao` C19/C20/C21/C22 · `modo_notas` C19/C22/C26 · `publicar_release` C19/C25/C26/C27 | - |
| recusas da validação (4) | formato fora de `X.Y.Z` C20 · `0.0.0` C20 · tag já existente C21 · notas ausentes no modo `arquivo` C22 | - |
| guardas do job (2) | ator autorizado C28 · branch `main` C28 | - |
| desfechos de `publicar_release` (2) | `false` só artefato C25/C27 · `true` tag e release C26 | - |
| saídas do workflow (2) | `CadCli-Setup-x64.exe` C25/C26 · `CadCli-Setup-x64.exe.sha256` C25/C26 | - |
| installer interactive - textos próprios (7) | `Instalar Firebird 3` C17/C5 · `Criar um atalho na área de trabalho` C17/C4 · `Banco de dados:` C17 · `Atalhos adicionais:` C17 · `Instalando o Firebird 3...` C17 · mensagem de falha do Firebird C17/C7 · mensagem de banco preservado C17/C13 | - |
| installer interactive - arranjo (3) | tarefa Firebird antes da tarefa de atalho na página de tarefas C4/C5 · idioma pt-BR nas páginas padrão C17 · resumo da desinstalação depois da remoção (`usPostUninstall`) C13 | - |
| startup config: versão do pacote (2 lugares) | `ISCC /DVersao` nas provas locais C1 · `ISCC /DVersao=$versao` no workflow C23 | - |

- `Relations` e `Surface` são `None` no plano: nenhuma entidade nem rota exige join.
- Todas as provas desta parte leem artefatos versionados no repositório; nenhuma depende do serviço Firebird nem de rede.
- O `Observable` do plano marca `destructive action confirms` e `partial failure` como `existing`: ambos pertencem ao runtime do Inno Setup (confirmação do desinstalador e rollback de instalação incompleta) e não têm código próprio neste repositório para assertar. C13 e C14 cobrem o que é nosso na desinstalação.
- C1 e C2 são as únicas provas que compilam; as demais leem o mesmo `.iss` que o C1 compilou com sucesso, então um script quebrado fica vermelho em C1 antes de chegar às outras.

## Test policy

| Code | Required proofs | Coverage expectation |
| --- | --- | --- |
| Script declarativo compilado por ferramenta externa (`tools\CadCli.iss`) | uma prova que compila com a ferramenta real e assere sobre o artefato e o log, mais uma prova por decisão declarada no script | cada diretiva que fecha um one-way door, cada tarefa, cada destino de arquivo e cada ramo do `[Code]` |
| Manifesto declarativo não executável neste repositório (`.github/workflows/criar-release.yml`) | uma prova por gatilho, input, guarda, validação, ordem de passos e saída | cada input, cada recusa de validação, cada desfecho de `publicar_release` |
| Script PowerShell de apoio ao build (`tools\CompilarInstalador.ps1`) | nenhuma própria | coberto por C1 e C2, que o executam de ponta a ponta |

As provas são comandos, não testes automatizados: por decisão do usuário esta parte não cria fixtures DUnitX. A coluna `Required proofs` descreve o que cada comando precisa evidenciar.

Evidence:

- `tools\CadCli.iss` (novo): 2 tarefas, 3 destinos de arquivo, 2 ramos no `[Code]` de instalação e 1 no de desinstalação, 5 diretivas que fecham doors -> decide.
- `.github/workflows/criar-release.yml` (novo): 3 inputs, 4 recusas de validação, 2 guardas de job, 2 desfechos de publicação -> decide.
- `tools\CompilarInstalador.ps1` (novo): localiza o `ISCC.exe`, repassa a versão e gera o `.sha256`; nenhuma condicional decide resultado além de "ferramenta ausente" -> instrumentação.
- Closest analogue: `tests\Unitarios\Testes.EntregaRunner.pas`, que já assere sobre o artefato de entrega (cabeçalho PE, fechamento de BPLs, ausência de runtime Firebird) em vez de sobre código-fonte.

Cost: 28 checks, 28 comandos. Sem essas linhas, o `.iss` e o `.yml` seriam conferidos apenas por uma compilação que passa com qualquer conteúdo válido.

## Swept

- validation: C20, C21, C22 - formato da versão, `0.0.0`, tag existente e arquivo de notas ausente, todos antes de compilar
- failure modes: C7, C24 - falha do instalador oficial do Firebird reportada com o código; falha de qualquer passo interrompe o workflow sem publicar
- idempotency: C12, C21 - reinstalar por cima substitui binários e não toca no banco; a mesma versão não pode ser publicada duas vezes porque a tag existente é recusada
- authorization: C3, C28 - elevação administrativa exigida pelo instalador; job restrito a ator autorizado e ao branch `main`
- concurrency: n/a - o instalador é um processo único por execução e o workflow é disparado manualmente; nenhuma seção compartilha estado entre execuções simultâneas
- data lifecycle: C11, C12, C13 - o instalador nunca entrega nem remove `cadcli.fdb`; criação e migração continuam da Parte 01, e a desinstalação preserva o arquivo
- dependency failure: C7 - instalador oficial do Firebird terminando com código diferente de 0
- state transitions: C8, C26, C27 - tarefa Firebird marcada e desmarcada; `publicar_release` false (só artefato) para true (tag e release)
- observability: C7, C13, C17 - mensagens em português, com o código de saída na falha e o caminho do banco preservado; nenhum requisito de log além do log padrão do Inno Setup (`/LOG`)

## Decisões

Tomadas ao derivar os checks; nenhuma é one-way door além das já aprovadas no plano, e todas são revisáveis antes do build.

- AD-020 (a registrar no build): esta parte não acrescenta testes automatizados e nenhuma prova executa o `CadCli-Setup-x64.exe`. C1 e C2 compilam o script com o `ISCC.exe` real; C3 a C28 são comandos `Select-String` sobre o `.iss` e o `.yml` versionados. Executar o setup exigiria um shell elevado e alteraria a máquina de desenvolvimento; a instalação, a atualização e a desinstalação reais ficam como verificação manual em sandbox. Decisão do usuário, tomada antes de qualquer código.
- O instalador oficial do Firebird 3 x64 fica versionado como `tools\Firebird3.exe` (10.895.486 bytes, Firebird 3.0.13.33818 x64), escolha do usuário. O build não depende de rede.
- O `ISCC.exe` é localizado por `tools\CompilarInstalador.ps1`, que procura `%LOCALAPPDATA%\Programs\Inno Setup 6`, `%ProgramFiles(x86)%\Inno Setup 6` e o `PATH`, nessa ordem. Ferramenta ausente é falha da prova, não teste ignorado.
- A saída do instalador vai para `dist\`, ignorado pelo git, para não misturar o pacote com o diretório de entrega `bin\Win64\Release`.
- A execução do instalador oficial do Firebird fica no `[Code]`, e não em `[Run]`, porque o `[Run]` do Inno Setup descarta o código de saída e o `Observable` do plano exige a propagação da falha (C7).
- O ator autorizado no `if:` do job é `jsousaliz`, dono do remoto `https://github.com/jsousaliz/cadcli.git`.
- A versão do pacote entra por `/DVersao`; sem o define, o `.iss` usa `0.0.0`, que é exatamente o valor que o workflow recusa (C20).
- O manifesto do `SetupLdr` do Inno Setup 6.7.3 declara `requestedExecutionLevel level="asInvoker"` e a elevação é pedida em tempo de execução; por isso C3 assere `PrivilegesRequired=admin` no script, e não o manifesto do executável compilado.

## Handoff

- Arquivos existentes tocados (`wc -c`): `tools\README.md` 0,5 KB + `.gitignore` 0,4 KB + `.specs\STATE.md` 15,4 KB + `README.md` 12,5 KB = 28,8 KB; analogues lidos (`Testes.EntregaRunner.pas` 9,0 KB, `Suporte.ProcessoAplicacao.pas` 6,6 KB, `CopiarBplsEntrega.ps1` 3,6 KB) = 19,2 KB; novos estimados ~15 KB (`CadCli.iss` 6, `CompilarInstalador.ps1` 3, `criar-release.yml` 6); total ~79 KB / 4 = ~20k tokens, abaixo do budget de 150k - one builder.
- S1 ~8k entra em `tools\`; S2 ~4k acrescenta `.github\workflows\`; nenhum corte faz sentido.
- Mechanism: one builder - o escopo cabe no orçamento.
- Branch: `feat/parte-06-instalador`.
- Pré-requisitos: Inno Setup 6.7.3 em `%LOCALAPPDATA%\Programs\Inno Setup 6`; `bin\Win64\Release\CadCli.exe` e as BPLs presentes (build Release da Parte 05); `tools\Firebird3.exe` versionado. Nenhuma prova desta parte precisa do serviço Firebird nem de rede.
