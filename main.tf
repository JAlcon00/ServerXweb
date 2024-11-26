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
    region                     = "nyc3"
    skip_credentials_validation = true
    skip_metadata_api_check    = true
    skip_region_validation     = true
    skip_requesting_account_id = true
    use_path_style            = true
    acl                       = "private"
  }
}

provider "digitalocean" {
  token = var.DIGITALOCEAN_TOKEN
}

resource "digitalocean_droplet" "web_server" {
  image       = "ubuntu-20-04-x64"
  name        = "web-server-${formatdate("YYYYMMDDHHmmss", timestamp())}"
  region      = "nyc3"
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
      
      # Esperar cualquier proceso apt existente
      "while ps aux | grep -i apt | grep -v grep; do sleep 5; done",
      
      # Remover locks antiguos si existen
      "sudo rm -f /var/lib/apt/lists/lock",
      "sudo rm -f /var/lib/dpkg/lock*",
      "sudo rm -f /var/cache/apt/archives/lock",
      
      # Actualizar e instalar dependencias básicas
      "DEBIAN_FRONTEND=noninteractive sudo apt-get clean",
      "DEBIAN_FRONTEND=noninteractive sudo apt-get update",
      "DEBIAN_FRONTEND=noninteractive sudo apt-get install -y software-properties-common curl apt-transport-https ca-certificates",
      
      # Instalar Node.js
      "curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -",
      "DEBIAN_FRONTEND=noninteractive sudo apt-get install -y nodejs",
      
      # Verificar instalaciones
      "node --version",
      "npm --version",
      
      # Instalar PM2 globalmente
      "sudo npm install -g pm2",
      
      # Crear directorio de la aplicación
      "sudo mkdir -p /var/www/app",
      "sudo chown -R root:root /var/www/app"
    ]
  }
}

# Outputs actualizados con más información
output "droplet_ip" {
  value       = digitalocean_droplet.web_server.ipv4_address
  description = "IP pública del servidor web"
}

output "droplet_status" {
  value       = digitalocean_droplet.web_server.status
  description = "Estado actual del Droplet"
}

output "ssh_command" {
  value       = "ssh -i ${var.PRIVATE_KEY_PATH} root@${digitalocean_droplet.web_server.ipv4_address}"
  description = "Comando para conectarse via SSH"
}

output "node_install_log" {
  value       = "Verifica los logs en: /var/log/cloud-init-output.log"
  description = "Ubicación de logs de instalación"
}