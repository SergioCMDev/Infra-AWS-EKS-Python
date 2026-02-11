data "template_file" "ingress_tmpl" {
  template = file("${local.k8s_python_web_manifests_folder}/ingress.tmpl")
  vars = {
    sg_alb = aws_security_group.alb_access_sg.id
  }
}

resource "local_file" "ingress" {
  filename = "${local.k8s_python_web_manifests_folder}/ingress.yaml"
  content  = data.template_file.ingress_tmpl.rendered
}


data "template_file" "install_alb_k8s_manifests_argocd_tmpl" {
  template = file("${local.scripts_folder}/install-alb-k8s-manifests-argocd.tmpl")
  vars = {
    cluster_name     = local.cluster_name
    region           = local.region
    vpc_id           = aws_vpc.vpc.id
    aws_alb_iam_role = aws_iam_role.aws_load_balancer_controller.name
    argocd_role_arn  = aws_iam_role.argocd_ecr_pull.arn
  }
}

resource "local_file" "install_alb_k8s_manifests_argocd_tmpl" {
  filename = "${local.scripts_folder}/install-alb-k8s-manifests-argocd.sh"
  content  = data.template_file.install_alb_k8s_manifests_argocd_tmpl.rendered
}


data "template_file" "alb_serviceAccount_tmpl" {
  template = file("${local.k8s_python_web_manifests_folder}/alb_serviceAccount.tmpl")
  vars = {
    cluster_name      = local.cluster_name
    region            = local.region
    role_arn          = aws_iam_role.aws_load_balancer_controller.arn
    aws_iam_role_name = aws_iam_role.aws_load_balancer_controller.name
  }
}

resource "local_file" "alb_serviceAccount_tmpl" {
  filename = "${local.k8s_python_web_manifests_folder}/alb_serviceAccount.yaml"
  content  = data.template_file.alb_serviceAccount_tmpl.rendered
}

#En caso de querer añadir un ServiceAccount a mano
# data "template_file" "argocd_serviceAccount_tmpl" {
#   template = file("${local.k8s_python_web_manifests_folder}/argocd_serviceAccount.tmpl")
#   vars = {
#     argocd_role_arn = aws_iam_role.argocd_ecr_pull.arn
#   }
# }

# resource "local_file" "argocd_serviceAccount_tmpl" {
#   filename = "${local.k8s_python_web_manifests_folder}/argocd_serviceAccount.yaml"
#   content  = data.template_file.argocd_serviceAccount_tmpl.rendered
# }
