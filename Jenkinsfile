pipeline {
    // This label must refer to the node on the application server.
    agent { label 'home-deploy' }

    options {
        disableConcurrentBuilds()
        skipDefaultCheckout(true)
        timestamps()
        buildDiscarder(logRotator(numToKeepStr: '20', artifactNumToKeepStr: '5'))
    }

    // Works even when Jenkins is reachable only on the private network.
    triggers { pollSCM('* * * * *') }

    stages {
        stage('Checkout') {
            steps { checkout scm }
        }
        stage('Build and test') {
            options { timeout(time: 20, unit: 'MINUTES') }
            steps { sh 'bash ./gradlew --no-daemon clean build' }
            post { always { junit testResults: 'build/test-results/test/*.xml', allowEmptyResults: true } }
        }
        stage('Archive') {
            steps {
                archiveArtifacts artifacts: 'build/libs/*.jar', excludes: 'build/libs/*-plain.jar', fingerprint: true
            }
        }
        stage('Deploy') {
            steps { sh 'bash ops/deploy-jenkins.sh' }
        }
    }
}
