# Especificação de requisito para teste de desenvolvimento

Criar um sistema em Delphi para controle de clientes:

## Item 1

Criar uma tela principal (Nesta tela principal use sua criatividade).

- Inserir um menu, contendo 3 (três) itens horizontais ("Sistema", "Cadastros," Relatórios").
  1. Para o item de menu "Sistema", inserir o submenu "Sair", que ao ser clicado irá fechar o sistema.
  2. Para o item de menu "Cadastros", inserir o submenu "Cliente", que ao ser clicado irá abrir a tela de cadastro de cliente.
  3. Para o item de menu "Relatórios", inserir o submenu "Relatório", que ao ser clicado irá abrir o relatório de cliente conforme especificação abaixo:

## Item 2

Criar a rotina de cadastro de cliente, em que o usuário consiga realizar as seguinte ações:

- Inserção de clientes;
- Alteração de clientes;
- Exclusão de clientes;
- Pesquisa de clientes.

A rotina de cadastro de clientes obrigatoriamente deverá conter os campos especificados no item abaixo:

### Requisitos obrigatórios

- Os campos e suas características deverão seguir a especificação informada abaixo (item 4);
- Tela para pesquisa dos clientes cadastrados, podendo efetuar a pesquisa pelos campos (ID, NOME, CPF ou CNPJ, CEP, CIDADE, ESTADO, DATANASCIMENTO);
- Criar a validação de exclusão, se os id's estiverem dentro dos números (1, 5, 8, 10, 15), não poderão ser excluídos;
- Utilizar Firedac para conexão com o banco de dados;
- Quando o usuário digitar o CEP e mudar de campo, consultar o CEP na api viacep, caso seja inválido alertar ao usuário, caso seja valido, preencher o endereço, bairro e a cidade/estado;
- Utilizar o enter como tab (mudar de campo ao pressionar enter);
- Outras validações de campos ficarão a critério do candidato (e poderão ser vistas como diferencial);
- Utilizar IDE Delphi 12.0 ou 10.3;
- Utilizar componentes visuais DevExpress;

### Requisitos opcionais

- Arquitetura MVC;
- Utilizar orientação a objetos;
- Utilizar transação;
- Sinta-se à vontade para implementar além do solicitado. Tais questões poderão ser vistas como diferenciais.

## Item 3

Criar um relatório utilizando o componente ReportBuilder para listar os clientes.

Filtros:

- Id Inicial e Id Final;
- Cidade/Estado;
- Todos.

Campos para listar no relatório:
ID, NOME, CPF ou CNPJ, CEP, BAIRRO, CIDADE, ESTADO);

## Outros requisitos obrigatórios

### 4 - Especificações de banco de dados

- Criar um banco de dados no firebird 3.0
- Criar a tabela CLIENTE com os seguintes campos:

| CAMPO          | TIPO         |
| -------------- | ------------ |
| PK - ID        | INTEGER      |
| NOME           | VARCHAR(80)  |
| CEP            | CHAR(8)      |
| CPF_CNPJ       | VARCHAR(14)  |
| ENDERECO       | VARCHAR(100) |
| NUMERO         | VARCHAR(20)  |
| COMPLEMENTO    | VARCHAR(60)  |
| BAIRRO         | VARCHAR(100) |
| FK - CIDADE    | INTEGER      |
| DATANASCIMENTO | DATE         |

- Criar a tabela ESTADO e inserir diretamente via banco ("Minas Gerais", "São Paulo", "Rio de Janeiro", "Bahia")

| CAMPO   | TIPO        |
| ------- | ----------- |
| PK - ID | INTEGER     |
| NOME    | VARCHAR(50) |
| UF      | CHAR(2)     |

- Criar a tabela CIDADE e inserir algumas cidades utilizando os 4 estados acima

| CAMPO         | TIPO        |
| ------------- | ----------- |
| PK - ID       | INTEGER     |
| NOME          | VARCHAR(50) |
| FK - ESTADOID | INTEGER     |

## Entregas esperadas

- Todo o código fonte da aplicação;
- Banco de dados da aplicação;
- Arquivos necessários para execução da aplicação (.exe, .dll, e outros);
- Outros documentos e ou arquivos que o candidato julgar interessante e importante.
