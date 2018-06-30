# Manage state properly

Terraform state is a very important file! It is used behind the scene to track
your provider resource internal identifier and how they are linked to the
project resources. At the beginning of this part, you should have a file
`terraform.tfstate` in your `terraform` directory that is the current state.

This file should not be considered as part of the project. The reason is your
code could have N representations: 

- One on production
- One on staging
- ...

This part consists in pushing that file on an OCI bucket and referencing it
as your terraform back-end.

## Secure your state on a bucket

Send the state file to a bucket so that it can be secured and shared between
people in the team. In order to proceed:

- Decide a name for your bucket that is unique

```shell
export BUCKET=princess.resetlogs.com
```

- Create the bucket in the compartment you have created in the previous part

```shell
oci os bucket create \
  --compartment-id=${TF_VAR_compartment} \
  --public-access-type NoPublicAccess \
  --name ${BUCKET}
```

- Upload the current state to your bucket

```shell
cd terraform
oci os object put --bucket-name=${BUCKET} \
  --file=terraform.tfstate \
  --name=/terraform/princess-stack/terraform.tfstate
```

- The way terraform supports the OCI provider as a backend for now is with
  pre-authenticated requests for now. It has 2 main limits that are, you cannot
  lock the resource and you cannot use a set of resource that is needed for
  the terraform `worskpace` feature. To continue with the setup, you should
  create a pre-authenticated requests for your file:

```shell
ACCESS_URI=$(oci os preauth-request create \
  --bucket-name=${BUCKET} \
  --name=terraform-princess \
  --object-name=/terraform/princess-stack/terraform.tfstate \
  --access-type=ObjectReadWrite \
  --time-expires 2020-12-31T23:59Z \
  --query='data.{uri:"access-uri"}' \
  --output=json | jq -r '.uri')
```

- The pre-authenticated requests being created, you can access the associated
  object with the command below:

```shell
curl -L "https://objectstorage.${TF_VAR_region}.oraclecloud.com${ACCESS_URI}"

```

# Declare the remote state as your backend

Because the pre-authenticated request URL should remain secret and you can have
several backends to your terraform project, you cannot send the `backend.tf`
file to your project. Create that file in the directory and add it to your
`.gitignore`:

```shell
cd terraform
cat >backend.tf <<EOF
terraform {
  backend "http" {
    address       = "https://objectstorage.${TF_VAR_region}.oraclecloud.com${ACCESS_URI}"
    update_method = "PUT"
  }
}
EOF
```

# Re-initialize your project

Once done, you can re-initialize your project state and verify you can now
access the remote state:

```shell
# Remove the local state and configuration
cd terraform
rm -rf .terraform terraform.tfstate*

# Initialize the state from the `backend.tf` file
terraform init

# Verify the state is used
terraform state list
```

