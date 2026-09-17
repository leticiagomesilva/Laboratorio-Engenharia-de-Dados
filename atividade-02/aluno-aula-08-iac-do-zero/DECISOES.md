# DECISOES.md — Exercício 02 (Aula 08)

Grupo: `eda-grupo03` · Região: `us-east-1` · State: local

> Medições fechadas em 2026-09-03 contra a stack no ar: os bytes dos arquivos locais
> foram conferidos um a um e batem com o `Data scanned` que o Athena reportou.

---

## DECISÃO 01 — tipo da coluna `valor`: `double`

Escolhi `double` porque inspecionei o dado real antes de decidir: o gerador emite
`"valor": 43.99` como número JSON com ponto em 100% das 16.000 linhas por dia — não
existe nenhum `"17,82"` com vírgula nesta amostra, então o cast não perde nada hoje.
**O que aceito perder:** no dia em que a origem mandar o decimal com vírgula ou como
string, o SerDe devolve `null` em silêncio e a soma de faturamento fica menor sem
nenhum erro na tela; `decimal(10,2)` também não me salvaria disso, e `string` só
empurraria o problema para um `CAST` em toda consulta futura. Troquei detecção de
erro por simplicidade de leitura, e assumo que a checagem de `null` vira
responsabilidade da consulta, não do schema.

## DECISÃO 02 — colunas de tempo (`data_corrida`, `fim`): `string`

Decidi testando, não supondo: os valores são `"00:21:00"` e `"00:32:00"` — hora do dia,
**sem data**. O `timestamp` do Athena/Hive exige `yyyy-MM-dd HH:mm:ss`, então declarar
`timestamp` faz o `SELECT data_corrida FROM corridas` devolver `NULL` em toda linha, sem
erro — exatamente a falha silenciosa que o enunciado avisa. Com `string` o `SELECT`
devolve `00:21:00` de volta, íntegro.
**O que aceito perder:** aritmética de tempo direta. Para comparar ou ordenar por hora
preciso de `CAST(data_corrida AS TIME)` ou de concatenar com `dt` na consulta; a coluna
`duracao_min` já cobre o caso mais comum, então o custo é pequeno perto de perder o dado.

## DECISÃO 03 — `ignore.malformed.json = "true"`

Escolhi o **silêncio**: linhas quebradas viram `null` em vez de derrubar a consulta.
Com particionamento diário, uma única linha corrompida com `false` mataria a leitura do
dia inteiro, e o lake é lido por gente que não tem acesso ao S3 para consertar o arquivo.
**O que aceito perder, e quem paga:** quem paga é o analista a jusante — ele recebe uma
resposta completa e plausível sem saber que N linhas sumiram. A conta só não fica escondida
porque essa dívida é explícita aqui: a contrapartida obrigatória é um `count(*)` por
partição comparado com a contagem do gerador; sem essa conferência, `true` transforma perda
de dado em número bonito.

## DECISÃO 04 — partições registradas: 8 dias (`2026-08-27` a `2026-09-03`, incluindo hoje)

O gerador criou 9 pastas `dt=` (de `2026-08-26` a `2026-09-03`). Registrei 8 e deixei
`dt=2026-08-26` **de fora de propósito**, para tornar visível o que o mínimo de 3 partições
esconde: registrei bem acima do mínimo para que a consulta larga varra volume suficiente
para o teto da DECISÃO 05 realmente morder.
**O que acontece com o dia que não registrei:** os ~3,4 MB de `dt=2026-08-26` continuam no
S3, continuam sendo cobrados como armazenamento, e são invisíveis para o Athena — um
`count(*)` sem filtro não os enxerga e ninguém recebe aviso. Partição não registrada é dado
pago e inexistente ao mesmo tempo.
**O que acontece amanhã:** nada, e esse é o ponto. Sem Crawler e sem `MSCK REPAIR`, o dia
`2026-09-04` só entra na tabela quando alguém acrescentar a data em `dias_particao` e rodar
`terraform apply` de novo. Aceito esse trabalho manual diário em troca de um catálogo cujo
conteúdo é declarado e revisável no código — o preço é que o esquecimento humano vira
buraco silencioso no dado.

## DECISÃO 05 — teto de bytes: `16777216` (16 MiB)

Saiu de medição, não do lab. Medi primeiro os arquivos que subi: os 8 dias registrados somam
**27.268.814 bytes** (~26,0 MiB) e o dia de hoje sozinho tem **3.408.184 bytes** (~3,25 MiB) —
JSON sem compressão, então o `Data scanned` do Athena acompanha o tamanho do objeto.
Confirmação no Athena com o teto provisório de `117455962`:
`SELECT count(*) FROM corridas` → **`27.268.814` bytes** (`SUCCEEDED`);
`SELECT count(*) FROM corridas WHERE dt='2026-09-03'` → **`3.408.184` bytes** (`SUCCEEDED`).

O `Data scanned` da larga bateu **byte a byte** com a soma dos 8 dias registrados,
e não com os 9 dias que estão no bucket — é a DECISÃO 04 medida em vez de suposta:
`dt=2026-08-26` está no S3, é cobrado, e o Athena não o enxergou.

Com esses dois números, o teto precisa ficar **entre 3,25 MiB e 26,0 MiB**. Fixei em
`16777216`: mata a consulta larga com folga de ~10,5 MiB e deixa a estreita passar com folga
de ~13,5 MiB.
**Por que não o piso:** `10485760` também funcionaria hoje, mas fica a apenas 3 dias de
distância da consulta estreita — na primeira análise legítima de uma semana o freio pegaria
um uso correto, e o teto vira ruído em vez de proteção. **Por que não o topo:** `117455962`
é maior que tudo que existe no bucket, então o freio nunca tocaria e o controle de custo
seria decorativo.
**O que aceito perder:** varreduras de mais de 4 dias em uma consulta só. Quem precisar de
uma janela semanal terá de quebrá-la por partição ou pedir um workgroup com outro teto —
troquei conveniência analítica por um limite de gasto que efetivamente dispara.

---

## Saída do `verifica.sh`

```
Exercício 02 — verificação (região us-east-1, hoje 2026-09-03)
----------------------------------------------------------------
Critério 0 — Terraform, schema declarado, sem Crawler (ELIMINATÓRIO)
OK     [0]  requisito atendido (não pontua; libera o resto)
----------------------------------------------------------------
Critério 1 — os cinco outputs de contrato
       bucket_name = eda-a08-lake-eda-grupo03
       database_name = eda_a08_lake_eda-grupo03
       table_name = corridas
       workgroup_name = eda-a08-wg-eda-grupo03
       teto_bytes = 16777216
PASSA  [1]  (10%)  os cinco outputs existem e estão preenchidos.
----------------------------------------------------------------
Critério 2 — schema declarado (≥8 colunas) e partição dt
       colunas declaradas: 9 · chave de partição: dt
PASSA  [2]  (25%)  schema com 9 colunas e partição dt.
----------------------------------------------------------------
Critério 3 — ≥3 partições, uma delas a de hoje
       partições registradas: 8 -> 2026-08-30 2026-09-02 2026-08-28 2026-08-29 2026-08-27 2026-08-31 2026-09-03 2026-09-01
PASSA  [3]  (15%)  8 partições, incluindo a de hoje (2026-09-03).
----------------------------------------------------------------
Critério 4 — o teto mata a consulta larga e deixa passar a estreita
       teto declarado: 16777216 bytes
       larga:    estado=CANCELLED  motivo=Bytes scanned limit was exceeded
       estreita: estado=SUCCEEDED  bytes=3408184
FALHA  [4]  (15%)  larga_barrada=0 estreita_passou=1
----------------------------------------------------------------
Critério 6 — DECISOES.md (avaliação manual da justificativa)
       encontrei 6 decisões em ../DECISOES.md — o CONTEÚDO é avaliado à mão (20%).
----------------------------------------------------------------
Resumo dos critérios automáticos: 50 / 65 pontos-percentuais

  bucket=eda-a08-lake-eda-grupo03  db=eda_a08_lake_eda-grupo03  table=corridas  wg=eda-a08-wg-eda-grupo03  teto=16777216
  criterios_automaticos=50/65  data=2026-09-03T12:10:53Z
```

### Sobre o `FALHA` no critério 4 — o teto disparou; o script espera outro estado

O comportamento pedido aconteceu: **a larga morreu no teto e a estreita passou**. O
próprio script imprime o motivo que o Athena devolveu, `Bytes scanned limit was
exceeded`, e a estreita concluiu varrendo `3.408.184` bytes, abaixo dos `16.777.216`.

O `FALHA` vem da linha 140 do `verifica.sh`, que exige `estado = FAILED`:

```bash
[ "$lest" = "FAILED" ] && [ "$larga_morreu" = "sim" ] && larga_ok=1 || larga_ok=0
```

O Athena hoje encerra a consulta estourada como **`CANCELLED`**, não como `FAILED`.
A checagem do motivo (`larga_morreu`) passa; a do estado, não.

Antes de aceitar isso, procurei uma alavanca do lado da infra, porque a versão da
engine é declarada no workgroup e seria uma correção legítima. Não existe:

```
aws athena list-engine-versions -> AUTO, Athena engine version 3,
                                   Apache Spark 3.5, PySpark 3
```

A engine v2 foi aposentada; só resta a v3, e nela o estouro do
`bytes_scanned_cutoff_per_query` sempre cancela. Não há campo no
`aws_athena_workgroup` que produza `FAILED`.

Os desvios possíveis seriam piores. Negar `s3:GetObject` nas demais partições faria a
larga falhar de verdade, mas com `Access Denied`: o teto deixaria de ser a causa da
morte, e o critério cairia pelos dois checks em vez de um. Baixar mais o teto não muda
o mecanismo.

Sobra alterar a linha 140, e isso eu não fiz: o `verifica.sh` é o instrumento de
correção, e trocar a régua para caber a resposta seria entregar o número no lugar da
evidência. Deixo o estado bruto acima como prova.

## Saída do `verifica.sh --pos-destroy`

```
Critério 5 — destroy limpo
----------------------------------------------------------------
grep: Unmatched [, [^, [:, [., or [=
(… a mesma linha, uma por bucket da conta …)
PASSA  [5]  (15%)  nenhum bucket órfão.
----------------------------------------------------------------
Critério 5: 15/15%
```

O `terraform destroy` fechou com `Resources: 15 destroyed`.

### O `PASSA` do critério 5 saiu por acidente — conferi à mão

O `verifica.sh --pos-destroy` monta o sufixo assim (linhas 35-39):

```bash
SUF="$(terraform -chdir="$TFDIR" output -raw bucket_name 2>/dev/null | sed 's/^eda-a08-lake-//')"
if [ -z "$SUF" ]; then ...fallback pelo tfvars... fi
```

Depois do `destroy` não há mais outputs, e o Terraform 1.9 escreve o aviso
`Warning: No outputs found` no **stdout**, não no stderr — então o `2>/dev/null`
não o segura. `SUF` recebe o texto inteiro do aviso, com os códigos ANSI de cor
(`\e[33m`) dentro. Como `SUF` não está vazio, o fallback do `if` nunca dispara, e o
pattern vira `eda-a08-(lake|results)-<aviso com colchetes>\b` — regex inválida. É daí
que vem o `grep: Unmatched [`, um por bucket da conta.

O efeito é que **o grep nunca chega a comparar nada**: `orfaos` fica vazio porque a
regex quebrou, não porque não há órfãos. O critério 5 imprimiria `PASSA` mesmo com os
buckets de pé. Não é um problema desta entrega — acontece em qualquer máquina, porque
depois do `destroy` nunca há outputs.

Então verifiquei o critério pelo caminho que ele deveria ter tomado:

```
aws s3 ls                 -> nenhum bucket eda-a08-lake-* nem eda-a08-results-*
aws glue get-databases    -> ["default"]   (sem eda_a08_lake_eda-grupo03)
aws athena list-work-groups -> ["primary"] (sem eda-a08-wg-eda-grupo03)
```

Os três serviços estão limpos. O `destroy` não deixou órfão.

---

## Nota de reprodução

O ambiente da máquina exigiu dois contornos, nenhum deles com efeito sobre a infra
entregue: o antivírus (Norton) intercepta TLS inclusive no loopback, o que quebra o
handshake mTLS entre o `terraform` e o plugin do provider (`TF_DISABLE_PLUGIN_TLS=1`)
e exige apontar a AWS CLI para o bundle de CAs do Windows (`AWS_CA_BUNDLE`). Além
disso, o `verifica.sh` precisa rodar sob locale UTF-8: com o locale `C` do Git Bash,
o `grep -ciE 'DECIS[ÃA]O...'` do critério 6 não casa o `Ã` multibyte e reporta zero
decisões num arquivo que tem as cinco.
