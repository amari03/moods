package data

import (
	"context"
	"database/sql"
	"time"
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

func (m MoodModel) Get(id int64) (*Mood, error) {
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
		case err == sql.ErrNoRows:
			return nil, ErrRecordNotFound
		default:
			return nil, err
		}
	}

	return &mood, nil
}