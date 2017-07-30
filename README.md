# ppx_bsx

OCaml JSX for [ReasonReact](https://github.com/reasonml/reason-react/).

## Install

Currently, you can only install manually:

- Install opam if you haven't
- Switch to 4.02.3: `opam switch 4.02.3`
- Install deps: `opam install ocaml-migrate-parsetree markup re
`
- Type `make` in dir of this repo
- Copy `ppx_bsx.exe` to one of your `$PATH`s e.g. `/usr/local/bin`
- On your ReasonReact project, add `"ppx-flags": ["ppx_bsx.exe"]` to `bsconfig.json`

*Install from npm is working in progress.*

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
