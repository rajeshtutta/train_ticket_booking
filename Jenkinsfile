pipeline {
    agent any

    tools {
        maven 'maven'     // ✅ fixed
        jdk 'jdk21'       // ✅ fixed
    }

    environment {
        SONARQUBE_ENV = 'sq'
        DOCKER_IMAGE = "rajeshtutta123/train_ticket_booking"
        AWS_DEFAULT_REGION = 'us-east-1'
        RECIPIENTS = 'rajeshtutta123@gmail.com'
    }

    stages {

        stage('Clone Repository') {
            steps {
                git branch: 'main', url: 'https://github.com/rajeshtutta/train_ticket_booking.git'
            }
        }

        stage('Build (Maven)') {
            steps {
                sh 'mvn clean package -DskipTests'
            }
        }

        stage('Deploy to Nexus') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'nexus-creds',
                    usernameVariable: 'NEXUS_USER',
                    passwordVariable: 'NEXUS_PASS'
                )]) {
                    sh '''
                    mvn deploy -DskipTests \
                    -Dnexus.username=$NEXUS_USER \
                    -Dnexus.password=$NEXUS_PASS
                    '''
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv("${SONARQUBE_ENV}") {
                    sh '''
                    mvn sonar:sonar \
                    -Dsonar.projectKey=train-ticket \
                    -Dsonar.projectName=train-ticket
                    '''
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 2, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh 'docker build -t $DOCKER_IMAGE:latest .'
            }
        }

        stage('Push Docker Image') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-cred',
                    usernameVariable: 'USER',
                    passwordVariable: 'PASS'
                )]) {
                    sh '''
                    echo $PASS | docker login -u $USER --password-stdin
                    docker push $DOCKER_IMAGE:latest
                    docker logout
                    '''
                }
            }
        }

        stage('Deploy to EKS') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'aws-creds',
                    usernameVariable: 'AWS_ACCESS_KEY_ID',
                    passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                )]) {
                    sh '''
                    aws eks update-kubeconfig --region $AWS_DEFAULT_REGION --name mycluster
                    kubectl apply -f deployment.yml
                    kubectl apply -f service.yml
                    '''
                }
            }
        }
    }

    post {
        success {
            emailext(
                subject: "SUCCESS: ${env.JOB_NAME}",
                body: "Build #${env.BUILD_NUMBER} succeeded\n${env.BUILD_URL}",
                to: "${RECIPIENTS}"
            )
        }

        failure {
            emailext(
                subject: "FAILED: ${env.JOB_NAME}",
                body: "Build #${env.BUILD_NUMBER} failed\n${env.BUILD_URL}",
                to: "${RECIPIENTS}"
            )
        }
    }
}
