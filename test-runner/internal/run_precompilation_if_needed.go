package internal

import (
	"errors"
	"fmt"
	"os"
	"os/exec"
	"path"

	"github.com/egym-playground/go-prefix-writer/prefixer"
)

func RunPrecompilationIfNeeded(testRun *TestRun, repositoryDir string) error {
	logWriter := testRun
	logWithPrefixWriter := prefixer.New(logWriter, func() string { return "\033[33m[compile]\033[0m " })

	newPrecompileFilePath := path.Join(repositoryDir, ".codecrafters/compile.sh")
	legacyPrecompileFilePath := "/codecrafters-precompile.sh"

	var precompileFilePath string
	_, newPrecompileFilePathErr := os.Stat(newPrecompileFilePath)
	_, legacyPrecompileFilePathErr := os.Stat(legacyPrecompileFilePath)

	if newPrecompileFilePathErr == nil {
		precompileFilePath = newPrecompileFilePath
	} else if legacyPrecompileFilePathErr == nil {
		precompileFilePath = legacyPrecompileFilePath
	} else if !errors.Is(newPrecompileFilePathErr, os.ErrNotExist) { // new script exists but failed to stat
		return &FriendlyError{
			UserError:     "CodeCrafters internal error: failed to stat precompile script: " + newPrecompileFilePathErr.Error(),
			InternalError: "failed to stat precompile script: " + newPrecompileFilePathErr.Error(),
		}
	} else if !errors.Is(legacyPrecompileFilePathErr, os.ErrNotExist) { // legacy script exists but failed to stat
		return &FriendlyError{
			UserError:     "CodeCrafters internal error: failed to stat precompile script: " + legacyPrecompileFilePathErr.Error(),
			InternalError: "failed to stat precompile script: " + legacyPrecompileFilePathErr.Error(),
		}
	}

	// No precompile script found
	if precompileFilePath == "" {
		return nil
	}

	cmd := exec.Command("sh", precompileFilePath)
	cmd.Env = os.Environ()
	cmd.Env = append(cmd.Env, fmt.Sprintf("CODECRAFTERS_SUBMISSION_DIR=%s", repositoryDir)) // TODO: Legacy, remove
	cmd.Env = append(cmd.Env, fmt.Sprintf("CODECRAFTERS_REPOSITORY_DIR=%s", repositoryDir))
	cmd.Stdout = logWithPrefixWriter
	cmd.Stderr = logWithPrefixWriter

	err := cmd.Run()
	if _, ok := err.(*exec.ExitError); ok {
		logWithPrefixWriter.Write([]byte("\033[31mLooks like your code failed to compile.\033[0m\n"))
		logWithPrefixWriter.Write([]byte("\033[31mIf you think this is a CodeCrafters error, please let us know at hello@codecrafters.io.\033[0m\n"))
		logWriter.Write([]byte("\n"))

		return &FriendlyError{
			UserError:     "Compilation failed (user error!)",
			InternalError: "Compilation failed (internal error!)",
			IsLogged:      true,
		}
	} else if err != nil {
		return &FriendlyError{
			UserError:     "CodeCrafters internal error: failed to run precompile script: " + err.Error(),
			InternalError: "failed to run precompile script: " + err.Error(),
		}
	}

	return nil
}
