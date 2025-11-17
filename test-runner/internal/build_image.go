package internal

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"

	"github.com/codecrafters-io/test-runner/internal/globals"
	"github.com/egym-playground/go-prefix-writer/prefixer"
	cp "github.com/otiai10/copy"
	"gvisor.dev/gvisor/pkg/linewriter"
)

type RemoteDockerImageConfiguration struct {
	ImageName        string
	ImageTag         string
	RegistryDomain   string
	RegistryUsername string
	RegistryPassword string
	DepotToken       string
	DepotProject     string
}

func (c RemoteDockerImageConfiguration) FullTag() string {
	return fmt.Sprintf("%s/%s:%s", c.RegistryDomain, c.ImageName, c.ImageTag)
}

func BuildImage(build *TestRunnerBuild, dockerImageConfiguration RemoteDockerImageConfiguration, repositoryDir string, dockerfilePath string, testerDir string, testRunnerDir string, repositoryId string) (bool, error) {
	newTesterDir := filepath.Join(repositoryDir, "tester")
	newTestRunnerDir := filepath.Join(repositoryDir, "test-runner")

	for _, dir := range []string{newTesterDir, newTestRunnerDir} {
		if _, err := os.Stat(dir); !os.IsNotExist(err) {
			removeErr := os.RemoveAll(dir)
			if removeErr != nil {
				return false, fmt.Errorf("failed to remove directory: %w", removeErr)
			}
		}
	}

	if err := cp.Copy(testerDir, newTesterDir); err != nil {
		return false, fmt.Errorf("failed to copy tester directory: %w", err)
	}

	if err := cp.Copy(testRunnerDir, newTestRunnerDir); err != nil {
		return false, fmt.Errorf("failed to copy test-runner directory: %w", err)
	}

	commandParts := []string{
		"depot",
		"build",
		"--provenance", "false",
		"--token", dockerImageConfiguration.DepotToken,
		"--project", dockerImageConfiguration.DepotProject,
		"--tag", dockerImageConfiguration.FullTag(),
		"--file", dockerfilePath,
		"--build-arg", fmt.Sprintf("REPOSITORY_ID=%s", repositoryId),
		"--build-arg", fmt.Sprintf("CODECRAFTERS_SERVER_URL=%s", globals.GetCodecraftersServerURL()),
		"--push",
		repositoryDir,
	}

	cmd := exec.Command(commandParts[0], commandParts[1:]...)

	userLogsSink := build
	prefixedWriter := prefixer.New(userLogsSink, func() string { return "\033[33m[build]\033[0m " })
	buildLogsProcessor := NewBuildLogsProcessor(prefixedWriter)
	lineWriter := linewriter.NewWriter(func(p []byte) { buildLogsProcessor.OnLogLine(p) })

	cmd.Stdout = lineWriter // Stdout isn't relevant for builds
	cmd.Stderr = lineWriter // Let's send both raw and prefixed logs to stderr

	prefixedWriter.Write([]byte(fmt.Sprintf("\033[34m%s\033[0m\n", "Starting build...")))
	prefixedWriter.Write([]byte(fmt.Sprintf("\033[34m%s\033[0m\n", "If you don't see logs for 60s+, please contact us at hello@codecrafters.io")))

	fmt.Printf("Running command: %s\n", cmd.String())

	// TODO: More prefixedWriter logs?

	err := cmd.Run() // Also prints logs, since we set cmd.Stdout and cmd.Stderr

	if exitError, ok := err.(*exec.ExitError); ok {
		prefixedWriter.Write([]byte("\033[31mBuild failed. Check the logs above for the reason.\033[0m\n"))
		prefixedWriter.Write([]byte("\033[31mIf you think this is a CodeCrafters error, please contact us at hello@codecrafters.io.\033[0m\n"))
		userLogsSink.Write([]byte("\n"))
		return exitError.ExitCode() == 0, nil
	}

	if err != nil {
		prefixedWriter.Write([]byte("\033[31mBuild failed. Check the logs above for the reason.\033[0m\n"))
		prefixedWriter.Write([]byte("\033[31mIf you think this is a CodeCrafters error, please contact us at hello@codecrafters.io.\033[0m\n"))
		userLogsSink.Write([]byte("\n"))
		return false, nil // If the build command itself fails, for now we'll assume it was a user error.
	}

	prefixedWriter.Write([]byte("\033[32mBuild successful.\033[0m\n"))
	userLogsSink.Write([]byte("\n"))

	// Ensure we don't leave any unflushed logs
	if build.testRunLogstreamWriter != nil {
		if err := build.testRunLogstreamWriter.Flush(); err != nil {
			// Don't report a user error for now
			fmt.Printf("CodeCrafters Internal Error: failed to flush logs: %v\n", err)
		}
	}

	return true, nil
}
