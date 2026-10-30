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
