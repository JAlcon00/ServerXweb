variable "DIGITALOCEAN_TOKEN" {
    type        = string
    description = "DigitalOcean API Token"
}

variable "SPACES_ACCESS_KEY" {
    type        = string
    description = "DigitalOcean Spaces Access Key"
}

variable "SPACES_SECRET_KEY" {
    type        = string
    description = "DigitalOcean Spaces Secret Key"
}

variable "SSH_KEY_ID" {
    type        = string
    description = "SSH Key ID in DigitalOcean"
}

variable "PRIVATE_KEY_PATH" {
    type        = string
    description = "Path to SSH private key"
    default     = "~/.ssh/serverxweb"
}