let sample ~id child =
  let a = [%bsx "<button />"] in
  let b = [%bsx "<br />"] in
  [%bsx "
  <div id className='abc'>
    <Upper ref="(fun () -> 1)" key="true" p='p'>hello, "{j|中文世界啊|j}" "{|好|}"</Upper>
    <Router.Route>"(fn ())"</Router.Route>
    <p>"(string_of_int 4)" hours "(string_of_bool true)"</p>
    <span ref="(fun () -> 2)" key='span'>
      "a"
      "b"
      c
      d
    </span>
    <a className="(string_of_int 4) id (string_of_float 6.)" id="id">"(child)": "("Hello" ^ " World" ^ "Foo" ^ "Bar")"</a>
  </div>
"]
