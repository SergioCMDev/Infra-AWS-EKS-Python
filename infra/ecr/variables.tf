variable "repo_name" {
  type    = string
  default = "SergioCMDev/PythonWebForIAC"
}

variable "region" {
  type    = string
  default = "eu-west-3"
}

variable "ssm_paramter" {
  type    = string
  default = "/app-python-web/active-slot"
}
