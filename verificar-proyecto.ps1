# Script de Verificación Completa del Proyecto CloudEdu TaskManager
# Este script verifica TODOS los requisitos del PDF

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "VERIFICACIÓN COMPLETA DEL PROYECTO" -ForegroundColor Cyan
Write-Host "CloudEdu TaskManager" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

$errores = 0
$warnings = 0
$total = 0

function Test-Requisito {
    param(
        [string]$Nombre,
        [scriptblock]$Test,
        [string]$Critico = $false
    )
    
    $script:total++
    Write-Host "[$script:total] Verificando: $Nombre" -ForegroundColor Yellow
    
    try {
        $resultado = & $Test
        if ($resultado) {
            Write-Host "    ✓ CUMPLE" -ForegroundColor Green
            return $true
        } else {
            if ($Critico) {
                Write-Host "    ✗ FALLO CRÍTICO" -ForegroundColor Red
                $script:errores++
            } else {
                Write-Host "    ⚠ WARNING" -ForegroundColor Yellow
                $script:warnings++
            }
            return $false
        }
    } catch {
        Write-Host "    ✗ ERROR: $($_.Exception.Message)" -ForegroundColor Red
        $script:errores++
        return $false
    }
}

Write-Host ""
Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
Write-Host "1. ESTRUCTURA DE ARCHIVOS" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan

Test-Requisito "Archivo app/app.py" { Test-Path "app/app.py" } -Critico $true
Test-Requisito "Archivo app/Dockerfile" { Test-Path "app/Dockerfile" } -Critico $true
Test-Requisito "Archivo app/requirements.txt" { Test-Path "app/requirements.txt" } -Critico $true
Test-Requisito "Archivo app/templates/index.html" { Test-Path "app/templates/index.html" } -Critico $true

Test-Requisito "Archivo kubernetes/namespace.yaml" { Test-Path "kubernetes/namespace.yaml" } -Critico $true
Test-Requisito "Archivo kubernetes/mysql-pv.yaml" { Test-Path "kubernetes/mysql-pv.yaml" } -Critico $true
Test-Requisito "Archivo kubernetes/mysql-deployment.yaml" { Test-Path "kubernetes/mysql-deployment.yaml" } -Critico $true
Test-Requisito "Archivo kubernetes/mysql-service.yaml" { Test-Path "kubernetes/mysql-service.yaml" } -Critico $true
Test-Requisito "Archivo kubernetes/app-deployment.yaml" { Test-Path "kubernetes/app-deployment.yaml" } -Critico $true
Test-Requisito "Archivo kubernetes/app-service.yaml" { Test-Path "kubernetes/app-service.yaml" } -Critico $true
Test-Requisito "Archivo kubernetes/rbac.yaml" { Test-Path "kubernetes/rbac.yaml" } -Critico $true

Test-Requisito "Archivo ansible/inventory.ini" { Test-Path "ansible/inventory.ini" }
Test-Requisito "Archivo ansible/playbook.yml" { Test-Path "ansible/playbook.yml" }
Test-Requisito "Archivo ansible/cleanup-playbook.yml" { Test-Path "ansible/cleanup-playbook.yml" }

Test-Requisito "Script deploy.ps1" { Test-Path "deploy.ps1" } -Critico $true
Test-Requisito "Script cleanup.ps1" { Test-Path "cleanup.ps1" }

Test-Requisito "Archivo README.md" { Test-Path "README.md" } -Critico $true
Test-Requisito "Archivo .gitignore" { Test-Path ".gitignore" }

Test-Requisito "Archivo docs/arquitectura.md" { Test-Path "docs/arquitectura.md" } -Critico $true
Test-Requisito "Archivo docs/reflexion-final.md" { Test-Path "docs/reflexion-final.md" } -Critico $true
Test-Requisito "Carpeta docs/evidencias/" { Test-Path "docs/evidencias" }

Write-Host ""
Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
Write-Host "2. DOCKER" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan

Test-Requisito "Docker instalado" {
    $null = docker --version 2>&1
    return $LASTEXITCODE -eq 0
} -Critico $true

Test-Requisito "Imagen cloudedu-taskmanager:v1 existe" {
    $imagen = docker images cloudedu-taskmanager:v1 --format "{{.Repository}}:{{.Tag}}" 2>&1
    return $imagen -like "*cloudedu-taskmanager:v1*"
} -Critico $true

Test-Requisito "Dockerfile NO usa nginx:latest" {
    $contenido = Get-Content "app/Dockerfile" -Raw
    return $contenido -notlike "*FROM nginx*"
} -Critico $true

Test-Requisito "Dockerfile usa imagen personalizada" {
    $contenido = Get-Content "app/Dockerfile" -Raw
    return $contenido -like "*FROM python*"
} -Critico $true

Write-Host ""
Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
Write-Host "3. KUBERNETES" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan

Test-Requisito "kubectl instalado" {
    $null = kubectl version --client 2>&1
    return $LASTEXITCODE -eq 0
} -Critico $true

Test-Requisito "Cluster Kubernetes accesible" {
    $null = kubectl cluster-info 2>&1
    return $LASTEXITCODE -eq 0
} -Critico $true

Test-Requisito "Namespace 'cloudedu' existe" {
    $ns = kubectl get namespace cloudedu 2>&1
    return $LASTEXITCODE -eq 0
} -Critico $true

Test-Requisito "Deployment MySQL existe" {
    $deploy = kubectl get deployment mysql -n cloudedu 2>&1
    return $LASTEXITCODE -eq 0
} -Critico $true

Test-Requisito "Deployment App existe" {
    $deploy = kubectl get deployment taskmanager-app -n cloudedu 2>&1
    return $LASTEXITCODE -eq 0
} -Critico $true

Test-Requisito "Pods están Running" {
    $pods = kubectl get pods -n cloudedu -o json | ConvertFrom-Json
    $running = $pods.items | Where-Object { $_.status.phase -eq "Running" }
    return $running.Count -ge 2
} -Critico $true

Test-Requisito "Service NodePort existe" {
    $svc = kubectl get svc taskmanager-service -n cloudedu -o json 2>&1 | ConvertFrom-Json
    return $svc.spec.type -eq "NodePort"
} -Critico $true

Test-Requisito "Service expuesto en puerto 30080" {
    $svc = kubectl get svc taskmanager-service -n cloudedu -o json 2>&1 | ConvertFrom-Json
    $nodePort = $svc.spec.ports[0].nodePort
    return $nodePort -eq 30080
} -Critico $true

Write-Host ""
Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
Write-Host "4. ALMACENAMIENTO PERSISTENTE" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan

Test-Requisito "PersistentVolume existe" {
    $pv = kubectl get pv mysql-pv 2>&1
    return $LASTEXITCODE -eq 0
} -Critico $true

Test-Requisito "PersistentVolumeClaim existe" {
    $pvc = kubectl get pvc mysql-pvc -n cloudedu 2>&1
    return $LASTEXITCODE -eq 0
} -Critico $true

Test-Requisito "PVC está Bound" {
    $pvc = kubectl get pvc mysql-pvc -n cloudedu -o json 2>&1 | ConvertFrom-Json
    return $pvc.status.phase -eq "Bound"
}

Write-Host ""
Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
Write-Host "5. SEGURIDAD (RBAC)" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan

Test-Requisito "ServiceAccount existe" {
    $sa = kubectl get sa taskmanager-sa -n cloudedu 2>&1
    return $LASTEXITCODE -eq 0
} -Critico $true

Test-Requisito "Role existe" {
    $role = kubectl get role taskmanager-role -n cloudedu 2>&1
    return $LASTEXITCODE -eq 0
} -Critico $true

Test-Requisito "RoleBinding existe" {
    $rb = kubectl get rolebinding taskmanager-rolebinding -n cloudedu 2>&1
    return $LASTEXITCODE -eq 0
} -Critico $true

Test-Requisito "ClusterRole cloudedu-admin existe" {
    $cr = kubectl get clusterrole cloudedu-admin 2>&1
    return $LASTEXITCODE -eq 0
}

Test-Requisito "ClusterRole cloudedu-developer existe" {
    $cr = kubectl get clusterrole cloudedu-developer 2>&1
    return $LASTEXITCODE -eq 0
}

Write-Host ""
Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
Write-Host "6. DOCUMENTACIÓN" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan

Test-Requisito "README.md contiene 'Arquitectura'" {
    $readme = Get-Content "README.md" -Raw
    return $readme -like "*Arquitectura*"
} -Critico $true

Test-Requisito "README.md contiene 'Instrucciones'" {
    $readme = Get-Content "README.md" -Raw
    return $readme -like "*Instrucciones*"
} -Critico $true

Test-Requisito "README.md contiene 'RBAC'" {
    $readme = Get-Content "README.md" -Raw
    return $readme -like "*RBAC*"
} -Critico $true

Test-Requisito "arquitectura.md existe y tiene contenido" {
    if (Test-Path "docs/arquitectura.md") {
        $arq = Get-Content "docs/arquitectura.md" -Raw
        return $arq.Length -gt 1000
    }
    return $false
} -Critico $true

Test-Requisito "reflexion-final.md contiene 'Decisiones'" {
    if (Test-Path "docs/reflexion-final.md") {
        $ref = Get-Content "docs/reflexion-final.md" -Raw
        return $ref -like "*Decisiones*"
    }
    return $false
} -Critico $true

Test-Requisito "reflexion-final.md contiene 'Dificultades'" {
    if (Test-Path "docs/reflexion-final.md") {
        $ref = Get-Content "docs/reflexion-final.md" -Raw
        return $ref -like "*Dificultades*"
    }
    return $false
} -Critico $true

Test-Requisito "reflexion-final.md contiene 'Aprendizaje'" {
    if (Test-Path "docs/reflexion-final.md") {
        $ref = Get-Content "docs/reflexion-final.md" -Raw
        return $ref -like "*Aprendizaje*"
    }
    return $false
} -Critico $true

Write-Host ""
Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
Write-Host "7. FUNCIONAMIENTO" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan

Test-Requisito "Aplicación responde en localhost:30080" {
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:30080" -TimeoutSec 5 -UseBasicParsing
        return $response.StatusCode -eq 200
    } catch {
        return $false
    }
} -Critico $true

Test-Requisito "Endpoint /health responde" {
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:30080/health" -TimeoutSec 5 -UseBasicParsing
        return $response.StatusCode -eq 200
    } catch {
        return $false
    }
}

Write-Host ""
Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
Write-Host "8. REQUISITOS OPCIONALES" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan

Test-Requisito "Git inicializado" {
    return Test-Path ".git"
}

Test-Requisito "Carpeta de evidencias existe" {
    return Test-Path "docs/evidencias"
}

Test-Requisito "Evidencias contiene capturas" {
    if (Test-Path "docs/evidencias") {
        $capturas = Get-ChildItem "docs/evidencias" -Filter "*.png"
        return $capturas.Count -gt 0
    }
    return $false
}

Write-Host ""
Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
Write-Host "RESUMEN DE VERIFICACIÓN" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

$aprobados = $total - $errores - $warnings

Write-Host "Total de pruebas: $total" -ForegroundColor White
Write-Host "✓ Aprobadas: $aprobados" -ForegroundColor Green
Write-Host "⚠ Warnings: $warnings" -ForegroundColor Yellow
Write-Host "✗ Errores críticos: $errores" -ForegroundColor Red
Write-Host ""

$porcentaje = [math]::Round(($aprobados / $total) * 100, 2)
Write-Host "Porcentaje de cumplimiento: $porcentaje%" -ForegroundColor Cyan

Write-Host ""
if ($errores -eq 0) {
    Write-Host "═══════════════════════════════════════" -ForegroundColor Green
    Write-Host "✓ PROYECTO LISTO PARA ENTREGAR" -ForegroundColor Green
    Write-Host "═══════════════════════════════════════" -ForegroundColor Green
    Write-Host ""
    Write-Host "Todos los requisitos CRÍTICOS están cumplidos." -ForegroundColor Green
    
    if ($warnings -gt 0) {
        Write-Host ""
        Write-Host "Tareas pendientes (opcionales):" -ForegroundColor Yellow
        Write-Host "  - Tomar capturas de pantalla en docs/evidencias/" -ForegroundColor Yellow
        Write-Host "  - Inicializar repositorio Git (opcional)" -ForegroundColor Yellow
    }
} else {
    Write-Host "═══════════════════════════════════════" -ForegroundColor Red
    Write-Host "✗ HAY ERRORES CRÍTICOS" -ForegroundColor Red
    Write-Host "═══════════════════════════════════════" -ForegroundColor Red
    Write-Host ""
    Write-Host "Por favor, revisa los errores marcados arriba." -ForegroundColor Red
}

Write-Host ""
Write-Host "Para más detalles, revisa cada sección marcada con ✗" -ForegroundColor White
Write-Host ""