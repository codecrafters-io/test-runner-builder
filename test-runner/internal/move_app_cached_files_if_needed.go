package internal

import (
	"fmt"
	"os"

	cp "github.com/otiai10/copy"
)

func MoveAppCachedFilesIfNeeded(repositoryDir string) error {
	if _, err := os.Stat("/app-cached"); !os.IsNotExist(err) {
		fmt.Printf("Moving /app-cached to %s\n", repositoryDir)

		err := cp.Copy("/app-cached", repositoryDir, cp.Options{
			PreserveTimes: true, // Some caching strategies rely on file timestamps
			PreserveOwner: true, // Some caching strategies rely on file ownership
		})
		if err != nil {
			return fmt.Errorf("failed to copy dir: %s", err)
		}
	}

	return nil
}
