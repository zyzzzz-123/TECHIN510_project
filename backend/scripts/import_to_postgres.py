#!/usr/bin/env python3
import json
import sys
import os
import datetime
from sqlalchemy import create_engine, text
from sqlalchemy.exc import SQLAlchemyError

def import_data_to_postgres(json_file, db_url):
    """Import JSON data to PostgreSQL database."""
    print(f"Importing data from {json_file} to {db_url}")
    
    if not os.path.exists(json_file):
        print(f"Error: JSON file {json_file} not found.")
        sys.exit(1)
    
    try:
        # Load JSON data
        with open(json_file, 'r') as f:
            data = json.load(f)
        
        # Connect to PostgreSQL
        engine = create_engine(db_url)
        
        # Process each table
        for table_name, rows in data.items():
            print(f"Importing table: {table_name} ({len(rows)} rows)")
            
            if not rows:  # Skip empty tables
                print(f"  - Table {table_name} is empty, skipping")
                continue
                
            with engine.connect() as conn:
                # For each row in the table
                for row in rows:
                    # Build column names and placeholders
                    columns = ', '.join(row.keys())
                    placeholders = ', '.join([f":{k}" for k in row.keys()])
                    
                    # Create the SQL query
                    query = text(f"INSERT INTO {table_name} ({columns}) VALUES ({placeholders})")
                    
                    # Execute the query with parameters
                    try:
                        conn.execute(query, row)
                        conn.commit()
                    except SQLAlchemyError as e:
                        print(f"  - Error importing row: {e}")
                        conn.rollback()
            
            print(f"  - Table {table_name} imported")
        
        print("Import completed successfully")
        
    except Exception as e:
        print(f"Error during import: {e}")
        sys.exit(1)

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python import_to_postgres.py <json_file> <db_url>")
        print("Example: python import_to_postgres.py ../db_backup.json postgresql://postgres:password@localhost:5432/goalapp")
        sys.exit(1)
        
    json_file = sys.argv[1]
    db_url = sys.argv[2]
    import_data_to_postgres(json_file, db_url) 