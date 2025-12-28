# ecr.tf

# Defines a private ECR (Elastic Container Registry) repository for the Flask webserver application.
resource "aws_ecr_repository" "flask_webserver_repo" {
  # Name is now dynamic and uses a path-like structure for organization.
  name = "${var.cluster_name}/python-flask-webserver"

  image_tag_mutability = "MUTABLE"

  encryption_configuration {
    encryption_type = "AES256"
  }

  # Enable vulnerability scanning on push for better security.
  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    "project" = var.cluster_name
    yor_trace = "85cb9b0c-f4ab-491e-9581-3bcb23a1fdf1"
  }
}

# Defines a second ECR repository, in this case for storing malware analysis container images.
resource "aws_ecr_repository" "malware_repo" {
  name = "${var.cluster_name}/malware"

  image_tag_mutability = "MUTABLE"

  encryption_configuration {
    encryption_type = "AES256"
  }

  # Enable vulnerability scanning on push for better security.
  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    "project" = var.cluster_name
    yor_trace = "f4ef0bc2-99eb-4894-9db0-6ad705b90c90"
  }
}