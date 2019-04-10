# encoding: utf-8

##
# Backup v5.x Configuration
#
# Documentation: http://backup.github.io/backup
# Issue Tracker: https://github.com/backup/backup/issues

`curl -X PUT "localhost:9200/_snapshot/my_backup/snapshot-#{Time.now.strftime("%Y-%m-%d")}?wait_for_completion=true"`

Backup::Model.new(:archivematica, 'Backup the database and files for Archivematica') do
  ##
  # Split [Splitter]
  #
  # Split the backup file in to chunks of 250 megabytes
  # if the backup file size exceeds 250 megabytes
  #
  split_into_chunks_of 250

  database MySQL do |db|
    db.username           = ENV['MYSQL_USERNAME']
    db.password           = ENV['MYSQL_PASSWORD']
    db.host               = ENV['MYSQL_HOSTNAME']
    db.port               = ENV['MYSQL_PORT']
  end

  archive :snapshots do |archive|
    archive.add "/opt/elasticsearch/backups/127.0.0.1-node1"
    archive.add "/var/archivematica"
    archive.tar_options '--warning=no-file-changed'
  end

  compress_with Gzip

  #$ openssl aes-256-cbc -d -base64 -in my_backup.tar.enc -out my_backup.tar
  encrypt_with OpenSSL do |encryption|
    encryption.password = ENV['MYSQL_PASSWORD']
    encryption.base64   = true
    encryption.salt     = true
  end

  Storage::S3.defaults do |s3|
    s3.region             = ENV['AWS_REGION']
    s3.bucket             = ENV['BACKUP_BUCKET']
    s3.path               = ''
    s3.encryption         = :aes256
    s3.storage_class      = :standard
    s3.access_key_id      = ENV['AWS_ACCESS_KEY_ID']
    s3.secret_access_key  = ENV['AWS_SECRET_ACCESS_KEY']
  end

  # Grandfather - Father - Sons implementation
  time = Time.now

  if time.day == 1  # first day of the month
    storage_id = :monthly
    keep = 12000  # only good until the year 3014
    store_with S3, storage_id do |s3|
      s3.keep               = keep
    end
  end

  if time.sunday?
    storage_id = :weekly
    keep = 8
    store_with S3, storage_id do |s3|
      s3.keep               = keep
    end
  end

  storage_id = :daily
  keep = 14

  store_with S3, storage_id do |s3|
    s3.keep               = keep
  end

  notify_by Mail do |mail|
    mail.on_success           = true
    mail.on_warning           = true
    mail.on_failure           = true

    mail.from                 = 'appdev@records.nyc.gov'
    mail.to                   = 'appdev@records.nyc.gov'
    mail.cc                   = 'support@notch8.com'
    mail.address              = ENV['SMTP_ADDRESS']
    mail.port                 = ENV['SMTP_PORT']
    mail.user_name            = ENV['SMTP_USERNAME']
    mail.password             = ENV['SMTP_PASSWORD']
    mail.authentication       = 'plain'
    mail.encryption           = :starttls
  end
end
