structure CLA = CommandLineArgs
structure Seq = ArraySequence

(* chosen by subdirectory *)
structure M = MCSS

val n = CLA.parseInt "n" (1000 * 1000 * 100)

fun gen i =
  Real.fromInt ((Util.hash i) mod 1000 - 500) / 500.0

val input =
  Seq.tabulate gen n

fun task () =
  M.mcss input

val result = Benchmark.run "mcss-prefixes" task
val _ = print ("result " ^ Real.toString (Seq.nth result (n-1)) ^ "\n")
