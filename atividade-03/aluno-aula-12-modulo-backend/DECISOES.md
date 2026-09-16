# DECISOES.md — Exercício 03 (Aula 12)

Grupo: `eda-grupo03` · Região: `us-east-1` · Backend remoto S3

## DECISÃO 01 — fronteira do módulo

Coloquei os seis recursos da stack (`S3`, bloqueio de acesso público, Glue Database, Glue Table e Athena Workgroup) dentro de `modules/lake/`, mantendo na raiz apenas a chamada do módulo, as variáveis e os outputs; aceitei essa separação para encapsular a infraestrutura do lake sem alterar os nomes ou propriedades dos recursos existentes.

## DECISÃO 02 — movimentação do state

Usei `terraform state mv` para trocar os endereços da raiz, como `aws_s3_bucket.lake`, pelos endereços equivalentes dentro de `module.lake`, porque essa operação atualiza o mapa do Terraform sem recriar os recursos na AWS; aceitei executar os movimentos individualmente para preservar a correspondência entre cada recurso antigo e seu novo endereço.

## DECISÃO 03 — workspace e organização

Criei o workspace nomeado `dev`, mas mantive a stack migrada no workspace `default`, porque o state original estava nesse workspace e movê-la para `dev` alteraria a organização do state e poderia exigir uma nova migração; aceitei usar o workspace `dev` para um ambiente separado, em vez de renomear o ambiente já existente.

## DECISÃO 04 — significado do plan limpo

Considerei o resultado `No changes` a prova de que o código modular corresponde ao state e à infraestrutura atual, sem recursos a adicionar, alterar ou destruir; aceitei que um plan limpo não prova a ausência de drift que não seja detectado pelo refresh nem garante que as decisões de arquitetura sejam as melhores.

## DECISÃO 05 — ordem das operações

Segui a ordem de aplicar a stack plana, criar o módulo, executar o `terraform state mv` e só então rodar o plan final; aceitei essa disciplina porque aplicar antes da movimentação faria o Terraform interpretar os endereços antigos como removidos e os endereços do módulo como novos, podendo destruir e recriar toda a infraestrutura.

