variable "DIGITALOCEAN_TOKEN" {
  type        = string
  description = "Token de API de DigitalOcean"
  sensitive   = true

  validation {
    condition     = length(var.DIGITALOCEAN_TOKEN) > 0
    error_message = "El token de DigitalOcean no puede estar vacío"
  }
}

variable "SSH_KEY_ID" {
  type        = string
  description = "ID de la llave SSH en DigitalOcean"

  validation {
    condition     = can(regex("^[0-9]+$", var.SSH_KEY_ID))
    error_message = "El ID de la llave SSH debe ser un número"
  }
}

variable "PRIVATE_KEY_PATH" {
  type        = string
  description = "Ruta al archivo de la llave SSH privada"
  default     = "~/.ssh/serverxweb"
  sensitive   = true

  validation {
    condition     = fileexists(pathexpand(var.PRIVATE_KEY_PATH))
    error_message = "El archivo de llave privada no existe en la ruta especificada"
  }
}

variable "SPACES_ACCESS_KEY" {
  type        = string
  description = "Llave de acceso para DigitalOcean Spaces"
  sensitive   = true

  validation {
    condition     = length(var.SPACES_ACCESS_KEY) > 0
    error_message = "La llave de acceso para Spaces no puede estar vacía"
  }
}

variable "SPACES_SECRET_KEY" {
  type        = string
  description = "Llave secreta para DigitalOcean Spaces"
  sensitive   = true

  validation {
    condition     = length(var.SPACES_SECRET_KEY) > 0
    error_message = "La llave secreta para Spaces no puede estar vacía"
  }
}