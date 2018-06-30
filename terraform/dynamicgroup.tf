resource "oci_identity_dynamic_group" "devinstances" {
  compartment_id = "${var.tenancy}"
  description    = "List all the Instances from the DevTeam compartment"
  matching_rule  = "any {ALL {instance.compartment.id = '${var.compartment}'}}"
  name           = "DevInstances"
}

resource "oci_identity_policy" "devinstance_policies" {
  compartment_id = "${var.compartment}"
  description    = "Granting access to the devinstance group"
  name           = "DevInstanceAccess"

  statements = [
    "Allow dynamicgroup ${oci_identity_dynamic_group.devinstances.name} to manage buckets in compartment DevTeam",
    "Allow dynamicgroup ${oci_identity_dynamic_group.devinstances.name} to read buckets in compartment DevTeam",
    "Allow dynamicgroup ${oci_identity_dynamic_group.devinstances.name} to read objects in compartment DevTeam",
  ]
}

resource "random_string" "key" {
  length  = 16
  special = false
}

data "oci_objectstorage_namespace" "ns" {}

resource "oci_objectstorage_bucket" "backup_bucket" {
  compartment_id = "${var.compartment}"
  namespace      = "${data.oci_objectstorage_namespace.ns.namespace}"
  name           = "${lower(random_string.key.result)}.resetlogs.com"

  access_type = "NoPublicAccess"
}
