# Complete CodePipeline Example
This example demonstrates creating a CodePipeline pipeline. It includes 2 stages. First stage is a source S3 bucket that triggers the pipeline with an event bridge notification. The second stage is a manual approval stage.


## Provider requirements
Make sure a `provider.tf` file is created with the below contents inside the `examples/with_tls_enforced` directory
```shell
provider "aws" {
  profile = "<profile_name>"
  region  = "<aws_region>"
}
# Used to create a random integer postfix for aws resources
provider "random" {}
```

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0, <= 1.5.5 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.32.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.6.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_random"></a> [random](#provider\_random) | 3.6.2 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_codepipeline"></a> [codepipeline](#module\_codepipeline) | ../.. | n/a |

## Resources

| Name | Type |
|------|------|
| [random_string.random](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_name"></a> [name](#input\_name) | The name of the pipeline | `string` | n/a | yes |
| <a name="input_stages"></a> [stages](#input\_stages) | One or more stage blocks. | `any` | n/a | yes |
| <a name="input_pipeline_type"></a> [pipeline\_type](#input\_pipeline\_type) | The CodePipeline pipeline\_type. Valid options are V1, V2 | `string` | `"V2"` | no |
| <a name="input_execution_mode"></a> [execution\_mode](#input\_execution\_mode) | The CodePipeline execution\_mode. Valid options are `PARALLEL`, `QUEUED`, `SUPERSEDED` (default) | `string` | `"SUPERSEDED"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | An arbitrary map of tags that can be added to all resources. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_id"></a> [id](#output\_id) | The codepipeline ID |
| <a name="output_arn"></a> [arn](#output\_arn) | The codepipeline ARN |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
c