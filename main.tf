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

# Generar timestamp único para nombres
locals {
  timestamp = formatdate("YYYYMMDDHHmmss", timestamp())
}

resource "digitalocean_project" "yisus" {
  name        = "yisus-server-${local.timestamp}"
  description = "Proyecto para desplegar el servidor backend"
  purpose     = "Web Application"
  environment = "Production"
}

resource "digitalocean_droplet" "web_server" {
  image       = "ubuntu-20-04-x64"
  name        = "web-server-${local.timestamp}"
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

  # Instalar dependencias
  provisioner "remote-exec" {
  inline = [
    "#!/bin/bash",
    "set -e",
    "while ps aux | grep -i apt | grep -v grep; do sleep 1; done",
    
    # Actualizar sistema
    "DEBIAN_FRONTEND=noninteractive apt-get update",
    "DEBIAN_FRONTEND=noninteractive apt-get install -y command-not-found",
    
    # Instalar Node.js desde NodeSource
    "curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -",
    "DEBIAN_FRONTEND=noninteractive apt-get install -y nodejs",
    
    # Verificar instalaciones
    "node --version || exit 1",
    "npm --version || exit 1",
    
    # Instalar PM2
    "npm install -g pm2",
    
    # Crear directorio de la aplicación
    "mkdir -p /var/www/app"
  ]
}

  # Copiar archivos de la aplicación
  provisioner "file" {
    source      = "src/"
    destination = "/var/www/app"
  }

  # Configurar y iniciar la aplicación
  provisioner "remote-exec" {
    inline = [
      "cd /var/www/app",
      "npm install",
      "pm2 start server.ts --name backend || pm2 start server.js --name backend",
      "pm2 save",
      "pm2 startup",
      "systemctl enable pm2-root"
    ]
  }
}

# Asignar recursos al proyecto
resource "digitalocean_project_resources" "project_resources" {
  project = digitalocean_project.yisus.id
  resources = [
    digitalocean_droplet.web_server.urn
  ]
}

# Outputs
output "droplet_ip" {
  value       = digitalocean_droplet.web_server.ipv4_address
  description = "IP pública del servidor web"
}

output "project_id" {
  value       = digitalocean_project.yisus.id
  description = "ID del proyecto creado"
}

output "project_url" {
  value       = "https://cloud.digitalocean.com/projects/${digitalocean_project.yisus.id}"
  description = "URL del proyecto en DigitalOcean"
}

output "ssh_command" {
  value       = "ssh root@${digitalocean_droplet.web_server.ipv4_address} -i ${var.PRIVATE_KEY_PATH}"
  description = "Comando para conectarse via SSH al servidor"
}