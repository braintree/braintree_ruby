#!groovy

def FAILED_STAGE

pipeline {
  agent none

  environment {
    REPO_NAME = "braintree-ruby"
    SLACK_CHANNEL = "#auto-team-sdk-builds"
  }

  options {
    buildDiscarder(logRotator(numToKeepStr: '50'))
    timestamps()
    timeout(time: 120, unit: 'MINUTES')
  }

  stages {
    stage("Audit") {
      parallel {
        stage("CodeQL") {
          agent {
            node {
              label ""
              customWorkspace "workspace/${REPO_NAME}"
            }
          }

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

        stage("SonarQube") {
          agent {
            node {
              label ""
              customWorkspace "workspace/${REPO_NAME}"
            }
          }

          steps {
            script {
              sh "docker build -t braintree-ruby ."
              sh "docker run --rm -e COVERAGE=1 -v \"\$(pwd):\$(pwd)\" -w \"\$(pwd)\" braintree-ruby /bin/bash -l -c 'bundle install && bundle exec rspec --pattern spec/unit/**/*_spec.rb'"
              executeSonarQubeScan()
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
    }

    stage("Lint") {
      when {
        branch 'master'
      }

      agent {
        node {
          label ""
          customWorkspace "workspace/${REPO_NAME}"
        }
      }

      steps {
        build job: 'ruby_sdk_master_lint', wait: true
      }

      post {
        failure {
          script {
            FAILED_STAGE = env.STAGE_NAME
          }
        }
      }
    }

    stage("SDK Tests") {
      when {
        branch 'master'
      }

      parallel {
        stage("Ruby 2.6 Bullseye") {
          agent {
            node {
              label ""
              customWorkspace "workspace/${REPO_NAME}"
            }
          }

          steps {
            build job: 'ruby_2.6-bullseye_server_sdk_master', wait: true
          }

          post {
            failure {
              script {
                FAILED_STAGE = env.STAGE_NAME
              }
            }
          }
        }

        stage("Ruby 2.7.7 Bullseye") {
          agent {
            node {
              label ""
              customWorkspace "workspace/${REPO_NAME}"
            }
          }

          steps {
            build job: 'ruby_2.7.7-bullseye_server_sdk_master', wait: true
          }

          post {
            failure {
              script {
                FAILED_STAGE = env.STAGE_NAME
              }
            }
          }
        }

        stage("Ruby 3.0.6 Bullseye") {
          agent {
            node {
              label ""
              customWorkspace "workspace/${REPO_NAME}"
            }
          }

          steps {
            build job: 'ruby_3.0.6-bullseye_server_sdk_master', wait: true
          }

          post {
            failure {
              script {
                FAILED_STAGE = env.STAGE_NAME
              }
            }
          }
        }

        stage("Ruby 3.4 Bookworm") {
          agent {
            node {
              label ""
              customWorkspace "workspace/${REPO_NAME}"
            }
          }

          steps {
            build job: 'ruby_3.4-bookworm_server_sdk_master', wait: true
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
