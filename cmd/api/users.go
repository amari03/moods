package main

import (
	"errors"
	"feel-flow-api/internal/data"
	"feel-flow-api/internal/validator"
	"net/http"
	"time"

	//"github.com/julienschmidt/httprouter"
	
)

func (a *applicationDependencies) registerUserHandler(w http.ResponseWriter, r *http.Request) {
	var input struct {
		Name     string `json:"name"`
		Email    string `json:"email"`
		Password string `json:"password"`
	}

	err := a.readJSON(w, r, &input)
	if err != nil {
		a.badRequestResponse(w, r, err)
		return
	}

	user := &data.User{
		Name:      input.Name,
		Email:     input.Email,
		Activated: false,
	}

	err = user.Password.Set(input.Password)
	if err != nil {
		a.serverErrorResponse(w, r, err)
		return
	}

	v := validator.New()
	if data.ValidateUser(v, user); !v.IsEmpty() {
		a.failedValidationResponse(w, r, v.Errors)
		return
	}

	err = a.models.Users.Insert(user)
	if err != nil {
		if errors.Is(err, data.ErrDuplicateEmail) {
			v.AddError("email", "a user with this email address already exists")
			a.failedValidationResponse(w, r, v.Errors)
		} else {
			a.serverErrorResponse(w, r, err)
		}
		return
	}

	// Generate an activation token.
	token, err := a.models.Tokens.New(user.ID, 3*24*time.Hour, data.ScopeActivation)
	if err != nil {
    	a.serverErrorResponse(w, r, err)
    	return
	}

	// Use the background helper to send the welcome email.
	a.background(func() {
    // Create a map to hold the data for the email template.
    emailData := map[string]interface{}{
        "activationToken": token.Plaintext,
        "userID":          user.ID,
        "userName":        user.Name,
    }
    err = a.mailer.Send(user.Email, "user_welcome.tmpl", emailData)
    	if err != nil {
        	a.logger.Error(err.Error())
    	}
	})

	err = a.writeJSON(w, http.StatusCreated, envelope{"user": user}, nil)
	if err != nil {
		a.serverErrorResponse(w, r, err)
	}
}

func (a *applicationDependencies) activateUserHandler(w http.ResponseWriter, r *http.Request) {
	var input struct {
		TokenPlaintext string `json:"token"`
	}
	err := a.readJSON(w, r, &input)
	if err != nil {
		a.badRequestResponse(w, r, err)
		return
	}

	v := validator.New()
	if data.ValidateTokenPlaintext(v, input.TokenPlaintext); !v.IsEmpty() {
		a.failedValidationResponse(w, r, v.Errors)
		return
	}

	user, err := a.models.Users.GetForToken(data.ScopeActivation, input.TokenPlaintext)
	if err != nil {
		switch {
		case errors.Is(err, data.ErrRecordNotFound):
			v.AddError("token", "invalid or expired activation token")
			a.failedValidationResponse(w, r, v.Errors)
		default:
			a.serverErrorResponse(w, r, err)
		}
		return
	}

	user.Activated = true

	err = a.models.Users.Update(user)
	if err != nil {
		switch {
		case errors.Is(err, data.ErrEditConflict):
			a.editConflictResponse(w, r)
		default:
			a.serverErrorResponse(w, r, err)
		}
		return
	}

	err = a.models.Tokens.DeleteAllForUser(data.ScopeActivation, user.ID)
	if err != nil {
		a.serverErrorResponse(w, r, err)
		return
	}

	err = a.writeJSON(w, http.StatusOK, envelope{"user": user}, nil)
	if err != nil {
		a.serverErrorResponse(w, r, err)
	}
}