# Infrastructure as Code guidelines

## Project structure

### Tags and Affiliate file

In the `tags.auto.tfvars` file :

#### Declaration of all common tags for all resources

```tf
# resources tags
account = "account"
```

#### Declaration of location and affiliates

```tf

### Networks and virtual machines

Networks and virtual machines are defined in the `terraform.tfvars`file

#### Networks structure

A 'network' (= an AWS VPC) is created for each location. A typical network/location should contains 2 public subnets (one for dev, one for prod) and 2 private subnets (one for dev, one for prod)

A NAT Gateway is created to allow machines on the private subnet to reach the public subnet.

An Internet Gateway is created to allow the public subnet to access the public internet.
        
networks = {
  NETWORK_NAME = {
    name               = "NETWORK_NAME"
    network_cidr       = "NETWORK_CIDR"
    availability_zones = ["eu-west-1a"]
    private_subnets = [
      {
        name = "prod"
        cidr = "SUBNET_CIDR"
        tags = ""
      }
      ,{
        name = "dev_NETWORK_NAME"
        cidr = "SUBNET_CIDR"
        tags = ""
      }
    ]
    public_subnets = [
      {
        name = "prod"
        cidr = "SUBNET_CIDR"
        tags = ""
      }
      ,{
        name = "dev_NETWORK_NAME"
        cidr = "SUBNET_CIDR"
        tags = ""
      },
    ]
    internet_gateway   = true
    enable_nat_gateway = true
    single_nat_gateway = true
  },
```

#### Virtual machines structure

The EC2 machines are defined as a list of "clusters", each cluster containing a list of "machines". The repartition of machines by "cluster" was aimed at allowing easier management of similar group of machines.

Machines types are defined in a dictionary ('types') in the same file.

OS types allow to associate a human-readable OS type (ubuntu, windows, etc.) to an AWS AMI. The mapping is defined in `mappings.auto.tfvars` ('amis' field)

In the 'ingress_cidr' field, you can add a protocol (defined in a map in 'ingress_rules' in `mappings.auto.tfvars`) and a list of of CIDR ranges for each protocol.

In the 'data_disk' field, you can set a boolean if you want to add an extra disk of data to the machine

In 'root_disk_type' and 'data_disk_type', you can choose the kind of disk you want to create. Disk types are defined in a map 'generic_disk_parameters' in `mappings.auto.tfvars`. 'gp2' is SSD (efficient but costly, ok for root disks), 'sc1' is HDD (less performant, less expensive, better for data disks)

'autoff' : boolean, set to 'True' if you want to shut down the machine at night

'use_elastic_ip' : boolean, set to 'True' if you want to associate the machine with a dedicated Elastic IP as public IP. Can be necessary for machines with a public IP that should stay the same after reboot.

'data_disk_id' : choose the id of the data disk if you want one. Format should be "/dev/sdb", "/dev/sdf", or similar, for a Linux machine, or "xvdb", "xvdf", or similar, for a Windows machine.

Beware of the following points :

- network name must be an existing VPC
- type should be a defined one
- os should be a defined one
- subnet must be an existing subnet from the defined VPC
- private_ip should be in the CIDR range of the chosen subnet



### Custom Access for specific users to group

In `terraform.tfvars`, in the map 'custom_user_access_group', you can attach specific users to IAM groups, per environment and per affiliate.

## Creation of a new Terraform module

Terraform modules are stored in the `terraform` folder, using the following structure :

terraform						-> folder containing all the Terraform modules, organized by Cloud provider and functionalities
├── aws
│   ├── cluster
│   │   ├── main.tf
│   │   ├── outputs.tf			-> typical module structure
│   │   └── variables.tf
│   ├── instance
│   ├── monitoring
│   ├── network
│   ├── provider.tf
│   ├── storage
│   └── templates				-> templates for cloudinit and AWS IAM
│       ├── cloudinit_templates
│       │   └── cloudinit.yml.tpl
│       └── iam_templates
│           └── data_engineer_policy.json
├── azure
│   └── ...
└── gcp
   └── ...