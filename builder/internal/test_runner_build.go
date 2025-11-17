package internal

import (
	"fmt"
	"io"
	"os"

	"github.com/codecrafters-io/logstream/redis"
)

type TestRunnerBuild struct {
	ID                  string
	CommitSHA           string
	LogstreamURL        string
	TestRunLogstreamURL string // Logstream URL for a test run that's waiting on this build.

	logstreamWriter        *redis.Producer
	logsFile               *os.File
	testRunLogstreamWriter *redis.Producer
}

func (b *TestRunnerBuild) InitLogging() error {
	logstreamWriter, err := redis.NewProducer(b.LogstreamURL)
	if err != nil {
		return fmt.Errorf("failed to create logstream writer: %w", err)
	}

	b.logstreamWriter = logstreamWriter

	logsFile, err := os.CreateTemp("", "test-runner-build")
	if err != nil {
		return fmt.Errorf("failed to create temporary file: %w", err)
	}

	b.logsFile = logsFile

	if b.TestRunLogstreamURL != "" {
		testRunLogstreamWriter, err := redis.NewProducer(b.TestRunLogstreamURL)
		if err != nil {
			return fmt.Errorf("failed to create test run logstream writer: %w", err)
		}

		b.testRunLogstreamWriter = testRunLogstreamWriter
	}

	return nil
}

func (b *TestRunnerBuild) CleanupLogging() {
	if b.logsFile != nil {
		err := os.Remove(b.logsFile.Name())
		if err != nil {
			fmt.Printf("CodeCrafters Internal Error: unable to delete logs file: %v\n", err)
		}

		b.logsFile = nil
	}
}

func (b *TestRunnerBuild) ReadLogsFromFile() ([]byte, error) {
	b.logsFile.Seek(0, 0)
	logs, err := io.ReadAll(b.logsFile)
	if err != nil {
		return nil, fmt.Errorf("failed to read logs from file: %w", err)
	}

	return logs, nil
}

func (b *TestRunnerBuild) Write(p []byte) (n int, err error) {
	_, logStreamError := b.logstreamWriter.Write(p)
	_, fileError := b.logsFile.Write(p)
	os.Stdout.Write(p)

	if logStreamError != nil {
		return 0, fmt.Errorf("failed to write to logstream: %w", logStreamError)
	}

	if fileError != nil {
		return 0, fmt.Errorf("failed to write to file: %w", fileError)
	}

	if b.testRunLogstreamWriter != nil {
		_, testRunLogStreamError := b.testRunLogstreamWriter.Write(p)

		if testRunLogStreamError != nil {
			return 0, fmt.Errorf("failed to write to test run logstream: %w", testRunLogStreamError)
		}
	}

	return len(p), nil
}

// We intentionally don't close b.testRunLogstreamWriter here because that'll need to receive test run logs later.
func (b *TestRunnerBuild) Close() {
	b.logstreamWriter.Close()
	b.logsFile.Close()
}
