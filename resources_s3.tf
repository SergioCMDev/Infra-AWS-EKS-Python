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
    cluster_name = local.cluster_name
    region       = local.region
    vpc_id       = aws_vpc.vpc.id
    aws_iam_role = aws_iam_role.aws_load_balancer_controller.name
  }
}

resource "local_file" "install_alb_k8s_manifests_argocd_tmpl" {
  filename = "${local.scripts_folder}/install-alb-k8s-manifests-argocd.sh"
  content  = data.template_file.install_alb_k8s_manifests_argocd_tmpl.rendered
}


data "template_file" "configure_eks_tmpl" {
  template = file("${local.scripts_folder}/configure_eks.tmpl")
  vars = {
    cluster_name = local.cluster_name
    region       = local.region
  }
}

resource "local_file" "configure_eks" {
  filename = "${local.scripts_folder}/configure_eks.yaml"
  content  = data.template_file.configure_eks_tmpl.rendered
}
