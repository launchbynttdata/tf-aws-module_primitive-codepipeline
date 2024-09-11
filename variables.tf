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

variable "name" {
  description = "The name of the pipeline"
  type        = string
}

variable "artifact_stores" {
  description = "One or more artifact_store blocks."
  type        = list(map(string))
  default = [
    {
      use_kms = false
    }
  ]
}

variable "stages" {
  description = "One or more stage blocks."
  type        = any
}

variable "create_s3_source" {
  description = "Create S3 source bucket for CodePipeline."
  type        = string
  default     = false
}

variable "source_s3_bucket" {
  description = "Name of the S3 source bucket."
  type        = string
  default     = null
}

variable "s3_trigger_file" {
  description = "S3 file that the event rule is looking for to trigger the pipeline."
  type        = string
  default     = "trigger_pipeline.zip"
}

variable "log_target_bucket" {
  description = "Target bucket for S3 Access Logs. If left blank, access logging is disabled."
  type        = string
  default     = ""
}

variable "log_target_prefix" {
  description = "Prefix for S3 Access logs. Defaults to AWSLogs/<AWS Account ID>/s3audit if not otherwise provided."
  type        = string
  default     = ""
}

# variable "codepipeline_iam" {
#   description = "Additional IAM actions to add to CodePipeline IAM role."
#   type        = map(list(string))
#   default     = null
# }

variable "pipeline_type" {
  description = "The CodePipeline pipeline_type. Valid options are V1, V2"
  type        = string
  default     = "V1"
}

variable "execution_mode" {
  description = "The CodePipeline execution_mode. Valid options are `PARALLEL`, `QUEUED`, `SUPERSEDED` (default)"
  type        = string
  default     = "SUPERSEDED"

  validation {
    condition     = contains(["PARALLEL", "QUEUED", "SUPERSEDED"], var.execution_mode)
    error_message = "Must be either `PARALLEL`, `QUEUED`, or `SUPERSEDED`."
  }
}

variable "tags" {
  description = "An arbitrary map of tags that can be added to all resources."
  type        = map(string)
  default     = {}
}
