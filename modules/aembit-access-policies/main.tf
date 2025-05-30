data "aembit_access_conditions" "this" {}
data "aembit_client_workloads" "this" {}
data "aembit_trust_providers" "this" {}
data "aembit_credential_providers" "this" {}
data "aembit_server_workloads" "this" {}

resource "aembit_client_workload" "this" {
  count = var.create_client_workload == true ? 1 : 0

  name        = var.client_workload_name
  description = "${var.client_workload_name} Lambda Client Workload"
  is_active   = var.is_active
  identities  = var.client_workload_identities
  tags        = var.tags
}

resource "aembit_trust_provider" "this" {
  for_each = var.create_trust_providers == true ? var.trust_providers : {}

  name        = "${var.client_workload_name}-${each.key}"
  description = "${var.client_workload_name}-${each.key} ${each.value["type"]} Trust Provider"
  is_active   = var.is_active
  tags        = var.tags

  aws_metadata               = each.value["type"] == "aws_metadata" ? each.value["aws_metadata"] : null
  aws_role                   = each.value["type"] == "aws_role" ? each.value["aws_role"] : null
  azure_metadata             = each.value["type"] == "azure_metadata" ? each.value["azure_metadata"] : null
  gcp_identity               = each.value["type"] == "gcp_identity" ? each.value["gcp_identity"] : null
  github_action              = each.value["type"] == "github_action" ? each.value["github_action"] : null
  gitlab_job                 = each.value["type"] == "gitlab_job" ? each.value["gitlab_job"] : null
  kerberos                   = each.value["type"] == "kerberos" ? each.value["kerberos"] : null
  kubernetes_service_account = each.value["type"] == "kubernetes_service_account" ? each.value["kubernetes_service_account"] : null
  terraform_workspace        = each.value["type"] == "terraform_workspace" ? each.value["terraform_workspace"] : null
}

resource "aembit_credential_provider" "this" {
  for_each = var.create_credential_providers == true ? var.credential_providers : {}

  name        = each.key
  description = "${var.client_workload_name}-${each.key} ${each.value["type"]} Credential Provider"
  is_active   = try(each.value["is_active"], true)
  tags        = var.tags

  aembit_access_token           = each.value["type"] == "aembit_access_token" ? each.value["aembit_access_token"] : null
  api_key                       = each.value["type"] == "api_key" ? each.value["api_key"] : null
  aws_sts                       = each.value["type"] == "aws_sts" ? each.value["aws_sts"] : null
  azure_entra_workload_identity = each.value["type"] == "azure_entra_workload_identity" ? each.value["azure_entra_workload_identity"] : null
  google_workload_identity      = each.value["type"] == "google_workload_identity" ? each.value["google_workload_identity"] : null
  managed_gitlab_account        = each.value["type"] == "managed_gitlab_account" ? each.value["managed_gitlab_account"] : null
  oauth_authorization_code      = each.value["type"] == "oauth_authorization_code" ? each.value["oauth_authorization_code"] : null
  oauth_client_credentials      = each.value["type"] == "oauth_client_credentials" ? each.value["oauth_client_credentials"] : null
  snowflake_jwt                 = each.value["type"] == "snowflake_jwt" ? each.value["snowflake_jwt"] : null
  username_password             = each.value["type"] == "username_password" ? each.value["username_password"] : null
  vault_client_token            = each.value["type"] == "vault_client_token" ? each.value["vault_client_token"] : null
}

resource "aembit_access_policy" "this" {
  for_each = var.access_policies

  name                = "${var.client_workload_name}-${each.key}"
  client_workload     = try(aembit_client_workload.this[0].id, compact([for v in data.aembit_client_workloads.this.client_workloads : v["name"] == var.client_workload_name ? v["id"] : ""])[0])
  trust_providers     = try([for v in aembit_trust_provider.this : v["id"]], compact([for v in data.aembit_trust_providers.this.trust_providers : v["name"] == var.trust_provider_name ? v["id"] : ""])[0])
  access_conditions   = try(compact([for v in data.aembit_access_conditions.this.access_conditions : contains(each.value["access_condition_names"], v["name"]) ? v["id"] : ""]), [])
  credential_provider = try(aembit_credential_provider.this[each.value["credential_provider_name"]].id, compact([for v in data.aembit_credential_providers.this.credential_providers : v["name"] == each.value["credential_provider_name"] ? v["id"] : ""])[0])
  server_workload     = try(each.value["server_workload_id"], compact([for v in data.aembit_server_workloads.this.server_workloads : v["name"] == each.value["server_workload_name"] ? v["id"] : ""])[0])
  is_active           = try(each.value["is_active"], true)
}
