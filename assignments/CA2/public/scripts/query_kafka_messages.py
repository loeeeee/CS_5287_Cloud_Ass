#!/usr/bin/env python3
"""
Kafka Messages Query Script

This script connects to PostgreSQL and queries messages that were
sunk from Kafka via Kafka Connect JDBC sink connector.

Usage:
    python3 query_kafka_messages.py [--limit N] [--format table|json]

Requirements:
    pip install -r requirements.txt
"""

import argparse
import json
import sys
from datetime import datetime
from typing import List, Dict, Any

try:
    import psycopg2
    from psycopg2.extras import RealDictCursor
    from tabulate import tabulate
except ImportError as e:
    print(f"Error: Missing required package. Please install requirements:")
    print(f"pip install -r requirements.txt")
    print(f"Missing: {e}")
    sys.exit(1)


class KafkaMessageQuerier:
    """Query Kafka messages from PostgreSQL database."""
    
    def __init__(self, host: str = "172.22.0.133", port: int = 5432, 
                 database: str = "kafka", user: str = "kafka", password: str = "kafka123"):
        """Initialize database connection parameters."""
        self.connection_params = {
            "host": host,
            "port": port,
            "database": database,
            "user": user,
            "password": password
        }
        self.conn = None
    
    def connect(self) -> bool:
        """Establish connection to PostgreSQL database."""
        try:
            self.conn = psycopg2.connect(**self.connection_params)
            print(f"✓ Connected to PostgreSQL at {self.connection_params['host']}:{self.connection_params['port']}")
            return True
        except psycopg2.Error as e:
            print(f"✗ Failed to connect to PostgreSQL: {e}")
            return False
    
    def disconnect(self):
        """Close database connection."""
        if self.conn:
            self.conn.close()
            print("✓ Database connection closed")
    
    def check_table_exists(self) -> bool:
        """Check if kafka_messages table exists."""
        try:
            with self.conn.cursor() as cursor:
                cursor.execute("""
                    SELECT EXISTS (
                        SELECT FROM information_schema.tables 
                        WHERE table_schema = 'public' 
                        AND table_name = 'kafka_messages'
                    );
                """)
                exists = cursor.fetchone()[0]
                return exists
        except psycopg2.Error as e:
            print(f"✗ Error checking table existence: {e}")
            return False
    
    def get_table_schema(self) -> List[Dict[str, Any]]:
        """Get the schema of kafka_messages table."""
        try:
            with self.conn.cursor(cursor_factory=RealDictCursor) as cursor:
                cursor.execute("""
                    SELECT column_name, data_type, is_nullable, column_default
                    FROM information_schema.columns 
                    WHERE table_schema = 'public' 
                    AND table_name = 'kafka_messages'
                    ORDER BY ordinal_position;
                """)
                return cursor.fetchall()
        except psycopg2.Error as e:
            print(f"✗ Error getting table schema: {e}")
            return []
    
    def query_messages(self, limit: int = 50) -> List[Dict[str, Any]]:
        """Query messages from kafka_messages table."""
        try:
            with self.conn.cursor(cursor_factory=RealDictCursor) as cursor:
                cursor.execute("""
                    SELECT * FROM kafka_messages 
                    ORDER BY processed_at DESC 
                    LIMIT %s;
                """, (limit,))
                return cursor.fetchall()
        except psycopg2.Error as e:
            print(f"✗ Error querying messages: {e}")
            return []
    
    def get_message_count(self) -> int:
        """Get total count of messages in the table."""
        try:
            with self.conn.cursor() as cursor:
                cursor.execute("SELECT COUNT(*) FROM kafka_messages;")
                return cursor.fetchone()[0]
        except psycopg2.Error as e:
            print(f"✗ Error getting message count: {e}")
            return 0
    
    def format_messages_table(self, messages: List[Dict[str, Any]]) -> str:
        """Format messages as a table."""
        if not messages:
            return "No messages found."
        
        # Convert to list of lists for tabulate
        table_data = []
        for msg in messages:
            row = []
            for key, value in msg.items():
                if isinstance(value, datetime):
                    row.append(value.strftime("%Y-%m-%d %H:%M:%S"))
                elif value is None:
                    row.append("NULL")
                else:
                    row.append(str(value))
            table_data.append(row)
        
        headers = list(messages[0].keys()) if messages else []
        return tabulate(table_data, headers=headers, tablefmt="grid")
    
    def format_messages_json(self, messages: List[Dict[str, Any]]) -> str:
        """Format messages as JSON."""
        # Convert datetime objects to strings for JSON serialization
        json_messages = []
        for msg in messages:
            json_msg = {}
            for key, value in msg.items():
                if isinstance(value, datetime):
                    json_msg[key] = value.isoformat()
                else:
                    json_msg[key] = value
            json_messages.append(json_msg)
        
        return json.dumps(json_messages, indent=2)


def main():
    """Main function."""
    parser = argparse.ArgumentParser(description="Query Kafka messages from PostgreSQL")
    parser.add_argument("--limit", type=int, default=50, 
                       help="Maximum number of messages to retrieve (default: 50)")
    parser.add_argument("--format", choices=["table", "json"], default="table",
                       help="Output format (default: table)")
    parser.add_argument("--host", default="172.22.0.133",
                       help="PostgreSQL host (default: 172.22.0.133)")
    parser.add_argument("--port", type=int, default=5432,
                       help="PostgreSQL port (default: 5432)")
    parser.add_argument("--database", default="kafka",
                       help="Database name (default: kafka)")
    parser.add_argument("--user", default="kafka",
                       help="Database user (default: kafka)")
    parser.add_argument("--password", default="kafka123",
                       help="Database password (default: kafka123)")
    
    args = parser.parse_args()
    
    # Initialize querier
    querier = KafkaMessageQuerier(
        host=args.host,
        port=args.port,
        database=args.database,
        user=args.user,
        password=args.password
    )
    
    # Connect to database
    if not querier.connect():
        sys.exit(1)
    
    try:
        # Check if table exists
        if not querier.check_table_exists():
            print("✗ Table 'kafka_messages' does not exist.")
            print("Make sure Kafka Connect JDBC sink connector is running and has created the table.")
            sys.exit(1)
        
        # Get table schema
        print("\n📋 Table Schema:")
        schema = querier.get_table_schema()
        if schema:
            schema_data = [[col['column_name'], col['data_type'], col['is_nullable']] 
                          for col in schema]
            print(tabulate(schema_data, headers=["Column", "Type", "Nullable"], tablefmt="grid"))
        
        # Get message count
        count = querier.get_message_count()
        print(f"\n📊 Total messages in database: {count}")
        
        # Query messages
        print(f"\n🔍 Retrieving latest {args.limit} messages...")
        messages = querier.query_messages(args.limit)
        
        if not messages:
            print("No messages found in the database.")
        else:
            print(f"Found {len(messages)} messages.")
            
            # Format and display results
            if args.format == "json":
                print("\n📄 Messages (JSON format):")
                print(querier.format_messages_json(messages))
            else:
                print("\n📄 Messages (Table format):")
                print(querier.format_messages_table(messages))
    
    finally:
        querier.disconnect()


if __name__ == "__main__":
    main()
