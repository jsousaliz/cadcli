# Project state

## Decisions

| ID | Decision | Rationale | Status | Date |
| --- | --- | --- | --- | --- |
| AD-001 | A aplicação possui somente alvo Win64 e distribui um único executável `CadCli.exe`, sem runtime packages | reduz a matriz de entrega e corresponde ao formato solicitado | active | 2026-09-19 |
| AD-002 | `cadcli.fdb` fica no diretório de `CadCli.exe`, que deve ser gravável pelo usuário | mantém aplicação e dados transportáveis conforme a decisão aprovada | active | 2026-09-19 |
| AD-003 | Migrações SQL são classes Delphi compiladas no executável e registradas em `SCHEMA_VERSION` | impede perda ou dessincronização de scripts externos | active | 2026-09-19 |
| AD-004 | Cada form própria possui exatamente um controlador testável por interfaces e implementa uma visão passiva | impede regras de negócio e infraestrutura em handlers VCL | active | 2026-09-19 |
| AD-005 | A base inicial contém MG, SP, RJ e BA, cada um com as três cidades enumeradas na Parte 01 | fornece referências mínimas exigidas pelos cadastros posteriores | active | 2026-09-19 |
| AD-006 | `CadCli.exe` linka `FireDAC.VCLUI.Wait`, e toda prova de inicialização de ponta a ponta executa o artefato entregue | sem o provedor de cursor de espera o FireDAC falha na primeira operação da conexão, e nenhuma prova de nível de unidade observa isso | active | 2026-09-19 |
| AD-007 | A aplicação acessa o Firebird 3 x64 como serviço local em `localhost:3050`, usando `SYSDBA`/`masterkey`; nenhuma DLL do Firebird é distribuída ao lado de `CadCli.exe` | centraliza o runtime na instalação do Firebird e elimina a distribuição do runtime Embedded com a aplicação | active | 2026-09-21 |
| AD-008 | O Inno Setup exige administrador e oferece, em checkbox marcado por padrão, a instalação silenciosa do Firebird 3 x64 como serviço; desmarcado, assume um serviço compatível já configurado | permite uma instalação completa sem impedir o uso de uma instância local existente | active | 2026-09-21 |

## Handoff

**Feature**: `parte-01-fundacao-banco`
**Where**: checks da Parte 01 recriados para o serviço local do Firebird 3 (24 checks, `validate_checks.py` exit 0)
**In progress**: `parte-01-fundacao-banco/plan.md` e `parte-05-identidade-instalador/plan.md` adaptados às decisões AD-007 e AD-008
**Next step**: adaptar testes a partir de C4, C16, C17, C20 e C22-C24, depois o código, e despachar um Verifier novo
**Blockers**: nenhum; as provas de integração exigem o serviço Firebird 3 x64 em `localhost:3050`
**Uncommitted**: documentação de planejamento e decisões globais
**Branch**: `master`

### Observações do build

- O relatório de verificação anterior registra a implementação Embedded e fica obsoleto para AD-007; uma nova verificação independente será exigida depois da adaptação.
- As provas de integração passam a exigir um serviço local do Firebird 3 disponível e configurado para o ambiente de testes.
- AD-006 registra por que `FireDAC.VCLUI.Wait` é obrigatório no executável VCL.
