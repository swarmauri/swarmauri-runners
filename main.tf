terraform {
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "3.2.3"  # Adjust the version as needed
    }
  }
}

provider "null" {}

# Create directory and set ownership/permissions
resource "null_resource" "create_directory" {
  provisioner "remote-exec" {
    inline = [
      "mkdir -p /tmp/linux/dir",
      "chown 1000:1000 /tmp/linux/dir",
      "chmod 755 /tmp/linux/dir"
    ]

    connection {
      type        = "ssh"
      host        = var.linux_host
      port        = var.linux_port
      user        = var.linux_user
      password    = var.linux_password
    }
  }

  triggers = {
    always_run = timestamp()
  }
}

# Create file with content and set ownership/permissions
resource "null_resource" "create_file" {
  provisioner "remote-exec" {
    inline = [
      "echo 'hello world' > /tmp/linux/file",
      "chown 1000:1000 /tmp/linux/file",
      "chmod 644 /tmp/linux/file"
    ]

    connection {
      type        = "ssh"
      host        = var.linux_host
      port        = var.linux_port
      user        = var.linux_user
      password    = var.linux_password
    }
  }

  triggers = {
    always_run = timestamp()
  }
}

locals {
  package_name = "docker.io"
}

# Install Docker on the remote Linux server and create a user 'runner' with a configurable password
resource "null_resource" "install_docker_and_create_user" {
  provisioner "remote-exec" {
    inline = [
      "apt update",
      "apt install -y apt-transport-https ca-certificates curl software-properties-common",
      "apt install -y ${local.package_name}",
      "systemctl start docker",
      "systemctl enable docker",
      
      # Create the 'runner' user with a configurable password
      "id -u runner || useradd -m runner",  # Add user only if it doesn't exist  
      "echo 'runner:${var.runner_password}' | chpasswd",  # Set the password for the runner user
      "usermod -aG docker runner",          # Add 'runner' to 'docker' group

      # Ensure the runner user can use Docker without sudo
      "newgrp docker"
    ]

    connection {
      type        = "ssh"
      host        = var.linux_host
      port        = var.linux_port
      user        = var.linux_user
      password    = var.linux_password
    }
  }

  triggers = {
    package_name = local.package_name
  }
}

# Variables
variable "linux_host" {
  description = "The host for the Linux provider"
  type        = string
  sensitive   = true  # Marks the password as sensitive, which will hide it in logs
}

variable "linux_port" {
  description = "The port for the Linux provider"
  type        = number
  default     = 22
}

variable "linux_user" {
  description = "The user for the Linux provider"
  type        = string
  sensitive   = true  # Marks the password as sensitive, which will hide it in logs
}

variable "linux_password" {
  description = "The password for the Linux provider"
  type        = string
  sensitive   = true  # Marks the password as sensitive, which will hide it in logs
}

# New variable for runner user password
variable "runner_password" {
  description = "Password for the runner user"
  type        = string
  sensitive   = true  # Marks the password as sensitive, which will hide it in logs
}
