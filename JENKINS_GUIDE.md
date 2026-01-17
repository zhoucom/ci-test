# Spring Boot + Jenkins CI/CD 本地搭建指南 (Docker 版)

这份指南将指导你如何在本地 Mac 上使用 Docker 搭建 Jenkins，并将其与 GitHub 上的 Spring Boot 项目集成。

> [!NOTE]
> **关于网络环境的重要说明**：
> 鉴于你的 Jenkins 运行在本地且**没有配置内网穿透** (No public IP)，GitHub 无法通过 Webhook 主动通知 Jenkins。
> 因此，我们将通过配置 Jenkins **定时扫描 (Polling)** 来检测代码更新，或者手动触发构建。

## 1. 环境准备 (Prerequisites)

确保你的 Mac 上已经安装并运行了 Docker。

```bash
docker -v
docker-compose -v
```

## 2. 启动 Jenkins 环境

在项目根目录下，运行以下命令一键启动：

```bash
docker-compose up -d --build
```
*首次启动可能需要几分钟下载镜像和插件，请耐心等待。*

启动完成后，访问 Jenkins：
- **URL**: [http://localhost:8080](http://localhost:8080)
- **管理员账号**: `admin`
- **管理员密码**: `admin`

## 3. GitHub 配置 (获取访问令牌)

你需要创建一个 Personal Access Token (PAT) 让 Jenkins 有权限拉取代码并回写构建状态（Build Status）。

1.  登录 GitHub，点击右上角头像 -> **Settings**。
2.  在左侧菜单最下方点击 **Developer settings**。
3.  点击 **Personal access tokens** -> **Tokens (classic)**。
4.  点击 **Generate new token** -> **Generate new token (classic)**。
5.  **Note** (备注): 填写 `Jenkins Local Token`。
6.  **Expiration** (过期时间): 建议选择 `No expiration` 或根据需要设置。
7.  **Select scopes** (选择权限) - **必须勾选以下两项**:
    - [x] `repo` (Full control of private repositories) —— 用于拉取代码和更新 Commit Status。
    - [x] `admin:repo_hook` (Full control of repository hooks) —— 虽然不用 webhook 触发，但有时插件检查需要此权限。
8.  点击底部的 **Generate token** 按钮。
9.  **关键**: 立即复制生成的 Token (以 `ghp_` 开头)，关掉页面就看不到了。

### 4. 在 Jenkins 配置 GitHub 凭据 (PAT)

1. 进入 **Manage Jenkins** -> **Credentials** -> **System** -> **Global credentials (unrestricted)** -> **Add Credentials**。
2. **关键配置 (必看)**：
   - **Kind**: 必须选择 **`Username with password`** (很多教程说选 Secret text，但在 Multibranch 模式下，选这个最稳定)。
   - **Username**: 填写您的 GitHub 用户名。
   - **Password**: 填写您的 GitHub **PAT (Token)**。
   - **ID**: 建议起名为 `github-auth` (记住这个 ID)。
   - **Description**: 随便写。
3. 点击 **Create**。

> [!TIP]
> **报错排查**：如果您在创建工程时下拉框选不到 ID，请回头检查 Kind 是否选成了 "Secret text"。

## 5. 创建多分支流水线 (Multibranch Pipeline)

1.  回到 Jenkins 首页 (Dashboard)，点击 **+ New Item**。
2.  **Enter an item name**: 输入项目名称，例如 `spring-boot-jenkins`。
3.  选择 **Multibranch Pipeline** (多分支流水线)。
4.  点击 **OK**。

### 配置项目详情：
在配置页面中：

1.  **Branch Sources (分支源)**:
    - 点击 **Add source** -> 选择 **GitHub**。
    - **Credentials**: 选择刚才创建的 `GitHub PAT for Local Jenkins`。
    - **Repository HTTPS URL**: 粘贴你的 GitHub 仓库地址 (例如 `https://github.com/yourname/repo.git`)。
    - 点击 **Validate** 确保连接成功。

2.  **Scan Multibranch Pipeline Triggers (关键配置)**:
    - *因为没有 Webhook，我们需要让 Jenkins 主动检查代码更新。*
    - 勾选 **Periodically if not otherwise run**。
    - **Interval**: 选择 `1 minute` 或 `2 minutes` (为了测试可以设快点)。
    - *这意味着 Jenkins 会每隔几分钟去 GitHub 看看有没有新代码，如果有，就触发构建。*

3.  点击底部的 **Save**。

保存后，Jenkins 会立即开始第一次扫描 (Scanning)。如果你的仓库里已经有了 `Jenkinsfile`，它就会自动开始构建。

## 6. 设置 GitHub 分支保护 (实现“不通过不准 Merge”)

你看到 "No checks have been added" 是正常的。**GitHub 的列表是动态的：只有当 GitHub 账号*收到过一次*来自 Jenkins 的状态报告后，那个名字才会出现在搜索框里。**

### 第一步：激活状态名 (最关键)

为了让 GitHub 知道有一个叫 `Jenkins/Build` 的检查项，你需要先手动“调戏”一下 GitHub API。

**请在你的 Mac 终端（或 Windows PowerShell）执行第 8 章中的 [1. 模拟构建成功] 的命令。**

执行成功后，GitHub 就会记录下这个 `Jenkins/Build` 的名字。

### 第二步：配置分支保护规则

1.  进入 GitHub 仓库页面 -> **Settings** -> **Branches**。
2.  点击 **Add branch protection rule**。
3.  **Branch name pattern**: 输入 `main` (或者是你想保护的分支名)。
4.  勾选 **Require a pull request before merging**。
5.  勾选 **Require status checks to pass before merging**。
6.  **在搜索框中搜索**: 输入 `Jenkins/Build`。
    - *如果你上一步执行了 curl 命令，现在这里会跳出这个选项，点击勾选它。*
7.  (可选) 勾选 **Require branches to be up to date before merging** —— 确保 PR 是基于最新代码测试的。
8.  点击底部的 **Create** (或 **Save changes**)。

---

## 7. 验证流程 (How to Verify)

1.  **提交代码**: 在本地修改代码并 Push 到一个新的 Feature 分支 (例如 `feature/test-ci`)。
2.  **等待触发**:
    - 由于是定时扫描 (Polling)，可能需要等待 1-2 分钟。
    - 或者你可以去 Jenkins 项目页面，点击左侧的 **Scan Repository Now** 立即触发。
3.  **观察构建**:
    - Jenkins 应该会自动发现新分支并开始构建 (`Build & Test`)。
    - 构建完成后，会生成 Jacoco 覆盖率报告。
4.  **查看 GitHub PR**:
    - 在 GitHub 上主要分支新建 Pull Request。
    - 你会看到底部的 Checks 部分显示 Jenkins 的构建状态 (Pending -> Success)。
    - 如果构建失败，GitHub 会禁止 Merge 按钮 (如果配置了分支保护)。

## 常见问题
*   **构建一直不触发？**
    *   检查 Jenkins 项目配置里的 **Scan Multibranch Pipeline Triggers** 是否勾选。
    *   手动点一下 **Scan Repository Now** 试试。
## 8. 手动模拟 GitHub 状态 (使用 Curl)

你可以通过以下命令在 GitHub 界面上显示具体的失败原因。

### A. 准备工作 (变量)
根据你的环境，你的变量如下：
- **Token**: `ghp_Q5V3j...` (建议设为环境变量)
- **Repo**: `zhoucom/ci-test`
- **SHA**: 在 PR 的 Commits 页面复制长 Hash

---

### B. Mac / Linux (Bash) 命令场景

| 场景 | 命令 |
| :--- | :--- |
| **0. 初始化/运行中** | `curl -L -X POST -H "Authorization: Bearer <TOKEN>" https://api.github.com/repos/zhoucom/ci-test/statuses/<SHA> -d '{"state":"pending","description":"Build is running...","context":"Jenkins/Build"}'` |
| **1. 编译失败** | `curl -L -X POST -H "Authorization: Bearer <TOKEN>" https://api.github.com/repos/zhoucom/ci-test/statuses/<SHA> -d '{"state":"failure","description":"Build Failed: syntax error in HelloController.java","context":"Jenkins/Build"}'` |
| **2. 测试失败** | `curl -L -X POST -H "Authorization: Bearer <TOKEN>" https://api.github.com/repos/zhoucom/ci-test/statuses/<SHA> -d '{"state":"failure","description":"Tests Failed: 2 tests failed","context":"Jenkins/Build"}'` |
| **3. 覆盖率低** | `curl -L -X POST -H "Authorization: Bearer <TOKEN>" https://api.github.com/repos/zhoucom/ci-test/statuses/<SHA> -d '{"state":"failure","description":"Jacoco Error: Coverage 10.5% < 80%","context":"Jenkins/Build"}'` |
| **4. 恢复成功** | `curl -L -X POST -H "Authorization: Bearer <TOKEN>" https://api.github.com/repos/zhoucom/ci-test/statuses/<SHA> -d '{"state":"success","description":"All checks passed!","context":"Jenkins/Build"}'` |

---

### C. Windows (PowerShell) 命令场景

在 PowerShell 中，先执行这一行设置变量：
```powershell
$headers = @{"Authorization" = "Bearer ghp_xxx"; "Accept" = "application/vnd.github+json"}
$url = "https://api.github.com/repos/zhoucom/ci-test/statuses/<SHA>"
```

**0. 模拟运行中 (Pending):**
```powershell
$body = @{ state="pending"; description="Build is running..."; context="Jenkins/Build" } | ConvertTo-Json
Invoke-RestMethod -Method Post -Uri $url -Headers $headers -Body $body
```

*(其他编译/测试/成功命令同上文，只需修改 $body 中的 state 和 description)*

---

## 9. 真实代码模拟 (触发 Build / Test 失败)

我也在代码里为你准备了“失败开关”，你可以在本地 Maven 构建时通过参数触发真实的失败：

1.  **触发编译失败**:
    运行 `mvn verify -Dfail.build=true`
    *(使用了 maven-enforcer-plugin 模拟)*

2.  **触发测试失败**:
    运行 `mvn verify -Dfail.tests=true`
    *(Controller 测试会主动抛出 AssertionError)*

3.  **触发覆盖率检查失败**:
    运行 `mvn verify -Djacoco.minimum.coverage=1.0`
    *(强制要求 100% 覆盖率，目前代码肯定达不到，会触发报错)*

---

## 10. 进阶：如何规模化管理 (GitHub App)

你提到的“每个新分支都要触发一次 Curl”确实很麻烦。这是因为你目前使用的是 **PAT (Personal Access Token)** 这种“个人补丁”模式。

在企业级开发中，我们使用 **GitHub App** 来解决：

### 为什么用 GitHub App？
1.  **自动激活**：一旦 App 安装到仓库，它的所有 Check 权限会自动对该 Repo 生效。
2.  **批量管理**：你可以创建一个 App（比如叫 `Company-CI`），然后点击 `Install App` 并勾选 `All repositories`。这样你名下所有（及未来创建）的工程都会自动拥有这个检查项。
3.  **安全性**：不需要暴露个人 Token，权限粒度更细。

### 简单的配置思路：
1.  **在 GitHub 创建 App**: `Settings` -> `Developer settings` -> `GitHub Apps` -> `New GitHub App`。
2.  **设置权限**: 勾选 `Checks: Read & write` 和 `Statuses: Read & write`。
3.  **安装**: 点击 `Install App` 安装到你的整个 zhoucom 组织或个人账号下。
4.  **Jenkins 集成**: 在 Jenkins 的 GitHub 配置里，不选 `Secret Text`，而是使用 `GitHub App` 类型的凭据（需要上传 `.pem` 私钥）。

---

## 11. 在 Jenkins UI 中一键触发失败 (参数化构建)

我已经更新了 `Jenkinsfile`，支持在 Jenkins 界面上直接勾选开关来模拟失败。

### A. 如何在 Jenkins 开启“参数化”
由于多分支流水线（Multibranch Pipeline）是自动扫描 `Jenkinsfile` 的，通常在文件更新后，你需要：
1.  在 Jenkins 项目页面点击左侧的 **Scan Repository Now**。
2.  等待扫描完成。
3.  点击具体的某一个分支（如 `main` 或 `test-feature`）。
4.  如果你是第一次运行，左侧可能还是 `Build Now`；**请点击手动运行一次**。
5.  运行过一次后，左侧菜单会变成 **Build with Parameters**。

### B. 模拟步骤 (演示)

1.  点击 **Build with Parameters**。
2.  你会看到三个选项：
    - **FAIL_BUILD**: 勾选后，Maven 会因为 Enforcer 插件报错，Jenkins 会向 GitHub 发送 "Simulated Build Failure"。
    - **FAIL_TESTS**: 勾选后，单元测试会抛出异常，Jenkins 发送 "Simulated Test Failure"。
    - **JACOCO_MIN_COVERAGE**: 输入 `1.00`，会因为覆盖率达不到 100% 而报错。
3.  点击 **Build** 按钮。

### C. 观察结果
- **Jenkins 内部**: 你会在 Console Output 看到我自定义的错误信息：`!!! [SIMULATED FAILURE] ... !!!`。
- **GitHub PR 界面**: 刷新 PR，你会看到底部 Checks 自动从 Pending 变成 Failure，并且 **Description 描述内容** 与你勾选的开关完全对应。

---

### 总结：你的模拟调试流程
1.  **代码改动**: 在 IDE 改代码并 Push。
2.  **Jenkins 触发**: 去 Jenkins 界面选一个失败场景点 Build。
3.  **GitHub 确认**: 去 PR 页面确认 Merge 按钮是否被锁死，以及报错文案是否正确。
---

## 12. 手动安装插件并保存为镜像 (解决网络异常)

由于国内网络环境复杂，自动下载插件经常失败。最稳妥的办法是：**先启动一个“干净”的 Jenkins，在 UI 界面手动装好插件，然后将整个状态“打包”成镜像推送到 Docker Hub。**

### 第一步：启动干净的 Jenkins
我已经将 `Dockerfile` 中的 Jenkins 版本切换到了最稳定的 `lts-jdk17` 镜像，并注释掉了自动下载代码。现在执行：
```bash
docker-compose up -d --build
```

### 第二步：正确的手动安装顺序 (防止依赖报错)
Jenkins 插件之间有复杂的依赖关系（如你遇到的 `workflow-api` 报错）。请务必按照以下顺序操作，**不要手动点开每一个小插件安装**：

1. **初始安装向导 (墙裂建议)**：
   如果你是第一次启动，访问 `http://localhost:8080` 会看到安装向导。请直接点击 **"Install suggested plugins" (安装推荐插件)**。这会帮你自动装好 90% 的基础依赖。

2. **如果错过了向导**：
   去 **Manage Jenkins** -> **Plugins** -> **Available Plugins**，只需搜索并安装这 **两个大包**，它们会自动勾选所有依赖：
   - **Pipeline** (搜索 `workflow-aggregator`)：安装这一个，它会带起你报错里提到的所有 `workflow-api`、`workflow-step-api` 等。
   - **GitHub Branch Source**：安装它，它会带起所有 `scm-api` 等依赖。

3. **补充安装**：
   在上述两个大包装完后，再单独补装：
   - `jacoco`
    - `blueocean`

> [!IMPORTANT]
> **安装技巧**：在勾选完插件点安装后，请务必勾选界面底部的 **"Restart Jenkins when installation is complete"**。很多依赖错误是通过重启解决的。

### 第三步：如果“Add source”里看不到 GitHub？
如果你在配置界面点击 **Add source** 却只看到 "Single repository & branch"（如你截图所示），这说明 **GitHub Branch Source** 插件没有安装成功或没有激活。

请按照以下步骤排查：
1. **检查已安装列表**：
   - 进入 **Manage Jenkins** -> **Plugins** -> **Installed plugins**。
   - 搜索 `GitHub Branch Source`。
2. **确认状态**：
   - 如果它在列表里，但右侧有红色报错（类似你之前遇到的 `dependency errors`），请看它的具体提示。通常是缺少了 `GitHub Plugin` 或 `SCM API`。
   - 如果它不在列表里，请回到 **Available Plugins** 重新搜索并安装。
3. **强制激活依赖**：
   - 最简单粗暴的方法：直接在 **Available Plugins** 搜索并安装 **"GitHub Integration"** 和 **"Pipeline"**。这两个是“大包”，安装它们通常会自动勾选所有底层的小碎片。
4. **重启是万能的**：
   - 安装完一定要勾选底部的 **"Restart Jenkins"**，或者直接在终端 `docker-compose restart jenkins`。

---

### 第四步：将安装好插件的状态保存为新镜像
当你在界面上装好所有插件后，这些插件是在“容器”里的。我们需要用 `commit` 命令把它固化：

1. **查找运行中的容器 ID**:
   ```bash
   docker ps
   # 假设你的容器 ID 是 abc123456
   ```

2. **提交为新镜像 (Snapshot)**:
   ```bash
   # 格式：docker commit <容器ID> <你的用户名>/jenkins-custom:<版本号>
   docker commit abc123456 zhoucom/jenkins-custom:v1.0
   ```

### 第四步：推送到 Docker Hub
1. **登录**: `docker login` (输入你的 Docker Hub 账号密码)。
2. **推送**: 
   ```bash
   docker push zhoucom/jenkins-custom:v1.0
   ```
3. **导出文件 (离线备用)**:
   ```bash
   docker save -o jenkins-v1.0.tar zhoucom/jenkins-custom:v1.0
   ```

---

## 13. 如何通过 Docker Hub 镜像分发给其他人

一旦你完成了上述步骤，你的同事或另一台机器就不再需要经历“下载插件”的痛苦了：

1. **修改 docker-compose.yml**:
   将 `build: ./jenkins-setup` 改为直接使用你刚推上去的镜像：
   ```yaml
   services:
     jenkins:
       image: zhoucom/jenkins-custom:v1.0  # 直接使用你做好的成品镜像
       # build: ./jenkins-setup (注释掉这一行)
   ```

2. **一键启动**:
   ```bash
   docker-compose up -d
   ```
   **秒开！** 所有的插件都已经预装在里面了。

### 场景三：数据持久化 (Volume)
请注意，镜像只负责保存“程序和插件”，而不保存“作业记录、构建历史、账号”。所有的工作内容都保存在 `docker-compose.yml` 中定义的 `jenkins-data` 卷里。
- 如果你想备份任务和配置，你应该备份 Docker 的 Volume 文件夹（通常在 `/var/lib/docker/volumes/`），而不是只备份镜像。
