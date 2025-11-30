package backend

import (
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io"
)

func FinalizeBuild(buildId string, status string, logs []byte) error {
	body := map[string]string{
		"test_runner_build_id": buildId,
		"status":               status,
		"logs_base64":          base64.StdEncoding.EncodeToString(logs),
	}

	bodyJson, err := json.Marshal(body)
	if err != nil {
		return fmt.Errorf("failed to marshal JSON: %w", err)
	}

	resp, err := PerformRequest("POST", "/services/test_runner_builder/finalize_test_runner_build", bodyJson)
	if err != nil {
		return fmt.Errorf("HTTP request failed: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode == 200 {
		return nil
	} else {

		bodyBytes, err := io.ReadAll(resp.Body)
		if err != nil {
			return fmt.Errorf("unexpected HTTP status %d. Body read error: %w", resp.StatusCode, err)
		}

		return fmt.Errorf("unexpected HTTP status %d. Body: %s", resp.StatusCode, string(bodyBytes))
	}
}
