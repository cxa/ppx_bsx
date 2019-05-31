# ppx_bsx

OCaml JSX for ReasonReact.

## Install

`ppx_bsx` depends on `ppx_lib`, which means that `ppx_bsx` doesn't support `bs-platform` 5.x, so first step is configuring your project to `"bs-platform": "^6.0.1"`.

Install `ppx_bsx` with `opam` or `esy`, and add `ppx_bsx` executable to `bs-config.json`:

```json
{
  "ppx-flags": [
    "./_opam/bin/ppx_bsx",
    "./node_modules/bs-platform/lib/bsppx.exe -bs-jsx 3"
  ]
}
```

Replace `./_opam/bin/ppx_bsx` to actual `ppx_bsx` installed path.

Example: https://github.com/cxa/ppx_bsx_example.

## Basic Usage

This is how it feel:

```ocaml
[%bsx "
<Container>
  <h1>Nice example</h1>
  <nav className="(styles "sidebar")">
    This is sidebar
  </nav>
  <div className="(styles "content")">
    "(React.string {j|这是主内容|j})"
  </div>
</Container>
"]
```

### Simple Rules
- Break `[%bsx ""]` into
  ```ocaml
  [%bsx "

  "]
  ```
  and ignore the first and last quotation marks.
- When you need OCaml expression, wrap it with double quotation marks, otherwise
- For string literal value, just use single quotation marks
- For single text node, you don't need to wrap it to `ReasonReact.string`, (surprisedly) `<span>Hello, World</span>` is accepted
- Single text `{|你好|}` (but not `expr {|你好|}`) will be transformed to `{j|你好|j}` automatically
