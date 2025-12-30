# Guía Rápida - ELK Stack

**Autores:** Manuel Botella, Carlos Gomez, Diego Rodriguez, Hugo Langenaeken, David Gonzalez

## Qué hay desplegado

- Elasticsearch - guardando logs
- Kibana - para ver los logs
- Filebeat - recogiendo logs de los pods
- TaskManager - la app con logs en JSON
- MySQL - base de datos

## Acceder

```
Kibana:      http://localhost:5601
TaskManager: http://localhost:30080
```

## Configurar Kibana (5 minutos)

### 1. Crear el patrón de índice
1. Abre http://localhost:5601
2. Ve al menú (☰) → Management → Stack Management
3. Kibana → Data Views
4. Create data view
5. Nombre: `filebeat-*`
6. Timestamp: `@timestamp`
7. Save

### 2. Ver los logs
1. Menú (☰) → Analytics → Discover
2. Selecciona `filebeat-*`
3. Ajusta el rango de tiempo (arriba a la derecha)
4. Ya puedes ver los logs

## Búsquedas útiles

Buscar solo errores:
```
json.level: ERROR
```

Buscar logs de la app:
```
kubernetes.labels.app: taskmanager
```

Buscar por función:
```
json.function: "add_task"
```
```
json.message: "Database connection"
```

---

## 📊 CREAR TU PRIMER DASHBOARD
Ver logs de conexión a BD:
```
json.message: *Database*
```

## Crear visualizaciones

### Gráfico de tarta - Logs por nivel
1. Analytics → Visualize → Create
2. Tipo: Pie
3. Index: filebeat-*
4. Slice by: `json.level.keyword`
5. Filtro: `kubernetes.labels.app: taskmanager`
6. Guardar

### Línea temporal
1. Create → Line
2. X-axis: @timestamp
3. Y-axis: Count
4. Break down: `json.level.keyword`
5. Guardar

## Campos importantes en los logs

| Campo | Qué es | Ejemplo |
|-------|--------|---------|
| `@timestamp` | Cuándo pasó | 2025-12-29 22:00:00 |
| `json.level` | Tipo | INFO, ERROR, WARNING |
| `json.message` | Mensaje | "Task added successfully" |
| `json.function` | Función | add_task, delete_task |
| `kubernetes.pod.name` | Qué pod | taskmanager-app-xyz |

## Comandos útiles

Ver estado:
```bash
kubectl get pods -n cloudedu
```

Ver logs en tiempo real:
```bash
kubectl logs -n cloudedu -l app=taskmanager --follow
```

Ver índices de Elasticsearch:
```bash
kubectl exec -n cloudedu deploy/elasticsearch -- curl 'http://localhost:9200/_cat/indices?v'
```

## Si algo no funciona

**No veo logs en Kibana:**
1. Verifica que Filebeat está corriendo: `kubectl get pods -n cloudedu`
2. Ve logs de Filebeat: `kubectl logs -n cloudedu -l app=filebeat`

**Los logs no están en JSON:**
Verifica la imagen: `kubectl describe pod -n cloudedu -l app=taskmanager | findstr Image`

**Kibana no carga:**
```bash
kubectl logs -n cloudedu -l app=kibana --tail=100
kubectl rollout restart deployment/kibana -n cloudedu
```

---

Más info en: [docs/ELK-LOGGING-GUIDE.md](docs/ELK-LOGGING-GUIDE.md)
