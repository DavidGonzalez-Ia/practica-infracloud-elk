\# Guía para la Defensa del Proyecto



Duración: 10-15 minutos  

Formato: Presentación + Demostración en vivo  



---



\## 📋 Estructura de la Defensa



\### 1. Introducción (1-2 minutos)



Qué decir:

\- "Buenos días/tardes. Presento el proyecto CloudEdu TaskManager, una aplicación de gestión de tareas desplegada en arquitectura cloud-native."

\- "El objetivo era demostrar el dominio de Docker, Kubernetes, IaC y seguridad en la nube."

\- "La aplicación consta de un frontend/backend en Flask y una base de datos MySQL, todo orquestado en Kubernetes."



Mostrar: Diagrama de arquitectura (README o slides)



---



\### 2. Demostración en Vivo (3-4 minutos)



Script de demostración:



\# 1. Mostrar que no hay nada desplegado

kubectl get all -n cloudedu

\# (Debería dar error: namespace no encontrado)



\# 2. Ejecutar script de despliegue automático

.\\deploy.ps1



\# 3. Mientras se despliega, explicar lo que hace:



Qué explicar mientras corre el script:

\- "El script verifica Docker y kubectl"

\- "Construye la imagen Docker personalizada"

\- "Crea el namespace aislado 'cloudedu'"

\- "Configura el almacenamiento persistente"

\- "Despliega MySQL con un PersistentVolume"

\- "Aplica las políticas RBAC de seguridad"

\- "Despliega 2 réplicas de la aplicación Flask"

\- "Expone el servicio en el puerto 30080"



\# 4. Mostrar que todo está corriendo

kubectl get pods -n cloudedu

kubectl get svc -n cloudedu



Qué resaltar:

\- "Tenemos 3 pods: 1 de MySQL y 2 de la aplicación"

\- "El servicio NodePort expone la app en localhost:30080"

\- "MySQL usa ClusterIP, solo accesible internamente"



\# 5. Abrir el navegador

start http://localhost:30080



Demostración en el navegador:

\- "Aquí tenemos la interfaz de usuario"

\- "Voy a crear una tarea..." (crear 1-2 tareas)

\- "Puedo marcarla como completada..."

\- "Y eliminarla si quiero..."

\- "Los datos persisten gracias al PersistentVolume de MySQL"



---



\### 3. Componentes Técnicos (4-5 minutos)



\#### 3.1 Docker (1 min)



\# Mostrar la imagen

docker images | findstr cloudedu



\# Abrir el Dockerfile (opcional)

code app/Dockerfile



Qué explicar:

\- "Imagen personalizada basada en Python 3.11"

\- "Usuario no-root para seguridad (appuser)"

\- "Health check integrado para Kubernetes"

\- "Optimizada con capas: dependencias → código → configuración"



\#### 3.2 Kubernetes (1-2 min)



\# Mostrar los recursos

kubectl get all -n cloudedu

kubectl describe deployment taskmanager-app -n cloudedu



Qué explicar:

\- "2 réplicas para alta disponibilidad"

\- "Liveness y readiness probes configurados"

\- "Resource limits para prevenir consumo excesivo"

\- "Labels y selectors para organización"



\#### 3.3 Almacenamiento Persistente (1 min)



kubectl get pv

kubectl get pvc -n cloudedu



Qué explicar:

\- "PersistentVolume de 1Gi para MySQL"

\- "Datos persisten incluso si el pod se reinicia"

\- "En producción se usaría un StorageClass dinámico"



\#### 3.4 RBAC (1 min)



kubectl get roles,rolebindings -n cloudedu

kubectl get clusterroles | findstr cloudedu

kubectl get sa -n cloudedu



Qué explicar:

\- "Service Account 'taskmanager-sa' con permisos mínimos"

\- "Role con acceso solo a ConfigMaps y Secrets"

\- "ClusterRoles para administradores y desarrolladores"

\- "Modelo de least privilege: cada componente tiene solo los permisos necesarios"



---



\### 4. Infraestructura como Código (1-2 minutos)



\# Mostrar estructura

tree /F kubernetes

tree /F ansible



Qué explicar:

\- "Toda la infraestructura está definida como código"

\- "Manifiestos YAML de Kubernetes versionados en Git"

\- "Playbooks de Ansible para automatización"

\- "Scripts de PowerShell para entornos Windows"

\- "Despliegue reproducible: mismo comando, mismo resultado"



Demostrar reproducibilidad (si hay tiempo):



\# Limpiar todo

.\\cleanup.ps1



\# Volver a desplegar

.\\deploy.ps1



---



\### 5. Problemas y Soluciones (1-2 minutos)



Mencionar:



Problema 1: MySQL en CrashLoopBackOff

\- "Inicialmente MySQL no arrancaba por datos corruptos"

\- "Solución: Limpiar el PersistentVolume y usar emptyDir"

\- "Aprendí la importancia de gestionar el estado correctamente"



Problema 2: ErrImageNeverPull

\- "Kubernetes no encontraba la imagen local"

\- "Solución: Verificar que la imagen existe con docker images"

\- "Configurar imagePullPolicy: Never para desarrollo local"



Problema 3: Ansible en Windows

\- "Ansible no funciona nativamente en Windows"

\- "Solución: Scripts de PowerShell equivalentes + playbooks para cumplir requisito"

\- "Flexibilidad: adaptar la herramienta al entorno"



---



\### 6. Conclusiones (1 minuto)



Qué decir:



"En conclusión, este proyecto me ha permitido:



✅ Dominar Docker: Crear imágenes optimizadas y seguras  

✅ Entender Kubernetes: Deployments, Services, PV/PVC, RBAC  

✅ Implementar IaC: Automatización completa del despliegue  

✅ Aplicar seguridad: RBAC, usuarios no-root, permisos mínimos  

✅ Resolver problemas: Debugging de pods, logs, y recursos  



La aplicación cumple todos los requisitos:

\- Contenedores Docker personalizados ✓

\- Orquestación con Kubernetes ✓

\- IaC con Ansible/PowerShell ✓

\- Almacenamiento persistente ✓

\- Servicios expuestos ✓

\- Control de acceso RBAC ✓

\- Documentación completa ✓



Estoy preparado para responder preguntas."



---



\## ❓ Preguntas Frecuentes Esperadas



\### Pregunta 1: ¿Por qué Flask y no otra tecnología?



Respuesta:

"Elegí Flask por su simplicidad y rapidez de desarrollo. Es lightweight, fácil de contenedorizar, y suficientemente robusto para esta aplicación. En producción, dependería del caso de uso: Node.js para alta concurrencia, Django para apps complejas, o Go para máximo rendimiento."



\### Pregunta 2: ¿Por qué solo 1 réplica de MySQL?



Respuesta:

"Para este proyecto de demostración, 1 réplica es suficiente. En producción usaría un StatefulSet con replicación master-slave para:

\- Alta disponibilidad

\- Lectura distribuida

\- Failover automático

También consideraría servicios gestionados como AWS RDS o Cloud SQL."



\### Pregunta 3: ¿Cómo escalarías esta aplicación?



Respuesta:

"Horizontalmente:



kubectl scale deployment taskmanager-app --replicas=5 -n cloudedu



Para auto-scaling, implementaría un HorizontalPodAutoscaler basado en CPU o memoria. La aplicación Flask es stateless, así que escala fácilmente.



Para MySQL, usaría replicación read-replicas o un cluster como Vitess."



\### Pregunta 4: ¿Qué pasa si un pod de Flask falla?



Respuesta:

"Kubernetes lo detecta automáticamente mediante las liveness probes y reinicia el pod. Mientras tanto, el otro pod continúa sirviendo tráfico. No hay downtime perceptible porque:

1\. Service distribuye el tráfico entre pods saludables

2\. Readiness probe asegura que solo pods listos reciben tráfico

3\. El pod reiniciado se reincorpora cuando pasa las probes"



\### Pregunta 5: ¿Cómo aseguras los secrets?



Respuesta:

"En este proyecto, las credenciales están en variables de entorno por simplicidad. En producción usaría:

1\. Kubernetes Secrets (mínimo)

2\. Mejor aún: HashiCorp Vault o AWS Secrets Manager

3\. Encriptación en reposo con KMS

4\. Rotación automática de credenciales

5\. RBAC estricto sobre quién puede leer secrets"



\### Pregunta 6: ¿Por qué PowerShell en lugar de solo Ansible?



Respuesta:

"Ansible no funciona nativamente en Windows. Implementé ambos:

\- Ansible playbooks: Cumplen el requisito académico, estándar en la industria

\- Scripts PowerShell: Funcionalidad real en Windows sin WSL



Esta dual approach demuestra adaptabilidad: usar la herramienta correcta para cada entorno."



\### Pregunta 7: ¿Cómo monitorizarías esto en producción?



Respuesta:

"Implementaría el stack de observabilidad:

\- Prometheus: Métricas de pods, CPU, memoria, requests

\- Grafana: Dashboards visuales

\- Loki: Logs centralizados

\- Jaeger: Tracing distribuido para debugging

\- Alertmanager: Alertas a Slack/email



También usaría las herramientas nativas del cloud provider: CloudWatch, Azure Monitor, o Google Cloud Monitoring."



\### Pregunta 8: ¿Qué mejoras implementarías?



Respuesta:

"Prioridades:

1\. CI/CD: GitHub Actions para tests y deploy automático

2\. HTTPS: Ingress con cert-manager y Let's Encrypt

3\. Secrets: Vault para gestión segura

4\. Monitoring: Stack Prometheus/Grafana

5\. Backups: Velero para backups del cluster

6\. Multi-environment: dev, staging, prod

7\. Network Policies: Restricciones de tráfico entre pods"



---



\## 🎯 Consejos para la Defensa



\### Antes de la Presentación



\- Ensaya el flujo completo al menos 2 veces

\- Asegúrate de que deploy.ps1 funciona sin errores

\- Ten el proyecto ya desplegado como backup

\- Abre todas las terminales y ventanas necesarias

\- Verifica que localhost:30080 es accesible

\- Ten el README.md abierto para referencia rápida



\### Durante la Presentación



✅ Habla con confianza: Conoces tu proyecto  

✅ Explica el "por qué", no solo el "cómo"  

✅ Relaciona con conceptos del curso: Menciona teoría aprendida  

✅ Demuestra comprensión: Explica decisiones técnicas  

✅ Sé honesto: Si algo no lo sabes, admítelo y explica cómo lo investigarías  



❌ No leas diapositivas palabra por palabra  

❌ No te excuses: "No tuve tiempo para..." → "Prioricé X porque Y"  

❌ No entres en pánico si algo falla: explica y usa el backup  



\### Si Algo Sale Mal



Plan B:

1\. Si deploy.ps1 falla: Muestra que ya está desplegado previamente

2\. Si la demo no funciona: Usa capturas de pantalla de evidencias

3\. Si te preguntan algo que no sabes: "No lo he implementado, pero investigaría X"



---



\## ⏱️ Timing Recomendado



| Sección | Tiempo | Acumulado |

|---------|--------|-----------|

| Introducción | 1-2 min | 2 min |

| Demo en vivo | 3-4 min | 6 min |

| Componentes técnicos | 4-5 min | 11 min |

| IaC | 1-2 min | 13 min |

| Problemas/Conclusiones | 2 min | 15 min |



Total: 15 minutos máximo



---



\## 📝 Checklist Pre-Defensa



\### Técnico

\- Docker Desktop corriendo

\- Kubernetes habilitado

\- Proyecto clonado/descargado

\- deploy.ps1 y cleanup.ps1 funcionan

\- Aplicación accesible en localhost:30080

\- Todas las capturas de pantalla tomadas



\### Documentación

\- README.md completo

\- Arquitectura documentada

\- Reflexión final escrita

\- Evidencias organizadas



\### Presentación

\- Estructura mental clara

\- Respuestas a preguntas frecuentes preparadas

\- Demo ensayada

\- Plan B listo





