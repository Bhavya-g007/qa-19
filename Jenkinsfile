pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                git url: 'https://github.com/Bhavya-g007/qa-19.git', branch: 'main'
            }
        }

        stage('Build') {
            steps {
                dir('javaapp-pipeline') {
                    echo "Building the project"
                    sh 'mvn clean package'
                }
            }
        }

        stage('Terraform Init & Apply') {
            steps {
                dir('terraform') {
                    withCredentials([usernamePassword(credentialsId: 'aws-creds', usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                        echo "Initializing and applying Terraform"
                        sh 'terraform init'
                        sh 'terraform apply -auto-approve'
                    }
                }
            }
        }

        stage('Fetch EC2 Public IP') {
            steps {
                dir('terraform') {
                    echo 'Sleeping to let EC2 boot...'
                    sleep 60
                    echo "Fetching EC2 Public IP from Terraform output"
                    script {
                        def publicIp = sh(script: 'terraform output -raw ec2_public_ip', returnStdout: true).trim()
                        echo "EC2 Public IP: ${publicIp}"
                        env.EC2_PUBLIC_IP = publicIp
                    }
                }
            }
        }

        stage('Deploy JAR to Tomcat') {
            steps {
                dir('javaapp-pipeline') {
                    echo "Deploying JAR to Tomcat on EC2"
                    sshagent(credentials: ['ssh-creds']) {
                        sh """
                            scp -o StrictHostKeyChecking=no target/*.jar ec2-user@${EC2_PUBLIC_IP}:/tmp/java-app.jar
                        """
                    }
                }
            }
        }
        
        stage('Ansible to Install Tomcat') {
            steps {
                dir('ansible') {
                    echo "Installing Tomcat with Ansible"
                    sshagent(credentials: ['ssh-creds']) {
                        sh """
                            export ANSIBLE_HOST_KEY_CHECKING=False
                            ansible all -i '${EC2_PUBLIC_IP},' -u ec2-user -m ping
                            ansible-playbook -i '${EC2_PUBLIC_IP},' -u ec2-user tomcat.yaml  
                        """
                    }
                }
            }
        }
    }

    post {
        always {
            echo "Running Terraform Destroy (post-build action)"
            dir('terraform') {
                withCredentials([usernamePassword(credentialsId: 'aws-creds', usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    sh 'sleep 120'
                    sh 'terraform destroy -auto-approve'
                }
            }
        }
    }
}
