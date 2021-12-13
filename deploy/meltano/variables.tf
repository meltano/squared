
variable "meltano_image_tag" {
  type        = string
  description = "The Docker image tag to deploy."
  default = "latest"
}

variable "airflow_image_tag" {
  type        = string
  description = "The Docker image tag to deploy."
  default = "latest"
}