
# Awesome List Site Generator

This project provides a shell script to generate static websites from Markdown files using popular static site generators. The script supports MkDocs, Hugo, VuePress, and Docsify, allowing you to select themes and plugins interactively.

## Purpose

The purpose of this project is to help users quickly set up and preview static websites using different frameworks. This can be particularly useful for generating documentation sites, blogs, or any other static content websites.

## Usage

### Prerequisites

- Python
- pip
- mkdocs
- hugo
- yarn
- docsify-cli

### Installation

1. Clone the repository:
    ```sh
    git clone https://github.com/yourusername/awesome-list-site-generator.git
    cd awesome-list-site-generator
    ```

2. Make the script executable:
    ```sh
    chmod +x setup_frameworks.sh
    ```

3. Run the script with your `README.md` file and the desired output directory. Optionally use the `--interactive` flag to enable interactive theme and plugin selection:
    ```sh
    ./setup_frameworks.sh path/to/README.md output/directory [--interactive]
    ```

### Options

- `README_FILE`: Path to your `README.md` file.
- `OUTPUT_DIRECTORY`: Directory where the generated sites will be stored.
- `--interactive`: (Optional) Enable interactive mode for selecting themes and plugins.

### Themes and Plugins

The script supports a variety of themes and plugins for each framework. Below are the available options:

#### MkDocs Themes
- mkdocs
- readthedocs
- material
- alabaster
- mkdocs-bootstrap
- mkdocs-cinder
- mkdocs-rtd-dropdown
- mkdocs-windmill
- mkdocs-yeti
- slate
- mkdocs-material
- mkdocs-alabaster
- mkdocs-bootstrap4
- mkdocs-insiders

#### Hugo Themes
- theNewDynamic/gohugo-theme-ananke
- bep/hyde
- spf13/hyde
- kubeflow/hugo-multilingual
- henrythemes/hugo-theme-minimo
- zenorocha/fliptheme
- calintat/minimal
- halogenica/beautifulhugo
- track3/hermit
- budparr/gohugo-theme-ananke
- digitalcraftsman/hugo-agency-theme
- htr3n/hyde-hyde
- muesli/beautifulhugo
- mathieudutour/hugo-drawer
- lucperkins/hugo-fresh

#### VuePress Themes
- vuepress/theme-default
- vuepress/theme-blog
- vuepress/theme-vue
- vuepress/theme-craft
- vuepress/theme-medium
- vuepress/theme-yuque
- vuepress/theme-book
- vuepress/theme-cosmos
- vuepress/theme-reco
- vuepress/theme-vdoing
- vuepress/theme-hope
- vuepress/theme-antdocs
- vuepress/theme-modern-blog
- vuepress/theme-ououe
- vuepress/theme-succinct

#### Docsify Themes
- vue
- dark
- buble
- pure
- doka
- vuepress
- minty
- flatly
- readable
- materia
- cinder
- docsify-themeable
- docsify-themeable-dark
- docsify-themeable-light
- docsify-themeable-modern

#### MkDocs Plugins
- search
- macros
- redirects
- minify
- table-reader
- google-analytics
- sitemap
- git-revision-date
- social
- tags

#### Hugo Plugins
- autoprefixer
- postcss
- babel
- sass
- imagemin
- hugo-extended
- hugo-analytics
- hugo-seo
- hugo-deploy
- hugo-redirects

#### VuePress Plugins
- @vuepress/plugin-back-to-top
- @vuepress/plugin-medium-zoom
- @vuepress/plugin-nprogress
- @vuepress/plugin-google-analytics
- @vuepress/plugin-blog
- @vuepress/plugin-seo
- @vuepress/plugin-pwa
- @vuepress/plugin-sitemap
- @vuepress/plugin-pagination
- @vuepress/plugin-reading-time

#### Docsify Plugins
- docsify-plugin-search
- docsify-plugin-tabs
- docsify-plugin-zoom-image
- docsify-plugin-pagination
- docsify-plugin-mathjax
- docsify-plugin-gtag
- docsify-plugin-seo
- docsify-plugin-ga
- docsify-plugin-sitemap
- docsify-plugin-pwa

### Documentation URLs

- [MkDocs Themes](https://github.com/mkdocs/mkdocs/wiki/MkDocs-Themes)
- [Hugo Themes](https://themes.gohugo.io/)
- [VuePress Themes](https://vuepress.vuejs.org/theme/default-theme-config.html)
- [Docsify Themes](https://docsify.js.org/#/themes)
- [MkDocs Plugins](https://github.com/mkdocs/mkdocs/wiki/MkDocs-Plugins)
- [Hugo Plugins](https://gohugo.io/hugo-modules/)
- [VuePress Plugins](https://vuepress.vuejs.org/plugin/using-a-plugin.html)
- [Docsify Plugins](https://docsify.js.org/#/plugins)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request or open an issue.

## License

This project is licensed under the MIT License.
