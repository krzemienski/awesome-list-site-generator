#!/bin/bash

# Logging function
log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Ensure required tools are installed
install_dependencies() {
  log "Installing necessary dependencies..."

  # Install pip if not installed
  if ! command -v pip &> /dev/null; then
    log "pip not found. Installing pip..."
    curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
    python get-pip.py
    rm get-pip.py
  else
    log "pip is already installed."
  fi

  # Install mkdocs
  if ! command -v mkdocs &> /dev/null; then
    log "mkdocs not found. Installing mkdocs..."
    pip install mkdocs
  else
    log "mkdocs is already installed."
  fi

  # Install hugo
  if ! command -v hugo &> /dev/null; then
    log "hugo not found. Installing hugo..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
      brew install hugo
    else
      sudo snap install hugo
    fi
  else
    log "hugo is already installed."
  fi

  # Install yarn if not installed
  if ! command -v yarn &> /dev/null; then
    log "yarn not found. Installing yarn..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
      brew install yarn
    else
      npm install -g yarn
    fi
  else
    log "yarn is already installed."
  fi

  # Install docsify-cli
  if ! command -v docsify &> /dev/null; then
    log "docsify not found. Installing docsify..."
    npm install -g docsify-cli
  else
    log "docsify is already installed."
  fi

  log "All dependencies are installed."
}
# Parse the title from README.md
parse_title() {
  TITLE=$(grep -m 1 '^# ' "$LOCAL_README_FILE" | sed 's/^# //')
  log "Parsed title: $TITLE"
}

# Function to find an available port
find_available_port() {
  local port=8000
  while lsof -i:$port > /dev/null; do
    port=$((port + 1))
  done
  echo $port
}

# Function to set up MkDocs
setup_mkdocs() {
  local dir="$1/mkdocs-site"
  local theme=$2
  local port=$(find_available_port)

  log "Setting up MkDocs in $dir"
  mkdir -p "$dir"
  cd "$dir" || { log "Failed to change directory to $dir"; exit 1; }

  mkdocs new .
  cp "$LOCAL_README_FILE" docs/index.md
  sed -i "s/site_name:.*/site_name: $TITLE/" mkdocs.yml
  sed -i "s/theme:.*/theme: $theme/" mkdocs.yml

  mkdocs build
  mkdocs serve -a 127.0.0.1:$port &
  log "MkDocs is serving on port $port"
  cd - > /dev/null || log "Failed to return to previous directory"
}

# Function to set up Hugo
setup_hugo() {
  local dir="$1/hugo-site"
  local theme=$2
  local port=$(find_available_port)

  log "Setting up Hugo in $dir"
  mkdir -p "$dir"
  cd "$dir" || { log "Failed to change directory to $dir"; exit 1; }

  hugo new site .
  git submodule add "https://github.com/$theme.git" "themes/$(basename $theme)"
  echo "theme = $(basename $theme)" >> config.toml
  echo "title = $TITLE" >> config.toml

  cp "$LOCAL_README_FILE" content/_index.md
  hugo
  hugo server -D -p $port &
  log "Hugo is serving on port $port"
  cd - > /dev/null || log "Failed to return to previous directory"
}

# Function to set up VuePress
setup_vuepress() {
  local dir="$1/vuepress-site"
  local theme=$2
  local port=$(find_available_port)

  log "Setting up VuePress in $dir"
  mkdir -p "$dir/docs"
  cd "$dir" || { log "Failed to change directory to $dir"; exit 1; }

  yarn add -D vuepress "$theme"

  echo "module.exports = { title: \"$TITLE\", description: \"An Awesome List\", theme: \"$theme\" }" > docs/.vuepress/config.js

  cp "$LOCAL_README_FILE" docs/README.md
  npx vuepress build docs
  npx vuepress dev docs --port $port &
  log "VuePress is serving on port $port"
  cd - > /dev/null || log "Failed to return to previous directory"
}

# Function to set up Docsify
setup_docsify() {
  local dir="$1/docsify-site"
  local theme=$2
  local port=$(find_available_port)

  log "Setting up Docsify in $dir"
  mkdir -p "$dir"
  cd "$dir" || { log "Failed to change directory to $dir"; exit 1; }

  echo "<!DOCTYPE html>
<html>
<head>
  <meta charset=\"UTF-8\">
  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">
  <title>$TITLE</title>
  <link rel=\"stylesheet\" href=\"//cdn.jsdelivr.net/npm/docsify/lib/themes/$theme.css\">
</head>
<body>
  <div id=\"app\"></div>
  <script>
    window.\$docsify = {
      name: \"$TITLE\",
      repo: \"\",
      loadSidebar: true,
      subMaxLevel: 2
    }
  </script>
  <script src=\"//cdn.jsdelivr.net/npm/docsify/lib/docsify.min.js\"></script>
</body>
</html>" > index.html

  cp "$LOCAL_README_FILE" .
  docsify serve --port $port &
  log "Docsify is serving on port $port"
  cd - > /dev/null || log "Failed to return to previous directory"
}

# Function to select a framework
select_framework() {
  echo "Select a framework:"
  echo "1. MkDocs"
  echo "2. Hugo"
  echo "3. VuePress"
  echo "4. Docsify"
  read -p "Enter your choice (1-4): " choice
  case $choice in
    1) FRAMEWORK="MkDocs" ;;
    2) FRAMEWORK="Hugo" ;;
    3) FRAMEWORK="VuePress" ;;
    4) FRAMEWORK="Docsify" ;;
    *) echo "Invalid choice. Exiting."; exit 1 ;;
  esac
}

# Function to select a theme
select_theme() {
  local themes=("${!1}")
  echo "Available themes:"
  for i in "${!themes[@]}"; do
    echo "$((i + 1)). ${themes[$i]}"
  done
  read -p "Select a theme (1-${#themes[@]}): " theme_choice
  if [[ $theme_choice -ge 1 && $theme_choice -le ${#themes[@]} ]]; then
    SELECTED_THEME=${themes[$((theme_choice - 1))]}
  else
    echo "Invalid theme choice. Exiting."
    exit 1
  fi
}

# Check if the correct number of arguments is provided
if [ "$#" -lt 2 ]; then
  log "Usage: $0 README_FILE OUTPUT_DIRECTORY"
  exit 1
fi

# Assign arguments to variables
README_FILE=$1
OUTPUT_DIR=$2

# Copy the README file to the script's directory
LOCAL_README_FILE="$(pwd)/README-content.md"
cp "$README_FILE" "$LOCAL_README_FILE"
log "Copied README.md to $LOCAL_README_FILE"

# Parse the title from the README file
parse_title

# Create the main directory
mkdir -p "$OUTPUT_DIR"

# Install dependencies
install_dependencies

# Prompt for framework and theme selection
select_framework

case $FRAMEWORK in
  "MkDocs")
    THEMES=("mkdocs" "readthedocs" "material" "alabaster" "mkdocs-bootstrap" "mkdocs-cinder" "mkdocs-rtd-dropdown" "mkdocs-windmill" "mkdocs-yeti" "slate" "mkdocs-material" "mkdocs-alabaster" "mkdocs-bootstrap4" "mkdocs-insiders")
    select_theme THEMES[@]
    setup_mkdocs "$OUTPUT_DIR" "$SELECTED_THEME"
    ;;
  "Hugo")
    THEMES=("theNewDynamic/gohugo-theme-ananke" "bep/hyde" "spf13/hyde" "kubeflow/hugo-multilingual" "henrythemes/hugo-theme-minimo" "zenorocha/fliptheme" "calintat/minimal" "halogenica/beautifulhugo" "track3/hermit" "budparr/gohugo-theme-ananke" "digitalcraftsman/hugo-agency-theme" "htr3n/hyde-hyde" "muesli/beautifulhugo" "mathieudutour/hugo-drawer" "lucperkins/hugo-fresh")
    select_theme THEMES[@]
    setup_hugo "$OUTPUT_DIR" "$SELECTED_THEME"
    ;;
  "VuePress")
    THEMES=("vuepress/theme-default" "vuepress/theme-blog" "vuepress/theme-vue" "vuepress/theme-craft" "vuepress/theme-medium" "vuepress/theme-yuque" "vuepress/theme-book" "vuepress/theme-cosmos" "vuepress/theme-reco" "vuepress/theme-vdoing" "vuepress/theme-hope" "vuepress/theme-antdocs" "vuepress/theme-modern-blog" "vuepress/theme-ououe" "vuepress/theme-succinct")
    select_theme THEMES[@]
    setup_vuepress "$OUTPUT_DIR" "$SELECTED_THEME"
    ;;
  "Docsify")
    THEMES=("vue" "dark" "buble" "pure" "doka" "vuepress" "minty" "flatly" "readable" "materia" "cinder" "docsify-themeable" "docsify-themeable-dark" "docsify-themeable-light" "docsify-themeable-modern")
    select_theme THEMES[@]
    setup_docsify "$OUTPUT_DIR" "$SELECTED_THEME"
    ;;
esac
