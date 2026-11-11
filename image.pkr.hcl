packer {
  required_version = ">= 1.9.0"

  required_plugins {
    amazon = {
      version = ">= 1.3.0"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

variable "image_name" {
  type        = string
  default     = "sample-golden-image"
  description = "Prefix of the image name; a build timestamp is appended."
}

variable "region" {
  type        = string
  default     = "us-east-1"
  description = "AWS region the image is built and registered in."
}

variable "instance_type" {
  type        = string
  default     = "t3.medium"
  description = "EC2 instance type of the temporary build instance."
}

locals {
  build_time = formatdate("YYYYMMDDhhmmss", timestamp())
  image_name = "${var.image_name}-${local.build_time}"
}

source "amazon-ebs" "main" {
  ami_name      = local.image_name
  instance_type = var.instance_type
  region        = var.region

  source_ami_filter {
    filters = {
      name                = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
      architecture        = "x86_64"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"] # Canonical
  }

  ssh_username = "ubuntu"

  # IMDSv2 only, on the build instance and on instances launched from the AMI.
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
  imds_support = "v2.0"

  tags = {
    Name      = var.image_name
    BaseOS    = "ubuntu-22.04"
    ManagedBy = "packer"
  }
}

build {
  sources = ["source.amazon-ebs.main"]

  provisioner "shell" {
    execute_command = "chmod +x {{ .Path }}; sudo -E bash '{{ .Path }}'"
    script          = "scripts/provision.sh"
  }

  post-processor "manifest" {
    output     = "manifest.json"
    strip_path = true
  }
}
