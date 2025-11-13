package main

import (
	"errors"
	"feel-flow-api/internal/data"
	"feel-flow-api/internal/validator"
	"golang.org/x/time/rate"
	"net"
	"net/http"
	"strings"
	"sync"
	"time"
)

// recoverPanic recovers from any panics and responds with a 500 Internal Server Error.
func (a *applicationDependencies) recoverPanic(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		defer func() {
			if err := recover(); err != nil {
				w.Header().Set("Connection", "close")
				a.serverErrorResponse(w, r, errors.New(err.(string)))
			}
		}()
		next.ServeHTTP(w, r)
	})
}

// rateLimit is middleware for IP-based rate limiting.
func (app *applicationDependencies) rateLimit(next http.Handler) http.Handler {
	type client struct {
		limiter  *rate.Limiter
		lastSeen time.Time
	}
	var (
		mu      sync.Mutex
		clients = make(map[string]*client)
	)

	go func() {
		for {
			time.Sleep(time.Minute)
			mu.Lock()
			for ip, client := range clients {
				if time.Since(client.lastSeen) > 3*time.Minute {
					delete(clients, ip)
				}
			}
			mu.Unlock()
		}
	}()

	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		ip, _, err := net.SplitHostPort(r.RemoteAddr)
		if err != nil {
			app.serverErrorResponse(w, r, err)
			return
		}

		mu.Lock()
		if _, found := clients[ip]; !found {
			clients[ip] = &client{limiter: rate.NewLimiter(2, 4)} // 2 requests/sec, burst of 4
		}
		clients[ip].lastSeen = time.Now()

		if !clients[ip].limiter.Allow() {
			mu.Unlock()
			app.rateLimitExceededResponse(w, r)
			return
		}
		mu.Unlock()

		next.ServeHTTP(w, r)
	})
}
/*
func (app *applicationDependencies) rateLimitExceededResponse(w http.ResponseWriter, r *http.Request) {
	message := "rate limit exceeded"
	app.errorResponse(w, r, http.StatusTooManyRequests, message)
}*/

// authenticate checks for a bearer token and adds the user to the request context.
func (a *applicationDependencies) authenticate(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Add("Vary", "Authorization")
		authorizationHeader := r.Header.Get("Authorization")
		if authorizationHeader == "" {
			r = a.contextSetUser(r, data.AnonymousUser)
			next.ServeHTTP(w, r)
			return
		}
		headerParts := strings.Split(authorizationHeader, " ")
		if len(headerParts) != 2 || headerParts[0] != "Bearer" {
			a.invalidAuthenticationTokenResponse(w, r)
			return
		}
		token := headerParts[1]
		v := validator.New()
		if data.ValidateTokenPlaintext(v, token); !v.IsEmpty() {
			a.invalidAuthenticationTokenResponse(w, r)
			return
		}
		user, err := a.models.Users.GetForToken(data.ScopeAuthentication, token)
		if err != nil {
			switch {
			case errors.Is(err, data.ErrRecordNotFound):
				a.invalidAuthenticationTokenResponse(w, r)
			default:
				a.serverErrorResponse(w, r, err)
			}
			return
		}
		r = a.contextSetUser(r, user)
		next.ServeHTTP(w, r)
	})
}

// --- NEW AUTHORIZATION MIDDLEWARE ---

// requireAuthenticatedUser checks if a user is authenticated (not anonymous).
func (a *applicationDependencies) requireAuthenticatedUser(next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		user := a.contextGetUser(r)
		if user.IsAnonymous() {
			a.authenticationRequiredResponse(w, r)
			return
		}
		next.ServeHTTP(w, r)
	}
}

// requireActivatedUser checks if a user is both authenticated and activated.
func (a *applicationDependencies) requireActivatedUser(next http.HandlerFunc) http.HandlerFunc {
	fn := func(w http.ResponseWriter, r *http.Request) {
		user := a.contextGetUser(r)
		if !user.Activated {
			a.inactiveAccountResponse(w, r)
			return
		}
		next.ServeHTTP(w, r)
	}
	// Wrap fn with the requireAuthenticatedUser middleware to ensure the user is not anonymous.
	return a.requireAuthenticatedUser(fn)
}

func (a *applicationDependencies) enableCORS(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// Add the "Vary: Origin" header.
		w.Header().Add("Vary", "Origin")

		// Add a Vary header for the request method for preflight requests.
		w.Header().Add("Vary", "Access-Control-Request-Method")

		origin := r.Header.Get("Origin")

		if origin != "" && len(a.config.cors.trustedOrigins) > 0 {
			for i := range a.config.cors.trustedOrigins {
				if origin == a.config.cors.trustedOrigins[i] {
					w.Header().Set("Access-Control-Allow-Origin", origin)

					// Check if the request is a preflight request.
					if r.Method == http.MethodOptions && r.Header.Get("Access-Control-Request-Method") != "" {
						// Set the necessary preflight response headers.
						w.Header().Set("Access-Control-Allow-Methods", "OPTIONS, PUT, PATCH, DELETE")
						w.Header().Set("Access-Control-Allow-Headers", "Authorization, Content-Type")

						// Write the headers along with a 200 OK status and return.
						w.WriteHeader(http.StatusOK)
						return
					}
					break
				}
			}
		}

		// Call the next handler in the chain.
		next.ServeHTTP(w, r)
	})
}