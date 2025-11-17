package backend

import (
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io"
)

func CreateTestRunResult(testRunId string, testRunnerId string, logs []byte, status string) error {
	body := map[string]string{
		"test_run_id":    testRunId,
		"test_runner_id": testRunnerId,
		"status":         status,
		"logs_base64":    base64.StdEncoding.EncodeToString(logs),
	}

	bodyJson, err := json.Marshal(body)
	if err != nil {
		return fmt.Errorf("failed to marshal JSON: %w", err)
	}

	resp, err := PerformRequest("POST", "/services/test_runner/create_test_run_result", bodyJson)
	if err != nil {
		return fmt.Errorf("HTTP request failed: %w", err)
	}
	defer resp.Body.Close()

	fmt.Printf("Response: %d\n", resp.StatusCode)

	bodyBytes, err := io.ReadAll(resp.Body)
	if err != nil {
		return fmt.Errorf("failed to read response body: %w", err)
	}

	if resp.StatusCode != 200 {
		return fmt.Errorf("unexpected HTTP status %d. Body: %s", resp.StatusCode, string(bodyBytes))
	}

	return nil
}
