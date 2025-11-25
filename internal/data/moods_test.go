package data

import (
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
)

func TestMoodModel_Integration(t *testing.T) {
	if testing.Short() {
		t.Skip("skipping integration test")
	}

	// === Test Insert() and Get() ===
	t.Run("Insert and Get", func(t *testing.T) {
		db, teardown := newTestDB(t)
		defer teardown()

		// Initialize our models with the test database.
		moodModel := MoodModel{DB: db}
		userModel := UserModel{DB: db} // We need this to create a user first.

		// 1. Create a dummy user to associate the mood with.
		user := &User{
			Name: "Test User",
			Email: "test@example.com",
			Activated: true,
		}
		err := user.Password.Set("password123")
		assert.NoError(t, err)
		err = userModel.Insert(user)
		assert.NoError(t, err)

		// 2. Define and insert a new mood.
		mood := &Mood{
			Title:   "Integration Test Mood",
			Content: "This is a test from a real database.",
			Emotion: "Focused",
			Emoji:   "🔬",
			Color:   "#CCCCCC",
			UserID:  user.ID, // Associate with the user we just created.
		}

		err = moodModel.Insert(mood)
		assert.NoError(t, err)
		assert.NotZero(t, mood.ID) // Check that the DB assigned an ID.

		// 3. Retrieve the mood we just inserted.
		retrievedMood, err := moodModel.Get(mood.ID)
		assert.NoError(t, err)
		assert.NotNil(t, retrievedMood)

		// 4. Assert that the retrieved data is correct.
		assert.Equal(t, mood.ID, retrievedMood.ID)
		assert.Equal(t, "Integration Test Mood", retrievedMood.Title)
		assert.Equal(t, "Focused", retrievedMood.Emotion)
		assert.WithinDuration(t, mood.CreatedAt, retrievedMood.CreatedAt, time.Second) // Check timestamps are close.
	})

	// === Test Update() ===
	t.Run("Update", func(t *testing.T) {
		db, teardown := newTestDB(t)
		defer teardown()

		moodModel := MoodModel{DB: db}
		userModel := UserModel{DB: db}
		
		// Setup: Insert a user and a mood to update.
		user := &User{ Name: "Test User", Email: "test@example.com", Activated: true }
		_ = user.Password.Set("password123")
		_ = userModel.Insert(user)
		mood := &Mood{ Title: "Original Title", Content: "Original Content", Emotion: "Neutral", Emoji: "😐", Color: "#AAAAAA", UserID: user.ID }
		_ = moodModel.Insert(mood)

		// Modify the mood data.
		mood.Title = "Updated Title"
		mood.Content = "This content has been updated."

		// Perform the update.
		err := moodModel.Update(mood)
		assert.NoError(t, err)

		// Retrieve the mood again to verify the changes.
		updatedMood, err := moodModel.Get(mood.ID)
		assert.NoError(t, err)
		assert.Equal(t, "Updated Title", updatedMood.Title)
		assert.Equal(t, "This content has been updated.", updatedMood.Content)
	})
	
	// === Test Delete() ===
	t.Run("Delete", func(t *testing.T) {
		db, teardown := newTestDB(t)
		defer teardown()

		moodModel := MoodModel{DB: db}
		userModel := UserModel{DB: db}
		
		// Setup: Insert a user and a mood to delete.
		user := &User{ Name: "Test User", Email: "test@example.com", Activated: true }
		_ = user.Password.Set("password123")
		_ = userModel.Insert(user)
		mood := &Mood{ Title: "To Be Deleted", Content: "...", Emotion: "Ephemeral", Emoji: "👻", Color: "#000000", UserID: user.ID }
		_ = moodModel.Insert(mood)
		
		// Delete the mood.
		err := moodModel.Delete(mood.ID)
		assert.NoError(t, err)
		
		// Try to retrieve the deleted mood.
		deletedMood, err := moodModel.Get(mood.ID)
		
		// Assert that we get a "record not found" error.
		assert.Error(t, err)
		assert.Equal(t, ErrRecordNotFound, err)
		assert.Nil(t, deletedMood)
	})
}