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

variable "image_id" {
  default = "demoPackerImage-formatdate("YYYY-MM-DD_hh_mm_ss", "2018-01-02T23:12:01")" #"demoPackerImage-2020-03-24_04_40_17"
  #validation {
    # regex(...) fails if it cannot find a match
   # condition    = can (regex(demoPackerImage-formatdate("YYYY-MM-DD_hh_mm_ss", "2018-01-02T23:12:01"), var.image_id))
    
    #}
}
