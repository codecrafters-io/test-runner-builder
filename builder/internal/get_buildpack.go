package internal

import (
	"fmt"
	"os"
	"strings"

	"gopkg.in/yaml.v2"
)

func GetBuildpack(repositoryDir string) (string, error) {
	file, err := os.Open(fmt.Sprintf("%s/codecrafters.yml", repositoryDir))
	if err != nil {
		return "", &FriendlyError{
			UserError:     "Didn't find a codecrafters.yml file in your repository. This is required to run tests.",
			InternalError: fmt.Sprintf("failed to open codecrafters.yml. err=%s", err),
		}
	}
	defer file.Close()

	decoder := yaml.NewDecoder(file)
	var data map[string]interface{}
	err = decoder.Decode(&data)
	if err != nil {
		return "", &FriendlyError{
			UserError:     "Your codecrafters.yml file is not valid YAML. Please fix it and try again.",
			InternalError: fmt.Sprintf("failed to decode codecrafters.yml. err=%s", err),
		}
	}

	// Try buildpack first (new), then fall back to language_pack (old) for backwards compatibility
	if buildpack, ok := data["buildpack"].(string); ok {
		return strings.TrimSpace(buildpack), nil
	} else if languagePack, ok := data["language_pack"].(string); ok {
		return strings.TrimSpace(languagePack), nil
	} else {
		return "", &FriendlyError{
			UserError:     "Could not find buildpack in codecrafters.yml. Please make sure codecrafters.yml is a valid YAML file with a buildpack key.",
			InternalError: "codecrafters.yml is missing buildpack field",
		}
	}
}
