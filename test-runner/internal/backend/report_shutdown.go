package backend

import (
	"encoding/json"
	"fmt"
	"io"
)

func ReportShutdown(testRunnerId string) error {
	body := map[string]string{
		"test_runner_id": testRunnerId,
	}

	bodyJson, err := json.Marshal(body)
	if err != nil {
		return fmt.Errorf("failed to marshal JSON: %w", err)
	}

	resp, err := PerformRequest("POST", "/services/test_runner/report_shutdown", bodyJson)
	if err != nil {
		return fmt.Errorf("HTTP request failed: %w", err)
	}
	defer resp.Body.Close()

	fmt.Printf("Response: %d\n", resp.StatusCode)

	bodyBytes, err := io.ReadAll(resp.Body)
	if err != nil {
		return fmt.Errorf("failed to read response body: %w", err)
	}

	if resp.StatusCode == 200 {
		return nil
	} else {
		return fmt.Errorf("unexpected HTTP status %d. Body: %s", resp.StatusCode, string(bodyBytes))
	}
}
