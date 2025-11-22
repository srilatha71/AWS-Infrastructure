pipeline {
    agent any

    environment {
        AWS_REGION = "us-east-1"
        AWS_REGION_SUBNET1 = "us-east-1a"
        AWS_REGION_SUBNET2 = "us-east-1b"
        AWS_CREDS = credentials('aws-creds')   // Jenkins stored AWS IAM user
    }

    stages {


   stage('Install AWS CLI') {
    steps {
        sh '''
            set -e  # Exit on error

            echo "🔍 Checking if AWS CLI is already installed..."

            if command -v aws >/dev/null 2>&1; then
                echo "✅ AWS CLI is already installed."
                aws --version
            else
                echo "🚀 AWS CLI not found. Installing..."

                sudo apt-get update -y
                sudo apt-get install -y unzip

                curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"

                if [ ! -f awscliv2.zip ]; then
                    echo "❌ ERROR: Failed to download AWS CLI."
                    exit 1
                fi

                unzip -o awscliv2.zip
                sudo ./aws/install

                echo "✅ AWS CLI installed successfully."
                aws --version
            fi
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
                    SUBNET1=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.1.0/24 --availability-zone ${AWS_REGION_SUBNET1} --query 'Subnet.SubnetId' --output text)
                    SUBNET2=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.2.0/24 --availability-zone ${AWS_REGION_SUBNET2} --query 'Subnet.SubnetId' --output text)

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

                    AMI_ID="ami-0ecb62995f68bb549"

                           echo "Ubuntu 24.04 AMI: $AMI_ID"

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

                    scp -o StrictHostKeyChecking=no -i https://github.com/srilatha71/AWS-Infrastructure.git app.jar ubuntu@$PUBLIC_IP:/home/ubuntu/

                    ssh -o StrictHostKeyChecking=no -i https://github.com/srilatha71/AWS-Infrastructure.git ubuntu@$PUBLIC_IP << EOF
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
