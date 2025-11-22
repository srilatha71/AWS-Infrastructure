pipeline {
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
