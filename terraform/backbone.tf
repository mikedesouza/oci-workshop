data "oci_identity_availability_domains" "primary_availability_domains" {
  compartment_id = "${var.tenancy}"
}
