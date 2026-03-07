# Infraestructura AWS EKS con CI/CD Blue-Green

[![Terraform](https://img.shields.io/badge/Terraform-~>6.0-623CE4?logo=terraform&logoColor=white)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-EKS-FF9900?logo=amazon-aws&logoColor=white)](https://aws.amazon.com/eks/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.32-326CE5?logo=kubernetes&logoColor=white)](https://kubernetes.io/)
[![Python](https://img.shields.io/badge/Python-3.x-3776AB?logo=python&logoColor=white)](https://www.python.org/)
[![ArgoCD](https://img.shields.io/badge/ArgoCD-GitOps-EF7B4D?logo=argo&logoColor=white)](https://argoproj.github.io/cd/)

## Descripción

Proyecto de infraestructura como código (IaC) que despliega un clúster **Amazon EKS** completo en la región `eu-west-3` (París) utilizando **Terraform**, con despliegue **Blue-Green** gestionado por **ArgoCD** y **GitHub Actions** para una aplicación web Python: [PythonWebForIAC](https://github.com/SergioCMDev/PythonWebForIAC/).

La infraestructura se organiza en cuatro módulos Terraform independientes y ordenados, con scripts de automatización para aplicarlos de forma secuencial.

## Arquitectura

```
┌──────────────────────────────────────────────────────────────────┐
│                           AWS Cloud (eu-west-3)                  │
│                                                                   │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                   VPC (124.0.0.0/16)                      │  │
│  │                                                            │  │
│  │  ┌─────────────────────┐    ┌────────────────────────┐   │  │
│  │  │   Subnets Públicas   │    │   Subnets Privadas      │   │  │
│  │  │  eu-west-3a / 3b    │    │  eu-west-3a / 3b        │   │  │
│  │  │                      │    │                          │   │  │
│  │  │  - Internet Gateway  │NAT │  - EKS Node Group       │   │  │
│  │  │  - ALB (Ingress)     │───►│    (t3.medium, 1-8)     │   │  │
│  │  └─────────────────────┘    └────────────────────────┘   │  │
│  │                                                            │  │
│  │  ┌─────────────────────────────────────────────────────┐ │  │
│  │  │               EKS Cluster (Kubernetes 1.32)          │ │  │
│  │  │                                                       │ │  │
│  │  │    ┌────────────┐  ALB weighted  ┌────────────┐     │ │  │
│  │  │    │  Blue (3)  │◄──────────────►│  Green (3) │     │ │  │
│  │  │    │  replicas  │   routing      │  replicas  │     │ │  │
│  │  │    └────────────┘                └────────────┘     │ │  │
│  │  │                                                       │ │  │
│  │  │    addons: vpc-cni · kube-proxy · coredns            │ │  │
│  │  └─────────────────────────────────────────────────────┘ │  │
│  │                                                            │  │
│  │  ┌─────────────────────┐    ┌────────────────────────┐   │  │
│  │  │   ECR Repository    │    │   ArgoCD (in-cluster)  │   │  │
│  │  │  python_web_app     │    │   GitOps CD            │   │  │
│  │  │  (ENHANCED scan)    │    │                        │   │  │
│  │  └─────────────────────┘    └────────────────────────┘   │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                   │
│  GitHub Actions ──OIDC──► ECR push + SSM parameter update       │
└──────────────────────────────────────────────────────────────────┘
```

## Características Principales

- **Infraestructura modular**: 4 módulos Terraform independientes y ordenados (`networking` → `eks` → `ecr` → `template_config`)
- **Despliegue Blue-Green**: Zero-downtime con pesos de tráfico configurables via ALB weighted routing
- **GitOps con ArgoCD**: ArgoCD instalado en el clúster gestiona los manifiestos K8s desde el repositorio
- **CI/CD sin credenciales estáticas**: OIDC para GitHub Actions → ECR push sin secrets de larga duración
- **ECR con escaneo ENHANCED**: Análisis de vulnerabilidades en cada push de imagen
- **Seguridad en capas**: Security groups granulares por componente (ALB/NLB, cluster, workers)
- **Kustomize multi-entorno**: Overlays diferenciados para EKS y Minikube
- **Templates Terraform**: Generación automática de scripts, valores Helm y service accounts con variables del estado

## Tecnologías Utilizadas

### Infraestructura & Cloud
| Herramienta | Uso |
|---|---|
| **Terraform ~> 6.0 (AWS provider)** | Infraestructura como código |
| **AWS EKS** (Kubernetes 1.32) | Clúster gestionado |
| **AWS VPC** | Red aislada multi-AZ (eu-west-3a/3b) |
| **AWS ALB** (AWS Load Balancer Controller) | Ingress con weighted routing Blue-Green |
| **AWS ECR** | Registro privado de imágenes Docker |
| **AWS S3** | Backend remoto de estado Terraform |
| **AWS SSM Parameter Store** | Paso de parámetros entre pipeline y clúster |
| **OIDC (GitHub + EKS)** | Autenticación federada sin credenciales estáticas |

### Contenedores & Orquestación
| Herramienta | Uso |
|---|---|
| **Kubernetes 1.32** | Orquestación de contenedores |
| **ArgoCD** | GitOps Continuous Delivery |
| **Helm** | Instalación de ALB Controller y ArgoCD |
| **Kustomize** | Gestión de manifiestos multi-entorno |
| **Docker** | Containerización de la aplicación |

### CI/CD & Automatización
| Herramienta | Uso |
|---|---|
| **GitHub Actions** | Pipeline CI/CD (build → push → deploy) |
| **Bash Scripts** | Automatización de apply/destroy por módulo |

## Estructura del Proyecto

```
.
├── infra/                          # Infraestructura Terraform
│   ├── main.tf                     # Configuración raíz (AWS provider ~> 6.0)
│   ├── provider.tf
│   ├── variables.tf                # Variables globales (región: eu-west-3, env: dev)
│   │
│   ├── 1-networking/               # Módulo 1: Red
│   │   ├── vpc.tf                  # VPC (124.0.0.0/16, DNS habilitado)
│   │   ├── public_network.tf       # Subnets públicas (eu-west-3a/3b)
│   │   ├── private_networks.tf     # Subnets privadas (eu-west-3a/3b)
│   │   ├── gateway.tf              # Internet Gateway
│   │   ├── nat.tf                  # NAT Gateway
│   │   ├── public_routes.tf        # Tabla de rutas públicas
│   │   ├── private_routes.tf       # Tabla de rutas privadas
│   │   ├── security_alb_nlb_ssm.tf # Security groups para ALB/NLB/SSM
│   │   ├── security_cluster.tf     # Security group del control plane EKS
│   │   └── security_workers.tf     # Security group de los worker nodes
│   │
│   ├── 2-eks/                      # Módulo 2: Clúster EKS
│   │   ├── eks_cluster.tf          # Cluster + Node Group (t3.medium, 1-8 nodos)
│   │   ├── eks_roles.tf            # IAM roles del control plane
│   │   ├── workers_roles.tf        # IAM roles de los worker nodes
│   │   ├── oidc.tf                 # OIDC provider del clúster EKS
│   │   ├── alb_role.tf             # IAM role para AWS Load Balancer Controller
│   │   ├── argocd_role.tf          # IAM role para ArgoCD (pull ECR via IRSA)
│   │   ├── pods_roles.tf           # IAM roles adicionales para pods
│   │   └── iam_policies/
│   │       └── alb_controller_policy.json
│   │
│   ├── 3-ecr/                      # Módulo 3: Registro de imágenes
│   │   ├── ecr.tf                  # Repositorio ECR con escaneo ENHANCED
│   │   ├── role_github_actions_ecr.tf  # OIDC role para GitHub Actions → ECR + SSM
│   │   └── eks_pods_ecr_policies.tf    # Políticas ECR para pods del clúster
│   │
│   ├── 4-template_config/          # Módulo 4: Generación de configuración
│   │   └── templates/
│   │       ├── scripts/
│   │       │   └── install-alb-k8s-manifests-argocd.tmpl  # Script de post-instalación
│   │       ├── charts_service_accounts/
│   │       │   ├── alb_serviceAccount.tmpl     # SA para ALB Controller
│   │       │   └── argocd_serviceAccount.tmpl  # SA para ArgoCD (IRSA)
│   │       ├── charts_values/
│   │       │   └── alb_values.tmpl             # Values de Helm para ALB
│   │       └── k8s/
│   │           └── ingress.tmpl                # Ingress con VPC_ID y cluster_name
│   │
│   └── infra_scripts/              # Scripts de automatización por módulo
│       ├── apply_all.sh            # Aplica los 4 módulos en orden
│       ├── apply_networking.sh
│       ├── apply_eks.sh
│       ├── apply_ecr.sh
│       ├── apply_template_config.sh
│       ├── destroy_all.sh
│       └── destroy_*.sh            # Destrucción individual por módulo
│
└── k8s/                            # Kubernetes
    ├── manifests/
    │   ├── base/                   # Manifiestos base (Kustomize)
    │   │   ├── deployment-blue.yaml    # 3 réplicas, puerto 5000, health probes
    │   │   ├── deployment-green.yaml
    │   │   ├── ingress-blue.yaml
    │   │   ├── ingress-green.yaml
    │   │   ├── service-blue.yaml
    │   │   ├── service-green.yaml
    │   │   ├── service-account.yaml
    │   │   ├── nginx-health-config.yaml
    │   │   └── kustomization.yaml
    │   └── overlays/
    │       ├── eks/                # Overlay para AWS EKS
    │       └── minikube/           # Overlay para desarrollo local
    ├── k8s_fixed_scripts/
    │   ├── install-argocd.sh
    │   ├── install-aws-alb.sh
    │   ├── Applying-k8s-manifests.sh
    │   ├── blue-green-updater.sh   # Cambia pesos ALB (Blue% + Green% = 100)
    │   └── cleanup-argocd.sh
    └── values/
        ├── argocd-values.yaml
        └── argocd-values-minikube.yaml
```

## Pre-requisitos

- [Terraform](https://www.terraform.io/downloads) >= 1.0
- [AWS CLI](https://aws.amazon.com/cli/) configurado con credenciales de administrador
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Helm](https://helm.sh/docs/intro/install/)
- [jq](https://stedolan.github.io/jq/) (requerido por `blue-green-updater.sh`)
- Cuenta de AWS con permisos suficientes para crear VPC, EKS, IAM, ECR y S3
- Repositorio GitHub para guardar los manifiestos que ArgoCD sincronizará

## Instalación y Configuración

### 1. Clonar el Repositorio

```bash
git clone https://github.com/SergioCMDev/Infra-AWS-EKS-Python.git
cd Infra-AWS-EKS-Python
```

### 2. Configurar el Backend S3

Cada módulo usa un backend S3 independiente. Asegúrate de que el bucket exista antes de inicializar:

```bash
aws s3api create-bucket \
  --bucket my-terraform-project-bucket-aws-tokio-2 \
  --region eu-west-3 \
  --create-bucket-configuration LocationConstraint=eu-west-3
```

### 3. Desplegar la Infraestructura

El script `apply_all.sh` aplica los 4 módulos en el orden correcto:

```bash
cd infra/infra_scripts
bash apply_all.sh
```

O bien, módulo a módulo:

```bash
bash apply_networking.sh    # 1. VPC, subnets, security groups
bash apply_eks.sh           # 2. Clúster EKS + node group + IAM
bash apply_ecr.sh           # 3. ECR + roles OIDC para GitHub Actions
bash apply_template_config.sh  # 4. Genera scripts y configuración con outputs anteriores
```

### 4. Post-instalación: ALB, K8s manifests y ArgoCD

El módulo `4-template_config` genera un script renderizado con los valores del estado de Terraform. Ejecútalo una vez que el clúster esté activo:

```bash
cd infra/4-template_config/rendered/scripts
bash install-alb-k8s-manifests-argocd.sh
```

Este script:
1. Configura `kubeconfig` para el clúster
2. Instala el **AWS Load Balancer Controller** via Helm
3. Aplica los manifiestos K8s (deployments Blue/Green, services, ingress)
4. Instala **ArgoCD** con su IAM role para pull de ECR

### 5. Verificar el Clúster

```bash
aws eks update-kubeconfig --region eu-west-3 --name mi-cluster
kubectl get nodes
kubectl get pods -A
```

## Estrategia Blue-Green Deployment

### Cómo Funciona

El ALB gestiona el tráfico mediante **weighted routing** entre los dos deployments. Ambos conviven siempre en el clúster con 3 réplicas cada uno.

1. **Estado Inicial**: Blue recibe el 100% del tráfico
2. **Nuevo Deploy**: GitHub Actions construye la imagen y la publica en ECR con tag `green`
3. **Sincronización GitOps**: ArgoCD detecta el cambio en el repositorio y actualiza el deployment Green
4. **Health Check**: Startup, liveness y readiness probes validan la nueva versión
5. **Switch de Tráfico**: Se actualiza el peso del Ingress ALB
### Cambio de Pesos de Tráfico

```bash
# Enviar 100% a Blue (estado inicial o rollback)
bash k8s/k8s_fixed_scripts/blue-green-updater.sh default <ingress-name> 100 0

# Enviar 100% a Green (nuevo despliegue estable)
bash k8s/k8s_fixed_scripts/blue-green-updater.sh default <ingress-name> 0 100

# Canary: 80% Blue, 20% Green
bash k8s/k8s_fixed_scripts/blue-green-updater.sh default <ingress-name> 80 20
```

> Los pesos deben sumar 100. El script valida esto antes de aplicar el patch.

### Rollback Instantáneo

Basta con invertir los pesos de vuelta a Blue:

```bash
bash k8s/k8s_fixed_scripts/blue-green-updater.sh default <ingress-name> 100 0
```

## Seguridad

### Red
- Worker nodes en subnets **privadas** sin acceso directo a internet
- NAT Gateway para salida controlada al exterior
- Security groups independientes y granulares para ALB/NLB, control plane y workers

### IAM & Autenticación
- **OIDC para GitHub Actions**: push a ECR y escritura en SSM sin credenciales estáticas de larga duración
- **IRSA (IAM Roles for Service Accounts)**: ArgoCD y el ALB Controller usan sus propios roles IAM mínimos
- Políticas IAM de mínimo privilegio por componente

### Imágenes
- ECR con **escaneo ENHANCED** (Amazon Inspector) en cada push
- Política de repositorio que restringe el pull solo a la cuenta de AWS propietaria

## Desarrollo Local con Minikube

Los overlays de Kustomize incluyen una configuración alternativa para Minikube:

```bash
# Instalar ArgoCD en Minikube
bash k8s/k8s_fixed_scripts/install-argocd-minikube.sh

# Aplicar manifiestos con overlay de Minikube
bash k8s/k8s_fixed_scripts/Applying-k8s-manifests-minikube.sh
```

## Limpieza de Recursos

Destruir módulo a módulo (orden inverso recomendado):

```bash
cd infra/infra_scripts
bash destroy_template_config.sh
bash destroy_ecr.sh
bash destroy_eks.sh
bash destroy_networking.sh
```

O todo a la vez:

```bash
bash destroy_all.sh
```

> **Advertencia**: Esto eliminará TODOS los recursos de AWS creados. Revisa los outputs de Terraform antes de destruir.

## Mejoras Futuras

- [ ] Integración con Prometheus/Grafana para métricas del clúster
- [ ] Horizontal Pod Autoscaler (HPA) para Blue y Green
- [ ] Cluster Autoscaler para nodos
- [ ] Canary deployments progresivos con lógica en el pipeline
- [ ] Disaster recovery multi-región
- [ ] Separación de responsabilidad añadiendo un nuevo repositorio para los manifiestos de K8s
- [ ] Desacople de ingress y Terraform
## Autor

**Sergio Cristauro Manzano**

- LinkedIn: [Sergio Cristauro Manzano](www.linkedin.com/in/sergio-cristauro-manzano/)
- Email: sergiocmdev@gmail.com

---

Si este proyecto te ha sido útil, considera darle una estrella en GitHub.
Para preguntas o sugerencias, abre un issue o contáctame directamente.
