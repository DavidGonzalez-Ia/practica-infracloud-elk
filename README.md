\# CloudEdu TaskManager - Proyecto Cloud-Native



\## 📋 Información del Proyecto



\*\*Asignatura\*\*: Infraestructura Cloud  

\*\*Proyecto\*\*: Práctica Final Integrada - Despliegue Cloud-Native Seguro con IaC y Kubernetes  

\*\*Aplicación\*\*: Sistema de gestión de tareas (TaskManager)  

\*\*Peso\*\*: 30% de la nota final  



---



\## 🎯 Objetivos del Proyecto



Migrar una aplicación web a una arquitectura cloud-native cumpliendo con:



1\. ✅ Contenedores Docker personalizados

2\. ✅ Orquestación con Kubernetes

3\. ✅ Infraestructura como Código (IaC) con Ansible/PowerShell

4\. ✅ Almacenamiento persistente

5\. ✅ Servicios expuestos (NodePort)

6\. ✅ Control de acceso (RBAC)

7\. ✅ Documentación técnica completa



---



\## 🏗️ Arquitectura de la Solución



\### Componentes Principales



&nbsp;                 DOCKER DESKTOP / MINIKUBE              

&nbsp;                    (Kubernetes Cluster)                

&nbsp;                                                        

&nbsp;        NAMESPACE: cloudedu                     

&nbsp;                                                

&nbsp;      Flask App          MySQL 8.0      

&nbsp;      (Python 3.11)  -->  (Database)     

&nbsp;      Port: 5000         Port: 3306     

&nbsp;      Replicas: 2        Replicas: 1    

&nbsp;                                        

&nbsp;      Service            Service        

&nbsp;      NodePort           ClusterIP      

&nbsp;      :30080             :3306          

&nbsp;                                        

&nbsp;      Persistent Volume (1Gi)              

&nbsp;      Storage para MySQL                   

&nbsp;                                        

&nbsp;      RBAC (Roles \& ServiceAccounts)       

&nbsp;      - taskmanager-sa                     

&nbsp;      - cloudedu-admin (ClusterRole)       

&nbsp;      - cloudedu-developer (ClusterRole)   



&nbsp;             http://localhost:30080

&nbsp;                  (Navegador)





\### Stack Tecnológico



| Componente | Tecnología | Versión |

|------------|------------|---------|

| Aplicación | Flask (Python) | 3.0.0 |

| Base de Datos | MySQL | 8.0 |

| Contenedores | Docker | 29.0+ |

| Orquestación | Kubernetes | 1.28+ |

| IaC | Ansible + PowerShell | 2.15+ / 7.0+ |

| Control de Versiones | Git | 2.40+ |



---



\## 📂 Estructura del Proyecto



cloudedu-taskmanager/

├── app/                          

│   ├── app.py                    

│   ├── templates/

│   │   └── index.html           

│   ├── requirements.txt          

│   └── Dockerfile               

├── kubernetes/                   

│   ├── namespace.yaml           

│   ├── mysql-pv.yaml            

│   ├── mysql-deployment.yaml    

│   ├── mysql-service.yaml       

│   ├── app-deployment.yaml      

│   ├── app-service.yaml         

│   └── rbac.yaml                

├── ansible/                      

│   ├── inventory.ini            

│   ├── playbook.yml             

│   └── cleanup-playbook.yml     

├── docs/                         

│   ├── arquitectura.md          

│   ├── reflexion-final.md       

│   ├── INSTRUCCIONES\_DEFENSA.md 

│   └── evidencias/              

├── deploy.ps1                   

├── cleanup.ps1                  

├── verificar-proyecto.ps1       

├── .gitignore                   

└── README.md                    



---



\## 🚀 Instrucciones de Despliegue



\### Prerequisitos



1\. Docker Desktop instalado y en ejecución

2\. Kubernetes habilitado en Docker Desktop

3\. kubectl instalado

4\. Git para control de versiones

5\. PowerShell (Windows) o Bash (Linux/Mac)



\### Opción 1: Despliegue Automático (Recomendado)



\# Ejecutar script de despliegue

.\\deploy.ps1



El script realizará automáticamente:

\- Verificación de requisitos

\- Construcción de imagen Docker

\- Creación de namespace

\- Configuración de almacenamiento

\- Despliegue de MySQL y aplicación

\- Configuración de RBAC

\- Verificación del estado



\### Opción 2: Despliegue Manual



\# 1. Construir imagen Docker

cd app

docker build -t cloudedu-taskmanager:v1 .

cd ..



\# 2. Crear namespace

kubectl apply -f kubernetes/namespace.yaml



\# 3. Configurar almacenamiento

kubectl apply -f kubernetes/mysql-pv.yaml



\# 4. Desplegar MySQL

kubectl apply -f kubernetes/mysql-deployment.yaml

kubectl apply -f kubernetes/mysql-service.yaml



\# 5. Configurar RBAC

kubectl apply -f kubernetes/rbac.yaml



\# 6. Desplegar aplicación

kubectl apply -f kubernetes/app-deployment.yaml

kubectl apply -f kubernetes/app-service.yaml



\# 7. Verificar estado

kubectl get pods -n cloudedu

kubectl get svc -n cloudedu



---



\## 🔍 Verificación del Despliegue



\### Comprobar estado de los pods



kubectl get pods -n cloudedu



Resultado esperado:

NAME                               READY   STATUS    RESTARTS   AGE

mysql-7f67b5dcf8-xxxxx             1/1     Running   0          2m

taskmanager-app-7865bb5d68-xxxxx   1/1     Running   0          1m

taskmanager-app-7865bb5d68-xxxxx   1/1     Running   0          1m



\### Acceder a la aplicación



Abrir navegador en: http://localhost:30080



---



\## 🔐 Seguridad y Control de Acceso (RBAC)



\### Service Accounts



\- taskmanager-sa: Service account para los pods de la aplicación



\### Roles



taskmanager-role (Role)

Permisos para la aplicación dentro del namespace:

\- Leer ConfigMaps y Secrets

\- Listar Pods



cloudedu-admin (ClusterRole)

Permisos de administrador:

\- Crear, actualizar, eliminar Deployments

\- Gestionar Services y PersistentVolumeClaims

\- Acceso completo al namespace



cloudedu-developer (ClusterRole)

Permisos de solo lectura:

\- Ver Deployments y Pods

\- Listar Services

\- Leer logs de Pods



---



\## 💾 Almacenamiento Persistente



\### PersistentVolume (PV)



Capacidad: 1Gi

AccessMode: ReadWriteOnce

StorageClass: manual

Path: /data/mysql



\### PersistentVolumeClaim (PVC)



Nombre: mysql-pvc

Namespace: cloudedu

Storage: 1Gi



El volumen persistente garantiza que los datos de MySQL sobreviven a reinicios de pods.



---



\## 🧪 Pruebas y Validación



\### Health Checks



La aplicación incluye un endpoint de salud:



curl http://localhost:30080/health



Respuesta esperada:

{

&nbsp; "status": "healthy",

&nbsp; "database": "connected"

}



\### Logs



\# Ver logs de la aplicación

kubectl logs -n cloudedu -l app=taskmanager --tail=50



\# Ver logs de MySQL

kubectl logs -n cloudedu -l app=mysql --tail=50



---



\## 🗑️ Limpieza y Eliminación



\### Con script automático



.\\cleanup.ps1



\### Manualmente



\# Eliminar namespace (elimina todo)

kubectl delete namespace cloudedu



\# Eliminar PersistentVolume

kubectl delete pv mysql-pv



\# Eliminar ClusterRoles

kubectl delete clusterrole cloudedu-admin cloudedu-developer



---



\## 🐛 Resolución de Problemas



\### Pods en CrashLoopBackOff



\# Ver logs del pod

kubectl logs -n cloudedu <POD\_NAME>



\# Describir el pod

kubectl describe pod -n cloudedu <POD\_NAME>



\### MySQL no inicia



\# Reiniciar MySQL

kubectl rollout restart deployment mysql -n cloudedu



\### No se puede acceder a localhost:30080



\# Verificar que el servicio existe

kubectl get svc -n cloudedu taskmanager-service



\# Verificar que Kubernetes está corriendo

kubectl cluster-info



---



\## 📈 Mejoras Futuras



\- CI/CD con GitHub Actions

\- Monitorización con Prometheus/Grafana

\- Ingress Controller con HTTPS

\- Secrets management con Vault

\- Helm Charts para packaging

\- Multi-environment (dev, staging, prod)

\- Backup automatizado de MySQL

\- Autoscaling (HPA)



---



\## 👥 Autores



Nombres: Manuel Botella, Carlos Gómez, Diego Rodríguez, Hugo Langenaeken y David González  

Fecha: Noviembre 2025  

Asignatura: Infraestructura Cloud  



---



\## 🔗 Referencias



\- Kubernetes Documentation: https://kubernetes.io/docs/

\- Docker Documentation: https://docs.docker.com/

\- Flask Documentation: https://flask.palletsprojects.com/

\- Ansible Documentation: https://docs.ansible.com/

\- MySQL Documentation: https://dev.mysql.com/doc/

