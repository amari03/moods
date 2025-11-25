package main

import (
	"context"
	"database/sql"
	"flag"
	"log/slog"
	"os"
	"time"
	"sync"
	"strings"
	"net/http"

	"feel-flow-api/internal/mailer"
	"feel-flow-api/internal/data"
	"feel-flow-api/internal/quotes"

	_ "github.com/lib/pq"
)

const appVersion = "1.0.0"

type serverConfig struct {
	port int
	env  string
	db struct {
		dsn string
	}
	smtp struct {
		host string
		port int
		username string
		password string
		sender string
	}
	cors struct {
		trustedOrigins []string
	}
}

type applicationDependencies struct {
	config serverConfig
	logger *slog.Logger
	models data.Models
	mailer mailer.Mailer
	quotes *quotes.Client 
	wg     sync.WaitGroup
}

type Models struct{
	Moods data.MoodModel
	Users data.UserModel
}

func main() {
	var settings serverConfig

	flag.IntVar(&settings.port, "port", 4000, "Server port")
	flag.StringVar(&settings.env, "env", "development", "Environment (development|staging|production)")
	flag.StringVar(&settings.db.dsn, "db-dsn", os.Getenv("FEEL_FLOW_DB_DSN"), "PostgreSQL DSN")

	// Add SMTP flags
	flag.StringVar(&settings.smtp.host, "smtp-host", os.Getenv("SMTP_HOST"), "SMTP host")
	flag.IntVar(&settings.smtp.port, "smtp-port", 2525, "SMTP port")
	flag.StringVar(&settings.smtp.username, "smtp-username", os.Getenv("SMTP_USERNAME"), "SMTP username")
	flag.StringVar(&settings.smtp.password, "smtp-password", os.Getenv("SMTP_PASSWORD"), "SMTP password")
	flag.StringVar(&settings.smtp.sender, "smtp-sender", os.Getenv("SMTP_SENDER"), "SMTP sender")

	flag.Func("cors-trusted-origins", "Trusted CORS origins (space separated)", func(val string) error {
		settings.cors.trustedOrigins = strings.Fields(val)
		return nil
	})

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
		models: data.NewModels(db),
		mailer: mailer.New(settings.smtp.host, settings.smtp.port, settings.smtp.username, settings.smtp.password, settings.smtp.sender),
		quotes: quotes.NewClient(),
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

// In a handlers file or in main.go

// getQuoteHandler handles requests for a random quote.
func (app *applicationDependencies) getQuoteHandler(w http.ResponseWriter, r *http.Request) {
	// Call our new service method.
	quote, err := app.quotes.GetRandomQuote(r.Context())
	if err != nil {
		// I'm assuming you have a serverErrorResponse helper.
		// If not, you can just log the error and write a 500 status.
		app.serverErrorResponse(w, r, err) 
		return
	}

	envelope := map[string]any{"quote": quote}

	// Pass the envelope to your writeJSON helper.
	err = app.writeJSON(w, http.StatusOK, envelope, nil)
	if err != nil {
		app.serverErrorResponse(w, r, err)
	}
}