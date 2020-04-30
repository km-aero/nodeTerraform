# Two Tier Structure Node Mongo Terraform
This repository contains orchestration instructions for a two-tier (public and private) infrastructure. We create 2 instances for the node app and the database seperately in two different subnets and we also create the surrounding structure inside the vpc. 

# Prerequisites
I have run the cookbook using the below prerequisites:
- AWS AMI (Amazon Machine Image)
- AWS account
- Git v2.24.1
- Terraform v0.12.24

# Setup


# How To
Clone the repository, navigate into the nodeTerraform directory and follow the below steps.
- Initialise Terraform
```terraform
$ terraform init
```
- Check the plan for any errors (optional)
```terraform
$ terraform plan
```
- Apply the orchestration rules (this also does the above plan before you say yes)
```terraform
$ terraform apply
```

## Author
**Kevin Monteiro** - *DevOps Engineer* - [km-aero](https://github.com/km-aero)
