# Fill out terraform/.env, packer/config.json and hyku/.env

## Install Dependencies
`brew install packer terraform`
`gem install dotenv` 


# Deploy updates to Hyku

```
cd hyku && cap production deploy
```

# View Hyku app config
```
cd hyku && cap production config:show
```

# Change Hyku app config
```
cd hyku && cap production config:set SENTRY_DSN=XYZ SOMETHING=value
```

# Install existing AMIs

## Copy secrets.tgz to root of this project

## Unpack secret files

```bash
./unpack-secrets
```

## Init Terraform

`cd terraform && dotenv terraform init`


## Create the infrastructure

`cd terraform && dotenv terraform apply `


# Creating new AMIs with Packer

## Make sure keypair is set up correctly

```
cd terraform
dotenv terraform init
dotenv terraform apply -target=aws_key_pair.doris-services-keys
```

## Change configs as desired in packer/config.json

## Create the base AMI
./build.sh base ami

## Create the Storage AMI (Fedora/Solr/Mysql/Redis)
./build.sh storage ami

## Create the Hyku AMI
./build.sh hyku ami

## Create the Archivematica AMI
./build.sh archivematica ami

