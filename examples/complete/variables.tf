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

variable "stages" {
  description = "One or more stage blocks."
  type        = any
}
variable "pipeline_type" {
  description = "The CodePipeline pipeline_type. Valid options are V1, V2"
  type        = string
  default     = "V2"
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

variable "artifact_bucket_name" {
  description = "the name of the S3 bucket used for storing the artifacts in the Codepipeline"
  type        = string
}

variable "tags" {
  description = "An arbitrary map of tags that can be added to all resources."
  type        = map(string)
  default     = {}
}
