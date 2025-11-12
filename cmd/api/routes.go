package main

import (
	"net/http"
	"github.com/julienschmidt/httprouter"
)

func (a *applicationDependencies) routes() http.Handler {
	router := httprouter.New()

	// Custom error handlers
	router.NotFound = http.HandlerFunc(a.notFoundResponse)
	router.MethodNotAllowed = http.HandlerFunc(a.methodNotAllowedResponse)

	// Register handlers
	router.HandlerFunc(http.MethodGet, "/v1/healthcheck", a.healthCheckHandler)
	router.HandlerFunc(http.MethodPost, "/v1/moods", a.createMoodHandler)
	router.HandlerFunc(http.MethodGet, "/v1/moods/:id", a.showMoodHandler)

	return router
}