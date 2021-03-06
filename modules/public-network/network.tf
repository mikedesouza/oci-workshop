resource "oci_core_subnet" "public-subnet" {
  count               = 3
  availability_domain = "${lookup(data.oci_identity_availability_domains.primary_availability_domains.availability_domains[count.index],"name")}"
  cidr_block          = "10.0.${count.index}.0/24"
  display_name        = "${oci_core_virtual_network.main.display_name}-subnet${count.index}pub"
  dns_label           = "subnet${count.index}pub"
  security_list_ids   = ["${oci_core_security_list.public-sl.id}"]
  compartment_id      = "${var.compartment}"
  vcn_id              = "${oci_core_virtual_network.main.id}"
  route_table_id      = "${oci_core_route_table.public-rt.id}"
  dhcp_options_id     = "${oci_core_dhcp_options.DhcpOptions.id}"
}

resource "oci_core_route_table" "public-rt" {
  compartment_id = "${var.compartment}"
  vcn_id         = "${oci_core_virtual_network.main.id}"
  display_name   = "${oci_core_virtual_network.main.display_name}-public-rt"

  route_rules {
    cidr_block        = "0.0.0.0/0"
    network_entity_id = "${oci_core_internet_gateway.internetgateway.id}"
  }
}

resource "oci_core_security_list" "public-sl" {
  display_name   = "${oci_core_virtual_network.main.display_name}-public-sl"
  compartment_id = "${var.compartment}"
  vcn_id         = "${oci_core_virtual_network.main.id}"

  egress_security_rules = [
    {
      protocol    = "all"
      stateless   = "true"
      destination = "0.0.0.0/0"
    }
  ]

  ingress_security_rules = [
    {
      protocol = "6"
      stateless   = "true"
      source   = "0.0.0.0/0"

      tcp_options = {
        min = "22"
        max = "22"
      }
    },
    {
      protocol = "6"
      stateless   = "true"
      source   = "0.0.0.0/0"

      tcp_options = {
        min = "80"
        max = "80"
      }
    },
    {
      protocol = "6"
      stateless   = "true"
      source   = "0.0.0.0/0"

      tcp_options = {
        min = "32768"
        max = "61000"
      }
    }
  ]
}

output "public_subnets" {
  value = "${oci_core_subnet.public-subnet.*.id}"
}
