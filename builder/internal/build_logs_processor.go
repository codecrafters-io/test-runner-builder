package internal

import (
	"fmt"
	"io"
	"regexp"
)

type buildLogsProcessor struct {
	// lastLine          []byte
	currentBuildStepLine []byte
	writer               io.Writer
}

var buildStepLineRegex = regexp.MustCompile(`^#(\d+) \[[^\]]+\] (.*)$`)
var buildStepDoneRegex = regexp.MustCompile(`^#(\d+) DONE .*$`)
var buildStepCachedRegex = regexp.MustCompile(`^#(\d+) CACHED.*$`)
var buildProgressLineRegex = regexp.MustCompile(`^#(\d+) [\d.]+ (.*)$`)
var buildErrorLineRegex = regexp.MustCompile(`^#(\d+) ERROR: (.*)$`)

// func (p *buildLogsProcessor) currentBuildStepNumber() string {
// 	return string(buildStepLineRegex.FindSubmatch(p.currentBuildStepLine)[1])
// }

func (p *buildLogsProcessor) OnLogLine(line []byte) {
	// p.writer.Write(append([]byte("[Verbose Logger] "), line...))
	if buildStepLineRegex.Match(line) {
		// Ignore the line
		p.currentBuildStepLine = line
	} else if buildStepDoneRegex.Match(line) {
		stepNumber := buildStepDoneRegex.FindSubmatch(line)[1]
		p.writer.Write([]byte(fmt.Sprintf("Step %s complete.\n", stepNumber)))
		p.currentBuildStepLine = nil
	} else if buildStepCachedRegex.Match(line) {
		stepNumber := buildStepCachedRegex.FindSubmatch(line)[1]
		p.writer.Write([]byte(fmt.Sprintf("Step %s complete.\n", stepNumber)))
		p.currentBuildStepLine = nil
	} else if buildErrorLineRegex.Match(line) {
		error := string(buildErrorLineRegex.FindSubmatch(line)[2])
		p.writer.Write([]byte(fmt.Sprintf("Error: %s.\n", error)))
	} else {
		if p.currentBuildStepLine == nil {
			// Ignore the line
		} else {
			if buildProgressLineRegex.Match(line) {
				progressText := string(buildProgressLineRegex.FindSubmatch(line)[2])
				p.writer.Write([]byte(fmt.Sprintf("> %s\n", progressText)))
			}
		}
	}
}

func NewBuildLogsProcessor(writer io.Writer) *buildLogsProcessor {
	return &buildLogsProcessor{
		writer: writer,
	}
}
