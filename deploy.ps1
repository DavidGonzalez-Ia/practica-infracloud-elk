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

Write-Host ""
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
Write-Host "=========================================" -ForegroundColor Green