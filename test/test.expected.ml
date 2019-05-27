type el =
  | S of string 
  | L of el list 
module React = struct let string s = S s end
module Foo =
  struct
    let createElement ?(a= "")  ?(b= "")  ?(children= [])  () =
      L ([S a; S b] |> (List.append children))
  end
let div ?(a= "")  ?(b= "")  ?(children= [])  () =
  L ([S a; S b] |> (List.append children))
let span ?(a= "")  ?(b= "")  ?(children= [])  () =
  L ([S a; S b] |> (List.append children))
let _ =
  let a = "foo" in
  let b = "bar" in
  let txt = React.string "baz" in
  let name = "bba" in
  (([((Foo.createElement ~a ~b
         ~children:[((div ~a:{j|数据|j}
                        ~children:[((span ~a ~children:[txt] ())
                                  [@JSX ]);
                                  ((span
                                      ~children:[React.string
                                                   {j|你好世界|j}] ())
                                  [@JSX ]);
                                  ((span
                                      ~children:[React.string
                                                   {j|你好世界|j}] ())
                                  [@JSX ]);
                                  ((span
                                      ~children:[React.string "Hello World"]
                                      ())
                                  [@JSX ])] ())
                   [@JSX ]);
                   ((span ~children:[React.string @@ ("Hello, " ^ name)] ())
                   [@JSX ])] ())
    [@JSX ]);
    ((span ~children:[] ())
    [@JSX ])])[@JSX ])
