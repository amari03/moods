package main

import (
	"errors"
	"feel-flow-api/internal/data"
	"feel-flow-api/internal/validator"
	"fmt"
	"net/http"
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

	mood := &data.Mood{
		Title:   input.Title,
		Content: input.Content,
		Emotion: input.Emotion,
		Emoji:   input.Emoji,
		Color:   input.Color,
		UserID:  1, // Hardcode user ID for now
	}

	v := validator.New()

	if data.ValidateMood(v, mood); !v.IsEmpty() {
        a.failedValidationResponse(w, r, v.Errors)
        return
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

func (a *applicationDependencies) updateMoodHandler(w http.ResponseWriter, r *http.Request) {
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

	// Use pointers to handle partial updates.
	var input struct {
		Title   *string `json:"title"`
		Content *string `json:"content"`
		Emotion *string `json:"emotion"`
		Emoji   *string `json:"emoji"`
		Color   *string `json:"color"`
	}

	err = a.readJSON(w, r, &input)
	if err != nil {
		a.badRequestResponse(w, r, err)
		return
	}

	// If the input field is not nil, update the mood record.
	if input.Title != nil {
		mood.Title = *input.Title
	}
	if input.Content != nil {
		mood.Content = *input.Content
	}
	if input.Emotion != nil {
		mood.Emotion = *input.Emotion
	}
	if input.Emoji != nil {
		mood.Emoji = *input.Emoji
	}
	if input.Color != nil {
		mood.Color = *input.Color
	}

	v := validator.New()
	if data.ValidateMood(v, mood); !v.IsEmpty() {
		a.failedValidationResponse(w, r, v.Errors)
		return
	}

	err = a.models.Moods.Update(mood)
	if err != nil {
		a.serverErrorResponse(w, r, err)
		return
	}

	err = a.writeJSON(w, http.StatusOK, envelope{"mood": mood}, nil)
	if err != nil {
		a.serverErrorResponse(w, r, err)
	}
}

func (a *applicationDependencies) deleteMoodHandler(w http.ResponseWriter, r *http.Request) {
	id, err := a.readIDParam(r)
	if err != nil {
		a.notFoundResponse(w, r)
		return
	}

	err = a.models.Moods.Delete(id)
	if err != nil {
		switch {
		case errors.Is(err, data.ErrRecordNotFound):
			a.notFoundResponse(w, r)
		default:
			a.serverErrorResponse(w, r, err)
		}
		return
	}

	err = a.writeJSON(w, http.StatusOK, envelope{"message": "mood successfully deleted"}, nil)
	if err != nil {
		a.serverErrorResponse(w, r, err)
	}
}

func (a *applicationDependencies) listMoodsHandler(w http.ResponseWriter, r *http.Request) {
	var input struct {
		Title   string
		Emotion string
		data.Filters
	}

	v := validator.New()
	qs := r.URL.Query()

	input.Title = a.getSingleQueryParameter(qs, "title", "")
	input.Emotion = a.getSingleQueryParameter(qs, "emotion", "")

	input.Filters.Page = a.getSingleIntegerParameter(qs, "page", 1, v)
	input.Filters.PageSize = a.getSingleIntegerParameter(qs, "page_size", 20, v)
	input.Filters.Sort = a.getSingleQueryParameter(qs, "sort", "id")

	// Add the allowed sort values.
	input.Filters.SortSafeList = []string{"id", "title", "updated_at", "-id", "-title", "-updated_at"}

	if data.ValidateFilters(v, input.Filters); !v.IsEmpty() {
		a.failedValidationResponse(w, r, v.Errors)
		return
	}

	moods, metadata, err := a.models.Moods.GetAll(input.Title, input.Emotion, input.Filters)
	if err != nil {
		a.serverErrorResponse(w, r, err)
		return
	}

	err = a.writeJSON(w, http.StatusOK, envelope{"moods": moods, "metadata": metadata}, nil)
	if err != nil {
		a.serverErrorResponse(w, r, err)
	}
}