structure CLA = CommandLineArgs
structure Seq = ArraySequence

(* chosen by subdirectory *)
structure BC = BC

val n = CLA.parseInt "n" 200000000
val _ = print ("n " ^ Int.toString n ^ "\n")

val events = Event.generateInput n
val r = (0, n)
val r1 = (0, n)
val r2 = (0, n)

fun task () =
  BC.bestCut events r r1 r2

val (cost, v, ln, rn) = Benchmark.run "best cut" task
val _ = print ("cost  " ^ Real.toString cost ^ "\n")
val _ = print ("value " ^ Real.toString v ^ "\n")
val _ = print ("ln    " ^ Int.toString ln ^ "\n")
val _ = print ("rn    " ^ Int.toString rn ^ "\n")
