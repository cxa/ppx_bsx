type el = S of string | L of el list

module React = struct
  let string s =
    S s
end

module Foo = struct
  let createElement ?(a="") ?(b="") ?(children=[]) () =
    L ([S a; S b] |> List.append children)
end

let div ?(a="") ?(b="") ?(children=[]) () =
  L ([S a; S b] |> List.append children)

let span ?(a="") ?(b="") ?(children=[]) () =
  L ([S a; S b] |> List.append children)

let _ =
  let a = "foo" in
  let b = "bar" in
  let txt = React.string "baz" in
  let name = "bba" in
  [%bsx "
  <>
    <Foo a="a" b="b">
      <div a="{|数据|}">
        <span a>"txt"</span>
        <span>"{j|你好世界|j}"</span>
        <span>"{|你好世界|}"</span>
        <span>Hello World</span>
      </div>
      <span>"(React.string @@ "Hello, " ^ name)"</span>
    </Foo>
    <span />
  </>
  "]
