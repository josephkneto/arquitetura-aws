# main.tf


terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  backend "s3" {
    bucket = "josephkallasbucket"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }

  required_version = ">= 1.2.0"
}

data "aws_availability_zones" "available" {
  state = "available"
}

provider "aws" {
  region = "us-east-1" # Update this to your desired AWS region
}

# VPC ----------------------------------------------------------------------------------------------

resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16" # substitua isso pelo bloco CIDR desejado para a sua VPC

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "MyVPC"
  }
}

# SUBNET -------------------------------------------------------------------------------------------

resource "aws_subnet" "my_subnet" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.1.0/24" # substitua isso pelo bloco CIDR desejado para a sua subnet
  availability_zone       = "us-east-1a"  # substitua isso pela zona de disponibilidade desejada
  map_public_ip_on_launch = true

  tags = {
    Name = "MySubnet"
  }
}

# INTERNET GATEWAY --------------------------------------------------------------------------------

resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "MyInternetGateway"
  }
}

# PUBLIC ROUTE TABLE -------------------------------------------------------------------------------------

resource "aws_route_table" "my_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0" # rota padrão para a internet
    gateway_id = aws_internet_gateway.my_igw.id
  }

  tags = {
    Name = "MyRouteTable"
  }
}

resource "aws_route_table_association" "my_association" {
  subnet_id      = aws_subnet.my_subnet.id
  route_table_id = aws_route_table.my_route_table.id
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# INSTANCE ----------------------------------------------------------------------------------------

# resource "aws_instance" "inst1" {
#   ami                    = data.aws_ami.ubuntu.id
#   instance_type          = "t2.micro"
#   subnet_id              = aws_subnet.my_subnet.id
#   vpc_security_group_ids = [aws_security_group.my_security_group.id]

#   tags = {
#     Name = "Maquina1Joseph"
#   }

#   user_data = base64encode(<<-EOF
#     #!/bin/bash
#     sudo apt update
#     sudo apt install -y apache2
#     sudo systemctl enable apache2
#     sudo systemctl start apache2    
#     EOF
#   )
# }

# resource "aws_eip" "elastic_ip" {
#   instance = aws_instance.inst1.id
# }

resource "aws_eip" "nat_elastic_ip" {
  depends_on = [aws_internet_gateway.my_igw]
  vpc        = true

  tags = {
    Name = "MyElasticIP"
  }
}

# SECURITY GROUP ----------------------------------------------------------------------------------

resource "aws_security_group" "my_security_group" {
  name        = "MySecurityGroup"
  description = "My Security Group Description"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # Permitir tráfego SSH de qualquer lugar
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # Permitir todo o tráfego de saída
  }

  tags = {
    Name = "MySecurityGroup"
  }
}

# LOAD BALANCER -----------------------------------------------------------------------------------

#target group
resource "aws_lb_target_group" "my_lb_target_group" {
  health_check {
    interval            = 10
    path                = "/healthcheck"
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
    matcher             = "200"
  }

  name        = "MyLBTargetGroup"
  port        = 8080
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.my_vpc.id
}

#load balancer subnet
resource "aws_subnet" "my_subnet_2" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "MySubnet2"
  }
}

# load balancer subnet route table
resource "aws_route_table_association" "my_association2" {
  subnet_id      = aws_subnet.my_subnet_2.id
  route_table_id = aws_route_table.my_route_table.id
}

#creating load balancer
resource "aws_lb" "my_lb" {
  name               = "MyLB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.my_security_group.id]
  subnets            = [aws_subnet.my_subnet.id, aws_subnet.my_subnet_2.id]

  tags = {
    Name = "MyLB"
  }
}

#creating listener
resource "aws_lb_listener" "my_lb_listener" {
  load_balancer_arn = aws_lb.my_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.my_lb_target_group.arn
    type             = "forward"
  }
}

#attachment
# resource "aws_lb_target_group_attachment" "ec2_attach" {
#   count            = length(aws_instance.inst1)
#   target_group_arn = aws_lb_target_group.my_lb_target_group.arn
#   target_id        = aws_instance.inst1.id
# }

# Private Subnet and Private Route Table ------------------------------------------------------------------

resource "aws_subnet" "my_private_subnet" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.101.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "MyPrivateSubnet"
  }
}

resource "aws_subnet" "my_private_subnet2" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.102.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "MyPrivateSubnet2"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_elastic_ip.id
  subnet_id     = aws_subnet.my_subnet.id # Specify the subnet ID of the public subnet
}

resource "aws_route_table" "my_private_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block     = "0.0.0.0/0" # rota padrão para a internet
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "MyRouteTable"
  }
}

resource "aws_route_table_association" "my_private_association" {
  subnet_id      = aws_subnet.my_private_subnet.id
  route_table_id = aws_route_table.my_private_route_table.id
}

resource "aws_route_table_association" "my_private_association2" {
  subnet_id      = aws_subnet.my_private_subnet2.id
  route_table_id = aws_route_table.my_private_route_table.id
}


# RDS ---------------------------------------------------------------------------------------------

resource "aws_db_subnet_group" "my_db_subnet_group" {
  name        = "my_db_subnet_group"
  description = "My DB subnet group"
  subnet_ids  = [aws_subnet.my_private_subnet.id, aws_subnet.my_private_subnet2.id]
}

resource "aws_db_instance" "my_db_instance" {
  allocated_storage       = 20
  storage_type            = "gp2"
  engine                  = "mysql"
  engine_version          = "5.7"
  instance_class          = "db.t2.micro"
  db_name                 = "MyDBInstance"
  username                = "MyUsername"
  password                = "MyPassword"
  db_subnet_group_name    = aws_db_subnet_group.my_db_subnet_group.name
  vpc_security_group_ids  = [aws_security_group.my_security_group.id]
  skip_final_snapshot     = true
  multi_az                = true
  backup_retention_period = 7
  backup_window           = "02:00-03:00"
  maintenance_window      = "Sun:03:30-Sun:04:30"
}

# AUTO SCALING GROUP ---------------------------------------------------------------------------------

resource "aws_launch_template" "my_launch_template" {
  name_prefix   = "MyLaunchTemplate"
  image_id      = "ami-0fc5d935ebf8bc3bc"
  instance_type = "t2.micro"
  user_data = base64encode(<<-EOF
    #!/bin/bash
    export DEBIAN_FRONTEND=noninteractive
    
    sudo apt-get update
    sudo apt-get install -y python3-pip python3-venv git

    # Criação do ambiente virtual e ativação
    sudo python3 -m venv /home/ubuntu/myappenv
    source /home/ubuntu/myappenv/bin/activate

    # Clonagem do repositório da aplicação
    git clone https://github.com/ArthurCisotto/aplicacao_projeto_cloud.git /home/ubuntu/myapp

    # Instalação das dependências da aplicação
    pip install -r /home/ubuntu/myapp/requirements.txt

    sudo apt-get install -y uvicorn
 
    # Configuração da variável de ambiente para o banco de dados
    export DATABASE_URL="mysql+pymysql://MyUsername:MyPassword@${aws_db_instance.my_db_instance.endpoint}/MyDBInstance"

    cd /home/ubuntu/myapp
    # Inicialização da aplicação
    uvicorn main:app --host 0.0.0.0 --port 8080
  EOF
  )

  network_interfaces {
    security_groups             = [aws_security_group.my_security_group.id]
    associate_public_ip_address = true
    subnet_id                   = aws_subnet.my_subnet.id
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "MyLaunchTemplate"
    }
  }
}

resource "aws_autoscaling_group" "my_autoscaling_group" {
  name             = "MyAutoScalingGroup"
  max_size         = 1
  min_size         = 1
  desired_capacity = 1

  vpc_zone_identifier = [aws_subnet.my_subnet.id]
  target_group_arns   = [aws_lb_target_group.my_lb_target_group.arn]

  launch_template {
    id      = aws_launch_template.my_launch_template.id
    version = "$Latest" # Corrected spelling
  }

  tag {
    key                 = "Name"
    value               = "MyAutoScalingGroup"
    propagate_at_launch = true
  }
}

# auto scaling policy
resource "aws_autoscaling_policy" "my_rising_autoscaling_policy" {
  name                   = "MyRisingAutoScalingPolicy"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.my_autoscaling_group.name
}

# auto scaling policy
resource "aws_autoscaling_policy" "my_falling_autoscaling_policy" {
  name                   = "MyFallingAutoScalingPolicy"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.my_autoscaling_group.name
}

# cloudwatch alarm
resource "aws_cloudwatch_metric_alarm" "my_rising_cloudwatch_alarm" {
  alarm_name          = "MyRisingCloudWatchAlarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "70"
  alarm_description   = "This metric monitors ec2 cpu utilization"
  alarm_actions       = [aws_autoscaling_policy.my_rising_autoscaling_policy.arn]
  ok_actions          = [aws_autoscaling_policy.my_falling_autoscaling_policy.arn]
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.my_autoscaling_group.name
  }
}

# cloudwatch alarm
resource "aws_cloudwatch_metric_alarm" "my_falling_cloudwatch_alarm" {
  alarm_name          = "MyFallingCloudWatchAlarm"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "30"
  alarm_description   = "This metric monitors ec2 cpu utilization"
  alarm_actions       = [aws_autoscaling_policy.my_falling_autoscaling_policy.arn]
  ok_actions          = [aws_autoscaling_policy.my_rising_autoscaling_policy.arn]
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.my_autoscaling_group.name
  }
}
