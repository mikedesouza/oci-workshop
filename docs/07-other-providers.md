# Other providers

The previous part already shown how to use the `random` provider to generate
a unique bucket name. Terraform provide many other providers that comes
out of the box, including `null`, `http`, `external`, `template`. It also
allow to access another terraform stack with `terraform_remote_state`. This
part provide a few example of these configuration.

## The external provider

The external provider is by far one of the most valuable provider. One of
the issue though is that you must have a command that works on your various
system which usually finishes by leading to giving up on Windows. The example
provides as part of this repository relies on the script `version.sh` below:

```shell
#!/usr/bin/env bash

set -e

version() {
  git tag -l --merged HEAD --sort=-creatordate "$1@*" | head -1 | cut -d'@' -f2
}

OCI_WORKSHOP=$(version oci-workshop)

jq -n \
  --arg oci_workshop "$OCI_WORKSHOP" \
  '{ "oci-workshop": $oci_workshop }'
```

What this script does is return the first parent tag that looks like
`oci-workshop@version` and return it as part of a JSON file. It requires `git`
`bash` and `jq` to be installed. You can test it on the repository by running
the command below:

```shell
cd terraform
echo '{ "workspace": "default" }' | ./version.sh
```

The content of `version.tf` show how to use this provider. This consists in:

- the `data "external" "version"` declaration to defines the script and the
  input to serve
- the `lookup(data.external.version.result, "oci-workshop")` shows how to
  get the output.


```hcl
data "external" "version" {
  program = ["${path.module}/version.sh"]

  query = {
    workspace = "${terraform.workspace}"
  }
}

output "oci-workshop" {
  value = "${lookup(data.external.version.result, "oci-workshop")}"
}
```

## The template provider

The template provider allows to create files from templates and use them to
provision other resources. This part contains such an example of a file in
`instance.tpl`. The following section references the `workshop_version`
variable that is provided by the resource itself:

```text
  - echo "${workshop_version}" >/etc/oci-workshop.version
```

> Note: if you need to have a `$` in your stack, escape it with `$$`

The section below creates a `template_file` and pass the `workshop_version`
parameter:

```hcl
data "template_file" "userdata" {
  template = "${file("${path.module}/instance.tpl")}"

  vars {
    workshop_version = "${lookup(data.external.version.result, "oci-workshop")}"
  }
}
```

If you want to get the output of the template, you can simply reference the
template_file rendered property like below:

```hcl
user_data = "${base64encode(data.template_file.userdata.rendered)}"
```

## Accessing the output of another stack

To simplify and consolidate resource, you often want to access values from a stack
from another set of terraform resources. The `terraform_remote_state` data can be
used for that purpose. You'll find an example in the `remote.tf` file located in
`terraform-remote`. In order to use it, you should add the URL from the remote
state of the terraform stack so that the resource looks like below:

```hcl
data "terraform_remote_state" "terraform" {
  backend = "http"

  config {
    address = "https://objectstorage.xxx.oraclecloud.com/p/xxx"
  }
}
```

Once done you can simply access outputs from the first stack with an inference
expression like `data.terraform_remote_state.terraform.oci-workshop`. To test
it is working correctly, run:

```shell
cd terraform-remote
terraform init
terraform apply
```
