variable "cidr_block" {
  type = string
}

variable "public_subnets" {
  type = list(string)
}

variable "private_subnets" {
  type = list(string)
}

variable "azs" {
  type = list(string)
}

variable "env_prefix" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "single_nat_gateway" {
  type    = bool
  default = true
}

variable "enable_nat_gateway" {
  type    = bool
  default = true
}