structure CLA = CommandLineArgs
structure Seq = ArraySequence

(* chosen by subdirectory *)
structure L = LinearRec

val n = CLA.parseInt "n" (1000 * 1000 * 100)

val _ = print ("n " ^ Int.toString n ^ "\n")

fun gen i =
  Real.fromInt ((Util.hash i) mod 1000 - 500) / 500.0

val input =
  Seq.tabulate (fn i => (gen (2*i), gen (2*i + 1))) n

fun task () =
  L.linearRec input

val result = Benchmark.run "linear recurrence" task
val x = Seq.nth result (n-1)
val _ = print ("result " ^ Real.toString x ^ "\n")
