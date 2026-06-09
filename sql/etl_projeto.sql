--Quantidade de transaçoes historicas (vida, D7,D14,D28,D56);
--dia desde a ultima transação
--idade na base
--produto mais usasdo (vida, D7,D14,D28,D56)
--saldo de pontos atual
--pontos acumulados positivos (vida, D7,D14,D28,D56)
--pontos acumulados negativos (vida, D7,D14,D28,D56)
--dia da semana mais ativo (D28)
--periodo mais ativo (d28)
--Engajamento em D28 versus vida

WITH tb_transacoes AS (

        SELECT IdTransacao,
                idCliente,
                QtdePontos,
                datetime(substr(DtCriacao,1,19)) AS dtCriacao,
                julianday('now') - julianday(substr(DtCriacao,1,10)) AS diffData,
                CAST(strftime('%H', substr(DtCriacao,1,19)) AS INT) AS dtHora
        FROM transacoes
),
tb_cliente AS (

        SELECT 
                idCliente,
                datetime(substr(DtCriacao,1,19)) AS dtCriacao,
                julianday('now') - julianday(substr(DtCriacao,1,10)) AS idade_base
        FROM clientes
),
tb_sumario_transacoes AS (

        SELECT  idCliente,
                count(IdTransacao) AS qtdTransacaoVida,
                count(CASE WHEN diffData <=7 THEN IdTransacao END) AS qtdTransacaoD7,
                count(CASE WHEN diffData <=14 THEN IdTransacao END) AS qtdTransacaoD14,
                count(CASE WHEN diffData <=28 THEN IdTransacao END) AS qtdTransacaoD28,
                count(CASE WHEN diffData <=56 THEN IdTransacao END) AS qtdTransacaoD56,
               
                SUM(qtdePontos) AS saldoPontos,

                MIN(diffData) AS Dia_ult_interacao,

                SUM(CASE WHEN qtdePontos > 0 THEN qtdePontos ELSE 0 END) AS qtPontosPosVida,
                SUM(CASE WHEN QtdePontos > 0 AND diffData <=56 THEN qtdePontos ELSE 0 END) AS qtPontosPos56,
                SUM(CASE WHEN QtdePontos > 0 AND diffData <=28 THEN qtdePontos ELSE 0 END) AS qtPontosPos28,
                SUM(CASE WHEN QtdePontos > 0 AND diffData <=14 THEN qtdePontos ELSE 0 END) AS qtPontosPos14,
                SUM(CASE WHEN QtdePontos > 0 AND diffData <= 7 THEN qtdePontos ELSE 0 END) AS qtPontosPos7,

                SUM(CASE WHEN qtdePontos < 0 THEN qtdePontos ELSE 0 END) AS qtPontosNegVida,
                SUM(CASE WHEN QtdePontos < 0 AND diffData <=56 THEN qtdePontos ELSE 0 END) AS qtPontosNeg56,
                SUM(CASE WHEN QtdePontos < 0 AND diffData <=28 THEN qtdePontos ELSE 0 END) AS qtPontosNeg28,
                SUM(CASE WHEN QtdePontos < 0 AND diffData <=14 THEN qtdePontos ELSE 0 END) AS qtPontosNeg14,
                SUM(CASE WHEN QtdePontos < 0 AND diffData <= 7 THEN qtdePontos ELSE 0 END) AS qtPontosNeg7


        FROM tb_transacoes
        GROUP BY 1
),

tb_transacao_produto AS (

        SELECT t1.*,
                t3.DescNomeProduto,
                t3.DescCategoriaProduto

        FROM tb_transacoes AS t1

        LEFT JOIN transacao_produto AS t2
        ON t1.IdTransacao = t2.IdTransacao

        LEFT JOIN produtos AS t3
        ON t2.IdProduto = t3.IdProduto 

),

tb_cliente_produto AS (

        SELECT  idCliente,
                DescNomeProduto,
                count(*) AS qtdVida,
                count( CASE WHEN diffdata <= 56 THEN IdTransacao END) AS qtde56,
                count( CASE WHEN diffdata <= 28 THEN IdTransacao END) AS qtde28,
                count( CASE WHEN diffdata <= 14 THEN IdTransacao END) AS qtde14,
                count( CASE WHEN diffdata <= 7 THEN IdTransacao END)  AS qtde7

        FROM tb_transacao_produto

        GROUP BY 1,2
),

tb_cliente_produto_rn AS (

        SELECT *,
                row_number() OVER (PARTITION BY idCliente ORDER BY qtdVida DESC) AS rn_vida,
                row_number() OVER (PARTITION BY idCliente ORDER BY qtde56 DESC) AS rn_56,
                row_number() OVER (PARTITION BY idCliente ORDER BY qtde28 DESC) AS rn_28,
                row_number() OVER (PARTITION BY idCliente ORDER BY qtde14 DESC) AS rn_14,
                row_number() OVER (PARTITION BY idCliente ORDER BY qtde7 DESC)  AS  rn_7

        FROM tb_cliente_produto
),

tb_cliente_dia AS (

        SELECT idCliente,
            strftime('%w', DtCriacao) AS dtDia,
            count(*) AS qtdTransacoes
        FROM tb_transacoes
        WHERE diffdata  <= 28
        GROUP BY 1,2
),

tb_cliente_dia_rn AS (
        SELECT *,
            row_number() OVER (PARTITION BY idCliente ORDER BY qtdTransacoes DESC) AS rn 
        FROM tb_cliente_dia
),


tb_cliente_periodo AS (

        SELECT 
            idCliente,
            dtHora,
            CASE 
                    WHEN dtHora BETWEEN 7 AND 12 THEN 'MANHÃ'
                    WHEN dtHora BETWEEN 13 AND 18 THEN 'TARDE'
                    WHEN dtHora BETWEEN 19 AND 23 THEN 'NOITE'
                    ELSE 'MADRUGADA'
                    END AS periodo,
                    count(*) AS qtdeTransacao


        FROM tb_transacoes
        WHERE diffData <= 28
        GROUP BY 1,2
),

tb_cliente_periodo_rn AS (

        SELECT *,
                ROW_NUMBER() OVER( PARTITION BY idCliente ORDER BY qtdeTransacao DESC) AS rn_periodo
        FROM tb_cliente_periodo
),

tb_join AS (

        SELECT t1.*,
        t2.idade_base,
        t3.DescNomeProduto AS produtoVida,
        t4.DescNomeProduto AS produto56,
        t5.DescNomeProduto AS produto28,
        t6.DescNomeProduto AS produto14,
        t7.DescNomeProduto AS produto7,
        COALESCE(t8.dtDia, -1) AS dtDia,
        COALESCE(t9.periodo, 'SEM INFORMAÇÃO') AS periodomaistransacao28

        FROM tb_sumario_transacoes AS t1

        LEFT JOIN tb_cliente AS t2 
        ON t1.idCliente = t2.idCliente

        LEFT JOIN tb_cliente_produto_rn AS t3
        ON t1.idCliente = t3.idCliente
        AND t3.rn_vida = 1

        LEFT JOIN tb_cliente_produto_rn AS t4
        ON t1.idCliente = t4.idCliente
        AND t4.rn_56 = 1

        LEFT JOIN tb_cliente_produto_rn AS t5
        ON t1.idCliente = t5.idCliente
        AND t5.rn_28 = 1

        LEFT JOIN tb_cliente_produto_rn AS t6
        ON t1.idCliente = t6.idCliente
        AND t6.rn_14 = 1

        LEFT JOIN tb_cliente_produto_rn AS t7
        ON t1.idCliente = t7.idCliente
        AND t7.rn_7 = 1

        LEFT JOIN tb_cliente_dia_rn AS t8
        ON t1.idCliente = t8.idCliente
        AND t8.rn = 1

        LEFT JOIN tb_cliente_periodo_rn AS t9
        ON t1.idCliente = t9.idCliente
        AND t9.rn_periodo = 1

)

SELECT *,
        1.* qtdTransacaoD28 / qtdTransacaoVida AS engajamento28Vida
FROM tb_join