# Ruby on Rails Development

## Ruby

### Prerequisites

We need to install RBENV and RUST to manage our Ruby environments.

### Install Rust

```bash
brew install rust
```

### Install rbenv

```shell
brew install rbenv
```

```shell
rbenv init
```

### Install Ruby

```shell
RUBY_CONFIGURE_OPTS="--enable-zjit --enable-yjit" rbenv install 4.0.9
```

```shell
rbenv global 4.0.9
```

```shell
rbenv rehash
```

**Check the installation**

```shell
ruby -v --zjit
```

**You should see something like:**

```shell
ruby 4.0.9 (2026-10-23 revision 3e93b23afc) +ZJIT +PRISM [arm64-darwin25]
```

### Update Ruby Gem Environment

#### Configure .gemrc

Create a .gemrc file. See [https://guides.rubygems.org/](https://guides.rubygems.org/command-reference/#gem-environment).

```shell
touch ~/.gemrc
```

Paste in the following:

```text
gem: --no-document
:backtrace: true
```

Update the gem system.

```shell
gem update --system && gem update
```

### Install Bundler and Rails

```shell
gem install bundler rails
```

## Ruby on Rails Environment

Create a Rails config file:

```shell
touch ~/.railsrc
```

Add the following to ~/.railsrc

```shell
# =====================
# Configuration
# =====================
--edge
--devcontainer
--css=tailwind

# =====================
# Skips
# =====================

# --skip-solid
# --skip-action-cable
# --skip-action-mailer
--skip-action-mailbox
# --skip-action-text
# --skip-active-job
# --skip-active-record
# --skip-active-storage
# --skip-asset-pipeline
--skip-ci
# --skip-git
# --skip-hotwire
# --skip-action-cable
# --skip-bootsnap
# --skip-brakeman
# --skip-bundler-audit
# --skip-dev-gems
# --skip-docker
# --skip-jbuilder
# --skip-kamal
# --skip-rubocop
# --skip-thruster
# --skip-test
# --skip-system-test

# =====================
# Template
# =====================
--template=https://github.com/lehisanchez/Development/raw/refs/heads/main/Rails/Templates/Baseline.rb
```
