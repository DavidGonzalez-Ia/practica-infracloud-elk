# Guía de Uso de ELK Stack - CloudEdu TaskManager

**Autores:** Manuel Botella, Carlos Gomez, Diego Rodriguez, Hugo Langenaeken, David Gonzalez

## 🎯 Descripción

Este proyecto integra un stack ELK completo para centralizar y analizar logs de la aplicación TaskManager y sus componentes.

## 📊 Componentes del Stack de Logs

### 1. **Elasticsearch** (Puerto 9200)
- Motor de búsqueda y análisis de datos
- Almacena todos los logs indexados
- Permite búsquedas rápidas y complejas

### 2. **Kibana** (Puerto 30601)
- Interfaz web para visualización de datos
- Crea dashboards y visualizaciones
- Acceso: http://localhost:30601

### 3. **Filebeat** (DaemonSet)
- Recolector ligero de logs
- Se ejecuta en cada nodo del cluster
- Envía logs automáticamente a Elasticsearch

## 🚀 Despliegue

### Opción 1: Despliegue Automatizado
```powershell
.\deploy.ps1
```

### Opción 2: Despliegue Manual
```powershell
# Namespace y configuraciones base
kubectl apply -f kubernetes/namespace.yaml
kubectl apply -f kubernetes/rbac.yaml

# MySQL (base de datos)
kubectl apply -f kubernetes/mysql-pv.yaml
kubectl apply -f kubernetes/mysql-deployment.yaml
kubectl apply -f kubernetes/mysql-service.yaml

# Aplicación TaskManager
kubectl apply -f kubernetes/app-deployment.yaml
kubectl apply -f kubernetes/app-service.yaml

# Stack ELK
kubectl apply -f kubernetes/elasticsearch-deployment.yaml
kubectl apply -f kubernetes/kibana-deployment.yaml
kubectl apply -f kubernetes/filebeat-daemonset.yaml
```

## 📝 Configuración de Kibana

### Paso 1: Acceder a Kibana
```
http://localhost:30601
```

### Paso 2: Crear Index Pattern
1. Ve a **Management** → **Stack Management** → **Index Management**
2. Espera a ver los índices: `filebeat-taskmanager-*`, `filebeat-mysql-*`
3. Ve a **Management** → **Stack Management** → **Kibana** → **Index Patterns**
4. Clic en **Create index pattern**
5. Ingresa el patrón: `filebeat-*`
6. Selecciona `@timestamp` como time field
7. Clic en **Create index pattern**

### Paso 3: Ver Logs en Discover
1. Ve a **Analytics** → **Discover**
2. Selecciona el index pattern `filebeat-*`
3. Ajusta el rango de tiempo (últimas 24 horas, última hora, etc.)
4. Ya puedes ver todos los logs en tiempo real

## 🔍 Búsquedas Útiles en Kibana

### Búsquedas Básicas (Lucene Query)

#### Todos los logs de TaskManager
```
kubernetes.labels.app: taskmanager
```

#### Solo logs de errores
```
level: ERROR AND kubernetes.labels.app: taskmanager
```

#### Logs de MySQL
```
kubernetes.labels.app: mysql
```

#### Operaciones de base de datos (CRUD)
```
function: (add_task OR delete_task OR toggle_task)
```

#### Logs de una función específica
```
function: "add_task"
```

#### Búsqueda por mensaje
```
message: "Database connection"
```

#### Combinar condiciones
```
level: (ERROR OR WARNING) AND kubernetes.labels.app: taskmanager
```

#### Logs de un pod específico
```
kubernetes.pod.name: "taskmanager-app-*"
```

### Búsquedas Avanzadas (KQL - Kibana Query Language)

#### Rango de tiempo personalizado
```
kubernetes.labels.app: "taskmanager" and @timestamp >= "now-1h"
```

#### Excluir health checks
```
kubernetes.labels.app: "taskmanager" and not function: "health"
```

## 📈 Visualizaciones Recomendadas

### 1. Distribución de Logs por Nivel (Pie Chart)
- **Tipo**: Pie Chart
- **Aggregation**: Terms on `level.keyword`
- **Filtro**: `kubernetes.labels.app: taskmanager`

### 2. Timeline de Logs (Line Chart)
- **Tipo**: Line Chart
- **X-Axis**: Date Histogram on `@timestamp`
- **Y-Axis**: Count
- **Split Series**: Terms on `level.keyword`

### 3. Top Funciones con Errores (Bar Chart)
- **Tipo**: Horizontal Bar
- **Aggregation**: Terms on `function.keyword`
- **Filtro**: `level: ERROR`
- **Size**: 10

### 4. Logs por Pod (Data Table)
- **Tipo**: Data Table
- **Aggregation**: Terms on `kubernetes.pod.name.keyword`
- **Metrics**: Count

### 5. Tasa de Errores (Gauge)
- **Tipo**: Gauge
- **Query**: `level: ERROR`
- **Metric**: Count

## 📊 Crear un Dashboard

### Dashboard Recomendado: "TaskManager Overview"

1. Ve a **Analytics** → **Dashboard**
2. Clic en **Create dashboard**
3. Añade las siguientes visualizaciones:

#### Panel 1: Métrica de Logs Totales
- **Tipo**: Metric
- **Aggregation**: Count
- **Título**: "Total de Logs"

#### Panel 2: Distribución por Nivel
- **Tipo**: Pie Chart
- **Aggregation**: Terms on `level.keyword`
- **Título**: "Logs por Severidad"

#### Panel 3: Timeline
- **Tipo**: Area Chart
- **X-Axis**: @timestamp
- **Y-Axis**: Count
- **Split**: level.keyword
- **Título**: "Logs en el Tiempo"

#### Panel 4: Top Errores
- **Tipo**: Data Table
- **Rows**: function.keyword, message.keyword
- **Filtro**: level: ERROR
- **Título**: "Principales Errores"

#### Panel 5: Actividad por Pod
- **Tipo**: Heat Map
- **X-Axis**: @timestamp
- **Y-Axis**: kubernetes.pod.name.keyword
- **Título**: "Actividad por Pod"

4. Guarda el dashboard como "TaskManager Overview"

## 🎨 Campos Importantes en los Logs

| Campo | Descripción | Ejemplo |
|-------|-------------|---------|
| `@timestamp` | Timestamp del log | 2024-01-15T10:30:45.123Z |
| `level` | Nivel de severidad | INFO, WARNING, ERROR |
| `message` | Mensaje principal del log | "Task added successfully" |
| `logger` | Nombre del logger | "taskmanager" |
| `function` | Función que generó el log | "add_task", "delete_task" |
| `module` | Módulo Python | "app" |
| `kubernetes.pod.name` | Nombre del pod | "taskmanager-app-xyz123" |
| `kubernetes.namespace` | Namespace de K8s | "cloudedu" |
| `kubernetes.labels.app` | Label de la app | "taskmanager" |
| `extra_data.*` | Datos adicionales | task_id, title, etc. |

## 🔧 Troubleshooting

### No aparecen logs en Kibana

1. **Verificar que Filebeat está corriendo**:
```powershell
kubectl get pods -n cloudedu | Select-String "filebeat"
kubectl logs -n cloudedu -l app=filebeat --tail=50
```

2. **Verificar que Elasticsearch está corriendo**:
```powershell
kubectl get pods -n cloudedu | Select-String "elasticsearch"
kubectl logs -n cloudedu -l app=elasticsearch --tail=50
```

3. **Verificar conectividad**:
```powershell
kubectl exec -n cloudedu -it <filebeat-pod> -- curl http://elasticsearch:9200/_cluster/health
```

4. **Ver índices en Elasticsearch**:
```powershell
kubectl exec -n cloudedu -it deploy/elasticsearch -- curl http://localhost:9200/_cat/indices
```

### Los logs no tienen formato JSON

Verifica que la aplicación está usando el logger correcto:
```powershell
kubectl logs -n cloudedu -l app=taskmanager --tail=20
```

Deberías ver logs en formato JSON como:
```json
{"timestamp": "2024-01-15T10:30:45.123Z", "level": "INFO", "message": "..."}
```

### Kibana no puede conectarse a Elasticsearch

```powershell
# Verificar servicio de Elasticsearch
kubectl get svc -n cloudedu elasticsearch

# Ver logs de Kibana
kubectl logs -n cloudedu -l app=kibana --tail=100
```

### Filebeat no envía logs

```powershell
# Ver configuración de Filebeat
kubectl get configmap filebeat-config -n cloudedu -o yaml

# Ver logs de Filebeat
kubectl logs -n cloudedu daemonset/filebeat --tail=100
```

## 📚 Recursos Adicionales

- [Elasticsearch Query DSL](https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl.html)
- [Kibana Query Language (KQL)](https://www.elastic.co/guide/en/kibana/current/kuery-query.html)
- [Filebeat Configuration](https://www.elastic.co/guide/en/beats/filebeat/current/configuring-howto-filebeat.html)
- [Kubernetes Logging Architecture](https://kubernetes.io/docs/concepts/cluster-administration/logging/)

## 🎯 Casos de Uso Comunes

### Monitorear errores en producción
```
level: ERROR AND kubernetes.labels.app: taskmanager
```
Crea una alerta en Kibana para notificarte cuando aparezcan errores.

### Analizar rendimiento de operaciones
```
function: add_task
```
Visualiza cuántas tareas se crean por minuto/hora.

### Debugging de un pod específico
```
kubernetes.pod.name: "taskmanager-app-abc123"
```
Rastrea todos los logs de un pod problemático.

### Auditoría de cambios
```
function: (add_task OR delete_task OR toggle_task)
```
Crea un reporte de todas las operaciones CRUD realizadas.

---

## 🎉 Siguiente Nivel: Alertas y Monitoreo

Una vez que tengas tu dashboard funcionando, puedes:

1. **Crear Alertas**: Configurar notificaciones cuando ocurran errores
2. **Exportar Dashboards**: Compartir configuraciones con tu equipo
3. **Integrar con Prometheus**: Métricas adicionales de rendimiento
4. **Añadir APM**: Application Performance Monitoring para tracing distribuido

¡Disfruta analizando tus logs! 📊✨
