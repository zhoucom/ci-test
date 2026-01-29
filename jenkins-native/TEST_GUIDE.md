# Plugin-Free Jenkins: Testing Guide (Zero-Plugin SCM)

This guide covers how to set up your CI/CD without the Jenkins Git plugin by using an inline "bootstrapper" script.

## 1. Start Jenkins
```bash
cd jenkins-native
docker-compose up -d --build
```

## 2. Access Jenkins
[http://localhost:8081](http://localhost:8081)

## 3. Step-by-Step: Zero-Plugin Configuration

### 第一步：创建 Job
1. 点击 **New Item** -> 输入名称 -> 选择 **Pipeline** -> **OK**。

### 第二步：配置参数
1. 勾选 **This project is parameterized**。
2. 添加以下关键参数：
   - `REPO_URL`: Git 地址 (例如 `https://github.com/zhoucom/jenkins-springboot.git`)。
   - `BRANCH_NAME`: 分支 (默认 `main`)。
   - `GIT_TOKEN`: GitHub 令牌 (用于私有仓库或状态更新)。

### 第三步：配置核心脚本（重点：不要选 SCM）
1. 在 **Pipeline** 部分，保持 **Definition** 为 **Pipeline script** (不是 from SCM)。
2. 在 **Script** 文本框中粘贴以下“引导”代码：

```groovy
node {
    stage('Manual Bootstrap') {
        // 1. 清理目录
        sh "rm -rf *"
        // 2. 只有这一步是手动的，克隆完成后，所有逻辑都在 repo 的 Jenkinsfile 里
        sh "git clone --depth 1 --branch ${params.BRANCH_NAME} ${params.REPO_URL} ."
        // 3. 加载并执行仓库里的真正流水线
        load "jenkins-native/Jenkinsfile"
    }
}
```
*这样你就不需要安装任何 Git 插件，Jenkins 只要能运行 shell 命令（git clone）就能工作。*

## 4. Why this works?
- **无需插件**：我们直接调用系统安装的 `git` 命令，避开了 Jenkins 的插件依赖。
- **配置完全外部化**：虽然引导脚本在 UI 里，但它只是个“梯子”，真正的构建逻辑依然维护在代码仓库的 `jenkins-native/Jenkinsfile` 中。

## 5. Cleanup
```bash
docker-compose down -v
```
