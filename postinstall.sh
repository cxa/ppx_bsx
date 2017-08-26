cd ../bs-platform
sh scripts/buildocaml.sh
cd ../ppx_bsx
../bs-platform/vendor/ocaml/ocamlopt.opt -no-alias-deps -I +compiler-libs ocamlcommon.cmxa -I +compiler-libs str.cmxa ppx_bsx.ml -o ./bin/ppx_bsx.exe
rm ppx_bsx.cmi ppx_bsx.cmx ppx_bsx.o
