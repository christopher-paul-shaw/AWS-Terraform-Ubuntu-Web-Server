provider "aws" {
    region = "eu-west-2"
    access_key = var.aws_access_key
    secret_key = var.aws_secret_key
}

variable "aws_access_key" {
    description = "AWS Access Key"
}

variable "aws_secret_key" {
    description = "AWS Secret Key"
}


# Networking

resource "aws_internet_gateway" "Main_Gateway" {
    vpc_id = aws_vpc.Main_VPC.id
}

resource "aws_eip" "primary" {
    vpc = true
    network_interface = aws_network_interface.Main_Network_Interface.id
    associate_with_private_ip = "10.0.1.50"
    depends_on = [aws_internet_gateway.Main_Gateway]
}

resource "aws_route_table" "Main_Route_Table" {
    vpc_id = aws_vpc.Main_VPC.id
    route {
        cidr_block =  "0.0.0.0/0"
        gateway_id = aws_internet_gateway.Main_Gateway.id
    }
    tags = {
        Name = "Prod"
    }
}

resource "aws_vpc" "Main_VPC" {
    cidr_block = "10.0.0.0/16"
    tags = {
        Name = "prod-vpc"
    }
}

resource "aws_subnet" "Main_Subnet" {
    vpc_id = aws_vpc.Main_VPC.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "eu-west-2a"
    tags = {
        Name = "prod-subnet"
    }
}

resource "aws_route_table_association" "route_subnet" {
    subnet_id = aws_subnet.Main_Subnet.id
    route_table_id = aws_route_table.Main_Route_Table.id
}

resource "aws_network_interface" "Main_Network_Interface" {
    subnet_id = aws_subnet.Main_Subnet.id
    private_ips = ["10.0.1.50"]
    security_groups = [aws_security_group.allow_web.id]
}


# Security
resource "aws_security_group" "allow_web" {
    name = "allow_web"
    description = "Allow Web Traffic"
    vpc_id = aws_vpc.Main_VPC.id

    ingress {
        description = "HTTP"
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        description = "HTTPS"
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        description = "SSH"
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "Allow Web"
    }
}


resource "aws_instance" "API_Instance" {
    ami = "ami-01b8d743224353ffe"
    availability_zone = "eu-west-2a"
    instance_type = "t2.micro"
    tags = {
        Name = "API"
    }
    network_interface {
      device_index = 0
      network_interface_id = aws_network_interface.Main_Network_Interface.id
    }

    user_data = <<-EOF
                #!/bin/bash
                sudo apt update -y
                sudo apt install apache2 -y
                sudo systemclt start apache2
                sudo bash -c 'echo "Installed" > /var/www/html/index.html'
                EOF

}