module STR = Str                (* Avoid shadowed by Ast_helper.Str *)

open Migrate_parsetree
open Ast_404
open Ast_mapper
open Ast_helper
open Asttypes
open Parsetree
open Location
open Longident

module ExprMap = Map.Make(String)

type collector =
  { html_frags: string list;
    exprs: expression ExprMap.t;
    placeholder_index: int;
  }

type tag = string
type prop_name = string
type props = (arg_label * expression) list
type dom_repr =
  | Empty
  | Text of Location.t * expression list
  | Element of Location.t * tag * props * dom_repr list

let expr_placeholder_prefix = "__b_s_x__"

let re_id = Re.compile Re.(seq [ str expr_placeholder_prefix; rep digit ])

let collect e =
  let rec loop col e =
    match e.pexp_desc with
    | Pexp_apply ({ pexp_desc = Pexp_constant Pconst_string (str, None) }, al) ->
      let expr_list = snd @@ List.split al in
      let c = List.fold_left loop col expr_list in
      let html_frags = str :: (List.rev c.html_frags) in
      { c with html_frags  }
    | Pexp_constant Pconst_string (str, None) ->
      { col with html_frags = str :: col.html_frags }
    | _ ->
      let html = Printf.sprintf "%s%i" expr_placeholder_prefix col.placeholder_index in
      let html_frags = html :: col.html_frags in
      let exprs = ExprMap.add html e col.exprs in
      let placeholder_index = col.placeholder_index + 1 in
      { html_frags; exprs; placeholder_index }
  in
  loop { html_frags = []; exprs = ExprMap.empty; placeholder_index = 0 } e

type text_expr_type =
  | Pure_text of expression
  | Ocaml_expr of expression

let rec text_to_exprs loc expr_map str =
  let convert_to_j_if_neccessary e = match e.pexp_desc with
    | Pexp_constant Pconst_string (str, Some "") -> Exp.constant ~loc:e.pexp_loc (Pconst_string (str, Some "j"))
    | _ -> e
  in
  let to_expr s g =
    let slen = String.length s in
    let (i,j) = Re.Group.offset g 0 in
    let key = String.sub s i (j-i) in
    let e =
      try
        ExprMap.find key expr_map
      with
        _ -> raise (Location.Error (Location.error ~loc  "Wrong OCaml expression, you may missed the parentheses."))
    in
    let oe = [Ocaml_expr (convert_to_j_if_neccessary e)] in
    let isWhole = i = 0 && j = slen in
    if isWhole then oe else begin
      let es = ref oe in
      if i > 0 then
        es := text_to_exprs loc expr_map (String.sub s 0 i) @ !es
      else ();
      if j < slen then
        es := !es @ text_to_exprs loc expr_map (String.sub s j (slen-j))
      else ();
      !es
    end
  in
  match Re.exec_opt re_id str with
  | None ->
    begin
      match String.trim str with
      | "" -> [ ]
      | _ as s ->
        let nl_to_sp = STR.(global_replace (regexp "\n") " " s) in
        [ Pure_text (Exp.constant (Pconst_string (nl_to_sp, None))) ]
    end
  | Some g -> to_expr str g

let handle_text loc expr_map xs =
  let str =
    xs
    |> List.map (fun x ->
        STR.(split (regexp "\n+") x)
        |> List.map String.trim
        |> String.concat "\n"
        |> String.trim
      )
    |> String.concat ""
  in
  match str with
  | "" -> Empty
  | _ ->
    let exprs = text_to_exprs loc expr_map str in
    let to_react_el e =
      let loc = e.pexp_loc in
      let rrste = Exp.ident ~loc { loc; txt = Ldot (Lident "ReasonReact", "string")} in
      Exp.apply rrste [ (Nolabel, e)]
    in
    let fold acc item = match item with
      | Pure_text e -> to_react_el e :: acc
      | Ocaml_expr e ->
        match e.pexp_desc with
        | Pexp_constant Pconst_string (_, Some "j") -> to_react_el e :: acc
        | _ -> e :: acc
    in
    Text (loc, (exprs |> List.fold_left fold [] |> List.rev))

let tidy_attr =
  function
  | "class" -> "className"
  | "for" -> "htmlFor"
  | "type" -> "type_"
  | "to" -> "to_"
  | _ as origin -> origin

let handle_element loc expr_map (_, name) attrs children =
  let attrs_map ((_,n), v) =
    let n = tidy_attr n in
    match v with
    | "" -> [ (Labelled n, Exp.ident { loc; txt = Lident n }) ]
    | _ ->
      let v_exprs = text_to_exprs loc expr_map v in
      let to_e item  = match item with Pure_text e -> e | Ocaml_expr e -> e in
      match (List.length v_exprs) with
      | 0 -> []
      | 1 -> [ (Labelled n,  to_e (List.hd v_exprs)) ]
      | _ ->
        let str_cat acc item =
          let e = to_e item in
          let loc = e.pexp_loc in
          Exp.apply ~loc (Exp.ident ~loc { loc; txt = Lident "^"}) ([ (Nolabel, acc); (Nolabel, e) ])
        in
        [ (Labelled n, List.tl v_exprs |> List.fold_left str_cat (List.hd v_exprs |> to_e )) ]
  in
  Element (loc, name, attrs |> List.map attrs_map |> List.concat, children)

let is_titlecase str =
  let fstc = String.get str 0 in
  Char.uppercase fstc = fstc

let handle_titlecase loc tag_name props children_expr =
  let create_comp = Exp.ident ~loc { loc; txt = Ldot (Lident "ReasonReact", "element")} in
  let is_key_or_ref (label, _) = match label with
    | Labelled l -> l = "key" || l = "ref"
    | _ -> false
  in
  let (kr_props, mk_props) = List.partition is_key_or_ref props in
  let modules = (STR.split (STR.regexp "\\.") tag_name) @ [ "make" ] in
  let mk_ldot acc m =  Ldot (acc, m) in
  let ident = List.tl modules |> List.fold_left mk_ldot (Lident (List.hd modules)) in
  let make = Exp.ident ~loc { loc; txt = ident } in
  let comp = Exp.apply make (mk_props @ [ (Nolabel, Exp.array children_expr) ]) in
  Exp.apply create_comp (kr_props @ [ (Nolabel, comp) ])

let handle_lowercase loc tag_name props children_expr =
  let create_dom_el = Exp.ident ~ loc { loc; txt = Ldot (Lident "ReactDOMRe", "createElement")} in
  let tag_name_expr = (Nolabel, Exp.constant (Pconst_string (tag_name, None))) in
  let args = match List.length props with
    | 0 -> [ tag_name_expr; (Nolabel, Exp.array children_expr) ]
    | _ ->
      let create_props = Exp.ident ~loc { loc; txt = Ldot (Lident "ReactDOMRe", "props")} in
      let unit_ = (Nolabel, Exp.construct ~loc {loc; txt = Lident "()"} None) in
      let props_expr = Exp.apply create_props (props @ [ unit_ ]) in
      [ tag_name_expr; (Labelled "props", props_expr); (Nolabel, Exp.array children_expr) ] in
  Exp.apply create_dom_el args

let expr mapper e =
  match e.pexp_desc with
  | Pexp_extension ({ txt = "bsx" }, PStr [{pstr_desc = Pstr_eval (e, _)}]) ->
    let open Markup in
    let c = collect e in
    let html = String.concat "" c.html_frags |> String.trim in
    let rec dom_to_expr = function
      | Element (loc, tag_name, props, children) ->
        let fold acc item = match item with
          | Element _ -> acc @ [ dom_to_expr item ]
          | Text (loc, els) -> acc @ els
          | _ -> acc
        in
        let handler =
          if is_titlecase tag_name then handle_titlecase
          else handle_lowercase
        in
        handler loc tag_name props (children |> List.fold_left fold [])
      | _ -> default_mapper.expr mapper e
    in
    let report location (error: Markup.Error.t) =
      match error with
      | `Bad_token _ -> ()         (* ignore this error because our attrs missing quotations*)
      | _ ->
        let open Lexing in
        let loc = e.pexp_loc in
        let location = (fst location + loc.loc_start.pos_lnum, snd location + loc.loc_start.pos_cnum) in
        let errstr = Error.to_string ~location error in
        raise (Location.Error (Location.error ~loc errstr))
    in
    begin match
        html
        |> STR.global_replace (STR.regexp "<>") "<ReasonReact.Fragment>"
        |> STR.global_replace (STR.regexp "</>") "</ReasonReact.Fragment>"
        |> string
        |> parse_xml ~report
        |> signals
        |> tree
          ~text: (handle_text e.pexp_loc c.exprs)
          ~element: (handle_element e.pexp_loc c.exprs)
      with
      | Some de -> dom_to_expr de
      | None -> default_mapper.expr mapper e
    end
  | _ -> default_mapper.expr mapper e

let mapper _ =
  let module To_current = Convert(OCaml_404)(OCaml_current) in
  To_current.copy_mapper {default_mapper with expr}

let () = Compiler_libs.Ast_mapper.register "bsx"  mapper
