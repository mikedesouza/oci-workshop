variable environment {
  type        = "string"
  description = "The environment name"
  default     = "default"
}

variable message {
  type        = "map"
  description = "The environment name"

  default = {
    default = "We did not provide any message"
  }
}

variable ssh_public_key {
  type        = "string"
  description = "The local public key"
}
