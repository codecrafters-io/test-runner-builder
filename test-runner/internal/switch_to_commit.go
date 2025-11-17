package internal

import (
	"context"
	"fmt"
	"os"
	"os/exec"
	"time"
)

func SwitchToCommit(repositoryDir string, newCommitSHA string) error {
	commands := []struct {
		name    string
		args    []string
		errMsg  string
		timeout time.Duration
	}{
		// Clean up any untracked files, (such as dummy ones created in the Dockerfile)
		{
			name:    "git",
			args:    []string{"-C", repositoryDir, "clean", "-fd"},
			errMsg:  "failed to clean repository",
			timeout: 2 * time.Second,
		},
		{
			name:    "git",
			args:    []string{"-C", repositoryDir, "fetch", "origin", newCommitSHA}, // This commit might not be on the default branch, so we need to fetch it specifically
			errMsg:  "failed to fetch commit from origin",
			timeout: 10 * time.Second,
		},
		{
			name:    "git",
			args:    []string{"-C", repositoryDir, "checkout", "-f", newCommitSHA},
			errMsg:  "failed to checkout commit",
			timeout: 10 * time.Second,
		},
	}

	for _, command := range commands {
		// Create a context with timeout
		ctx, cancel := context.WithTimeout(context.Background(), command.timeout)
		defer cancel()

		// Start command with context
		cmd := exec.CommandContext(ctx, command.name, command.args...)
		cmd.Stdout = os.Stdout
		cmd.Stderr = os.Stderr

		err := cmd.Run()
		if err != nil {
			// Check if the error is due to timeout
			if ctx.Err() == context.DeadlineExceeded {
				return fmt.Errorf("%s, timeout after %d seconds", command.errMsg, int(command.timeout.Seconds()))
			}

			return fmt.Errorf("%s, %w", command.errMsg, err)
		}
	}

	return nil
}
