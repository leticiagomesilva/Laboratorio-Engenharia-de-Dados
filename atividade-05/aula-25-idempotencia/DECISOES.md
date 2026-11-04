# DECISOES.md — Exercício 05 · grupo: grupo03

## DECISÃO 01 — modo de escrita (`modo_escrita`)

Escolhemos `sobrescrever` para evitar duplicações entre execuções, aceitando o custo de reescrever as partições processadas. Após duas execuções, a tabela permaneceu com **518.400 linhas**.

## DECISÃO 02 — a chave da linha (`chave_dedup`)

Escolhemos `corrida_id` para identificar corridas repetidas, aceitando o processamento adicional da deduplicação. O job removeu **17.280 duplicatas**, mantendo **518.400 linhas para 518.400 corridas distintas**.

## DECISÃO 03 — janela de atraso (`janela_atraso_dias`)

Escolhemos **3 dias**, aceitando o processamento de uma janela maior para recuperar dados atrasados. A madrugada dos últimos 7 dias apresentou **11.137 corridas**, incluindo **1.591 corridas atrasadas**. A janela considera o dia da chegada e os 3 dias anteriores, totalizando 4 dias possíveis.

## DECISÃO 04 — o backfill

Se uma corrida chegar com mais de 3 dias de atraso, utilizaremos o comando `./rodar-job.sh DIAS=AAAA-MM-DD`, informando a data do evento. O processamento reescreve **1 partição diária**, sem duplicar registros, pois utiliza o modo `sobrescrever` e a chave `corrida_id`.

A tabela apresentou **518.400 linhas** na verificação geral. O backfill específico não foi executado, portanto esse total não constitui uma medição após backfill.