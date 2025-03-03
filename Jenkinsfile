#!groovy

def FAILED_STAGE

pipeline {
  agent {
    node {
      label "ec2"
      customWorkspace "workspace/braintree-ruby"
    }
  }
  environment {
    SLACK_CHANNEL = "#auto-team-sdk-builds"
  }

  options {
    buildDiscarder(logRotator(numToKeepStr: '50'))
    timestamps()
    timeout(time: 120, unit: 'MINUTES')
  }

  stages {
    stage("CodeQL") {
      steps {
        script {
          codeQLv2(ruby: true)
        }
      }

      post {
        failure {
          script {
            FAILED_STAGE = env.STAGE_NAME
          }
        }
      }
    }
  }

  post {
    unsuccessful {
      slackSend color: "danger",
        channel: "${env.SLACK_CHANNEL}",
        message: "${env.JOB_NAME} - #${env.BUILD_NUMBER} Failure after ${currentBuild.durationString} at stage \"${FAILED_STAGE}\"(<${env.BUILD_URL}|Open>)"
    }
  }
}
