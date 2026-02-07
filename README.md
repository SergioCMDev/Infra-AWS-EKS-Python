#  Infraestructura AWS EKS con CI/CD Blue-Green

[![Terraform](https://img.shields.io/badge/Terraform-1.x-623CE4?logo=terraform&logoColor=white)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-EKS-FF9900?logo=amazon-aws&logoColor=white)](https://aws.amazon.com/eks/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.28+-326CE5?logo=kubernetes&logoColor=white)](https://kubernetes.io/)
[![Python](https://img.shields.io/badge/Python-3.x-3776AB?logo=python&logoColor=white)](https://www.python.org/)

## Descripción

Proyecto de infraestructura como código (IaC) que despliega un clúster **Amazon EKS** completo utilizando **Terraform**, con capacidades de despliegue **Blue-Green** mediante GitHub Actions para una aplicación web Python (https://github.com/SergioCMDev/PythonWebForIAC/.

Este proyecto demuestra las mejores prácticas de DevOps, incluyendo automatización completa de infraestructura, CI/CD sin interrupciones y arquitectura cloud-native escalable.

## Arquitectura

```
┌─────────────────────────────────────────────────────────────┐
│                         AWS Cloud                            │
│                                                               │
│  ┌──────────────────────────────────────────────────────┐  │
│  │                        VPC                            │  │
│  │                                                        │  │
│  │  ┌──────────────┐        ┌──────────────┐           │  │
│  │  │   Public     │        │   Private    │           │  │
│  │  │   Subnets    │────────│   Subnets    │           │  │
│  │  │              │  NAT   │              │           │  │
│  │  │  - IGW       │  GW    │  - EKS       │           │  │
│  │  │  - ALB       │        │  - Workers   │           │  │
│  │  └──────────────┘        └──────────────┘           │  │
│  │                                                        │  │
│  │  ┌────────────────────────────────────────┐          │  │
│  │  │         EKS Cluster                    │          │  │
│  │  │                                         │          │  │
│  │  │  ┌──────────┐      ┌──────────┐       │          │  │
│  │  │  │  Blue    │◄────►│  Green   │       │          │  │
│  │  │  │  Deploy  │ LB   │  Deploy  │       │          │  │
│  │  │  └──────────┘      └──────────┘       │          │  │
│  │  └────────────────────────────────────────┘          │  │
│  │                                                        │  │
│  │  ┌────────────────────────────────────────┐          │  │
│  │  │  GitHub Actions Runner (EC2)           │          │  │
│  │  │  - Self-hosted runner                  │          │  │
│  │  │  - CI/CD automation                    │          │  │
│  │  └────────────────────────────────────────┘          │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

##  Características Principales

- **Infraestructura como Código**: Todo el stack definido en Terraform con módulos reutilizables
- **Despliegue Blue-Green**: Zero-downtime deployments con rollback instantáneo
- **CI/CD Automatizado**: Pipeline completo con GitHub Actions
- **Seguridad Avanzada**:
  - Security groups granulares
  - OIDC para autenticación con AWS
  - IAM roles con mínimos privilegios
  - Subnets privadas para workers
- **Alta Disponibilidad**: Multi-AZ deployment con balanceo de carga
- **Optimización de Costos**: Uso de Spot Instances y auto-scaling

## Tecnologías Utilizadas

### Infrastructure & Cloud
- **Terraform** - Infraestructura como código
- **AWS EKS** - Kubernetes gestionado
- **AWS VPC** - Networking aislado
- **AWS ALB** - Application Load Balancer
- **AWS S3** - Backend de estado de Terraform
- **AWS EC2** - GitHub self-hosted runner

### Container & Orchestration
- **Kubernetes** - Orquestación de contenedores
- **Docker** - Containerización
- **Kubectl** - CLI de Kubernetes

### CI/CD & Automation
- **GitHub Actions** - Pipeline CI/CD
- **Bash Scripts** - Automatización de despliegues

## Estructura del Proyecto

```
.
├── main.tf                      # Configuración principal de Terraform
├── provider.tf                  # Configuración de providers
├── variables.tf                 # Variables de entrada
├── output.tf                    # Outputs de la infraestructura
│
├── vpc.tf                       # Definición de VPC
├── public_network.tf            # Subnets públicas
├── private_networks.tf          # Subnets privadas
├── gateway.tf                   # Internet Gateway
├── nat.tf                       # NAT Gateway
├── public_routes.tf             # Rutas públicas
├── private_routes.tf            # Rutas privadas
│
├── eks-cluster.tf               # Cluster EKS
├── security_cluster.tf          # Security groups del cluster
├── security_workers.tf          # Security groups de workers
├── roles.tf                     # IAM roles del cluster
├── workers_roles.tf             # IAM roles de workers
│
├── roles_alb.tf                 # Roles para ALB Controller
├── security_alb-nlb-ssm.tf      # Security groups para ALB/NLB
├── oidc.tf                      # OIDC provider
│
├── github-runner-ec2.tf         # EC2 para GitHub runner
├── security_github_runner.tf    # Security groups del runner
│
├── resources_s3.tf              # Bucket S3 para estado
│
├── k8s_manifests/               # Manifiestos de Kubernetes
│   ├── deployment-blue.yaml     # Deployment Blue
│   ├── deployment-green.yaml    # Deployment Green
│   ├── service.yaml             # Service
│   └── ingress.yaml             # Ingress/ALB
│
├── k8s_config_files/            # Configuración adicional K8s
│
└── scripts/                     # Scripts de automatización
    ├── deploy-blue-green.sh     # Script de despliegue
    └── rollback.sh              # Script de rollback
```

## Pre-requisitos

Antes de comenzar, asegúrate de tener instalado:

- [Terraform](https://www.terraform.io/downloads) >= 1.0
- [AWS CLI](https://aws.amazon.com/cli/) configurado con credenciales
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Docker](https://docs.docker.com/get-docker/)
- Cuenta de AWS con permisos de administrador
- Repositorio GitHub para la aplicación Python

## Instalación y Configuración

### 1. Clonar el Repositorio

```bash
git clone https://github.com/SergioCMDev/Infra-AWS-EKS-Python.git
cd Infra-AWS-EKS-Python
```

### 2. Configurar Variables

Edita el archivo `variables.tf` o crea un `terraform.tfvars`:

```hcl
aws_region          = "eu-west-1"
cluster_name        = "my-eks-cluster"
vpc_cidr            = "10.0.0.0/16"
availability_zones  = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
```

### 3. Inicializar Terraform

```bash
terraform init
```

### 4. Planificar el Despliegue

```bash
terraform plan
```

### 5. Aplicar la Infraestructura

```bash
terraform apply
```

Este proceso creará:
- 1 VPC con subnets públicas y privadas
- 1 Cluster EKS con node group
- 1 Application Load Balancer
- 1 EC2 instance para GitHub runner
- Todos los security groups y IAM roles necesarios

### 6. Configurar kubectl

```bash
aws eks update-kubeconfig --region eu-west-1 --name my-eks-cluster
```

### 7. Verificar el Cluster

```bash
kubectl get nodes
kubectl get pods -A
```

## Estrategia Blue-Green Deployment

### Cómo Funciona

1. **Estado Inicial**: Deployment Blue activo recibiendo tráfico
2. **Nuevo Deploy**: Se despliega versión Green en paralelo
3. **Health Check**: Se verifica que Green esté saludable
4. **Switch**: Se actualiza el Service para apuntar a Green
5. **Cleanup**: Blue permanece inactivo para posible rollback

### Proceso de Despliegue

El pipeline de GitHub Actions automáticamente:

```yaml
1. Build → Construye nueva imagen Docker
2. Push → Sube imagen a DockerHub
3. Deploy → Despliega a ambiente Green
4. Test → Ejecuta smoke tests
5. Switch → Cambia tráfico a Green
6. Verify → Monitorea métricas
```

### Rollback Instantáneo

En caso de problemas:

```bash
./scripts/rollback.sh
```

Esto revierte el tráfico al deployment anterior en menos de 5 segundos.

## Seguridad

### Seguridad de red
- Workers en subnets privadas sin acceso directo a internet
- NAT Gateway para salida controlada
- Security groups con mínimo privilegio

### IAM & Autenticación
- OIDC para GitHub Actions (sin credentials estáticas)
- Service accounts de Kubernetes con IAM roles
- Políticas IAM específicas por servicio

### Mejores prácticas
- Secrets gestionados con AWS Secrets Manager
- Encryption at rest para EBS y S3
- VPC flow logs para auditoría

## Monitoreo y Observabilidad

```bash
# Ver logs de pods
kubectl logs -f deployment/python-app-green

# Métricas del cluster
kubectl top nodes
kubectl top pods

# Estado de los deployments
kubectl get deployments -o wide
```


### Para añadir una nueva funcionalidad

```bash
# 1. Crear rama
git checkout -b feature/nueva-funcionalidad

# 2. Desarrollar y commitear
git add .
git commit -m "feat: nueva funcionalidad"

# 3. Push dispara el pipeline
git push origin feature/nueva-funcionalidad

# 4. El pipeline automáticamente:
#    - Ejecuta tests
#    - Construye imagen
#    - Despliega a Green
#    - Ejecuta smoke tests
#    - Switch de tráfico si todo OK
```

## Limpieza de Recursos

Para destruir toda la infraestructura:

```bash
# Eliminar recursos de Kubernetes primero
kubectl delete all --all -n default

# Destruir infraestructura de Terraform
terraform destroy
```

**Advertencia**: Esto eliminará TODOS los recursos creados. Asegúrate de hacer backup de datos importantes.

## Mejoras Futuras

- [ ] Integración con Prometheus/Grafana para métricas avanzadas
- [ ] Implementar Horizontal Pod Autoscaler (HPA)
- [ ] Agregar Cluster Autoscaler
- [ ] Implementar service mesh (Istio/Linkerd)
- [ ] Añadir canary deployments
- [ ] Implementar disaster recovery multi-región
- [ ] Agregar tests de carga automatizados

## Contribuciones

Las contribuciones son bienvenidas. Para contribuir:

1. Fork del proyecto
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## Licencia

Este proyecto está bajo la Licencia MIT. Ver archivo `LICENSE` para más detalles.

## Autor

**Sergio Cristauro Manzano**

- LinkedIn: [Sergio Cristauro](https://www.linkedin.com/in/sergio-cristauro/)
- Email: sergiocmdev@gmail.com

## Agradecimientos

- Documentación oficial de Terraform
- Comunidad de AWS EKS
- Kubernetes community
- GitHub Actions documentation

---

⭐ Si este proyecto te ha sido útil, considera darle una estrella en GitHub

📫 Para preguntas o sugerencias, abre un issue o contáctame directamente
