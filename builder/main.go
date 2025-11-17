package main

import (
	"fmt"
	"os"

	"github.com/codecrafters-io/test-runner-builder/internal/commands"
	"github.com/codecrafters-io/test-runner-builder/internal/utils"
	"github.com/getsentry/sentry-go"
)

func main() {
	utils.InitSentry()
	defer utils.TeardownSentry()

	// Used to check if the test runner is installed in the dockerfile
	if len(os.Args) == 2 && os.Args[1] == "--version" {
		fmt.Println("Test runner installed!")
		os.Exit(0)
	}

	exitCode := 0

	func() {
		defer sentry.Recover() // Ensure panics are captured and sent to Sentry
		exitCode = commands.BuildImageCommand()
	}()

	os.Exit(exitCode)
}
