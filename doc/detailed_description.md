# Detailed description

## Infrastructure as Code

### Folder organization

The Terraform files are structured in two separate folders :

```txt
├── infrastructure
└── terraform
```

- `infrastructure` contains all the files dedicated to the specific description of the project's infrastructure
- `terraform` contains a list of subfolders defining various terraform modules that can be easily re-used in the project's definition. These modules are not projet-specific

```txt
infrastructure				-> definition of hardware environments for Terraform
├── main							-> a typical environment / you can develop others following this model
│   ├── main.tf						-> TF script for rearranging 
│   ├── modules.tf					-> TF script for accessing module files from terraform folder 
│   ├── variables.tf				-> TF script for declaring variables 
│   ├── tags.auto.tfvars			-> TF vars file for declaring locations, affiliates and tags
│   ├── mappings.auto.tfvars		-> TF vars file for mapping OS/Cloud/machine types/ingress & egress port rules
│   ├── outputs.tf					-> TF output file : defines which parameters will be dumped after architecture deployment
│   ├── terraform.tfvars			-> TF var file for defining your architecture : PLEASE DEFINE YOUR ARCHITECTURE HERE !
├── setup_tf_proj_aws.sh			-> script called by deploy_infra.sh for setting AWS account credentials as env variables
├── upgrade_terraform.sh			-> deprecated script for upgrading terraform files version from 0.11 to 0.12
```

### Architecture syntax

Please follow [these guidelines](./doc/iac_guidelines.md) for writing and editing Terraform files and modules for the project.

### Execution

The IaC is launched with the following command :

```bash
./deploy_infra.sh <DEPLOY_or_DESTROY> <aws_OR_azure_OR_gcp>
```

### Under the hood

#### Setting SSH keys

The script `deploy_infra.sh` will call the subscript `tools/prepare_ssh_keys.sh` to parse the `infrastructure/<PROJECT>/terraform.tfvars` file in order to get the list of resources needing an SSH key. It essentially means EC2 VMs.

IMPORTANT NOTICE : for the moment, the SSH keys are uniquely identified PER VPC and PER ENVIRONMENT

The list of necessary keys is dumped as a temporary file `tools/keys.txt` (erase and remplace if already exists). Then the script `tools/prepare_ssh_keys.sh` check if the SSH keys already exist in `credentials/.ssh/private` (as .pem files). If the keys do not exist, the script create them with ssh-keygen Unix command and store public and private keys (as .pem files) respectively in `credentials/.ssh/public` and `credentials/.ssh/private`.

The SSH keys thus created can be uploaded to AWS through Terraform, using the `ssh` module

#### Creating templates for access policies

The script `deploy_infra.sh` will call the subscript `tools/prepare_iam_policies.sh` to parse the `infrastructure/<PROJECT>/tags.auto.tfvars` file using the python script `tools/extract_iam_policies.py` in order to get the list of locations and affiliates.

The generated policy files are created in `terraform/templates/iam_templates`.

You can change the format of the generated policy files by editing `tools/extract_iam_policies.py`.

#### Applying Terraform and dumping outputs

The script `deploy_infra.sh` will execute Terraform from the `infrastructure/<PROJECT>` folder, where it will call `terraform init` and `terraform apply`.

It will then call `terraform output` to the folder `ansible/inventory` as a json file. This json file contains all the information about our cloud infrastructure.

#### Managing Terraform tfstate

Terraform works by 'folder', which means that when running a terraform command, it will make use of all the '*.tf' and '*tfvars' files contained in the folder. You can add extra files and folders containing terraform files through extra CLI inputs. When launching Terraform in a folder, Terraform will create a 'hidden' folder named '.terraform' where it will download and strore many metadata and plugins.

By default, the 'state' of the architecture created by Terraform is located in the '.terraform' folder. You can change this by providing an extra 'backend' section inside the 'terraform' section at the beginning of 'main.tf'. 

In the current project, the 'main' tfstate is hosted on a S3 bucket on AWS, named 'datalake-iac', and located in 'prod_v2/state.tfstate' file on this bucket.

#### Specific targetting of resources using Terraform

When the number of resources in a tfstate is large, a refresh (be conscious that a 'plan' or 'apply' command in Terraform does include a 'refresh') can take a lot of time. 

If you want to run commamnds that only affect specific modules of the architecture, you can use 

```bash
terraform apply -target=module.<MODULE_NAME>
```

You can even target resources more precisely :

```bash
terraform apply -target=module.<MODULE_NAME>.<RESOURCE_TYPE>
```

or

```bash
terraform apply -target=module.<MODULE_NAME>.<RESOURCE_TYPE>.<RESOURCE_NAME>
```

#### Importing / exporting resources to / from tfstate

In some cases, you could want to import a resource created in the AWS GUI (or from another Terraform project) into a tfstate.

You can do this by running (at the root of your current Terraform project) :

```bash
terraform import <TARGET_PATH_OF_INSERTED_RESOURCE> <AWS_ID_OF_RESOURCE>
```

You can also remove a resource from your tfstate like this (but be conscious that the resource will only be removed from the tfstate, not destroyed - it will still be visible in the AWS GUI)

```bash
terraform state rm <PATH_OF_RESOURCE_TO_DELETE>
```

Finally, you can move a resource inside the tfstate, from a place to another, like this

```bash
terraform state mv <PATH_OF_RESOURCE_TO_MOVE> <TARGET_PATH_OF_MOVED_RESOURCE>
```

ADVICE : do not hesitate to edit/hack the 'deploy_infra.sh', at the end of the script (in the 'Terraform' section), through adding the '-target' parameters after 'terraform apply'.

#### Avoiding destruction of resources

When importing existing resources to the tfstate, it is often extremely important to avoid destruction of resources in the 'terraform apply' step. 

There are two reasons for (unwanted) resource destruction during an apply :

- moving a resource inside a list of Terraform resources : Terraform cannot for the moment manage cleverly the insertion/pop of elements inside lists, and will try to destroy the moved elements and recreate them at the desired position
- updating a resource on a parameter that force recreation. Some AWS resources and resource parameters (typically S3 buckets) cannot be updated without destroying and recreating them, a process that can be problematic when the initial resource is already in use.

The current way to avoid destruction when integrating new resources is :

- create the resources in the Infra as Code scripts (main.tf, terraform.tfvars, modules, etc)
- run a 'terraform plan' or 'terraform apply' (and answer 'no' when Terraform asks for confirmation of apply). Terraform will output a list of all the proposed modifications implied by your previous IaC modifications. Terraform plan shows planned creations of resources and parameters with '+', removal with '-', edition with '~'
- use 'terraform import' to import all pre-existing AWS resources at the position in the IaC where Terraform wanted to create fresh new resources in the previous step
- use 'terraform state mv' to move AWS resources already listed in the tfstate, but not at the correct position (typically Terraform wants to destroy a resource and recreate it somewhere else). In some cases, you will even need to switch position of resources in list. You can always temporarily move a Terraform resource at a huge position in a Terraform list before re-moving it at a correct position.
- edit IaC parameters to meet the state planned by Terraform.
- loop through previous steps, until you reach complete coherence between current state and planned state.

## Configuration Management

The output of Terraform is dumped as a json file in``ansible/inventory/terraform_outputs.json`.

### Execution

The Configuration Management is launched with the following command :

```bash
./configure_infra.sh
```

### Folder organization

The Ansible resources are gathered in the `ansible` folder.

This folder is organized as follows :

```txt
ansible							-> folder containing Ansible playbooks and roles, plus host files
├── ansible.cfg					-> config file for Ansible
├── requirements.yml			-> list of existing Ansible roles to download from Ansible Galaxy
├── cloudwatch					-> folder for AWS cloudwatch specific config files
├── inventory					-> folder for remote hosts inventory for Ansible
│   ├── envt.hosts				-> hosts file
│   ├── ssh.cfg					-> config file for allowing Ansible to manage SSH proxies
│   └── terraform_outputs.json	-> output of Terraform, used to collect host machines' IPs
├── playbooks					-> folder storing single, one-task Ansible's playbooks
├── roles						-> folder storing complex Ansible's roles
│   ├── airflow
│   ├── gitlab					-> existing roles for configuring tools
│   ├── jenkins
│   ├── nexus
│   └── ...
└── scripts						-> custom Python's script for specific configuration
    ├── airflow
    └── ...
```

### Under the hood

#### Ansible configuration

Ansible's default configuration can be override by setting the environment variable 'ANSIBLE_CONFIG'. By default, the `configure_infra.sh` script does set this variable to the file `ansible/inventory/ansible.cfg`. This file defines some SSH parameters that will be used by Ansible at run for connecting to the remote machines, especially a file named `ansible/inventory/ssh.cfg`

The file `ansible/inventory/envt.hosts` lists all virtual machines created by Terraform, and associates their IPs with a name - per machine or group of machines - that will allow to target them when calling Ansible.

The file `ansible/inventory/ssh.cfg` describes the way Ansible can access all the target machines, including username at connection, and potentially defining a SSH proxy.

This file is generated when running `configure_infra.sh` : the python script `ansible/scripts/set_hosts_file_ssh_proxy.py` is called, that will dynamically generate the `ssh.cfg` file by parsing the `ansible/inventory/terraform_outputs.json` file.

If the virtual machine is a `bastion` (defined by using the word 'bastion' as its name), then the IP associated with it will be its public IP in `ssh.cfg` and `envt.hosts`. Otherwise, the VM is associated with its private IP.

The script `ansible/scripts/set_hosts_file_ssh_proxy.py` will give a specific name to each virtual machine, using both its name, its VPC name (= location) and its subnet, but will also create groups of machines according to their environment (dev or prod for example) and their role (remote engine, bastion, etc).

#### Execution of playbooks

Once the `ssh.cfg` and the `envt.hosts` files are generated, `configure_infra.sh` will run Ansible playbooks on the target machines, using the standard command 

```bash
cd ansible/inventory
ansible-playbook -i ./envt.hosts --limit "<HOSTS_TARGET>" ../playbooks/<FEATURE_TO_CONFIGURE>.yml
```
