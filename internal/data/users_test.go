package data

import (
	"database/sql"
	"regexp"
	"testing"
	"time"
	"errors"

	"github.com/DATA-DOG/go-sqlmock"
	"github.com/stretchr/testify/assert"
)

/*It's a mock database driver. It lets us "pretend" to be a real PostgreSQL 
database. We can tell it exactly what SQL query to expect and exactly what rows 
(or errors) to return. */

// Helper function to create a new mock DB and UserModel
func NewMockUserModel() (*sql.DB, sqlmock.Sqlmock, UserModel) {
	db, mock, err := sqlmock.New()
	if err != nil {
		panic("An error occurred while creating a mock database connection")
	}
	return db, mock, UserModel{DB: db}
}

func TestUserModel_GetByEmail(t *testing.T) {
	t.Run("Success - User Found", func(t *testing.T) {
		// 1. Setup
		db, mock, userModel := NewMockUserModel()
		defer db.Close()

		// Test user data
		testUser := &User{
			ID:        1,
			CreatedAt: time.Now(),
			Name:      "Jane Doe",
			Email:     "jane@example.com",
			Activated: true,
			Version:   1,
		}
		testUser.Password.hash = []byte("hashedpassword")

		// 2. Define the expected SQL query and the rows it should return.
		// Use regexp.QuoteMeta to treat the SQL string literally.
		query := regexp.QuoteMeta(`
			SELECT id, created_at, name, email, password_hash, activated, version
			FROM users
			WHERE email = $1`)

		// Create the expected rows that the DB will return.
		rows := sqlmock.NewRows([]string{"id", "created_at", "name", "email", "password_hash", "activated", "version"}).
			AddRow(testUser.ID, testUser.CreatedAt, testUser.Name, testUser.Email, testUser.Password.hash, testUser.Activated, testUser.Version)

		// Tell the mock to expect this specific query, with these arguments, and return these rows.
		mock.ExpectQuery(query).WithArgs(testUser.Email).WillReturnRows(rows)

		// 3. Execute the method we are testing.
		user, err := userModel.GetByEmail(testUser.Email)

		// 4. Assert the results.
		assert.NoError(t, err) // We expect no error.
		assert.NotNil(t, user) // We expect a user to be returned.
		assert.Equal(t, testUser.ID, user.ID)
		assert.Equal(t, testUser.Email, user.Email)
		assert.NoError(t, mock.ExpectationsWereMet()) // Ensure all expected queries were executed.
	})

	t.Run("Fail - User Not Found", func(t *testing.T) {
		// 1. Setup
		db, mock, userModel := NewMockUserModel()
		defer db.Close()

		emailToTest := "notfound@example.com"

		// 2. Define the expected SQL query and the error it should return.
		query := regexp.QuoteMeta(`
			SELECT id, created_at, name, email, password_hash, activated, version
			FROM users
			WHERE email = $1`)

		// Tell the mock to expect the query but return sql.ErrNoRows.
		mock.ExpectQuery(query).WithArgs(emailToTest).WillReturnError(sql.ErrNoRows)

		// 3. Execute
		user, err := userModel.GetByEmail(emailToTest)

		// 4. Assert
		assert.Error(t, err)                             // We expect an error.
		assert.Nil(t, user)                              // We expect a nil user.
		assert.Equal(t, ErrRecordNotFound, err)          // The error should be our specific ErrRecordNotFound.
		assert.NoError(t, mock.ExpectationsWereMet())
	})
}

func TestUserModel_Insert(t *testing.T) {
db, mock, userModel := NewMockUserModel()
defer db.Close()
    
// The user we are trying to insert
testUser := &User{
	Name:      "John Smith",
	Email:     "john@example.com",
	Activated: false,
}
// We need to set a password hash, as the Insert method requires it.
testUser.Password.hash = []byte("hashedpassword")

t.Run("Success - User Inserted", func(t *testing.T) {
	query := regexp.QuoteMeta(`
		INSERT INTO users (name, email, password_hash, activated)
		VALUES ($1, $2, $3, $4)
		RETURNING id, created_at, version`)

	// The insert will return a new ID, CreatedAt, and Version
	rows := sqlmock.NewRows([]string{"id", "created_at", "version"}).
		AddRow(1, time.Now(), 1)

	mock.ExpectQuery(query).
		WithArgs(testUser.Name, testUser.Email, testUser.Password.hash, testUser.Activated).
		WillReturnRows(rows)

	err := userModel.Insert(testUser)

	assert.NoError(t, err)
	assert.NoError(t, mock.ExpectationsWereMet())
})

t.Run("Fail - Duplicate Email", func(t *testing.T) {
	query := regexp.QuoteMeta(`
		INSERT INTO users (name, email, password_hash, activated)
		VALUES ($1, $2, $3, $4)
		RETURNING id, created_at, version`)

	// Simulate the unique constraint violation error from PostgreSQL.
	mock.ExpectQuery(query).
		WithArgs(testUser.Name, testUser.Email, testUser.Password.hash, testUser.Activated).
		WillReturnError(errors.New(`pq: duplicate key value violates unique constraint "users_email_key"`))

	err := userModel.Insert(testUser)

	assert.Error(t, err)
	assert.Equal(t, ErrDuplicateEmail, err)
	assert.NoError(t, mock.ExpectationsWereMet())
})

}

func TestUserModel_Update(t *testing.T) {
db, mock, userModel := NewMockUserModel()
defer db.Close()
    
// A pre-existing user that we will update.
testUser := &User{
	ID:        1,
	Name:      "John Smith Updated",
	Email:     "john.smith@example.com",
	Activated: true,
	Version:   1, // Crucial for optimistic locking
}
testUser.Password.hash = []byte("newhashedpassword")

t.Run("Success - User Updated", func(t *testing.T) {
	query := regexp.QuoteMeta(`
		UPDATE users
		SET name = $1, email = $2, password_hash = $3, activated = $4, version = version + 1
		WHERE id = $5 AND version = $6
		RETURNING version`)

	// The update will return the new version number.
	rows := sqlmock.NewRows([]string{"version"}).AddRow(2)

	mock.ExpectQuery(query).
		WithArgs(testUser.Name, testUser.Email, testUser.Password.hash, testUser.Activated, testUser.ID, testUser.Version).
		WillReturnRows(rows)

	err := userModel.Update(testUser)

	assert.NoError(t, err)
	assert.NoError(t, mock.ExpectationsWereMet())
})

t.Run("Fail - Edit Conflict", func(t *testing.T) {
	query := regexp.QuoteMeta(`
		UPDATE users
		SET name = $1, email = $2, password_hash = $3, activated = $4, version = version + 1
		WHERE id = $5 AND version = $6
		RETURNING version`)

	// Simulate an edit conflict by having the DB return no rows.
	mock.ExpectQuery(query).
		WithArgs(testUser.Name, testUser.Email, testUser.Password.hash, testUser.Activated, testUser.ID, testUser.Version).
		WillReturnError(sql.ErrNoRows)

	err := userModel.Update(testUser)

	assert.Error(t, err)
	assert.Equal(t, ErrEditConflict, err)
	assert.NoError(t, mock.ExpectationsWereMet())
})

}