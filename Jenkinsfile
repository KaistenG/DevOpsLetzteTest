pipeline {
    agent any
    environment {
        DOCKER_HOST = "tcp://host.docker.internal:2375" // Remote Docker auf Host
        IMAGE_NAME = "kaisteng/flask-hello:latest"
    }
    stages {
        stage('Checkout SCM') {
            steps {
                checkout scm
            }
        }
        stage('Build Docker Image') {
            steps {
                script {
                    sh "docker -H ${DOCKER_HOST} build -t ${IMAGE_NAME} ."
                }
            }
        }
        stage('Deploy to Kubernetes') {
            steps {
                withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG')]) {
                    sh "kubectl apply -f k8s-deployment.yaml"
                    sh "kubectl apply -f k8s-service.yaml"
                    sh "kubectl apply -f k8s-hpa.yaml"
                }
            }
        }
        stage('Run Load Test in Cluster') {
            steps {
                withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG')]) {
                    script {
                        sh """
                        kubectl run locust-load-test \
                            --image=${IMAGE_NAME} \
                            --restart=Never \
                            --rm -i -- \
                            locust -f locustfile.py --host=http://flask-service:5000 --headless -u 1000 -r 20 --run-time 30s --stop-timeout 10
                        """
                    }
                }
            }
        }
    }
    post {
        always {
            echo 'Pipeline beendet.'
        }
        failure {
            echo 'Es gab einen Fehler während der Pipeline.'
        }
    }
}
