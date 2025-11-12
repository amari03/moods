package main

import (
	"feel-flow-api/internal/data"
	"fmt"
	"net/http"
	"errors"
)

func (a *applicationDependencies) createMoodHandler(w http.ResponseWriter, r *http.Request) {
	var input struct {
		Title   string `json:"title"`
		Content string `json:"content"`
		Emotion string `json:"emotion"`
		Emoji   string `json:"emoji"`
		Color   string `json:"color"`
	}

	err := a.readJSON(w, r, &input)
	if err != nil {
		a.badRequestResponse(w, r, err)
		return
	}

    // We will add validation next.

	mood := &data.Mood{
		Title:   input.Title,
		Content: input.Content,
		Emotion: input.Emotion,
		Emoji:   input.Emoji,
		Color:   input.Color,
		UserID:  1, // Hardcode user ID for now
	}

	err = a.models.Moods.Insert(mood)
	if err != nil {
		a.serverErrorResponse(w, r, err)
		return
	}

	headers := make(http.Header)
	headers.Set("Location", fmt.Sprintf("/v1/moods/%d", mood.ID))

	err = a.writeJSON(w, http.StatusCreated, envelope{"mood": mood}, headers)
	if err != nil {
		a.serverErrorResponse(w, r, err)
	}
}

func (a *applicationDependencies) showMoodHandler(w http.ResponseWriter, r *http.Request) {
	id, err := a.readIDParam(r)
	if err != nil {
		a.notFoundResponse(w, r)
		return
	}

	mood, err := a.models.Moods.Get(id)
	if err != nil {
		switch {
		case errors.Is(err, data.ErrRecordNotFound):
			a.notFoundResponse(w, r)
		default:
			a.serverErrorResponse(w, r, err)
		}
		return
	}

	err = a.writeJSON(w, http.StatusOK, envelope{"mood": mood}, nil)
	if err != nil {
		a.serverErrorResponse(w, r, err)
	}
}