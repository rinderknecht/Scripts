#!/bin/sh

rm -rf ./_opam

./scripts/setup_switch.sh

opam install -y ocp-indent tuareg merlin alcotest-lwt crowbar ocaml-lsp-server ocamlformat-rpc

./scripts/install_vendors_deps.sh
