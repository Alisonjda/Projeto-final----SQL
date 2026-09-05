
WITH tb_transaçao AS (

    SELECT
        IdTransacao,
        idCliente,
        qtdePontos,
        datetime(substr(DtCriacao,1,19)) AS DtCriacao,
        julianday('now') - julianday(substr(DtCriacao,1,10)) AS diffDate,
        srtftime('%H', substr(DtCriacao,1,19) AS dtHoras

    FROM transacoes
), 

    tb_cliente AS (

        SELECT
            idCliente,
            datetime(substr(DtCriacao,1,19)) AS DtCriacao,
            julianday('now') - julianday(substr(DtCriacao,1,10)) AS idadeBase

    FROM clientes

),

tb_sumario_transacao AS(


    SELECT
        idCliente,

        count(IdTransacao) AS atdtransacaoVida, 
        count(CASE WHEN diffDate <= 56 THEN IdTransacao END) AS qtransacao56,
        count(CASE WHEN diffDate <= 28 THEN IdTransacao END) AS qtransacao28,
        count(CASE WHEN diffDate <= 14 THEN IdTransacao END) AS qtransacao14,
        count(CASE WHEN diffDate <= 7 THEN IdTransacao END) AS qtransacao7,
        
        sum(qtdePontos) AS Saldopontos,

        min(diffDate) AS diasUltimaInteracao,
    
        sum(CASE  WHEN qtdePontos > 0 AND diffdate <= 56 THEN qtdePontos ELSE 0 END ) AS qtdPontospos56,
        sum(CASE  WHEN qtdePontos > 0 AND diffdate <= 28 THEN qtdePontos ELSE 0 END ) AS qtdPontospos28,
        sum(CASE  WHEN qtdePontos > 0 AND diffdate <= 14 THEN qtdePontos ELSE 0 END ) AS qtdPontospos14,
        sum(CASE WHEN qtdePontos > 0 AND diffdate <=  7 THEN qtdePontos ELSE 0 END ) AS qtdPontospos7,

        sum(CASE  WHEN qtdePontos < 0 AND diffdate <= 56 THEN qtdePontos ELSE 0 END ) AS qtdPontosNeg56,
        sum(CASE  WHEN qtdePontos < 0 AND diffdate <= 28 THEN qtdePontos ELSE 0 END ) AS qtdPontosNeg28,
        sum(CASE  WHEN qtdePontos < 0 AND diffdate <= 14 THEN qtdePontos ELSE 0 END ) AS qtdPontosNeg14,
        sum(CASE WHEN qtdePontos  < 0 AND diffdate <=  7 THEN qtdePontos ELSE 0 END ) AS qtdPontosNeg7


    FROM tb_transaçao
    GROUP BY idCliente
),

tb_transacao_produto AS (

    SELECT
        t1.*,
        t3.DescNomeProduto,
        t3.DescCategoriaProduto

    FROM tb_transaçao AS t1

    LEFT JOIN transacao_produto AS t2
    ON t1.IdTransacao = t2.IdTransacao

    LEFT JOIN produtos AS t3
    ON t2.IdProduto = t3.IdProduto
),

tb_cliente_produto AS (

    SELECT 
        idCliente,
        DescCategoriaProduto,
        count(*) AS qtdeVida,
        count(CASE WHEN diffdate <= 56 THEN IdTransacao END ) AS qtde56,
        count(CASE WHEN diffdate <= 28 THEN IdTransacao END ) AS qtde28,
        count(CASE WHEN diffdate <= 14 THEN IdTransacao END ) AS qtde14,
        count(CASE WHEN diffdate <= 7 THEN IdTransacao END ) AS qtde7


    FROM tb_transacao_produto

    GROUP BY idCliente, DescCategoriaProduto
),

tb_cliente_rn AS (

    SELECT *,
        row_number() OVER (PARTITION BY idCliente ORDER BY qtdeVida DESC ) AS rn,
        row_number() OVER (PARTITION BY idCliente ORDER BY qtde56 DESC ) AS rn56,
        row_number() OVER (PARTITION BY idCliente ORDER BY qtde28 DESC ) AS rn28,
        row_number() OVER (PARTITION BY idCliente ORDER BY qtde14 DESC ) AS rn14,
        row_number() OVER (PARTITION BY idCliente ORDER BY qtde7 DESC ) AS rn7

    
    FROM tb_cliente_produto
),


tb_cliente_dia AS (

    SELECT 
        idCliente,
        strftime('%w', substr(DtCriacao,1,10)) AS dtdia,
        count(*) AS qttransacao
    FROM tb_transaçao

    WHERE diffdate <= 28
    GROUP BY idCliente, dtdia
),

tb_cliente_dia_rn AS (

SELECT *,
    ROW_NUMBER() OVER (PARTITION BY idCliente ORDER BY qttransacao DESC ) AS rndia

FROM tb_cliente_dia
),
tb_cliente_periodo AS (

    SELECT 
        idCliente,
        CASE
            WHEN dtHoras BETWEEN 7 AND 12 THEN 'Manhã'
            WHEN dtHoras BETWEEN 13 AND 18 THEN 'Tarde' 
            WHEN dtHoras BETWEEN 19 AND 22 THEN 'noite' 
        END AS periodo, 
        count(*) AS qtdeperiodo

    FROM tb_transaçao
    GROUP BY 1,2
),

tb_join AS (

    SELECT
        t1.*,
        t2.idadeBase,
        t3.DescCategoriaProduto AS produtoVida,
        t4.DescCategoriaProduto AS produto56,
        t5.DescCategoriaProduto AS produto28,
        t6.DescCategoriaProduto AS produto14,
        t7.DescCategoriaProduto AS produto7,
        COALESCE(t8.dtdia, -1) AS dtdia
 



    FROM tb_sumario_transacao AS t1

    LEFT JOIN tb_cliente AS t2
    ON t1.idCliente = t2.idCliente

    LEFT JOIN tb_cliente_rn AS t3
    ON t1.idCliente = t3.idCliente 
    AND t3.rn = 1

    LEFT JOIN tb_cliente_rn AS t4
    ON t1.idCliente = t4.idCliente
    AND t4.rn56 = 1

    LEFT JOIN tb_cliente_rn AS t5
    ON t1.idCliente = t5.idCliente
    AND t5.rn28 = 1

    LEFT JOIN tb_cliente_rn AS t6
    ON t1.idCliente = t6.idCliente
    AND t6.rn14 = 1

    LEFT JOIN tb_cliente_rn AS t7
    ON t1.idCliente = t7.idCliente
    AND t7.rn7 = 1

    LEFT JOIN tb_cliente_dia_rn AS t8
    ON t1.idCliente = t8.idCliente
    AND t8.rndia = 1
)

SELECT *

FROM tb_join







