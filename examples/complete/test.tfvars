name                    = "tf-aws-module_primitive-codepipeline-test-pipeline"
create_s3_source        = true
source_s3_bucket_prefix = "tf-aws-module_primitive-codepipeline-test-bucket"
pipeline_type           = "V2"
execution_mode          = "PARALLEL"

stages = [
  {
    stage_name = "Source"
    name       = "Source"
    category   = "Source"
    owner      = "AWS"
    provider   = "S3"
    version    = "1"
    configuration = {
      S3Bucket             = "aaron-test-bucket-778189110199"
      S3ObjectKey          = "trigger_pipeline.zip"
      PollForSourceChanges = "false"
    }
    input_artifacts  = []
    output_artifacts = ["SourceArtifact"]
    run_order        = null
    region           = null
    namespace        = null
  },
  {
    stage_name       = "Manual-Approval"
    name             = "Manual-Approval"
    category         = "Approval"
    owner            = "AWS"
    provider         = "Manual"
    version          = "1"
    configuration    = {}
    input_artifacts  = []
    output_artifacts = []
    run_order        = null
    region           = null
    namespace        = null
  }
]
