terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }

  backend "s3" {
    endpoint                    = "sfo3.digitaloceanspaces.com"
    bucket                      = "devjesus"
    key                         = "terraform.tfstate"
    region                      = "us-east-1"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    force_path_style            = true
  }
}

provider "digitalocean" {
  token = var.digitalocean_token
}

resource "digitalocean_project" "yisus" {
  name        = "yisus"
  description = "Proyecto para desplegar el servidor backend"
  purpose     = "Web Application"
  environment = "Production"
}

resource "digitalocean_droplet" "web_server" {
  image    = "ubuntu-20-04-x64"
  name     = "web-server"
  region   = "nyc1"
  size     = "s-1vcpu-1gb"
  ssh_keys = [var.ssh_key_id]
  tags     = ["web", "production", "nodejs"]

  connection {
    type        = "ssh"
    user        = "root"
    host        = self.ipv4_address
    private_key = file(var.private_key_path)
    timeout     = "5m"
  }

  provisioner "remote-exec" {
    inline = [
      "set -e",
      "apt-get update || (sleep 30 && apt-get update)",
      "DEBIAN_FRONTEND=noninteractive apt-get install -y nginx",
      "systemctl start nginx || systemctl status nginx",
      "systemctl enable nginx",
      "curl -fsSL https://deb.nodesource.com/setup_16.x | bash - || exit 1",
      "DEBIAN_FRONTEND=noninteractive apt-get install -y nodejs || exit 1",
      "npm install pm2 -g",
      "mkdir -p /var/www/app"
    ]
  }

  provisioner "file" {
    source      = "../backend"
    destination = "/var/www/app"
  }

  provisioner "remote-exec" {
    inline = [
      "cd /var/www/app",
      "npm install",
      "pm2 start server.ts --name backend",
      "pm2 save",
      "pm2 startup"
    ]
  }
}

output "droplet_ip" {
  value = digitalocean_droplet.web_server.ipv4_address
}