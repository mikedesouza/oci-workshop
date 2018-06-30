data "terraform_remote_state" "terraform" {
  backend = "http"

  config {
    address = ""
  }
}

output "workshop-version" {
  value = "${data.terraform_remote_state.terraform.oci-workshop}"
}
