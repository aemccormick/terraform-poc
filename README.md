# Aembit POC deployment
Configuration in this directory creates an Aembit Agent Controller and Aembit Access Policies for a AWS Lambda Container that uses the Aembit Lambda Extension to provided dynamic federated authentication to S3.  It also creates an EC2 instance that uses the Aembit Agent Proxy to provide dynamic federated authentication to Google BigQuery.

## Usage
1. Ensure your [AWS](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication-and-configuration), [Google](https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/provider_reference#authentication), and [Aembit](https://registry.terraform.io/providers/Aembit/aembit/latest/docs) provider credentials are configured correctly
2. Configure required variables
3. Run `terraform init` and `terraform apply`
4. After the terraform apply completes, test the Lambda function.  A successful test should result in a list of S3 buckets in the function logs.
5. Test Google BigQuery on the example EC2 Instance using the following command:
```
curl -X POST \
  "https://bigquery.googleapis.com/bigquery/v2/projects/gcp-smoketest/queries" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "SELECT display_name, job_title, user_principal_name, id FROM demo_data.employees LIMIT 100",
    "useLegacySql": false
  }'
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5 |
| <a name="requirement_aembit"></a> [aembit](#requirement\_aembit) | >= 1.17.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 6.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | >= 3.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aembit"></a> [aembit](#provider\_aembit) | 1.22.1 |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.99.0 |
| <a name="provider_google"></a> [google](#provider\_google) | 6.37.0 |
| <a name="provider_null"></a> [null](#provider\_null) | 3.2.4 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_ec2-bigquery"></a> [ec2-bigquery](#module\_ec2-bigquery) | ./modules/ec2-bigquery | n/a |
| <a name="module_ec2_agent_controller"></a> [ec2\_agent\_controller](#module\_ec2\_agent\_controller) | ./modules/ec2-agent-controller | n/a |
| <a name="module_lambda-function-s3"></a> [lambda-function-s3](#module\_lambda-function-s3) | ./modules/lambda-function-s3 | n/a |

## Resources

| Name | Type |
|------|------|
| [aembit_server_workload.bigquery](https://registry.terraform.io/providers/aembit/aembit/latest/docs/resources/server_workload) | resource |
| [aembit_server_workload.s3](https://registry.terraform.io/providers/aembit/aembit/latest/docs/resources/server_workload) | resource |
| [aws_lambda_layer_version.trust_bundle](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_layer_version) | resource |
| [aws_serverlessapplicationrepository_cloudformation_stack.aembit_proxy_layer](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/serverlessapplicationrepository_cloudformation_stack) | resource |
| [google_iam_workload_identity_pool.aembit](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/iam_workload_identity_pool) | resource |
| [google_iam_workload_identity_pool_provider.aembit](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/iam_workload_identity_pool_provider) | resource |
| [null_resource.trust_bundle](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aembit_agent_log_level"></a> [aembit\_agent\_log\_level](#input\_aembit\_agent\_log\_level) | Log level of Aembit agent proxy Lambda extension. | `string` | `"info"` | no |
| <a name="input_aembit_tenant_id"></a> [aembit\_tenant\_id](#input\_aembit\_tenant\_id) | ID of Aembit tenant. | `string` | n/a | yes |
| <a name="input_aws_account_id"></a> [aws\_account\_id](#input\_aws\_account\_id) | ID of AWS where Aembit edge components will be deployed. | `string` | n/a | yes |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region where Aembit edge components will be deployed. | `string` | n/a | yes |
| <a name="input_gcp_project"></a> [gcp\_project](#input\_gcp\_project) | GCP Project name | `string` | n/a | yes |
| <a name="input_gcp_workload_identity_pool_name"></a> [gcp\_workload\_identity\_pool\_name](#input\_gcp\_workload\_identity\_pool\_name) | Name of GCP Workload Identity Federation Pool | `string` | n/a | yes |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | List of subnet IDs where Aembit edge components will be deployed. | `list(string)` | n/a | yes |
| <a name="input_vpc_cidr_block"></a> [vpc\_cidr\_block](#input\_vpc\_cidr\_block) | CIDR block of AWS VPC | `string` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | ID of AWS VPC where Aembit edge components will be deployed. | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->