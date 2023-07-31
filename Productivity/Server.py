import asyncio
import websockets
import sqlite3
import uuid

async def echo(websocket, path):
    async for message in websocket:
        response = f"Server received: {message}"
        await websocket.send(response)

if __name__ == "__main__":
    start_server = websockets.serve(echo, "0.0.0.0", 8765)
    asyncio.get_event_loop().run_until_complete(start_server)
    asyncio.get_event_loop().run_forever()

def create_database():
    # Connect to or create the SQLite database file
    conn = sqlite3.connect('local_database.db')
    cursor = conn.cursor()

    # Create the table with the specified columns
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS tasks (
            id TEXT PRIMARY KEY,
            name TEXT,
            progressToday INTEGER,
            goalToday INTEGER,
            color TEXT,
            isCompleted INTEGER,
            isHidden INTEGER
        )
    ''')

    # Save the changes and close the connection
    conn.commit()
    conn.close()

if __name__ == "__main__":
    create_database()
