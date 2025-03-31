
data "aws_ami" "imagem_ec2" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

resource "aws_security_group" "coninch_nginx_sg" {
  vpc_id = var.vpc_id
  name   = "coninch_nginx_sg"
  tags = {
    Name = "coninch-nginx_sg"
  }
}

resource "aws_vpc_security_group_egress_rule" "coninch_egress_sg_rule" {
  security_group_id = aws_security_group.coninch_nginx_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "coninch_ingress_80_sg_rule" {
  security_group_id = aws_security_group.coninch_nginx_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
}
resource "aws_vpc_security_group_ingress_rule" "coninch_ingress_22_sg_rule" {
  security_group_id = aws_security_group.coninch_nginx_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
}

resource "aws_network_interface" "coninch_nginx_ei" {
  subnet_id = var.pub_subnets_id[0]
  tags = {
    Name = "coninch_nginx_ei"
  }
}

resource "aws_instance" "coninch_nginx_ec2" {
  instance_type          = "t3.micro"
  ami                    = data.aws_ami.imagem_ec2.id
  subnet_id              = var.pub_subnets_id[0]
  vpc_security_group_ids = [aws_security_group.coninch_nginx_sg.id]

  associate_public_ip_address = true

  user_data = <<-EOF
            #!/bin/bash
            exec > /var/log/user-data.log 2>&1

            log() {
                echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
            }

            check_error() {
                if [ $? -ne 0 ]; then
                    log "ERRO: $1"
                    exit 1
                else
                    log "OK: $2"
                fi
            }

            log "Iniciando instalação do NGINX no Amazon Linux..."

            log "Atualizando pacotes..."
            sudo yum update -y
            check_error "Falha ao atualizar os pacotes." "Pacotes atualizados com sucesso."

            log "Habilitando repositório nginx1..."
            sudo amazon-linux-extras enable nginx1
            check_error "Falha ao habilitar o repositório nginx1." "Repositório nginx1 habilitado com sucesso."

            log "Instalando NGINX..."
            sudo yum install -y nginx
            check_error "Falha na instalação do NGINX." "NGINX instalado com sucesso."

            log "Iniciando o serviço NGINX..."
            sudo systemctl start nginx
            check_error "Falha ao iniciar o serviço NGINX." "NGINX iniciado com sucesso."

            log "Habilitando NGINX para iniciar com o sistema..."
            sudo systemctl enable nginx
            check_error "Falha ao habilitar NGINX no boot." "NGINX habilitado com sucesso."

            log "Criando página personalizada..."
            echo "<h1>Servidor NGINX provisionado via Terraform</h1>" > /usr/share/nginx/html/index.html
            check_error "Falha ao criar página HTML." "Página HTML personalizada criada com sucesso."
            EOF

  tags = {
    Name = "coninch-nginx_ec2"
  }
}
