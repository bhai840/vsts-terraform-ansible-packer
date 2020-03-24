variable "credentials" {
  default = ""
}

variable "project" {
  default = "terraform-ansible-demo"
}

variable "manageddiskname_rg" {
  default = "manageddiskname"    #this is the resource group where packers image resides
}

variable "baked_image_url" {
  default = ""
}

variable "manageddiskname" {
  default = ""
}
