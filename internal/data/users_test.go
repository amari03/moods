package data

import (
	"context"
	"database/sql"
	"flag"
	"os"
	"testing"
	"time"

	//"feel-flow-api/internal/mailer" // We might need this later if we test things that send emails

	_ "github.com/lib/pq"
	"github.com/stretchr/testify/assert"
)

// Declare a global variable to hold the test DB connection pool.
var testDB *sql.DB

// TestMain is the entry point for all tests in this package.
func TestMain(m *testing.M) {
	// Define a new command-line flag for the test database DSN.
	// We'll default it to our test database.
	dsn := flag.String("db-test-dsn", "postgres://moods:fishsticks@localhost/feel_flow_test?sslmode=disable", "PostgreSQL test DSN")
	flag.Parse()

	var err error
	testDB, err = sql.Open("postgres", *dsn)
	if err != nil {
		panic("failed to connect to test database")
	}

	// Ping the database to check that a connection was established.
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	err = testDB.PingContext(ctx)
	if err != nil {
		panic("failed to ping test database")
	}

	// Run all the tests for this package.
	// The return code from m.Run() will be used as the exit code for the whole test suite.
	code := m.Run()

	// Close the database connection.
	testDB.Close()

	// Exit with the status code from the test run.
	os.Exit(code)
}

// newTestDB is a helper function that returns a clean database and a teardown function.
func newTestDB(t *testing.T) (*sql.DB, func()) {
	// Truncate all relevant tables to ensure a clean state.
	// RESTART IDENTITY resets auto-incrementing counters.
	// CASCADE will also truncate any tables that have foreign keys to these tables.
	_, err := testDB.Exec(`TRUNCATE TABLE moods, users, tokens RESTART IDENTITY CASCADE`)
	if err != nil {
		t.Fatalf("failed to truncate tables: %s", err)
	}

	// The teardown function to be called after the test finishes.
	teardown := func() {
		_, err := testDB.Exec(`TRUNCATE TABLE moods, users, tokens RESTART IDENTITY CASCADE`)
		if err != nil {
			t.Fatalf("failed to truncate tables during teardown: %s", err)
		}
	}

	return testDB, teardown
}

func TestUserModel_Integration(t *testing.T) {
	// Skip the test if the `-short` flag is provided.
	if testing.Short() {
		t.Skip("skipping integration test")
	}
	
	t.Run("Insert and GetByEmail", func(t *testing.T) {
		// Get a clean database and a teardown function.
		db, teardown := newTestDB(t)
		defer teardown() // Ensure the DB is cleaned up after the test.

		// Create an instance of our UserModel using the test DB.
		userModel := UserModel{DB: db}

		// Define the user we want to insert.
		user := &User{
			Name:      "Alice Jones",
			Email:     "alice@example.com",
			Activated: true,
		}
		err := user.Password.Set("pa55word")
		assert.NoError(t, err)

		// Insert the user into the real test database.
		err = userModel.Insert(user)
		assert.NoError(t, err)

		// Retrieve the user from the database.
		retrievedUser, err := userModel.GetByEmail("alice@example.com")
		assert.NoError(t, err)

		// Assert that the retrieved user matches what we inserted.
		assert.NotNil(t, retrievedUser)
		assert.Equal(t, user.Name, retrievedUser.Name)
		assert.Equal(t, user.Email, retrievedUser.Email)
		assert.True(t, retrievedUser.Activated)

		// Check that the password matches.
		match, err := retrievedUser.Password.Matches("pa55word")
		assert.NoError(t, err)
		assert.True(t, match)
	})
}