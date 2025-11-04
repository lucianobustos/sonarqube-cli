#!/usr/bin/env bash
# sq - Minimal SonarQube/SonarCloud CLI
# Requires: curl, jq, column
# Author: Luciano Bustos <luchyx@gmail.com>

SONAR_HOST="${SONAR_HOST:-https://sonarcloud.io}"
SONAR_TOKEN="${SONAR_TOKEN:?You must define SONAR_TOKEN}"
VERSION="1.1.0"

# --- Colors and icons ---
ICON_CLOUD="☁️ "
ICON_CONF="⚙️ "
ICON_STAR="⭐ "
ICON_PR="🔀 "
ICON_BUG="🐞 "
ICON_WARN="⚠️ "
ICON_OK="✅ "
ICON_LINK="🔗"
BOLD="\033[1m"
RESET="\033[0m"

# self-install
if [[ "$1" == "install" ]]; then
  target="$HOME/.local/bin/sq"
  mkdir -p "$(dirname "$target")"
  cp -f "$0" "$target"
  chmod +x "$target"
  echo "$VERSION Installed CLI to: $target"
  echo "Make sure this path is in your \$PATH:"
  echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
  [[ "${BASH_SOURCE[0]}" != "${0}" ]] && return 0 || exit 0
fi

project="$1"
pr_id="$2"
action="$3"
flag="$4"

api() {
  curl -s -u "$SONAR_TOKEN:" "$SONAR_HOST/api/$1"
}

is_json() {
  [[ "$flag" == "--json" ]]
}

print_table() {
  if command -v column >/dev/null; then
    column -t -s $'\t'
  else
    cat
  fi
}

show_help() {
  echo -e "${ICON_CLOUD}${BOLD} SonarQube CLI $VERSION${RESET}"
  echo ""
  echo "Usage:"
  echo "  sq                          Show available commands"
  echo "  sq config                   Show current SonarQube configuration"
  echo "  sq favourites [--json]      List your favourite projects"
  echo "  sq <project> [--json]       Show project overview"
  echo "  sq <project> <pr> status [--json]     Show pull request status"
  echo "  sq <project> <pr> analysis [--json]   Show pull request metrics summary"
  echo "  sq <project> <pr> coverage [--json]   Show pull request coverage metrics"
}

show_config() {
  echo -e "${ICON_CONF}${BOLD} Configuration${RESET}"
  echo -e "KEY\tVALUE"
  {
    echo -e "Sonar Host\t$SONAR_HOST"
    echo -e "Sonar Token\t${SONAR_TOKEN:0:6}******"
  } | print_table
}

show_favourites() {
  local data
  data=$(api "favorites/search")
  if is_json; then echo "$data" | jq; else
    echo -e "${ICON_STAR}${BOLD} Favourites${RESET}"
    echo -e "KEY\tNAME\tLINK"
    echo "$data" | jq -r --arg h "$SONAR_HOST" \
      '.favorites[] | [.key, .name, ($h+"/dashboard?id="+.key)] | @tsv' \
      | print_table
  fi
}

show_project_summary() {
  local data
  data=$(api "projects/search?projects=$project")
  if is_json; then echo "$data" | jq; else
    echo -e "${ICON_CLOUD}${BOLD} Project Overview${RESET}"
    echo -e "KEY\tNAME\tVISIBILITY\tTYPE\tLINK"
    echo "$data" | jq -r --arg h "$SONAR_HOST" \
      '.components[] | [.key, .name, .visibility, .qualifier, ($h+"/dashboard?id="+.key)] | @tsv' \
      | print_table
  fi
}

show_pr_status() {
  local data
  data=$(api "project_pull_requests/list?project=$project")
  if is_json; then
    echo "$data" | jq --arg id "$pr_id" '.pullRequests[] | select(.key == $id)'
  else
    echo -e "${ICON_PR}${BOLD} Pull Request Status${RESET}"
    echo -e "ID\tBRANCH\tTITLE\tQGATE\tDATE\tLINK"
    echo "$data" | jq -r --arg id "$pr_id" --arg h "$SONAR_HOST" --arg proj "$project" '
      .pullRequests[] 
      | select(.key == $id)
      | [
          .key // "",
          .branch // "",
          .title // "",
          (.status.qualityGateStatus // ""),
          .analysisDate // "",
          ($h + "/dashboard?id=" + $proj + "&pullRequest=" + .key)
        ] | @tsv
    ' | awk -F'\t' '{
        q=$4
        if (q=="OK")      color="\033[32m"      # green
        else if (q=="ERROR") color="\033[31m"   # red
        else if (q=="WARN")  color="\033[33m"   # yellow
        else color="\033[0m"
        printf "%s\t%s\t%s\t%s%s\033[0m\t%s\t%s\n", $1,$2,$3,color,q,$5,$6
      }' | print_table
  fi
}


show_pr_analysis() {
  local metrics="coverage,bugs,vulnerabilities,code_smells,duplicated_lines_density"
  local data
  data=$(api "measures/component?component=$project&pullRequest=$pr_id&metricKeys=$metrics")
  if is_json; then echo "$data" | jq; else
    echo -e "${ICON_PR}${BOLD} PR Analysis Metrics${RESET}"
    echo -e "METRIC\tVALUE"
    echo "$data" | jq -r '
      .component.measures[]
      | [.metric, .value // ""] | @tsv
    ' | print_table
  fi
}

show_pr_coverage() {
  local data
  data=$(api "measures/component_tree?component=$project&pullRequest=$pr_id&metricKeys=coverage,line_coverage,branch_coverage,uncovered_lines,lines_to_cover")
  if is_json; then echo "$data" | jq; else
    echo -e "${ICON_BUG}${BOLD} Coverage Metrics${RESET}"
    echo -e "METRIC\tVALUE"
    echo "$data" | jq -r '.baseComponent.measures[]? | [.metric, .value // ""] | @tsv' | print_table
  fi
}

# Routing
if [[ -z "$project" ]]; then
  show_help
  [[ "${BASH_SOURCE[0]}" != "${0}" ]] && return 0 || exit 0
fi

case "$project" in
  help|--help|-h)
    show_help
    ;;
  config)
    show_config
    ;;
  favourites|favorites)
    show_favourites
    ;;
  *)
    if [[ -z "$pr_id" ]]; then
      show_project_summary
    else
      case "$action" in
        ""|status)   show_pr_status ;;
        analysis)    show_pr_analysis ;;
        coverage)    show_pr_coverage ;;
        *)
          echo "Unknown action: $action"
          show_help
          [[ "${BASH_SOURCE[0]}" != "${0}" ]] && return 1 || exit 1 ;;
      esac
    fi
    ;;
esac
