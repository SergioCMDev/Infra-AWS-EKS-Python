variable "repo_name" {
  type    = string
  default = "SergioCMDev/PythonWebForIAC"
}

variable "region" {
  type    = string
  default = "eu-west-3"
}

variable "ssm_parameter" {
  type    = string
  default = "app-python-web/active-slot"
}

variable "env" {
  type    = string
  default = "dev"
}
