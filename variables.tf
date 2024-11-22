variable "digitalocean_token" {
    type        = string
    description = "DigitalOcean API Token"
}

variable "spaces_access_key" {
    type        = string
    description = "DigitalOcean Spaces Access Key"
}

variable "spaces_secret_key" {
    type        = string
    description = "DigitalOcean Spaces Secret Key"
}

variable "ssh_key_id" {
    type        = string
    description = "SSH Key ID in DigitalOcean"
}

variable "private_key_path" {
    type        = string
    description = "Path to SSH private key"
    default     = "~/.ssh/serverxweb"
}

variable "project_id" {
  type        = string
  description = "ID del proyecto en DigitalOcean"
}