
#!/bin/bash

# Ensure required tools are installed
install_dependencies() {
  echo "Installing necessary dependencies..."

  # Install pip if not installed
  if ! command -v pip &> /dev/null; then
    echo "pip not found. Installing pip..."
    curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
    python get-pip.py
    rm get-pip.py
  fi

  # Install mkdocs
  if ! command -v mkdocs &> /dev/null; then
    echo "mkdocs not found. Installing mkdocs..."
    pip install mkdocs
  fi

  # Install hugo
  if ! command -v hugo &> /dev/null; then
    echo "hugo not found. Installing hugo..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
      brew install hugo
    else
      sudo snap install hugo
    fi
  fi

  # Install yarn if not installed
  if ! command -v yarn &> /dev/null; then
    echo "yarn not found. Installing yarn..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
      brew install yarn
    else
      npm install -g yarn
    fi
  fi

  # Install docsify-cli
  if ! command -v docsify &> /dev/null; then
    echo "docsify not found. Installing docsify..."
    npm install -g docsify-cli
  fi

  echo "All dependencies are installed."
}

# Parse the title from README.md
parse_title() {
  TITLE=$(grep -m 1 '^# ' $README_FILE | sed 's/^# //')
  echo "Parsed title: $TITLE"
}

# Get user input for theme selection
choose_theme() {
  local framework=$1
  local default_theme=$2
  local themes=("${!3}")

  if [ "$INTERACTIVE" = true ]; then
    echo "Available themes for $framework:"
    for i in "${!themes[@]}"; do
      echo "$((i+1)). ${themes[$i]}"
    done
    echo "Choose a theme for $framework (default: $default_theme):"
    read -r choice
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#themes[@]}" ]; then
      echo "${themes[$((choice-1))]}"
    else
      echo "$default_theme"
    fi
  else
    echo "$default_theme"
  fi
}

# Get user input for plugin selection
choose_plugins() {
  local framework=$1
  local plugins=("${!2}")
  local selected_plugins=()

  if [ "$INTERACTIVE" = true ]; then
    echo "Available plugins for $framework (separate choices by spaces, leave empty for none):"
    for i in "${!plugins[@]}"; do
      echo "$((i+1)). ${plugins[$i]}"
    done
    echo "Choose plugins for $framework:"
    read -r choice

    for index in $choice; do
      if [[ "$index" =~ ^[0-9]+$ ]] && [ "$index" -ge 1 ] && [ "$index" -le "${#plugins[@]}" ]; then
        selected_plugins+=("${plugins[$((index-1))]}")
      fi
    done
  fi

  echo "${selected_plugins[@]}"
}

# Function to set up MkDocs
setup_mkdocs() {
  local dir="$1/mkdocs-site"
  local port=$2
  local theme=$3
  local plugins=("${!4}")
  mkdir -p $dir
  cd $dir


  mkdocs new .
  mv $README_FILE docs/index.md
  sed -i "s/site_name:.*/site_name: $TITLE/" mkdocs.yml
  sed -i "s/theme:.*/theme: $theme/" mkdocs.yml

  if [ ${#plugins[@]} -gt 0 ]; then
    echo "plugins:" >> mkdocs.yml
    for plugin in "${plugins[@]}"; do
      echo "  - $plugin" >> mkdocs.yml
    done
  fi

  mkdocs build
  mkdocs serve -a 127.0.0.1:$port &
  cd - > /dev/null
}

# Function to set up Hugo
setup_hugo() {
  local dir="$1/hugo-site"
  local port=$2
  local theme=$3
  local plugins=("${!4}")
  mkdir -p $dir
  cd $dir
  hugo new site .
  git submodule add "https://github.com/$theme.git" "themes/$(basename $theme)"
  echo "theme = "$(basename $theme)"" >> config.toml
  echo "title = "$TITLE"" >> config.toml

  for plugin in "${plugins[@]}"; do
    echo "[[params.plugins]]" >> config.toml
    echo "name = "$plugin"" >> config.toml
  done

  cp $README_FILE content/_index.md
  hugo
  hugo server -D -p $port &
  cd - > /dev/null
}

# Function to set up VuePress
setup_vuepress() {
  local dir="$1/vuepress-site"
  local port=$2
  local theme=$3
  local plugins=("${!4}")
  mkdir -p $dir/docs
  cd $dir
  yarn add -D vuepress "$theme"

  echo "module.exports = { title: "$TITLE", description: "An Awesome List", theme: "$theme", plugins: [" > docs/.vuepress/config.js
  for plugin in "${plugins[@]}"; do
    echo ""$plugin"," >> docs/.vuepress/config.js
  done
  echo "] }" >> docs/.vuepress/config.js

  cp $README_FILE docs/README.md
  npx vuepress build docs
  npx vuepress dev docs --port $port &
  cd - > /dev/null
}

# Function to set up Docsify
setup_docsify() {
  local dir="$1/docsify-site"
  local port=$2
  local theme=$3
  local plugins=("${!4}")
  mkdir -p $dir
  cd $dir
  echo "<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>$TITLE</title>
  <link rel="stylesheet" href="//cdn.jsdelivr.net/npm/docsify/lib/themes/$theme.css">
</head>
<body>
  <div id="app"></div>
  <script>
    window.\$docsify = {
      name: "$TITLE",
      repo: "",
      loadSidebar: true,
      subMaxLevel: 2,
      plugins: [
" > index.html

  for plugin in "${plugins[@]}"; do
    echo "      function(hook, vm) {
        hook.beforeEach(function(content) {
          return content + '

Powered by $plugin';
        });
      }," >> index.html
  done

  echo "    ]
    }
  </script>
  <script src="//cdn.jsdelivr.net/npm/docsify/lib/docsify.min.js"></script>
</body>
</html>" >> index.html

  cp $README_FILE .
  docsify serve --port $port &
  cd - > /dev/null
}

# Function to check if a port is available
check_port() {
  local port=$1
  if ! lsof -i:$port > /dev/null; then
    echo $port
  else
    while lsof -i:$port > /dev/null; do
      port=$((port+1))
    done
    echo $port
  fi
}

# Check if the correct number of arguments is provided
if [ "$#" -lt 2 ]; then
  echo "Usage: $0 README_FILE OUTPUT_DIRECTORY [--interactive]"
  exit 1
fi

# Assign arguments to variables
README_FILE=$1
OUTPUT_DIR=$2
INTERACTIVE=false
if [ "$#" -eq 3 ] && [ "$3" == "--interactive" ]; then
  INTERACTIVE=true
fi

# Default themes
DEFAULT_MKDOCS_THEME="mkdocs"
DEFAULT_HUGO_THEME="theNewDynamic/gohugo-theme-ananke"
DEFAULT_VUEPRESS_THEME="vuepress/theme-default"
DEFAULT_DOCSIFY_THEME="vue"

# Available themes
MKDOCS_THEMES=("mkdocs" "readthedocs" "material" "alabaster" "mkdocs-bootstrap" "mkdocs-cinder" "mkdocs-rtd-dropdown" "mkdocs-windmill" "mkdocs-yeti" "slate" "mkdocs-material" "mkdocs-alabaster" "mkdocs-bootstrap4" "mkdocs-insiders")
HUGO_THEMES=("theNewDynamic/gohugo-theme-ananke" "bep/hyde" "spf13/hyde" "kubeflow/hugo-multilingual" "henrythemes/hugo-theme-minimo" "zenorocha/fliptheme" "calintat/minimal" "halogenica/beautifulhugo" "track3/hermit" "budparr/gohugo-theme-ananke" "digitalcraftsman/hugo-agency-theme" "htr3n/hyde-hyde" "muesli/beautifulhugo" "mathieudutour/hugo-drawer" "lucperkins/hugo-fresh")
VUEPRESS_THEMES=("vuepress/theme-default" "vuepress/theme-blog" "vuepress/theme-vue" "vuepress/theme-craft" "vuepress/theme-medium" "vuepress/theme-yuque" "vuepress/theme-book" "vuepress/theme-cosmos" "vuepress/theme-reco" "vuepress/theme-vdoing" "vuepress/theme-hope" "vuepress/theme-antdocs" "vuepress/theme-modern-blog" "vuepress/theme-ououe" "vuepress/theme-succinct")
DOCSIFY_THEMES=("vue" "dark" "buble" "pure" "doka" "vuepress" "minty" "flatly" "readable" "materia" "cinder" "docsify-themeable" "docsify-themeable-dark" "docsify-themeable-light" "docsify-themeable-modern")

# Available plugins
MKDOCS_PLUGINS=("search" "macros" "redirects" "minify" "table-reader" "google-analytics" "sitemap" "git-revision-date" "social" "tags")
HUGO_PLUGINS=("autoprefixer" "postcss" "babel" "sass" "imagemin" "hugo-extended" "hugo-analytics" "hugo-seo" "hugo-deploy" "hugo-redirects")
VUEPRESS_PLUGINS=("@vuepress/plugin-back-to-top" "@vuepress/plugin-medium-zoom" "@vuepress/plugin-nprogress" "@vuepress/plugin-google-analytics" "@vuepress/plugin-blog" "@vuepress/plugin-seo" "@vuepress/plugin-pwa" "@vuepress/plugin-sitemap" "@vuepress/plugin-pagination" "@vuepress/plugin-reading-time")
DOCSIFY_PLUGINS=("docsify-plugin-search" "docsify-plugin-tabs" "docsify-plugin-zoom-image" "docsify-plugin-pagination" "docsify-plugin-mathjax" "docsify-plugin-gtag" "docsify-plugin-seo" "docsify-plugin-ga" "docsify-plugin-sitemap" "docsify-plugin-pwa")

# Parse the title from the README file
parse_title

# Create the main directory
mkdir -p $OUTPUT_DIR

# Install dependencies
install_dependencies

# Find available ports
MKDOCS_PORT=$(check_port 8001)
HUGO_PORT=$(check_port 8002)
VUEPRESS_PORT=$(check_port 8003)
DOCSIFY_PORT=$(check_port 8004)

# Choose themes
MKDOCS_THEME=$(choose_theme "MkDocs" $DEFAULT_MKDOCS_THEME MKDOCS_THEMES[@])
HUGO_THEME=$(choose_theme "Hugo" $DEFAULT_HUGO_THEME HUGO_THEMES[@])
VUEPRESS_THEME=$(choose_theme "VuePress" $DEFAULT_VUEPRESS_THEME VUEPRESS_THEMES[@])
DOCSIFY_THEME=$(choose_theme "Docsify" $DEFAULT_DOCSIFY_THEME DOCSIFY_THEMES[@])

# Choose plugins
MKDOCS_PLUGINS_SELECTED=$(choose_plugins "MkDocs" MKDOCS_PLUGINS[@])
HUGO_PLUGINS_SELECTED=$(choose_plugins "Hugo" HUGO_PLUGINS[@])
VUEPRESS_PLUGINS_SELECTED=$(choose_plugins "VuePress" VUEPRESS_PLUGINS[@])
DOCSIFY_PLUGINS_SELECTED=$(choose_plugins "Docsify" DOCSIFY_PLUGINS[@])

# Set up each framework
setup_mkdocs $OUTPUT_DIR $MKDOCS_PORT $MKDOCS_THEME MKDOCS_PLUGINS_SELECTED[@]
setup_hugo $OUTPUT_DIR $HUGO_PORT $HUGO_THEME HUGO_PLUGINS_SELECTED[@]
setup_vuepress $OUTPUT_DIR $VUEPRESS_PORT $VUEPRESS_THEME VUE

PRESS_PLUGINS_SELECTED[@]
setup_docsify $OUTPUT_DIR $DOCSIFY_PORT $DOCSIFY_THEME DOCSIFY_PLUGINS_SELECTED[@]

echo "Setup completed. You can now preview each framework by navigating to the respective URLs."

echo "MkDocs: http://127.0.0.1:$MKDOCS_PORT (Theme: $MKDOCS_THEME)"
echo "Hugo: http://127.0.0.1:$HUGO_PORT (Theme: $(basename $HUGO_THEME))"
echo "VuePress: http://127.0.0.1:$VUEPRESS_PORT (Theme: $VUEPRESS_THEME)"
echo "Docsify: http://127.0.0.1:$DOCSIFY_PORT (Theme: $DOCSIFY_THEME)"
