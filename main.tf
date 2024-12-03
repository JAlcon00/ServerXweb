//1.- Levanto la maquina virtual sin nada
//2.- Instalo nodejs
//4.- Guardo los comandos en un archivo SH
//5.- Ejecuto el archivo SH como user data
//6.- Descomento remote exect
//xd

provider "digitalocean" {
  token = var.DIGITALOCEAN_TOKEN
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
      s3 = "https://nyc3.digitaloceanspaces.com"
    }
    bucket                      = "devjesus2"
    key                         = "terraform.tfstate"
    skip_region_validation      = true
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_requesting_account_id  = true
    skip_s3_checksum           = true
    region                     = "us-east-1"
    use_path_style             = true
  }
}

# Crea primero la clave SSH
resource "digitalocean_ssh_key" "serverxweb" {
  name       = "serverxweb"
  public_key = file("./keys/serverxweb.pub")
  lifecycle {
    create_before_destroy = true
  }
}

# Luego crea el droplet
resource "digitalocean_droplet" "yisus-project-droplet" {
  name      = "yisus-project-droplet"
  size      = "s-2vcpu-4gb-120gb-intel"
  image     = "ubuntu-20-04-x64"
  region    = "sfo3"
  ssh_keys  = [digitalocean_ssh_key.serverxweb.fingerprint]
  user_data = file("node-install.sh")
  depends_on = [digitalocean_ssh_key.serverxweb]
}

# Finalmente crea el proyecto
resource "digitalocean_project" "yisus-project2" {
  name        = "yisus-project2"
  description = "yisus-project2"
  purpose     = "Web Application"
  environment = "Production"
  resources   = [digitalocean_droplet.yisus-project-droplet.urn]
  depends_on  = [digitalocean_droplet.yisus-project-droplet]
}

output "droplet_ip" {
  value = digitalocean_droplet.yisus-project-droplet.ipv4_address
}