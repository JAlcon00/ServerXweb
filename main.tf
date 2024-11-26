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
    bucket                      = "devjesus2"
    key                         = "terraform.tfstate"
    region                      = "nyc3"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    use_path_style              = true
  }
}

provider "digitalocean" {
  token = var.DIGITALOCEAN_TOKEN
}

resource "digitalocean_droplet" "web_server" {
  image      = "ubuntu-20-04-x64"
  name       = "web-server-${formatdate("YYYYMMDDHHmmss", timestamp())}"
  region     = "sfo3"
  size       = "s-1vcpu-1gb"
  ssh_keys   = [tonumber(var.SSH_KEY_ID)]
  tags       = ["web", "production", "nodejs"]
  monitoring = true

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

      # Función para esperar a que apt esté disponible
      "wait_for_apt() {",
      "  while sudo fuser /var/lib/dpkg/lock >/dev/null 2>&1 || sudo fuser /var/lib/apt/lists/lock >/dev/null 2>&1 || sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do",
      "    echo 'Esperando a que otras instancias de apt terminen...'",
      "    sleep 10",
      "  done",
      "}",

      # Limpiar locks si existen
      "sudo killall apt apt-get 2>/dev/null || true",
      "sudo rm -f /var/lib/apt/lists/lock",
      "sudo rm -f /var/cache/apt/archives/lock",
      "sudo rm -f /var/lib/dpkg/lock*",

      # Esperar y actualizar
      "wait_for_apt",
      "sudo apt-get clean",
      "wait_for_apt",
      "DEBIAN_FRONTEND=noninteractive sudo apt-get update -y",
      "wait_for_apt",
      "DEBIAN_FRONTEND=noninteractive sudo apt-get install -y ca-certificates curl gnupg",

      # Instalar Node.js desde NodeSource
      "curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -",
      "wait_for_apt",
      "DEBIAN_FRONTEND=noninteractive sudo apt-get install -y nodejs",

      # Verificar instalación
      "node --version || exit 1",
      "npm --version || exit 1",

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
