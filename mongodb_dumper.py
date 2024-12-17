from pymongo import MongoClient
import json
import os
from bson import ObjectId
from datetime import datetime

def json_serial(obj):
    """
    JSON serializer for objects not serializable by default json code
    
    Handles:
    - ObjectId
    - datetime
    - Other potential non-serializable types
    """
    if isinstance(obj, ObjectId):
        return str(obj)
    elif isinstance(obj, datetime):
        return obj.isoformat()
    elif hasattr(obj, '__dict__'):
        return obj.__dict__
    raise TypeError(f"Type {type(obj)} not serializable")

def dump_all_mongodb_databases(host='localhost', port=27017, username=None, password=None, output_base_dir='mongodb_full_dump'):
    """
    Dump all databases and their collections to individual JSON files.
    
    Args:
    - host: MongoDB host (default: localhost)
    - port: MongoDB port (default: 27017)
    - username: Optional username for authentication
    - password: Optional password for authentication
    - output_base_dir: Base directory to save database dumps (default: mongodb_full_dump)
    """
    try:
        # Establish connection
        if username and password:
            client = MongoClient(host, port, 
                                 username=username, 
                                 password=password)
        else:
            client = MongoClient(host, port)
        
        # Create base output directory
        os.makedirs(output_base_dir, exist_ok=True)
        
        # Get list of databases
        databases = client.list_database_names()
        
        # Track total statistics
        total_databases = 0
        total_collections = 0
        total_documents = 0
        
        # Dump each database
        for database_name in databases:
            # Skip system databases unless explicitly needed
            if database_name in ['admin', 'local', 'config']:
                continue
            
            # Create database-specific directory
            db_output_dir = os.path.join(output_base_dir, database_name)
            os.makedirs(db_output_dir, exist_ok=True)
            
            # Select database
            db = client[database_name]
            
            # Get all collection names
            collections = db.list_collection_names()
            
            # Dump each collection in the database
            for collection_name in collections:
                # Get collection
                collection = db[collection_name]
                
                # Retrieve all documents
                documents = list(collection.find())
                
                # Output filename
                output_file = os.path.join(db_output_dir, f"{collection_name}.json")
                
                # Write to JSON file with custom serialization
                with open(output_file, 'w', encoding='utf-8') as f:
                    json.dump(documents, f, indent=2, default=json_serial, ensure_ascii=False)
                
                # Update statistics
                total_collections += 1
                total_documents += len(documents)
                
                print(f"Dumped {database_name}.{collection_name}: {len(documents)} documents")
            
            total_databases += 1
        
        # Print final statistics
        print("\n--- Dump Complete ---")
        print(f"Total Databases Dumped: {total_databases}")
        print(f"Total Collections Dumped: {total_collections}")
        print(f"Total Documents Dumped: {total_documents}")
        print(f"Output Directory: {output_base_dir}")
    
    except Exception as e:
        print(f"An error occurred: {e}")
        import traceback
        traceback.print_exc()  # This will print the full stack trace
    finally:
        client.close()

# Example usage
if __name__ == "__main__":
    dump_all_mongodb_databases(
        host='localhost',
        port=27017,
        username=None,     # Set username if authentication is required
        password=None,     # Set password if authentication is required
        output_base_dir='mongodb_full_dump'
    )
