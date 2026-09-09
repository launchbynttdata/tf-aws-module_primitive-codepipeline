# Complete CodePipeline Example

This example creates a CodePipeline with two stages: an S3 source that can trigger the pipeline, and a manual approval stage. It calls the root module from `examples/complete/main.tf`.

The repository Makefile generates `provider.tf` when you run `make lint` or `make test` from the repository root. Sign in to AWS first.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.32.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.6.0 |

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
| <a name="input_artifact_bucket_name"></a> [artifact\_bucket\_name](#input\_artifact\_bucket\_name) | the name of the S3 bucket used for storing the artifacts in the Codepipeline | `string` | n/a | yes |
| <a name="input_execution_mode"></a> [execution\_mode](#input\_execution\_mode) | The CodePipeline execution\_mode. Valid options are `PARALLEL`, `QUEUED`, `SUPERSEDED` (default) | `string` | `"SUPERSEDED"` | no |
| <a name="input_name"></a> [name](#input\_name) | The name of the pipeline | `string` | n/a | yes |
| <a name="input_pipeline_type"></a> [pipeline\_type](#input\_pipeline\_type) | The CodePipeline pipeline\_type. Valid options are V1, V2 | `string` | `"V2"` | no |
| <a name="input_stages"></a> [stages](#input\_stages) | One or more stage blocks. | `any` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | An arbitrary map of tags that can be added to all resources. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_arn"></a> [arn](#output\_arn) | The codepipeline ARN |
| <a name="output_id"></a> [id](#output\_id) | The codepipeline ID |
<!-- END_TF_DOCS -->
