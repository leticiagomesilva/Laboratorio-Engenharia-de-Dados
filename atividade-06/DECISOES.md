# Decisões do Exercício 06 · Grupo 03

## 01 · Acesso da Prefeitura à refined

Limitamos a Prefeitura à tabela `madrugada_bairro`, deixando futuras tabelas sujeitas a uma concessão explícita, e a consulta executada como Prefeitura retornou 11.137 corridas na madrugada dos últimos sete dias.

## 02 · Colunas da trusted visíveis à analista

Ocultamos `corrida_id`, `motorista_id` e `passageiro_id`, preservando 8 das 11 colunas de dados para investigar preço, distância, bairro e horário, e o Athena retornou 518.400 em `count(bairro)` e recusou `SELECT passageiro_id` no perfil da analista.

## 03 · Contrato da refined

Definimos a Engenharia de Dados do Grupo 03 como responsável pela tabela, atualizada após cada execução bem-sucedida do job refined, e o Glue confirmou a descrição de 142 caracteres sobre o agregado por bairro e dia das 00h00 às 05h59 UTC, com o dono e os comentários das colunas preenchidos.

## Evidência para a PR

Saída de `verificacao/verifica.sh` na AWS.

```text
OK     [0]  (elimina)  backend remoto s3, três databases (um por camada) e a refined em Parquet
PASSA  [1]  (20%)  a Prefeitura lê a refined: 11137 corridas na madrugada dos últimos 7 dias
PASSA  [2]  (25%)  a Prefeitura não lê a trusted, nem a raw, nem o S3 direto
PASSA  [3]  (15%)  a analista lê a trusted (518400 corridas) e não vê passageiro_id
PASSA  [4]  (10%)  o contrato da refined está no catálogo: descrição (142 caracteres), dono 'Engenharia de Dados do Grupo 03', comentário em toda coluna

Critérios automáticos: 70 / 70 pontos-percentuais
Falta o que o script não mede: o critério 5 (rode com --pos-destroy depois do destroy) e o DECISOES.md (20%).

evidência: sufixo=grupo03 hoje=2026-11-25 prefeitura_refined=11137 prefeitura_trusted=RECUSADO prefeitura_raw=RECUSADO prefeitura_s3=RECUSADO analista_trusted=518400 analista_passageiro=RECUSADO {"colunas_ocultas_analista":["corrida_id","motorista_id","passageiro_id"],"escopo_prefeitura":"tabela"}
```

Saídas de `terraform destroy` e `verificacao/verifica.sh --pos-destroy`.

```text
Destroy complete! Resources: 34 destroyed.
PASSA  [5]  (10%)  destroy limpo: nenhum recurso eda-a29-grupo03 sobrou
```
