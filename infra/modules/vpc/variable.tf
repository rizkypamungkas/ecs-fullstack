variable "name" {
  type = string
}

variable "vpc_cidr" {
  type = string  
}

variable "public_subnet" {
  type = list(string)
}

variable "private_subnet" {
  type = list(string)
}