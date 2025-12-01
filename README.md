# Feel-Flow API
This repository contains the backend API for the Feel-Flow mobile application. It is a production-ready web service built in Go that provides endpoints for user authentication, mood tracking, and more.  

The API features JWT-based authentication, rate limiting, CORS, detailed filtering/pagination/sorting, and integration with an external service for providing inspirational quotes.  

## **Features**

- User Management: User registration, login, and profile management.
- CRUD Operations: Full Create, Read, Update, and Delete functionality for mood entries.
- Authentication: Secure JWT-based authentication for protected endpoints.
- Advanced Querying: Pagination, sorting, and filtering for list endpoints.
- Security: Rate limiting, CORS configuration, and environment-based secrets management.
- Third-Party Integration: Fetches random inspirational quotes from the Zen Quotes API.
- Health Checks: /healthcheck endpoint for monitoring application status.  

## **Quickstart Guide**
Follow these steps to get the API server running on your local machine.
**Prerequisites**  
- Go (version 1.21 or newer)
- PostgreSQL (running locally or accessible)
- make command-line tool
- .envrc for managing environment variables  

**Installation & Setup**
1. Clone the repository:
```Bash
git clone https://amari03/feel-flow-api.git
cd feel-flow-api
```
2. Configure Environment Variables:
The application uses environment variables for configuration. You can use a .envrc file, you can find an example file. 

Copy the example file:
```Bash
cp .envrc.example .envrc
```
3. Run Database Migrations:
Before starting the server, you need to set up the database schema.
```Bash
make db-migrations-up
```
**Running the Server**
1. Start the API:
```Bash
make run
```
2. Verify it's running:
You should see a log message indicating the server has started, typically on port 4000. You can check the healthcheck endpoint to confirm it's working:
```Bash
curl http://localhost:4000/v1/healthcheck
```
You should get a JSON response indicating the status is "available".  

You can use the curl commands provided in the file `curl_commands.md` to play round with your data.
# Architecture Overview
The API is built using the standard Go net/http library and follows a clean, layered architecture to ensure separation of concerns.  

- **Dependency Injection:** The `main.go` file initializes all dependencies (logger, database models, mailer, quote client) and injects them into the handlers. This makes the application easy to test and maintain.
- **Layered Structure:** The code is organized into distinct layers within the `/internal` directory:
    - `/cmd/api`: The entry point of the application. Handles configuration, dependency injection, and starts the HTTP server.
    - `/internal/data`: Contains the data models and the logic for interacting with the database (repository pattern).
    - `/internal/mailer`: A package for sending emails (e.g., for user activation).
    - `/internal/quotes`: An isolated client for interacting with the third-party Zen Quotes API.
- **Handlers & Routing**: Handlers for each resource (users, moods) are in their own files. Routes are registered in a central `routes.go` file, which also applies middleware for rate limiting, CORS, and authentication.

# FRONTEND  
The frontend is a mobile-first web application built with Flutter. Follow these steps to get it running.  
### **Prerequisites**
- Flutter SDK: Ensure you have the Flutter SDK installed and the flutter command is available in your terminal. For installation instructions, see the official Flutter documentation.
- Google Chrome: Required for running the web version of the app.

### **Installation & Setup**  
1. Navigate to the frontend directory:  
From the root of the project, `cd` into the frontend folder.
``` Bash
cd frontend 
```
2. Install dependencies:  
Run the following command to download all the necessary packages for the Flutter project:
``` Bash
flutter pub get
```

## Running the Frontend
**Important Note:** Before starting the frontend, make sure the backend server is already running.  
**Start the frontend:**
Go back into your frontend directory. Run the application on a stable port (`3000`) so that features like email activation links will work correctly.  
``` Bash
# From the frontend folder
flutter run -d chrome --web-port=3000
```

The application will launch in a new Chrome window. You can now register, activate, and log in to use the app.