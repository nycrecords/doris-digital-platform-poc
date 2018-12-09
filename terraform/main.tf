provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "doris_services" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "doris_services_subnet" {
  vpc_id            = "${data.aws_vpc.doris_services.id}"
  availability_zone = "us-east-1b"
  cidr_block        = "${cidrsubnet(data.aws_vpc.doris_services.cidr_block, 4, 1)}"
}

resource "aws_security_group" "allow_all" {
  name        = "allow_all"
  description = "Allow all inbound traffic"
  vpc_id      = "${aws_vpc.doris_services_subnet.id}"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_ami" "base" {
  most_recent = true

  filter {
    name   = "name"
    values = ["doris-hyku-base-centos*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["self"]
}

resource "aws_instance" "storage" {
  ami = "${data.aws_ami.base.id}"
  instance_type = "m5.xlarge"
  disable_api_termination = true
  key_name = "doris-services-keys"
  vpc_security_group_ids = ["${data.aws_security_group.allow_all.id}"]
  subnet_id = "${data.aws_subnet.doris_services_subnet.id}"
  root_block_device = {
    volume_size = "10000" # 10TB
  }
  tags {
    Name = "storage-1"
    Type = "storage"
  }
}

resource "aws_instance" "hyku" {
  ami = "${data.aws_ami.base.id}"
  instance_type = "m5.large"
  disable_api_termination = true
  key_name = "doris-services-keys"
  vpc_security_group_ids = ["${data.aws_security_group.allow_all.id}"]
  subnet_id = "${data.aws_subnet.doris_services_subnet.id}"
  root_block_device = {
    volume_size = "500" # 10TB
  }
  tags {
    Name = "hyku-1"
    Type = "hyku"
  }
}

resource "aws_instance" "archivematica" {
  ami = "${data.aws_ami.base.id}"
  instance_type = "m5.large"
  disable_api_termination = true
  key_name = "doris-services-keys"
  vpc_security_group_ids = ["${data.aws_security_group.allow_all.id}"]
  subnet_id = "${data.aws_subnet.doris_services_subnet.id}"
  root_block_device = {
    volume_size = "1000" # 1TB
  }
  tags {
    Name = "archivematica-1"
    Type = "archivematica"
  }
}