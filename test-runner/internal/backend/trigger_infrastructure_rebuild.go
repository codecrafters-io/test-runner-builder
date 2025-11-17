package backend

import (
	"encoding/json"
	"fmt"
	"io"
)

type TriggerInfrastructureRebuildResponse struct {
	ID           string `json:"id"`
	CommitSHA    string `json:"commit_sha"`
	LogstreamURL string `json:"logstream_url"`
}

func TriggerInfrastructureRebuild(testRunId string, testRunnerId string) (TriggerInfrastructureRebuildResponse, error) {
	body := map[string]string{
		"test_run_id":    testRunId,
		"test_runner_id": testRunnerId,
	}

	bodyJson, err := json.Marshal(body)
	if err != nil {
		return TriggerInfrastructureRebuildResponse{}, fmt.Errorf("failed to marshal JSON: %w", err)
	}

	resp, err := PerformRequest("POST", "/services/test_runner/rebuild_for_test_run", bodyJson)
	if err != nil {
		return TriggerInfrastructureRebuildResponse{}, fmt.Errorf("HTTP request failed: %w", err)
	}

	defer resp.Body.Close()
	bodyBytes, err := io.ReadAll(resp.Body)
	if err != nil {
		return TriggerInfrastructureRebuildResponse{}, fmt.Errorf("failed to read response body: %w", err)
	}

	if resp.StatusCode != 200 {
		return TriggerInfrastructureRebuildResponse{}, fmt.Errorf("unexpected HTTP status %d. Body: %s", resp.StatusCode, string(bodyBytes))
	}

	buildResponse := &TriggerInfrastructureRebuildResponse{}
	err = json.Unmarshal(bodyBytes, buildResponse)

	if err != nil {
		return TriggerInfrastructureRebuildResponse{}, fmt.Errorf("failed to parse response into submission: %w", err)
	}

	return *buildResponse, nil
}
