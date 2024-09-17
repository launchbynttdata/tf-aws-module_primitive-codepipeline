package tests

import (
	"context"
	"encoding/json"
	"os"
	"testing"

	"github.com/gruntwork-io/terratest/modules/logger"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/codepipeline"
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/stretchr/testify/assert"
)

const (
	base            = "../../examples/"
	testVarFileName = "/test.tfvars"
)

type Configuration struct {
	S3Bucket             string `json:"S3Bucket"`
	S3ObjectKey          string `json:"S3ObjectKey"`
	PollForSourceChanges string `json:"PollForSourceChanges"`
}

type Stage struct {
	StageName       string        `json:"stage_name"`
	Name            string        `json:"name"`
	Category        string        `json:"category"`
	Owner           string        `json:"owner"`
	Provider        string        `json:"provider"`
	Version         string        `json:"version"`
	Configuration   Configuration `json:"configuration"`
	InputArtifacts  []interface{} `json:"input_artifacts"`
	OutputArtifacts []string      `json:"output_artifacts"`
	RunOrder        *int          `json:"run_order"`
	Region          *string       `json:"region"`
	Namespace       *string       `json:"namespace"`
}

type TestTfvars struct {
	Name           string  `json:"name"`
	Stages         []Stage `json:"stages"`
}

func TestCodePipeline(t *testing.T) {
	t.Parallel()
	stage := test_structure.RunTestStage

	files, err := os.ReadDir(base)
	if err != nil {
		assert.Error(t, err)
	}
	for _, file := range files {
		dir := base + file.Name()
		if file.IsDir() {
			defer stage(t, "teardown_pipeline", func() { tearDownPipeline(t, dir) })
			stage(t, "setup_and_test_pipeline", func() { setupAndTestPipeline(t, dir) })
		}
	}
}

func setupAndTestPipeline(t *testing.T, dir string) {
	terraformOptions := &terraform.Options{
		TerraformDir: dir,
		VarFiles:     []string{dir + testVarFileName},
		NoColor:      true,
	}

	expectedPatternPipelineID := "^arn:aws:codepipeline:[a-z0-9-]+:[0-9]{12}:.+$"

	test_structure.SaveTerraformOptions(t, dir, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)
	logger.Log(t, "Verifying pipeline arn")
	actualId := terraform.Output(t, terraformOptions, "arn")
	assert.NotEmpty(t, actualId, "pipeline ID is empty")
	assert.Regexp(t, expectedPatternPipelineID, actualId, "PipelineID does not match expected pattern")

	cfg, err := config.LoadDefaultConfig(
		context.TODO(),
		config.WithSharedConfigProfile(os.Getenv("AWS_PROFILE")),
	)
	if err != nil {
		assert.Error(t, err, "can't connect to aws")
	}
	logger.Log(t, "Connected to AWS")
	client := codepipeline.NewFromConfig(cfg)
	actualID := terraform.Output(t, terraformOptions, "id")
	assert.NotEmpty(t, actualId, "pipeline ID is empty")
	input := &codepipeline.GetPipelineInput{
		Name: aws.String(actualID),
	}

	result, err := client.GetPipeline(context.TODO(), input)
	if err != nil {
		assert.Error(t, err, "The expected pipeline was not found")
	}

	assert.NotNil(t, result, "GetPipeline returned nil result")
	if result == nil {
		return
	}

	assert.NotNil(t, result.Pipeline, "GetPipeline returned nil Pipeline")
	if result.Pipeline == nil {
		return
	}

	pipeline := result.Pipeline
	logger.Log(t, "Pipeline was found")

	jsonOutPath := dir + "/output.json"
	err = terraform.HCLFileToJSONFile(dir+testVarFileName, jsonOutPath)
	assert.NoError(t, err)

	// Read the JSON file into your variable
	var vars TestTfvars
	bytes, err := os.ReadFile(jsonOutPath)
	assert.NoError(t, err)
	err = json.Unmarshal(bytes, &vars)
	assert.NoError(t, err)

	// Extract the names from the stages
	expectedStages := make([]string, len(vars.Stages))
	for i, stage := range vars.Stages {
		expectedStages[i] = stage.Name
	}

	actualStages := make([]string, len(pipeline.Stages))
	for i, stage := range pipeline.Stages {
		actualStages[i] = *stage.Name
	}
	assert.ElementsMatch(t, expectedStages, actualStages, "Stages do not match")
	logger.Log(t, "Pipeline stages match expected")
}

func tearDownPipeline(t *testing.T, dir string) {
	terraformOptions := test_structure.LoadTerraformOptions(t, dir)
	terraform.Destroy(t, terraformOptions)
}
