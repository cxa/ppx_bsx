open Ppxlib

module ExprsMap = Map.Make(String)

type html_frags =
  { strs: string list
  ; exprs: expression ExprsMap.t
  }

let name = "ppx_bsx"

let expr_placeholder_prefix = "__b_s_x__placeholder__"

let fragment_placeholder = "ppx_bsx_fragment"

let tidy_attr_name =
  function
  | "class" -> "className"
  | "for" -> "htmlFor"
  | "type" -> "type_"
  | "to" -> "to_"
  | "open" -> "open_"
  | "begin" -> "begin_"
  | "end" -> "end_"
  | "in" -> "in_"
  | _ as origin -> origin

let is_titlecase str =
  let fstc = String.get str 0 in
  Char.uppercase_ascii fstc = fstc

let placeholderize_fragment html =
  Str.(
    html
    |> global_replace (regexp "<>") ("<" ^ fragment_placeholder ^ ">")
    |> global_replace (regexp "</>") ("</" ^ fragment_placeholder ^ ">")
  )

let collect_html first_html_frag expr_list =
  expr_list
  |> List.fold_left (fun (frags, placeholder_index) (_, expr) ->
      match expr.pexp_desc with
      | Pexp_constant (Pconst_string (str, None)) ->
        ({ frags with strs = str :: frags.strs }, placeholder_index)
      | _ ->
        let attr = Printf.sprintf "%s%i" expr_placeholder_prefix placeholder_index in
        ({ strs = attr :: frags.strs
         ; exprs = ExprsMap.add attr expr frags.exprs
         }, placeholder_index + 1)
    ) ({ strs = [first_html_frag]; exprs = ExprsMap.empty }, 0)
  |> fst

let text_to_expr loc txts exprs =
  let txt = String.concat "" txts in
  Ast_builder.Default.(
    match exprs |> ExprsMap.find_opt txt with
    | Some expr ->
      begin match expr.pexp_desc with
        | Pexp_constant (Pconst_string (str, Some "")) -> (* transform {|w|} to {j|w|j} *)
          pexp_constant ~loc (Pconst_string (str, Some "j"))
        | _ -> expr
      end
    | None -> estring ~loc txt
  )

let handle_markup_text loc exprs txts =
  let expr = text_to_expr loc txts exprs in
  match expr.pexp_desc with
  | Pexp_constant _ ->
    let args = [(Nolabel, expr)] in
    Ast_builder.Default.pexp_apply ~loc [%expr React.string] args
  | _ -> expr

let add_jsx_attr loc e =
  {e with pexp_attributes = [({txt = "JSX"; loc}, PStr [])] }

let handle_markup_element loc exprs (_nsuri, lname) attrs children =
  let open Ast_builder.Default in
  match lname with
  | n when n = fragment_placeholder ->
    elist ~loc children |> add_jsx_attr loc
  | _ ->
    let is_titlecase = is_titlecase lname in
    let fname =
      if is_titlecase
      then Printf.sprintf "%s.createElement" lname
      else lname
    in
    let f = [%expr [%e evar ~loc fname]] in
    let labled_args =
      attrs
      |> List.map (fun ((_uri, name), v) ->
          let exp =
            if String.length v = 0
            then evar ~loc name
            else text_to_expr loc [v] exprs
          in
          ((Labelled (tidy_attr_name name)), exp)
        )
    in
    let args =
      (Nolabel, eunit ~loc)
      :: (Labelled "children", elist ~loc children)
      :: List.rev labled_args
      |> List.rev
    in
    pexp_apply ~loc f args |> add_jsx_attr loc

let report loc mloc error =
  Markup.(
    match error with
    | `Bad_token _ -> ()         (* ignore this error because our attrs missing quotations*)
    | _ ->
      let location =
        fst mloc + loc.loc_start.pos_lnum
      , snd mloc + loc.loc_start.pos_cnum
      in
      let errstr = Error.to_string ~location error in
      Location.raise_errorf ~loc "%s" errstr
  )

let mk_html str_list =
  str_list
  |> List.rev
  |> String.concat ""
  |> placeholderize_fragment

let markupize loc html_frags =
  Markup.(
    mk_html html_frags.strs
    |> string
    |> parse_xml ~report:(report loc)
    |> signals
    |> trim
    |> normalize_text
    |> tree
      ~text:(handle_markup_text loc html_frags.exprs)
      ~element:(handle_markup_element loc html_frags.exprs)
  )

let expand ~loc ~path:_ expr =
  let first_html_frag, expr_list =
    match expr.pexp_desc with
    | Pexp_constant (Pconst_string (str, None)) ->
      str, []
    | Pexp_apply ({ pexp_desc = Pexp_constant (Pconst_string (str, None)); _ }, exprs) ->
      str, exprs
    | _ -> Location.raise_errorf ~loc "Wrong JSX format"
  in
  let html_frags = collect_html first_html_frag expr_list in
  match markupize loc html_frags with
  | Some expr -> expr
  | None -> Location.raise_errorf ~loc "Wrong JSX format"

let ext =
  Extension.declare
    "bsx"
    Extension.Context.expression
    Ast_pattern.(single_expr_payload __)
    expand

let () =
  Driver.register_transformation name ~extensions:[ext]
