rm ../ppx_bsx.ml

git submodule update --init

cd markup && make
cd ../ocaml-re && make
cd ../ocaml-migrate-parsetree && make
cd _build/default/src
mmv -d "*.pp.mli" "#1.mli"
mmv -d "*.pp.ml" "#1.ml"
cd ../../../../

../node_modules/bs-platform/bin/bspack.exe \
-bs-main Ppx_bsx \
-prelude-str "module Result = struct type ('a, 'b) result = Ok of 'a | Error of 'b end open Result" \
-I ../src \
-I uchar/src \
-I uutf/src \
-I markup/src \
-I ocaml-re/lib \
-I ocaml-migrate-parsetree/_build/default/src \
-o ../ppx_bsx.ml
