package main

import (
	"encoding/json"
	"net/http"
    "net/url"
	"errors"
	"strconv"
	"io"
	"strings"
	"fmt"

	"github.com/julienschmidt/httprouter"
    "feel-flow-api/internal/validator"
)

type envelope map[string]interface{}

func (a *applicationDependencies) writeJSON(w http.ResponseWriter, status int, data envelope, headers http.Header) error {
	js, err := json.MarshalIndent(data, "", "\t")
	if err != nil {
		return err
	}

	js = append(js, '\n')

	for key, value := range headers {
		w.Header()[key] = value
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	w.Write(js)

	return nil
}

func (a *applicationDependencies) readJSON(w http.ResponseWriter, r *http.Request, dst interface{}) error {
    maxBytes := 1_048_576 // Set max size to 1MB
    r.Body = http.MaxBytesReader(w, r.Body, int64(maxBytes))

    dec := json.NewDecoder(r.Body)
    dec.DisallowUnknownFields()

    err := dec.Decode(dst)
    if err != nil {
        var syntaxError *json.SyntaxError
        var unmarshalTypeError *json.UnmarshalTypeError
        var invalidUnmarshalError *json.InvalidUnmarshalError

        switch {
        case errors.As(err, &syntaxError):
            return fmt.Errorf("body contains badly-formed JSON (at character %d)", syntaxError.Offset)
        
        case errors.Is(err, io.ErrUnexpectedEOF):
            return errors.New("body contains badly-formed JSON")

        case errors.As(err, &unmarshalTypeError):
            if unmarshalTypeError.Field != "" {
                return fmt.Errorf("body contains incorrect JSON type for field %q", unmarshalTypeError.Field)
            }
            return fmt.Errorf("body contains incorrect JSON type (at character %d)", unmarshalTypeError.Offset)

        case errors.Is(err, io.EOF):
            return errors.New("body must not be empty")

        case strings.HasPrefix(err.Error(), "json: unknown field "):
            fieldName := strings.TrimPrefix(err.Error(), "json: unknown field ")
            return fmt.Errorf("body contains unknown key %s", fieldName)

        case err.Error() == "http: request body too large":
            return fmt.Errorf("body must not be larger than %d bytes", maxBytes)

        case errors.As(err, &invalidUnmarshalError):
            panic(err)

        default:
            return err
        }
    }
    
    // Check for a second JSON value in the request body
    err = dec.Decode(&struct{}{})
    if err != io.EOF {
        return errors.New("body must only contain a single JSON value")
    }

    return nil
}

func (a *applicationDependencies) readIDParam(r *http.Request) (int64, error) {
	params := httprouter.ParamsFromContext(r.Context())

	id, err := strconv.ParseInt(params.ByName("id"), 10, 64)
	if err != nil || id < 1 {
		return 0, errors.New("invalid id parameter")
	}

	return id, nil
}

// getSingleQueryParameter reads a string value from the query string, with a default.
func (a *applicationDependencies) getSingleQueryParameter(qs url.Values, key, defaultValue string) string {
	s := qs.Get(key)
	if s == "" {
		return defaultValue
	}
	return s
}

// getSingleIntegerParameter reads an integer value from the query string, with a default.
func (a *applicationDependencies) getSingleIntegerParameter(qs url.Values, key string, defaultValue int, v *validator.Validator) int {
	s := qs.Get(key)
	if s == "" {
		return defaultValue
	}
	i, err := strconv.Atoi(s)
	if err != nil {
		v.AddError(key, "must be an integer value")
		return defaultValue
	}
	return i
}