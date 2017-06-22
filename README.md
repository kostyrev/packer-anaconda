[![Build Status](https://travis-ci.org/kostyrev/packer-anaconda.svg?branch=master)](https://travis-ci.org/kostyrev/packer-anaconda)
## SSH
### General info
Read this [overview](http://www.unixwiz.net/techtips/ssh-agent-forwarding.html).
### Generate ssh key
Follow this [guide](https://help.github.com/articles/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent/#platform-mac) to generate new ssh key.
### Specify default username and keepalive for ssh (optionally)
```
cat >> ~/.ssh/config <<EOF
Host *
   User kostyrev
   ServerAliveInterval 30
   ServerAliveCountMax 10
EOF
```
## Homebrew (MacOS only)
[Read](https://en.wikipedia.org/wiki/Homebrew_(package_management_software)) about brew and [install](https://brew.sh) it.

## Working with this repository
### Initial cloning
```
cd ~/
git clone https://github.com/kostyrev/packer-anaconda.git
cd packer-anaconda
```
### Pulling recent commits
`git pull --no-edit origin $(git rev-parse --abbrev-ref HEAD) --rebase --ff-only`

### PRs
Read this [guide](https://confluence.atlassian.com/bitbucket/work-with-pull-requests-223220593.html) about pull requests.

## Building AMI (for admins only)
### Using packer
```
make anaconda
```
### Using molecule
Use [molecule](https://molecule.readthedocs.io) to verify that `packer` will build right AMI with all required packages and modifications.

## Using AMI
### Configure required environment variables
`cp .envrc.dist .envrc`
and set appropriate environment variables in it.  

#### AWS_PROFILE
`AWS_PROFILE` is used to configure `aws_access_key_id` and `aws_secret_access_key` to access AWS API in some AWS account.  
For example, you could name your profile `fasten-analytics` and configure it:
```
mkdir ~/.aws/
cat >> ~/.aws/credentials <<EOF
[fasten-analytics]
aws_access_key_id=AKIAIXXXXXXXXXX
aws_secret_access_key=XXXXXXXXXXX
EOF
```
#### TF_VAR_spot_price
`TF_VAR_spot_price` is a price you willing to pay for an instance on the spot market.
Gradually increase this value until your request for instance is fulfilled.

Export those environment variables by sourcing `.envrc` manually  
`. .envrc`  
or  
[read](https://direnv.net) and [setup](https://github.com/direnv/direnv#setup) `direnv`.
> **Note:**
> Use `brew install direnv` on MacOS

> **Note:**
> Do not forget to execute `direnv allow .` after installing.

### Use terraform to request an instance
[Install](https://github.com/kostyrev/ansible-role-terraform) [terraform](https://www.terraform.io/)  
> **Note:**
> Use `brew install terraform` on MacOS

Go to directory with terraform configuration files  
`cd terraform/`  
Before any operations with terraform run  
`terraform plan`  
to verify that terraform will do what you planned it to do.

If everything seems to be ok execute
```
terraform apply
```

### Connect to instance with port forwarding for jupiter
connect to instance  
`ssh -L 127.0.0.1:8888:127.0.0.1:8888 ubuntu@$(terraform output public_address)`  
run jupiter  
`jupyter notebook --port=8888 --no-browser`

### Destroy instance
```
terraform destroy
```
### Demo
[![asciicast](https://asciinema.org/a/bfbhhuiwqi0zx6nrspu5mch4e.png)](https://asciinema.org/a/bfbhhuiwqi0zx6nrspu5mch4e)
