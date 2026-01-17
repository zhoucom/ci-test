pipeline {
    agent any
    
    // 定义参数，方便在 Jenkins 界面手动触发不同场景
    parameters {
        booleanParam(name: 'FAIL_BUILD', defaultValue: false, description: '强制编译失败 (模拟)')
        booleanParam(name: 'FAIL_TESTS', defaultValue: false, description: '强制单元测试失败 (模拟)')
        string(name: 'JACOCO_MIN_COVERAGE', defaultValue: '0.00', description: 'Jacoco 最小覆盖率要求 (0.00 - 1.00)')
    }

    stages {
        stage('Checkout') {
            steps {
                script {
                    // 初始化 GitHub 状态为 Pending
                    setGitHubStatus('pending', 'Jenkins build started...')
                }
                checkout scm
            }
        }

        stage('Build & Test') {
            steps {
                script {
                    try {
                        // 将 Jenkins 参数传递给 Maven
                        sh "mvn -B clean verify \
                            -Dfail.build=${params.FAIL_BUILD} \
                            -Dfail.tests=${params.FAIL_TESTS} \
                            -Djacoco.minimum.coverage=${params.JACOCO_MIN_COVERAGE}"
                    } catch (err) {
                        currentBuild.result = 'FAILURE'
                        throw err
                    }
                }
            }
        }

        stage('Jacoco Report') {
            steps {
                jacoco(
                    execPattern: '**/target/jacoco.exec',
                    classPattern: '**/target/classes',
                    sourcePattern: '**/src/main/java'
                )
            }
        }
    }

    post {
        success {
            setGitHubStatus('success', 'Build, Tests and Jacoco passed!')
        }
        failure {
            script {
                // 根据结果判断具体的错误信息上报给 GitHub
                def msg = "Build failed. Check Jenkins logs for details."
                if (params.FAIL_BUILD) msg = "Simulated Build Failure triggered."
                if (params.FAIL_TESTS) msg = "Simulated Test Failure triggered."
                
                setGitHubStatus('failure', msg)
            }
        }
        always {
            cleanWs()
        }
    }
}

// 辅助方法：统一发送 GitHub 状态
def setGitHubStatus(String state, String message) {
    echo "Attempting to set GitHub status to ${state}: ${message}"
    try {
        // 只有在 github 插件安装的情况下才调用
        githubNotify context: 'Jenkins/Build', description: message, status: state
    } catch (Throwable e) {
        echo "Note: Could not send GitHub status (Plugin might be missing): ${e.message}"
    }
}
