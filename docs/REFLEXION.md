# Reflexión - Práctica InfraCloud

**Autores:** Manuel Botella, Carlos Gomez, Diego Rodriguez, Hugo Langenaeken, David Gonzalez  
**Asignatura:** Infraestructura Cloud  
**Diciembre 2025**

---

## Resumen

Hemos montado una app web (TaskManager) en Kubernetes con logs centralizados usando ELK Stack. Básicamente pusimos Docker + Kubernetes + Elasticsearch + Kibana + Filebeat todo junto para tener un sistema donde puedes ver todos los logs en un sitio en vez de ir pod por pod.

## Decisiones que tomamos

### Por qué ELK Stack
Elegimos ELK en vez de otras opciones (como Loki+Grafana) porque:
- Elasticsearch busca super rápido en los logs
- Kibana es fácil de usar y no hay que configurar mucho
- Está bien documentado y hay mucha info online
- Es lo que se usa bastante en empresas reales

### Por qué Filebeat y no Logstash
Usamos Filebeat porque consume menos recursos (unos 50MB vs 1GB+ de Logstash) y como DaemonSet se despliega solo en todos los nodos. Para lo que necesitábamos (solo recoger logs) no hacía falta Logstash con todas sus transformaciones.

### Logs en JSON
Hicimos un formatter personalizado en Python para que los logs salieran en JSON. Así Elasticsearch los indexa automáticamente y es mucho más fácil buscar por campos específicos (tipo nivel ERROR, timestamp, etc.).

### Ansible para IaC
Usamos Ansible en vez de Terraform porque:
- No necesita instalar nada en los servidores (agentless)
- La sintaxis YAML es más fácil de leer
- Tiene integración directa con Kubernetes
- Si lo ejecutas varias veces hace lo mismo (idempotente)

## Problemas que tuvimos

### MySQL no arrancaba
El PersistentVolumeClaim se quedaba en Pending. Resulta que Minikube con Docker no crea los volúmenes automáticamente. Tuvimos que hacer un PV manual con hostPath apuntando a `/data/mysql-pv`. Funciona para desarrollo pero no es lo ideal para producción.

### Kibana no se veía desde fuera  
El NodePort 30601 no funcionaba. Buscamos y vimos que con Minikube + Docker los NodePorts no se exponen en localhost directamente. La solución fue usar `kubectl port-forward` o el comando `minikube service`.

### Los logs salían en texto plano
Al principio los logs de Python salían normales (texto). Tuvimos que crear una clase JSONFormatter que formatea los logs a JSON antes de escribirlos. Así Elasticsearch los puede indexar bien.

### Filebeat no encontraba logs
El path estaba mal en la configuración. Había que poner `/var/log/containers/*.log` y montar ese directorio del host como volumen.

## Lo que aprendimos

**Técnico:**
- Kubernetes es bastante más complejo de lo que parecía. No es solo levantar contenedores, hay que entender networking, storage, permisos RBAC, etc.
- Tener logs centralizados ahorra MUCHO tiempo. Antes teníamos que hacer kubectl logs en cada pod.
- Automatizar con Ansible está bien porque puedes recrear todo el entorno rápido.
- Los DaemonSets son útiles para cosas que necesitas en todos los nodos (como Filebeat).

**Metodológico:**
- Documentar mientras haces las cosas es mejor que dejarlo para el final.
- Probar paso a paso (MySQL → App → Elasticsearch → Kibana → Filebeat) fue mejor que desplegar todo de golpe.
- Port-forward es tu amigo cuando estás desarrollando en local.

## Cosas que se podrían mejorar

Si tuviéramos más tiempo:
- Poner 3 réplicas de Elasticsearch para alta disponibilidad
- Usar un Ingress Controller para acceder mejor a los servicios
- Añadir Prometheus para métricas (ahora solo tenemos logs)
- Hacer Helm Charts para empaquetar todo
- Configurar alertas en Kibana para cuando haya errores graves

## Conclusión

La práctica nos sirvió para ver cómo funcionan estas tecnologías en un caso real. Lo más útil fue entender cómo se conectan todas las piezas (app → logs → Filebeat → Elasticsearch → Kibana) y poder debuggear problemas viendo los logs centralizados en vez de ir pod por pod con kubectl.

También aprendimos que montar infraestructura cloud no es trivial - hay muchos detalles (networking, storage, permisos) que hay que tener en cuenta. Pero al final quedó funcionando todo y se entiende mejor cómo se hace esto en empresas de verdad.

---

**Equipo:** Manuel Botella, Carlos Gomez, Diego Rodriguez, Hugo Langenaeken, David Gonzalez

2. **Observabilidad es crítica desde el inicio**: Integrar logging antes de llegar a producción ahorra horas de debugging. Ver logs estructurados en Kibana es 100x más eficiente que hacer `kubectl logs | grep`.

3. **IaC no es opcional**: Ansible nos permitió replicar el entorno completo en minutos. Sin IaC, desplegar manualmente 15+ manifests de Kubernetes es propenso a errores.

4. **DaemonSets para agentes globales**: Filebeat como DaemonSet asegura que todos los nodos tengan un recolector de logs sin intervención manual.

### Metodológicos
1. **Documentación exhaustiva vale la pena**: Crear `QUICK-START-ELK.md`, `ELK-LOGGING-GUIDE.md` y `ARQUITECTURA.md` nos obligó a entender profundamente cada componente.

2. **Testing incremental**: Desplegar paso a paso (MySQL → App → Elasticsearch → Kibana → Filebeat) fue más efectivo que desplegar todo de golpe y debuggear después.

3. **Port-forwarding es tu amigo en desarrollo**: Para acceso rápido a servicios sin configurar Ingress o LoadBalancers.

## 🔮 Trabajo Futuro

Si tuviéramos más tiempo, implementaríamos:
1. **Alta Disponibilidad**: 3 réplicas de Elasticsearch con StatefulSet
2. **Ingress Controller**: NGINX Ingress para exponer servicios con nombres de dominio
3. **CI/CD Completo**: GitHub Actions desplegando automáticamente en push a `main`
4. **Helm Charts**: Empaquetar toda la aplicación como Helm chart reutilizable
5. **Alerting**: Configurar alertas en Kibana para errores críticos (500, crashes)
6. **Métricas con Prometheus**: Añadir exporters para métricas de rendimiento

## 🏆 Conclusión

Esta práctica nos ha proporcionado experiencia real en tecnologías cloud-native que son estándares de la industria. Hemos aprendido que la infraestructura moderna requiere no solo desplegar aplicaciones, sino también diseñar para observabilidad, escalabilidad y resiliencia desde el primer día.

El stack ELK nos ha demostrado el valor de los logs centralizados: lo que antes requería conectarse a múltiples pods con `kubectl logs`, ahora es una query KQL en Kibana. La automatización con Ansible nos enseñó que el tiempo invertido en IaC se recupera inmediatamente en la primera reedición del entorno.

En resumen, esta práctica nos ha dado una base sólida para trabajar en entornos cloud profesionales y nos ha preparado para enfrentar desafíos de infraestructura a escala real.

---

**Práctica Final InfraCloud**  
**Equipo:** Manuel Botella, Carlos Gomez, Diego Rodriguez, Hugo Langenaeken, David Gonzalez  
**Diciembre 2025**
