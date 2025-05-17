#!/usr/bin/env python3
import sqlite3
import json
import datetime
import os
import sys

def converter(o):
    """Convert datetime objects to ISO format strings for JSON serialization."""
    if isinstance(o, datetime.datetime):
        return o.isoformat()
    return str(o)

def export_sqlite_data(db_path, output_path):
    """Export all tables from SQLite database to JSON file."""
    print(f"Exporting data from {db_path} to {output_path}")
    
    if not os.path.exists(db_path):
        print(f"Error: Database file {db_path} not found.")
        sys.exit(1)
        
    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    
    # Get all table names
    tables = cursor.execute('SELECT name FROM sqlite_master WHERE type="table"').fetchall()
    data = {}
    
    for table in tables:
        table_name = table['name']
        if table_name.startswith('sqlite_'):
            continue
        
        print(f"Exporting table: {table_name}")
        rows = cursor.execute(f'SELECT * FROM {table_name}').fetchall()
        data[table_name] = [dict(row) for row in rows]
        print(f"  - Exported {len(data[table_name])} rows")
    
    with open(output_path, 'w') as f:
        json.dump(data, f, default=converter, indent=2)
    
    conn.close()
    print(f"Export completed. Data saved to {output_path}")

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python export_sqlite_data.py <sqlite_db_path> <output_json_path>")
        print("Example: python export_sqlite_data.py ../test.db ../db_backup.json")
        sys.exit(1)
        
    db_path = sys.argv[1]
    output_path = sys.argv[2]
    export_sqlite_data(db_path, output_path) 