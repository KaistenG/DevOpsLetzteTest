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
                // Prüfen, ob Container schon läuft und ggf. stoppen/entfernen
                sh '''
                if [ $(docker -H tcp://host.docker.internal:2375 ps -q -f name=flask-test) ]; then
                    docker -H tcp://host.docker.internal:2375 rm -f flask-test
                fi
                '''
                // Container im Hintergrund starten, persistent
                sh 'docker -H tcp://host.docker.internal:2375 run -d --name flask-test -p 5000:5000 flask-hello'
            }
        }
        stage('HTTP Test') {
            steps {
                // Kurze Wartezeit, damit Flask starten kann
                sh 'sleep 5'
                // Prüfen, ob Container antwortet
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
        // Cleanup-Stage optional, erst nach späteren Tests
        // stage('Cleanup') {
        //     steps {
        //         sh 'docker -H tcp://host.docker.internal:2375 rm -f flask-test'
        //     }
        // }
    }
}
