## AWS Provider
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

## Init Credentials Profile and Region
provider "aws" {
  profile = "default"
  region  = "us-east-1"
}


# VPC
resource "aws_vpc" "main" {
  cidr_block       = "10.1.0.0/16"
  tags = {
    Name = "dumbways"
  }
}

# availability zones

data "aws_availability_zones" "available" {
  state = "available"
}

#subnet public
resource "aws_subnet" "public" {
 vpc_id = aws_vpc.main.id
 cidr_block = "10.1.0.0/28"
 tags = {
   Name = "subnetpublic"
 }
}

#subnet private

resource "aws_subnet" "private" {
 vpc_id = aws_vpc.main.id
 cidr_block = "10.1.1.0/28"
 tags = {
   Name = "subnetprivate"
 }
}

#key pair

resource "tls_private_key" "ssh" {
 algorithm = "RSA"
 rsa_bits = 4096
}

resource "aws_key_pair" "ssh" {
 key_name = "Final"
 public_key = tls_private_key.ssh.public_key_openssh
}

output "ssh_private_key_pem" {
value = tls_private_key.ssh.private_key_pem
}

output "ssh_public_key_pem" {
value = tls_private_key.ssh.public_key_pem
}



#Internet Gateway 

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

   tags = {
     Name = "igw"
   }

}

# Route Table Public and association

resource "aws_route_table" "publicroute" {
  vpc_id = aws_vpc.main.id
  route {
     cidr_block = "0.0.0.0/0"
     gateway_id = aws_internet_gateway.gw.id
  }
}


resource "aws_route_table_association" "publicroute" {
   subnet_id = aws_subnet.public.id
   route_table_id = aws_route_table.publicroute.id
}


#NAT GATEWAY
resource "aws_eip" "nat_gateway" {
  vpc = true
}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_gateway.id
  subnet_id = aws_subnet.public.id
  tags = {
    Name = "NatGateway"
  }

}
output "nat_gateway_ip" {
  value = aws_eip.nat_gateway.public_ip
}


#Route table private and association
resource "aws_route_table" "privateroute" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }
}

resource "aws_route_table_association" "privateroute" {
  subnet_id = aws_subnet.private.id
  route_table_id = aws_route_table.privateroute.id
}


#Security Group

resource "aws_security_group" "public" {
    
   name  = "public"
   description = "Security Group Public"
   vpc_id = aws_vpc.main.id
   
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 9100
    to_port = 9100
    protocol = "tcp"
    cidr_blocks = ["10.1.1.0/32"]
  }
  egress {
     from_port = 0
     to_port = 0
     protocol = "-1"
     cidr_blocks = ["0.0.0.0/0"]
   }
   tags = {
     Name = "Public"
     Description = "Public Security Group"
   }
}
resource "aws_security_group" "frontend" {
   
   name  = "frontend"
   description = "Security Group Frontend"
   vpc_id = aws_vpc.main.id
   ingress {
       from_port = 22
       to_port = 22
       protocol = "tcp"
       cidr_blocks = ["10.1.0.0/32"]
   }
   ingress {
      from_port = 3000
      to_port = 3000
      protocol = "tcp"
      cidr_blocks = ["10.1.0.0/32"]
   }
   ingress {
      from_port = 9100
      to_port = 9100
      protocol = "tcp"
      cidr_blocks = ["10.1.1.0/32"]
   }
   egress {
     from_port = 0
     to_port = 0
     protocol = "-1"
     cidr_blocks = ["0.0.0.0/0"]
   }
   tags = {
     Name = "Frontend"
     Description = "Security Group Frontend"
   }
  
}
resource "aws_security_group" "backend" {

   name  = "backend"
   description = "Security Group Backend"
   vpc_id = aws_vpc.main.id
   ingress {
     from_port = 22
     to_port = 22
     protocol = "tcp"
     cidr_blocks = ["10.1.0.0/32"]
   }
   ingress {
     from_port = 5000
     to_port = 5000
     protocol = "tcp"
     cidr_blocks = ["10.1.0.0/32"]
   }
   ingress {
      from_port = 9100
      to_port = 9100
      protocol = "tcp"
      cidr_blocks = ["10.1.1.0/32"]
   }
   egress {
     from_port = 0
     to_port = 0
     protocol = "-1"
     cidr_blocks = ["0.0.0.0/0"]
   }
   tags = {
      Name = "Backend"
      Description = "Security Group Backend"
    }

}
resource "aws_security_group" "database" {
   
   name  = "database"
   description = "Security Group database"
   vpc_id = aws_vpc.main.id
   ingress {
     from_port = 22
     to_port = 22
     protocol = "tcp"
     cidr_blocks = ["10.1.0.0/32"]
   }
   ingress {
      from_port = 5432
      to_port = 5432
      protocol = "tcp"
      cidr_blocks = ["10.10.2.68/32"]
   }
   egress {
     from_port = 0
     to_port = 0
     protocol = "-1"
     cidr_blocks = ["0.0.0.0/0"]
   }
   tags = {
      Name = "Database"
      Description = "Security Group Database"
   }
}

resource "aws_security_group" "jenkins" {
   
   name  = "jenkins"
   description = "Security Group Jenkins"
   vpc_id = aws_vpc.main.id
   ingress {
     from_port = 22
     to_port = 22
     protocol = "tcp"
     cidr_blocks = ["10.1.0.0/32"]
   }
   ingress {
      from_port = 8080
      to_port = 8080
      protocol = "tcp"
      cidr_blocks = ["10.1.1.0/32"]
   }
   ingress {
       from_port = 50000
       to_port = 50000
       protocol = "tcp"
       cidr_blocks = ["10.1.1.0/32"]
   }
   ingress {
      from_port = 9100
      to_port = 9100
      protocol = "tcp"
      cidr_blocks = ["10.1.1.0/32"]
   }
   egress {
     from_port = 0
     to_port = 0
     protocol = "-1"
     cidr_blocks = ["0.0.0.0/0"]
   }
   tags = {
     Name = "Jenkins"
     Description = "Security Group Jenkins"
   } 
 
}
resource "aws_security_group" "monitoring" {
   

   name  = "monitoring"
   description = "Security Group Monitoring"
   vpc_id = aws_vpc.main.id
   ingress {
      from_port = 22
      to_port = 22
      protocol = "tcp"
      cidr_blocks = ["10.1.0.0/32"]
   }
   ingress {
      from_port = 9090
      to_port = 9090
      protocol = "tcp"
      cidr_blocks = ["10.1.1.0/32"]
   }
   ingress {
       from_port = 3000
       to_port = 3000
       protocol = "tcp"
       cidr_blocks = ["10.1.1.0/32"]
   }
   egress {
     from_port = 0
     to_port = 0
     protocol = "-1"
     cidr_blocks = ["0.0.0.0/0"]
   }
   tags = {
      Name = "Monitoring"
      Description = "Security Group Monitoring"
   }
}




# Instance Public
resource "aws_instance" "public" {
  ami               = "ami-00ddb0e5626798373"
  instance_type     = "t2.medium"
  source_dest_check = false
  key_name          = "Final"
  subnet_id         = aws_subnet.public.id
  private_ip        = "10.1.0.14"
  security_groups   = [aws_security_group.public.id]
  tags = {
    Name = "01-Public"
  }
  root_block_device {
#    delete_on_termination = true
#    encrypted             = false
#    iops                  = 100
    volume_size           = 15
#    volume_type           = "gp2"
  }
}

resource "aws_eip" "lb" {
   instance = aws_instance.public.id
}

# Instance Frontend
resource "aws_instance" "frontend" {
  ami               = "ami-00ddb0e5626798373"
  instance_type     = "t2.medium"
  associate_public_ip_address = false
  source_dest_check = false
  key_name          = "Final"
  private_ip        = "10.1.1.4"
  subnet_id         = aws_subnet.private.id
  security_groups   = [aws_security_group.frontend.id]
  tags = {
    Name = "02-Frontend"
  }
  root_block_device {
#    delete_on_termination = true
#    encrypted             = false
#    iops                  = 100
    volume_size           = 8
#    volume_type           = "gp2"
  }
}

# Instance Frontend2
resource "aws_instance" "frontend2" {
  ami               = "ami-00ddb0e5626798373"
  instance_type     = "t2.medium"
  associate_public_ip_address = false
  source_dest_check = false
  key_name          = "Final"
  private_ip        = "10.1.1.5"
  subnet_id         = aws_subnet.private.id
  security_groups   = [aws_security_group.frontend.id]
  tags = {
    Name = "02-Frontend"
  }
  root_block_device {
#    delete_on_termination = true
#    encrypted             = false
#    iops                  = 100
    volume_size           = 8
#    volume_type           = "gp2"
  }
}

# Instance Backend
resource "aws_instance" "Backend" {
  ami               = "ami-00ddb0e5626798373"
  instance_type     = "t2.micro"
  associate_public_ip_address = false
  source_dest_check = false
  key_name          = "Final"
  private_ip        = "10.1.1.6"
  subnet_id         = aws_subnet.private.id
  security_groups   = [aws_security_group.backend.id]
  tags = {
    Name = "03-Backend"
  }
  root_block_device {
#    delete_on_termination = true
#    encrypted             = false
#    iops                  = 100
    volume_size           = 8
#    volume_type           = "gp2"
  }
}

# # Instance Backend2
# resource "aws_instance" "Backend2" {
#   ami               = "ami-00ddb0e5626798373"
#   instance_type     = "t2.micro"
#   associate_public_ip_address = false
#   source_dest_check = false
#   key_name          = "Final"
#   private_ip        = "10.1.1.7"
#   subnet_id         = aws_subnet.private.id
#   security_groups   = [aws_security_group.backend.id]
#   tags = {
#     Name = "03-Backend"
#   }
#   root_block_device {
# #    delete_on_termination = true
# #    encrypted             = false
# #    iops                  = 100
#     volume_size           = 8
# #    volume_type           = "gp2"
#   }
# }

# Instance Database
resource "aws_instance" "database" {
  ami               = "ami-00ddb0e5626798373"
  instance_type     = "t2.micro"
  associate_public_ip_address = false
  source_dest_check = false
  key_name          = "Final"
  private_ip        = "10.1.1.8"
  subnet_id         = aws_subnet.private.id
  security_groups   = [aws_security_group.database.id]
  tags = {
    Name = "04-Database"
  }
  root_block_device {
#    delete_on_termination = true
#    encrypted             = false
#    iops                  = 100
    volume_size           = 8
#    volume_type           = "gp2"
  }
}

# Instance Database2
resource "aws_instance" "database2" {
  ami               = "ami-00ddb0e5626798373"
  instance_type     = "t2.micro"
  associate_public_ip_address = false
  source_dest_check = false
  key_name          = "Final"
  private_ip        = "10.1.1.9"
  subnet_id         = aws_subnet.private.id
  security_groups   = [aws_security_group.database.id]
  tags = {
    Name = "04-Database"
  }
  root_block_device {
#    delete_on_termination = true
#    encrypted             = false
#    iops                  = 100
    volume_size           = 8
#    volume_type           = "gp2"
  }
}

# Instance Jenkins
resource "aws_instance" "jenkins" {
  ami               = "ami-00ddb0e5626798373"
  instance_type     = "t2.small"
  associate_public_ip_address = false
  source_dest_check = false
  key_name          = "Final"
  private_ip        = "10.1.1.10"
  subnet_id         = aws_subnet.private.id
  security_groups   = [aws_security_group.jenkins.id]
  tags = {
    Name = "05-Jenkins"
  }
  root_block_device {
#    delete_on_termination = true
#    encrypted             = false
#    iops                  = 100
    volume_size           = 8
#    volume_type           = "gp2"
  }
}

# Instance Monitoring
resource "aws_instance" "monitoring" {
  ami               = "ami-00ddb0e5626798373"
  instance_type     = "t2.micro"
  associate_public_ip_address = false
  source_dest_check = false
  key_name          = "Final"
  private_ip        = "10.1.1.11"
  subnet_id         = aws_subnet.private.id
  security_groups   = [aws_security_group.monitoring.id]
  tags = {
    Name = "06-Monitoring"
  }
  root_block_device {
#    delete_on_termination = true
#    encrypted             = false
#    iops                  = 100
    volume_size           = 8
#    volume_type           = "gp2"
  }
}
