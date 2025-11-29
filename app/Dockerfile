# Imagen base oficial de Python
FROM python:3.11-slim

# Metadata
LABEL maintainer="cloudedu@example.com"
LABEL description="TaskManager CloudEdu - Flask Application"
LABEL version="1.0"

# Establecer directorio de trabajo
WORKDIR /app

# Instalar dependencias del sistema necesarias para MySQL
RUN apt-get update && apt-get install -y \
    default-libmysqlclient-dev \
    build-essential \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

# Copiar archivo de dependencias
COPY requirements.txt .

# Instalar dependencias de Python
RUN pip install --no-cache-dir -r requirements.txt

# Copiar el código de la aplicación
COPY . .

# Crear usuario no-root por seguridad
RUN useradd -m -u 1000 appuser && chown -R appuser:appuser /app
USER appuser

# Exponer puerto 5000
EXPOSE 5000

# Variables de entorno por defecto (se sobreescriben en Kubernetes)
ENV DB_HOST=mysql-service
ENV DB_USER=root
ENV DB_PASSWORD=rootpassword
ENV DB_NAME=taskdb
ENV FLASK_APP=app.py

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD python -c "import requests; requests.get('http://localhost:5000/health')" || exit 1

# Comando para ejecutar la aplicación
CMD ["python", "app.py"]