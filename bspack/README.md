# bspack

This subdirectory is used for packing up the entire `ppx_bsx` into a single file through BuckleScript's [bspack](https://github.com/bloomberg/bucklescript/blob/master/jscomp/core/bspack_main.ml).

You can run `sh ./pack.sh` to generate `ppx_bsx.ml` which can be feeded to BuckleScript's OCaml compiler.
