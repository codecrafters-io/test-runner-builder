package internal

import (
	"fmt"
	"os/exec"
	"strings"
)

func GetHeadCommitSha(repositoryDir string) (string, error) {
	cmd := exec.Command("git", "-C", repositoryDir, "rev-parse", "HEAD")

	output, err := cmd.CombinedOutput()
	if err != nil {
		return "", fmt.Errorf("failed to get HEAD commit SHA: %w. Output: %v", err, string(output))
	}

	return strings.TrimSpace(string(output)), nil
}
