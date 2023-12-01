### Projeto Cloud

### Objetivo 

	Provisionar uma arquitetura na AWS utilizando o Terraform, que englobe o uso de um Application Load Balancer (ALB), instâncias EC2 com Auto Scaling e um banco de dados RDS.

### Decisões Técnicas

### VPC
	Um VPC, ou Virtual Private Cloud, é um serviço de computação em nuvem que permite que você crie uma rede virtual isolada na infraestrutura de nuvem de um provedor, como a AWS. Essa rede virtual oferece controle total sobre a configuração dos recursos de rede, como sub-redes, tabelas de roteamento e gateways, proporcionando uma camada adicional de segurança e isolamento para os recursos em execução na nuvem. Um VPC permite que você crie e gerencie recursos, como instâncias de servidores, bancos de dados e balanceadores de carga, dentro de um ambiente virtualmente privado e personalizado. Isso facilita a implementação de soluções escaláveis e seguras na nuvem.
Para dar início ao projeto, foi criada uma VPC com as seguintes características. Bloco CIDR "10.0.0.0/16" e com suporte de DNS e nomes de host DNS ativos.

### SUBNETS
	Subnets são subdivisões de uma rede maior, geralmente dentro de um VPC. Elas representam segmentos isolados da rede e ajudam na organização e gestão de endereços IP. Cada subnet pode ter configurações de segurança e roteamento específicas. Em um contexto de nuvem, subnets são utilizadas para distribuir recursos de maneira mais eficiente, fornecendo isolamento lógico e permitindo a implementação de serviços em diferentes partes da infraestrutura de nuvem. 
	No projeto, foram configuradas duas subnets públicas e duas privadas. As subnets públicas foram criadas para permitir a existência de um Load Balancer e Auto Scaling, enquanto as privadas foram criadas para posteriormente dar origem ao RDS. As subnets públicas foram criadas respectivamente com bloco CIDR "10.0.1.0/24" e "10.0.2.0/24" e nas zonas "us-east-1a" e "us-east-1b". Já as privadas foram criadas com bloco CIDR "10.0.101.0/24" e "10.0.102.0/24" e também nas zonas "us-east-1a" e "us-east-1b".

### AUTO SCALING GROUP
	Um Auto Scaling Group é um recurso em serviços de nuvem que automatiza o processo de ajuste da capacidade de recursos computacionais, como instâncias de servidores. O grupo monitora a demanda de recursos e, com base em políticas predefinidas, adiciona ou remove automaticamente instâncias para garantir que a aplicação tenha capacidade suficiente para lidar com o tráfego, mantendo eficiência e resiliência. Isso permite que a infraestrutura se adapte dinamicamente às variações de carga, assegurando a escalabilidade e o desempenho adequado da aplicação.
	Por conta das vantagens citadas, foi criado um Auto Scaling Group no projeto com alarme cloudwatch, para automaticamente gerenciar a quantidade de máquinas alocadas em relação à necessidade.

### RDS
	O Amazon RDS (Relational Database Service) é um serviço de banco de dados gerenciado oferecido pela Amazon Web Services (AWS). Ele simplifica a configuração, operação e escalabilidade de bancos de dados relacionais.
	No projeto, um RDS foi criado usando uma AWS DataBase Instance, de classe t2 micro e memória alocada de 20GB. 

### GUIA
	Primeiramente, deve se possuir o terraform instalado em sua máquina:
	https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli 

	Feito isso, é necessária a instalação do Amazon CLI que pode ser feita como descrito neste link:
	https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html 

	Com isso tudo, pode se criar uma conta na AWS e configurar suas credenciais como descrito neste link:
	https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html 

	Configurado, pode se rodar os seguintes comandos:
	terraform init -upgrade (para iniciar o terraform)
	terraform destroy (para destruir a infraestrutura já existente)
	terraform apply (Para aplicar as alterações feitas pelo projeto)

	Com isso feito, pode-se entrar na aplicação pesquisando pelo nome de DNS do load balancer, obtido em seu dashboard da AWS. Após o nome de DNS, deve-se colocar um “/docs”, para acertar a rota da aplicação.

### ANÁLISE DE CUSTO

![image](https://github.com/josephkneto/projeto-cloud/assets/79852830/9f3ac54f-7083-41d2-b7be-86917a8a6f00)
![image](https://github.com/josephkneto/projeto-cloud/assets/79852830/db0420c0-ea6c-45de-93ce-880bbe8810af)



	
	

