package validator

import "slices"

// Validator holds a map of validation errors.
type Validator struct {
	Errors map[string]string
}

// New creates a new Validator instance.
func New() *Validator {
	return &Validator{Errors: make(map[string]string)}
}

// IsEmpty returns true if the Errors map is empty.
func (v *Validator) IsEmpty() bool {
	return len(v.Errors) == 0
}

// AddError adds an error message to the map if the key doesn't already exist.
func (v *Validator) AddError(key, message string) {
	if _, exists := v.Errors[key]; !exists {
		v.Errors[key] = message
	}
}

// Check adds an error message to the map only if a validation check is not 'ok'.
func (v *Validator) Check(ok bool, key, message string) {
	if !ok {
		v.AddError(key, message)
	}
}

// PermittedValue returns true if a value is in a list of permitted strings.
func PermittedValue(value string, permittedValues ...string) bool {
	return slices.Contains(permittedValues, value)
}