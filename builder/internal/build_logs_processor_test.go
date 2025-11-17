package internal

import (
	"bytes"
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestBuildLogsProcessorSimple(t *testing.T) {
	bytesBuffer := bytes.NewBuffer([]byte{})
	p := NewBuildLogsProcessor(bytesBuffer)

	p.OnLogLine([]byte("#1 [depot] build: xxx"))
	p.OnLogLine([]byte("#1 DONE 0.0s"))
	p.OnLogLine([]byte(""))
	p.OnLogLine([]byte("#2 [depot] launching amd64 machine"))
	p.OnLogLine([]byte("#2 DONE 0.3s"))

	assert.Equal(t, "Step 1 complete.\nStep 2 complete.\n", bytesBuffer.String())
}

func TestBuildLogsProcessorCached(t *testing.T) {
	bytesBuffer := bytes.NewBuffer([]byte{})
	p := NewBuildLogsProcessor(bytesBuffer)

	logs := `
#26 [19/21] WORKDIR /app
#26 CACHED

#27 [20/21] COPY . /app
#27 DONE 0.2s
`

	logLines := bytes.Split([]byte(logs), []byte("\n"))

	for _, line := range logLines {
		p.OnLogLine(line)
	}

	assert.Equal(t, "Step 26 complete.\nStep 27 complete.\n", bytesBuffer.String())
}

func TestBuildLogsProcessorRunCommandProgress(t *testing.T) {
	bytesBuffer := bytes.NewBuffer([]byte{})
	p := NewBuildLogsProcessor(bytesBuffer)

	logs := `
#13 [ 6/21] WORKDIR /app
#13 DONE 0.0s

#14 [ 7/21] RUN cargo build --release --target-dir=/tmp/codecrafters-redis-target
#14 0.600 Updating crates.io index
#14 0.678 Downloading crates...
#14 DONE 8.3s

#15 [ 8/21] RUN rm /tmp/codecrafters-redis-target/release/redis-starter-rust
#15 DONE 0.2s
`

	logLines := bytes.Split([]byte(logs), []byte("\n"))

	for _, line := range logLines {
		p.OnLogLine(line)
	}

	assert.Equal(t, "Step 13 complete.\n> Updating crates.io index\n> Downloading crates...\nStep 14 complete.\nStep 15 complete.\n", bytesBuffer.String())
}
