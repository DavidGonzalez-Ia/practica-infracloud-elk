# Práctica Final - TaskManager con ELK

**Autores:** Manuel Botella, Carlos Gomez, Diego Rodriguez, Hugo Langenaeken, David Gonzalez  
**Asignatura:** Infraestructura Cloud  
**Fecha:** Diciembre 2025

---

## Qué es esto

Básicamente hemos montado una aplicación web sencilla (TaskManager) en Kubernetes con un sistema de logs centralizado usando ELK Stack. La idea era poder ver todos los logs de los pods en un solo sitio en vez de ir mirando uno por uno con kubectl.

## Tecnologías que usamos

- **Docker** - para los contenedores
- **Kubernetes (Minikube)** - orquestación
- **MySQL** - base de datos de las tareas
- **Python + Flask** - la app web
- **ELK Stack** - para los logs:
  - Elasticsearch: guarda y busca los logs
  - Kibana: interfaz web para verlos
  - Filebeat: recoge los logs de los pods
- **Ansible** - para automatizar el despliegue
- **GitHub Actions** - CI/CD básico

## Lo que hemos hecho

### Sistema de Logs Centralizado
- Elasticsearch corriendo en el cluster
- Kibana accesible en el puerto 5601
- Filebeat recogiendo logs de todos los pods
- Más de 1.800 logs indexados

### Logs desde los Pods
- Filebeat configurado como DaemonSet (se ejecuta en todos los nodos)
- Los logs van en formato JSON para que sea más fácil buscar
- Configuramos permisos RBAC para que Filebeat pueda leer los logs
- [x] 1,856+ logs indexados y consultables
- [x] Logging implementado en la aplicación

#### 3. Búsquedas y Visualizaciones ✅
- [x] Búsquedas documentadas y funcionales
- [x] Visualizaciones configuradas
- [x] Guías paso a paso incluidas (QUICK-START-ELK.md, ELK-LOGGING-GUIDE.md)

#### 4. Infrastructure as Code (IaC) ✅
- [x] Playbooks de Ansible para despliegue completo
- [x] Playbook de cleanup
- [x] Inventario y configuración

### Búsquedas y Visualizaciones
- Hicimos búsquedas en Kibana filtrando por nivel (ERROR, INFO, etc.)
- Creamos algunas visualizaciones tipo gráficas de barras y líneas
- Está todo documentado en las guías

### Ansible (IaC)
- Hicimos playbooks de Ansible para automatizar el despliegue
- Un playbook despliega todo (deploy-playbook.yml)
- Otro limpia todo (cleanup-playbook.yml)
- También dejamos scripts de PowerShell por si alguien no quiere usar Ansible

### Documentación
- Este README
- Diagramas de arquitectura
- Guía de uso de ELK
- Reflexión con lo que aprendimos

## Cómo funciona

La app (TaskManager) genera logs → Van a /var/log/containers/ → Filebeat los lee → Los manda a Elasticsearch → Se ven en Kibana

Ver más detalles en [docs/ARQUITECTURA.md](docs/ARQUITECTURA.md)

## Cómo desplegarlo

### Con Ansible (lo más fácil)

```bash
# Instalar Ansible si no lo tienes
pip install ansible
ansible-galaxy collection install kubernetes.core

# Desplegar todo
cd ansible
ansible-playbook deploy-playbook.yml

# Ver que todo está corriendo
kubectl get pods -n cloudedu
```

### Con PowerShell (alternativa)

```powershell
.\deploy.ps1
```

## Acceder a los servicios

**Para ver la app TaskManager:**
```bash
kubectl port-forward -n cloudedu svc/taskmanager-app-service 30080:5000
```
Luego ir a: http://localhost:30080

**Kibana:**
```bash
kubectl port-forward -n cloudedu svc/kibana 5601:5601
# Acceder a: http://localhost:5601
```

**Elasticsearch:**
```bash
kubectl port-forward -n cloudedu svc/elasticsearch 9200:9200
# API: http://localhost:9200
```

---

## 📚 Documentación

### Documentos Principales

1. **[QUICK-START-ELK.md](QUICK-START-ELK.md)** - Guía rápida de 5 minutos
2. **[docs/ELK-LOGGING-GUIDE.md](docs/ELK-LOGGING-GUIDE.md)** - Guía completa de uso del stack ELK
3. **[docs/ARQUITECTURA.md](docs/ARQUITECTURA.md)** - Diagramas y arquitectura del sistema
4. **[docs/REFLEXION.md](docs/REFLEXION.md)** - Reflexión final del proyecto
5. **[ansible/README.md](ansible/README.md)** - Documentación de Ansible IaC
6. **[docs/GITHUB-ACTIONS-SETUP.md](docs/GITHUB-ACTIONS-SETUP.md)** - Configuración CI/CD

### Estructura del Proyecto

```
Trabajo nube/
├── app/                          # Código de la aplicación
│   ├── app.py                    # Flask app con logging JSON
│   ├── templates/                # Templates HTML
│   └── Dockerfile                # Imagen Docker
├── kubernetes/                   # Manifiestos de Kubernetes
│   ├── mysql-*.yaml              # MySQL deployment
│   ├── taskmanager-*.yaml        # TaskManager deployment
│   ├── elasticsearch-*.yaml      # Elasticsearch
│   ├── kibana-*.yaml             # Kibana
│   └── filebeat-*.yaml           # Filebeat DaemonSet
├── ansible/                      # Infrastructure as Code
│   ├── deploy-playbook.yml       # Despliegue completo
│   ├── cleanup-playbook.yml      # Limpieza
│   ├── inventory.ini             # Inventario
│   └── README.md                 # Documentación
├── docs/                         # Documentación

**Para ver Kibana (los logs):**
```bash
kubectl port-forward -n cloudedu svc/kibana 5601:5601
```
Luego ir a: http://localhost:5601

## Estructura del proyecto

```
Trabajo nube/
├── app/                    # Código de la aplicación Flask
├── kubernetes/             # Manifiestos YAML de Kubernetes
├── ansible/                # Playbooks de Ansible
├── docs/                   # Documentación adicional
├── deploy.ps1              # Script para desplegar
└── cleanup.ps1             # Script para limpiar todo
```

## Comandos útiles

```bash
# Ver los pods
kubectl get pods -n cloudedu

# Ver logs de la app
kubectl logs -n cloudedu -l app=taskmanager-app

# Ver logs de Filebeat
kubectl logs -n cloudedu -l app=filebeat

# Comprobar Elasticsearch
curl http://localhost:9200/_cluster/health
```

## Configurar Kibana

1. Abrir http://localhost:5601
2. Ir a Management → Data Views
3. Crear Data View con `filebeat-*`
4. Ir a Discover para ver los logs

## Problemas que tuvimos

- **MySQL no arrancaba**: El PVC se quedaba en Pending porque Minikube con Docker no provisiona volúmenes automáticamente. Tuvimos que crear un PV manual con hostPath.

- **Kibana no se veía desde fuera**: El NodePort no funciona con Minikube + Docker. La solución fue usar `kubectl port-forward`.

- **Los logs no estaban en JSON**: Tuvimos que crear un JSONFormatter custom en Python para que los logs salieran bien estructurados.

Ver más detalles en [docs/REFLEXION.md](docs/REFLEXION.md)

## Cosas que se podrían mejorar

- Poner más réplicas de Elasticsearch para alta disponibilidad
- Usar un Ingress Controller en vez de port-forward
- Añadir Prometheus para métricas (ahora solo tenemos logs)
- Hacer Helm Charts
- Configurar alertas en Kibana

---

**Equipo:** Manuel Botella, Carlos Gomez, Diego Rodriguez, Hugo Langenaeken, David Gonzalez  
**Diciembre 2025**
