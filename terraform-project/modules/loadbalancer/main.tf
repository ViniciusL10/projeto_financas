
data "aws_ami" "imagem_ec2" {
    most_recent = true
    owners = [ "amazon" ]
    filter {
      name = "name"
      values = [ "al2023-ami-2023.*-x86_64" ]
    }
}

resource "aws_security_group" "coninch_nginx_sg" {
    vpc_id = var.vpc_id
    name = "coninch_nginx_sg"
    tags = {
      Name = "coninch-nginx_sg"
    }
}

resource "aws_vpc_security_group_egress_rule" "coninch_egress_sg_rule" {
  security_group_id = aws_security_group.coninch_nginx_sg.id
  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"
} 

resource "aws_vpc_security_group_ingress_rule" "coninch_ingress_80_sg_rule" {
  security_group_id = aws_security_group.coninch_nginx_sg.id
  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "tcp"
  from_port   = 80
  to_port     = 80
}
resource "aws_vpc_security_group_ingress_rule" "coninch_ingress_22_sg_rule" {
  security_group_id = aws_security_group.coninch_nginx_sg.id
  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "tcp"
  from_port   = 22
  to_port     = 22
}

resource "aws_network_interface" "coninch_nginx_ei" {
  subnet_id = var.subnet_pub_a_id
  tags = {
    Name = "coninch_nginx_ei"
  }
}

resource "aws_instance" "coninch_nginx_ec2" {
  instance_type = "t3.micro"
  ami = data.aws_ami.imagem_ec2.id
  subnet_id = var.subnet_pub_a_id
  vpc_security_group_ids = [ aws_security_group.coninch_nginx_sg.id ]
  
  associate_public_ip_address = true
  tags = {
    Name = "coninch-nginx_ec2"
  }
}