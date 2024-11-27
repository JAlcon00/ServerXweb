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
      "  local max_attempts=30",
      "  local attempt=1",
      "  while sudo fuser /var/lib/dpkg/lock >/dev/null 2>&1 || sudo fuser /var/lib/apt/lists/lock >/dev/null 2>&1 || sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do",
      "    if [ $attempt -gt $max_attempts ]; then",
      "      echo 'Error: Timeout esperando a apt'",
      "      exit 1",
      "    fi",
      "    echo 'Esperando a que otras instancias de apt terminen... Intento $attempt de $max_attempts'",
      "    sleep 10",
      "    attempt=$((attempt + 1))",
      "  done",
      "}",

      # Función para verificar instalación
      "verify_package() {",
      "  if ! dpkg -l \"$1\" >/dev/null 2>&1; then",
      "    echo \"Error: $1 no se instaló correctamente\"",
      "    exit 1",
      "  fi",
      "}",

      # Limpiar locks si existen
      "sudo killall apt apt-get 2>/dev/null || true",
      "sudo rm -f /var/lib/apt/lists/lock /var/cache/apt/archives/lock /var/lib/dpkg/lock*",
      "sudo dpkg --configure -a",

      # Actualizar lista de paquetes
      "sudo apt-get update",

      # Actualizar e instalar dependencias básicas
      "wait_for_apt",
      "sudo apt-get clean",
      "wait_for_apt",
      "DEBIAN_FRONTEND=noninteractive sudo apt-get install -y ca-certificates curl gnupg build-essential || (echo 'Error instalando dependencias básicas' && exit 1)",
      "verify_package ca-certificates",
      "verify_package curl",
      "verify_package gnupg",
      "verify_package build-essential",

      # Instalar Node.js desde NodeSource
      "if ! curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -; then",
      "  echo 'Error configurando repositorio de Node.js'",
      "  exit 1",
      "fi",

      "wait_for_apt",
      "DEBIAN_FRONTEND=noninteractive sudo apt-get install -y nodejs || (echo 'Error instalando Node.js' && exit 1)",
      "verify_package nodejs",

      # Verificar versiones
      "echo 'Verificando Node.js...'",
      "node --version || (echo 'Error: Node.js no está disponible' && exit 1)",
      "echo 'Verificando npm...'",
      "npm --version || (echo 'Error: npm no está disponible' && exit 1)",

      # Instalar PM2
      "echo 'Instalando PM2...'",
      "if ! sudo npm install -g pm2; then",
      "  echo 'Error instalando PM2'",
      "  exit 1",
      "fi",
      "pm2 --version || (echo 'Error: PM2 no está disponible' && exit 1)",

      # Configurar directorio
      "sudo mkdir -p /var/www/app || (echo 'Error creando directorio de la aplicación' && exit 1)",
      "sudo chown -R root:root /var/www/app || (echo 'Error configurando permisos' && exit 1)",

      "echo 'Instalación completada con éxito'"
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
