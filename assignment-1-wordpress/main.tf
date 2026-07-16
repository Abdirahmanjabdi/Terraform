# 1 dynamically fetch the latest ubuntu ami for the specified region
data "aws_ami" "Ubuntu" {
    most_recent = true
    owners  = ["099720109477"] # Canonical
    filter {
        name = "name"
        values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
    }
}
# 2 Setting up the security group for the WordPress instance and ssh access
resource "aws_security_group" "wordpress_sg" {
    name        = "wordpress_sg"
    description = "Allow HTTP, HTTPS and SSH inbound traffic"
    ingress {
        description = "HTTP from anywhere"
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        description = "SSH from anywhere (in producttion only from my ip)"
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        description = "Allow all outbound traffic"
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

# 3 The EC2 instances 
resource "aws_instance" "wordpress_server" {
    ami           = data.aws_ami.Ubuntu.id
    instance_type = var.instance_type
    security_groups = [aws_security_group.wordpress_sg.name]

    # this pulls the user data script from the local file and passes it to the instance
    user_data = file("${path.module}/setup.sh")

    tags = {
        Name = "WordPress Server Project 1"
    }

}