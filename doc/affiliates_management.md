# Managing countries and affiliates

## Architecture overview


terraform apply -backend-config=backend.tfvars  -var-file=nifi.tfvars


All the 'affiliates' are clustered into 'countries'.

There is one VPC for each country. The Talend remote engine and Talend studio machines are mutualized for all the affiliates of each country.


## Creation of a new affiliate

You must add the new affiliate in `tags.auto.tfvars` in 'affiliate' and 'affiliate_bis'

You must attach the new affiliate to a location in the 'aff2net' map (format : "AFFILIATE" = "LOCATION")

You must Terraform apply (at least) the following modules :



if possible in that order. Nevertheless, the best practice would be to run the whole terraform project (can take a lot of time).

## Creation of a new location

You must add the new location in `tags.auto.tfvars` in 'locations'

Then, you must define the new network and its machines in `terraform.tfvars`

You must Terraform apply (at least) the following modules :

- network
- instance

if possible in that order. Nevertheless, the best practice would be to run the whole terraform project (can take a lot of time).