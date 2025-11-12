package data

import (
	"feel-flow-api/internal/validator"
	"math"
	"strings"
)

// Filters holds the pagination and sorting parameters.
type Filters struct {
	Page         int
	PageSize     int
	Sort         string
	SortSafeList []string // A list of allowed sort fields.
}

// Metadata holds the pagination metadata.
type Metadata struct {
	CurrentPage  int   `json:"current_page,omitempty"`
	PageSize     int   `json:"page_size,omitempty"`
	FirstPage    int   `json:"first_page,omitempty"`
	LastPage     int   `json:"last_page,omitempty"`
	TotalRecords int64 `json:"total_records,omitempty"`
}

// ValidateFilters checks that the pagination and sort parameters are valid.
func ValidateFilters(v *validator.Validator, f Filters) {
	v.Check(f.Page > 0, "page", "must be greater than zero")
	v.Check(f.Page <= 10_000, "page", "must be a maximum of 10,000")
	v.Check(f.PageSize > 0, "page_size", "must be greater than zero")
	v.Check(f.PageSize <= 100, "page_size", "must be a maximum of 100")
	v.Check(validator.PermittedValue(f.Sort, f.SortSafeList...), "sort", "invalid sort value")
}

// sortColumn checks if the client-provided sort field is in our safelist.
func (f Filters) sortColumn() string {
	for _, safeValue := range f.SortSafeList {
		if f.Sort == safeValue {
			return strings.TrimPrefix(f.Sort, "-")
		}
	}
	panic("unsafe sort parameter: " + f.Sort)
}

// sortDirection returns the sort direction ("ASC" or "DESC").
func (f Filters) sortDirection() string {
	if strings.HasPrefix(f.Sort, "-") {
		return "DESC"
	}
	return "ASC"
}

func (f Filters) limit() int {
	return f.PageSize
}

func (f Filters) offset() int {
	return (f.Page - 1) * f.PageSize
}

// calculateMetadata calculates the pagination metadata.
func calculateMetadata(totalRecords int64, page, pageSize int) Metadata {
	if totalRecords == 0 {
		return Metadata{}
	}
	return Metadata{
		CurrentPage:  page,
		PageSize:     pageSize,
		FirstPage:    1,
		LastPage:     int(math.Ceil(float64(totalRecords) / float64(pageSize))),
		TotalRecords: totalRecords,
	}
}