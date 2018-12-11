provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "doris_services" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags {
    Name = "doris-services-vpc"
  }
}

resource "aws_internet_gateway" "doris_services_gateway" {
    vpc_id = "${aws_vpc.doris_services.id}"
}

resource "aws_subnet" "doris_services_subnet" {
  vpc_id            = "${aws_vpc.doris_services.id}"
  availability_zone = "us-east-1b"
  cidr_block        = "${cidrsubnet(aws_vpc.doris_services.cidr_block, 4, 1)}"
}

resource "aws_route_table" "doris_services_route_table" {
    vpc_id = "${aws_vpc.doris_services.id}"

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.doris_services_gateway.id}"
    }

    tags {
        Name = "Public Subnet"
    }
}

resource "aws_route_table_association" "doris_service_route_association" {
    subnet_id = "${aws_subnet.doris_services_subnet.id}"
    route_table_id = "${aws_route_table.doris_services_route_table.id}"
}

resource "aws_security_group" "allow_all" {
  name        = "allow_all"
  description = "Allow all inbound traffic"
  vpc_id      = "${aws_vpc.doris_services.id}"

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

# resource "aws_lb" "alb_front" {
# 	name		=	"front-alb"
# 	internal	=	false
# 	security_groups	=	["${aws_security_group.allow_all.id}"]
# 	subnets		=	["${aws_subnet.doris_services_subnet.id}"]
# 	#enable_deletion_protection	=	true
# }

# resource "aws_lb_target_group" "alb_front_http" {
# 	name	= "alb-front-https"
# 	vpc_id	= "${aws_vpc.doris_services.id}"
# 	port	= "80"
# 	protocol	= "HTTP"
# 	health_check {
#                 path = "/"
#                 port = "80"
#                 protocol = "HTTP"
#                 healthy_threshold = 2
#                 unhealthy_threshold = 2
#                 interval = 5
#                 timeout = 4
#                 matcher = "200-308"
#         }
# }

resource "aws_key_pair" "doris-services-keys" {
  key_name   = "doris-services-keys"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCzWJ2JxLo0xyC5+KCIE9vslBmmpKmqexQhuIgMNQdvycH2cUAdlRksXcgXRzGJNMjGdJkZiXs56HFa5ZbCTnPcbD8bmcB3mY7hX5BQRTyoQwniMItRjHTPXcwep6LsuepK1xSXKIXHnwy3wLcRP/N0LbwTHrlgY5nv8YxOHrGLK7oHj7MAkLZCSjt7njBa6J8jYOg2/cx2lvc30aBFM3aIaDEpif3+/rIGAfXJP+ThWj7SKgLgmTS6mAztCyn/6gmFjptN4Uegk6CyCK906qSkfdKr4DQPafkjSeM9MMECL4T5xSdAYb7snaNABKvn4iSmV1xPuuJi4Bhqwal7j5Sx doris-services-key"
}

resource "aws_s3_bucket" "doris-services-assets" {
  bucket = "doris-services-assets"
  acl    = "public-read"
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
data "aws_ami" "storage" {
  most_recent = true

  filter {
    name   = "name"
    values = ["doris-hyku-storage-centos*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["self"]
}
data "aws_ami" "hyku" {
  most_recent = true

  filter {
    name   = "name"
    values = ["doris-hyku-hyku-centos*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["self"]
}
# data "aws_ami" "archivematica" {
#   most_recent = true

#   filter {
#     name   = "name"
#     values = ["doris-hyku-archivematica-centos*"]
#   }

#   filter {
#     name   = "virtualization-type"
#     values = ["hvm"]
#   }

#   owners = ["self"]
# }
# data "aws_ami" "base" {
#   most_recent = true
#   filter {
#     name = "name"
#     values = ["RHEL-7.6_HVM_GA-201*-x86_64-0-Hourly2-GP2"]
#   }
#   filter {
#     name   = "virtualization-type"
#     values = ["hvm"]
#   }

#   owners = ["309956199498"]
# } 

resource "aws_instance" "storage" {
  ami = "${data.aws_ami.storage.id}"
  instance_type = "m5.xlarge"
  #disable_api_termination = true
  key_name = "doris-services-keys"
  vpc_security_group_ids = ["${aws_security_group.allow_all.id}"]
  subnet_id = "${aws_subnet.doris_services_subnet.id}"
  associate_public_ip_address = true
  root_block_device = {
    volume_size = "1000" # 1TB
  }
  tags {
    Name = "storage-1"
    Type = "storage"
  }
}

resource "aws_instance" "hyku" {
  ami = "${data.aws_ami.hyku.id}"
  instance_type = "m5.large"
  #disable_api_termination = true
  key_name = "doris-services-keys"
  vpc_security_group_ids = ["${aws_security_group.allow_all.id}"]
  subnet_id = "${aws_subnet.doris_services_subnet.id}"
  associate_public_ip_address = true
  root_block_device = {
    volume_size = "500" # 10TB
  }
  tags {
    Name = "hyku-1"
    Type = "hyku"
  }
}

# resource "aws_instance" "archivematica" {
#   ami = "${data.aws_ami.archivematica.id}"
#   instance_type = "m5.large"
#   #disable_api_termination = true
#   key_name = "doris-services-keys"
#   vpc_security_group_ids = ["${aws_security_group.allow_all.id}"]
#   subnet_id = "${aws_subnet.doris_services_subnet.id}"
#   associate_public_ip_address = true
#   root_block_device = {
#     volume_size = "1000" # 1TB
#   }
#   tags {
#     Name = "archivematica-1"
#     Type = "archivematica"
#   }
# }


# resource "aws_lb_target_group_attachment" "frontent_http" {
#   target_group_arn = "${aws_lb_target_group.alb_front_http.arn}"
#   target_id        = "${aws_instance.hyku.id}"
#   port             = 80
# }

resource "aws_route53_record" "doris-db" {
  zone_id = "Z1RXNGAAOJQGI4"
  name    = "doris-db.notch8.com"
  type    = "A"
  ttl     = "300"
  records = ["${aws_instance.storage.public_ip}"]
}

resource "aws_route53_record" "doris-hyku" {
  zone_id = "Z1RXNGAAOJQGI4"
  name    = "doris-hyku.notch8.com"
  type    = "A"
  ttl     = "300"
  records = ["${aws_instance.hyku.public_ip}"]
}

# resource "aws_route53_record" "doris-archivematica" {
#   zone_id = "Z1RXNGAAOJQGI4"
#   name    = "doris-archivematica.notch8.com"
#   type    = "A"
#   ttl     = "300"
#   records = ["${aws_instance.archivematica.public_ip}"]
# }