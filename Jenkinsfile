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
        stage('Run & HTTP Test Container') {
            steps {
                // Container im Hintergrund starten
                sh 'docker -H tcp://host.docker.internal:2375 run -d --name flask-test -p 5000:5000 flask-hello'

                // Kurze Wartezeit, damit Flask Zeit hat zu starten
                sh 'sleep 5'

                // HTTP-Test: prüfen, ob Container auf / antwortet
                sh '''
                STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://host.docker.internal:5000)
                if [ "$STATUS" -ne 200 ]; then
                    echo "HTTP-Test fehlgeschlagen: Status $STATUS"
                    exit 1
                fi
                echo "HTTP-Test erfolgreich: Status $STATUS"
                '''

                // Container wieder stoppen und entfernen
                sh 'docker -H tcp://host.docker.internal:2375 rm -f flask-test'
            }
        }
    }
}