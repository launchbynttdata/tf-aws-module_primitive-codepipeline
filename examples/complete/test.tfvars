name                    = "tf-aws-module_primitive-codepipeline-test-pipeline"
pipeline_type           = "V2"
execution_mode          = "PARALLEL"
artifact_bucket_name    = "osahon-test-020127659860"


stages = [
  {
    stage_name = "Source",
    name       = "Source",
    category   = "Source",
    owner      = "AWS",
    provider   = "S3",
    version    = "1",
    configuration = {
      S3Bucket             = "osahon-test-020127659860",
      S3ObjectKey          = "trigger_pipeline.zip",
      PollForSourceChanges = "false"
    },
    input_artifacts  = [],
    output_artifacts = ["SourceArtifact"],
    run_order        = null,
    region           = null,
    namespace        = null
  },
  {
    stage_name       = "Manual-Approval",
    name             = "Manual-Approval",
    category         = "Approval",
    owner            = "AWS",
    provider         = "Manual",
    version          = "1",
    configuration    = {},
    input_artifacts  = [],
    output_artifacts = ["SourceArtifact"]
    run_order        = null,
    region           = null,
    namespace        = null
  }
]
