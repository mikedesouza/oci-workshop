module "livecode" {
  tenancy = "${var.tenancy}"
  compartment = "${var.compartment}"
  name = "livecode"
  source = "../modules/public-network"
}

