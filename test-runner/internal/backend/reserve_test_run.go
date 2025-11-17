package backend

import (
	"encoding/json"
	"fmt"
	"io"
)

type HTTPStatusError struct {
	StatusCode int
}

func (e *HTTPStatusError) Error() string {
	return fmt.Sprintf("HTTP status %d", e.StatusCode)
}

type ReservedTestRun struct {
	ID            string `json:"id"`
	CommitSHA     string `json:"commit_sha"`
	TestCasesJSON string `json:"test_cases_json"`
	LogstreamURL  string `json:"logstream_url"`
}

type ReserveTestRunResponse struct {
	TestRun     *ReservedTestRun `json:"test_run"`
	ShouldRetry bool             `json:"should_retry"`
}

func ReserveTestRun(testRunnerId string) (ReserveTestRunResponse, error) {
	path := fmt.Sprintf("/services/test_runner/reserve_test_run?test_runner_id=%s", testRunnerId)

	resp, err := PerformRequest("POST", path, nil)
	if err != nil {
		return ReserveTestRunResponse{}, fmt.Errorf("HTTP request failed: %w", err)
	}

	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return ReserveTestRunResponse{}, fmt.Errorf("read response failed: %w", err)
	}

	fmt.Printf("Response (%d): %s\n", resp.StatusCode, string(body))

	// Handle legacy response (TODO: Remove this once we've migrated all clients)
	if resp.StatusCode == 202 {
		return ReserveTestRunResponse{ShouldRetry: false}, nil
	}

	if resp.StatusCode == 200 {
		var reserveTestRunResponse ReserveTestRunResponse

		if err = json.Unmarshal(body, &reserveTestRunResponse); err != nil {
			return ReserveTestRunResponse{}, fmt.Errorf("unable to parse response: %w", err)
		}

		return reserveTestRunResponse, nil
	} else {
		return ReserveTestRunResponse{}, &HTTPStatusError{StatusCode: resp.StatusCode}
	}
}
