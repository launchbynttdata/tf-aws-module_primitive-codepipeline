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

resource "aws_codepipeline" "this" {
  name           = var.name
  role_arn       = aws_iam_role.combined_role.arn
  pipeline_type  = var.pipeline_type
  execution_mode = var.execution_mode

  dynamic "artifact_store" {
    for_each = [for store in var.artifact_stores : {
      use_kms = try(store.use_kms, false)
      kms_arn = try(store.kms_arn, null)
      region  = try(store.region, null)
    }]

    content {
      location = aws_s3_bucket.codepipeline_bucket.bucket
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

resource "aws_s3_bucket" "codepipeline_bucket" {
  bucket        = join("-", ["codepipeline", random_string.random.result])
  force_destroy = true
}

resource "aws_s3_bucket_logging" "codepipeline_bucket_logging" {
  count         = length(var.log_target_bucket) > 0 ? 1 : 0
  bucket        = aws_s3_bucket.codepipeline_bucket.id
  target_bucket = var.log_target_bucket
  target_prefix = local.bucket_prefix
}

resource "random_string" "random" {
  length  = 16
  special = false
  upper   = false
}

# Combined assume role policy for CodePipeline and EventBridge
data "aws_iam_policy_document" "combined_assume_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = [
        "codepipeline.amazonaws.com",
        "events.amazonaws.com"
      ]
    }
  }
}

# Combined IAM role
resource "aws_iam_role" "combined_role" {
  name               = local.combined_role_name
  assume_role_policy = data.aws_iam_policy_document.combined_assume_role_policy.json
}

# Combined policy for both CodePipeline and EventBridge operations
data "aws_iam_policy_document" "combined_policy" {
  statement {
    effect = "Allow"
    actions = [
      # CodePipeline Actions
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild",
      "codebuild:BatchGetBuildBatches",
      "codebuild:StartBuildBatch",
      "s3:*",
      "cloudwatch:*",
      "sns:*",
      "sqs:*"
    ]
    resources = [
      local.source_bucket_arn,
      "${local.source_bucket_arn}/*",
      "*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      # EventBridge Actions
      "codepipeline:StartPipelineExecution"
    ]
    resources = [aws_codepipeline.this.arn]
  }

  dynamic "statement" {
    for_each = var.create_s3_source ? [1] : []
    content {
      effect = "Allow"
      actions = [ 
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:GetBucketVersioning",
        "s3:PutObjectAcl",
        "s3:PutObjct"
       ]
       resources = [ 
        local.source_bucket_arn,
      "${local.source_bucket_arn}/*"
        ]
    }
    
  }
}

# Attach combined policy to the combined role
resource "aws_iam_role_policy" "combined_role_policy" {
  name   = local.combined_policy_name
  role   = aws_iam_role.combined_role.id
  policy = data.aws_iam_policy_document.combined_policy.json
}

resource "aws_s3_bucket" "source" {
  count         = local.create_s3_source_cond
  bucket        = replace(var.source_s3_bucket, "_", "-")
  force_destroy = true
}

resource "aws_s3_bucket_logging" "source_bucket_logging" {
  count         = length(var.log_target_bucket) > 0 && var.create_s3_source ? 1 : 0
  bucket        = local.source_bucket_arn
  target_bucket = var.log_target_bucket
  target_prefix = local.bucket_prefix
}

resource "aws_s3_bucket_versioning" "source_bucket_versioning" {
  bucket = local.source_bucket_arn

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "sse" {
  bucket = aws_s3_bucket.source[0].bucket

  rule {
    bucket_key_enabled = true
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_cloudwatch_event_rule" "pipeline_event" {
  count       = local.create_s3_source_cond
  name        = local.event_name_limit
  description = "CloudWatch event when a zip is uploaded to S3"

  event_pattern = <<EOF
{
  "source": ["aws.s3"],
  "detail-type": ["AWS API Call via CloudTrail"],
  "detail": {
    "eventSource": ["s3.amazonaws.com"],
    "eventName": ["PutObject", "CompleteMultipartUpload", "CopyObject"],
    "requestParameters": {
      "bucketName": ["${local.source_bucket_arn}"],
      "key": ["${var.s3_trigger_file}"]
    }
  }
}
EOF
}

resource "aws_cloudwatch_event_target" "code_pipeline" {
  count     = local.create_s3_source_cond
  rule      = aws_cloudwatch_event_rule.pipeline_event[0].name
  target_id = "SendToCodePipeline"
  arn       = aws_codepipeline.this.arn
  role_arn  = aws_iam_role.combined_role.arn
}

# Combined EventBridge role policy (no longer needed since it's combined with CodePipeline)
data "aws_iam_policy_document" "pipeline_event_role_policy" {
  statement {
    actions   = ["codepipeline:StartPipelineExecution"]
    resources = [aws_codepipeline.this.arn]
    effect    = "Allow"
  }
}

resource "aws_iam_role_policy_attachment" "pipeline_event_role_attach_" {
  role       = aws_iam_role.combined_role.name
  policy_arn = aws_iam_role_policy.combined_role_policy.name
}


