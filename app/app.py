from flask import Flask, render_template, request, redirect, jsonify
import mysql.connector
import os
import time
import logging
import json
from datetime import datetime
from pythonjsonlogger import jsonlogger

app = Flask(__name__)

# Configurar logging en formato JSON para ELK
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Handler para stdout (para contenedores)
log_handler = logging.StreamHandler()
formatter = jsonlogger.JsonFormatter()
log_handler.setFormatter(formatter)
logger.addHandler(log_handler)

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
            logger.info("Database connection successful", extra={"attempt": attempt + 1})
            return connection
        except mysql.connector.Error as err:
            logger.error("Database connection failed", extra={
                "attempt": attempt + 1,
                "max_retries": max_retries,
                "error": str(err),
                "error_code": getattr(err, 'errno', 'unknown')
            })
            if attempt < max_retries - 1:
                time.sleep(retry_delay)
            else:
                logger.critical("Failed to connect to database after retries", extra={
                    "max_retries": max_retries,
                    "error": str(err)
                })
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
        logger.info("Database initialized successfully")
    except Exception as e:
        logger.error("Error initializing database", extra={"error": str(e)})

@app.route('/')
def index():
    """Página principal con lista de tareas"""
    try:
        logger.info("GET / - Fetching all tasks")
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)
        cursor.execute("SELECT * FROM tasks ORDER BY created_at DESC")
        tasks = cursor.fetchall()
        cursor.close()
        connection.close()
        logger.info("GET / - Tasks fetched successfully", extra={"count": len(tasks)})
        return render_template('index.html', tasks=tasks)
    except Exception as e:
        logger.error("GET / - Error fetching tasks", extra={"error": str(e)})
        return f"Error: {e}", 500

@app.route('/add', methods=['POST'])
def add_task():
    """Añadir nueva tarea"""
    try:
        title = request.form.get('title')
        description = request.form.get('description', '')
        
        logger.info("POST /add - Adding new task", extra={"title": title})
        
        connection = get_db_connection()
        cursor = connection.cursor()
        cursor.execute(
            "INSERT INTO tasks (title, description) VALUES (%s, %s)",
            (title, description)
        )
        connection.commit()
        cursor.close()
        connection.close()
        logger.info("POST /add - Task added successfully", extra={"title": title})
        return redirect('/')
    except Exception as e:
        logger.error("POST /add - Error adding task", extra={"error": str(e), "title": title})
        return f"Error: {e}", 500

@app.route('/delete/<int:task_id>')
def delete_task(task_id):
    """Eliminar tarea"""
    try:
        logger.info("DELETE /delete - Deleting task", extra={"task_id": task_id})
        connection = get_db_connection()
        cursor = connection.cursor()
        cursor.execute("DELETE FROM tasks WHERE id = %s", (task_id,))
        connection.commit()
        cursor.close()
        connection.close()
        logger.info("DELETE /delete - Task deleted successfully", extra={"task_id": task_id})
        return redirect('/')
    except Exception as e:
        logger.error("DELETE /delete - Error deleting task", extra={"error": str(e), "task_id": task_id})
        return f"Error: {e}", 500

@app.route('/toggle/<int:task_id>')
def toggle_task(task_id):
    """Marcar tarea como completada/pendiente"""
    try:
        logger.info("PUT /toggle - Toggling task status", extra={"task_id": task_id})
        connection = get_db_connection()
        cursor = connection.cursor()
        cursor.execute(
            "UPDATE tasks SET completed = NOT completed WHERE id = %s",
            (task_id,)
        )
        connection.commit()
        cursor.close()
        connection.close()
        logger.info("PUT /toggle - Task toggled successfully", extra={"task_id": task_id})
        return redirect('/')
    except Exception as e:
        logger.error("PUT /toggle - Error toggling task", extra={"error": str(e), "task_id": task_id})
        return f"Error: {e}", 500

@app.route('/health')
def health():
    """Endpoint de salud para Kubernetes"""
    try:
        connection = get_db_connection()
        connection.close()
        logger.info("GET /health - Health check passed")
        return jsonify({"status": "healthy", "database": "connected"}), 200
    except Exception as e:
        logger.error("GET /health - Health check failed", extra={"error": str(e)})
        return jsonify({"status": "unhealthy", "error": str(e)}), 503

if __name__ == '__main__':
    # Inicializar base de datos al arrancar
    init_db()
    # Ejecutar aplicación
    app.run(host='0.0.0.0', port=5000, debug=True)