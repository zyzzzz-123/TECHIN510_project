#!/bin/bash
set -e

# Default values
SQLITE_DB="../test.db"
BACKUP_FILE="db_backup.json"
PG_USER="postgres"
PG_PASSWORD="password"
PG_HOST="localhost"
PG_PORT="5432"
PG_DB="goalapp"

# Display usage info
function show_usage {
  echo "Usage: $0 [options]"
  echo "Options:"
  echo "  -s, --sqlite-db PATH     Path to SQLite database file (default: $SQLITE_DB)"
  echo "  -b, --backup-file PATH   Path to JSON backup file (default: $BACKUP_FILE)"
  echo "  -u, --pg-user USER       PostgreSQL username (default: $PG_USER)"
  echo "  -p, --pg-password PASS   PostgreSQL password (default: $PG_PASSWORD)"
  echo "  -h, --pg-host HOST       PostgreSQL host (default: $PG_HOST)"
  echo "  -P, --pg-port PORT       PostgreSQL port (default: $PG_PORT)"
  echo "  -d, --pg-db DB           PostgreSQL database name (default: $PG_DB)"
  echo "  --help                   Display this help message"
  exit 1
}

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -s|--sqlite-db)
      SQLITE_DB="$2"
      shift 2
      ;;
    -b|--backup-file)
      BACKUP_FILE="$2"
      shift 2
      ;;
    -u|--pg-user)
      PG_USER="$2"
      shift 2
      ;;
    -p|--pg-password)
      PG_PASSWORD="$2"
      shift 2
      ;;
    -h|--pg-host)
      PG_HOST="$2"
      shift 2
      ;;
    -P|--pg-port)
      PG_PORT="$2"
      shift 2
      ;;
    -d|--pg-db)
      PG_DB="$2"
      shift 2
      ;;
    --help)
      show_usage
      ;;
    *)
      echo "Unknown option: $1"
      show_usage
      ;;
  esac
done

# Build PostgreSQL connection URL
PG_URL="postgresql://$PG_USER:$PG_PASSWORD@$PG_HOST:$PG_PORT/$PG_DB"

# Check if Python scripts exist
if [ ! -f "export_sqlite_data.py" ]; then
  echo "Error: export_sqlite_data.py not found in current directory"
  exit 1
fi

if [ ! -f "import_to_postgres.py" ]; then
  echo "Error: import_to_postgres.py not found in current directory"
  exit 1
fi

echo "=== Starting migration from SQLite to PostgreSQL ==="
echo "SQLite DB: $SQLITE_DB"
echo "Backup file: $BACKUP_FILE"
echo "PostgreSQL connection: $PG_URL"
echo

# Export data from SQLite
echo "1. Exporting data from SQLite..."
python export_sqlite_data.py "$SQLITE_DB" "$BACKUP_FILE"
echo

# Run Alembic migrations to create schema in PostgreSQL
echo "2. Creating schema in PostgreSQL using Alembic..."
cd ..
export DATABASE_URL="$PG_URL"
alembic upgrade head
cd scripts
echo

# Import data to PostgreSQL
echo "3. Importing data to PostgreSQL..."
python import_to_postgres.py "$BACKUP_FILE" "$PG_URL"
echo

echo "=== Migration completed successfully! ===" 