package internal

import (
	"fmt"
	"os"
	"os/exec"
	"path"
)

func RunTester(testRun *TestRun, repositoryDir string, testerDir string) (bool, error) {
	cmd := exec.Command(path.Join(testerDir, "test.sh"))
	cmd.Env = os.Environ()
	cmd.Env = append(cmd.Env, "PYTHONUNBUFFERED=true")                                      // TODO: Move this to dockerfile?
	cmd.Env = append(cmd.Env, fmt.Sprintf("CODECRAFTERS_SUBMISSION_DIR=%s", repositoryDir)) // TODO: Legacy, remove
	cmd.Env = append(cmd.Env, fmt.Sprintf("CODECRAFTERS_REPOSITORY_DIR=%s", repositoryDir))
	cmd.Env = append(cmd.Env, fmt.Sprintf("TESTER_DIR=%s", testerDir))
	cmd.Env = append(cmd.Env, fmt.Sprintf("CODECRAFTERS_TEST_CASES_JSON=%s", testRun.TestCasesJSON))
	cmd.Stdout = testRun
	cmd.Stderr = testRun

	err := cmd.Run()
	if exitError, ok := err.(*exec.ExitError); ok {
		if exitError.ExitCode() != 0 && exitError.ExitCode() != 1 {
			return false, err
		}

		return exitError.ExitCode() == 0, nil
	} else if err != nil {
		return false, err
	}

	return true, nil
}
