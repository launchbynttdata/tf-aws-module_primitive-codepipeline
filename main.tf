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

#data "aws_caller_identity" "current" {}

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
      location = var.artifact_bucket_name
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
    for_each = [for s in var.stages : {
      stage_name = lookup(s, "stage_name", "My-Stage")
      name       = s.name
      action     = s.action
    } if(lookup(s, "enabled", true))]

    content {
      name = stage.value.stage_name
      dynamic "action" {
        for_each = stage.value.action
        content {
          name             = lookup(action.value, "name", "Manual-Approval")
          owner            = lookup(action.value, "owner", "AWS")
          version          = lookup(action.value, "version", "1")
          category         = lookup(action.value, "category", "Approval")
          provider         = lookup(action.value, "provider", "Manual")
          input_artifacts  = lookup(action.value, "input_artifacts", [])
          output_artifacts = lookup(action.value, "output_artifacts", [])
          configuration    = lookup(action.value, "configuration", {})
          run_order        = lookup(action.value, "run_order", null)
          region           = lookup(action.value, "region", null)
          namespace        = lookup(action.value, "namespace", null)
        }
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

resource "aws_iam_role_policy" "codepipeline_policy" {
  name   = "codepipeline_policy"
  role   = aws_iam_role.codepipeline_role.id
  policy = data.aws_iam_policy_document.assume_role.json
}