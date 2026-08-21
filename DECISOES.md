# Decisões — Atividade 01

## DECISÃO 01 — Tipo de `valor`

Escolhi double para manter o campo diretamente numérico e facilitar agregações. No teste, porém, uma consulta que leu a coluna falhou com BAD_DATA ao encontrar o valor "8,43", pois a vírgula decimal não é aceita pelo tipo double. Aceito essa limitação nesta camada e registro que esses dados precisarão ser normalizados pelo produtor ou em uma etapa anterior à consulta.

## DECISÃO 02 — Tipo das colunas de tempo

Escolhemos timestamp. Testamos as colunas data_corrida e fim no Athena e o SELECT devolveu corretamente os valores de data e hora, em vez de null. Assim, mantivemos o tipo temporal, que permite operações e filtros de tempo diretamente, sem exigir conversão posterior.

## DECISÃO 03 — `ignore.malformed.json`

Escolhemos true: preferimos que a consulta responda com nulls a derrubar o painel inteiro.

## DECISÃO 04 — Partições

Escolhemos declarar três partições: anteontem, ontem e hoje, que é o mínimo exigido pelo exercício. As outras 27 continuam armazenadas no S3, mas não são visíveis para consultas pelo Glue/Athena porque não foram registradas no catálogo. No dia seguinte, uma nova partição também precisaria ser registrada manualmente ou por uma futura orquestração.

## DECISÃO 05 — Teto de bytes por consulta

Escolhemos o teto de 10.485.760 bytes. O conjunto completo medido possui 117.655.606 bytes, a maior partição possui 3.922.560 bytes e a partição de hoje possui 3.921.495 bytes. Assim, a consulta filtrada por uma partição fica abaixo do teto, enquanto a consulta ampla deve ser interrompida.