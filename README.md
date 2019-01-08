# Fill out terraform/.env, packer/config.json and hyku/.env

## Install Dependencies
`brew install packer terraform`
`gem install dotenv` 


## Init Terraform

`cd terraform && dotenv terraform init`


## Set up the keys in aws for Packer to run

`cd terraform && dotenv terraform apply -target=aws_key_pair.doris-services-keys`
