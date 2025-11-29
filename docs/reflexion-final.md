\# Reflexión Final - CloudEdu TaskManager



Proyecto: Despliegue Cloud-Native Seguro con IaC y Kubernetes  

Autor: \[Tu Nombre]  

Fecha: Noviembre 2025  



---



\## 1. Decisiones Técnicas Clave



\### 1.1 Elección del Stack Tecnológico



Flask + MySQL: 

Elegí Flask por su simplicidad y rapidez de desarrollo. Es un framework minimalista que permite crear aplicaciones web funcionales sin complejidad innecesaria. MySQL fue seleccionado por ser una base de datos robusta, ampliamente documentada y con excelente soporte en Kubernetes.



Docker Desktop con Kubernetes:

Opté por Docker Desktop en lugar de Minikube o servicios cloud (EKS/GKE/AKS) por las siguientes razones:

\- No requiere cuenta cloud ni costos

\- Integración nativa con Windows

\- Suficiente para demostrar todos los conceptos del proyecto

\- Simplifica el desarrollo local



Ansible + PowerShell para IaC:

Dado que trabajo en Windows, implementé una estrategia dual:

\- Scripts de PowerShell para ejecución nativa en Windows

\- Playbooks de Ansible para cumplir el requisito de IaC estándar



Esto demuestra flexibilidad y adaptación a diferentes entornos.



\### 1.2 Arquitectura de la Aplicación



Separación de Concerns:

\- Frontend/Backend en Flask (tier aplicación)

\- MySQL en contenedor separado (tier datos)

\- Comunicación a través de Services de Kubernetes



2 Réplicas de Flask:

Implementé 2 réplicas del frontend para demostrar:

\- Load balancing automático de Kubernetes

\- Alta disponibilidad básica

\- Escalabilidad horizontal



1 Réplica de MySQL:

Aunque en producción se usarían StatefulSets con replicación, para este proyecto:

\- Una réplica es suficiente para la demostración

\- Simplifica la gestión de datos

\- Los datos persisten gracias al PersistentVolume



\### 1.3 Estrategia de Almacenamiento



PersistentVolume con hostPath:

Inicialmente intenté usar un PV estándar, pero enfrenté problemas con datos corruptos. La solución fue:

\- Usar emptyDir en el deployment para pruebas rápidas

\- Mantener el PV/PVC para cumplir el requisito del proyecto

\- En producción, se usaría un StorageClass dinámico (AWS EBS, Azure Disk, etc.)



\### 1.4 Seguridad (RBAC)



Modelo de tres niveles:

1\. Service Account (taskmanager-sa): Permisos mínimos para la aplicación

2\. Role (taskmanager-role): Acceso limitado a ConfigMaps y Secrets

3\. ClusterRoles: 

&nbsp;  - cloudedu-admin: Administradores con control total

&nbsp;  - cloudedu-developer: Desarrolladores con solo lectura



Este modelo sigue el principio de least privilege (mínimo privilegio necesario).



---



\## 2. Dificultades Encontradas



\### 2.1 Problema: MySQL en CrashLoopBackOff



Descripción: 

Al intentar el primer despliegue, MySQL entraba en un bucle de reinicios constantes.



Causa Raíz:

El PersistentVolume contenía datos corruptos de intentos anteriores. MySQL no podía inicializar la base de datos porque el directorio /var/lib/mysql ya tenía archivos.



Solución Implementada:



volumes:

&nbsp; - name: mysql-storage

&nbsp;   emptyDir: {}  # Datos en memoria, limpios cada vez



Alternativa más robusta para producción:



kubectl delete pv mysql-pv

\# Cambiar hostPath de /mnt/data/mysql a /data/mysql

\# Agregar type: DirectoryOrCreate



Aprendizaje: Siempre verificar el estado de los volúmenes persistentes antes de redesplegar.



\### 2.2 Problema: ErrImageNeverPull



Descripción:

Los pods de la aplicación no arrancaban con el error ErrImageNeverPull.



Causa Raíz:

Kubernetes no encontraba la imagen cloudedu-taskmanager:v1 porque:

\- La política imagePullPolicy: Never requiere que la imagen exista localmente

\- La imagen no se había cargado correctamente en el runtime de Kubernetes



Solución:



\# Construir imagen en el contexto correcto

docker build -t cloudedu-taskmanager:v1 .



\# Verificar que existe

docker images | findstr cloudedu



Aprendizaje: En entornos locales, usar imagePullPolicy: Never o IfNotPresent. En producción, siempre push a un registry.



\### 2.3 Problema: Ansible en Windows



Descripción:

Ansible no funciona nativamente en PowerShell de Windows.



Solución Implementada:

\- Creé playbooks de Ansible (cumple requisito académico)

\- Implementé scripts de PowerShell equivalentes (funcionalidad real)

\- Documenté ambos métodos en el README



Alternativa mencionada: Usar WSL2 para ejecutar Ansible, pero los scripts de PowerShell son más directos.



Aprendizaje: La infraestructura como código debe adaptarse al entorno. PowerShell es tan válido como Ansible para automatización en Windows.



\### 2.4 Problema: Health Checks Fallando



Descripción:

Inicialmente, las readiness probes fallaban porque la aplicación tardaba en conectarse a MySQL.



Solución:



readinessProbe:

&nbsp; initialDelaySeconds: 10  # Dar tiempo a que MySQL esté listo

&nbsp; periodSeconds: 5

&nbsp; timeoutSeconds: 3

&nbsp; failureThreshold: 3



Y en el código Python:



def get\_db\_connection():

&nbsp;   max\_retries = 5

&nbsp;   retry\_delay = 3

&nbsp;   # Reintentar conexión hasta 5 veces



Aprendizaje: Los microservicios deben ser resilientes a dependencias no disponibles temporalmente.



---



\## 3. Aprendizaje Obtenido



\### 3.1 Conceptos Técnicos



Kubernetes:

\- Entendí profundamente cómo funcionan los Deployments, ReplicaSets y Pods

\- Aprendí la diferencia entre ClusterIP, NodePort e Ingress

\- Comprendí el modelo de almacenamiento con PV/PVC

\- Dominé los conceptos de probes (liveness, readiness)



Docker:

\- Aprendí a crear Dockerfiles optimizados

\- Entendí las capas de las imágenes y cómo minimizar el tamaño

\- Implementé usuarios no-root por seguridad

\- Configuré health checks dentro de la imagen



RBAC:

\- Comprendí la diferencia entre Roles y ClusterRoles

\- Aprendí a crear Service Accounts y RoleBindings

\- Entendí el principio de least privilege



IaC:

\- Desarrollé habilidades en Ansible (sintaxis YAML, playbooks)

\- Mejoré en scripting con PowerShell

\- Aprendí a automatizar flujos complejos de despliegue



\### 3.2 Habilidades Blandas



Resolución de Problemas:

Cada error fue una oportunidad de aprendizaje. Aprendí a:

\- Leer logs de Kubernetes efectivamente

\- Buscar documentación oficial

\- Iterar soluciones hasta encontrar la correcta



Documentación:

Este proyecto me enseñó la importancia de documentar:

\- Cada decisión técnica

\- Problemas y sus soluciones

\- Instrucciones claras para reproducir el entorno



Pensamiento Arquitectónico:

Desarrollé la capacidad de pensar en sistemas distribuidos:

\- Separación de concerns

\- Comunicación entre servicios

\- Persistencia de datos

\- Seguridad y permisos



---



\## 4. Aplicación Práctica



\### 4.1 Relevancia en el Mundo Real



Este proyecto refleja escenarios reales de la industria:



Microservicios:

La arquitectura con Flask y MySQL separados es común en sistemas modernos. Empresas como Netflix, Uber y Airbnb usan arquitecturas similares.



Kubernetes en Producción:

Empresas de todos los tamaños usan Kubernetes:

\- Startups para escalar rápidamente

\- Grandes corporaciones para gestionar miles de servicios



IaC:

La infraestructura como código es estándar en DevOps moderno:

\- Terraform para provisionar infraestructura cloud

\- Ansible para configuración de servidores

\- GitOps para despliegues automatizados



\### 4.2 Habilidades Transferibles



Las competencias desarrolladas son aplicables a:

\- DevOps Engineer

\- Platform Engineer

\- Cloud Architect

\- Site Reliability Engineer (SRE)

\- Full Stack Developer (con enfoque cloud)



---



\## 5. Si Tuviera Más Tiempo



\### 5.1 Mejoras de Seguridad



Kubernetes Secrets:



apiVersion: v1

kind: Secret

metadata:

&nbsp; name: mysql-credentials

type: Opaque

data:

&nbsp; password: <base64-encoded>



Network Policies:

Restringir tráfico entre pods, permitiendo solo:

\- Flask → MySQL

\- Bloquear todo lo demás



Pod Security Standards:

Implementar políticas de seguridad estrictas:

\- No permitir contenedores privilegiados

\- Forzar usuarios no-root

\- Restricciones de capabilities



\### 5.2 Observabilidad



Stack de Monitorización:

\- Prometheus: Recolección de métricas

\- Grafana: Visualización de dashboards

\- Loki: Agregación de logs

\- Jaeger: Tracing distribuido



Alertas:

Configurar alertas para:

\- Pods en estado no saludable

\- Alto uso de CPU/memoria

\- Errores en logs



\### 5.3 CI/CD



GitHub Actions Pipeline:



on: \[push]

jobs:

&nbsp; build:

&nbsp;   - Build Docker image

&nbsp;   - Run tests

&nbsp;   - Push to registry

&nbsp; deploy:

&nbsp;   - Update Kubernetes manifests

&nbsp;   - Apply to cluster

&nbsp;   - Smoke tests



\### 5.4 Alta Disponibilidad



MySQL StatefulSet:

Replicación master-slave para:

\- Lectura distribuida

\- Failover automático



Horizontal Pod Autoscaler:



apiVersion: autoscaling/v2

kind: HorizontalPodAutoscaler

spec:

&nbsp; minReplicas: 2

&nbsp; maxReplicas: 10

&nbsp; metrics:

&nbsp; - type: Resource

&nbsp;   resource:

&nbsp;     name: cpu

&nbsp;     target:

&nbsp;       type: Utilization

&nbsp;       averageUtilization: 70



\### 5.5 Productización



Helm Charts:

Empaquetar toda la aplicación en un chart reutilizable:



helm install cloudedu-taskmanager ./helm-chart



Multi-Environment:

\- Desarrollo (dev)

\- Staging (pruebas)

\- Producción (prod)



Cada uno con sus propios valores y configuraciones.



---



\## 6. Conclusiones Finales



\### 6.1 Objetivos Cumplidos



✅ Contenedores Docker personalizados: Dockerfile optimizado con seguridad y health checks  

✅ Kubernetes: Despliegue completo con Deployments, Services, PV/PVC  

✅ IaC: Ansible playbooks + Scripts de PowerShell automatizados  

✅ Persistencia: PersistentVolume para datos de MySQL  

✅ Exposición: Service NodePort accesible desde localhost:30080  

✅ Seguridad: RBAC completo con Roles, ClusterRoles y Service Accounts  

✅ Documentación: README, arquitectura, reflexión y evidencias  



\### 6.2 Valoración Personal



Este proyecto ha sido un viaje completo desde el concepto hasta la implementación. Comenzando sin experiencia en Terraform, cloud providers, y con conocimientos básicos de Docker y Kubernetes, logré:



1\. Aprender haciendo: Cada error fue una lección valiosa

2\. Investigar activamente: Consulté documentación oficial constantemente

3\. Adaptarme: Cuando Ansible falló en Windows, implementé una alternativa

4\. Perseverar: Los problemas con MySQL y las imágenes Docker fueron frustrantes pero superables



\### 6.3 Reflexión Final



La transición a arquitecturas cloud-native no es solo un cambio tecnológico, es un cambio de mentalidad:



\- De servidores a contenedores: Inmutabilidad y reproducibilidad

\- De manual a automatizado: Infraestructura como código

\- De monolito a microservicios: Escalabilidad y resiliencia

\- De "funciona en mi máquina" a "funciona en cualquier lugar": Portabilidad



Este proyecto me ha preparado para enfrentar desafíos reales en el mundo de DevOps y la computación en la nube. Las habilidades adquiridas son directamente aplicables en la industria, y la experiencia de resolver problemas complejos ha fortalecido mi capacidad de aprendizaje autónomo.



Puntuación auto-evaluada: Creo que este proyecto cumple con todos los requisitos técnicos y demuestra comprensión profunda de los conceptos. La automatización funcional, la documentación exhaustiva y la resolución de problemas evidencian un trabajo completo y profesional.



---



Fecha de entrega: 29/11/2025  

Autores: Manuel Botella, Carlos Gómez, Diego Rodríguez, Hugo Langenaeken y David González   

Asignatura: Infraestructura Cloud

