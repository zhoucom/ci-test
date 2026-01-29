# Plugin-Free Jenkins Setup Guide (Lightweight)

This guide enables a "Native Shell" approach using standard Maven plugins for quality analysis, avoiding heavy external servers like SonarQube.

## 1. Prerequisites (On Jenkins Agent Machine)
Ensure the following tools are available in the system `$PATH`.

### Java (JDK 17+) & Maven (3.9+)
Required for building and running tests. The quality analysis (PMD/Checkstyle) is handled directly by Maven.

---

## 2. Jenkins Global Configuration
We use **Global Environment Variables** for repository access.

1. Go to **Dashboard** -> **Manage Jenkins** -> **System**.
2. Scroll to **Global properties** -> **Environment variables**.
3. Add only what's needed:

| Name | Default/Example | Description |
|------|-------|-------------|
| `GIT_TOKEN` | `ghp_xxxx` | GitHub PAT with repo/status permissions. |

---

## 3. Lightweight Quality Gate
Instead of SonarQube, we use:
1. **PMD**: Detects potential bugs and dead code.
2. **Checkstyle**: Enforces coding standards.
3. **JaCoCo**: Measures code coverage.

All reports are generated as HTML files in the `target/site/` directory of your project.

## 4. How to Use
1. Copy the `jenkins-native` folder to your project root.
2. In your Jenkins Job configuration:
   - **Script Path**: `jenkins-native/Jenkinsfile`.
   - **Build Triggers**: Check "Poll SCM" for auto-builds.

## 5. Troubleshooting
- **"Report not found"**: Ensure the `pmd-maven-plugin` and `checkstyle-maven-plugin` are in your `pom.xml`.
- **"Quality Gate Failed"**: Adjust the `MAX_QUALITY_ISSUES` parameter in the Jenkins build screen.
