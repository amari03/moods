# API Usage Examples (cURL)
The base URL for all endpoints is `http://localhost:4000/v1`.  

**Authentication**
1. Register a new user
```Bash
curl -X POST http://localhost:4000/v1/users \
-H "Content-Type: application/json" \
-d '{
  "name": "Joana Doe",
  "email": "Joana@example.com",
  "password": "a-strong-password"
}'
```
2. Get an authentication token (Log in)
After registering, the user must be activated (check your email if using the mailer). Then, log in to get a JWT.
```Bash
curl -X POST http://localhost:4000/v1/tokens/authentication \
-H "Content-Type: application/json" \
-d '{
  "email": "Joana@example.com",
  "password": "a-strong-password"
}'
```
The response will contain a token. Copy this token for use in authenticated requests.  

### **Users**  
(Details for user endpoints can be added here if needed, e.g., Get User Profile, Update User)  

### **Moods (Authenticated)**  
**Note**: For the following requests, replace `<YOUR_JWT_TOKEN>` with the token you received from the login step. For convenience, you can set it as a shell variable:
```Bash
TOKEN="<YOUR_JWT_TOKEN>"
```
1. Create a new mood entry
```Bash
curl -X POST http://localhost:4000/v1/moods \
-H "Authorization: Bearer $TOKEN" \
-H "Content-Type: application/json" \
-d '{
  "title": "A Productive Day",
  "content": "Finished all my tasks for the day and worked on the Feel-Flow project.",
  "emotion": "happy",
  "emoji": "😊",
  "color": "#FFC0CB"
}'
```
2. Get all mood entries (with filtering and sorting)
```Bash
curl -X GET "http://localhost:4000/v1/moods?page=1&page_size=5&sort=-created_at" \
-H "Authorization: Bearer $TOKEN"
```
3. Update a mood entry
```Bash
# First, get the ID of a mood you want to update
MOOD_ID="your-mood-id-here"

curl -X PATCH http://localhost:4000/v1/moods/$MOOD_ID \
-H "Authorization: Bearer $TOKEN" \
-H "Content-Type: application/json" \
-d '{
  "title": "An updated title",
  "content": "This content has been updated."
}'
```
## **Quotes (External API)**
Get a random inspirational quote
This endpoint is public and does not require authentication.
```Bash
curl http://localhost:4000/api/v1/quote
```