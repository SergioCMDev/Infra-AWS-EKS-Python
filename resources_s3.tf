data "template_file" "ingress_tmpl" {
  template = file("${local.k8s_manifests_folder}/ingress.tmpl")
  vars = {
    sg_alb = aws_security_group.alb_access_sg.id
  }
}

resource "local_file" "ingress" {
  filename = "${local.k8s_manifests_folder}/ingress.yaml"
  content  = data.template_file.ingress_tmpl.rendered
}


data "template_file" "afterDeployInfra_tmpl" {
  template = file("${local.scripts_folder}/afterDeployInfra.tmpl")
  vars = {
    cluster_name      = local.cluster_name
    region            = local.region
    vpc_id            = aws_vpc.vpc.id
    rol_github_runner = aws_iam_role.ec2_github_runner_role.name
  }
}

resource "local_file" "afterDeployInfra" {
  filename = "${local.scripts_folder}/afterDeployInfra.sh"
  content  = data.template_file.afterDeployInfra_tmpl.rendered
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
