package commands

import (
	"flag"
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/codecrafters-io/test-runner/internal"
	"github.com/codecrafters-io/test-runner/internal/backend"
	"github.com/codecrafters-io/test-runner/internal/color"
	"github.com/codecrafters-io/test-runner/internal/globals"
)

// If err is FriendlyError, it's a user error. Otherwise, it's an internal error.
// TODO: Handle write errors if InitLogging actually failed?
func handleErrorDuringBuild(build *internal.TestRunnerBuild, logPrefix string, err error) int {
	if logPrefix != "" {
		fmt.Printf("%s: %s\n", logPrefix, err)
	} else {
		fmt.Printf("%s\n", err)
	}

	if build != nil {
		if friendlyErr, ok := err.(*internal.FriendlyError); ok {
			if !friendlyErr.IsLogged {
				lines := strings.Split(friendlyErr.UserError, "\n")
				for _, line := range lines {
					build.Write([]byte(fmt.Sprintf("%s\n", color.Red(line))))
				}
			}

			build.Write([]byte(fmt.Sprintf("%s\n", color.Red("If you think this is a CodeCrafters bug, please contact us at hello@codecrafters.io."))))

			if err = flushLogsAndFinalizeBuild(build, "failure"); err != nil {
				fmt.Printf("Failed to create build result: %s\n", err)
				return 1 // Failed to report
			} else {
				return 0 // User error
			}
		} else {
			build.Write([]byte(fmt.Sprintf("%s\n", color.Red(fmt.Sprintf("CodeCrafters internal error: %s", err)))))
			build.Write([]byte(fmt.Sprintf("%s\n", color.Red("Try again? Contact us at hello@codecrafters.io if this persists."))))

			// Best effort, we're still going to return 1 since the error is an internal error
			if err = flushLogsAndFinalizeBuild(build, "error"); err != nil {
				fmt.Printf("Failed to create build result: %s\n", err)
			}

			return 1
		}
	}
	return 1
}

func flushLogsAndFinalizeBuild(build *internal.TestRunnerBuild, status string) error {
	if status != "success" && status != "failure" && status != "error" {
		panic(fmt.Errorf("invalid status: %s", status))
	}

	logs, err := build.ReadLogsFromFile()
	if err != nil {
		return err
	}

	build.Close() // Ensure we close the logstream writer
	build.CleanupLogging()

	return backend.FinalizeBuild(build.ID, status, logs)
}

func BuildImageCommand() int {
	var buildCommitSha string
	var buildId string
	var buildLogstreamUrl string
	var buildTestRunLogstreamUrl string
	var buildpackDockerfilePath string
	var buildpackSlug string
	var codecraftersServerUrl string
	var courseSlug string
	var depotToken string
	var depotProject string
	var dockerImageName string
	var dockerImageTag string
	var dockerRegistryDomain string
	var dockerRegistryPassword string
	var dockerRegistryUsername string
	var repositoryDir string
	var repositoryId string
	var testRunnerDir string
	var testerDir string

	flag.StringVar(&buildCommitSha, "build-commit-sha", "", "The SHA of the commit to use for building")
	flag.StringVar(&buildId, "build-id", "", "The ID of the build")
	flag.StringVar(&buildLogstreamUrl, "build-logstream-url", "", "The Logstream URL of the build")
	flag.StringVar(&buildTestRunLogstreamUrl, "build-test-run-logstream-url", "", "The Logstream URL of a test run that's waiting on this build")
	flag.StringVar(&buildpackDockerfilePath, "buildpack-dockerfile-path", "", "The path to the buildpack Dockerfile")
	flag.StringVar(&buildpackSlug, "buildpack-slug", "", "The slug of the buildpack")
	flag.StringVar(&codecraftersServerUrl, "codecrafters-server-url", "", "The server URL of Codecrafters")
	flag.StringVar(&courseSlug, "course-slug", "", "The slug of the course")
	flag.StringVar(&depotToken, "depot-token", "", "The Depot token to use")
	flag.StringVar(&depotProject, "depot-project", "", "The Depot project to use")
	flag.StringVar(&dockerImageName, "docker-image-name", "", "The name of the Docker image")
	flag.StringVar(&dockerImageTag, "docker-image-tag", "", "The tag of the Docker image")
	flag.StringVar(&dockerRegistryDomain, "docker-registry-domain", "", "The domain of the Docker registry")
	flag.StringVar(&dockerRegistryPassword, "docker-registry-password", "", "The password of the Docker registry")
	flag.StringVar(&dockerRegistryUsername, "docker-registry-username", "", "The username of the Docker registry")
	flag.StringVar(&repositoryId, "repository-id", "", "The ID of the repository")
	flag.StringVar(&repositoryDir, "repository-dir", "", "The directory of the repository")
	flag.StringVar(&testRunnerDir, "test-runner-dir", "", "The directory of the test runner")
	flag.StringVar(&testerDir, "tester-dir", "", "The directory of the tester")

	flag.CommandLine.Parse(os.Args[1:]) // Use 1: to avoid the first command (the program name)

	if codecraftersServerUrl == "" {
		fmt.Println("codecrafters-server-url must be provided")
		os.Exit(1)
	}

	globals.SetCodecraftersServerURL(codecraftersServerUrl)

	fmt.Printf("buildId: %q, buildLogstreamUrl: %q\n", buildId, buildLogstreamUrl)

	build := &internal.TestRunnerBuild{
		CommitSHA:           buildCommitSha,
		ID:                  buildId,
		LogstreamURL:        buildLogstreamUrl,
		TestRunLogstreamURL: buildTestRunLogstreamUrl,
	}

	if err := build.InitLogging(); err != nil {
		return handleErrorDuringBuild(build, "Failed to initialize logging", err)
	}
	defer build.CleanupLogging()

	// Just making sure we don't use these again, and use values on build instead.
	buildId = ""
	buildLogstreamUrl = ""
	buildCommitSha = ""
	buildTestRunLogstreamUrl = ""

	flags := map[string]string{
		"buildpack-dockerfile-path": buildpackDockerfilePath,
		"buildpack-slug":            buildpackSlug,
		"course-slug":               courseSlug,
		"depot-token":               depotToken,
		"depot-project":             depotProject,
		"repository-id":             repositoryId,
		"repository-dir":            repositoryDir,
		"tester-dir":                testerDir,
		"test-runner-dir":           testRunnerDir,
		"docker-image-name":         dockerImageName,
		"docker-image-tag":          dockerImageTag,
		"docker-registry-domain":    dockerRegistryDomain,
		"docker-registry-username":  dockerRegistryUsername,
		"docker-registry-password":  dockerRegistryPassword,
	}

	for flagName, flagValue := range flags {
		fmt.Printf("%-30s: %q\n", flagName, flagValue)
		if flagValue == "" {
			return handleErrorDuringBuild(build, "", fmt.Errorf("%s must be provided", flagName))
		}
	}

	if _, err := os.Stat(testerDir); os.IsNotExist(err) {
		return handleErrorDuringBuild(build, "", fmt.Errorf("tester dir (%s) does not exist", testerDir))
	}

	if _, err := os.Stat(testRunnerDir); os.IsNotExist(err) {
		return handleErrorDuringBuild(build, "", fmt.Errorf("test runner dir (%s) does not exist", testRunnerDir))
	}

	if _, err := os.Stat(repositoryDir); os.IsNotExist(err) {
		return handleErrorDuringBuild(build, "", fmt.Errorf("repository dir (%s) does not exist", repositoryDir))
	}

	currentCommitSha, err := internal.GetHeadCommitSha(repositoryDir)
	if err != nil {
		return handleErrorDuringBuild(build, "Failed to get HEAD commit SHA", err)
	}

	if build.CommitSHA == "" {
		build.CommitSHA = currentCommitSha
	}

	if build.CommitSHA != currentCommitSha {
		fmt.Printf("Checking out commit %s\n", build.CommitSHA)
		if err := internal.SwitchToCommit(repositoryDir, build.CommitSHA); err != nil {
			return handleErrorDuringBuild(build, fmt.Sprintf("failed to checkout commit %s", build.CommitSHA), err)
		}
	} else {
		fmt.Println("HEAD commit SHA is same as expected")
	}

	buildpackSlugInRepo, friendlyErr := internal.GetBuildpack(repositoryDir)
	if friendlyErr != nil {
		return handleErrorDuringBuild(build, "Failed to get buildpack", friendlyErr)
	}

	if buildpackSlugInRepo != buildpackSlug {
		return handleErrorDuringBuild(build, "", &internal.FriendlyError{
			UserError: fmt.Sprintf("Detected changes to buildpack (old: %s, new: %s).\nThis isn't supported. If you're trying to upgrade to a new language version, please run `codecrafters update-buildpack`.", buildpackSlug, buildpackSlugInRepo),
		})
	}

	fmt.Printf("Buildpack Slug: %s\n", buildpackSlugInRepo)
	fmt.Printf("Buildpack Dockerfile: %s\n", buildpackDockerfilePath)

	if _, err := os.Stat(buildpackDockerfilePath); os.IsNotExist(err) {
		return handleErrorDuringBuild(build, "", fmt.Errorf("dockerfile (%s) does not exist", buildpackDockerfilePath))
	}

	dockerignorePath := filepath.Join(repositoryDir, ".dockerignore")
	if _, err := os.Stat(dockerignorePath); err == nil {
		if err := os.RemoveAll(dockerignorePath); err != nil {
			return handleErrorDuringBuild(build, "Failed to remove .dockerignore", err)
		}
	}

	buildWasSuccessful, err := internal.BuildImage(
		build,
		internal.RemoteDockerImageConfiguration{
			ImageName:        dockerImageName,
			ImageTag:         dockerImageTag,
			RegistryDomain:   dockerRegistryDomain,
			RegistryUsername: dockerRegistryUsername,
			RegistryPassword: dockerRegistryPassword,
			DepotToken:       depotToken,
			DepotProject:     depotProject,
		},
		repositoryDir,
		buildpackDockerfilePath,
		testerDir,
		testRunnerDir,
		repositoryId,
	)
	if err != nil {
		return handleErrorDuringBuild(build, "Failed to run tester", err)
	}

	if buildWasSuccessful {
		fmt.Println("Build was successful")

		err = flushLogsAndFinalizeBuild(build, "success")
		if err != nil {
			return handleErrorDuringBuild(build, "Failed to finalize build", err)
		}
	} else {
		fmt.Println("Build was not successful")

		err = flushLogsAndFinalizeBuild(build, "failure")
		if err != nil {
			return handleErrorDuringBuild(build, "Failed to finalize build", err)
		}
	}

	return 0
}
