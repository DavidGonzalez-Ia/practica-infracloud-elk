# Infrastructure as Code con Ansible

**Autores:** Manuel Botella, Carlos Gomez, Diego Rodriguez, Hugo Langenaeken, David Gonzalez

## 📋 Descripción

Este directorio contiene los playbooks de Ansible para la gestión automatizada de la infraestructura del proyecto TaskManager con ELK Stack en Kubernetes.

## 📁 Estructura

```
ansible/
├── ansible.cfg              # Configuración de Ansible
├── inventory.ini            # Inventario de hosts
├── deploy-playbook.yml      # Despliegue completo
├── cleanup-playbook.yml     # Limpieza de recursos
└── README.md               # Esta documentación
```

## 🔧 Requisitos Previos

### 1. Instalar Ansible

**Windows (con Python):**
```powershell
pip install ansible
```

**Linux/MacOS:**
```bash
sudo apt-get install ansible  # Ubuntu/Debian
brew install ansible           # MacOS
```

### 2. Instalar colección de Kubernetes para Ansible

```bash
ansible-galaxy collection install kubernetes.core
pip install kubernetes
```

### 3. Verificar instalación

```bash
ansible --version
ansible-galaxy collection list
```

## 🚀 Uso de los Playbooks

### Despliegue Completo

Despliega toda la infraestructura: MySQL, TaskManager, Elasticsearch, Kibana y Filebeat.

```bash
# Desde el directorio ansible/
ansible-playbook deploy-playbook.yml

# Con salida detallada
ansible-playbook deploy-playbook.yml -v

# Con verificación previa (dry-run)
ansible-playbook deploy-playbook.yml --check
```

### Limpieza de Recursos

Elimina todos los recursos del cluster.

```bash
# Desde el directorio ansible/
ansible-playbook cleanup-playbook.yml

# Con confirmación
ansible-playbook cleanup-playbook.yml -v
```

## 📊 Variables Configurables

Puedes personalizar el despliegue modificando las variables en `deploy-playbook.yml`:

```yaml
vars:
  namespace: cloudedu              # Namespace de Kubernetes
  app_name: taskmanager            # Nombre de la aplicación
  app_version: v1                  # Versión de la imagen
  elk_version: "8.11.0"           # Versión del ELK Stack
  docker_image: "cloudedu-taskmanager:v1"  # Imagen Docker
```

## 🔍 Verificación del Despliegue

Después de ejecutar el playbook de despliegue, verifica el estado:

```bash
# Ver todos los pods
kubectl get pods -n cloudedu

# Ver servicios
kubectl get svc -n cloudedu

# Ver logs de la aplicación
kubectl logs -n cloudedu -l app=taskmanager-app

# Ver logs de Filebeat
kubectl logs -n cloudedu -l app=filebeat
```

## 🌐 Acceso a Servicios

### TaskManager
```bash
kubectl port-forward -n cloudedu svc/taskmanager-app-service 30080:5000
# Acceder a: http://localhost:30080
```

### Kibana
```bash
kubectl port-forward -n cloudedu svc/kibana 5601:5601
# Acceder a: http://localhost:5601
```

### Elasticsearch
```bash
kubectl port-forward -n cloudedu svc/elasticsearch 9200:9200
# API disponible en: http://localhost:9200
```

## 🔧 Troubleshooting

### Error: "kubernetes.core collection not found"

```bash
ansible-galaxy collection install kubernetes.core
pip install kubernetes
```

### Error: "Unable to connect to the cluster"

Verifica que:
1. Minikube está corriendo: `minikube status`
2. kubectl funciona: `kubectl cluster-info`
3. Contexto configurado: `kubectl config current-context`

### Error: "Permission denied"

En Linux/MacOS, ejecuta con privilegios si es necesario:
```bash
sudo ansible-playbook deploy-playbook.yml
```

### Pods en CrashLoopBackOff

Verifica los logs:
```bash
kubectl logs -n cloudedu <pod-name>
kubectl describe pod -n cloudedu <pod-name>
```

## 📚 Comandos Útiles

```bash
# Listar hosts del inventario
ansible-inventory -i inventory.ini --list

# Probar conectividad
ansible localhost -i inventory.ini -m ping

# Ver variables disponibles
ansible localhost -i inventory.ini -m debug -a "var=hostvars"

# Sintaxis del playbook
ansible-playbook deploy-playbook.yml --syntax-check

# Listar tareas sin ejecutar
ansible-playbook deploy-playbook.yml --list-tasks

# Ejecutar solo ciertas tareas
ansible-playbook deploy-playbook.yml --tags "docker,kubernetes"
```

## 🎯 Ventajas de Usar Ansible

1. **Idempotencia**: Ejecutar el playbook múltiples veces produce el mismo resultado
2. **Declarativo**: Describes el estado deseado, no los pasos
3. **Modular**: Playbooks reutilizables y fáciles de mantener
4. **Auditable**: Todo el despliegue está en código versionado
5. **Reproducible**: Mismo resultado en cualquier entorno

## 📖 Referencias

- [Documentación de Ansible](https://docs.ansible.com/)
- [Ansible Kubernetes Collection](https://galaxy.ansible.com/kubernetes/core)
- [Kubernetes Module](https://docs.ansible.com/ansible/latest/collections/kubernetes/core/k8s_module.html)

---

**Proyecto:** Práctica Final InfraCloud  
**Equipo:** Manuel Botella, Carlos Gomez, Diego Rodriguez, Hugo Langenaeken, David Gonzalez  
**Fecha:** Diciembre 2025
