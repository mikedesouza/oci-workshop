module "livecode" {
  tenancy = "${var.tenancy}"
  compartment = "${var.compartment}"
  name = "livecode"
  source = "../modules/public-network"
}

module "developer" {
  tenancy = "${var.tenancy}"
  compartment = "${var.compartment}"
  name = "developer"
  source = "github.com/gregoryguillou/oci-workshop?ref=04-demo//modules/public-network"
}

output livecode_subnets {
  value = "${module.livecode.public_subnets}"
}
