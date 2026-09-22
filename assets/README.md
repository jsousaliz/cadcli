# Recursos visuais do CadCli

Todos os arquivos deste diretório são arte original criada para o projeto CadCli.
Não há dependência de biblioteca de ícones externa e, portanto, nenhuma obrigação
de licença de terceiros sobre estes recursos.

## Autoria

- Autoria: projeto CadCli.
- Origem: desenhados especificamente para este repositório a partir das ações e do
  domínio de clientes do produto.

## Conteúdo

| Caminho | Papel |
| --- | --- |
| `icones-acao/*.svg` | arte-fonte dos nove ícones de ação, `viewBox 0 0 24 24`, traço uniforme e sem texto embutido |
| `marca/cadcli.svg` | marca do produto, silhueta de clientes sobre badge arredondado |
| `marca/CadCli.ico` | ícone do produto em 16, 32, 48, 64 e 256 px, derivado de `marca/cadcli.svg` |
| `marca/logo-44.png`, `marca/logo-150.png` | logos do pacote UWP/MSIX, derivados da mesma marca; usados apenas se o projeto for empacotado como MSIX |

## Uso

- Os SVGs de `icones-acao/` são inseridos manualmente no `TcxImageList`
  `ListaIconesAcao`, na ordem da tabela abaixo.
- `marca/CadCli.ico` é o ícone da aplicação, referenciado por `Icon_MainIcon` em
  `CadCli.dproj`; os logos UWP são referenciados por `UWP_DelphiLogo44` e
  `UWP_DelphiLogo150` no mesmo arquivo e não afetam o `CadCli.exe` nem o instalador.

## Ordem de inserção dos ícones de ação

O `TcxImageList` `ListaIconesAcao` vive em `src/Visao/Visao.ModuloIconesAcao.dfm`
e nasce vazio. Os botões das três forms já apontam para o índice correspondente
pelo `OptionsImage.ImageIndex`. Insira os SVGs pelo editor de imagens do
componente, na ordem abaixo, para que cada arquivo caia na posição esperada.

| Índice | Ação | Arquivo SVG | Form | Botão |
| --- | --- | --- | --- | --- |
| 0 | Incluir | `icones-acao/incluir.svg` | `Visao.FormPesquisaCliente` | `BotaoNovo` |
| 1 | Editar | `icones-acao/editar.svg` | `Visao.FormPesquisaCliente` | `BotaoEditar` |
| 2 | Excluir | `icones-acao/excluir.svg` | `Visao.FormPesquisaCliente` | `BotaoExcluir` |
| 3 | Pesquisar | `icones-acao/pesquisar.svg` | `Visao.FormPesquisaCliente` | `BotaoPesquisar` |
| 4 | Limpar | `icones-acao/limpar.svg` | `Visao.FormPesquisaCliente` | `BotaoLimpar` |
| 5 | Salvar | `icones-acao/salvar.svg` | `Visao.FormCadastroCliente` | `BotaoSalvar` |
| 6 | Cancelar | `icones-acao/cancelar.svg` | `Visao.FormCadastroCliente` | `BotaoCancelar` |
| 7 | Relatório | `icones-acao/relatorio.svg` | `Visao.FormFiltroRelatorioCliente` | `BotaoVisualizar` |
| 8 | Fechar | `icones-acao/fechar.svg` | `Visao.FormFiltroRelatorioCliente` | `BotaoFechar` |

Enquanto a lista estiver vazia, os botões continuam operando normalmente e exibem
apenas o `Caption`; nenhum índice inválido é acessado.
