# A Proof of Concept implementation of digital archiving tools. The system will upgrade the agencies archival and information management standards and build capacity. Includes Hyku/Samvera, Archivematica.

# Initial Setup
## Install Dependencies
`brew install packer terraform`
`gem install dotenv`

## Check out the code from Git

`git clone https://gitlab.com/notch8/doris.git`

## Init the submodules
`cd doris && git submodules init && git submodules update`

## Pack secrets on working machine

Secrets should not be committed and can by transferred to new machines by first packing them as a tarzip and then copying them. The list of files needed and editable is maintained in bin/pack-secrets script. They should only be transferred securely.

`./bin/pack-secrets`

## Copy secrets.tgz to root of this project

## Unpack secret files

`./bin/unpack-secrets`

# Deploy updates to Hyku

`cd hyku && cap production deploy`

# View Hyku app config

`cd hyku && cap production config:show`

# Change Hyku app config

`cd hyku && cap production config:set SENTRY_DSN=XYZ SOMETHING=value`

# Install existing AMIs

## Init Terraform

`cd terraform && dotenv terraform init`


## Create the infrastructure

`cd terraform && dotenv terraform apply `


# Backups
## Backup Tools

We use the [backup gem](http://backup.github.io/backup/v4/) to perform our backups. It has a lot of built in tools for dealing with most of the stack and runs very dependably. An email is sent at the end of each daily backup. This is set as a cron job on the Hyku server and on the Archivematica Server.

## What is Backed Up
### Hyku

For Hyku we backup the database that Hyku uses directly (to store users and session info), along with the database that Fedora uses. We back up all config files and derivatives (to speed restoration). Code is already in Github and thus does not need separate backup. The Redis queue and Solr indexes are not backed up currently as they can be regenerated, but this might be something to consider expanding when moving out of POC.

### Archivematica

Archivematcia is backed up by running a backup script on the Archivematica server. This script lives in the repo at `./bin/archivematica-backup.rb`. Archivematica requires backing up Mysql, Elastic Search and a working file directory. More information about Archivematica backups can be found at [this page](https://www.archivematica.org/fr/docs/archivematica-1.7/admin-manual/maintenance/maintenance/#data-back-up)

### S3 Files

Currently S3 files are not backed up outside of the Amazon bucket configuration. This means they are protected from faults such as machine failure or even data center failure, but are not protected from user issues (such as mass delete) or a complete partner outage (aka all of AWS going down or losing data).

## Backup Schedule

Currently backups are taken nightly. This can be scaled up or down easily by editing the cron jobs on the servers.

# Restore Procedure

Backups are encrypted and stored in S3. To restore backups, first download the correct backup file to S3.  At that point the backup needs to be decrypted as per [instructions here](http://backup.github.io/backup/v4/encryptor-openssl/).  Password is found in the secure env files under MYSQL_PASSWORD. After the tar file is decrypted Mysql restore is done via the mysql command and uploaded files can be copied back in to place manually. 

# Creating new AMIs with Packer

## Make sure keypair is set up correctly

`cd terraform`

`dotenv terraform init`

`dotenv terraform apply -target=aws_key_pair.doris-services-keys`

## Change configs as desired in packer/config.json

## Create the base AMI
`./build.sh base ami`

## Create the Storage AMI (Fedora/Solr/Mysql/Redis)
`./build.sh storage ami`

## Create the Hyku AMI
`./build.sh hyku ami`

## Create the Archivematica AMI
`./build.sh archivematica ami`

# Services

All services are run via systemctl. They can be started, stopped, restarted, etc with commands like `sudo systemctl start httpd`

On the Hyku host the following are available:

`systemctl status httpd` # Apache and Passenger

`systemctl status sidekiq` # Sidekiq background job runner

It is sometimes useful to restart just Passenger w/o restarting Apache. This is done as follows

`passenger-config restart-app /opt/doris-hyku/current`

On the Archivematica host:

`systemctl status node1_elasticsearch` # Search services

`systemctl status archivematica-dashboard` # Dashboard microservice

`systemctl status nginx` # Web proxy

`systemctl status archivematica-mcp-client` # MCP microservice

Storage host:

`systemctl status mysql` # Database service (serves Fedora, Archivematica and Hyku)

`systemctl status solr` # Solr search service

`systemctl status redis` # Key / Value store (used by Hyku for background job queuing)

`systemctl status fedora` # Fedora service

All systems have `ossec` (intrusion and system health) and `clamav` running as services as well.

# Importing in Hyku

Hyku currently supports a command line importer, though a visual method allowing librarians better access is planned. On the commandline, from the hyku root directory (currently `/opt/doris-hyku/current`) the command for CSV import is `RAILS_ENV=production ./bin/import_from_csv VISIBILITY PATH_TO_CSV ATH_TO_FILES`.  An example of this for the initial import is `RAILS_ENV=production ./bin/import_from_csv public /opt/import.csv /opt/stora^C/DPC\ Public\ Charities`.

Supported headers can be found in this document: https://docs.google.com/spreadsheets/d/1ErgashmCLwQB17_HNhIIgEFwPbaM0N_1Xkj5KzqWKQ0/edit?usp=sharing
