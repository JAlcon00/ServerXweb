terraform {
    required_providers {
        digitalocean = {
            source  = "digitalocean/digitalocean"
            version = "~> 2.0"
        }
    }

    backend "s3" {
        endpoint                    = "sfo3.digitaloceanspaces.com"  # Correct, this matches San Francisco 3 region
        bucket                      = "devjesus"
        key                         = "terraform.tfstate"
        region                      = "sfo3"                        # Updated to match the endpoint region
        skip_credentials_validation = true
        skip_metadata_api_check     = true
        force_path_style           = true
    }
}

provider "digitalocean" {
  token = var.digitalocean_token
}

resource "digitalocean_droplet" "web_server" {
    image    = "ubuntu-20-04-x64"
    name     = "web-server"
    region   = "nyc1"
    size     = "s-1vcpu-1gb"
    ssh_keys = [var.ssh_key_id]

    connection {
        type        = "ssh"
        user        = "root"
        host        = digitalocean_droplet.web_server.ipv4_address
        private_key = file(var.private_key_path)
    }

    provisioner "remote-exec" {
        inline = [
            "apt-get update",
            "apt-get install -y nginx",
            "systemctl start nginx",
            "systemctl enable nginx",
            
            # Install Node.js
            "curl -fsSL https://deb.nodesource.com/setup_16.x | bash -",
            "apt-get install -y nodejs",
            
            # Install PM2
            "npm install pm2 -g",
            
            # Create app directory
            "mkdir -p /var/www/app",
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