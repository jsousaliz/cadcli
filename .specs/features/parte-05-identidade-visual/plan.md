# Parte 05 - Identidade visual: ícones de ação e ícone do produto

## Problem

As forms de cliente usam apenas texto nos botões e `CadCli.exe` usa o ícone padrão
do Delphi. Falta a arte própria e o lugar onde ela será encaixada.

A arte dos ícones de ação é criada aqui, mas a inserção de cada SVG no
`TcxImageList` é manual: o componente serializa as imagens como blob binário no
`.dfm`, algo que não se gera fora da IDE. O ícone do produto é diferente - o
`.dproj` referencia o `.ico` por caminho em texto, então aqui ele é gerado e
também atribuído ao projeto.

## Flow

1. botões de ação das três forms de cliente (exists) -> `TcxImageList` vazio e
   unit de índices nomeados (new, door 1)
2. índice reservado -> `OptionsImage.Images`/`OptionsImage.ImageIndex` de cada
   botão (new, door 2)
3. nove ações -> nove SVGs próprios em `assets/icones-acao/` (new, door 3)
4. domínio de clientes -> `assets/marca/cadcli.svg` e `assets/marca/CadCli.ico`
   atribuído ao `.dproj` (new, door 4)

## Impact

| Front | What changes |
| --- | --- |
| domain | nothing |
| stored data | nothing |
| UI | os nove botões ganham `OptionsImage.Images`/`OptionsImage.ImageIndex`; nenhum ícone aparece até a inserção manual; `Caption` preservado |
| distribuição | `CadCli.exe` compila com o ícone de marca próprio |
| repositório | ganha `assets/` (SVGs de ação, marca, `CadCli.ico`, `README.md`) |

## Landing

| One-way door | Literal shape |
| --- | --- |
| 1. lista e índices | um único `TcxImageList` `ListaIconesAcao` no data module `Visao.ModuloIconesAcao`, criado no `.dpr` antes da interface; nove índices fixos reservados, 0 a 8, na ordem incluir, editar, excluir, pesquisar, limpar, salvar, cancelar, relatório e fechar; a lista nasce vazia |
| 2. vínculo botão -> índice | `BotaoNovo` 0, `BotaoEditar` 1, `BotaoExcluir` 2, `BotaoPesquisar` 3, `BotaoLimpar` 4 (`Visao.FormPesquisaCliente`); `BotaoSalvar` 5, `BotaoCancelar` 6 (`Visao.FormCadastroCliente`); `BotaoVisualizar` 7, `BotaoFechar` 8 (`Visao.FormFiltroRelatorioCliente`) |
| 3. ícones de ação | nove SVGs próprios em `assets/icones-acao/`, nomeados pela ação correspondente em minúsculas, `viewBox 0 0 24 24`, traço uniforme, sem texto |
| 4. ícone do produto | `assets/marca/cadcli.svg` (silhueta de clientes) e `assets/marca/CadCli.ico` com 16, 32, 48, 64 e 256 px, atribuído por `Icon_MainIcon` no `CadCli.dproj` |

## Criteria

### S1: Índices reservados e botões vinculados (P1)

1. WHEN o projeto for compilado THEN o sistema SHALL conter exatamente um
   `TcxImageList` de ícones de ação, com `Count = 0`, e nenhum índice de botão
   repetido ou fora da faixa 0 a 8.
2. WHEN cada uma das três forms for aberta THEN seus botões SHALL ter
   `OptionsImage.Images` apontando para `ListaIconesAcao` e
   `OptionsImage.ImageIndex` igual ao índice da sua ação, mantendo o `Caption`.
3. WHILE a lista estiver vazia THEN as três forms SHALL abrir e operar
   normalmente, sem erro de índice inválido.

### S2: Arte-fonte dos ícones de ação (P2)

4. WHEN os recursos forem gerados THEN o repositório SHALL conter os nove SVGs em
   `assets/icones-acao/` com `viewBox="0 0 24 24"`, traço uniforme e sem texto.
5. WHEN os recursos forem auditados THEN `assets/README.md` SHALL declarar autoria
   do projeto, sem dependência de licença externa.
6. WHEN a divisão for concluída THEN `assets/README.md` SHALL listar, em ordem,
   índice -> ação -> SVG -> form/botão.

### S3: Ícone do produto (P1)

7. WHEN os recursos forem gerados THEN o repositório SHALL conter
   `assets/marca/cadcli.svg` e `assets/marca/CadCli.ico` com 16, 32, 48, 64 e
   256 px derivados dessa marca.
8. WHEN o projeto for compilado THEN `CadCli.exe` SHALL carregar esse ícone pelo
   `Icon_MainIcon` do `CadCli.dproj`.

## Out of scope

| Excluded | Why |
| --- | --- |
| inserção dos SVGs no `TcxImageList` | manual, feita na IDE; o blob do `.dfm` não é gerável fora dela |
| verificação em 100%, 150% e 200% | sem imagem inserida não há nada a escalar |
| item de menu `ItemSair` | `TdxBarButton`, mecanismo de imagem diferente |
| instalador e pipeline de release | parte 06, que consome `assets/marca/CadCli.ico` |

## Assumptions

| Assumption | Chosen default | Rationale |
| --- | --- | --- |
| componente da lista | `TcxImageList` | `TcxImageCollection` não é `TCustomImageList` e não pode ir em `OptionsImage.Images` (AD-019) |
| hospedagem da lista | data module `Visao.ModuloIconesAcao` criado no `.dpr` | uma única lista compartilhada pelas três forms, resolvida por referência global no `.dfm` |
| ordem dos índices | sequência fixa de 0 a 8, uma ação por índice | reordenar depois quebraria botões já vinculados |
| conceito da marca | silhueta de pessoas, sem texto | alinha a identidade ao cadastro de clientes |

## Sources

- [Teste Programador Delphi 2026.md](../../Teste%20Programador%20Delphi%202026.md)
- `C:\Program Files (x86)\DevExpress\VCL\Library\RS29\cxImageList.hpp`,
  `cxButtons.hpp` - hierarquia real de `TcxImageList` e `TcxButton.OptionsImage`.
