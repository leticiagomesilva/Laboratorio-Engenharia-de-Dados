# DECISOES.md — Exercício 04 (Aula 21)

Uma frase por decisão, **cada uma com um número que você mediu**. Não repita o
enunciado: diga o que escolheu, o que aceitou perder e o que mediu.
Justificativa sem número não pontua (critério 7, 20%).

**DECISÃO 01 — chave de partição.** Escolhi `["dt"]` porque a pergunta da madrugada
filtra só por data (`dt >= hoje−6`) e agrega todos os bairros: com `dt` no caminho o
Athena pula 23 das 30 pastas sem abri-las, e a semana abre 7 arquivos. Com
`["dt","bairro"]` seriam 7 × 22 = 154 arquivos de ~27 KB cada, sem ganho, porque a
pergunta lê todos os bairros de qualquer jeito.

**DECISÃO 02 — arquivos por pasta.** Escolhi 1 arquivo por pasta; cada arquivo ficou
com ~591 KB (18.143.089 bytes em 30 arquivos), longe do tamanho em que dividir
compensaria, e a pergunta lê só 7 rodapés — tão pequenos que o `count(*)` da semana,
respondido pelos metadados do Parquet, mediu 0 bytes no Athena. Com 4 por pasta
seriam 28 rodapés e 28 GETs no S3 para o mesmo dado.

**DECISÃO 03 — a meta de custo.** Declarei 524.288 bytes (512 KiB). Ela saiu do Lab 05
(~0,4 MB para a mesma pergunta em Parquet particionado por dia) com ~47% de folga para
o crescimento do dado, e a pergunta leu 355.803 bytes no Athena — 68% da meta, com a
resposta certa (11.137 corridas).

**DECISÃO 04 — o teto do workgroup.** Declarei 10.485.760 bytes (10 MiB, o mínimo do
Athena, abaixo dos 18.143.089 bytes da trusted inteira): deixa passar a pergunta da
madrugada (355.803 bytes, ~29× abaixo do teto) e barra a consulta de todas as colunas,
que foi cancelada ao atingir 10.485.760 bytes; o preço é que qualquer consulta
legítima acima de 10 MiB — por exemplo, um relatório de 30 dias com todas as colunas —
também é cancelada e precisaria de outro workgroup.

**DECISÃO 05 — o registro das partições.** Escolhi partition projection com
`projection.dt.range = NOW-1YEARS,NOW`: o Athena calcula as 30 pastas pela regra,
sem MSCK e sem nenhuma partição registrada no catálogo. Aceito que uma pasta fora da
janela, ou com nome fora do formato `yyyy-MM-dd`, some sem erro nenhum; no dia 31, a
pasta nova aparece sozinha na próxima consulta, porque `NOW` avança com o calendário.
