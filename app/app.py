from flask import Flask, render_template, request, redirect, jsonify
import mysql.connector
import os
import time

app = Flask(__name__)

# Configuración de la base de datos desde variables de entorno
DB_CONFIG = {
    'host': os.getenv('DB_HOST', 'mysql-service'),
    'user': os.getenv('DB_USER', 'root'),
    'password': os.getenv('DB_PASSWORD', 'rootpassword'),
    'database': os.getenv('DB_NAME', 'taskdb')
}

def get_db_connection():
    """Intenta conectar a la base de datos con reintentos"""
    max_retries = 5
    retry_delay = 3
    
    for attempt in range(max_retries):
        try:
            connection = mysql.connector.connect(**DB_CONFIG)
            return connection
        except mysql.connector.Error as err:
            if attempt < max_retries - 1:
                print(f"Error connecting to database (attempt {attempt + 1}/{max_retries}): {err}")
                time.sleep(retry_delay)
            else:
                print(f"Failed to connect to database after {max_retries} attempts")
                raise

def init_db():
    """Inicializa la base de datos y crea la tabla si no existe"""
    try:
        connection = get_db_connection()
        cursor = connection.cursor()
        
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS tasks (
                id INT AUTO_INCREMENT PRIMARY KEY,
                title VARCHAR(255) NOT NULL,
                description TEXT,
                completed BOOLEAN DEFAULT FALSE,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)
        
        connection.commit()
        cursor.close()
        connection.close()
        print("Database initialized successfully")
    except Exception as e:
        print(f"Error initializing database: {e}")

@app.route('/')
def index():
    """Página principal con lista de tareas"""
    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)
        cursor.execute("SELECT * FROM tasks ORDER BY created_at DESC")
        tasks = cursor.fetchall()
        cursor.close()
        connection.close()
        return render_template('index.html', tasks=tasks)
    except Exception as e:
        return f"Error: {e}", 500

@app.route('/add', methods=['POST'])
def add_task():
    """Añadir nueva tarea"""
    try:
        title = request.form.get('title')
        description = request.form.get('description', '')
        
        connection = get_db_connection()
        cursor = connection.cursor()
        cursor.execute(
            "INSERT INTO tasks (title, description) VALUES (%s, %s)",
            (title, description)
        )
        connection.commit()
        cursor.close()
        connection.close()
        return redirect('/')
    except Exception as e:
        return f"Error: {e}", 500

@app.route('/delete/<int:task_id>')
def delete_task(task_id):
    """Eliminar tarea"""
    try:
        connection = get_db_connection()
        cursor = connection.cursor()
        cursor.execute("DELETE FROM tasks WHERE id = %s", (task_id,))
        connection.commit()
        cursor.close()
        connection.close()
        return redirect('/')
    except Exception as e:
        return f"Error: {e}", 500

@app.route('/toggle/<int:task_id>')
def toggle_task(task_id):
    """Marcar tarea como completada/pendiente"""
    try:
        connection = get_db_connection()
        cursor = connection.cursor()
        cursor.execute(
            "UPDATE tasks SET completed = NOT completed WHERE id = %s",
            (task_id,)
        )
        connection.commit()
        cursor.close()
        connection.close()
        return redirect('/')
    except Exception as e:
        return f"Error: {e}", 500

@app.route('/health')
def health():
    """Endpoint de salud para Kubernetes"""
    try:
        connection = get_db_connection()
        connection.close()
        return jsonify({"status": "healthy", "database": "connected"}), 200
    except Exception as e:
        return jsonify({"status": "unhealthy", "error": str(e)}), 503

if __name__ == '__main__':
    # Inicializar base de datos al arrancar
    init_db()
    # Ejecutar aplicación
    app.run(host='0.0.0.0', port=5000, debug=True)