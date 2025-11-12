package data

import "database/sql"

type Models struct {
    Moods MoodModel
}

func NewModels(db *sql.DB) Models {
    return Models{
        Moods: MoodModel{DB: db},
    }
}