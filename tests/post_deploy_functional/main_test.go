package test

import (
	"testing"

	"github.com/launchbynttdata/lcaf-component-terratest/lib"
	"github.com/launchbynttdata/lcaf-component-terratest/types"
	"github.com/launchbynttdata/tf-aws-module_primitive-codepipeline/tests/testimpl"
)

const (
	testConfigsExamplesFolderDefault = "../../examples"
	infraTFVarFileNameDefault        = "test.tfvars"
)

func TestCodePipelineModule(t *testing.T) {
	ctx := types.CreateTestContextBuilder().
		SetTestConfig(&testimpl.ThisTFModuleConfig{}).
		SetTestConfigFolderName(testConfigsExamplesFolderDefault).
		SetTestConfigFileName(infraTFVarFileNameDefault).
		SetTestSpecificFlags(map[string]types.TestFlags{
			"complete": {
				"IS_TERRAFORM_IDEMPOTENT_APPLY": false,
			},
		}).
		Build()

	lib.RunSetupTestTeardown(t, *ctx, testimpl.TestComposableComplete)
}
