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

resource "random_string" "random" {
  length  = 10
  special = false
  upper   = false
}

module "codepipeline" {
  source = "../.."

  name = var.name

  #create_s3_source = var.create_s3_source
  #source_s3_bucket = var.a
  artifact_bucket_name = var.artifact_bucket_name
  stages           = var.stages
  pipeline_type    = var.pipeline_type
  execution_mode   = var.execution_mode

  tags = var.tags
}
