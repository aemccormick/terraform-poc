output "client_workload_id" {
  description = "Aembit resource id for Lambda client workload."
  value       = try(aembit_client_workload.this[0].id, compact([for v in data.aembit_client_workloads.this.client_workloads : v["name"] == var.client_workload_name ? v["id"] : ""])[0])
}

output "trust_provider_ids" {
  description = "List of Aembit resource ids for Lambda trust providers."
  value       = try([aembit_trust_provider.this[0].id], compact([for v in data.aembit_trust_providers.this.trust_providers : v["name"] == var.trust_provider_name ? v["id"] : ""]))
}

output "credential_providers" {
  description = "List of credential providers created by module."
  value       = aembit_credential_provider.this
}

output "access_policies" {
  description = "List of Aembit resource ids for created access policies."
  value       = aembit_access_policy.this
}
