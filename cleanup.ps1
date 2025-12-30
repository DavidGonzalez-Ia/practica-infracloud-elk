# Script de Limpieza - CloudEdu TaskManager + ELK Stack
# Autores: Manuel Botella, Carlos Gomez, Diego Rodriguez, Hugo Langenaeken, David Gonzalez
# Fecha: Diciembre 2025

Write-Host "=========================================" -ForegroundColor Red
Write-Host "CloudEdu TaskManager + ELK - Limpieza" -ForegroundColor Red
Write-Host "=========================================" -ForegroundColor Red
Write-Host ""

$NAMESPACE = "cloudedu"

Write-Host "⚠️  ADVERTENCIA: Esto eliminará todos los recursos del proyecto (App + ELK Stack)" -ForegroundColor Yellow
Write-Host ""
$confirmation = Read-Host "¿Estás seguro de que quieres continuar? (S/N)"

if ($confirmation -ne 'S' -and $confirmation -ne 's') {
    Write-Host "Operación cancelada" -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "[1/4] Eliminando aplicaciones y servicios..." -ForegroundColor Yellow
kubectl delete -f kubernetes/app-service.yaml --ignore-not-found=true 2>&1 | Out-Null
kubectl delete -f kubernetes/app-deployment.yaml --ignore-not-found=true 2>&1 | Out-Null
kubectl delete -f kubernetes/filebeat-daemonset.yaml --ignore-not-found=true 2>&1 | Out-Null
kubectl delete -f kubernetes/kibana-deployment.yaml --ignore-not-found=true 2>&1 | Out-Null
kubectl delete -f kubernetes/elasticsearch-deployment.yaml --ignore-not-found=true 2>&1 | Out-Null
Write-Host "✓ Aplicaciones eliminadas" -ForegroundColor Green

Write-Host "[2/4] Eliminando namespace '$NAMESPACE'..." -ForegroundColor Yellow
kubectl delete namespace $NAMESPACE --ignore-not-found=true 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Namespace eliminado" -ForegroundColor Green
}

Write-Host "[3/4] Eliminando Persistent Volume..." -ForegroundColor Yellow
kubectl delete pv mysql-pv --ignore-not-found=true 2>&1 | Out-Null
kubectl delete pv elasticsearch-pv --ignore-not-found=true 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Persistent Volumes eliminados" -ForegroundColor Green
}

Write-Host "[4/4] Eliminando ClusterRoles..." -ForegroundColor Yellow
kubectl delete clusterrole cloudedu-admin --ignore-not-found=true 2>&1 | Out-Null
kubectl delete clusterrole cloudedu-developer --ignore-not-found=true 2>&1 | Out-Null
kubectl delete clusterrole filebeat --ignore-not-found=true 2>&1 | Out-Null
kubectl delete clusterrolebinding filebeat --ignore-not-found=true 2>&1 | Out-Null
Write-Host "✓ ClusterRoles eliminados" -ForegroundColor Green

Write-Host ""
Write-Host "=========================================" -ForegroundColor Green
Write-Host "✓ Limpieza completada" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green