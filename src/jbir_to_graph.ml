module J = Sawja_pack.JBir
module JB = Javalib_pack.JBasics
module L = Lang

let const = function
  | `ANull    -> assert false (* TODO *)
  | `Class _  -> assert false (* TODO *)
  | `Double f -> assert false (* TODO *)
  | `Float f  -> assert false (* TODO *)
  | `Int i    -> L.Int_lit (Int32.to_int i)
  | `Long i   -> assert false (* TODO *)
  | `String s -> assert false (* TODO *)

let binop op x y = match op with
  | J.ArrayLoad _ -> assert false (* TODO *)
  | J.Add _       -> L.Bi_op (L.Add, x, y)
  | J.Sub _       -> assert false (* TODO *)
  | J.Mult _      -> assert false (* TODO *)
  | J.Div _       -> assert false (* TODO *)
  | J.Rem _       -> assert false (* TODO *)
  | J.IShl        -> assert false (* TODO *)
  | J.IShr        -> assert false (* TODO *)
  | J.IAnd        -> assert false (* TODO *)
  | J.IOr         -> assert false (* TODO *)
  | J.IXor        -> assert false (* TODO *)
  | J.IUshr       -> assert false (* TODO *)
  | J.LShl        -> assert false (* TODO *)
  | J.LShr        -> assert false (* TODO *)
  | J.LAnd        -> assert false (* TODO *)
  | J.LOr         -> assert false (* TODO *)
  | J.LXor        -> assert false (* TODO *)
  | J.LUshr       -> assert false (* TODO *)
  | J.CMP _       -> assert false (* TODO *)

let rec expr st = function
  | J.Const c -> const c
  | J.Var (t, v) -> L.Var (Proc.var st v)
  | J.Binop (op, x, y)  -> binop op (expr st x) (expr st y)
  | J.Unop _            -> assert false (* TODO *)
  | J.Field (v, cn, fs) -> assert false (* TODO *)
  | J.StaticField _     -> assert false (* TODO *)

let rec comp st cond x y = match cond with
  | `Eq -> L.Bi_op (L.Eq, expr st x, expr st y)
  | `Ge -> L.Bi_op (L.Ge, expr st x, expr st y)
  | `Gt -> L.Bi_op (L.Gt, expr st x, expr st y)
  | `Le -> L.Bi_op (L.Le, expr st x, expr st y)
  | `Lt -> L.Bi_op (L.Lt, expr st x, expr st y)
  | `Ne -> L.Un_op (L.Not, (L.Bi_op (L.Eq, expr st x, expr st y)))

let opposite = function
  | `Eq -> `Ne
  | `Ge -> `Lt
  | `Gt -> `Le
  | `Le -> `Gt
  | `Lt -> `Ge
  | `Ne -> `Eq

let rec instr parse st line instr =
  let mk_lbl n = st.Proc.id ^ string_of_int n in
  let this = mk_lbl line in
  let next = mk_lbl (line+1) in
  let noop _ = L.PG.singleton (this, next, []) in
  let id = st.Proc.id in

  match instr with
  | J.Nop -> noop ()
  | J.AffectVar (v, e) ->
    L.PG.singleton (this, next, [L.Assign (Proc.var st v, expr st e)])
  | J.AffectArray (arr, ind, e) -> assert false
  | J.AffectField (v, cn, fs, e) -> assert false
  | J.AffectStaticField _ -> assert false
  | J.Goto l -> L.PG.singleton (this, mk_lbl l, [])
  | J.Ifd ((cond, x, y), l) ->
    L.PG.of_list
      [ (this, mk_lbl l, [L.Call (comp st cond x y)])
      ; (this, next, [L.Call (comp st (opposite cond) x y)])
      ]
  | J.Throw _ -> assert false
  | J.Return e ->
    L.PG.singleton
      (let lbl = id ^ "RET" in
        match e with
       | None   -> (this, lbl, [])
       | Some e -> (this, lbl, [L.Assign (id ^ "RETVAR", expr st e)]))
  | J.New (v, cn, t, es) -> assert false
  | J.NewArray (v, t, es) -> assert false
  | J.InvokeStatic (v, cn, ms, args) ->
    if (JB.ms_name ms) = "ensure"
    then L.PG.of_list
        [ (this, "NOWHERE", [(L.Assert (expr st (List.hd args)))])
        ; (this, next, [])
        ]
    else let v = match v with
        | None -> "DUMMY"
        | Some v -> Proc.var st v in
      let proc = (parse.Parse.cms_lookup (JB.make_cms cn ms)) in
      let assignments = List.map2
          (fun param arg -> L.Assign (param, expr st arg))
          (List.map (Proc.var proc) proc.Proc.params)
          args in
      let ret = proc.Proc.id ^ "RET" in
      let retvar = proc.Proc.id ^ "RETVAR" in

      let proc_graph = convert parse proc in
      L.PG.union
        (L.PG.of_list
           [ (this, proc.Proc.id ^ "0", assignments)
           ; (ret, next,
              [ L.Relate this
              ; L.Assign (v, L.Var retvar) ]) ])
        proc_graph

  (*         [Ir.Non_linear (Ir.Invoke (v, proc, List.map expr es))] *)
  | J.InvokeVirtual (v, e, ck, ms, es) -> assert false (* TODO *)
  | J.InvokeNonVirtual _    -> assert false (* TODO *)
  | J.MonitorEnter _        -> assert false (* TODO *)
  | J.MonitorExit _         -> assert false (* TODO *)
  | J.MayInit _ -> noop ()
  | J.Check _               -> noop ()
  | J.Formula _             -> assert false (* TODO *)

and convert parse proc =
  List.mapi (instr parse proc) proc.Proc.content
  |> L.PG.unions
  |> L.PG.simplify (@)
