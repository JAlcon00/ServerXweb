variable "DIGITALOCEAN_TOKEN" {
    type        = string
    description = "DigitalOcean API Token"
}

variable "SSH_KEY_ID" {
  type        = string
  description = "ID de la llave SSH en DigitalOcean"

  validation {
    condition     = can(tonumber(var.SSH_KEY_ID))
    error_message = "El SSH_KEY_ID debe ser un número válido"
  }
}

variable "PRIVATE_KEY_PATH" {
    type        = string
    description = "Path to SSH private key"
    default     = "~/.ssh/serverxweb"
}