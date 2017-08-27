# ppx_bsx

OCaml JSX for [ReasonReact](https://github.com/reasonml/reason-react/).

## Install

- `yarn add -D ppx_bsx` or `npm i --save-dev ppx_bsx`
- add `"ppx-flags": ["./node_modules/ppx_bsx/bin/ppx_bsx.exe"]` to `bsconfig.json`

👉 <https://github.com/cxa/ppx_bsx_example>

## Usage

This is how it feel:

```ocaml
[%bsx "
  <Container>
    <h1>Nice example</h1>
    <nav className="(styles "sidebar")">
      <Router.Route path='/' component="sidebar" />
    </nav>
    <div className="(styles "content")">
      <Router.Switch>"(mk_switches link_groups)"</Router.Switch>
    </div>
  </Container>
"]
```

### Simple rules

- When you need OCaml expression, wrap it with double quotation marks, otherwise
- For string literal value, just use single quotation marks
- For singe text node, you don't need to wrap it to `ReasonReact.stringToElement`, (surprisedly) `<div>Hello, World</div>` is accepted

### Bonus

For non-ascii string, you can simply use string literal like `{|中文|}`, `ppx_bsx` will convert to `{j|中文|j}` automatically.
