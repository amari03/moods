-- The citext extension provides a case-insensitive character string type.
CREATE EXTENSION IF NOT EXISTS citext;

CREATE TABLE IF NOT EXISTS users (
    id BIGSERIAL PRIMARY KEY,
    created_at TIMESTAMP(0) WITH TIME ZONE NOT NULL DEFAULT NOW(),
    name VARCHAR(100) NOT NULL,
    email citext UNIQUE NOT NULL,
    password_hash bytea NOT NULL,
    activated BOOL NOT NULL DEFAULT FALSE,
    version INTEGER NOT NULL DEFAULT 1
);