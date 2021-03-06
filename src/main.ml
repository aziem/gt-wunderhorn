module JB = Javalib_pack.JBasics
module JP = Sawja_pack.JProgram

let usage _ =
  Printf.eprintf "usage: %s <classpath> <main class name> [print|run]\n" Sys.argv.(0)

let method_sig = JP.main_signature

let _ =
  if (Array.length Sys.argv < 4)
  then
    usage ()
  else
    let classpath = Sys.argv.(1) in
    let class_name = Sys.argv.(2) in

    let ir = JBirToIr.gen_ir classpath class_name method_sig in
    let exprs = ProgramToClauses.translate ir in

    if Sys.argv.(3) = "print"
    then
      let p = PrintClauses.print exprs in
      Core.Std.Out_channel.write_all "example.z3" ~data:p

    (* TODO: not all the ir is printed, why? *)
    else if Sys.argv.(3) = "print-ir"
    then
      let content = ir.Instr.content in
      ( ToStr.proc ir |> Printf.printf "%s\n"
      ; ToStr.instructions (Lazy.force content) |> Printf.printf "%s\n"
      ; ())

    else if Sys.argv.(3) = "run"
    then ClausesToZ3.run exprs

    else
      ( Printf.eprintf "unknown run type: %s\n" Sys.argv.(3)
      ; usage ()
      )

