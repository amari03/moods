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

	// HealthCheck handler
	router.HandlerFunc(http.MethodGet, "/v1/healthcheck", a.healthCheckHandler)

	// Mood routes (ALL PROTECTED)
	router.HandlerFunc(http.MethodGet, "/v1/moods", a.requireActivatedUser(a.listMoodsHandler))
	router.HandlerFunc(http.MethodPost, "/v1/moods", a.requireActivatedUser(a.createMoodHandler))
	router.HandlerFunc(http.MethodGet, "/v1/moods/:id", a.requireActivatedUser(a.showMoodHandler))
	router.HandlerFunc(http.MethodPatch, "/v1/moods/:id", a.requireActivatedUser(a.updateMoodHandler))
	router.HandlerFunc(http.MethodDelete, "/v1/moods/:id", a.requireActivatedUser(a.deleteMoodHandler))

	// User routes (some public, some protected)
	router.HandlerFunc(http.MethodPost, "/v1/users", a.registerUserHandler)
	router.HandlerFunc(http.MethodPut, "/v1/users/activated", a.activateUserHandler)
	router.HandlerFunc(http.MethodPost, "/v1/tokens/authentication", a.createAuthenticationTokenHandler) // Add this route
	router.HandlerFunc(http.MethodPatch, "/v1/users/:id", a.requireActivatedUser(a.updateUserHandler))
	router.HandlerFunc(http.MethodDelete, "/v1/users/:id", a.requireActivatedUser(a.deleteUserHandler))
	
	return a.recoverPanic(a.enableCORS(a.rateLimit(a.authenticate(router))))
}