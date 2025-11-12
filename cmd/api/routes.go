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
	router.HandlerFunc(http.MethodGet, "/v1/moods", a.listMoodsHandler)
	router.HandlerFunc(http.MethodPatch, "/v1/moods/:id", a.updateMoodHandler)
	router.HandlerFunc(http.MethodDelete, "/v1/moods/:id", a.deleteMoodHandler)

	// User routes
	router.HandlerFunc(http.MethodPost, "/v1/users", a.registerUserHandler)
	router.HandlerFunc(http.MethodPut, "/v1/users/activated", a.activateUserHandler)
	// Add Update and Delete routes, wrapped in middleware
	router.HandlerFunc(http.MethodPatch, "/v1/users/:id", a.requireActivatedUser(a.updateUserHandler))
	router.HandlerFunc(http.MethodDelete, "/v1/users/:id", a.requireActivatedUser(a.deleteUserHandler))

	return a.recoverPanic(a.rateLimit(a.authenticate(router)))
}