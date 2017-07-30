build:
	ocamlfind ocamlopt src/ppx_bsx.ml -package str,ocaml-migrate-parsetree,markup,re -short-paths -linkpkg -o ppx_bsx.exe

tests:
	ocamlfind ppx_tools/rewriter ./ppx_bsx.exe test/sample.ml

clean:
	rm -f src/*.cmo src/*.cmi src/*.cmx src/*.o ppx_bsx.exe
