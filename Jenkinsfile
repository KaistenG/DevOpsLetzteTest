pipeline {
    agent any

    parameters {
        string(name: 'LOCUST_USERS', defaultValue: '200', description: 'Anzahl virtueller Benutzer')
        string(name: 'LOCUST_RATE', defaultValue: '20', description: 'Spawn-Rate (Benutzer pro Sekunde)')
        string(name: 'LOCUST_TIME', defaultValue: '30s', description: 'Dauer des Lasttests (z.B. 30s, 1m, 2m)')
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/KaistenG/DevOpsLetzteTest.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                sh 'docker -H tcp://host.docker.internal:2375 build -t kaisteng/flask-hello:latest .'
            }
        }

        stage('Run Persistent Container') {
            steps {
                sh '''
                if [ $(docker -H tcp://host.docker.internal:2375 ps -q -f name=flask-test) ]; then
                    docker -H tcp://host.docker.internal:2375 rm -f flask-test
                fi
                docker -H tcp://host.docker.internal:2375 run -d --name flask-test -p 5000:5000 kaisteng/flask-hello:latest
                '''
            }
        }

        stage('HTTP Test') {
            steps {
                sh 'sleep 5'
                sh '''
                STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://host.docker.internal:5000)
                if [ "$STATUS" -ne 200 ]; then
                    echo "HTTP-Test fehlgeschlagen: Status $STATUS"
                    exit 1
                fi
                echo "HTTP-Test erfolgreich: Status $STATUS"
                '''
            }
        }

        stage('Validate Parameters') {
            steps {
                script {
                    if (!params.LOCUST_USERS.isInteger() || params.LOCUST_USERS.toInteger() <= 0) {
                        error "LOCUST_USERS muss eine positive Zahl sein!"
                    }
                    if (!params.LOCUST_RATE.isInteger() || params.LOCUST_RATE.toInteger() <= 0) {
                        error "LOCUST_RATE muss eine positive Zahl sein!"
                    }
                    if (!params.LOCUST_TIME.matches(/^\d+[smh]$/)) {
                        error "LOCUST_TIME muss im Format <Zahl>s/m/h sein, z.B. 30s, 1m, 2h"
                    }
                }
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

        stage('Load Test & HPA Trigger') {
            steps {
                withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG')]) {
                    script {
                        echo "Starte Load-Test gegen Kubernetes Service..."
                        sh """
                        docker -H tcp://host.docker.internal:2375 exec flask-test \
                        locust -f locustfile.py --host=http://flask-service:5000 \
                        --headless -u ${params.LOCUST_USERS} -r ${params.LOCUST_RATE} \
                        --run-time ${params.LOCUST_TIME} --stop-timeout 10
                        """

                        echo "Überwache HPA für 30 Sekunden..."
                        sh """
                        END_TIME=\$((SECONDS+30))
                        while [ \$SECONDS -lt \$END_TIME ]; do
                            kubectl get hpa flask-hpa -o wide
                            kubectl get pods -l app=flask -o wide
                            sleep 5
                        done
                        """
                    }
                }
            }
        }

        stage('Cleanup') {
            steps {
                sh 'docker -H tcp://host.docker.internal:2375 rm -f flask-test'
            }
        }
    }
}
