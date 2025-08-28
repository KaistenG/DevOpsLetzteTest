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
        stage('Run Persistent Container') {
            steps {
                sh '''
                if [ $(docker -H tcp://host.docker.internal:2375 ps -q -f name=flask-test) ]; then
                    docker -H tcp://host.docker.internal:2375 rm -f flask-test
                fi
                '''
                sh 'docker -H tcp://host.docker.internal:2375 run -d --name flask-test -p 5000:5000 flask-hello'
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
        stage('Load Test') {
            steps {
                // Locust im Headless-Modus starten, 1000 User max, 100 pro Sekunde
                sh '''
                locust -f locustfile.py --host=http://host.docker.internal:5000 \
                       --headless -u 1000 -r 100 --run-time 1m --stop-timeout 10
                '''
            }
        }
        // Optional: Cleanup nach Load-Test
        // stage('Cleanup') {
        //     steps {
        //         sh 'docker -H tcp://host.docker.internal:2375 rm -f flask-test'
        //     }
        // }
    }
}
