package main

import (
	"flag"
	"fmt"
	"log/slog"
	"net/http"
	"os"
	"time"
	"context"
	"database/sql"

	_"github.com/lib/pq"
)

const appVersion = "1.0.0"

type serverConfig struct {
	port int
	env  string
	db struct {
		dsn string
	}
}

type applicationDependencies struct {
	config serverConfig
	logger *slog.Logger
}

func main() {
	var settings serverConfig

	flag.IntVar(&settings.port, "port", 4000, "Server port")
	flag.StringVar(&settings.env, "env", "development", "Environment (development|staging|production)")
	flag.StringVar(&settings.db.dsn, "db-dsn", "postgres://moods:fishsticks@localhost/moods?sslmode=disable", "PostgreSQL DSN")
	flag.Parse()

	logger := slog.New(slog.NewTextHandler(os.Stdout, nil))

	db, err := openDB(settings)
	if err != nil {
		logger.Error(err.Error())
		os.Exit(1)
	}
	defer db.Close()
	logger.Info("database connection pool established")

	appInstance := &applicationDependencies{
		config: settings,
		logger: logger,
	}

	router := http.NewServeMux()
	router.HandleFunc("/v1/healthcheck", appInstance.healthCheckHandler)

	apiServer := &http.Server{
		Addr:         fmt.Sprintf(":%d", settings.port),
		Handler:      router,
		IdleTimeout:  time.Minute,
		ReadTimeout:  5 * time.Second,
		WriteTimeout: 10 * time.Second,
		ErrorLog:     slog.NewLogLogger(logger.Handler(), slog.LevelError),
	}

	logger.Info("starting server", "address", apiServer.Addr, "environment", settings.env)

	err := apiServer.ListenAndServe()
	logger.Error(err.Error())
	os.Exit(1)
}

func (a *applicationDependencies) healthCheckHandler(w http.ResponseWriter, r *http.Request) {
    data := envelope{
        "status": "available",
        "system_info": map[string]string{
            "environment": a.config.env,
            "version":     appVersion,
        },
    }

    err := a.writeJSON(w, http.StatusOK, data, nil)
    if err != nil {
        a.logger.Error(err.Error())
        http.Error(w, "The server encountered a problem and could not process your request", http.StatusInternalServerError)
    }
}

func openDB(settings serverConfig) (*sql.DB, error) {
    db, err := sql.Open("postgres", settings.db.dsn)
    if err != nil {
        return nil, err
    }

    ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
    defer cancel()

    err = db.PingContext(ctx)
    if err != nil {
        return nil, err
    }

    return db, nil
}