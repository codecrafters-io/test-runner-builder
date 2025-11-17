package utils

import (
	"os"
	"time"

	"github.com/getsentry/sentry-go"
)

var defaultSentryDSN = "https://cf3aff40fb414dcc9311747852872623@o294739.ingest.us.sentry.io/5859980"

func InitSentry() {
	dsn, ok := os.LookupEnv("SENTRY_DSN")
	if !ok {
		dsn = defaultSentryDSN
	}

	err := sentry.Init(sentry.ClientOptions{
		Dsn:              dsn,
		Debug:            os.Getenv("SENTRY_DEBUG") == "1",
		TracesSampleRate: 1.0,
	})
	_ = err // ignore
}

func TeardownSentry() {
	sentry.Flush(time.Second)
}
