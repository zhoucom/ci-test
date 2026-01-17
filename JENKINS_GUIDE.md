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

## 4. 在 Jenkins 中配置凭据

1.  回到 Jenkins [http://localhost:8080](http://localhost:8080)。
2.  点击 **Manage Jenkins** (系统管理) -> **Credentials** (凭据)。
3.  点击 **System** -> **Global credentials (unrestricted)**。
4.  点击右上角的 **+ Add Credentials**。
5.  填写内容：
    - **Kind**: 选择 **Secret text** (注意不是 Username and password)。
    - **Scope**: `Global`。
    - **Secret**: 粘贴刚才复制的 **GitHub Token**。
    - **ID**: `github-token` (这个 ID 很重要，Jenkinsfile 中可能会用到，虽然多分支流水线主要在配置里用)。
    - **Description**: `GitHub PAT for Local Jenkins`。
6.  点击 **Create**。

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

## 6. 设置 GitHub 分支保护 (Branch Protection)

为了实现 "构建成功后才能 Merge" 的目标，需要在 GitHub 上设置规则。**注意：这需要等 Jenkins 至少跑成功一次构建后才能在 GitHub 列表里看到对应的 Check 选项。**

1.  进入你的 GitHub 仓库页面。
2.  点击顶部导航栏的 **Settings**。
3.  在左侧栏点击 **Branches**。
4.  点击 **Add branch protection rule**。
5.  **Branch name pattern**: 输入 `main` (或者是你的保护分支名)。
6.  勾选 **Require status checks to pass before merging** (合并前需要状态检查通过)。
7.  在搜索框中搜索 Jenkins 上报的状态名。
    - 通常是 `Jenkins/Build` 或者 `continuous-integration/jenkins/branch`。
    - *如果在搜索框里找不到，请先去本地 Jenkins 手动触发一次构建并确保成功，GitHub 收到状态后这里就会出现。*
8.  点击底部的 **Create** 保存规则。

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

如果 Jenkins 无法连接 GitHub，或者你处于内网环境，可以使用以下 `curl` 命令手动更新 GitHub 的构建状态，从而控制 Pull Request 的 Merge 权限。

### A. 准备工作 (准备变量)
你需要替换以下参数：
- `GITHUB_TOKEN`: 你的 Personal Access Token。
- `OWNER`: 你的 GitHub 用户名。
- `REPO`: 仓库名称。
- `SHA`: 你推送的那个提交的完整 **Commit SHA** (可以在 GitHub Commit 列表看到)。

---

### B. Mac / Linux (Bash/Zsh) 命令

**1. 模拟构建成功 (Success):**
```bash
curl -L \
  -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer <YOUR_TOKEN>" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/repos/<OWNER>/<REPO>/statuses/<SHA> \
  -d '{"state":"success","description":"Jenkins Build Passed","context":"Jenkins/Build"}'
```

**2. 模拟测试失败 (Failure - Test Error):**
```bash
curl -L \
  -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer <YOUR_TOKEN>" \
  https://api.github.com/repos/<OWNER>/<REPO>/statuses/<SHA> \
  -d '{"state":"failure","description":"Unit tests failed","context":"Jenkins/Build"}'
```

**3. 模拟覆盖率失败 (Failure - Jacoco Error):**
```bash
curl -L \
  -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer <YOUR_TOKEN>" \
  https://api.github.com/repos/<OWNER>/<REPO>/statuses/<SHA> \
  -d '{"state":"failure","description":"Jacoco coverage below threshold (0%)","context":"Jenkins/Build"}'
```

---

### C. Windows (PowerShell) 命令

**1. 模拟构建成功 (Success):**
```powershell
$headers = @{
    "Authorization" = "Bearer <YOUR_TOKEN>"
    "Accept"        = "application/vnd.github+json"
}
$body = @{
    state       = "success"
    description = "Jenkins Build Passed"
    context     = "Jenkins/Build"
} | ConvertTo-Json

Invoke-RestMethod -Method Post -Uri "https://api.github.com/repos/<OWNER>/<REPO>/statuses/<SHA>" -Headers $headers -Body $body
```

**2. 模拟测试失败 (Failure - Test Error):**
```powershell
$body = @{
    state       = "failure"
    description = "Unit tests failed"
    context     = "Jenkins/Build"
} | ConvertTo-Json

Invoke-RestMethod -Method Post -Uri "https://api.github.com/repos/<OWNER>/<REPO>/statuses/<SHA>" -Headers $headers -Body $body
```

**3. 模拟覆盖率失败 (Failure - Jacoco Error):**
```powershell
$body = @{
    state       = "failure"
    description = "Jacoco coverage below threshold"
    context     = "Jenkins/Build"
} | ConvertTo-Json

Invoke-RestMethod -Method Post -Uri "https://api.github.com/repos/<OWNER>/<REPO>/statuses/<SHA>" -Headers $headers -Body $body
```

> [!TIP]
> **注意 context 的统一**：如果你在 GitHub 分支保护规则里设置的检查项名字是 `Jenkins/Build`，那么 curl 命令里的 `"context"` 也必须是这个名字，GitHub 才能正确识别。
