package testimpl

import "github.com/launchbynttdata/lcaf-component-terratest/types"

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

type ThisTFModuleConfig struct {
	types.GenericTFModuleConfig
	Name   string  `json:"name"`
	Stages []Stage `json:"stages"`
}
