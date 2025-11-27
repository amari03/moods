include .envrc

## run: run the cmd/api application
.PHONY: run
run:
	@echo 'Running application...'
	@go run ./cmd/api \
	-port=4000 \
	-env=development \
	-db-dsn=${FEEL_FLOW_DB_DSN} \
	-smtp-host=${SMTP_HOST} \
	-smtp-port=${SMTP_PORT} \
	-smtp-username=${SMTP_USERNAME} \
	-smtp-password=${SMTP_PASSWORD} \
	-smtp-sender=${SMTP_SENDER} \
	-cors-trusted-origins="http://localhost:3000 http://localhost"

## db/psql: connect to the database using psql (terminal)
.PHONY: db/psql
db/psql:
	psql ${FEEL_FLOW_DB_DSN}

## db/migrations/new: create a new database migration
.PHONY: db/migrations/new
db/migrations/new:
	@echo 'Creating migration files for ${name}...'
	migrate create -seq -ext=.sql -dir=./migrations ${name}

## db/migrations/up: apply all up database migrations
.PHONY: db/migrations/up
db/migrations/up:
	@echo 'Running up migrations...'
	migrate -path ./migrations -database "postgres://postgres:2020151994@localhost/feel_flow_db?sslmode=disable" up