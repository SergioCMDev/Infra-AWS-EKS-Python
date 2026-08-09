# Infraestructura AWS EKS con CI/CD Blue-Green y Observabilidad

[![Terraform](https://img.shields.io/badge/Terraform-~>6.0-623CE4?logo=terraform&logoColor=white)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-EKS-FF9900?logo=amazon-aws&logoColor=white)](https://aws.amazon.com/eks/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.32-326CE5?logo=kubernetes&logoColor=white)](https://kubernetes.io/)
[![Python](https://img.shields.io/badge/Python-3.x-3776AB?logo=python&logoColor=white)](https://www.python.org/)
[![ArgoCD](https://img.shields.io/badge/ArgoCD-GitOps-EF7B4D?logo=argo&logoColor=white)](https://argoproj.github.io/cd/)

## Descripción

Este proyecto despliega una infraestructura completa sobre Amazon EKS en la región `eu-west-3`, con despliegue Blue-Green para la aplicación web del repositorio [PythonWebForIAC](https://github.com/SergioCMDev/PythonWebForIAC) y un flujo GitOps basado en ArgoCD. Además, incorpora una pila de observabilidad completa para EKS y Minikube con Prometheus, Grafana, Loki, Tempo y OpenTelemetry.

La infraestructura está organizada en módulos Terraform independientes y automatizada con scripts Bash para aplicar, validar y destruir los recursos de forma ordenada.

## Qué incluye la solución

- Infraestructura modular con Terraform: networking → eks → ecr → template_config
- Despliegue Blue-Green con weighted routing en ALB
- GitOps con ArgoCD para sincronizar recursos de Kubernetes desde el repositorio
- Integración con GitHub Actions mediante OIDC para publicar imágenes en ECR sin secrets estáticos
- Observabilidad lista para EKS y Minikube mediante ArgoCD Applications
- Soporte para desarrollo local con Minikube y scripts de instalación específicos

## Arquitectura resumida

```text
┌──────────────────────────────────────────────────────────────┐
│                       AWS Account (eu-west-3)               │
│                                                              │
│  ┌──────────────────────┐      ┌──────────────────────────┐  │
│  │   VPC / Networking    │      │   ECR / Image Registry   │  │
│  │  - Public subnets     │      │  - Python app images    │  │
│  │  - Private subnets    │      │  - OIDC + GitHub Actions │  │
│  │  - NAT / IGW / SGs    │      └──────────────────────────┘  │
│  └──────────┬───────────┘                                      │
│             │                                                  │
│  ┌──────────▼───────────┐                                      │
│  │        EKS Cluster    │                                      │
│  │  - Control plane      │                                      │
│  │  - Managed node group │                                      │
│  │  - Blue/Green apps    │                                      │
│  │  - ALB ingress        │                                      │
│  └──────────┬───────────┘                                      │
│             │                                                  │
│  ┌──────────▼───────────┐      ┌──────────────────────────┐     │
│  │   ArgoCD + GitOps     │      │   Observability Stack   │     │
│  │  - Sync manifests     │      │  - Prometheus/Grafana   │     │
│  │  - Self-heal          │      │  - Loki / Tempo         │     │
│  │  - Rollouts/Deploys   │      │  - Promtail / OTel      │     │
│  └──────────────────────┘      └──────────────────────────┘     │
│                                                              │
│  GitHub Actions ──OIDC──► ECR push + SSM parameter updates   │
└──────────────────────────────────────────────────────────────┘
```

## Estructura del repositorio

```text
.
├── infra/                      # Módulos Terraform y scripts de despliegue
│   ├── 1-networking/
│   ├── 2-eks/
│   ├── 3-ecr/
│   ├── 4-template_config/
│   └── infra_scripts/
├── k8s/                        # Manifiestos y scripts de Kubernetes
│   ├── manifests/
│   ├── k8s_fixed_scripts/
│   └── values/
└── observability/              # Aplicaciones ArgoCD y configuraciones de observabilidad
```

## Requisitos previos

- Terraform >= 1.0
- AWS CLI configurado con permisos administrativos o suficientes para VPC, EKS, IAM, ECR y S3
- kubectl
- Helm
- jq
- Acceso a un repositorio GitHub para los manifiestos de ArgoCD

## Despliegue en AWS EKS

### 1. Clonar el repositorio

```bash
git clone https://github.com/SergioCMDev/Infra-AWS-EKS-Python.git
cd Infra-AWS-EKS-Python
```

### 2. Preparar el backend remoto de Terraform

Asegúrate de que el bucket de S3 exista antes de inicializar los módulos:

```bash
aws s3api create-bucket \
  --bucket my-terraform-project-bucket-aws-tokio-2 \
  --region eu-west-3 \
  --create-bucket-configuration LocationConstraint=eu-west-3
```

### 3. Aplicar la infraestructura

```bash
cd infra/infra_scripts
bash apply_all.sh
```

También puedes ejecutarlo módulo a módulo:

```bash
bash apply_networking.sh
bash apply_eks.sh
bash apply_ecr.sh
bash apply_template_config.sh
```

### 4. Post-instalación

Una vez que el clúster esté disponible, ejecuta el script renderizado generado por el módulo de configuración:

```bash
cd infra/4-template_config/rendered/scripts
bash install-alb-k8s-manifests-argocd.sh
```

Este paso instala:
- AWS Load Balancer Controller
- Los manifiestos de la aplicación Blue/Green
- ArgoCD
- Roles IAM para los recursos del clúster

### 5. Verificar el estado

```bash
aws eks update-kubeconfig --region eu-west-3 --name mi-cluster
kubectl get nodes
kubectl get pods -A
```

## Estrategia Blue-Green

El tráfico se gestiona por pesos en el ingress mediante ALB. Los deployments Blue y Green coexisten en el clúster y el cambio de tráfico se controla con un script helper.

### Cambiar pesos de tráfico

```bash
# 100% Blue (rollback)
bash k8s/k8s_fixed_scripts/blue-green-updater.sh default <ingress-name> 100 0

# 100% Green
bash k8s/k8s_fixed_scripts/blue-green-updater.sh default <ingress-name> 0 100

# Canary: 80/20
bash k8s/k8s_fixed_scripts/blue-green-updater.sh default <ingress-name> 80 20
```

> Los pesos deben sumar 100.

## Observabilidad

La pila de observabilidad se despliega con ArgoCD y está preparada para EKS y Minikube.

### EKS

```bash
bash k8s/k8s_fixed_scripts/install-observability-eks.sh
```

### Minikube

```bash
bash k8s/k8s_fixed_scripts/install-observability-minikube.sh
```

Los componentes incluidos son:
- Prometheus + Grafana
- Loki
- Tempo
- Promtail
- OpenTelemetry Collector

## Desarrollo local con Minikube

```bash
minikube start
bash k8s/k8s_fixed_scripts/install-argocd-minikube.sh
bash k8s/k8s_fixed_scripts/Applying-k8s-manifests-minikube.sh
bash k8s/k8s_fixed_scripts/install-observability-minikube.sh
```

Para acceder a la UI de ArgoCD puedes hacer port-forward:

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

## Limpieza de recursos

### Destruir por módulos

```bash
cd infra/infra_scripts
bash destroy_template_config.sh
bash destroy_ecr.sh
bash destroy_eks.sh
bash destroy_networking.sh
```

### Destruir todo

```bash
bash destroy_all.sh
```

> Advertencia: este paso elimina los recursos creados en AWS.

## Notas importantes

- El proyecto está pensado como base para despliegues reales, pero aún puede requerir ajustes de nombres, regiones y permisos según el entorno.
- La instalación de observabilidad depende de que ArgoCD esté operativo y de que los recursos del cluster estén disponibles.
- Para entornos productivos, se recomienda añadir bloqueo de estado, políticas de seguridad adicionales y validaciones automáticas en CI.

## Autor

Sergio Cristauro Manzano

- LinkedIn: https://www.linkedin.com/in/sergio-cristauro-manzano/
- Email: sergiocmdev@gmail.com
