# ☁️ sq — Minimal SonarQube/SonarCloud CLI

A lightweight, portable Bash CLI to query **SonarQube** or **SonarCloud** directly — no scanner required.  
Ideal for developers and CI pipelines that need quick access to PR quality, metrics, and coverage without the full SonarQube scanner.
Ideal also to be consumed by AI tools that can execute command lines.

---

## 🚀 Features

- 🔹 Pure **Bash + curl + jq** — no heavy dependencies  
- 🔹 Works on **macOS** and **Linux**  
- 🔹 **Pretty tables** or machine-friendly `--json` output  
- 🔹 **Self-install** in one line  
- 🔹 Supports:
  - User favourites ⭐  
  - Project summaries ☁️  
  - Pull request status 🔀  
  - Analysis metrics 🧮  
  - Coverage details 🧩  

---

## 📦 Installation

```bash
curl -fsSL https://raw.githubusercontent.com/lucianobustos/sonarqube-cli/main/sonar-api.sh -o ./sonar-api.sh
chmod +x ./sonar-api.sh
./sonar-api.sh install
```

Ensure `~/.local/bin` is in your `PATH`:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

Then verify installation:

```bash
sq
```

---

## ⚙️ Configuration

The CLI reads your environment variables:

```bash
export SONAR_HOST="https://sonarcloud.io"
export SONAR_TOKEN="sqa_xxxxxxx"
```

Check configuration with:

```bash
sq config
```

Output example:

```
⚙️  Configuration
KEY          VALUE
Sonar Host   https://sonarcloud.io
Sonar Token  sqa_xxx******
```

---

## 💡 Usage

```bash
sq                           # Show help / available commands
sq config                    # Show configuration
sq favourites                # List your favourite projects
sq <project>                 # Show project overview
sq <project> <pr> status     # Show PR status
sq <project> <pr> analysis   # Show PR analysis metrics
sq <project> <pr> coverage   # Show coverage metrics
```

Add `--json` to any command for raw JSON output.

---

## 🧠 Examples

```bash
sq favourites
sq my-project
sq my-project 3058 status
sq my-project 3058 analysis --json
```

---

## 🧩 Output Preview

| ID   | BRANCH | TITLE | QGATE | DATE | LINK |
|------|---------|--------|--------|--------|------|
| 3058 | feature/PI-90986-user-repositories | feat(user): add user repository infrastructure | ❌ ERROR | 2025-11-03T18:03:12 | 🔗 [View in SonarCloud](https://sonarcloud.io/dashboard?id=my-project&pullRequest=3058) |
