terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
  backend "s3" {
    endpoints {
      s3 = "https://nyc3.digitaloceanspaces.com"
    }
    bucket                      = "devjesus2"
    key                         = "terraform.tfstate"
    region                      = "us-east-1"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    force_path_style            = true
  }
}

provider "digitalocean" {
  token = var.DIGITALOCEAN_TOKEN
}

resource "digitalocean_project" "yisus" {
  name        = "yisus-server-${formatdate("YYYYMMDD", timestamp())}" 
  description = "Proyecto para desplegar el servidor backend"
  purpose     = "Web Application"
  environment = "Production"
}

resource "digitalocean_droplet" "web_server" {
  image       = "ubuntu-20-04-x64"
  name        = "web-server"
  region      = "sfo3"
  size        = "s-1vcpu-1gb"
  ssh_keys    = [var.SSH_KEY_ID]
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