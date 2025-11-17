package main

import (
	"os"

	"github.com/codecrafters-io/test-runner/internal/commands"
	"github.com/codecrafters-io/test-runner/internal/utils"
	"github.com/getsentry/sentry-go"
)

func main() {
	utils.InitSentry()
	defer utils.TeardownSentry()

	exitCode := 0

	func() {
		defer sentry.Recover() // Ensure panics are captured and sent to Sentry
		exitCode = commands.BuildImageCommand()
	}()

	os.Exit(exitCode)
}
