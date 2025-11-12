package data

import (
	"context"
	"crypto/sha256"
	"database/sql"
	"errors"
	"feel-flow-api/internal/validator"
	"time"

	"golang.org/x/crypto/bcrypt"
)

// AnonymousUser represents a user that is not logged in.
var AnonymousUser = &User{}

// User defines the data structure for a user.
type User struct {
	ID          int64     `json:"id"`
	CreatedAt   time.Time `json:"created_at"`
	Name        string    `json:"name"`
	Email       string    `json:"email"`
	Password    password  `json:"-"` // This will not be exposed in JSON responses.
	Activated   bool      `json:"activated"`
	Version     int       `json:"-"`
}

// IsAnonymous checks if a User instance is the anonymous user.
func (u *User) IsAnonymous() bool {
	return u == AnonymousUser
}

// password is a custom type to handle plaintext and hashed passwords.
type password struct {
	plaintext *string
	hash      []byte
}

// Set generates a bcrypt hash of a plaintext password.
func (p *password) Set(plaintextPassword string) error {
	hash, err := bcrypt.GenerateFromPassword([]byte(plaintextPassword), 12)
	if err != nil {
		return err
	}
	p.plaintext = &plaintextPassword
	p.hash = hash
	return nil
}

// Matches compares a plaintext password with the stored hash.
func (p *password) Matches(plaintextPassword string) (bool, error) {
	err := bcrypt.CompareHashAndPassword(p.hash, []byte(plaintextPassword))
	if err != nil {
		if errors.Is(err, bcrypt.ErrMismatchedHashAndPassword) {
			return false, nil
		}
		return false, err
	}
	return true, nil
}

// --- Validation Functions ---

func ValidateEmail(v *validator.Validator, email string) {
	v.Check(email != "", "email", "must be provided")
	v.Check(validator.Matches(email, validator.EmailRX), "email", "must be a valid email address")
}

func ValidatePasswordPlaintext(v *validator.Validator, password string) {
	v.Check(password != "", "password", "must be provided")
	v.Check(len(password) >= 8, "password", "must be at least 8 bytes long")
	v.Check(len(password) <= 72, "password", "must not be more than 72 bytes long")
}

func ValidateUser(v *validator.Validator, user *User) {
	v.Check(user.Name != "", "name", "must be provided")
	v.Check(len(user.Name) <= 100, "name", "must not be more than 100 bytes long")

	ValidateEmail(v, user.Email)

	if user.Password.plaintext != nil {
		ValidatePasswordPlaintext(v, *user.Password.plaintext)
	}
	
	if user.Password.hash == nil {
		panic("missing password hash for user")
	}
}

// --- UserModel for database operations ---

type UserModel struct {
	DB *sql.DB
}

func (m *UserModel) Insert(user *User) error {
	query := `
		INSERT INTO users (name, email, password_hash, activated)
		VALUES ($1, $2, $3, $4)
		RETURNING id, created_at, version`

	args := []interface{}{user.Name, user.Email, user.Password.hash, user.Activated}
	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()

	err := m.DB.QueryRowContext(ctx, query, args...).Scan(&user.ID, &user.CreatedAt, &user.Version)
	if err != nil {
		if err.Error() == `pq: duplicate key value violates unique constraint "users_email_key"` {
			return ErrDuplicateEmail
		}
		return err
	}
	return nil
}

func (m *UserModel) GetByEmail(email string) (*User, error) {
    query := `
        SELECT id, created_at, name, email, password_hash, activated, version
        FROM users
        WHERE email = $1`

    var user User
    ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
    defer cancel()

    err := m.DB.QueryRowContext(ctx, query, email).Scan(
        &user.ID,
        &user.CreatedAt,
        &user.Name,
        &user.Email,
        &user.Password.hash,
        &user.Activated,
        &user.Version,
    )

    if err != nil {
        if errors.Is(err, sql.ErrNoRows) {
            return nil, ErrRecordNotFound
        }
        return nil, err
    }
    return &user, nil
}

func (m *UserModel) Update(user *User) error {
    query := `
        UPDATE users
        SET name = $1, email = $2, password_hash = $3, activated = $4, version = version + 1
        WHERE id = $5 AND version = $6
        RETURNING version`

    args := []interface{}{
        user.Name,
        user.Email,
        user.Password.hash,
        user.Activated,
        user.ID,
        user.Version,
    }

    ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
    defer cancel()

    err := m.DB.QueryRowContext(ctx, query, args...).Scan(&user.Version)
    if err != nil {
        if err.Error() == `pq: duplicate key value violates unique constraint "users_email_key"` {
            return ErrDuplicateEmail
        }
        if errors.Is(err, sql.ErrNoRows) {
            return ErrEditConflict
        }
        return err
    }
    return nil
}

func (m *UserModel) GetForToken(tokenScope, tokenPlaintext string) (*User, error) {
    tokenHash := sha256.Sum256([]byte(tokenPlaintext))

    query := `
        SELECT users.id, users.created_at, users.name, users.email, users.password_hash, users.activated, users.version
        FROM users
        INNER JOIN tokens ON users.id = tokens.user_id
        WHERE tokens.hash = $1
        AND tokens.scope = $2
        AND tokens.expiry > $3`

    args := []interface{}{tokenHash[:], tokenScope, time.Now()}

    var user User
    ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
    defer cancel()

    err := m.DB.QueryRowContext(ctx, query, args...).Scan(
        &user.ID,
        &user.CreatedAt,
        &user.Name,
        &user.Email,
        &user.Password.hash,
        &user.Activated,
        &user.Version,
    )
    if err != nil {
        if errors.Is(err, sql.ErrNoRows) {
            return nil, ErrRecordNotFound
        }
        return nil, err
    }
    return &user, nil
}