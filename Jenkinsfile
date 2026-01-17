pipeline {
    agent {
        docker {
            image 'maven:3.9.6-eclipse-temurin-17' 
            args '-v /root/.m2:/root/.m2' 
        }
    }
    
    tools {
        // Use the maven tool declared in global config or JCasC
        maven 'Default'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build & Test') {
            steps {
                script {
                    try {
                        sh 'mvn -B clean package'
                    } catch (err) {
                        currentBuild.result = 'FAILURE'
                        throw err
                    }
                }
            }
            post {
                success {
                    // Update GitHub commit status to PENDING or SUCCESS is handled by the GitHub Multibranch Plugin usually, 
                    // but we can enforce it.
                    echo 'Build successful.'
                }
            }
        }

        stage('Jacoco Report') {
            steps {
                jacoco(
                    execPattern: '**/target/jacoco.exec',
                    classPattern: '**/target/classes',
                    sourcePattern: '**/src/main/java',
                    exclusionPattern: '**/src/test*'
                )
            }
        }
    }

    post {
        always {
            cleanWs()
        }
        success {
            script {
                if (env.BRANCH_NAME != null) {
                    setGitHubPullRequestStatus(context: 'Jenkins/Build', message: 'Build passed', state: 'SUCCESS')
                }
            }
        }
        failure {
            script {
                if (env.BRANCH_NAME != null) {
                    setGitHubPullRequestStatus(context: 'Jenkins/Build', message: 'Build failed', state: 'FAILURE')
                }
            }
        }
    }
}

// Function to manually set GitHub status if needed (though the GitHub Branch Source plugin often handles this automatically)
// This requires the 'github' plugin and proper credentials/context.
void setGitHubPullRequestStatus(Map args) {
    // This is a placeholder. In a real Multibranch pipeline with GitHub Branch Source, 
    // the status is sent automatically for the checkout.
    // However, to send *custom* messages or contexts, you'd use the 'github-notify-step' or 'github-checks' blocks.
    // Since we are using the simple pipeline, we'll rely on the default behavior first.
    // If explicit reporting is needed, we would use:
    // githubNotify context: args.context, description: args.message, status: args.state
    
    // For this setup, I will use the `githubNotify` step which allows custom messages.
    try {
        githubNotify context: args.context, description: args.message, status: args.state
    } catch (Exception e) {
        echo "Warning: Could not send GitHub status: ${e.message}. Ensure credentials are set."
    }
}
