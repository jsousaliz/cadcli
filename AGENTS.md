# AGENTS.md

Este arquivo contém as regras gerais do projeto CadCli. Ele se aplica a todo o repositório. Requisitos funcionais específicos permanecem nos planos em `.specs/features/` e não devem ser duplicados aqui.

## Idioma

- Escreva em português o código pertencente ao projeto: nomes de classes, interfaces, métodos, propriedades, variáveis, constantes, testes e documentação.
- Escreva em português os textos apresentados ao usuário, incluindo títulos, rótulos, confirmações e mensagens de erro.
- Preserve os nomes oficiais de bibliotecas, componentes, APIs, protocolos, formatos e símbolos externos, como FireDAC, Firebird, DevExpress, ReportBuilder, ViaCEP, DUnitX, `TFDConnection` e `TppReport`.
- Use termos de domínio consistentes com os planos: `Cliente`, `Cidade`, `Estado`, `Migracao`, `Controlador`, `Repositorio` e `Visao`.
- Não traduza nomes impostos por contratos externos ou pelo esquema obrigatório do banco de dados.

## Plataforma e entrega

- Use Delphi 12 e VCL.
- Mantenha somente o alvo Win64. Não crie configuração Win32.
- A aplicação distribuída deve possuir um único executável: `CadCli.exe`.
- Linke com runtime packages somente os pacotes DevExpress e os pacotes Embarcadero exigidos por eles; todo o restante é linkado estaticamente (AD-011).
- Distribua ao lado de `CadCli.exe` exatamente o fechamento transitivo das BPLs importadas por ele, nem mais nem menos; o executável deve abrir sem Delphi nem DevExpress no `PATH`.
- Não crie pacotes próprios da aplicação; nenhuma BPL `CadCli*` é produzida ou distribuída.
- O Firebird 3 x64 deve operar como serviço local instalado no Windows; não distribua DLLs do Firebird ao lado de `CadCli.exe`.
- A biblioteca cliente usada pelo FireDAC deve ser fornecida pela instalação do Firebird e estar acessível no sistema.
- Use componentes visuais DevExpress nas forms.
- Use ReportBuilder exclusivamente por meio do adaptador de relatório do projeto.
- Use Inno Setup para produzir o instalador Win64.

## Arquitetura de interface

- Toda form própria deve possuir exatamente um controlador correspondente.
- Nomeie o par como `TForm<Finalidade>` e `TControlador<Finalidade>`.
- A form deve implementar uma interface de visão, nomeada `IVisao<Finalidade>`.
- Forms são views passivas: eventos apenas coletam dados visuais, chamam o controlador e refletem o estado devolvido.
- Não coloque regras de negócio, SQL, transações, chamadas HTTP ou criação de outras forms em handlers da interface.
- Controladores não devem depender de classes VCL concretas, FireDAC, DevExpress, ReportBuilder ou clientes HTTP concretos.
- Injete no controlador suas dependências por interfaces.
- Isole a criação e abertura de forms atrás de uma interface de navegação.
- Isole componentes comerciais e serviços externos atrás de adaptadores próprios.

## Domínio e aplicação

- Mantenha regras de negócio fora da camada visual e da infraestrutura.
- Modele resultados esperados e falhas conhecidas de forma explícita; não use mensagens de exceção de infraestrutura como regra de domínio.
- Centralize validações reutilizáveis para evitar comportamentos diferentes entre cadastro, pesquisa e relatório.
- Use um relógio injetável quando uma regra depender da data ou hora atual.
- Não introduza uma nova dependência de produção sem necessidade demonstrada e compatibilidade com Delphi 12/Win64.

## Persistência

- Use FireDAC para todo acesso ao serviço local do Firebird 3 x64 em `localhost:3050`.
- Armazene a base no mesmo diretório de `CadCli.exe`, com o nome `cadcli.fdb`; resolva o caminho a partir de `ExtractFilePath(ParamStr(0))`.
- Garanta que o diretório de instalação seja gravável pelo usuário atual e pelo serviço do Firebird, pois a aplicação cria e atualiza o banco ao lado do executável.
- Use `SYSDBA`/`masterkey` para a conexão local assumida pelo produto e nunca registre essas credenciais ou a string de conexão completa.
- Use SQL parametrizado para toda entrada variável. Nunca monte SQL por concatenação de valores fornecidos pelo usuário.
- Centralize o acesso a dados em repositórios; forms e controladores não executam SQL diretamente.
- Use transações explícitas nas operações de escrita que precisem ser atômicas.
- Use sequências Firebird para gerar identificadores. Não use `MAX(ID) + 1`.
- Não registre credenciais, strings de conexão completas ou dados sensíveis em mensagens e logs.

## Migrações do banco

- Mantenha as migrações no código Delphi, compiladas dentro de `CadCli.exe`. Não distribua arquivos `.sql` externos.
- Crie uma unit por versão no formato `Migracao.VNNN.Descricao.pas`.
- Cada unit deve fornecer uma classe `TMigracaoNNNDescricao` que implemente `IMigracaoBanco`.
- Registre todas as migrações no `TCatalogoMigracoes` e execute-as em ordem numérica crescente.
- A aplicação deve criar a base limpa quando ela não existir e aplicar o mesmo histórico usado para atualizar bases existentes.
- Execute cada migração e o registro correspondente em `SCHEMA_VERSION` na mesma transação.
- Em caso de falha, faça rollback e não registre a versão.
- Migrações publicadas são imutáveis. Corrija uma migração publicada criando uma nova versão.
- Só consolide uma baseline quando a versão mínima de banco ainda suportada for elevada formalmente.
- Recuse a abertura de uma base cuja versão seja mais nova que a suportada pelo executável.

## Integrações externas

- Coloque cada serviço externo atrás de uma interface, como `IServicoViaCep`.
- Defina timeout e traduza respostas, indisponibilidade e erros de transporte para resultados compreendidos pela aplicação.
- Testes unitários não devem acessar serviços externos reais.
- Preserve os dados digitados pelo usuário quando uma integração externa falhar.

## Testes

- Use DUnitX e mantenha o runner de testes em Win64.
- Controladores devem ser testáveis sem criar forms reais.
- Use fakes ou stubs para views, navegação, repositórios, transações, relógio, relatórios e serviços externos.
- Cubra caminhos de sucesso, validação, cancelamento, falha e rollback.
- Testes de persistência devem usar uma base temporária e isolada.
- Testes devem ser determinísticos e independentes de rede externa, relógio real, ordem de execução e dados deixados por outra execução; testes de persistência podem usar o serviço local do Firebird 3 configurado para o ambiente de testes.
- Não enfraqueça asserções, remova testes ou ignore falhas para obter uma execução verde.
- Não declare uma verificação concluída sem executar o comando ou teste correspondente e conferir seu código de saída.

## Interface e recursos visuais

- Mantenha rótulos ou hints textuais mesmo quando uma ação possuir ícone.
- Use SVGs próprios por meio de `TcxImageCollection` para os ícones de ação.
- Preserve os arquivos-fonte dos ícones e registre sua autoria em `assets/README.md`.
- Verifique os recursos visuais em escalas de 100%, 150% e 200%.
- Confirmações destrutivas devem identificar claramente o registro ou dado afetado.

## Instalador

- O instalador deve ser produzido pelo Inno Setup para sistemas x64 compatíveis.
- O instalador deve solicitar elevação administrativa.
- Inclua no setup o instalador oficial do Firebird 3 x64 e ofereça sua execução por um checkbox marcado por padrão.
- Quando o checkbox estiver marcado, instale e inicie silenciosamente o Firebird como serviço local; quando estiver desmarcado, assuma que um serviço compatível já está instalado e configurado.
- Instale `CadCli.exe` sem copiar DLLs do Firebird para o diretório da aplicação.
- Não inclua build Win32, executável helper, BPL própria da aplicação ou arquivo SQL externo; inclua as BPLs DevExpress e Embarcadero distribuídas ao lado de `CadCli.exe` (AD-011).
- Atualizações não podem sobrescrever o banco do usuário.
- A desinstalação deve preservar `<diretório do CadCli.exe>\cadcli.fdb` por padrão.
- O instalador e o executável devem usar o ICO multirresolução definido pelo projeto.

## Organização e estilo Delphi

- Siga as convenções Delphi: prefixo `T` para tipos/classes, `I` para interfaces e `E` para exceções próprias.
- Use nomes que expressem responsabilidade; evite abreviações não consagradas.
- Mantenha units coesas e dependências direcionadas do domínio para abstrações, nunca para a interface visual.
- Gerencie ownership explicitamente e libere objetos com `try..finally` quando não houver ownership de componente ou interface.
- Evite estado global mutável e componentes de dados globais usados como atalho entre camadas.
- Extraia constantes para limites, mensagens estáveis e conjuntos de regras; não espalhe números mágicos.
- Não escreva comentários no código. Expresse a intenção por meio de nomes, tipos e estrutura; registre decisões e contexto na documentação do projeto.
- Preserve a codificação UTF-8 dos arquivos de texto.
- Salve todo arquivo-fonte Delphi (`.pas`, `.dpr`, `.dpk`, `.inc`) em UTF-8 **com BOM**. Sem BOM, o compilador lê o fonte como ANSI (Windows-1252) e corrompe acentos em mensagens e dados gravados no banco (`ã` vira `Ã£`). Ao criar ou reescrever um fonte, confirme que os três primeiros bytes são `EF BB BF`.

## tlc-spec-lean

profile: ui
budget: 150k
