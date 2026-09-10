package testimpl

import (
	"context"
	"os"
	"testing"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/codepipeline"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/launchbynttdata/lcaf-component-terratest/types"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestComposableComplete verifies the deployed CodePipeline and its stage names.
func TestComposableComplete(t *testing.T, ctx types.TestContext) {
	opts := ctx.TerratestTerraformOptions()
	moduleConfig := ctx.TestConfig().(*ThisTFModuleConfig)

	arn := terraform.OutputContext(t, context.Background(), opts, "arn")
	require.NotEmpty(t, arn, "pipeline ARN is empty")
	assert.Regexp(t, "^arn:aws:codepipeline:[a-z0-9-]+:[0-9]{12}:.+$", arn)

	pipelineName := terraform.OutputContext(t, context.Background(), opts, "id")
	require.NotEmpty(t, pipelineName, "pipeline ID is empty")

	client := codePipelineClient(t)
	result, err := client.GetPipeline(context.Background(), &codepipeline.GetPipelineInput{
		Name: aws.String(pipelineName),
	})
	require.NoError(t, err, "GetPipeline failed for %s", pipelineName)
	require.NotNil(t, result.Pipeline)

	expectedStages := make([]string, len(moduleConfig.Stages))
	for i, stage := range moduleConfig.Stages {
		expectedStages[i] = stage.Name
	}

	actualStages := make([]string, len(result.Pipeline.Stages))
	for i, stage := range result.Pipeline.Stages {
		actualStages[i] = aws.ToString(stage.Name)
	}
	assert.ElementsMatch(t, expectedStages, actualStages, "pipeline stages do not match")
}

func codePipelineClient(t *testing.T) *codepipeline.Client {
	t.Helper()

	region := os.Getenv("AWS_REGION")
	if region == "" {
		region = "us-east-2"
	}

	cfg, err := config.LoadDefaultConfig(context.Background(), config.WithRegion(region))
	require.NoError(t, err)

	return codepipeline.NewFromConfig(cfg)
}
