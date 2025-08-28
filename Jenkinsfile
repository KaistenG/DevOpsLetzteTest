pipeline {
    agent any
    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/KaistenG/DevOpsLetzteTest.git'
            }
        }
        stage('Build Docker Image') {
            steps {
                sh 'docker -H tcp://host.docker.internal:2375 build -t flask-hello .'
            }
        }
    }
}