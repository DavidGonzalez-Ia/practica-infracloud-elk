# Script de Limpieza - CloudEdu TaskManager

Write-Host "=========================================" -ForegroundColor Red
Write-Host "CloudEdu TaskManager - Limpieza" -ForegroundColor Red
Write-Host "=========================================" -ForegroundColor Red
Write-Host ""

$NAMESPACE = "cloudedu"

Write-Host "⚠️  ADVERTENCIA: Esto eliminará todos los recursos del proyecto" -ForegroundColor Yellow
Write-Host ""
$confirmation = Read-Host "¿Estás seguro de que quieres continuar? (S/N)"

if ($confirmation -ne 'S' -and $confirmation -ne 's') {
    Write-Host "Operación cancelada" -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "[1/3] Eliminando namespace '$NAMESPACE'..." -ForegroundColor Yellow
kubectl delete namespace $NAMESPACE --ignore-not-found=true 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Namespace eliminado" -ForegroundColor Green
}

Write-Host "[2/3] Eliminando Persistent Volume..." -ForegroundColor Yellow
kubectl delete pv mysql-pv --ignore-not-found=true 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Persistent Volume eliminado" -ForegroundColor Green
}

Write-Host "[3/3] Eliminando ClusterRoles..." -ForegroundColor Yellow
kubectl delete clusterrole cloudedu-admin --ignore-not-found=true 2>&1 | Out-Null
kubectl delete clusterrole cloudedu-developer --ignore-not-found=true 2>&1 | Out-Null
Write-Host "✓ ClusterRoles eliminados" -ForegroundColor Green

Write-Host ""
Write-Host "=========================================" -ForegroundColor Green
Write-Host "✓ Limpieza completada" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green