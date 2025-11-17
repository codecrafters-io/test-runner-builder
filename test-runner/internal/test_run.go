package internal

import (
	"fmt"
	"io"
	"os"

	"github.com/codecrafters-io/logstream/redis"
)

type TestRun struct {
	ID            string
	CommitSHA     string
	TestCasesJSON string
	LogstreamURL  string

	logstreamWriter *redis.Producer
	logsFile        *os.File
}

func (t *TestRun) InitLogging() error {
	logstreamWriter, err := redis.NewProducer(t.LogstreamURL)
	if err != nil {
		return fmt.Errorf("failed to create logstream writer: %w", err)
	}

	logsFile, err := os.CreateTemp("", "test-run")
	if err != nil {
		return fmt.Errorf("failed to create temporary file: %w", err)
	}

	t.logstreamWriter = logstreamWriter
	t.logsFile = logsFile

	return nil
}

func (t *TestRun) CleanupLogging() {
	if t.logsFile != nil {
		err := os.Remove(t.logsFile.Name())
		if err != nil {
			fmt.Printf("CodeCrafters Internal Error: unable to delete logs file: %v\n", err)
		}

		t.logsFile = nil
	}
}

func (t *TestRun) ReadLogsFromFile() ([]byte, error) {
	t.logsFile.Seek(0, 0)
	logs, err := io.ReadAll(t.logsFile)
	if err != nil {
		return nil, fmt.Errorf("failed to read logs from file: %w", err)
	}

	return logs, nil
}

func (t *TestRun) Write(p []byte) (n int, err error) {
	_, logStreamError := t.logstreamWriter.Write(p)
	_, fileError := t.logsFile.Write(p)
	_, _ = os.Stdout.Write(p)

	if logStreamError != nil {
		return 0, fmt.Errorf("failed to write to logstream: %w", logStreamError)
	}

	if fileError != nil {
		return 0, fmt.Errorf("failed to write to file: %w", fileError)
	}

	return len(p), nil
}

func (t *TestRun) Close() {
	t.logstreamWriter.Close()
	t.logsFile.Close()
}
