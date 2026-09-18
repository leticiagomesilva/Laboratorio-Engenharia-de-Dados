output "bucket_name" {
  description = "Nome do bucket de dados."
  value       = module.lake.bucket_name
}

output "database_name" {
  description = "Nome do database no Glue."
  value       = module.lake.database_name
}

output "table_name" {
  description = "Nome da tabela."
  value       = module.lake.table_name
}

output "workgroup_name" {
  description = "Nome do workgroup do Athena."
  value       = module.lake.workgroup_name
}

output "teto_bytes" {
  description = "Teto de bytes por consulta."
  value       = module.lake.teto_bytes
}
