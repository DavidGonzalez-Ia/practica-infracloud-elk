\# Arquitectura Técnica - CloudEdu TaskManager



\## 1. Visión General



CloudEdu TaskManager es una aplicación web cloud-native diseñada para demostrar las mejores prácticas de despliegue en Kubernetes con infraestructura como código (IaC).



\### 1.1 Principios de Diseño



\- Contenedorización: Toda la aplicación corre en contenedores Docker

\- Orquestación: Kubernetes gestiona el ciclo de vida de los contenedores

\- Automatización: IaC permite despliegues reproducibles

\- Seguridad: RBAC controla el acceso a recursos

\- Persistencia: Datos críticos se almacenan en volúmenes persistentes

\- Escalabilidad: Múltiples réplicas de la aplicación



---



\## 2. Componentes de la Aplicación



\### 2.1 Frontend/Backend (Flask)



Tecnología: Python 3.11 + Flask 3.0  

Puerto: 5000  

Réplicas: 2  



Funcionalidades:

\- Interfaz web responsive

\- API REST para tareas

\- Conexión a base de datos MySQL

\- Health checks para Kubernetes



Endpoints:

\- GET / - Página principal con lista de tareas

\- POST /add - Crear nueva tarea

\- GET /delete/<id> - Eliminar tarea

\- GET /toggle/<id> - Marcar tarea como completada/pendiente

\- GET /health - Endpoint de salud



\### 2.2 Base de Datos (MySQL)



Tecnología: MySQL 8.0  

Puerto: 3306  

Réplicas: 1  

Almacenamiento: PersistentVolume de 1Gi  



Esquema de Base de Datos:



CREATE TABLE tasks (

&nbsp;   id INT AUTO\_INCREMENT PRIMARY KEY,

&nbsp;   title VARCHAR(255) NOT NULL,

&nbsp;   description TEXT,

&nbsp;   completed BOOLEAN DEFAULT FALSE,

&nbsp;   created\_at TIMESTAMP DEFAULT CURRENT\_TIMESTAMP

);



Variables de Entorno:

\- MYSQL\_ROOT\_PASSWORD: rootpassword

\- MYSQL\_DATABASE: taskdb

\- MYSQL\_USER: appuser

\- MYSQL\_PASSWORD: apppassword



---



\## 3. Infraestructura de Kubernetes



\### 3.1 Namespace



Nombre: cloudedu

Propósito: Aislamiento lógico de recursos

Etiquetas:

&nbsp; - environment: production

&nbsp; - project: taskmanager



\### 3.2 Deployments



\#### MySQL Deployment



Nombre: mysql

Réplicas: 1

Estrategia: Recreate

Recursos:

&nbsp; Requests:

&nbsp;   Memory: 256Mi

&nbsp;   CPU: 250m

&nbsp; Limits:

&nbsp;   Memory: 512Mi

&nbsp;   CPU: 500m

Probes:

&nbsp; Liveness: mysqladmin ping (30s initial, 10s period)

&nbsp; Readiness: mysqladmin ping (10s initial, 5s period)



\#### TaskManager Deployment



Nombre: taskmanager-app

Réplicas: 2

Service Account: taskmanager-sa

Recursos:

&nbsp; Requests:

&nbsp;   Memory: 128Mi

&nbsp;   CPU: 100m

&nbsp; Limits:

&nbsp;   Memory: 256Mi

&nbsp;   CPU: 200m

Probes:

&nbsp; Liveness: HTTP GET /health (30s initial, 10s period)

&nbsp; Readiness: HTTP GET /health (10s initial, 5s period)



\### 3.3 Services



\#### MySQL Service (ClusterIP)



Nombre: mysql-service

Tipo: ClusterIP (interno)

Puerto: 3306

Selector: app=mysql



Este servicio solo es accesible dentro del cluster.



\#### TaskManager Service (NodePort)



Nombre: taskmanager-service

Tipo: NodePort (expuesto)

Puerto interno: 5000

NodePort: 30080

Selector: app=taskmanager



Este servicio es accesible desde localhost:30080.



\### 3.4 Almacenamiento Persistente



\#### PersistentVolume



Nombre: mysql-pv

Capacidad: 1Gi

Access Mode: ReadWriteOnce

Storage Class: manual

Host Path: /data/mysql

Tipo: DirectoryOrCreate



\#### PersistentVolumeClaim



Nombre: mysql-pvc

Namespace: cloudedu

Storage Request: 1Gi

Access Mode: ReadWriteOnce



Montaje: /var/lib/mysql en el contenedor MySQL



---



\## 4. Seguridad (RBAC)



\### 4.1 Service Account



Nombre: taskmanager-sa

Namespace: cloudedu

Propósito: Identidad para los pods de la aplicación



\### 4.2 Role (Namespace)



Nombre: taskmanager-role

Tipo: Role

Permisos:

&nbsp; - ConfigMaps: get, list

&nbsp; - Secrets: get, list

&nbsp; - Pods: get, list



\### 4.3 RoleBinding



Nombre: taskmanager-rolebinding

Asocia: taskmanager-role con taskmanager-sa



\### 4.4 ClusterRoles



\#### cloudedu-admin



Permisos de Administrador:

\- Namespaces: get, list

\- Deployments: get, list, create, update, delete

\- ReplicaSets: get, list, create, update, delete

\- Services: get, list, create, update, delete

\- Pods: get, list, create, update, delete

\- PersistentVolumeClaims: get, list, create, update, delete



\#### cloudedu-developer



Permisos de Solo Lectura:

\- Namespaces: get, list

\- Deployments: get, list

\- ReplicaSets: get, list

\- Services: get, list

\- Pods: get, list

\- Logs: get, list



\### 4.5 Modelo de Seguridad



&nbsp;    Usuario Administrador           

&nbsp;  (cloudedu-admin ClusterRole)      

&nbsp;  - Puede modificar recursos        

&nbsp;  - Puede desplegar aplicaciones    

&nbsp;              |

&nbsp;              v

&nbsp;       Namespace: cloudedu          

&nbsp;                                    

&nbsp;      taskmanager-sa            

&nbsp;      (Service Account)         

&nbsp;      - Acceso limitado         

&nbsp;      - Solo lectura de configs 

&nbsp;              |                         

&nbsp;              v                         

&nbsp;      Pods de la Aplicación    

&nbsp;      - Ejecutan con SA        

&nbsp;      - Permisos mínimos       

&nbsp;              |

&nbsp;              v

&nbsp;    Usuario Desarrollador           

&nbsp; (cloudedu-developer ClusterRole)   

&nbsp;  - Solo puede ver recursos         

&nbsp;  - Puede leer logs                 



---



\## 5. Infraestructura como Código (IaC)



\### 5.1 Ansible



Componentes:

\- inventory.ini: Define los hosts (localhost en este caso)

\- playbook.yml: Automatiza todo el despliegue

\- cleanup-playbook.yml: Automatiza la limpieza



Flujo del Playbook:

1\. Verificar requisitos (Docker, kubectl)

2\. Construir imagen Docker

3\. Crear namespace

4\. Aplicar PersistentVolume

5\. Desplegar MySQL

6\. Configurar RBAC

7\. Desplegar aplicación

8\. Verificar estado



\### 5.2 Scripts de PowerShell



deploy.ps1:

\- Verificación de entorno

\- Construcción de imagen

\- Despliegue secuencial

\- Verificación de pods

\- Reportes de estado



cleanup.ps1:

\- Confirmación de usuario

\- Eliminación de namespace

\- Eliminación de PV

\- Limpieza de ClusterRoles



---



\## 6. Imagen Docker Personalizada



\### 6.1 Dockerfile



Base Image: python:3.11-slim



Capas:

1\. Instalación de dependencias del sistema (libmysqlclient-dev)

2\. Copia de requirements.txt

3\. Instalación de dependencias Python

4\. Copia del código de la aplicación

5\. Creación de usuario no-root (appuser)

6\. Configuración de health check



Características de Seguridad:

\- Usuario no-root (UID 1000)

\- Mínimas dependencias del sistema

\- Sin herramientas de desarrollo en producción

\- Health check integrado



\### 6.2 Tamaño de Imagen



Imagen base: ~150 MB

Dependencias: ~100 MB

Código: <1 MB

Total aproximado: ~250 MB



---



\## 7. Flujo de Datos



&nbsp; Navegador   

&nbsp; Usuario     

&nbsp;      | HTTP

&nbsp;      | localhost:30080

&nbsp;      v

&nbsp; NodePort Service    

&nbsp; :30080 → :5000      

&nbsp;      |

&nbsp;      v

&nbsp; Flask App Pod 1 o Pod 2     

&nbsp; (Load Balanced)             

&nbsp; - Recibe request HTTP       

&nbsp; - Procesa lógica de negocio 

&nbsp;      | MySQL Protocol

&nbsp;      | mysql-service:3306

&nbsp;      v

&nbsp; MySQL Pod                   

&nbsp; - Query a base de datos     

&nbsp; - Retorna resultados        

&nbsp;      |

&nbsp;      | Persistencia

&nbsp;      v

&nbsp; PersistentVolume            

&nbsp; /var/lib/mysql              

&nbsp; 1Gi Storage                 



---



\## 8. Resiliencia y Alta Disponibilidad



\### 8.1 Aplicación Flask



\- 2 réplicas: Si un pod falla, el otro continúa sirviendo tráfico

\- Health checks: Kubernetes reinicia pods no saludables automáticamente

\- Resource limits: Previene que un pod consuma todos los recursos



\### 8.2 Base de Datos MySQL



\- 1 réplica: Configuración básica (suficiente para el proyecto)

\- Persistent storage: Los datos sobreviven a reinicios de pods

\- Probes: Verificación continua de salud



\### 8.3 Recuperación Automática



Pod crashea → Kubernetes detecta (liveness probe)

&nbsp;             ↓

&nbsp;        Reinicia el pod

&nbsp;             ↓

&nbsp;        Readiness probe verifica

&nbsp;             ↓

&nbsp;        Pod recibe tráfico nuevamente



---



\## 9. Rendimiento



\### 9.1 Recursos Asignados



| Componente | CPU Request | CPU Limit | Memory Request | Memory Limit |

|------------|-------------|-----------|----------------|--------------|

| Flask App  | 100m        | 200m      | 128Mi          | 256Mi        |

| MySQL      | 250m        | 500m      | 256Mi          | 512Mi        |



\### 9.2 Escalabilidad



Horizontal:

\- Flask app ya tiene 2 réplicas

\- Se puede aumentar fácilmente: kubectl scale deployment taskmanager-app --replicas=5 -n cloudedu



Vertical:

\- Se pueden ajustar los límites de recursos en los manifiestos



---



\## 10. Decisiones Técnicas



\### 10.1 ¿Por qué Flask?



\- Lightweight y fácil de contenedorizar

\- Ideal para aplicaciones pequeñas/medianas

\- Excelente para prototipos y demostraciones

\- Buena integración con MySQL



\### 10.2 ¿Por qué MySQL?



\- Base de datos relacional robusta

\- Ampliamente utilizada en producción

\- Buen soporte en Kubernetes

\- Fácil de configurar con volúmenes persistentes



\### 10.3 ¿Por qué NodePort?



\- Acceso simple desde localhost

\- No requiere configuración de Ingress

\- Ideal para entornos de desarrollo/demo



\### 10.4 ¿Por qué 2 réplicas de Flask?



\- Demuestra load balancing

\- Proporciona redundancia básica

\- No consume demasiados recursos locales



---



\## 11. Limitaciones y Mejoras Futuras



\### 11.1 Limitaciones Actuales



\- Base de datos sin replicación

\- Sin HTTPS/TLS

\- Secrets en plain text (mejorable con Kubernetes Secrets)

\- Sin backup automatizado

\- Sin CI/CD integrado



\### 11.2 Mejoras Propuestas



1\. Seguridad:

&nbsp;  - Implementar Kubernetes Secrets

&nbsp;  - HTTPS con cert-manager

&nbsp;  - Network Policies



2\. Disponibilidad:

&nbsp;  - MySQL StatefulSet con replicación

&nbsp;  - ReadWriteMany PV para backups

&nbsp;  - Snapshots automatizados



3\. Observabilidad:

&nbsp;  - Prometheus para métricas

&nbsp;  - Grafana para dashboards

&nbsp;  - Loki para logs centralizados



4\. CI/CD:

&nbsp;  - GitHub Actions pipeline

&nbsp;  - Tests automatizados

&nbsp;  - Despliegue continuo



5\. Productización:

&nbsp;  - Helm Charts

&nbsp;  - Multi-environment (dev/staging/prod)

&nbsp;  - Autoscaling (HPA)

&nbsp;  - Ingress Controller



---



\## 12. Conclusión



La arquitectura implementada cumple con todos los requisitos del proyecto:



✅ Contenedores Docker personalizados  

✅ Orquestación con Kubernetes  

✅ IaC con Ansible y PowerShell  

✅ Almacenamiento persistente  

✅ Servicios expuestos  

✅ Control de acceso (RBAC)  

✅ Documentación completa  



La solución es escalable, reproducible y sigue las mejores prácticas de desarrollo cloud-native.

