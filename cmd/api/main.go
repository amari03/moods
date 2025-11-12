package main

import (
	"context"
	"database/sql"
	"feel-flow-api/internal/data"
	"flag"
	"log/slog"
	"os"
	"time"

	_ "github.com/lib/pq"
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
	models data.Models
}

type Models struct{
	Moods data.MoodModel
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
		models: data.Models{
			Moods: data.MoodModel{DB: db},
		},
	}

	err = appInstance.serve()
	if err != nil {
    	logger.Error(err.Error())
    	os.Exit(1)
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