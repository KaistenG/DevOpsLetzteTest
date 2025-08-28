pipeline {
    agent any

    environment {
        DOCKER_HOST = "tcp://host.docker.internal:2375"
    }

    stages {
        stage('Checkout SCM') {
            steps {
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                sh 'docker build -t kaisteng/flask-hello:latest .'
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG')]) {
                    sh 'kubectl apply -f k8s-deployment.yaml'
                    sh 'kubectl apply -f k8s-service.yaml'
                    sh 'kubectl apply -f k8s-hpa.yaml'
                }
            }
        }

        stage('Run Load Test in Cluster') {
            steps {
                withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG')]) {
                    script {
                        // Pod mit Locust erstellen und starten
                        sh '''
                        kubectl run locust-load-test \
                            --image=kaisteng/flask-hello:latest \
                            --restart=Never \
                            --rm -i -- \
                            locust -f locustfile.py --host=http://flask-service:5000 --headless -u 1000 -r 20 --run-time 30s --stop-timeout 10
                        '''
                        // Optional: HPA Status beobachten
                        sh 'kubectl get hpa flask-hpa -w --no-headers --timeout=40s || true'
                    }
                }
            }
        }

        stage('Cleanup') {
            steps {
                withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG')]) {
                    sh 'kubectl delete pod locust-load-test --ignore-not-found'
                }
            }
        }
    }
}
