open Import

let action = "destruct"

let code_action_of_case_analysis uri (loc, newText) =
  let edit : WorkspaceEdit.t =
    let textedit : TextEdit.t = { range = Range.of_loc loc; newText } in
    let uri = Uri.to_string uri in
    WorkspaceEdit.create ~changes:[ (uri, [ textedit ]) ] ()
  in
  let title = String.capitalize_ascii action in
  CodeAction.create ~title ~kind:(CodeActionKind.Other action) ~edit
    ~isPreferred:false ()

let code_action doc (params : CodeActionParams.t) =
  let uri = Uri.t_of_yojson (`String params.textDocument.uri) in
  match Document.kind doc with
  | Intf -> Fiber.return (Ok None)
  | Impl -> (
    let command =
      let start = Position.logical params.range.start in
      let finish = Position.logical params.range.end_ in
      Query_protocol.Case_analysis (start, finish)
    in
    let open Fiber.O in
    let+ res = Document.dispatch doc command in
    match res with
    | Ok res -> Ok (Some (code_action_of_case_analysis uri res))
    | Error
        ( Destruct.Wrong_parent _ | Query_commands.No_nodes
        | Destruct.Not_allowed _ | Destruct.Useless_refine
        | Destruct.Nothing_to_do ) ->
      Ok None
    | Error exn -> raise exn )
