package data

import (
	"context"
	"database/sql"
	"time"
	"fmt"
	"errors"

	"feel-flow-api/internal/validator"
)

// Note the json:"..." struct tags. These control how the struct fields are
// encoded to JSON. "-" means the field is ignored.
type Mood struct {
	ID        int64     `json:"id"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
	Title     string    `json:"title"`
	Content   string    `json:"content"`
	Emotion   string    `json:"emotion"`
	Emoji     string    `json:"emoji"`
	Color     string    `json:"color"`
	UserID    int64     `json:"-"` // Hide this for now
}

// MoodModel wraps the database connection pool.
type MoodModel struct {
	DB *sql.DB
}

func ValidateMood(v *validator.Validator, mood *Mood){
	v.Check(mood.Title != "", "title", "must be provided")
	v.Check(len(mood.Title) <= 100, "title", "must not be more than 100 bytes long")

	v.Check(mood.Content != "", "content", "must be provided")

	v.Check(mood.Emotion != "", "emotion", "must be provided")

	v.Check(mood.Emoji != "", "emoji", "must be provided")
	v.Check(len(mood.Emoji) <= 10, "emoji", "must not be more than 10 bytes long")

	v.Check(mood.Color != "", "color", "must be provided")
	v.Check(len(mood.Color) <= 20, "color", "must not be more than 20 bytes long")
}

// --- CRUD Methods will go here ---
func (m MoodModel) Insert(mood *Mood) error {
	query := `
		INSERT INTO moods (title, content, emotion, emoji, color, user_id)
		VALUES ($1, $2, $3, $4, $5, $6)
		RETURNING id, created_at, updated_at`

	args := []interface{}{mood.Title, mood.Content, mood.Emotion, mood.Emoji, mood.Color, mood.UserID}

	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()

	// The Scan() method copies the values from the returned row into the provided pointers.
	return m.DB.QueryRowContext(ctx, query, args...).Scan(&mood.ID, &mood.CreatedAt, &mood.UpdatedAt)
}

// Get retrieves a specific mood by its ID.
func (m *MoodModel) Get(id int64) (*Mood, error) {
	if id < 1 {
		return nil, ErrRecordNotFound
	}
	query := `
		SELECT id, created_at, updated_at, title, content, emotion, emoji, color
		FROM moods
		WHERE id = $1`
	var mood Mood
	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()
	err := m.DB.QueryRowContext(ctx, query, id).Scan(
		&mood.ID,
		&mood.CreatedAt,
		&mood.UpdatedAt,
		&mood.Title,
		&mood.Content,
		&mood.Emotion,
		&mood.Emoji,
		&mood.Color,
	)
	if err != nil {
		switch {
		case errors.Is(err, sql.ErrNoRows):
			return nil, ErrRecordNotFound
		default:
			return nil, err
		}
	}
	return &mood, nil
}

// GetAll returns a paginated slice of moods.
func (m MoodModel) GetAll(title string, emotion string, filters Filters) ([]*Mood, Metadata, error) {
    // Use a window function to get the total number of records.
    query := fmt.Sprintf(`
        SELECT COUNT(*) OVER(), id, created_at, updated_at, title, content, emotion, emoji, color
        FROM moods
        WHERE (to_tsvector('simple', title) @@ plainto_tsquery('simple', $1) OR $1 = '')
        AND (to_tsvector('simple', emotion) @@ plainto_tsquery('simple', $2) OR $2 = '')
        ORDER BY %s %s, id ASC
        LIMIT $3 OFFSET $4`, filters.sortColumn(), filters.sortDirection())

    ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
    defer cancel()

    args := []interface{}{title, emotion, filters.limit(), filters.offset()}

    rows, err := m.DB.QueryContext(ctx, query, args...)
    if err != nil {
        return nil, Metadata{}, err
    }
    defer rows.Close()

    totalRecords := int64(0)
    moods := []*Mood{}

    for rows.Next() {
        var mood Mood
        err := rows.Scan(
            &totalRecords, // Scan the total count
            &mood.ID,
            &mood.CreatedAt,
            &mood.UpdatedAt,
            &mood.Title,
            &mood.Content,
            &mood.Emotion,
            &mood.Emoji,
            &mood.Color,
        )
        if err != nil {
            return nil, Metadata{}, err
        }
        moods = append(moods, &mood)
    }

    if err = rows.Err(); err != nil {
        return nil, Metadata{}, err
    }

    metadata := calculateMetadata(totalRecords, filters.Page, filters.PageSize)

    return moods, metadata, nil
}

func (m MoodModel) Update(mood *Mood) error {
	query := `
		UPDATE moods
		SET title = $1, content = $2, emotion = $3, emoji = $4, color = $5, updated_at = NOW()
		WHERE id = $6
		RETURNING updated_at`

	args := []interface{}{
		mood.Title,
		mood.Content,
		mood.Emotion,
		mood.Emoji,
		mood.Color,
		mood.ID,
	}

	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()

	return m.DB.QueryRowContext(ctx, query, args...).Scan(&mood.UpdatedAt)
}

func (m MoodModel) Delete(id int64) error {
	if id < 1 {
		return ErrRecordNotFound
	}

	query := `DELETE FROM moods WHERE id = $1`

	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()

	result, err := m.DB.ExecContext(ctx, query, id)
	if err != nil {
		return err
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return err
	}

	if rowsAffected == 0 {
		return ErrRecordNotFound
	}

	return nil
}