package data

import (
	"database/sql"
	"regexp"
	"testing"
	"time"

	"github.com/DATA-DOG/go-sqlmock"
	"github.com/stretchr/testify/assert"
)

// Helper function for MoodModel tests
func NewMockMoodModel() (*sql.DB, sqlmock.Sqlmock, MoodModel) {
	db, mock, err := sqlmock.New()
	if err != nil {
		panic("An error occurred while creating a mock database connection")
	}
	return db, mock, MoodModel{DB: db}
}

func TestMoodModel_Insert(t *testing.T) {
	db, mock, moodModel := NewMockMoodModel()
	defer db.Close()

	testMood := &Mood{
		Title:   "Feeling Great",
		Content: "The tests are working!",
		Emotion: "Happy",
		Emoji:   "😄",
		Color:   "#FFD700",
		UserID:  1,
	}

	query := regexp.QuoteMeta(`
		INSERT INTO moods (title, content, emotion, emoji, color, user_id)
		VALUES ($1, $2, $3, $4, $5, $6)
		RETURNING id, created_at, updated_at`)

	rows := sqlmock.NewRows([]string{"id", "created_at", "updated_at"}).
		AddRow(1, time.Now(), time.Now())

	mock.ExpectQuery(query).
		WithArgs(testMood.Title, testMood.Content, testMood.Emotion, testMood.Emoji, testMood.Color, testMood.UserID).
		WillReturnRows(rows)

	err := moodModel.Insert(testMood)

	assert.NoError(t, err)
	assert.NoError(t, mock.ExpectationsWereMet())
}

func TestMoodModel_Get(t *testing.T) {
	db, mock, moodModel := NewMockMoodModel()
	defer db.Close()

	query := regexp.QuoteMeta(`
		SELECT id, created_at, updated_at, title, content, emotion, emoji, color
		FROM moods
		WHERE id = $1`)

	rows := sqlmock.NewRows([]string{"id", "created_at", "updated_at", "title", "content", "emotion", "emoji", "color"}).
		AddRow(1, time.Now(), time.Now(), "Test Title", "Test Content", "Test Emotion", "😊", "#FFFFFF")

	mock.ExpectQuery(query).WithArgs(1).WillReturnRows(rows)

	mood, err := moodModel.Get(1)

	assert.NoError(t, err)
	assert.NotNil(t, mood)
	assert.Equal(t, int64(1), mood.ID)
	assert.NoError(t, mock.ExpectationsWereMet())
}

func TestMoodModel_Delete(t *testing.T) {
	db, mock, moodModel := NewMockMoodModel()
	defer db.Close()

	query := regexp.QuoteMeta(`DELETE FROM moods WHERE id = $1`)

	// sqlmock.NewResult(lastInsertId, rowsAffected)
	result := sqlmock.NewResult(0, 1)

	mock.ExpectExec(query).WithArgs(1).WillReturnResult(result)

	err := moodModel.Delete(1)

	assert.NoError(t, err)
	assert.NoError(t, mock.ExpectationsWereMet())
}