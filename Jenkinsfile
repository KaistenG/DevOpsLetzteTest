pipeline {
    agent any

    environment {
        DOCKER_IMAGE = "kaisteng/flask-hello:latest"
    }

    stages {
        stage('Checkout SCM') {
            steps {
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                sh "docker build -t ${DOCKER_IMAGE} ."
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
                        echo "Starte Load-Test gegen Kubernetes Service..."

                        // Pod für Locust starten (ohne --rm)
                        sh '''
                        kubectl run locust-load-test \
                            --image=${DOCKER_IMAGE} \
                            --restart=Never \
                            --labels=app=locust-test \
                            --command -- sleep 60
                        '''

                        // Locust Load Test ausführen
                        sh '''
                        kubectl exec locust-load-test -- \
                            locust -f locustfile.py --host=http://flask-service:5000 \
                            --headless -u 1000 -r 20 --run-time 30s --stop-timeout 10
                        '''

                        // Pod wieder löschen
                        sh 'kubectl delete pod locust-load-test --ignore-not-found'
                    }
                }
            }
        }

        stage('Cleanup') {
            steps {
                echo "Bereinige Ressourcen falls nötig..."
                // Hier kannst du z.B. Docker-Container lokal entfernen oder andere Aufräumarbeiten machen
            }
        }
    }

    post {
        always {
            echo "Pipeline beendet."
        }
        failure {
            echo "Es gab einen Fehler während der Pipeline."
        }
    }
}
