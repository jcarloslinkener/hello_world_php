pipeline {
    agent { docker { image 'php:8.4.4-alpine3.21' } }
    stages {
        stage('build') {
            steps {
                sh 'php --version'
            }
        }
    }
}
