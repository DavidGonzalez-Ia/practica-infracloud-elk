# TaskManager CloudEdu - Kubernetes Deployment with ELK Stack

Aplicación TaskManager desplegada en Kubernetes con integración del stack ELK (Elasticsearch, Logstash, Kibana) para centralizar y visualizar logs.

## 📋 Tabla de Contenidos

- [Requisitos Previos](#requisitos-previos)
- [Estructura del Proyecto](#estructura-del-proyecto)
- [Despliegue Local (Minikube)](#despliegue-local-minikube)
- [Acceder a la Aplicación](#acceder-a-la-aplicación)
- [Sistema de Logs ELK](#sistema-de-logs-elk)
- [GitHub Actions CI/CD](#github-actions-cicd)
- [Troubleshooting](#troubleshooting)

## 🔧 Requisitos Previos

### Software Requerido

- **Docker Desktop** 4.0+
- **Kubernetes/Minikube** 1.24+
- **kubectl** 1.24+
- **PowerShell** 7.0+ (para scripts de despliegue)
- **Git** 2.30+

### Recursos Mínimos (Minikube)

```bash
minikube start --cpus=4 --memory=6144 --disk-size=30g
```

## 📁 Estructura del Proyecto

```
Trabajo nube/
├── app/                                    # Código de la aplicación Flask
│   ├── app.py                             # Aplicación principal con logging JSON
│   ├── requirements.txt                    # Dependencias Python (incluye python-json-logger)
│   ├── Dockerfile                         # Imagen Docker
│   └── templates/                         # Plantillas HTML
├── kubernetes/                             # Manifiestos de Kubernetes
│   ├── namespace.yaml                     # Namespace 'cloudedu'
│   ├── app-deployment.yaml                # Deployment de Flask
│   ├── app-service.yaml                   # Service de Flask
│   ├── mysql-deployment.yaml              # Deployment de MySQL
│   ├── mysql-service.yaml                 # Service de MySQL
│   ├── mysql-pv.yaml                      # Persistent Volume
│   ├── rbac.yaml                          # Roles y permisos
│   ├── elasticsearch-deployment.yaml      # Elasticsearch
│   ├── kibana-deployment.yaml             # Kibana
│   ├── logstash-deployment.yaml           # Logstash
│   ├── filebeat-deployment.yaml           # Filebeat (DaemonSet)
│   └── elk-config.yaml                    # Configuración ELK
├── .github/
│   └── workflows/
│       └── ci-cd-elk.yml                  # GitHub Actions workflow
├── ansible/                               # Playbooks de Ansible (opcional)
├── docs/
│   ├── README.md                          # Este archivo
│   └── ELK-INTEGRATION.md                 # Documentación detallada de ELK
├── deploy.ps1                             # Script de despliegue PowerShell
├── cleanup.ps1                            # Script para limpiar recursos
└── verificar-proyecto.ps1                 # Script de verificación
```

## 🚀 Despliegue Local (Minikube)

### Paso 1: Iniciar Minikube

```powershell
# Iniciar Minikube con recursos suficientes
minikube start --cpus=4 --memory=6144 --disk-size=30g --vm-driver=hyperv

# Verificar que está corriendo
minikube status
```

### Paso 2: Ejecutar el Script de Despliegue

```powershell
# Navegar al directorio del proyecto
cd "C:\Users\david\Documents\Trabajo nube"

# Ejecutar el script (despliega automáticamente ELK Stack)
.\deploy.ps1
```

El script realizará automáticamente:
- ✅ Validación de herramientas (Docker, kubectl)
- ✅ Construcción de la imagen Docker
- ✅ Carga de la imagen en Minikube
- ✅ Creación del namespace
- ✅ Despliegue de MySQL
- ✅ Despliegue de la aplicación Flask
- ✅ Despliegue del stack ELK completo (Elasticsearch, Logstash, Kibana, Filebeat)

### Paso 3: Verificar el Despliegue

```powershell
# Ver estado de los pods
kubectl get pods -n cloudedu

# Ver servicios
kubectl get svc -n cloudedu

# Ver logs de la aplicación
kubectl logs -n cloudedu deployment/taskmanager-app

# Seguir logs en tiempo real
kubectl logs -f deployment/taskmanager-app -n cloudedu
```

## 📱 Acceder a la Aplicación

### TaskManager Web App

```
URL: http://localhost:30080
```

**Funcionalidades:**
- Crear tareas
- Marcar tareas como completadas
- Eliminar tareas
- Ver todas las tareas

### Health Check

```bash
curl http://localhost:30080/health
```

Respuesta:
```json
{
  "status": "healthy",
  "database": "connected"
}
```

## 📊 Sistema de Logs ELK

### Kibana Dashboard

```
URL: http://localhost:30601
```

#### Primer Acceso

1. **Crear Index Pattern**:
   - Stack Management → Index Patterns
   - Crear patrón `logs-*`
   - Time Field: `@timestamp`

2. **Ver Logs**:
   - Discover → Seleccionar `logs-*`
   - Ver logs en tiempo real

#### Búsquedas Útiles (KQL)

```
# Todos los errores
level: "ERROR"

# Errores en los últimos 15 minutos
level: "ERROR" and @timestamp > now-15m

# Errores de base de datos
message: "*Database*" and level: "ERROR"

# Operaciones POST
message: "POST*"

# Por aplicación
application: "taskmanager"

# Por pod específico
kubernetes.pod.name: "taskmanager-app-*"
```

#### Crear Visualizaciones

**Ejemplo 1: Pie chart de niveles de log**

1. Visualizations → Create
2. Pie chart
3. Metrics: Count
4. Buckets: Terms field=level.keyword
5. Save

**Ejemplo 2: Timeline de logs**

1. Visualizations → Create
2. Area chart
3. Metrics: Count
4. X-axis: Date histogram @timestamp
5. Save

### Componentes ELK

| Componente | Puerto | Imagen |
|-----------|--------|--------|
| Elasticsearch | 9200 | `docker.elastic.co/elasticsearch/elasticsearch:8.11.0` |
| Kibana | 30601 | `docker.elastic.co/kibana/kibana:8.11.0` |
| Logstash | 5000 | `docker.elastic.co/logstash/logstash:8.11.0` |
| Filebeat | - (DaemonSet) | `docker.elastic.co/beats/filebeat:8.11.0` |

### Flujo de Logs

```
Flask App (logs JSON a stdout)
    ↓
Filebeat (recolecta del Docker daemon)
    ↓
Elasticsearch (indexa logs)
    ↓
Kibana (visualiza)
```

## 🔄 GitHub Actions CI/CD

El workflow automatiza:

### 1. Code Quality Checks
- Python linting (flake8)
- Formateo de código (black)

### 2. Build
- Construcción de imagen Docker
- Push a GitHub Container Registry (GHCR)
- Caching de capas

### 3. Security
- Análisis de vulnerabilidades (bandit)
- Verificación de dependencias (safety)

### 4. Reports
- Tests unitarios
- Cobertura de código
- Upload a Codecov

### Configuración de Secrets

En GitHub → Settings → Secrets and variables → Actions:

```
No se requieren secrets adicionales si usas GITHUB_TOKEN
```

### Ejecutar Workflow

El workflow se ejecuta automáticamente en:
- Push a `main` o `develop`
- Pull request a `main`

Ver resultados: GitHub → Actions tab

## 📝 Tipos de Logs Generados

### 1. Logs de Inicialización
```json
{
  "@timestamp": "2025-12-29T10:00:00Z",
  "message": "Database initialized successfully",
  "level": "INFO"
}
```

### 2. Logs de Conexión
```json
{
  "@timestamp": "2025-12-29T10:00:05Z",
  "message": "Database connection successful",
  "level": "INFO",
  "attempt": 1
}
```

### 3. Logs de Operaciones
```json
{
  "@timestamp": "2025-12-29T10:01:00Z",
  "message": "GET / - Tasks fetched successfully",
  "level": "INFO",
  "count": 5
}
```

### 4. Logs de Errores
```json
{
  "@timestamp": "2025-12-29T10:02:00Z",
  "message": "Database connection failed",
  "level": "ERROR",
  "error": "Access denied",
  "error_code": 1045
}
```

## 🔧 Comandos Útiles

### Minikube

```bash
# Obtener IP de Minikube
minikube ip

# Abrir túnel para servicios (en otra terminal)
minikube tunnel

# Dashboard de Minikube
minikube dashboard

# Detener Minikube
minikube stop

# Eliminar Minikube
minikube delete
```

### Kubernetes

```bash
# Ver pods en tiempo real
kubectl get pods -n cloudedu -w

# Obtener descripción de pod
kubectl describe pod <pod-name> -n cloudedu

# Ver logs de un contenedor
kubectl logs deployment/taskmanager-app -n cloudedu

# Ejecutar comando en un pod
kubectl exec -it deployment/taskmanager-app -n cloudedu -- /bin/bash

# Obtener eventos del namespace
kubectl get events -n cloudedu

# Eliminar todos los recursos del namespace
kubectl delete namespace cloudedu
```

### Docker

```bash
# Construir imagen manualmente
docker build -t cloudedu-taskmanager:v1 ./app

# Listar imágenes
docker images cloudedu*

# Ver logs de un contenedor
docker logs <container-id>
```

### Elasticsearch

```bash
# Verificar estado del cluster
kubectl exec -n cloudedu deployment/elasticsearch -- \
  curl -s http://localhost:9200/_cluster/health | jq .

# Listar índices
kubectl exec -n cloudedu deployment/elasticsearch -- \
  curl -s http://localhost:9200/_cat/indices | head -20

# Obtener documentos de un índice
kubectl exec -n cloudedu deployment/elasticsearch -- \
  curl -s "http://localhost:9200/logs-*/_search?pretty" | jq .hits.hits
```

## 🐛 Troubleshooting

### Pod no inicia

```bash
# Ver logs detallados
kubectl describe pod <pod-name> -n cloudedu
kubectl logs <pod-name> -n cloudedu --previous

# Verificar recursos disponibles
kubectl top nodes
kubectl top pod -n cloudedu
```

### Elasticsearch no conecta

```bash
# Verificar servicio
kubectl get svc elasticsearch -n cloudedu

# Probar conectividad dentro del cluster
kubectl exec -n cloudedu deployment/kibana -- curl -v http://elasticsearch:9200

# Ver logs de Elasticsearch
kubectl logs deployment/elasticsearch -n cloudedu
```

### Kibana no muestra logs

```bash
# Verificar que hay índices
kubectl exec -n cloudedu deployment/elasticsearch -- \
  curl -s http://localhost:9200/_cat/indices

# Verificar que Filebeat está recolectando
kubectl logs -n cloudedu ds/filebeat | tail -50

# Verificar Logstash
kubectl logs -n cloudedu deployment/logstash | tail -50
```

### Base de datos sin conectar

```bash
# Ver logs de MySQL
kubectl logs deployment/mysql -n cloudedu

# Verificar PersistentVolume
kubectl get pv -n cloudedu
kubectl describe pv <pv-name>

# Ejecutar en el pod de la app
kubectl exec -it deployment/taskmanager-app -n cloudedu -- python -c \
  "import mysql.connector; conn = mysql.connector.connect(host='mysql-service', user='root', password='rootpassword'); print('Connected!')"
```

## 📚 Documentación Adicional

- [ELK Integration Details](./ELK-INTEGRATION.md) - Configuración detallada de ELK
- [Elasticsearch Docs](https://www.elastic.co/guide/en/elasticsearch/reference/current/index.html)
- [Kibana User Guide](https://www.elastic.co/guide/en/kibana/current/index.html)
- [Kubernetes Docs](https://kubernetes.io/docs/)

## 🧹 Limpiar Recursos

```powershell
# Ejecutar el script de limpieza
.\cleanup.ps1

# O manualmente
kubectl delete namespace cloudedu
minikube delete
```

## 🔐 Notas de Seguridad

⚠️ **Configuración Actual (DESARROLLO)**
- Elasticsearch sin autenticación
- Kibana sin autenticación
- MySQL con contraseña default
- Logs sin cifrado

✅ **Para Producción**
1. Habilitar XPack security en Elasticsearch
2. Configurar TLS/SSL
3. Usar secretos de Kubernetes para contraseñas
4. Implementar RBAC
5. Usar PersistentVolumes con respaldo
6. Configurar políticas de retención de logs

## 📞 Soporte

Para reportar issues o sugerencias:
1. Crear un GitHub Issue
2. Describir el problema
3. Incluir logs relevantes
4. Especificar versiones de software

## 📄 Licencia

MIT License - Ver LICENSE file

---

**Última actualización**: Diciembre 29, 2025  
**Versión**: 1.2 (con ELK Stack)
