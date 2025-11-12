package main

import (
	"fmt"
	"log/slog"
	"net/http"
	"time"
)

func (a *applicationDependencies) serve() error {
	apiServer := &http.Server{
		Addr:         fmt.Sprintf(":%d", a.config.port),
		Handler:      a.routes(),
		IdleTimeout:  time.Minute,
		ReadTimeout:  5 * time.Second,
		WriteTimeout: 10 * time.Second,
		ErrorLog:     slog.NewLogLogger(a.logger.Handler(), slog.LevelError),
	}

	a.logger.Info("starting server", "address", apiServer.Addr, "environment", a.config.env)

	return apiServer.ListenAndServe()
}