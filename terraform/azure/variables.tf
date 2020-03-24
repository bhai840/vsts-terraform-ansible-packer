variable "credentials" {
  default = ""
}

variable "project" {
  default = "terraform-ansible-demo"
}

variable "manageddiskname_rg" {
  default = "managed-images2020"
}

variable "baked_image_url" {
  default = ""
}

variable "manageddiskname" {
  default = "demoPackerImage-{{isotime \"2006-01-02_03_04_05\"}}"
}
