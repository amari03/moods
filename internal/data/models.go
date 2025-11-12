package data

import "database/sql"

type Models struct {
    Moods MoodModel
    Users UserModel
    Tokens TokenModel
}

func NewModels(db *sql.DB) Models {
    return Models{
        Moods: MoodModel{DB: db},
        Users: UserModel{DB: db},
        Tokens: TokenModel{DB: db},
    }
}