package backend

import (
	"bytes"
	"fmt"
	"net/http"
	"time"

	"github.com/codecrafters-io/test-runner-builder/internal/globals"
	"github.com/google/uuid"
	"github.com/hashicorp/go-retryablehttp"
)

var globalClient = retryablehttp.NewClient()
var loggingEnabled = true

func init() {
	globalClient.HTTPClient.Timeout = 10 * time.Second
	globalClient.RetryWaitMin = 1 * time.Second
	globalClient.RetryWaitMax = 5 * time.Second
	globalClient.RetryMax = 5
}

func DisableLogging() {
	loggingEnabled = false
}

func EnableLogging() {
	loggingEnabled = true
}

func PerformRequest(method, path string, body []byte) (*http.Response, error) {
	req := newRequest(method, path, body)

	if loggingEnabled {
		fmt.Printf("%s %s (request_id: \"%s\")\n", req.Method, req.URL.String(), req.Header.Get("X-Request-Id"))
	}

	retryableReq, err := retryablehttp.FromRequest(req)
	if err != nil {
		panic("CodeCrafters Internal Error: Failed to create retryable HTTP request: " + err.Error())
	}

	return globalClient.Do(retryableReq)
}

func newRequest(method, path string, body []byte) *http.Request {
	if path[0] != '/' {
		panic("path must start with a slash")
	}

	url := fmt.Sprintf("%s%s", globals.GetCodecraftersServerURL(), path)
	req, err := http.NewRequest(method, url, bytes.NewBuffer(body))
	if err != nil {
		panic("CodeCrafters Internal Error: Failed to create HTTP request: " + err.Error())
	}

	req.Header.Add("Accept", "application/json")
	req.Header.Add("Content-type", "application/json")
	req.Header.Add("X-Request-Id", uuid.New().String())

	return req
}
