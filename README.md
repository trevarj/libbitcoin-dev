# Guix Development Environment for libbitcoin

## Goals

- To create an isolated dev environment for libbitcoin libraries which can promote
hacking on the project.

- Provide a simple (if you can consider Guix simple), reproducible build for a
  libbitcoin-node or libbitcoin-server

## First Checkout

Pulling all submodules:
```sh
git submodule update --init --recursive
```

## Building a package
```sh
guix shell -L guix libbitcoin-node
```

## Starting a dev environment
```sh
guix shell -m manifest.scm
```

## Running a node
```sh
guix shell -L guix libbitcoin-node
bn
```

## Updating all submodules to head
```sh
git submodule update --recursive --remote
```
