
## ssh connectivity
resource "aws_key_pair" "key" {
  key_name = "key"
  public_key = file("~/.ssh/id_rsa.pub")
}
# EC2 instance in Public Subnet
resource "aws_instance" "Bastion" {
  ami             = var.os # Replace with the desired AMI ID
  instance_type = var.instance   # Replace with the desired instance type
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  subnet_id     = aws_subnet.public_subnet1.id
  associate_public_ip_address = true
  key_name      = "key" # Replace with your SSH key pair
  tags = {
    Name = "Bastion"
    description = "Jump server to the private instance "
  }
}
resource "aws_launch_configuration" "ec2" {
  name                        = "${var.tag}-instances"
  image_id            = var.os  # Replace with the desired AMI ID
  instance_type = var.instance     # Replace with the desired instance type
  security_groups             = [aws_security_group.ec2_sg.id]
  key_name                    = "key"
  associate_public_ip_address = false
  user_data = <<-EOL
  #!/bin/bash -xe
  sudo yum update -y
  sudo yum -y install docker
  sudo service docker start
  sudo usermod -a -G docker ec2-user
  sudo chmod 666 /var/run/docker.sock
  docker pull nginx
  docker tag nginx my-nginx
  docker run --rm --name nginx-server -d -p 80:80 -t my-nginx
  EOL
  depends_on = [aws_nat_gateway.nat]
}
