pipeline {
    agent any

    environment {
        AWS_REGION = "ap-south-1"
        AWS_CREDS = credentials('aws-creds')   // Jenkins stored AWS IAM user
    }

    stages {

        stage('Checkout Repo') {
            steps {
                git branch: 'main', url: 'https://github.com/your/repo.git'
            }
        }

        stage('Install AWS CLI') {
            steps {
                sh '''
                    sudo apt-get update -y
                    sudo apt-get install -y unzip

                    # Install AWS CLI
                    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
                    unzip awscliv2.zip
                    sudo ./aws/install

                    aws --version
                '''
            }
        }

        stage('Configure AWS Credentials') {
            steps {
                sh '''
                    aws configure set aws_access_key_id ${AWS_CREDS_USR}
                    aws configure set aws_secret_access_key ${AWS_CREDS_PSW}
                    aws configure set default.region ${AWS_REGION}
                '''
            }
        }

        stage('Create Network Infra (VPC, Subnets, IGW)') {
            steps {
                sh '''
                    echo "Creating VPC..."
                    VPC_ID=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 --query 'Vpc.VpcId' --output text)
                    echo $VPC_ID > vpc_id.txt

                    aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-hostnames

                    echo "Creating Subnets..."
                    SUBNET1=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.1.0/24 --availability-zone ap-south-1a --query 'Subnet.SubnetId' --output text)
                    SUBNET2=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.2.0/24 --availability-zone ap-south-1b --query 'Subnet.SubnetId' --output text)

                    echo $SUBNET1 > subnet1.txt
                    echo $SUBNET2 > subnet2.txt

                    echo "Creating Internet Gateway..."
                    IGW_ID=$(aws ec2 create-internet-gateway --query 'InternetGateway.InternetGatewayId' --output text)
                    aws ec2 attach-internet-gateway --vpc-id $VPC_ID --internet-gateway-id $IGW_ID

                    echo "Creating Route Table..."
                    RT_ID=$(aws ec2 create-route-table --vpc-id $VPC_ID --query 'RouteTable.RouteTableId' --output text)
                    aws ec2 create-route --route-table-id $RT_ID --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW_ID
                    aws ec2 associate-route-table --subnet-id $SUBNET1 --route-table-id $RT_ID
                '''
            }
        }

        stage('Create EC2 for App Deployment') {
            steps {
                sh '''
                    echo "Launching EC2 Instance..."

                    AMI_ID=$(aws ec2 describe-images --owners amazon \
                      --filters "Name=name,Values=amzn2-ami-hvm-*-x86_64-gp2" \
                      --query 'Images[0].ImageId' --output text)

                    SUBNET1=$(cat subnet1.txt)

                    INSTANCE_ID=$(aws ec2 run-instances \
                      --image-id $AMI_ID \
                      --count 1 \
                      --instance-type t3.micro \
                      --subnet-id $SUBNET1 \
                      --associate-public-ip-address \
                      --query 'Instances[0].InstanceId' \
                      --output text)

                    echo $INSTANCE_ID > ec2.txt

                    aws ec2 wait instance-running --instance-ids $INSTANCE_ID

                    PUBLIC_IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
                    echo "EC2 Public IP: $PUBLIC_IP"
                    echo $PUBLIC_IP > public_ip.txt
                '''
            }
        }

        stage('Deploy Application to EC2') {
            steps {
                sh '''
                    PUBLIC_IP=$(cat public_ip.txt)

                    echo "Installing app on EC2..."

                    # Example deployment: copy artifact & start service
                    # Replace key.pem with correct key

                    scp -o StrictHostKeyChecking=no -i key.pem app.jar ec2-user@$PUBLIC_IP:/home/ec2-user/

                    ssh -o StrictHostKeyChecking=no -i key.pem ec2-user@$PUBLIC_IP << EOF
                        sudo yum install java -y
                        nohup java -jar /home/ec2-user/app.jar > app.log 2>&1 &
                    EOF
                '''
            }
        }
    }

    post {
        success {
            echo 'AWS infrastructure created and app deployed successfully!'
        }
        failure {
            echo 'Build failed. Manual cleanup may be required.'
        }
    }
}
