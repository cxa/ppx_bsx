cd ../bs-platform
node scripts/buildocaml.js
cd ../ppx_bsx
../bs-platform/ocaml/ocamlopt.opt -no-alias-deps -I +compiler-libs ocamlcommon.cmxa -I +compiler-libs str.cmxa ppx_bsx.ml -o ./bin/ppx_bsx.exe
rm ppx_bsx.cmi ppx_bsx.cmx ppx_bsx.o
