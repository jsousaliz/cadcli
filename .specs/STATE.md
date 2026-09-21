# Project state

## Decisions

| ID | Decision | Rationale | Status | Date |
| --- | --- | --- | --- | --- |
| AD-001 | A aplicação possui somente alvo Win64 e distribui um único executável `CadCli.exe`, sem runtime packages | reduz a matriz de entrega e corresponde ao formato solicitado | superseded by AD-011 | 2026-09-19 |
| AD-002 | `cadcli.fdb` fica no diretório de `CadCli.exe`, que deve ser gravável pelo usuário | mantém aplicação e dados transportáveis conforme a decisão aprovada | active | 2026-09-19 |
| AD-003 | Migrações SQL são classes Delphi compiladas no executável e registradas em `SCHEMA_VERSION` | impede perda ou dessincronização de scripts externos | active | 2026-09-19 |
| AD-004 | Cada form própria possui exatamente um controlador testável por interfaces e implementa uma visão passiva | impede regras de negócio e infraestrutura em handlers VCL | active | 2026-09-19 |
| AD-005 | A base inicial contém MG, SP, RJ e BA, cada um com as três cidades enumeradas na Parte 01 | fornece referências mínimas exigidas pelos cadastros posteriores | active | 2026-09-19 |
| AD-006 | `CadCli.exe` linka `FireDAC.VCLUI.Wait`, e toda prova de inicialização de ponta a ponta executa o artefato entregue | sem o provedor de cursor de espera o FireDAC falha na primeira operação da conexão, e nenhuma prova de nível de unidade observa isso | active | 2026-09-19 |
| AD-007 | A aplicação acessa o Firebird 3 x64 como serviço local em `localhost:3050`, usando `SYSDBA`/`masterkey`; nenhuma DLL do Firebird é distribuída ao lado de `CadCli.exe` | centraliza o runtime na instalação do Firebird e elimina a distribuição do runtime Embedded com a aplicação | active | 2026-09-21 |
| AD-008 | O Inno Setup exige administrador e oferece, em checkbox marcado por padrão, a instalação silenciosa do Firebird 3 x64 como serviço; desmarcado, assume um serviço compatível já configurado | permite uma instalação completa sem impedir o uso de uma instância local existente | active | 2026-09-21 |
| AD-009 | As provas que executam o `CadCli.exe` com inicialização bem-sucedida fecham o shell enviando `WM_CLOSE` à janela `TFormPrincipal`; `-sem-interacao` só suprime o diálogo de erro e não pula o shell | mantém verdes as provas de executável da Parte 01 sem enfraquecer asserções e sem um modo em que AC 1 da Parte 02 deixa de valer | active | 2026-09-21 |
| AD-010 | O navegador concreto recebe um criador de tela por destino; na Parte 02 clientes e relatório ficam sem tela e falham pelo caminho de erro do shell, e as Partes 03 e 04 registram suas telas reais | evita forms provisórias com controladores descartáveis e deixa o ponto de extensão explícito para as partes seguintes | active | 2026-09-21 |
| AD-011 | A partir da Parte 02, `CadCli.exe` (alvo Win64, único executável) linka com runtime packages somente os pacotes DevExpress RS29 e os pacotes Embarcadero exigidos por eles, e a entrega leva ao lado do exe exatamente o fechamento transitivo dessas BPLs; o DevExpress usado é a instalação trial, que só fornece `.bpl`/`.dcp` (sem `.dcu` nem fontes), e o aviso de trial é aceito | sem `.dcu` o link estático falha com `F2613 Unit 'dxBar' not found`; a especificação do teste exige DevExpress e aceita "arquivos necessários para execução (.exe, .dll, e outros)"; substitui AD-001 | active | 2026-09-21 |
| AD-012 | Os artefatos `.specs` da Parte 01 não são alterados; as duas provas da Parte 01 que a Parte 02 torna falsas são reescritas pela Parte 02 e passam a ser obrigações dela: `NaoDistribuiBplNemExecutavelAuxiliar` (zero BPL -> exatamente o fechamento de AD-011) e `InicializaComFakesSemCarregarInterfaceOuAdaptadoresConcretos` (zero `.dfm` no repositório -> zero `.dfm` nas pastas da Parte 01) | a Parte 01 já foi entregue e verificada e não será reexecutada; o claim "a Parte 01 contém zero forms" continua verdadeiro e só a regra de distribuição muda, por AD-011 | active | 2026-09-21 |
| AD-013 | O aviso trial do DevExpress (`TfrmNewTrialDialog`, janela modal aberta na inicialização do pacote, antes do `begin` do programa) é fechado com `WM_CLOSE` somente pelos testes: no runner, `Suporte.AvisoTrialDevExpress` (primeira unit do `uses`) fecha o aviso do próprio processo e o runner processa mensagens antes de rodar, liberando a form do aviso; as provas de executável fecham o aviso do processo filho antes de procurar o shell ou aguardar o encerramento. O `CadCli.exe` entregue continua mostrando o aviso ao usuário | sem isso o runner e toda prova de executável travam esperando uma pessoa; nenhuma asserção muda, e a form do aviso fica em `Screen.Forms` até a próxima rodada de mensagens, o que deixaria vermelha a Parte 01 C3 | active | 2026-09-21 |

## Handoff

**Feature**: `parte-02-shell-principal`
**Where**: build concluído e verificado em `feat/parte-02-shell-principal` (35344fb..f3a79db); `verification.md` com veredito PASS no round 3 (27/27 checks, 0 membros sem prova, faltas injetadas todas mortas); C27 acrescentada com aprovação do usuário a partir do round 1; AD-013 registrada durante o build
**In progress**: nada
**Next step**: smoke test visual dos três caminhos pelo usuário (copiar `bin\Win64\Release` para outra pasta antes de executar, para não criar `cadcli.fdb` na pasta de entrega); push/PR só com autorização explícita; depois, plano da Parte 03
**Blockers**: nenhum; C21, C22 e C25 exigem o serviço Firebird 3 em `localhost:3050`
**Uncommitted**: nenhum
**Branch**: `feat/parte-02-shell-principal` (criada a partir de `feat/parte-01-firebird-servico`)
