# ELK Stack Integration - TaskManager Application

## Overview

Este documento describe la integración del stack ELK (Elasticsearch, Logstash, Kibana) en la aplicación TaskManager para centralizar y visualizar los logs de los pods de Kubernetes.

## Componentes Implementados

### 1. **Elasticsearch**
- **Imagen**: `docker.elastic.co/elasticsearch/elasticsearch:8.11.0`
- **Puerto**: 9200 (API), 9300 (Transport)
- **Almacenamiento**: EmptyDir (para desarrollo; reemplazar con PersistentVolumeClaim en producción)
- **Configuración**: Single-node cluster, sin seguridad habilitada (cambiar en producción)
- **Recursos**: 512Mi RAM solicitado, 1Gi límite

### 2. **Logstash**
- **Imagen**: `docker.elastic.co/logstash/logstash:8.11.0`
- **Puertos**: 5000 (TCP/UDP para logs)
- **Función**: Procesa y enriquece los logs JSON desde la aplicación
- **Configuración**: 
  - Input: TCP/UDP en puerto 5000 (codec JSON)
  - Filter: Parsing, enriquecimiento de metadatos
  - Output: Elasticsearch e índices diarios

### 3. **Kibana**
- **Imagen**: `docker.elastic.co/kibana/kibana:8.11.0`
- **Puerto**: 5601 (NodePort: 30601)
- **Función**: Interfaz web para explorar y visualizar logs
- **Acceso**: http://localhost:30601 (en Minikube)

### 4. **Filebeat**
- **Imagen**: `docker.elastic.co/beats/filebeat:8.11.0`
- **Tipo**: DaemonSet (se ejecuta en todos los nodos)
- **Función**: Recolecta logs de los contenedores Docker
- **Configuración**: 
  - Monitorea `/var/lib/docker/containers/*/*.log`
  - Añade metadatos de Kubernetes
  - Envía a Elasticsearch directamente

### 5. **Aplicación Flask mejorada**
- **Logging**: Implementado logging estructurado en JSON
- **Librería**: `python-json-logger==2.0.7`
- **Niveles**: INFO, ERROR, CRITICAL
- **Campos**: timestamp, level, message, custom fields (task_id, error_code, etc.)

## Flujo de Logs

```
┌─────────────────┐
│  Flask App      │
│  (app.py)       │  ← Genera logs JSON a stdout
└────────┬────────┘
         │
         ├─────────────────────────────┐
         │                             │
         v                             v
    ┌─────────┐                  ┌──────────┐
    │ Filebeat│                  │  Logstash│
    │(DaemonSet)                 │(Deployment)
    └────┬────┘                  └────┬─────┘
         │  Recolecta del FS      │  TCP/UDP
         │  Docker containers    │  Input
         │                       │
         └───────────┬───────────┘
                     │
                     v
          ┌──────────────────────┐
          │   Elasticsearch      │
          │   (Indexing)         │
          └──────────┬───────────┘
                     │
                     v
          ┌──────────────────────┐
          │      Kibana          │
          │   (Visualization)    │
          └──────────────────────┘
```

## Índices en Elasticsearch

- **logs-YYYY.MM.dd**: Logs procesados por Logstash desde la aplicación
- **filebeat-YYYY.MM.dd**: Logs recolectados por Filebeat desde contenedores

## Configuración de Kibana

### 1. Crear Index Pattern

```
1. Acceder a Kibana: http://localhost:30601
2. Stack Management → Index Patterns
3. Crear nuevo patrón: "logs-*"
4. Time Field: "@timestamp"
```

### 2. Explorar Logs (Discover)

```
Kibana → Discover → Seleccionar "logs-*"
```

### 3. Crear Visualizaciones

Ejemplos de búsquedas útiles:

**Logs por nivel:**
```json
{
  "aggs": {
    "group_by_level": {
      "terms": {
        "field": "level.keyword"
      }
    }
  }
}
```

**Logs de errores en la aplicación:**
```
level: "ERROR"
```

**Logs de conexión a BD:**
```
message: "Database connection*"
```

**Logs por endpoint:**
```
GET: "GET*"
POST: "POST*"
DELETE: "DELETE*"
```

## Logs Generados por la Aplicación

### Inicialización
```json
{
  "@timestamp": "2025-12-29T10:00:00Z",
  "message": "Database initialized successfully",
  "level": "INFO"
}
```

### Conexiones
```json
{
  "@timestamp": "2025-12-29T10:00:05Z",
  "message": "Database connection successful",
  "level": "INFO",
  "attempt": 1
}
```

### Errores
```json
{
  "@timestamp": "2025-12-29T10:00:10Z",
  "message": "Database connection failed",
  "level": "ERROR",
  "attempt": 1,
  "max_retries": 5,
  "error": "Access denied for user 'root'@'mysql-service'",
  "error_code": 1045
}
```

### Operaciones
```json
{
  "@timestamp": "2025-12-29T10:00:15Z",
  "message": "GET / - Fetching all tasks",
  "level": "INFO"
}

{
  "@timestamp": "2025-12-29T10:00:16Z",
  "message": "GET / - Tasks fetched successfully",
  "level": "INFO",
  "count": 5
}
```

## Despliegue

### Paso 1: Ejecutar el script de despliegue

```powershell
.\deploy.ps1
```

El script despliegará automáticamente:
1. Namespace `cloudedu`
2. MySQL
3. Aplicación Flask
4. **ELK Stack (Elasticsearch, Logstash, Kibana, Filebeat)**

### Paso 2: Verificar despliegue

```bash
# Ver pods
kubectl get pods -n cloudedu

# Ver servicios
kubectl get svc -n cloudedu

# Logs de Elasticsearch
kubectl logs -n cloudedu deployment/elasticsearch

# Logs de Kibana
kubectl logs -n cloudedu deployment/kibana

# Logs de Logstash
kubectl logs -n cloudedu deployment/logstash

# Logs de Filebeat
kubectl logs -n cloudedu ds/filebeat
```

### Paso 3: Acceder a Kibana

- URL: `http://localhost:30601`
- No requiere autenticación (configuración de desarrollo)

## Troubleshooting

### Elasticsearch no inicia
```bash
# Verificar logs
kubectl logs -n cloudedu deployment/elasticsearch

# Aumentar memoria
kubectl edit deployment elasticsearch -n cloudedu
# Cambiar: ES_JAVA_OPTS: "-Xms1Gi -Xmx1Gi"
```

### Kibana no conecta con Elasticsearch
```bash
# Verificar conectividad
kubectl exec -n cloudedu deployment/kibana -- curl -v http://elasticsearch:9200

# Verificar servicio
kubectl get svc elasticsearch -n cloudedu
```

### No hay logs en Kibana
```bash
# Verificar que Filebeat está recolectando
kubectl logs -n cloudedu ds/filebeat | head -20

# Verificar índices en Elasticsearch
kubectl exec -n cloudedu deployment/elasticsearch -- curl -s http://localhost:9200/_cat/indices

# Verificar que la app está generando logs
kubectl logs -n cloudedu deployment/taskmanager-app
```

### Logstash no procesa logs
```bash
# Verificar logs de Logstash
kubectl logs -n cloudedu deployment/logstash

# Probar envío manual de logs
kubectl exec -n cloudedu deployment/logstash -- \
  echo '{"message":"test","level":"INFO"}' | \
  nc -u localhost 5000
```

## Configuración en Producción

Para una configuración de producción, implementar:

### Seguridad
```yaml
xpack.security.enabled: true
xpack.security.authc.api_key.enabled: true
```

### Almacenamiento Persistente
```yaml
volumeClaimTemplates:
- metadata:
    name: data
  spec:
    accessModes: [ "ReadWriteOnce" ]
    resources:
      requests:
        storage: 10Gi
```

### Replicación
```yaml
replicas: 3  # Elasticsearch
- cluster.routing.allocation.awareness.attributes: topology.kubernetes.io/zone
```

### Retention
```yaml
# En Elasticsearch
curator:
  image: bobrik/curator:latest
  schedule: "0 2 * * *"  # Ejecutar diariamente a las 2 AM
```

## Búsquedas KQL útiles en Kibana

```
# Errores en los últimos 15 minutos
level: "ERROR" and @timestamp > now-15m

# Errores de conexión a BD
message: "*Database connection*" and level: "ERROR"

# Solicitudes POST
message: "POST*"

# Logs de inicialización
message: "Database initialized*"

# Pods específicos
kubernetes.pod.name: "taskmanager-app-*"

# Por nivel en rango horario
level: ("ERROR" or "CRITICAL") and @timestamp > "2025-12-29T09:00:00Z" and @timestamp < "2025-12-29T12:00:00Z"
```

## Dashboards Recomendados

1. **TaskManager Overview**: Resumen general de logs
2. **Database Activity**: Conexiones y operaciones de BD
3. **Errors & Issues**: Concentración en errores y warnings
4. **Performance**: Latencias y tiempos de respuesta
5. **Pod Health**: Estado y logs de los pods

## Referencias

- [Elasticsearch Documentation](https://www.elastic.co/guide/en/elasticsearch/reference/current/index.html)
- [Kibana User Guide](https://www.elastic.co/guide/en/kibana/current/index.html)
- [Logstash Documentation](https://www.elastic.co/guide/en/logstash/current/index.html)
- [Filebeat Documentation](https://www.elastic.co/guide/en/beats/filebeat/current/index.html)
- [Python JSON Logger](https://github.com/mber/python-json-logger)
