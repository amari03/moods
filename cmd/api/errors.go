package main

import (
	"fmt"
	"net/http"
)

// logError logs the error message.
func (a *applicationDependencies) logError(r *http.Request, err error) {
	a.logger.Error(err.Error(), "method", r.Method, "uri", r.URL.RequestURI())
}

// errorResponseJSON sends a JSON-formatted error message to the client.
func (a *applicationDependencies) errorResponseJSON(w http.ResponseWriter, r *http.Request, status int, message interface{}) {
	err := a.writeJSON(w, status, envelope{"error": message}, nil)
	if err != nil {
		a.logError(r, err)
		w.WriteHeader(500)
	}
}

// serverErrorResponse is used for unexpected server errors (500 Internal Server Error).
func (a *applicationDependencies) serverErrorResponse(w http.ResponseWriter, r *http.Request, err error) {
	a.logError(r, err)
	message := "the server encountered a problem and could not process your request"
	a.errorResponseJSON(w, r, http.StatusInternalServerError, message)
}

// notFoundResponse is for when a requested resource doesn't exist (404 Not Found).
func (a *applicationDependencies) notFoundResponse(w http.ResponseWriter, r *http.Request) {
	message := "the requested resource could not be found"
	a.errorResponseJSON(w, r, http.StatusNotFound, message)
}

// methodNotAllowedResponse is for when the client uses an unsupported HTTP method (405 Method Not Allowed).
func (a *applicationDependencies) methodNotAllowedResponse(w http.ResponseWriter, r *http.Request) {
	message := fmt.Sprintf("the %s method is not supported for this resource", r.Method)
	a.errorResponseJSON(w, r, http.StatusMethodNotAllowed, message)
}

// badRequestResponse is for when the client sends a malformed request (400 Bad Request).
func (a *applicationDependencies) badRequestResponse(w http.ResponseWriter, r *http.Request, err error) {
	a.errorResponseJSON(w, r, http.StatusBadRequest, err.Error())
}

func (a *applicationDependencies) failedValidationResponse(w http.ResponseWriter, r *http.Request, errors map[string]string) {
	a.errorResponseJSON(w, r, http.StatusUnprocessableEntity, errors)
}

func (a *applicationDependencies) rateLimitExceededResponse(w http.ResponseWriter, r *http.Request) {
	message := "rate limit exceeded"
	a.errorResponseJSON(w, r, http.StatusTooManyRequests, message)
}

func (a *applicationDependencies) editConflictResponse(w http.ResponseWriter, r *http.Request) {
	message := "unable to update the record due to an edit conflict, please try again"
	a.errorResponseJSON(w, r, http.StatusConflict, message)
}

func (a *applicationDependencies) notPermittedResponse(w http.ResponseWriter, r *http.Request) {
	message := "you are not permitted to perform this action"
	a.errorResponseJSON(w, r, http.StatusForbidden, message)
}

func (a *applicationDependencies) invalidCredentialsResponse(w http.ResponseWriter, r *http.Request) {
	message := "invalid authentication credentials"
	a.errorResponseJSON(w, r, http.StatusUnauthorized, message)
}

func (a *applicationDependencies) invalidAuthenticationTokenResponse(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("WWW-Authenticate", "Bearer")
	message := "invalid or missing authentication token"
	a.errorResponseJSON(w, r, http.StatusUnauthorized, message)
}

func (a *applicationDependencies) authenticationRequiredResponse(w http.ResponseWriter, r *http.Request) {
	message := "you must be authenticated to access this resource"
	a.errorResponseJSON(w, r, http.StatusUnauthorized, message)
}

func (a *applicationDependencies) inactiveAccountResponse(w http.ResponseWriter, r *http.Request) {
	message := "your user account must be activated to access this resource"
	a.errorResponseJSON(w, r, http.StatusForbidden, message)
}