terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }

  backend "s3" {
    endpoints = {
      s3 = "https://nyc3.digitaloceanspaces.com"
    }
    bucket                     = "devjesus2"
    key                        = "terraform.tfstate"
    region                     = "us-east-1"  # Cambiado a us-east-1 para Spaces
    skip_credentials_validation = true
    skip_metadata_api_check    = true
    skip_region_validation     = true
    skip_requesting_account_id = true
    use_path_style            = true
  }
}

provider "digitalocean" {
  token = var.DIGITALOCEAN_TOKEN
}

resource "digitalocean_droplet" "web_server" {
  image       = "ubuntu-20-04-x64"
  name        = "web-server-${formatdate("YYYYMMDDHHmmss", timestamp())}"
  region      = "sfo3"
  size        = "s-1vcpu-1gb"
  ssh_keys    = [tonumber(var.SSH_KEY_ID)]
  tags        = ["web", "production", "nodejs"]
  monitoring  = true

  connection {
    type        = "ssh"
    user        = "root"
    host        = self.ipv4_address
    private_key = file(var.PRIVATE_KEY_PATH)
    timeout     = "5m"
  }

  provisioner "remote-exec" {
    inline = [
      "#!/bin/bash",
      "set -e",
      
      # Limpiar locks y esperar
      "sudo rm -f /var/lib/apt/lists/lock /var/lib/dpkg/lock* /var/cache/apt/archives/lock",
      "while sudo fuser /var/lib/dpkg/lock >/dev/null 2>&1; do sleep 1; done",
      
      # Actualizar sistema
      "sudo apt-get update",
      "sudo apt-get install -y ca-certificates curl gnupg",
      
      # Instalar Node.js y npm
      "curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -",
      "sudo apt-get update",
      "sudo apt-get install -y nodejs",
      
      # Verificar instalación
      "echo 'Versión de Node.js:'",
      "node --version",
      "echo 'Versión de npm:'",
      "npm --version",
      
      # Instalar PM2
      "sudo npm install -g pm2",
      
      # Configurar directorio
      "sudo mkdir -p /var/www/app",
      "sudo chown -R root:root /var/www/app"
    ]
  }
}

output "droplet_ip" {
  value       = digitalocean_droplet.web_server.ipv4_address
  description = "IP pública del servidor"
}

output "droplet_status" {
  value       = digitalocean_droplet.web_server.status
  description = "Estado del Droplet"
}

output "ssh_command" {
  value       = "ssh -i ${var.PRIVATE_KEY_PATH} root@${digitalocean_droplet.web_server.ipv4_address}"
  description = "Comando SSH"
}

output "install_logs" {
  value       = "tail -f /var/log/cloud-init-output.log"
  description = "Comando para ver logs de instalación"
}