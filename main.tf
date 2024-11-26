provider "digitalocean" {
  token = digitalocean_token
}

terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
  backend "s3" {
    endpoints = {
      s3 = "https://sfo3.digitaloceanspaces.com"
    }
    bucket                      = "devjesus"
    key                         = "terraform.tfstate"
    region                      = "us-east-1"
    skip_region_validation      = true
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
    force_path_style            = true
  }
}

resource "digitalocean_project" "jesus_server_proyect" {
  name        = "yisus"
  description = "Proyecto para desplegar el servidor backend"
  purpose     = "Web Application"
  environment = "Production"
  resources   = [digitalocean_droplet.jesus_server_droplet.urn]
}

resource "digitalocean_ssh_key" "jesus_server_ssh_key" {
  name       = "jesus_server_web_prod"
  public_key = file(var.spaces_access_key)
}

resource "digitalocean_droplet" "jesus_server_droplet" {
  name       = "jesusserver"
  size       = "s-1vcpu-1gb"
  image      = "ubuntu-20-04-x64"
  region     = "sfo3"
  ssh_keys   = [digitalocean_ssh_key.jesus_server_ssh_key.id]
  tags       = ["web", "production", "nodejs"]
  monitoring = true

  user_data = file("./docker-install.sh")

  connection {
    type        = "ssh"
    user        = "root"
    private_key = file(var.private_key_path)
    host        = self.ipv4_address
    timeout     = "5m"
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir -p /var/www/app",
      "apt-get update || (sleep 30 && apt-get update)",
      "DEBIAN_FRONTEND=noninteractive apt-get install -y nginx",
      "systemctl start nginx || systemctl status nginx",
      "systemctl enable nginx",
      "curl -fsSL https://deb.nodesource.com/setup_16.x | bash - || exit 1",
      "DEBIAN_FRONTEND=noninteractive apt-get install -y nodejs || exit 1",
      "npm install pm2 -g"
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

resource "time_sleep" "wait_docker_install" {
  depends_on      = [digitalocean_droplet.jesus_server_droplet]
  create_duration = "130s"
}

resource "null_resource" "init_api" {
  depends_on = [time_sleep.wait_docker_install]
  provisioner "remote-exec" {
    inline = [
      "cd /var/www/app",
      "pm2 start server.ts --name backend",
      "pm2 save",
      "pm2 startup"
    ]
    connection {
      type        = "ssh"
      user        = "root"
      private_key = file(var.private_key_path)
      host        = digitalocean_droplet.jesus_server_droplet.ipv4_address
    }
  }
}

output "ip" {
  value = digitalocean_droplet.jesus_server_droplet.ipv4_address
}