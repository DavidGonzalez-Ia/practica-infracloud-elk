# TaskManager Application with Structured JSON Logging
# Autores: Manuel Botella, Carlos Gomez, Diego Rodriguez, Hugo Langenaeken, David Gonzalez
# Fecha: Diciembre 2025

from flask import Flask, render_template, request, redirect, jsonify
import mysql.connector
import os
import time
import logging
import json
from datetime import datetime

# Configurar logging estructurado en formato JSON
class JSONFormatter(logging.Formatter):
    def format(self, record):
        log_data = {
            'timestamp': datetime.utcnow().isoformat(),
            'level': record.levelname,
            'logger': record.name,
            'message': record.getMessage(),
            'module': record.module,
            'function': record.funcName,
            'line': record.lineno
        }
        
        # Añadir información extra si existe
        if hasattr(record, 'extra_data'):
            log_data.update(record.extra_data)
            
        # Añadir excepción si existe
        if record.exc_info:
            log_data['exception'] = self.formatException(record.exc_info)
            
        return json.dumps(log_data)

# Configurar el logger
logger = logging.getLogger('taskmanager')
logger.setLevel(logging.INFO)

# Handler para stdout (capturado por Filebeat)
handler = logging.StreamHandler()
handler.setFormatter(JSONFormatter())
logger.addHandler(handler)

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
            logger.info("Database connection established", extra={'extra_data': {
                'attempt': attempt + 1,
                'db_host': DB_CONFIG['host']
            }})
            return connection
        except mysql.connector.Error as err:
            if attempt < max_retries - 1:
                logger.warning("Database connection attempt failed", extra={'extra_data': {
                    'attempt': attempt + 1,
                    'max_retries': max_retries,
                    'error': str(err)
                }})
                time.sleep(retry_delay)
            else:
                logger.error("Failed to connect to database after all retries", extra={'extra_data': {
                    'max_retries': max_retries,
                    'error': str(err)
                }})
                raise

def init_db():
    """Inicializa la base de datos y crea la tabla si no existe"""
    try:
        logger.info("Initializing database")
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
        logger.error("Error initializing database", extra={'extra_data': {
            'error': str(e)
        }})

@app.route('/')
def index():
    """Página principal con lista de tareas"""
    try:
        logger.info("Fetching tasks list")
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)
        cursor.execute("SELECT * FROM tasks ORDER BY created_at DESC")
        tasks = cursor.fetchall()
        cursor.close()
        connection.close()
        logger.info("Tasks retrieved successfully", extra={'extra_data': {
            'task_count': len(tasks)
        }})
        return render_template('index.html', tasks=tasks)
    except Exception as e:
        logger.error("Error fetching tasks", extra={'extra_data': {
            'error': str(e)
        }})
        return f"Error: {e}", 500

@app.route('/add', methods=['POST'])
def add_task():
    """Añadir nueva tarea"""
    try:
        title = request.form.get('title')
        description = request.form.get('description', '')
        
        logger.info("Adding new task", extra={'extra_data': {
            'title': title,
            'description_length': len(description) if description else 0
        }})
        
        connection = get_db_connection()
        cursor = connection.cursor()
        cursor.execute(
            "INSERT INTO tasks (title, description) VALUES (%s, %s)",
            (title, description)
        )
        task_id = cursor.lastrowid
        connection.commit()
        cursor.close()
        connection.close()
        
        logger.info("Task added successfully", extra={'extra_data': {
            'task_id': task_id,
            'title': title
        }})
        return redirect('/')
    except Exception as e:
        logger.error("Error adding task", extra={'extra_data': {
            'error': str(e),
            'title': title if 'title' in locals() else 'unknown'
        }})
        return f"Error: {e}", 500

@app.route('/delete/<int:task_id>')
def delete_task(task_id):
    """Eliminar tarea"""
    try:
        logger.info("Deleting task", extra={'extra_data': {
            'task_id': task_id
        }})
        
        connection = get_db_connection()
        cursor = connection.cursor()
        cursor.execute("DELETE FROM tasks WHERE id = %s", (task_id,))
        connection.commit()
        cursor.close()
        connection.close()
        
        logger.info("Task deleted successfully", extra={'extra_data': {
            'task_id': task_id
        }})
        return redirect('/')
    except Exception as e:
        logger.error("Error deleting task", extra={'extra_data': {
            'task_id': task_id,
            'error': str(e)
        }})
        return f"Error: {e}", 500

@app.route('/toggle/<int:task_id>')
def toggle_task(task_id):
    """Marcar tarea como completada/pendiente"""
    try:
        logger.info("Toggling task status", extra={'extra_data': {
            'task_id': task_id
        }})
        
        connection = get_db_connection()
        cursor = connection.cursor()
        cursor.execute(
            "UPDATE tasks SET completed = NOT completed WHERE id = %s",
            (task_id,)
        )
        connection.commit()
        cursor.close()
        connection.close()
        
        logger.info("Task status toggled successfully", extra={'extra_data': {
            'task_id': task_id
        }})
        return redirect('/')
    except Exception as e:
        logger.error("Error toggling task", extra={'extra_data': {
            'task_id': task_id,
            'error': str(e)
        }})
        return f"Error: {e}", 500

@app.route('/health')
def health():
    """Endpoint de salud para Kubernetes"""
    try:
        connection = get_db_connection()
        connection.close()
        logger.debug("Health check passed")
        return jsonify({"status": "healthy", "database": "connected"}), 200
    except Exception as e:
        logger.error("Health check failed", extra={'extra_data': {
            'error': str(e)
        }})
        return jsonify({"status": "unhealthy", "error": str(e)}), 503

if __name__ == '__main__':
    # Inicializar base de datos al arrancar
    logger.info("Starting TaskManager application")
    init_db()
    # Ejecutar aplicación
    logger.info("Application is ready to accept requests", extra={'extra_data': {
        'host': '0.0.0.0',
        'port': 5000
    }})
    app.run(host='0.0.0.0', port=5000, debug=True)