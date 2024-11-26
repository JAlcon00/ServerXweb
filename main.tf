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

      # Limpiar y esperar procesos APT
      "while ps aux | grep -i apt | grep -v grep; do sleep 5; done",
      "sudo rm -f /var/lib/apt/lists/lock /var/lib/dpkg/lock* /var/cache/apt/archives/lock",
      
      # Actualizar sistema base
      "sudo apt-get update -y || true",
      "sudo apt-get install -y ca-certificates curl gnupg",
      
      # Instalar Node.js
      "mkdir -p /etc/apt/keyrings",
      "curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg",
      "echo 'deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main' | sudo tee /etc/apt/sources.list.d/nodesource.list",
      "sudo apt-get update -y",
      "sudo apt-get install -y nodejs",
      
      # Verificar instalación
      "node --version",
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