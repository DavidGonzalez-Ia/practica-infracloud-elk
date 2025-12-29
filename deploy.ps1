# Script de Despliegue Automatizado - CloudEdu TaskManager
# Este script automatiza todo el proceso de despliegue (equivalente a IaC con Ansible)

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "CloudEdu TaskManager - Despliegue Automatizado" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Variables
$NAMESPACE = "cloudedu"
$DOCKER_IMAGE = "cloudedu-taskmanager:v1"
$APP_DIR = "app"
$K8S_DIR = "kubernetes"
$DEPLOY_ELK = $true  # Controlar despliegue de ELK Stack

# Función para verificar comandos
function Test-Command {
    param($CommandName)
    $null = Get-Command $CommandName -ErrorAction SilentlyContinue
    return $?
}

# Verificar Docker
Write-Host "[1/10] Verificando Docker..." -ForegroundColor Yellow
if (Test-Command "docker") {
    $dockerVersion = docker --version
    Write-Host "✓ Docker encontrado: $dockerVersion" -ForegroundColor Green
} else {
    Write-Host "✗ Error: Docker no está instalado" -ForegroundColor Red
    exit 1
}

# Verificar kubectl
Write-Host "[2/10] Verificando kubectl..." -ForegroundColor Yellow
if (Test-Command "kubectl") {
    $kubectlVersion = kubectl version --client --short 2>$null
    Write-Host "✓ kubectl encontrado: $kubectlVersion" -ForegroundColor Green
} else {
    Write-Host "✗ Error: kubectl no está instalado" -ForegroundColor Red
    exit 1
}

# Verificar cluster de Kubernetes
Write-Host "[3/10] Verificando conexión al cluster..." -ForegroundColor Yellow
$clusterInfo = kubectl cluster-info 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Cluster de Kubernetes accesible" -ForegroundColor Green
} else {
    Write-Host "✗ Error: No se puede conectar al cluster de Kubernetes" -ForegroundColor Red
    exit 1
}

# Construir imagen Docker
Write-Host "[4/10] Construyendo imagen Docker..." -ForegroundColor Yellow
Push-Location $APP_DIR
docker build -t $DOCKER_IMAGE . 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Imagen Docker construida: $DOCKER_IMAGE" -ForegroundColor Green
} else {
    Write-Host "✗ Error al construir la imagen Docker" -ForegroundColor Red
    Pop-Location
    exit 1
}
Pop-Location

# Verificar que la imagen existe
Write-Host "[5/10] Verificando imagen Docker..." -ForegroundColor Yellow
$imageExists = docker images $DOCKER_IMAGE --format "{{.Repository}}:{{.Tag}}"
if ($imageExists) {
    Write-Host "✓ Imagen verificada: $imageExists" -ForegroundColor Green
} else {
    Write-Host "✗ Error: La imagen no se encuentra" -ForegroundColor Red
    exit 1
}

# Detectar si estamos usando Minikube y cargar la imagen
$currentContext = kubectl config current-context 2>$null
if ($currentContext -eq "minikube") {
    Write-Host "[5.5/10] Detectado Minikube - Cargando imagen en Minikube..." -ForegroundColor Yellow
    minikube image load $DOCKER_IMAGE 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Imagen cargada en Minikube" -ForegroundColor Green
    } else {
        Write-Host "⚠ Advertencia: No se pudo cargar la imagen en Minikube" -ForegroundColor Yellow
    }
}

# Crear namespace
Write-Host "[6/10] Creando namespace '$NAMESPACE'..." -ForegroundColor Yellow
kubectl apply -f "$K8S_DIR/namespace.yaml" | Out-Null
Write-Host "✓ Namespace creado/actualizado" -ForegroundColor Green

# Aplicar Persistent Volume
Write-Host "[7/10] Configurando almacenamiento persistente..." -ForegroundColor Yellow
kubectl apply -f "$K8S_DIR/mysql-pv.yaml" | Out-Null
Write-Host "✓ Persistent Volume configurado" -ForegroundColor Green

# Desplegar MySQL
Write-Host "[8/10] Desplegando MySQL..." -ForegroundColor Yellow
kubectl apply -f "$K8S_DIR/mysql-deployment.yaml" | Out-Null
kubectl apply -f "$K8S_DIR/mysql-service.yaml" | Out-Null
Write-Host "✓ MySQL desplegado" -ForegroundColor Green

# Aplicar RBAC
Write-Host "[9/10] Configurando permisos y roles (RBAC)..." -ForegroundColor Yellow
kubectl apply -f "$K8S_DIR/rbac.yaml" | Out-Null
Write-Host "✓ RBAC configurado" -ForegroundColor Green

# Desplegar aplicación
Write-Host "[10/10] Desplegando aplicación TaskManager..." -ForegroundColor Yellow
kubectl apply -f "$K8S_DIR/app-deployment.yaml" | Out-Null
kubectl apply -f "$K8S_DIR/app-service.yaml" | Out-Null
Write-Host "✓ Aplicación desplegada" -ForegroundColor Green

# Desplegar ELK Stack si está habilitado
if ($DEPLOY_ELK) {
    Write-Host "[11/12] Desplegando ELK Stack (Elasticsearch, Logstash, Kibana)..." -ForegroundColor Yellow
    
    # Crear ConfigMaps para ELK
    kubectl apply -f "$K8S_DIR/elk-config.yaml" | Out-Null
    Write-Host "✓ Configuración de ELK creada" -ForegroundColor Green
    
    # Desplegar Elasticsearch
    Write-Host "Desplegando Elasticsearch..." -ForegroundColor Yellow
    kubectl apply -f "$K8S_DIR/elasticsearch-deployment.yaml" | Out-Null
    Write-Host "✓ Elasticsearch desplegado" -ForegroundColor Green
    
    # Esperar a que Elasticsearch esté listo
    Write-Host "Esperando Elasticsearch..." -ForegroundColor Yellow
    kubectl wait --for=condition=ready pod -l app=elasticsearch -n $NAMESPACE --timeout=120s 2>&1 | Out-Null
    Write-Host "✓ Elasticsearch listo" -ForegroundColor Green
    
    # Desplegar Logstash
    Write-Host "Desplegando Logstash..." -ForegroundColor Yellow
    kubectl apply -f "$K8S_DIR/logstash-deployment.yaml" | Out-Null
    Write-Host "✓ Logstash desplegado" -ForegroundColor Green
    
    # Desplegar Kibana
    Write-Host "Desplegando Kibana..." -ForegroundColor Yellow
    kubectl apply -f "$K8S_DIR/kibana-deployment.yaml" | Out-Null
    Write-Host "✓ Kibana desplegado" -ForegroundColor Green
    
    # Desplegar Filebeat
    Write-Host "Desplegando Filebeat..." -ForegroundColor Yellow
    kubectl apply -f "$K8S_DIR/filebeat-deployment.yaml" | Out-Null
    Write-Host "✓ Filebeat desplegado" -ForegroundColor Green
}

Write-Host "[12/12] Completado" -ForegroundColor Yellow

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Esperando a que los pods estén listos..." -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Esperar a que MySQL esté listo
Write-Host "Esperando MySQL..." -ForegroundColor Yellow
kubectl wait --for=condition=ready pod -l app=mysql -n $NAMESPACE --timeout=120s 2>&1 | Out-Null

# Esperar a que la app esté lista
Write-Host "Esperando aplicación TaskManager..." -ForegroundColor Yellow
kubectl wait --for=condition=ready pod -l app=taskmanager -n $NAMESPACE --timeout=120s 2>&1 | Out-Null

Write-Host "=========================================" -ForegroundColor Green
Write-Host "✓ Despliegue completado exitosamente" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
Write-Host ""

# Mostrar estado
Write-Host "Estado de los pods:" -ForegroundColor Cyan
kubectl get pods -n $NAMESPACE
Write-Host ""

Write-Host "Servicios:" -ForegroundColor Cyan
kubectl get svc -n $NAMESPACE
Write-Host ""

Write-Host "=========================================" -ForegroundColor Green
Write-Host "🎉 Aplicación disponible en:" -ForegroundColor Green
Write-Host "   http://localhost:30080" -ForegroundColor Yellow
if ($DEPLOY_ELK) {
    Write-Host ""
    Write-Host "📊 Kibana disponible en:" -ForegroundColor Yellow
    Write-Host "   http://localhost:30601" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Instrucciones para Kibana:" -ForegroundColor Cyan
    Write-Host "1. Accede a http://localhost:30601" -ForegroundColor White
    Write-Host "2. Ve a 'Stack Management' > 'Index Patterns'" -ForegroundColor White
    Write-Host "3. Crea un patrón de índice para 'logs-*'" -ForegroundColor White
    Write-Host "4. Ve al 'Discover' tab para ver los logs" -ForegroundColor White
}
Write-Host "=========================================" -ForegroundColor Green