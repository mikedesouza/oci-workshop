data "oci_core_images" "myimage" {
  #Required
  compartment_id = "${var.compartment}"

  #Optional
  display_name = "LiveCode"
}

resource "oci_core_instance" "myinstance" {
  availability_domain = "${lookup(data.oci_identity_availability_domains.primary_availability_domains.availability_domains[0],"name")}"
  compartment_id      = "${var.compartment}"
  display_name        = "livecode-instance"

  source_details {
    source_type = "image"
    source_id   = "${data.oci_core_images.myimage.images.0.id}"
  }

  shape = "VM.Standard1.1"

  create_vnic_details {
    subnet_id              = "${module.livecode.public_subnets[0]}"
    skip_source_dest_check = true
  }

  metadata {
    ssh_authorized_keys = "${var.ssh_public_key}"
    user_data           = "${base64encode(data.template_file.userdata.rendered)}"
  }
}

data "template_file" "userdata" {
  template = "${file("${path.module}/instance.tpl")}"

  vars {
    workshop_version = "${lookup(data.external.version.result, "oci-workshop")}"
    tweet            = "1013378279347286016"
  }
}

data "oci_core_vnic_attachments" "myinstancevnic" {
  compartment_id      = "${var.compartment}"
  availability_domain = "${lookup(data.oci_identity_availability_domains.primary_availability_domains.availability_domains[0],"name")}"
  instance_id         = "${oci_core_instance.myinstance.id}"
}

data "oci_core_vnic" "myinstancevnic" {
  vnic_id = "${lookup(data.oci_core_vnic_attachments.myinstancevnic.vnic_attachments[0],"vnic_id")}"
}

data "oci_core_private_ips" "myprivateip" {
  vnic_id = "${data.oci_core_vnic.myinstancevnic.id}"
}

data "oci_core_public_ips" "mypublicips" {
  compartment_id      = "${var.compartment}"
  scope               = "AVAILABILITY_DOMAIN"
  availability_domain = "${lookup(data.oci_identity_availability_domains.primary_availability_domains.availability_domains[0],"name")}"

  filter {
    name   = "private_ip_id"
    values = ["${lookup(data.oci_core_private_ips.myprivateip.private_ips[0], "id")}"]
  }
}

output livecode_url {
  value = "http://${lookup(data.oci_core_public_ips.mypublicips.public_ips[0], "ip_address")}"
}
