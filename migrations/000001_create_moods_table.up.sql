CREATE TABLE IF NOT EXISTS moods (
    id BIGSERIAL PRIMARY KEY,
    created_at TIMESTAMP(0) WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP(0) WITH TIME ZONE NOT NULL DEFAULT NOW(),
    title VARCHAR(100) NOT NULL,
    content TEXT NOT NULL,
    emotion TEXT NOT NULL,
    emoji VARCHAR(10) NOT NULL,
    color VARCHAR(20) NOT NULL,
    user_id BIGINT NOT NULL -- We will add the foreign key constraint later
);