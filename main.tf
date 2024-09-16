// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

data "aws_caller_identity" "current" {}

data "aws_s3_bucket" "artifact_bucket" {
  bucket = var.artifact_bucket_name
}

resource "aws_codepipeline" "this" {
  name           = var.name
  role_arn       = aws_iam_role.codepipeline_role.arn
  pipeline_type  = var.pipeline_type
  execution_mode = var.execution_mode

  dynamic "artifact_store" {
    for_each = [for store in var.artifact_stores : {
      use_kms = try(store.use_kms, false)
      kms_arn = try(store.kms_arn, null)
      region  = try(store.region, null)
    }]

    content {
      location = data.aws_s3_bucket.artifact_bucket.bucket
      type     = "S3"

      dynamic "encryption_key" {
        for_each = artifact_store.value.use_kms == true ? [1] : []
        content {
          id   = artifact_store.value.kms_arn != null ? artifact_store.value.kms_arn : null
          type = "KMS"
        }
      }
      region = artifact_store.value.region
    }
  }

  dynamic "stage" {
    for_each = [for stage_val in var.stages : {
      stage_name       = try(stage_val.stage_name, "My-Stage")
      name             = try(stage_val.name, "Manual-Approval")
      category         = try(stage_val.category, "Approval")
      owner            = try(stage_val.owner, "AWS")
      provider         = try(stage_val.provider, "Manual")
      version          = try(stage_val.version, "1")
      configuration    = try(stage_val.configuration, {})
      input_artifacts  = try(stage_val.input_artifacts, [])
      output_artifacts = try(stage_val.output_artifacts, [])
      run_order        = try(stage_val.run_order, null)
      region           = try(stage_val.region, null)
      namespace        = try(stage_val.namespace, null)
    }]

    content {
      name = stage.value.stage_name
      action {
        name             = stage.value.name
        category         = stage.value.category
        owner            = stage.value.owner
        provider         = stage.value.provider
        version          = stage.value.version
        configuration    = stage.value.configuration
        input_artifacts  = stage.value.input_artifacts
        output_artifacts = stage.value.output_artifacts
        run_order        = stage.value.run_order
        region           = stage.value.region
        namespace        = stage.value.namespace
      }
    }
  }

  tags = local.tags
}

#CodePipeline Role
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "codepipeline_role" {
  name               = "${var.name}-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "codepipeline_policy" {

  # Eventbridge trigger
  statement {
    effect = "Allow"
    actions = [
      "cloudwatch:*",
      "sns:*",
      "sqs:*"
    ]
    resources = ["*"]
  }

  # Start any stage CodeBuild projects
  statement {
    effect = "Allow"
    actions = [
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild",
      "codebuild:BatchGetBuildBatches",
      "codebuild:StartBuildBatch"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:*"
    ]
    resources = [
      data.aws_s3_bucket.artifact_bucket.arn,
      "${data.aws_s3_bucket.artifact_bucket.arn}/*",
    ]
  }
}
resource "aws_iam_role_policy" "codepipeline_policy" {
  name   = "codepipeline_policy"
  role   = aws_iam_role.codepipeline_role.id
  policy = data.aws_iam_policy_document.codepipeline_policy.json
}

resource "random_string" "random" {
  length  = 10
  special = false
  upper   = false
}