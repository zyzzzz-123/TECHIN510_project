# GoalAchiever Backend API

This is the backend API for the GoalAchiever app, built with FastAPI and SQLAlchemy.

## Development Setup

### Prerequisites

- Python 3.10+
- pip
- SQLite (for development)
- PostgreSQL (for production)

### Installation

1. Clone the repository
2. Create a virtual environment: `python -m venv venv`
3. Activate the virtual environment:
   - Windows: `venv\Scripts\activate`
   - macOS/Linux: `source venv/bin/activate`
4. Install dependencies: `pip install -r requirements.txt`
5. Create a `.env` file in the root directory with the following content:
   ```
   DATABASE_URL=sqlite:///./test.db
   SECRET_KEY=your-secret-key
   ALGORITHM=HS256
   ACCESS_TOKEN_EXPIRE_MINUTES=1440
   OPENAI_API_KEY=your-openai-api-key
   GEMINI_API_KEY=your-gemini-api-key
   DEFAULT_AI_MODEL=openai  # or 'gemini'
   ```
6. Run migrations: `alembic upgrade head`
7. Start the development server: `uvicorn app.main:app --reload`

## AI Integration

The backend supports both OpenAI and Google Gemini for AI chat functionality:

1. **API Keys**: Set either or both API keys in your `.env` file:
   ```
   OPENAI_API_KEY=your-openai-api-key
   GEMINI_API_KEY=your-gemini-api-key
   ```

2. **Default Model**: Set your preferred default model:
   ```
   DEFAULT_AI_MODEL=openai  # or 'gemini'
   ```

3. **Flexibility**: The system will:
   - Use your default model if available
   - Fall back to the other model if the default is unavailable
   - Allow explicit model selection via the API

4. **API Usage**: Clients can specify which model to use by adding the `model_provider` parameter:
   ```
   POST /chat/
   {
     "message": "Your message here",
     "model_provider": "openai"  # or "gemini"
   }
   ```

## Task Intent API

The backend provides a powerful AI task management interface through the Task Intent API:

### 1. Analyzing Task Intent

To analyze a user's message for task-related intent:

```
POST /api/tasks/intent
{
  "message": "添加一个明天截止的写报告任务",
  "model_provider": "openai"
}
```

Response:
```json
{
  "intent": {
    "action": "add_task",
    "task": {
      "text": "写报告",
      "due_date": "2023-06-15T00:00:00.000Z"
    },
    "confirmation_prompt": "是否要添加一个明天截止的写报告任务？"
  }
}
```

For query intent, the API will also return matching tasks:
```
POST /api/tasks/intent
{
  "message": "显示所有今天到期的任务"
}
```

Response:
```json
{
  "intent": {
    "action": "query_task",
    "task": {
      "date_filter": "today"
    },
    "confirmation_prompt": "以下是今天到期的任务："
  },
  "tasks": [
    {
      "id": 1,
      "text": "写报告",
      "status": "todo",
      "type": "todo",
      "due_date": "2023-06-15T00:00:00.000Z",
      "created_at": "2023-06-14T10:00:00.000Z"
    }
  ]
}
```

### 2. Executing Task Intent

To execute a task intent after confirmation:

```
POST /api/tasks/execute_intent
{
  "intent": {
    "action": "add_task",
    "task": {
      "text": "写报告",
      "due_date": "2023-06-15T00:00:00.000Z"
    }
  }
}
```

Response:
```json
{
  "success": true,
  "message": "已创建任务: 写报告",
  "task": {
    "id": 1,
    "text": "写报告",
    "status": "todo",
    "type": "todo",
    "due_date": "2023-06-15T00:00:00.000Z"
  }
}
```

### 3. Chat Integration

You can also analyze task intent directly in chat requests:

```
POST /chat/
{
  "message": "添加一个明天截止的写报告任务",
  "model_provider": "openai",
  "analyze_task_intent": true
}
```

Response:
```json
{
  "response": "是否要添加一个明天截止的写报告任务？",
  "task_intent": {
    "action": "add_task",
    "task": {
      "text": "写报告",
      "due_date": "2023-06-15T00:00:00.000Z"
    }
  }
}
```

If no task intent is detected, the response will just contain the AI's reply.

## Docker Local Setup

1. Build and start the containers: `docker-compose up -d --build`
2. Access the API at http://localhost:8000
3. Access the API documentation at http://localhost:8000/docs

## Database Migration

### Migrating from SQLite to PostgreSQL

1. Navigate to the `scripts` directory: `cd scripts`
2. Run the migration script:
   ```
   bash migrate_to_postgres.sh --sqlite-db ../test.db --pg-user postgres --pg-password your-password --pg-host localhost --pg-db goalapp
   ```

### Manual Migration Steps

1. Export data from SQLite:
   ```
   python scripts/export_sqlite_data.py test.db db_backup.json
   ```
2. Run migrations on PostgreSQL:
   ```
   DATABASE_URL=postgresql://postgres:password@localhost:5432/goalapp alembic upgrade head
   ```
3. Import data to PostgreSQL:
   ```
   python scripts/import_to_postgres.py db_backup.json postgresql://postgres:password@localhost:5432/goalapp
   ```

## Deployment

### Railway Deployment

1. Sign up for a [Railway](https://railway.app/) account
2. Install the Railway CLI: `npm i -g @railway/cli`
3. Login to Railway: `railway login`
4. Link to your project: `railway link`
5. Add environment variables through the Railway dashboard
6. Deploy your application: `railway up`

### Manual Deployment

1. Set up a PostgreSQL database
2. Set the following environment variables on your hosting provider:
   - `DATABASE_URL`: Your PostgreSQL connection string
   - `SECRET_KEY`: A secure secret key
   - `ALGORITHM`: HS256 (default)
   - `ACCESS_TOKEN_EXPIRE_MINUTES`: Token expiration time
   - `OPENAI_API_KEY`: Your OpenAI API key
   - `GEMINI_API_KEY`: Your Google Gemini API key
   - `DEFAULT_AI_MODEL`: Your preferred default AI model ("openai" or "gemini")
3. Deploy the code to your hosting provider
4. Run migrations: `alembic upgrade head`

## API Documentation

Once deployed, you can access the API documentation at:
- Swagger UI: `/docs`
- ReDoc: `/redoc`

## Maintenance

### Running Migrations

Create a new migration:
```
alembic revision --autogenerate -m "description"
```

Apply migrations:
```
alembic upgrade head
```

Revert migrations:
```
alembic downgrade -1
```
