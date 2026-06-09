# Pipeline de ETL e Análise de Comportamento de Clientes (SQL)

## 📌 Visão Geral do Projeto
Este projeto consiste no desenvolvimento de uma pipeline de transformação de dados (ETL) utilizando **SQL (SQLite)** para consolidar dados transacionais e gerar uma tabela analítica de perfil e engajamento de clientes (*Feature Store*). 

O objetivo principal é transformar dados brutos de transações, produtos e clientes em indicadores de negócio estruturados para dar suporte a análises de retenção (Churn), segmentação de clientes e entendimento de hábitos de consumo em diferentes janelas temporais (**Últimos 7, 14, 28 e 56 dias**).

## 🛠️ Ferramentas e Tecnologias
* **SGBD:** SQLite
* **Linguagem:** SQL (Uso avançado de CTEs, Window Functions, Funções de Data e Agregações Condicionais)
* **Origem dos Dados:** Arquivos estruturados (`.csv`)

## 📊 Modelo de Dados (Arquitetura)
O banco de dados é composto por 4 tabelas principais:
* `clientes`: Registro cadastral dos usuários e saldo de pontos.
* `produtos`: Catálogo de itens disponíveis (nome, descrição e categoria).
* `transacoes`: Histórico de eventos gerados pelos usuários (pontos acumulados/resgatados, datas e sistemas de origem).
* `transacao_produto`: Tabela de ligação que mapeia quais produtos fizeram parte de quais transações.

## ⚙️ O que o Script de ETL (`etl_projeto.sql`) faz?
A query principal constrói uma visão consolidada por cliente, calculando de forma dinâmica:
1. **Recência e Idade na Base:** Dias desde a última transação e tempo total de vida do cliente na plataforma.
2. **Volumetria Histórica e Temporal:** Total de transações na vida e recortes específicos para D7, D14, D28 e D56.
3. **Métricas de Saldo e Pontuação:** Saldo atual, além de fluxos acumulados positivos (ganhos) e negativos (gastos/resgates) divididos pelas mesmas janelas temporais.
4. **Análise de Preferências:** Identificação do produto mais consumido pelo cliente em cada período usando funções de ranking (`ROW_NUMBER()`).
5. **Comportamento e Sazonalidade:** Identificação do dia da semana e do período do dia (hora) em que o cliente é mais ativo.
6. **Métrica de Engajamento:** Comparativo de atividade recente (D28) versus o comportamento histórico (vida).

## 🚀 Como Executar o Projeto
1. Faça o clone deste repositório.
2. Certifique-se de ter um visualizador de SQLite instalado (como o *DBeaver* ou *DB Browser for SQLite*).
3. Abra o arquivo `database/database.db` para consultar as tabelas originais.
4. Execute o script `sql/etl_projeto.sql` para gerar a tabela analítica final de clientes.
